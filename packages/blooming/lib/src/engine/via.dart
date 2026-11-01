// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// Scoped Explicit Dependency Tracker (Hybrid Manifest)
// =============================================================================

/// The scoped dependency tracker injected into [computed], [RawViaTerminal],
/// and reactive widget build callbacks.
///
/// Unlike implicit global stack tracking, [BloomVia] requires explicit
/// observation calls (`via(node)`) during the evaluation pass. This creates an
/// explicit, deterministic, and AI-friendly dependency manifest while preserving
/// dynamic runtime branching, 1-pass epoch-based pruning, and on-demand
/// asynchronous turn isolation.
///
/// ## Data Propagation Flow
/// ```text
/// [Evaluation Scope / RawViaTerminal]
///        │
///        ├─► via(nodeA) ──► Registers DAG edge & returns valid data payload A
///        ├─► via(nodeB) ──► Registers DAG edge & returns valid data payload B
///        │
///        └─► Returns computed result & sweeps obsolete edges (1-Pass Epoch Sweeping)
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Zero Tracking Stack Overhead**: Dependency registration happens purely via explicit function
///    calls without maintaining or unwinding global thread-local or zone-scoped context stacks.
/// 2. **1-Pass Dynamic Epoch Sweeping**: Unused dependency edges from inactive conditional branches
///    are swept immediately in a single pass at the end of the synchronous evaluation turn.
/// 3. **On-Demand Asynchronous Turn Isolation**: Synchronous evaluations reuse a single [BloomVia]
///    instance with zero heap allocations. When an evaluation returns a [Future] or [Stream]
///    (e.g., `computed.future`, `computed.stream`, `Effect.via`), post-`await` and post-`yield`
///    `via(...)` calls remain tracked for the latest active turn while superseded turns and
///    deactivated scopes are isolated automatically.
/// 4. **AI Coding Agent Ground Truth**: Explicit manifests prevent AI agents and static analysis tools
///    from missing reactive edges or generating rogue, untracked property reads.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT read reactive nodes untracked inside a derivation closure without
///   wrapping them in `via(...)`.
/// - Do NOT escape or store the [BloomVia] instance in external fields, timers, or UI event
///   callbacks outside the evaluation closure; escaped calls after a synchronous evaluation
///   completes or from a superseded asynchronous turn are ignored.
///
/// **BAD:**
/// ```dart
/// final price = blooming(100);
/// final quantity = blooming(2);
///
/// // [Anti-Pattern] Reading untracked directly without via() leaves node untracked
/// final badTotal = computed((via) {
///   return untracked(price.bloom) * untracked(quantity.bloom); // Untracked! Misses graph invalidations!
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// final price = blooming(100);
/// final quantity = blooming(2);
///
/// // [Recommended] Explicitly register dependencies through via()
/// final goodTotal = computed((via) {
///   return via(price.bloom) * via(quantity.bloom); // Dynamically tracked in LPDAG
/// });
/// ```
///
/// ## Examples
/// ```dart
/// final firstName = blooming('Jane');
/// final lastName = blooming('Doe');
///
/// final fullName = computed((via) {
///   return '${via(firstName.bloom)} ${via(lastName.bloom)}';
/// });
///
/// // Pattern matching on upstream node state without short-circuiting:
/// final status = computed((via) {
///   final state = via.state(firstName.bloom);
///   return switch (state.phase) {
///     BloomPhase.valid => 'User: ${state.data}',
///     BloomPhase.empty => 'No user',
///     BloomPhase.error => 'Error: ${state.error}',
///   };
/// });
/// ```
final class BloomVia {
  BloomVia._(this._node);

  final _BloomViaEpochMixin _node;

  /// Scoped watch function that tracks [bloom] as an upstream dependency
  /// and returns its underlying valid data payload of type [T].
  ///
  /// If [bloom] is currently in an empty or error state, short-circuits
  /// the current evaluation and propagates that state directly downstream.
  ///
  /// * [bloom]: The reactive node to observe within this evaluation epoch.
  ///
  /// **Ensures:**
  /// * Registers [bloom] as an active dependency in the current evaluation epoch.
  /// * Returns the underlying payload [T] when in a valid data state.
  /// * Throws an internal short-circuit sentinel when [bloom] is empty or has error,
  ///   short-circuiting downstream evaluation.
  ///
  /// ## Examples
  /// ```dart
  /// final counter = blooming(0);
  /// final doubled = computed((via) => via(counter.bloom) * 2);
  /// ```
  @pragma('vm:prefer-inline')
  T call<T>(Bloom<T> bloom) {
    _node._trackDependency(this, bloom);
    final s = bloom._read();
    if (s is _ValidBloomState) {
      return s.data;
    }
    throw _ViaShortCircuit(s);
  }

  /// Registers [bloom] as an active dependency in the current evaluation epoch
  /// and returns its 3-phase [BloomState] container without short-circuiting.
  ///
  /// Use this method when you need to defensively inspect empty/error states,
  /// or perform exhaustive 3-state pattern matching inside reactive derivations.
  ///
  /// * [bloom]: The reactive node to observe within this evaluation epoch.
  ///
  /// **Ensures:**
  /// * Registers [bloom] as an active dependency in the current evaluation epoch.
  /// * Returns the zero-allocation [BloomState] view of [bloom].
  ///
  /// ## Examples
  /// ```dart
  /// final user = blooming.late<User>();
  ///
  /// // 1. Defensive conditional inspection
  /// final label = computed((via) {
  ///   final userState = via.state(user.bloom);
  ///   if (userState.isEmpty) return 'Guest';
  ///   return userState.data.name;
  /// });
  ///
  /// // 2. Exhaustive 3-phase pattern matching via phase (Dart 3 switch)
  /// final status = computed((via) {
  ///   final userState = via.state(user.bloom);
  ///   return switch (userState.phase) {
  ///     BloomPhase.valid => 'Welcome, ${userState.data.name}!',
  ///     BloomPhase.empty => 'Awaiting user sign-in',
  ///     BloomPhase.error => 'Authentication error: ${userState.error}',
  ///   };
  /// });
  /// ```
  @pragma('vm:prefer-inline')
  BloomState<T> state<T>(Bloom<T> bloom) {
    _node._trackDependency(this, bloom);
    return bloom as BloomState<T>;
  }

  /// Tethers declarative [tether] to this tracking scope's lifecycle.
  ///
  /// * [tether]: The scoped lifecycle resource or side-effect to attach.
  ///
  /// **Ensures:**
  /// * The tether is automatically activated when this scope activates, and
  ///   deactivated (dormant) when this scope deactivates or is unmounted.
  /// * Emits zero dirty invalidation pulses downstream to parent scopes.
  /// * Returns the identical [tether] instance.
  ///
  /// ## Examples
  /// ```dart
  /// final eventCount = blooming(0);
  ///
  /// final analyticsLoggerEffect = Effect([eventCount.bloom], () {
  ///   print('Logged event: ${untracked(eventCount.bloom)}');
  /// });
  ///
  /// final state = computed((via) {
  ///   via.tether(analyticsLoggerEffect);
  ///   return via(eventCount.bloom) * 10;
  /// });
  /// ```
  @pragma('vm:prefer-inline')
  T tether<T extends Tether>(T tether) {
    _node._trackDependency(this, tether);
    return tether;
  }
}

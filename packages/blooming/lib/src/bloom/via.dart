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
///    (e.g., `computed.future`, `computed.stream`, `switched`), post-`await` and post-`yield`
///    `via(...)` calls remain tracked for the latest active turn while superseded turns and
///    deactivated scopes are isolated automatically.
/// 4. **AI Coding Agent Ground Truth**: Explicit manifests prevent AI agents and static analysis tools
///    from missing reactive edges or generating rogue, untracked property reads.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT read reactive nodes untracked inside a derivation closure without
///   wrapping them in `via(...)`.
/// - Do NOT escape or store the [BloomVia] instance in external fields, timers, or UI event
///   callbacks outside the evaluation closure. While dependency tracking registrations
///   ([BloomVia.call], [state], [tether]) are silently ignored after a synchronous
///   evaluation completes or from a superseded asynchronous turn, control-flow methods
///   ([exit] and [exitIfInactive] when inactive) and evaluating empty or error nodes
///   throw an internal short-circuit sentinel. If invoked outside the framework's evaluation
///   scope, no resolver is present to trap this sentinel, causing an uncaught [Error].
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

  /// Short-circuits the current evaluation epoch and immediately transitions
  /// this reactive derivation into an empty state with an optional [emptyReason].
  ///
  /// This method never returns (returns [Never]), allowing Dart's control flow
  /// analysis to safely promote types and eliminate dead code.
  ///
  /// This method must strictly be invoked within the synchronous or asynchronous
  /// execution flow of a reactive evaluation closure (e.g., [computed], [managed], or custom
  /// terminals) managed by the framework. Because it returns [Never], it unconditionally
  /// throws an internal short-circuit sentinel (`_ViaShortCircuit` implementing [Error]) that
  /// is trapped and handled by the enclosing evaluation resolver.
  ///
  /// **Escaped Call Behavior:**
  /// Calling [exit] on an escaped or stored [BloomVia] instance outside the evaluation closure
  /// (such as inside a deferred timer or UI event callback) cannot be safely ignored as a no-op
  /// due to the [Never] return type. It will throw the internal sentinel into open application code,
  /// resulting in an uncaught [Error].
  ///
  /// ## Examples
  /// ```dart
  /// final validPrice = computed((via) {
  ///   final p = via(price.bloom);
  ///   if (p < 0) via.exit(emptyReason: 'Price cannot be negative');
  ///   return p;
  /// });
  /// ```
  @pragma('vm:prefer-inline')
  Never exit({Object? emptyReason}) {
    throw _ViaShortCircuit(_EmptyBloomState<Never>(emptyReason));
  }

  /// Cooperatively short-circuits the evaluation epoch into an empty state
  /// if this node has been deactivated or superseded by a newer asynchronous turn.
  ///
  /// Call this immediately after an `await` point to prevent wasteful execution
  /// of downstream computations when the result is no longer needed.
  ///
  /// This method must strictly be invoked within an asynchronous derivation closure
  /// (e.g., `computed.future`, `computed.stream`) managed by the framework. If the turn has
  /// been deactivated or superseded, it delegates to [exit], throwing an internal short-circuit
  /// sentinel that is trapped and handled by the asynchronous derivation bridge.
  ///
  /// **Escaped Call Behavior:**
  /// Calling [exitIfInactive] on an escaped or stored [BloomVia] instance outside the evaluation
  /// closure evaluates as inactive (stale or closed tracker), delegating to [exit] and throwing
  /// the internal sentinel. Because no framework resolver is present outside the evaluation
  /// scope, this will result in an uncaught [Error].
  ///
  /// ## Examples
  /// ```dart
  /// final profile = computed.future((via) async {
  ///   final data = await fetchHttp();
  ///   via.exitIfInactive(emptyReason: 'DisposedWhileAwaiting');
  ///   return parseHeavyJson(data);
  /// });
  /// ```
  @pragma('vm:prefer-inline')
  void exitIfInactive({Object? emptyReason}) {
    if (!identical(_node._activeVia, this) || !_node._lifecycle.isActive) {
      exit(emptyReason: emptyReason);
    }
  }
}

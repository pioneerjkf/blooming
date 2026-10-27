// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// Declarative Effect Terminal Base Contract & Sub-Factory Ecosystem
// =============================================================================

/// A declarative lifecycle-bound side-effect node that executes an untracked action upon upstream mutations.
///
/// Under the two-plane reactive architecture of the Bloom framework:
/// - **Data Plane ([Bloom])**: Evaluates and propagates state mutations downstream via the
///   2-Phase Push-Dirty / Lazy-Pull DAG.
/// - **Lifecycle Plane ([Tether])**: Declarative lifecycle entities governed by enclosing
///   tracking scopes via [BloomVia.tether] or executed imperatively via [EffectRunner].
/// - An [Effect] encapsulates an internal terminal (`_Terminal`) that acts as a non-propagating
///   terminal sink (`_isNewerThan` always returns `false`), executing pure side-effects
///   (analytics, external I/O sync, storage, audio/haptic feedback) without mutating intermediate
///   DAG nodes or propagating dirty pulses downstream.
///
/// ## Sub-Factory Pathways
/// ```text
/// Effect(...)                 ──> Manifest N-ary effect ([Effect])
///   ├─ .unary(...)            ──> Fast-path unary manifest effect
///   ├─ .via(...)              ──> Dynamic discovery effect
///   ├─ .scoped(...)           ──> Scoped effect with lifecycle context ([EffectScope])
///   │    ├─ .unary(...)       ──> Scoped unary effect
///   │    └─ .via(...)         ──> Scoped dynamic discovery effect
///   ├─ .debounce(...)         ──> Time-stabilized debounce effect
///   │    └─ .unary(...)       ──> Unary debounce effect
///   ├─ .throttle(...)         ──> Rate-limited throttle effect
///   │    └─ .unary(...)       ──> Unary throttle effect
///   └─ .group(...)            ──> Composite effect group
/// ```
///
/// ## System Architectural Flow
/// ```text
///                     Upstream Bloom Invalidation
///                                 │
///                                 ▼ (Push-Dirty Notification)
///                    ┌─────────────────────────┐
///                    │    Schedule Terminal    │ (_Scheduler.instance._scheduleTerminal)
///                    └────────────┬────────────┘
///                                 │ (Scheduled Turn Execution)
///                                 ▼
///                    ┌─────────────────────────┐
///                    │     _resolveDirty()?    │ (2-Phase Verification)
///                    └────────────┬────────────┘
///                                 │
///                  ┌──────────────┴──────────────┐
///           (false)│                             │(true)
///                  ▼                             ▼
///           [Abort execution]           ┌────────────────┐
///         (No actual mutation)          │ Check guard()? │
///                                       └────────┬───────┘
///                                                │
///                                 ┌──────────────┴──────────────┐
///                          (false)│                             │(true / no guard)
///                                 ▼                             ▼
///                          [Skip execution]             [Consume 1 take Ticket]
///                          [Retain tickets]                     │
///                                                               ▼
///                                                  [Execute action() Untracked]
///                                                               │
///                                                  ┌────────────┴────────────┐
///                                                  │ Exhausted take tickets? │
///                                                  └────────────┬────────────┘
///                                                               │(true)
///                                                               ▼
///                                                      [Auto-Deactivate]
///                                                      [Early Teardown]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Zero-Glitch Terminal Sinks**: Effects fire only after state transactions settle via the
///    Bloom microtask scheduler, eliminating transient tearing and intermediate glitch states.
/// 2. **Precondition Gating with Ticket Preservation**: When `guard` returns `false`, execution
///    is aborted without consuming `take` tickets.
/// 3. **Sound Early Teardown**: An effect configured with `take` automatically deactivates and
///    detaches its subscription edges once the ticket quota reaches zero.
/// 4. **Unified Creation Pathways**: Instances are constructed exclusively via the
///    [Effect] factories and sub-factories (`Effect(...)`, `Effect.unary(...)`, `Effect.via(...)`,
///    `Effect.scoped(...)`, `Effect.debounce(...)`, `Effect.throttle(...)`, `Effect.group(...)`).
/// 5. **Declarative Lifecycle Management**: Tethering via `via.tether()` automatically aligns
///    effect lifecycles with the enclosing computation scope.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT mutate observed `targets` synchronously inside `action` without an exit condition,
///   as it induces reentrant invalidation loops.
/// - Do NOT instantiate new [Effect] objects inside build methods without caching or lifecycle tethering.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Synchronously mutating target inside its own effect without an exit condition
/// final counter = blooming(0);
/// Effect([counter.bloom], () {
///   counter.set(untracked(counter.bloom) + 1); // Triggers infinite invalidation loop!
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] One-way terminal sink for external interactions
/// final counter = blooming(0);
/// Effect([counter.bloom], () {
///   analyticsService.logCounter(untracked(counter.bloom)); // Pure side-effect sink
/// });
/// ```
///
/// ## Examples
/// ```dart
/// final user = blooming('Alice');
/// final auth = blooming(true);
///
/// final syncEffect = Effect(
///   [user.bloom, auth.bloom],
///   () => syncSession(untracked(user.bloom), untracked(auth.bloom)),
///   take: 5,
/// );
/// ```
sealed class Effect extends Tether {
  Effect._() : super._();

  // ===========================================================================
  // Sub-factories
  // ===========================================================================

  /// Sub-factory providing managed lifecycle [EffectScope] callbacks with cleanup registration.
  static const EffectScopedFunctor scoped = EffectScopedFunctor._();

  /// Sub-factory providing time-domain debounce rate-limiting.
  static const EffectDebounceFunctor debounce = EffectDebounceFunctor._();

  /// Sub-factory providing time-domain throttle rate-limiting.
  static const EffectThrottleFunctor throttle = EffectThrottleFunctor._();

  // ===========================================================================
  // Factories
  // ===========================================================================

  /// Creates a manifest [Effect] attached strictly to explicit [targets].
  ///
  /// * Skips initial evaluation (0 runs upon construction/mount).
  /// * Executes [action] in an untracked environment when any of [targets] mutate.
  /// * If [guard] is provided and returns `false`, execution is skipped and [take] tickets are preserved.
  /// * If [take] is provided, executes at most [take] times and then automatically
  ///   deactivates and detaches from upstream targets (Early Teardown).
  /// * If [onUncaughtError] is provided, it is invoked when an uncaught exception is thrown in [action] or [guard].
  ///
  /// * [targets]: The reactive [Bloom] nodes to monitor for mutations.
  /// * [action]: The untracked callback to invoke upon mutation.
  /// * [guard]: Optional boolean predicate gating execution and preserving tickets when returning `false`.
  /// * [take]: Optional limit on execution count before automatic deactivation. Must be non-negative.
  /// * [onUncaughtError]: Optional error recovery handler invoked on uncaught exceptions.
  ///
  /// **Requires:**
  /// * If [take] is provided, it must be greater than or equal to `0`.
  ///
  /// **Ensures:**
  /// * Returns a manifest [Effect] bound to [targets].
  ///
  /// ## Examples
  /// ```dart
  /// final counter = blooming(0);
  /// final e = Effect([counter.bloom], () {
  ///   print('Counter mutated to: ${untracked(counter.bloom)}');
  /// });
  /// ```
  @pragma('vm:prefer-inline')
  factory Effect(
    Iterable<Bloom> targets,
    void Function() action, {
    bool Function()? guard,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  }) =>
      _ManifestEffect(
        targets,
        action,
        guard: guard,
        take: take,
        onUncaughtError: onUncaughtError,
      );

  /// Creates an optimized unary manifest [Effect] attached strictly to a single explicit [target].
  ///
  /// Provides zero-allocation fast-path dispatch by bypassing intermediate `List` allocations
  /// and linking directly via a specialized unary edge terminal.
  ///
  /// * Skips initial evaluation (0 runs upon construction/mount).
  /// * Executes [action] in an untracked environment when [target] mutates.
  /// * If [guard] is provided and returns `false`, execution is skipped and [take] tickets are preserved.
  /// * If [take] is provided, executes at most [take] times and then automatically
  ///   deactivates and detaches from [target] (Early Teardown).
  /// * If [onUncaughtError] is provided, it is invoked when an uncaught exception is thrown in [action] or [guard].
  ///
  /// * [target]: The single [Bloom] node to monitor.
  /// * [action]: The untracked callback to invoke upon mutation.
  /// * [guard]: Optional boolean predicate gating execution.
  /// * [take]: Optional limit on execution count before automatic deactivation.
  /// * [onUncaughtError]: Optional error recovery handler.
  ///
  /// **Requires:**
  /// * If [take] is provided, it must be greater than or equal to `0`.
  ///
  /// **Ensures:**
  /// * Returns an optimized unary manifest [Effect] bound to [target].
  ///
  /// ## Examples
  /// ```dart
  /// final query = blooming('');
  /// final e = Effect.unary(query.bloom, () {
  ///   print('Query changed to: ${untracked(query.bloom)}');
  /// });
  /// ```
  @pragma('vm:prefer-inline')
  factory Effect.unary(
    Bloom target,
    void Function() action, {
    bool Function()? guard,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  }) =>
      _UnaryManifestEffect(
        target,
        action,
        guard: guard,
        take: take,
        onUncaughtError: onUncaughtError,
      );

  /// Creates an explicit dynamic discovery [Effect] using [BloomVia].
  ///
  /// Unlike manifest effects which skip initial evaluation, [Effect.via] evaluates
  /// immediately upon activation to dynamically discover dependencies accessed through `via(node)`.
  ///
  /// * Re-runs [action] whenever any dynamically observed node mutates.
  /// * Automatically prunes stale dependencies and registers new dependencies during re-evaluation (1-pass epoch diffing).
  /// * If [guard] is provided, it is evaluated with [BloomVia] before each run; returning `false` skips execution.
  /// * If [onUncaughtError] is provided, it is invoked when an uncaught exception occurs.
  ///
  /// * [action]: The dynamic tracking callback receiving [BloomVia].
  /// * [guard]: Optional boolean predicate evaluated with [BloomVia] prior to each execution.
  /// * [onUncaughtError]: Optional error recovery handler.
  ///
  /// **Ensures:**
  /// * Returns a dynamic [Effect] with explicit [BloomVia] edge tracking.
  ///
  /// ## Examples
  /// ```dart
  /// final a = blooming(1);
  /// final b = blooming(2);
  ///
  /// final e = Effect.via((via) {
  ///   print('Dynamic sum: ${via(a.bloom) + via(b.bloom)}');
  /// });
  /// ```
  @pragma('vm:prefer-inline')
  factory Effect.via(
    void Function(BloomVia via) action, {
    bool Function(BloomVia via)? guard,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  }) =>
      _ViaEffect(
        action,
        guard: guard,
        onUncaughtError: onUncaughtError,
      );

  /// Bundles a collection of [effects] into a composite [Effect] managing their aggregated lifecycle.
  ///
  /// * [effects]: The collection of child effects to group together. Duplicate instances
  ///   are automatically deduplicated.
  ///
  /// **Ensures:**
  /// * Returns a composite [Effect] managing the aggregated lifecycle of [effects].
  ///
  /// ## Examples
  /// ```dart
  /// final group = Effect.group([searchEffect, loggingEffect]);
  /// final runner = group.start();
  /// runner.stop(); // Atomically cleans up both effects
  /// ```
  @pragma('vm:prefer-inline')
  factory Effect.group(Iterable<Effect> effects) => _EffectGroup(effects);

  _Terminal get _terminal;

  @mustCallSuper
  @override
  void _activate() {
    super._activate();
    _terminal.activate();
  }

  @mustCallSuper
  @override
  void _deactivate() {
    _terminal.deactivate();
    super._deactivate();
  }

  @override
  void _debugForceInvalidate(Set<_Node> visited) {
    if (!visited.add(this)) return;
    assert(() {
      _terminal._debugForceInvalidateInternal(visited);
      return true;
    }());
    _debugInvalidateSelf();
  }
}

/// Sub-factory providing declarative [Effect] creation with scoped lifecycle context ([EffectScope]).
@immutable
final class EffectScopedFunctor {
  const EffectScopedFunctor._();

  /// Creates a manifest [Effect] attached strictly to explicit [targets] providing an [EffectScope].
  ///
  /// * Skips initial evaluation (0 runs upon construction/mount).
  /// * Executes [action] with an injected [EffectScope] in an untracked environment when any of [targets] mutate.
  /// * Prior to subsequent evaluations or deactivation, the previous turn's [EffectScope]
  ///   is marked cancelled and its registered cleanup callbacks are executed in LIFO order.
  /// * If [guard] is provided and returns `false`, execution is skipped and [take] tickets are preserved.
  /// * If [take] is provided, executes at most [take] times and then automatically deactivates (Early Teardown).
  /// * If [onUncaughtError] is provided, it is invoked on uncaught exceptions.
  ///
  /// * [targets]: The reactive [Bloom] nodes to monitor for mutations.
  /// * [action]: The untracked callback receiving an [EffectScope] to invoke upon mutation.
  /// * [guard]: Optional boolean predicate gating execution.
  /// * [take]: Optional limit on execution count before automatic deactivation.
  /// * [onUncaughtError]: Optional error recovery handler.
  ///
  /// **Requires:**
  /// * If [take] is provided, it must be greater than or equal to `0`.
  ///
  /// **Ensures:**
  /// * Returns a scoped [Effect] bound to [targets].
  ///
  /// ## Examples
  /// ```dart
  /// final room = blooming('lobby');
  /// final e = Effect.scoped([room.bloom], (scope) {
  ///   final timer = Timer.periodic(const Duration(seconds: 5), (_) => ping());
  ///   scope.onCleanup(timer.cancel);
  /// });
  /// ```
  @pragma('vm:prefer-inline')
  Effect call(
    Iterable<Bloom> targets,
    void Function(EffectScope scope) action, {
    bool Function()? guard,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  }) =>
      _HandledManifestEffect(
        targets,
        action,
        guard: guard,
        take: take,
        onUncaughtError: onUncaughtError,
      );

  /// Creates an optimized unary manifest [Effect] attached strictly to a single explicit [target] providing an [EffectScope].
  ///
  /// * Skips initial evaluation (0 runs upon construction/mount).
  /// * Executes [action] with an injected [EffectScope] in an untracked environment when [target] mutates.
  /// * Prior to subsequent evaluations or deactivation, the previous turn's [EffectScope]
  ///   is marked cancelled and its registered cleanup callbacks are executed in LIFO order.
  /// * If [guard] is provided and returns `false`, execution is skipped and [take] tickets are preserved.
  /// * If [take] is provided, executes at most [take] times and then automatically deactivates (Early Teardown).
  /// * If [onUncaughtError] is provided, it is invoked on uncaught exceptions.
  ///
  /// * [target]: The single [Bloom] node to monitor.
  /// * [action]: The untracked callback receiving an [EffectScope] to execute when [target] mutates.
  /// * [guard]: Optional boolean predicate gating execution.
  /// * [take]: Optional limit on execution count before automatic deactivation.
  /// * [onUncaughtError]: Optional error recovery handler.
  ///
  /// **Requires:**
  /// * If [take] is provided, it must be greater than or equal to `0`.
  ///
  /// **Ensures:**
  /// * Returns an optimized unary scoped [Effect] bound to [target].
  ///
  /// ## Examples
  /// ```dart
  /// final room = blooming('lobby');
  /// final e = Effect.scoped.unary(room.bloom, (scope) {
  ///   final client = connect(untracked(room.bloom));
  ///   scope.onCleanup(client.close);
  /// });
  /// ```
  @pragma('vm:prefer-inline')
  Effect unary(
    Bloom target,
    void Function(EffectScope scope) action, {
    bool Function()? guard,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  }) =>
      _HandledUnaryManifestEffect(
        target,
        action,
        guard: guard,
        take: take,
        onUncaughtError: onUncaughtError,
      );

  /// Creates an explicit dynamic discovery [Effect] using [BloomVia] and [EffectScope].
  ///
  /// Evaluates immediately upon activation to discover dynamic dependencies via `via(node)`,
  /// providing an [EffectScope] to register turn teardowns and observe lifecycle state.
  ///
  /// Prior to subsequent evaluations or deactivation, the previous turn's [EffectScope]
  /// is marked cancelled and its registered cleanups are executed in LIFO order.
  ///
  /// * [action]: The dynamic tracking callback receiving [BloomVia] and [EffectScope].
  /// * [guard]: Optional boolean predicate evaluated with [BloomVia] prior to each execution.
  /// * [onUncaughtError]: Optional error recovery handler.
  ///
  /// **Ensures:**
  /// * Returns a dynamic [Effect] with explicit [BloomVia] edge tracking and [EffectScope] lifecycle.
  ///
  /// ## Examples
  /// ```dart
  /// final e = Effect.scoped.via((via, scope) {
  ///   final endpoint = via(apiEndpoint.bloom);
  ///   final client = HttpClient(endpoint);
  ///   scope.onCleanup(client.close);
  /// });
  /// ```
  @pragma('vm:prefer-inline')
  Effect via(
    void Function(BloomVia via, EffectScope scope) action, {
    bool Function(BloomVia via)? guard,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  }) =>
      _HandledViaEffect(
        action,
        guard: guard,
        onUncaughtError: onUncaughtError,
      );
}

/// Sub-factory providing declarative debounce rate-limiting [Effect] creation.
@immutable
final class EffectDebounceFunctor {
  const EffectDebounceFunctor._();

  /// Creates a debounce [Effect] attached to explicit [targets].
  ///
  /// Defers execution of [action] until [duration] has elapsed since the most recent mutation.
  ///
  /// * [targets]: The collection of reactive [Bloom] nodes to monitor.
  /// * [duration]: The silence window duration required before executing [action].
  /// * [action]: The untracked callback to execute when the debounce window settles.
  /// * [guard]: Optional predicate gating execution and preserving tickets when returning `false`.
  /// * [leading]: Whether to execute [action] immediately on the first mutation. Defaults to `false`.
  /// * [trailing]: Whether to execute [action] on the trailing edge after silence elapses. Defaults to `true`.
  /// * [take]: Optional maximum number of times this effect may execute before early teardown.
  /// * [onUncaughtError]: Optional error callback invoked when [action] or [guard] throws an uncaught exception.
  ///
  /// **Requires:**
  /// * At least one of [leading] or [trailing] must be `true`.
  /// * If [take] is provided, it must be greater than or equal to `0`.
  ///
  /// **Ensures:**
  /// * Returns a debounce [Effect] attached to [targets].
  ///
  /// ## Examples
  /// ```dart
  /// final query = blooming('');
  /// final e = Effect.debounce(
  ///   [query.bloom],
  ///   const Duration(milliseconds: 300),
  ///   () => apiService.search(untracked(query.bloom)),
  /// );
  /// ```
  @pragma('vm:prefer-inline')
  Effect call(
    Iterable<Bloom> targets,
    Duration duration,
    void Function() action, {
    bool Function()? guard,
    bool leading = false,
    bool trailing = true,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  }) =>
      _ManifestDebounceEffect(
        targets,
        duration,
        action,
        guard: guard,
        leading: leading,
        trailing: trailing,
        take: take,
        onUncaughtError: onUncaughtError,
      );

  /// Creates an optimized unary debounce [Effect] attached to a single explicit [target].
  ///
  /// * [target]: The single [Bloom] node to monitor.
  /// * [duration]: The silence window duration required before executing [action].
  /// * [action]: The untracked callback to execute.
  /// * [guard]: Optional predicate gating execution and preserving tickets when returning `false`.
  /// * [leading]: Whether to execute on the leading edge. Defaults to `false`.
  /// * [trailing]: Whether to execute on the trailing edge. Defaults to `true`.
  /// * [take]: Optional execution limit before deactivation.
  /// * [onUncaughtError]: Optional error recovery handler.
  ///
  /// **Requires:**
  /// * At least one of [leading] or [trailing] must be `true`.
  /// * If [take] is provided, it must be greater than or equal to `0`.
  ///
  /// **Ensures:**
  /// * Returns an optimized unary debounce [Effect] attached to [target].
  ///
  /// ## Examples
  /// ```dart
  /// final query = blooming('');
  /// final e = Effect.debounce.unary(
  ///   query.bloom,
  ///   const Duration(milliseconds: 300),
  ///   () => apiService.search(untracked(query.bloom)),
  /// );
  /// ```
  @pragma('vm:prefer-inline')
  Effect unary(
    Bloom target,
    Duration duration,
    void Function() action, {
    bool Function()? guard,
    bool leading = false,
    bool trailing = true,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  }) =>
      _UnaryManifestDebounceEffect(
        target,
        duration,
        action,
        guard: guard,
        leading: leading,
        trailing: trailing,
        take: take,
        onUncaughtError: onUncaughtError,
      );
}

/// Sub-factory providing declarative throttle rate-limiting [Effect] creation.
@immutable
final class EffectThrottleFunctor {
  const EffectThrottleFunctor._();

  /// Creates a throttle [Effect] attached to explicit [targets].
  ///
  /// Guarantees that [action] is executed at most once per [duration] window, preventing
  /// downstream I/O thrashing during high-frequency events.
  ///
  /// * [targets]: The collection of reactive [Bloom] nodes to monitor.
  /// * [duration]: The minimum time interval between consecutive executions.
  /// * [action]: The untracked callback to execute when triggered.
  /// * [guard]: Optional predicate gating execution and preserving tickets when returning `false`.
  /// * [leading]: Whether to execute on the leading edge of the time window. Defaults to `true`.
  /// * [trailing]: Whether to execute on the trailing edge if events arrived during cooldown. Defaults to `true`.
  /// * [take]: Optional maximum number of times this effect may execute.
  /// * [onUncaughtError]: Optional error recovery handler.
  ///
  /// **Requires:**
  /// * At least one of [leading] or [trailing] must be `true`.
  /// * If [take] is provided, it must be greater than or equal to `0`.
  ///
  /// **Ensures:**
  /// * Returns a throttle [Effect] attached to [targets].
  ///
  /// ## Examples
  /// ```dart
  /// final scroll = blooming(0.0);
  /// final e = Effect.throttle(
  ///   [scroll.bloom],
  ///   const Duration(milliseconds: 100),
  ///   () => syncScrollOffset(untracked(scroll.bloom)),
  /// );
  /// ```
  @pragma('vm:prefer-inline')
  Effect call(
    Iterable<Bloom> targets,
    Duration duration,
    void Function() action, {
    bool Function()? guard,
    bool leading = true,
    bool trailing = true,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  }) =>
      _ManifestThrottleEffect(
        targets,
        duration,
        action,
        guard: guard,
        leading: leading,
        trailing: trailing,
        take: take,
        onUncaughtError: onUncaughtError,
      );

  /// Creates an optimized unary throttle [Effect] attached to a single explicit [target].
  ///
  /// * [target]: The single [Bloom] node to monitor.
  /// * [duration]: The minimum time interval between consecutive executions.
  /// * [action]: The untracked callback to execute.
  /// * [guard]: Optional predicate gating execution.
  /// * [leading]: Whether to execute on the leading edge. Defaults to `true`.
  /// * [trailing]: Whether to execute on the trailing edge. Defaults to `true`.
  /// * [take]: Optional execution limit before deactivation.
  /// * [onUncaughtError]: Optional error recovery handler.
  ///
  /// **Requires:**
  /// * At least one of [leading] or [trailing] must be `true`.
  /// * If [take] is provided, it must be greater than or equal to `0`.
  ///
  /// **Ensures:**
  /// * Returns an optimized unary throttle [Effect] attached to [target].
  ///
  /// ## Examples
  /// ```dart
  /// final scroll = blooming(0.0);
  /// final e = Effect.throttle.unary(
  ///   scroll.bloom,
  ///   const Duration(milliseconds: 100),
  ///   () => syncScrollOffset(untracked(scroll.bloom)),
  /// );
  /// ```
  @pragma('vm:prefer-inline')
  Effect unary(
    Bloom target,
    Duration duration,
    void Function() action, {
    bool Function()? guard,
    bool leading = true,
    bool trailing = true,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  }) =>
      _UnaryManifestThrottleEffect(
        target,
        duration,
        action,
        guard: guard,
        leading: leading,
        trailing: trailing,
        take: take,
        onUncaughtError: onUncaughtError,
      );
}

// =============================================================================
// Effect Scope Contract
// =============================================================================

/// An active execution context scope for a scoped [Effect] run.
///
/// Encapsulates the execution turn's lifecycle status flags and cleanup callback
/// registration, safeguarding against in-flight race conditions and background
/// zombie execution.
///
/// ## System Architectural Flow
///
/// ### Execution Turn State Machine
/// ```text
/// [Upstream Target Mutation / Turn Initialized]
///                       │
///                       ▼
///        ┌──────────────────────────────┐
///        │      EffectScope Active      │ (isActive == true, isCancelled == false)
///        │ (Registers Cleanups via RAII)│
///        └──────────────┬───────────────┘
///                       │
///                       ├─► [Upstream Mutates Again] ──┐
///                       │                              │ (Invokes _dispose())
///                       ├─► [Effect Terminal Deactivated]│
///                       │                              │
///                       ▼                              ▼
///        ┌────────────────────────────────────────────────────────┐
///        │                 EffectScope Disposed                   │ (isActive == false)
///        │       (Executes Registered Cleanups in LIFO Order)     │ (isCancelled == true)
///        └────────────────────────────────────────────────────────┘
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **RAII Multi-Registration**: Call [onCleanup] multiple times within a single turn.
///    Cleanups are stored directly on the fast path (single cleanup) without heap list allocation,
///    and composed recursively with `try-finally` chaining when multiple cleanups are added.
/// 2. **Exception Safety during Setup**: If acquiring a second resource throws an exception,
///    previously registered cleanups for earlier resources remain intact and will be executed
///    when the scope is disposed.
/// 3. **Cancellation & Zombie Protection**: Asynchronous or long-running tasks can inspect
///    [isActive] and [isCancelled] to discard stale results if a newer mutation triggered.
/// 4. **Immediate Teardown on Stale Registration**: If [onCleanup] is invoked after this scope
///    has already been cancelled, the cleanup executes immediately to prevent resource leaks.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT retain [EffectScope] references across multiple effect execution turns.
/// - Do NOT omit cleanup registration for active timers, subscriptions, or sockets acquired
///   inside scoped effect callbacks.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Unregistered timer continues running after effect teardown
/// Effect([room.bloom], () {
///   Timer.periodic(const Duration(seconds: 1), (_) => ping()); // Leaks!
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Bind resource teardown directly to the execution scope
/// Effect.scoped([room.bloom], (scope) {
///   final timer = Timer.periodic(const Duration(seconds: 1), (_) => ping());
///   scope.onCleanup(timer.cancel);
/// });
/// ```
///
/// ## Examples
/// ```dart
/// final room = blooming('lobby');
///
/// final roomEffect = Effect.scoped([room.bloom], (scope) {
///   final timer = Timer.periodic(const Duration(seconds: 5), (_) => sendHeartbeat());
///   scope.onCleanup(timer.cancel);
/// });
/// ```
abstract interface class EffectScope {
  /// Whether this execution turn is currently active and valid (neither cancelled nor deactivated).
  bool get isActive;

  /// Whether this execution turn has been cancelled by a subsequent invalidation,
  /// node deactivation, or lifecycle teardown.
  bool get isCancelled;

  /// Registers a synchronous cleanup callback to be executed upon turn cancellation or deactivation.
  ///
  /// ## Multi-Registration & Locality of Reference (RAII)
  /// You can call [onCleanup] multiple times within a single effect turn.
  /// Registering cleanups **immediately adjacent to resource acquisition** guarantees
  /// exception safety and modular decomposition:
  ///
  /// ```dart
  /// Effect.scoped([room.bloom], (scope) {
  ///   // Resource 1: acquired and immediately guarded
  ///   final timer = Timer.periodic(const Duration(seconds: 1), (_) => ping());
  ///   scope.onCleanup(timer.cancel);
  ///
  ///   // Resource 2: acquired and immediately guarded
  ///   final sub = eventStream.listen(onEvent);
  ///   scope.onCleanup(sub.cancel);
  /// });
  /// ```
  ///
  /// ### Architectural Rationales
  /// 1. **Exception Safety during Setup**: If an exception is thrown while acquiring a subsequent
  ///    resource, previously registered cleanups remain intact and execute reliably.
  /// 2. **Modular Composition**: Enables passing [EffectScope] into independent helper functions
  ///    allowing each sub-routine to safely register its own cleanup without overwriting others.
  /// 3. **Clean Conditional Branching**: Resources acquired inside `if` blocks can register their
  ///    respective teardowns directly in-place without nullable tracking variables.
  ///
  /// ## Execution Timing
  /// Cleanups are **NOT** executed immediately when the action function returns.
  /// They remain dormant and active while the current turn is valid, and are executed:
  /// * **Right before the next execution turn begins** (upon upstream mutation).
  /// * **When the effect is deactivated or unmounted** (upon scope exit / disposal).
  ///
  /// * [cleanup]: The synchronous callback to execute when this turn is cancelled or deactivated.
  ///
  /// **Ensures:**
  /// * If this scope is already cancelled, executes [cleanup] immediately.
  /// * Otherwise, chains [cleanup] into the pending teardown pipeline.
  void onCleanup(void Function() cleanup);
}

// =============================================================================
// Direct .group Extension Suite (Tuples & Iterable)
// =============================================================================

/// Extension granting a 2-tuple of [Effect] instances direct grouping into a composite [Effect].
extension EffectRecord2Extension on (Effect, Effect) {
  /// The underlying [Effect] instances of this pair.
  List<Effect> get effects => [$1, $2];

  /// Bundles this pair of effects into a composite [Effect].
  ///
  /// **Ensures:**
  /// * Returns a composite [Effect] managing the aggregated lifecycle of this pair.
  @pragma('vm:prefer-inline')
  Effect get group => Effect.group(effects);
}

/// Extension granting a 3-tuple of [Effect] instances direct grouping into a composite [Effect].
extension EffectRecord3Extension on (Effect, Effect, Effect) {
  /// The underlying [Effect] instances of this triplet.
  List<Effect> get effects => [$1, $2, $3];

  /// Bundles this triplet of effects into a composite [Effect].
  ///
  /// **Ensures:**
  /// * Returns a composite [Effect] managing the aggregated lifecycle of this triplet.
  @pragma('vm:prefer-inline')
  Effect get group => Effect.group(effects);
}

/// Extension granting a 4-tuple of [Effect] instances direct grouping into a composite [Effect].
extension EffectRecord4Extension on (Effect, Effect, Effect, Effect) {
  /// The underlying [Effect] instances of this 4-tuple.
  List<Effect> get effects => [$1, $2, $3, $4];

  /// Bundles this 4-tuple of effects into a composite [Effect].
  ///
  /// **Ensures:**
  /// * Returns a composite [Effect] managing the aggregated lifecycle of this 4-tuple.
  @pragma('vm:prefer-inline')
  Effect get group => Effect.group(effects);
}

/// Extension granting a 5-tuple of [Effect] instances direct grouping into a composite [Effect].
extension EffectRecord5Extension on (Effect, Effect, Effect, Effect, Effect) {
  /// The underlying [Effect] instances of this 5-tuple.
  List<Effect> get effects => [$1, $2, $3, $4, $5];

  /// Bundles this 5-tuple of effects into a composite [Effect].
  ///
  /// **Ensures:**
  /// * Returns a composite [Effect] managing the aggregated lifecycle of this 5-tuple.
  @pragma('vm:prefer-inline')
  Effect get group => Effect.group(effects);
}

/// Extension granting collections of [Effect] instances direct grouping into a composite [Effect].
extension EffectIterableExtension on Iterable<Effect> {
  /// The underlying [Effect] instances of this collection.
  Iterable<Effect> get effects => this;

  /// Bundles this collection of effects into a composite [Effect].
  ///
  /// **Ensures:**
  /// * Returns a composite [Effect] managing the aggregated lifecycle of this collection.
  @pragma('vm:prefer-inline')
  Effect get group => Effect.group(this);
}

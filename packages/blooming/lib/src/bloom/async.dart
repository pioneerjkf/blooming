// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// Reactive Asynchronous Extensions
// =============================================================================

/// Extension bridging Dart's [Future] with the reactive [Bloom] pipeline.
extension FutureBloomExtension<T> on Future<T> {
  /// Converts this [Future] into a reactive [Bloom] node.
  ///
  /// Attaches error and data listeners immediately upon invocation to safely encapsulate
  /// completion into the reactive [Bloom] state machine without leaking unhandled asynchronous
  /// errors into the Dart event loop if the future settles before observation.
  ///
  /// Provide [initialFactory] to seed the node synchronously before the future settles.
  /// If the future completes with an error, [onError] can be supplied to intercept the
  /// failure and return a fallback value; otherwise, the node transitions to an error state.
  ///
  /// > [!NOTE]
  /// > A [Future] is an already dispatched, hot asynchronous operation. Converting an existing
  /// > [Future] via [toBloom] does NOT defer the underlying I/O. For true lazy on-demand
  /// > execution where asynchronous work is deferred until actively observed (and re-executed
  /// > on subsequent reactivations), use [FutureFactoryBloomExtension.toBloom] (`(() => fetchFuture()).toBloom()`)
  /// > or `computed.future`.
  ///
  /// ## System Architectural Flow
  /// ```text
  /// [Future Dispatched] ──> [toBloom()] ──> [Immediate Listener Binding] ──> [Bloom<T>]
  ///                                                                               │
  ///       ┌───────────────────────────────────────────────────────────────────────┴───────────────────────────────────────┐
  ///       ▼                                                                                                               ▼
  /// [Success: hasData == true, payload: value]                                                       [Error: hasError == true, payload: error]
  /// ```
  ///
  /// ## Architectural Benefits
  /// 1. **Immediate Error Containment**: Binds error listeners upon bridge creation, preventing unhandled asynchronous exceptions in the Dart Zone.
  /// 2. **State Triad Parity**: Starts in empty state (or initial factory seed) and deterministically transitions to data or error.
  /// 3. **Actionable Recovery**: [onError] allows local recovery, returning fallback data before exposing an error to the graph.
  /// 4. **Zero-Latency Read**: When settling while dormant, subsequent subscribers read the resolved state synchronously (0ms delay).
  ///
  /// * [initialFactory]: Optional factory callback returning the initial value before the future completes.
  /// * [onError]: Optional error interceptor converting an error into a valid fallback data instance.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom] node that initializes as empty (or with [initialFactory] value).
  /// * Transitions to a data state upon future completion.
  /// * Transitions to an error state on uncaught error, carrying the original error and stack trace.
  ///
  /// **Warning (Anti-Pattern Prevention):**
  /// - Do NOT invoke `future.toBloom(...)` repeatedly inside build methods or `computed` closures without caching,
  ///   as it creates a new [Bloom] node and re-attaches listeners on every evaluation.
  /// - To defer starting an asynchronous operation until observed, use [FutureFactoryBloomExtension.toBloom]
  ///   (`(() => fetchFuture()).toBloom()`) or `computed.future((via) async => ...)` instead of creating a [Future]
  ///   eagerly and calling `future.toBloom()`.
  ///
  /// **BAD:**
  /// ```dart
  /// // [Anti-Pattern] Invoking toBloom() on every computation pass
  /// final summaryBloom = computed((via) {
  ///   return fetchDetails().toBloom(); // Recreated and discarded continuously!
  /// });
  /// ```
  ///
  /// **GOOD:**
  /// ```dart
  /// // [Recommended] Create the bridged Bloom once and observe its state
  /// final detailsBloom = fetchDetails().toBloom(
  ///   initialFactory: () => UserDetails.loading(),
  /// );
  /// ```
  ///
  /// ## Examples
  /// ```dart
  /// Future<UserProfile> fetchProfile() async => ...;
  ///
  /// final profileBloom = fetchProfile().toBloom(
  ///   initialFactory: () => UserProfile.guest(),
  ///   onError: (error, stackTrace) => UserProfile.fallback(),
  /// );
  ///
  /// final state = untracked.state(profileBloom);
  /// final greeting = switch (state.phase) {
  ///   BloomPhase.valid => 'Welcome, ${state.data.name}!',
  ///   BloomPhase.empty => 'Loading profile...',
  ///   BloomPhase.error => 'Failed to load profile.',
  /// };
  /// ```
  @pragma('vm:prefer-inline')
  Bloom<T> toBloom({
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
  }) =>
      _FutureBloomBridge<T>(
        this,
        initialFactory: initialFactory,
        onError: onError,
      ).bloom;

  /// Converts this [Future] into a pair of reactive nodes: `({Bloom<T> data, Bloom<bool> pending})`.
  ///
  /// * [initialFactory]: Optional factory callback returning the initial value before the future completes.
  /// * [onError]: Optional error interceptor converting an error into a valid fallback data instance.
  ///
  /// **Ensures:**
  /// * Returns a Dart 3 named record `({Bloom<T> data, Bloom<bool> pending})` where:
  ///   - `data` reflects the future's completion value or error state.
  ///   - `pending` is `true` while the future is unresolved, and transitions synchronously to `false` upon settling.
  ///
  /// ## Examples
  /// ```dart
  /// final (:data, :pending) = fetchUser().toBloomTuple();
  /// // or with custom variable names:
  /// final (data: userBloom, pending: isPendingBloom) = fetchUser().toBloomTuple();
  /// ```
  @pragma('vm:prefer-inline')
  ({Bloom<T> data, Bloom<bool> pending}) toBloomTuple({
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
  }) =>
      _FutureBloomBridge<T>(
        this,
        initialFactory: initialFactory,
        onError: onError,
      ).tuple;
}

/// Extension grouping multiple [Future]s into a reactive list of [Bloom] nodes.
extension FutureIterableBloomExtension<T> on Iterable<Future<T>> {
  /// Converts this collection of [Future]s into a reactive list of [Bloom] nodes.
  ///
  /// Each [Future] in this iterable is mapped via [toBloom] with the optional [initialFactory]
  /// and [onError] callbacks. The resulting collection is bundled into a [Bloom] node,
  /// enabling batch observation and collective lifecycle management.
  ///
  /// * [initialFactory]: Optional factory callback returning the initial value before each future completes.
  /// * [onError]: Optional error interceptor converting an error into a valid fallback data instance.
  ///
  /// **Ensures:**
  /// * Returns a constant [Bloom<List<Bloom<T>>>] holding an unmodifiable list of bridged nodes.
  @pragma('vm:prefer-inline')
  Bloom<List<Bloom<T>>> toBloom({
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
  }) =>
      Bloom.constant(List<Bloom<T>>.unmodifiable(map((future) => future.toBloom(
            initialFactory: initialFactory,
            onError: onError,
          ))));
}

/// Extension bridging a lazy [Future] factory (`Future<T> Function()`) with the reactive [Bloom] pipeline.
///
/// Unlike [FutureBloomExtension] (`future.toBloom()`), which binds to an already-dispatched
/// hot [Future] instance, [FutureFactoryBloomExtension] accepts a cold factory closure or
/// function tear-off (`() => fetchFuture()`). This solves two fundamental lifecycle challenges:
/// 1. **Deferred Cold Execution**: The asynchronous operation is never started until a downstream
///    consumer actively subscribes (`0 -> 1` transition).
/// 2. **Bulkhead-Isolated Reactivation**: When all consumers unsubscribe (`1 -> 0` transition),
///    the bridge immediately resets to a fresh initial state (`Empty` or `initialFactory`),
///    completely isolating downstream observers from late-arriving completions of the previous
///    in-flight [Future]. Subsequent reactivations (`0 -> 1`) invoke the factory again to
///    fetch fresh state.
extension FutureFactoryBloomExtension<T> on Future<T> Function() {
  /// Converts this lazy [Future] factory into a reactive [Bloom] node.
  ///
  /// Defers invoking this factory until the returned [Bloom] node is actively observed
  /// by a downstream consumer (`0 -> 1` activation), and spawns a fresh isolated bridge
  /// on every subsequent reactivation cycle (`1 -> 0 -> 1`).
  ///
  /// ## System Architectural Flow
  /// ```text
  /// [Active Consumer Subscribes (0 -> 1)] ──> [futureFactory()] ──> [Fresh _FutureBloomBridge] ──> [Bloom<T>]
  /// [All Consumers Unsubscribe  (1 -> 0)] ──> [Bulkhead Reset to Initial State (Isolates In-Flight Future)]
  /// ```
  ///
  /// ## Architectural Benefits
  /// 1. **Lazy On-Demand Execution**: Defers network I/O or heavy asynchronous work until actively observed,
  ///    eliminating wasted background requests for unmounted views.
  /// 2. **Bulkhead Isolation on Deactivation**: Re-invokes the factory on every activation (`0 -> 1`)
  ///    and immediately swaps the underlying coupled state to a fresh initial [Bloom] upon deactivation (`1 -> 0`),
  ///    guaranteeing zero state contamination from late-settling futures of prior turns.
  /// 3. **Microtask & Temporal Coalescing ([graceful])**: Buffers transient unmounts (`1 -> 0 -> 1` within
  ///    the grace window) so the active bridge stays alive without redundantly re-invoking the factory.
  /// 4. **Composable SWR Caching**: Pairs seamlessly with `.retained()` or `.retainedTuple()` to preserve
  ///    stale-while-revalidate data across deactivation boundaries while still re-fetching on reactivation.
  ///
  /// * [initialFactory]: Optional factory callback returning the initial value before the future completes.
  /// * [onError]: Optional error interceptor converting an error into a valid fallback data instance.
  /// * [graceful]: Optional [Graceful] policy delaying deactivation when subscribers drop to zero.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom] node that lazily invokes this factory upon `0 -> 1` activation.
  /// * Resets synchronously to its initial state (`Empty` or [initialFactory]) upon `1 -> 0` deactivation.
  ///
  /// **Warning (Anti-Pattern Prevention):**
  /// - Pass a closure or function tear-off (`api.fetchProfile.toBloom()` or `(() => fetchProfile(id)).toBloom()`)
  ///   rather than invoking the function eagerly (`fetchProfile(id).toBloom()`) when you need lazy activation
  ///   and automatic refetching on remount.
  ///
  /// **BAD:**
  /// ```dart
  /// // [Anti-Pattern] Eagerly invokes fetchProfile() at construction time and never refetches on remount
  /// final profileBloom = fetchProfile().toBloom();
  /// ```
  ///
  /// **GOOD:**
  /// ```dart
  /// // [Recommended] Defers fetchProfile() until observed and refetches cleanly on reactivation
  /// final profileBloom = (() => fetchProfile()).toBloom(
  ///   graceful: Graceful.microtask,
  /// );
  /// ```
  ///
  /// ## Examples
  /// ```dart
  /// Future<UserProfile> fetchProfile() async => ...;
  ///
  /// // 1. Basic lazy & reconnectable Future bridge (via tear-off or closure)
  /// final profileBloom = fetchProfile.toBloom(
  ///   initialFactory: () => UserProfile.guest(),
  ///   graceful: Graceful.microtask,
  /// );
  ///
  /// // 2. Stale-While-Revalidate (SWR) across activation cycles via .retainedTuple()
  /// final (:data, :pending) = (() => fetchProfile()).toBloom().retainedTuple();
  /// ```
  @pragma('vm:prefer-inline')
  Bloom<T> toBloom({
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    Graceful? graceful,
  }) =>
      _FutureFactoryBloomBridge<T>(
        this,
        initialFactory: initialFactory,
        onError: onError,
        graceful: graceful,
      ).bloom;

  /// Converts this lazy [Future] factory into a pair of reactive nodes: `({Bloom<T> data, Bloom<bool> pending})`.
  ///
  /// * [initialFactory]: Optional factory callback returning the initial value before the future completes.
  /// * [onError]: Optional error interceptor converting an error into a valid fallback data instance.
  /// * [graceful]: Optional [Graceful] policy delaying deactivation when subscribers drop to zero.
  ///
  /// **Ensures:**
  /// * Returns a Dart 3 named record `({Bloom<T> data, Bloom<bool> pending})`.
  ///
  /// **Invariants & Lifecycle (Passive Facet):**
  /// * Invoking this [Future] factory is strictly driven by downstream observation of the `data` node.
  ///   Observing `pending` alone will NOT trigger the factory, preserving Command-Query Separation (CQS).
  ///
  /// ## Examples
  /// ```dart
  /// final (:data, :pending) = (() => fetchUser()).toBloomTuple(
  ///   graceful: Graceful.microtask,
  /// );
  /// ```
  @pragma('vm:prefer-inline')
  ({Bloom<T> data, Bloom<bool> pending}) toBloomTuple({
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    Graceful? graceful,
  }) =>
      _FutureFactoryBloomBridge<T>(
        this,
        initialFactory: initialFactory,
        onError: onError,
        graceful: graceful,
      ).tuple;
}

/// Extension grouping multiple lazy [Future] factories into a reactive list of [Bloom] nodes.
extension FutureFactoryIterableBloomExtension<T> on Iterable<Future<T> Function()> {
  /// Converts this collection of lazy [Future] factories into a reactive list of [Bloom] nodes.
  ///
  /// * [initialFactory]: Optional factory callback returning the initial value before each future completes.
  /// * [onError]: Optional error interceptor converting an error into a valid fallback data instance.
  /// * [graceful]: Optional [Graceful] policy delaying deactivation when subscribers drop to zero.
  ///
  /// **Ensures:**
  /// * Returns a constant [Bloom<List<Bloom<T>>>] holding an unmodifiable list of lazily bridged nodes.
  @pragma('vm:prefer-inline')
  Bloom<List<Bloom<T>>> toBloom({
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    Graceful? graceful,
  }) =>
      Bloom.constant(List<Bloom<T>>.unmodifiable(map((factory) => factory.toBloom(
            initialFactory: initialFactory,
            onError: onError,
            graceful: graceful,
          ))));
}

/// Extension bridging Dart's [Stream] with the reactive [Bloom] pipeline.
extension StreamBloomExtension<T> on Stream<T> {
  /// Converts this [Stream] into a reactive [Bloom] node.
  ///
  /// Bridges asynchronous [Stream] event sequences into synchronous reactive [Bloom] state,
  /// with lazy subscription upon activation and automatic cancellation upon deactivation.
  ///
  /// ## System Architectural Flow
  /// ```text
  /// [Active Consumer Subscribes] ──> [Stream.listen()] ──> Emits Data Pulses ──> [Bloom<T>]
  /// [All Consumers Unsubscribe]  ──> [Subscription.cancel()]
  /// ```
  ///
  /// ## Architectural Benefits
  /// 1. **Lifecycle-Coupled Subscription**: Prevents memory leaks by cancelling subscriptions when unobserved.
  /// 2. **Microtask Cancellation Coalescing**: Supports [graceful] deferral to prevent stream flickering.
  /// 3. **Built-In Distinct Filtering**: Suppresses duplicate consecutive event pulses.
  /// 4. **Exhaustive Pattern Matching**: Native Dart 3 `switch (phase)` enables zero-allocation branch jumping for clean UI mapping.
  ///
  /// * [initialFactory]: Optional callback providing an initial value before the Stream emits its first event.
  /// * [onError]: Optional error recovery callback invoked if the Stream emits an error event.
  /// * [cancelOnError]: If `true`, cancels the stream subscription on error.
  /// * [distinct]: When `true`, suppresses dirty notifications on identical consecutive values. Defaults to `true`.
  /// * [equals]: Custom equality comparator used when [distinct] is `true`.
  /// * [graceful]: Policy to defer unsubscription during rapid remounts or transitions.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom] node reflecting the latest emitted stream events.
  /// * Subscription lifecycle is fully synchronized with downstream demand.
  ///
  /// **Warning (Single-Subscription Streams & Reactivation):**
  /// - Dart's single-subscription streams (e.g. `async*` generators, standard `StreamController()`,
  ///   HTTP response streams, or file I/O streams) cannot be listened to again after cancellation.
  ///   If downstream consumers deactivate (`1 -> 0`, cancelling the subscription) and subsequently
  ///   reactivate (`0 -> 1`), re-listening to the same single-subscription [Stream] instance throws a
  ///   [StateError] (`Bad state: Stream has already been listened to`), moving the node into an error state.
  /// - For streams that must survive `1 -> 0 -> 1` reactivation cycles, prefer:
  ///   1. **Recommended for Cold / Single-Subscription Streams**: Wrapping the stream creation in a factory
  ///      and using [StreamFactoryBloomExtension.toBloom] (`(() => createStream()).toBloom(...)`), which
  ///      spawns a fresh [Stream] instance on every reactivation without throwing a [StateError], or
  ///   2. Converting a hot stream to a broadcast stream via `stream.asBroadcastStream().toBloom(...)` or
  ///      `StreamController.broadcast()` at the producer source, or
  ///   3. Supervising dynamic resource lifetimes with [Bloom.managed].
  ///
  /// **Warning (Anti-Pattern Prevention):**
  /// - Do NOT invoke `stream.toBloom(...)` repeatedly inside `computed` closures without caching,
  ///   as it will establish and cancel separate stream subscriptions on every evaluation.
  ///
  /// **BAD:**
  /// ```dart
  /// // [Anti-Pattern] Converting stream to Bloom on every derivation evaluation
  /// final formattedPrice = computed((via) {
  ///   final stockBloom = stockStream.toBloom(); // Re-subscribes on every evaluation!
  ///   return '\$${via(stockBloom).toStringAsFixed(2)}';
  /// });
  /// ```
  ///
  /// **GOOD:**
  /// ```dart
  /// // [Recommended] Convert stream to Bloom once at the state/controller layer
  /// class StockController {
  ///   late final stockBloom = stockStream.toBloom(
  ///     initialFactory: () => 0.0,
  ///     graceful: Graceful.microtask,
  ///   );
  /// }
  /// ```
  ///
  /// ## Examples
  /// ```dart
  /// Stream<int> sensorStream = ...;
  ///
  /// final sensorBloom = sensorStream.toBloom(
  ///   initialFactory: () => 0,
  ///   distinct: true,
  ///   graceful: Graceful.microtask,
  /// );
  ///
  /// final label = switch (untracked.state(sensorBloom).phase) {
  ///   BloomPhase.valid => 'Reading: ${untracked(sensorBloom)}',
  ///   BloomPhase.empty => 'Sensor calibrating...',
  ///   BloomPhase.error => 'Sensor failure: ${untracked.state(sensorBloom).error}',
  /// };
  /// ```
  @pragma('vm:prefer-inline')
  Bloom<T> toBloom({
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  }) =>
      _StreamBloomBridge.create<T>(
        this,
        initialFactory: initialFactory,
        onError: onError,
        cancelOnError: cancelOnError,
        distinct: distinct,
        equals: equals,
        graceful: graceful,
      ).bloom;

  /// Converts this [Stream] into a pair of reactive nodes: `({Bloom<T> data, Bloom<bool> pending})`.
  ///
  /// The pending state remains `true` until the first event (data or error) arrives or the
  /// stream closes, perfectly aligning with initial loading states in asynchronous UI bindings.
  ///
  /// * [initialFactory]: Optional callback providing an initial value before the Stream emits its first event.
  /// * [onError]: Optional error recovery callback.
  /// * [cancelOnError]: If `true`, cancels the subscription on error.
  /// * [distinct]: When `true`, suppresses duplicate consecutive events.
  /// * [equals]: Custom equality comparator.
  /// * [graceful]: Optional graceful deactivation policy.
  ///
  /// **Ensures:**
  /// * Returns a Dart 3 named record `({Bloom<T> data, Bloom<bool> pending})`.
  ///
  /// **Invariants & Lifecycle (Passive Facet):**
  /// * The underlying [Stream] subscription is strictly driven by downstream observation
  ///   of the `data` node. Observing `pending` alone will NOT trigger stream subscription,
  ///   preserving Command-Query Separation (CQS) and preventing unintended premature I/O.
  ///
  /// ## Examples
  /// ```dart
  /// final (:data, :pending) = stockStream.toBloomTuple();
  /// ```
  @pragma('vm:prefer-inline')
  ({Bloom<T> data, Bloom<bool> pending}) toBloomTuple({
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  }) =>
      _StreamBloomBridge.create<T>(
        this,
        initialFactory: initialFactory,
        onError: onError,
        cancelOnError: cancelOnError,
        distinct: distinct,
        equals: equals,
        graceful: graceful,
      ).tuple;

  /// Converts this [Stream] into a triad of reactive nodes: `({Bloom<T> data, Bloom<bool> pending, Bloom<bool> done})`.
  ///
  /// * `data`: reflects the latest emitted stream item or error state.
  /// * `pending`: remains `true` until the first event (data or error) arrives or the stream closes.
  /// * `done`: transitions to `true` when the stream emits its done event and closes.
  ///
  /// * [initialFactory]: Optional callback providing an initial value before the Stream emits its first event.
  /// * [onError]: Optional error recovery callback.
  /// * [cancelOnError]: If `true`, cancels the subscription on error.
  /// * [distinct]: When `true`, suppresses duplicate consecutive events.
  /// * [equals]: Custom equality comparator.
  /// * [graceful]: Optional graceful deactivation policy.
  ///
  /// **Ensures:**
  /// * Returns a Dart 3 named record `({Bloom<T> data, Bloom<bool> pending, Bloom<bool> done})`.
  ///
  /// **Invariants & Lifecycle (Passive Facets):**
  /// * The underlying [Stream] subscription is strictly driven by downstream observation
  ///   of the `data` node.
  /// * `pending` and `done` are passive projection facets; observing `pending` or `done`
  ///   alone without observing `data` will NOT trigger stream subscription, preserving
  ///   Command-Query Separation (CQS) and preventing unintended premature I/O.
  ///
  /// ## Examples
  /// ```dart
  /// final (:data, :pending, :done) = stockStream.toBloomTriple();
  /// ```
  @pragma('vm:prefer-inline')
  ({Bloom<T> data, Bloom<bool> pending, Bloom<bool> done}) toBloomTriple({
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  }) =>
      _StreamBloomBridge.create<T>(
        this,
        initialFactory: initialFactory,
        onError: onError,
        cancelOnError: cancelOnError,
        distinct: distinct,
        equals: equals,
        graceful: graceful,
      ).triple;
}

/// Extension grouping multiple [Stream]s into a reactive list of [Bloom] nodes.
extension StreamIterableBloomExtension<T> on Iterable<Stream<T>> {
  /// Converts this collection of [Stream]s into a reactive list of [Bloom] nodes.
  ///
  /// * [cancelOnError]: If `true`, cancels the stream subscription on error.
  /// * [distinct]: When `true`, suppresses dirty notifications on identical consecutive values. Defaults to `true`.
  /// * [equals]: Custom equality comparator used when [distinct] is `true`.
  ///
  /// **Ensures:**
  /// * Returns a constant [Bloom<List<Bloom<T>>>] holding an unmodifiable list of bridged nodes.
  @pragma('vm:prefer-inline')
  Bloom<List<Bloom<T>>> toBloom({
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
  }) =>
      Bloom.constant(List<Bloom<T>>.unmodifiable(map((stream) => stream.toBloom(
            cancelOnError: cancelOnError,
            distinct: distinct,
            equals: equals,
          ))));
}

/// Extension bridging a lazy [Stream] factory (`Stream<T> Function()`) with the reactive [Bloom] pipeline.
///
/// While [StreamBloomExtension] (`stream.toBloom()`) lazily calls `.listen()` on `0 -> 1` activation
/// and cancels the subscription on `1 -> 0` deactivation, Dart's single-subscription streams
/// (such as `async*` generator functions, standard `StreamController().stream`, or socket/query streams)
/// permanently expire once canceled and throw `StateError('Bad state: Stream has already been listened to')`
/// upon reactivation (`0 -> 1`).
///
/// [StreamFactoryBloomExtension] solves this by invoking `Stream<T> Function()` to instantiate a
/// brand-new [Stream] on every `0 -> 1` activation and immediately resetting the coupled state
/// to its initial bulkhead state on `1 -> 0` deactivation.
extension StreamFactoryBloomExtension<T> on Stream<T> Function() {
  /// Converts this lazy [Stream] factory into a reactive [Bloom] node.
  ///
  /// Defers invoking this factory until the returned [Bloom] node is actively observed
  /// by a downstream consumer (`0 -> 1` activation), and automatically cancels the
  /// subscription and resets to a fresh initial state when all consumers disconnect (`1 -> 0` deactivation).
  ///
  /// ## System Architectural Flow
  /// ```text
  /// [Active Consumer Subscribes (0 -> 1)] ──> [streamFactory().listen()] ──> [Fresh _StreamBloomBridge] ──> [Bloom<T>]
  /// [All Consumers Unsubscribe  (1 -> 0)] ──> [Subscription.cancel() & Immediate Bulkhead Reset]
  /// ```
  ///
  /// ## Architectural Benefits
  /// 1. **Single-Subscription Safe Reconnection**: Invokes this factory on every activation (`0 -> 1`),
  ///    enabling single-subscription streams and `async*` generators to cleanly reconnect across
  ///    unlimited `1 -> 0 -> 1` cycles without throwing a [StateError].
  /// 2. **Bulkhead Isolation on Deactivation**: Immediately swaps coupled nodes (`data`, `pending`, `done`)
  ///    to fresh initial states upon `1 -> 0` deactivation, preventing stale stream emissions or terminal
  ///    `done` flags from leaking into subsequent observation sessions.
  /// 3. **Microtask & Temporal Coalescing ([graceful])**: Buffers transient unmounts (`1 -> 0 -> 1` within
  ///    the grace window) to keep the existing stream subscription alive without re-invoking the factory.
  /// 4. **Composable SWR Caching**: Pairs with `.retained()` / `.retainedTuple()` when UI consumers want to
  ///    display the last emitted stream value while a fresh stream connection is establishing on remount.
  ///
  /// * [initialFactory]: Optional callback providing an initial value before the Stream emits its first event.
  /// * [onError]: Optional error recovery callback invoked if the Stream emits an error event.
  /// * [cancelOnError]: If `true`, cancels the stream subscription on error.
  /// * [distinct]: When `true`, suppresses dirty notifications on identical consecutive values. Defaults to `true`.
  /// * [equals]: Custom equality comparator used when [distinct] is `true`.
  /// * [graceful]: Policy to defer unsubscription during rapid remounts or transitions.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom] node reflecting the latest emitted stream events.
  /// * Spawns a fresh [Stream] via this factory on every `0 -> 1` activation.
  ///
  /// **Warning (Anti-Pattern Prevention):**
  /// - Do NOT call a single-subscription stream function eagerly (`watchSensor().toBloom()`) if the consumer
  ///   can unmount and remount; pass the function tear-off or closure (`(() => watchSensor()).toBloom()`) instead.
  ///
  /// **BAD:**
  /// ```dart
  /// Stream<int> watchSensor() async* {
  ///   yield 1;
  /// }
  ///
  /// // [Anti-Pattern] Single-subscription stream instance throws StateError on second activation (1 -> 0 -> 1)
  /// final sensorBloom = watchSensor().toBloom();
  /// ```
  ///
  /// **GOOD:**
  /// ```dart
  /// // [Recommended] Factory closure spawns a fresh async* stream on every activation (0 -> 1)
  /// final sensorBloom = (() => watchSensor()).toBloom(
  ///   initialFactory: () => 0,
  ///   graceful: Graceful.microtask,
  /// );
  /// ```
  ///
  /// ## Examples
  /// ```dart
  /// Stream<int> watchSensor() async* { ... }
  ///
  /// // 1. Reconnectable single-subscription stream with microtask grace buffer
  /// final sensorBloom = (() => watchSensor()).toBloom(
  ///   initialFactory: () => 0,
  ///   graceful: Graceful.microtask,
  /// );
  ///
  /// // 2. Preserving last known reading across reconnections via .retainedTuple()
  /// final (:data, :pending) = (() => watchSensor()).toBloom().retainedTuple();
  /// ```
  @pragma('vm:prefer-inline')
  Bloom<T> toBloom({
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  }) =>
      _StreamFactoryBloomBridge.create<T>(
        this,
        initialFactory: initialFactory,
        onError: onError,
        cancelOnError: cancelOnError,
        distinct: distinct,
        equals: equals,
        graceful: graceful,
      ).bloom;

  /// Converts this lazy [Stream] factory into a pair of reactive nodes: `({Bloom<T> data, Bloom<bool> pending})`.
  ///
  /// * [initialFactory]: Optional callback providing an initial value before the Stream emits its first event.
  /// * [onError]: Optional error recovery callback.
  /// * [cancelOnError]: If `true`, cancels the subscription on error.
  /// * [distinct]: When `true`, suppresses duplicate consecutive events.
  /// * [equals]: Custom equality comparator.
  /// * [graceful]: Optional graceful deactivation policy.
  ///
  /// **Ensures:**
  /// * Returns a Dart 3 named record `({Bloom<T> data, Bloom<bool> pending})`.
  ///
  /// **Invariants & Lifecycle (Passive Facet):**
  /// * Invoking this [Stream] factory and subscribing is strictly driven by downstream observation
  ///   of the `data` node. Observing `pending` alone will NOT trigger the factory or subscription.
  ///
  /// ## Examples
  /// ```dart
  /// final (:data, :pending) = (() => watchStock()).toBloomTuple();
  /// ```
  @pragma('vm:prefer-inline')
  ({Bloom<T> data, Bloom<bool> pending}) toBloomTuple({
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  }) =>
      _StreamFactoryBloomBridge.create<T>(
        this,
        initialFactory: initialFactory,
        onError: onError,
        cancelOnError: cancelOnError,
        distinct: distinct,
        equals: equals,
        graceful: graceful,
      ).tuple;

  /// Converts this lazy [Stream] factory into a triad of reactive nodes: `({Bloom<T> data, Bloom<bool> pending, Bloom<bool> done})`.
  ///
  /// * [initialFactory]: Optional callback providing an initial value before the Stream emits its first event.
  /// * [onError]: Optional error recovery callback.
  /// * [cancelOnError]: If `true`, cancels the subscription on error.
  /// * [distinct]: When `true`, suppresses duplicate consecutive events.
  /// * [equals]: Custom equality comparator.
  /// * [graceful]: Optional graceful deactivation policy.
  ///
  /// **Ensures:**
  /// * Returns a Dart 3 named record `({Bloom<T> data, Bloom<bool> pending, Bloom<bool> done})`.
  ///
  /// **Invariants & Lifecycle (Passive Facets):**
  /// * Invoking this [Stream] factory and subscribing is strictly driven by downstream observation
  ///   of the `data` node. `pending` and `done` are passive projection facets.
  ///
  /// ## Examples
  /// ```dart
  /// final (:data, :pending, :done) = (() => watchStock()).toBloomTriple();
  /// ```
  @pragma('vm:prefer-inline')
  ({Bloom<T> data, Bloom<bool> pending, Bloom<bool> done}) toBloomTriple({
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  }) =>
      _StreamFactoryBloomBridge.create<T>(
        this,
        initialFactory: initialFactory,
        onError: onError,
        cancelOnError: cancelOnError,
        distinct: distinct,
        equals: equals,
        graceful: graceful,
      ).triple;
}

/// Extension grouping multiple lazy [Stream] factories into a reactive list of [Bloom] nodes.
extension StreamFactoryIterableBloomExtension<T> on Iterable<Stream<T> Function()> {
  /// Converts this collection of lazy [Stream] factories into a reactive list of [Bloom] nodes.
  ///
  /// * [cancelOnError]: If `true`, cancels the stream subscription on error.
  /// * [distinct]: When `true`, suppresses dirty notifications on identical consecutive values. Defaults to `true`.
  /// * [equals]: Custom equality comparator used when [distinct] is `true`.
  /// * [graceful]: Optional graceful deactivation policy.
  ///
  /// **Ensures:**
  /// * Returns a constant [Bloom<List<Bloom<T>>>] holding an unmodifiable list of lazily bridged nodes.
  @pragma('vm:prefer-inline')
  Bloom<List<Bloom<T>>> toBloom({
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  }) =>
      Bloom.constant(List<Bloom<T>>.unmodifiable(map((factory) => factory.toBloom(
            cancelOnError: cancelOnError,
            distinct: distinct,
            equals: equals,
            graceful: graceful,
          ))));
}

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
  /// > execution where asynchronous work is deferred until actively observed, use `computed.future`.
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
  /// - To defer starting an asynchronous operation until observed, use `computed.future((via) async => ...)`
  ///   instead of creating a [Future] eagerly and calling `future.toBloom()`.
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
  /// - Dart's single-subscription streams (e.g. from standard `StreamController()`) cannot be
  ///   listened to again after cancellation. If downstream consumers deactivate and subsequently
  ///   reactivate, re-listening to a single-subscription stream throws a [StateError], moving the
  ///   node into an error state.
  /// - For streams shared across components that frequently activate and deactivate, prefer:
  ///   1. Converting the stream to a broadcast stream via `stream.asBroadcastStream().toBloom(...)`, or
  ///   2. Using `StreamController.broadcast()` at the producer source, or
  ///   3. Supervising dynamic stream connection lifetimes with [Bloom.managed].
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

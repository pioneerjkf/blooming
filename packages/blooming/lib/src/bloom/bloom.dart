// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// Bloom<T> Core Read-Only Reactive Interface
// =============================================================================

/// The core read-only reactive state interface in the Bloom reactive DAG engine.
///
/// Under the strict **Producer/Consumer Separation (Has-a)** architecture:
/// - [Bloom<T>] represents the observation-only view of a reactive node.
/// - It does **NOT** implement [BloomState<T>] or [BloomController<T>] directly on its public interface.
/// - Mutation APIs (`.set()`, `.data =`, `.setGuarded()`, `.setError()`, `.empty([reason])`) are
///   strictly confined to [BloomController<T>] and [RawBloomController<T>].
/// - [Bloom<T>] NEVER implements [BloomController<T>], and underlying physical entry nodes
///   are private to the library, preventing rogue downcasting at runtime.
///
/// Values and live states are read outside tracking scopes via the global [untracked] functor
/// ([untracked] for values, [BloomUntracked.state] for live states), and explicitly tracked
/// within derivation closures via injected [BloomVia] (`via(node)` for values, `via.state(node)` for live states).
///
/// ## System Architectural Flow
///
/// ### 1. 3-State Finite State Machine (Observed via untracked.state)
/// ```text
///                     ┌────────────────────────────────────────┐
///                     │     Bloom<T> 3-State State Machine      │
///                     └────────────────────────────────────────┘
///                            │ (Bloom.empty<T>() or uninitialized)
///                            ▼
///                     ┌──────────────┐    Controller .set(data)     ┌──────────────┐
///                     │    EMPTY     │ ───────────────────────────> │     DATA     │ (hasData == true)
///                     │  (isEmpty)   │ <─────────────────────────── │  (payload:T) │
///                     └──────┬───────┘   Controller .empty([reason])└──────┬───────┘
///                            │                                             │
///                            │ Controller .setError()        Controller    │
///                            │                               .setError()   │
///                            ▼                                             ▼
///                     ┌────────────────────────────────────────────────────────────┐
///                     │                           ERROR                            │ (hasError == true)
///                     │              (payload: Object, [StackTrace])               │
///                     └────────────────────────────────────────────────────────────┘
/// ```
///
/// ### 2. Explicit Dependency Registration vs. Raw Reads
/// ```text
/// [computed / Effect.via Scope]
///             │ (Injected BloomVia parameter)
///             ▼
///      via(sourceBloom)          ──>  [Registers Source Edge in Active LPDAG & Evaluates T]
///      via.state(sourceBloom)    ──>  [Registers Source Edge & Returns Live BloomState<T>]
///
/// [Outside Derivation Scope / Raw Read]
///             │
///      untracked(sourceBloom)    ──>  [Pure Direct Field Dereference: Returns T (Zero Overhead)]
///      untracked.state(sourceBloom) ──> [Zero-Allocation Live BloomState<T> View]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Zero-Overhead Raw Reads & Explicit Tracking**: Reading via [untracked]
///    is a pure field dereference with zero tracking overhead and no dynamic
///    tracking stack penalty. Reactive derivations explicitly declare dependencies via the injected
///    [BloomVia] parameter (`via(node)`).
/// 2. **3-State Exclusivity**: A [Bloom] node's observed state is strictly in one of three mutually exclusive states:
///    * **Data** ([BloomState.hasData] == true): Contains a valid payload of type `T` (including `null` for `T?`).
///    * **Empty** ([BloomState.isEmpty] == true): Uninitialized or dormant state with optional [BloomState.emptyReason].
///    * **Error** ([BloomState.hasError] == true): Exception state encapsulating [BloomState.error] and optional [BloomState.stackTrace].
/// 3. **Sound Fail-Fast Extraction**: Reading via [untracked] while in Empty or Error state throws
///    [BloomSnapshotExtractionException]. Use `untracked.state(node).dataOrNull`, `untracked.state(node).dataOrElse()`,
///    or native Dart 3 `switch (untracked.state(node).phase)` for safe total pattern matching.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT read reactive nodes untracked directly inside a [computed] or `Effect.via` scope without
///   wrapping in `via(...)`, as [untracked] intentionally bypasses dependency registration.
/// - Do NOT mutate a [BloomController] inside a [computed] or effect reading that same node
///   without a terminating condition, as this induces topological reentrancy cycles.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Reading untracked without via() bypasses dependency registration
/// final badComputed = computed((via) {
///   return untracked(count.bloom) * 2; // count is NOT tracked!
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Explicitly register dependencies through via()
/// final goodComputed = computed((via) {
///   return via(count.bloom) * 2; // Dynamically and explicitly registered in LPDAG
/// });
/// ```
///
/// ## Examples
/// ```dart
/// final counter = BloomController(0);
/// final doubled = computed((via) => via(counter.bloom) * 2);
///
/// print(untracked(doubled)); // 0
/// counter.data = 5;
/// print(untracked(doubled)); // 10
/// ```
abstract base class Bloom<T> extends _Node {
  Bloom._();

  _BloomState<T> _read();

  /// Creates a constant static leaf node holding an immutable valid [data] payload.
  ///
  /// * [data]: The payload to store in this static node.
  ///
  /// **Ensures:**
  /// * Returns a leaf [Bloom<T>] node permanently in the Data state ([BloomState.hasData] == true).
  ///
  /// ## Examples
  /// ```dart
  /// final fixedConfig = Bloom.constant(42);
  /// print(untracked(fixedConfig)); // 42
  /// ```
  factory Bloom.constant(T data) = _ConstantBloom<T>;

  /// A canonical, immutable static leaf node permanently holding a `null` payload.
  ///
  /// Because [Null] is a subtype of `T?` for any type `T` and [Bloom] is covariant,
  /// this singleton can be used as a zero-allocation default or fallback for any
  /// nullable reactive state [Bloom<T?>] without casting.
  ///
  /// ## Examples
  /// ```dart
  /// final Bloom<String?> fallback = config?.nameBloom ?? Bloom.constantNull;
  /// ```
  static final Bloom<Null> constantNull = _ConstantBloom<Null>(null);

  /// Creates a constant static leaf node permanently in an uninitialized (Empty) state.
  ///
  /// * [emptyReason]: Optional diagnostic object explaining why this node holds no data.
  ///
  /// **Ensures:**
  /// * Returns a leaf [Bloom<T>] node permanently in the Empty state ([BloomState.isEmpty] == true).
  ///
  /// ## Examples
  /// ```dart
  /// final placeholder = Bloom<String>.empty('Awaiting initial login');
  /// print(untracked.state(placeholder).isEmpty); // true
  /// ```
  factory Bloom.empty([Object? emptyReason]) = _ConstantBloom<T>.empty;

  /// Creates a constant static leaf node permanently in an Error state.
  ///
  /// * [error]: The exception or error payload.
  /// * [stackTrace]: Optional stack trace associated with the failure.
  ///
  /// **Ensures:**
  /// * Returns a leaf [Bloom<T>] node permanently in the Error state ([BloomState.hasError] == true).
  ///
  /// ## Examples
  /// ```dart
  /// final failedNode = Bloom<int>.error(StateError('Resource offline'));
  /// print(untracked.state(failedNode).hasError); // true
  /// ```
  factory Bloom.error(Object error, [StackTrace? stackTrace]) = _ConstantBloom<T>.error;

  /// Creates a reactive [Bloom] node from a Dart [Future].
  ///
  /// Bridges asynchronous single-value completion into the synchronous reactive LPDAG graph,
  /// lazily initiating the future upon first downstream activation and transitioning from
  /// Empty to Data or Error upon completion.
  ///
  /// ## System Architectural Flow
  /// ```text
  /// [Active Consumer Subscribes] ──> [Future Initiated]
  ///                                           │
  ///            ┌──────────────────────────────┴──────────────────────────────┐
  ///            ▼ (on completion)                                             ▼ (on error)
  ///    [Bloom<T> (Data)]                                              [Bloom<T> (Error)]
  /// ```
  ///
  /// ## Architectural Benefits
  /// 1. **Lazy On-Demand Execution**: Future computation is postponed until an active terminal or UI
  ///    observer requests the value, saving network and CPU bandwidth.
  /// 2. **Deterministic 3-State FSM Integration**: Transitions safely through [BloomSnapshot.empty],
  ///    [BloomSnapshot.new] (Data), or [BloomSnapshot.error], allowing total UI pattern matching.
  /// 3. **Synchronous Fallback Support**: [initialFactory] allows providing an immediate initial payload
  ///    before the asynchronous computation finishes.
  ///
  /// * [future]: The source [Future] to bridge into the reactive LPDAG graph.
  /// * [initialFactory]: Optional callback producing an initial synchronous fallback value.
  /// * [onError]: Optional error recovery callback transforming an exception into a valid [T] payload.
  ///
  /// **Ensures:**
  /// * Returns a reactive [Bloom<T>] node reflecting the resolution of [future].
  ///
  /// **Warning (Anti-Pattern Prevention):**
  /// - Do NOT invoke `Bloom.future(...)` repeatedly inside Flutter build methods or `computed` closures
  ///   without caching in a field, as it instantiates a new asynchronous bridge on every evaluation.
  ///
  /// **BAD:**
  /// ```dart
  /// // [Anti-Pattern] Invoking Bloom.future inside build re-executes the future every frame
  /// Widget build(BuildContext context) {
  ///   final profileBloom = Bloom.future(fetchProfile(userId)); // Triggers new fetch on each build!
  ///   return Text('${untracked.state(profileBloom).dataOrNull?.name}');
  /// }
  /// ```
  ///
  /// **GOOD:**
  /// ```dart
  /// // [Recommended] Instantiate Bloom.future once in a state or controller class
  /// class ProfileController {
  ///   late final profileBloom = Bloom.future(fetchProfile(userId));
  /// }
  /// ```
  ///
  /// ## Examples
  /// ```dart
  /// final userProfileBloom = Bloom.future(
  ///   fetchUserProfile('user-101'),
  ///   initialFactory: () => UserProfile.guest(),
  /// );
  /// ```
  factory Bloom.future(
    Future<T> future, {
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
  }) =>
      _FutureBloomBridge<T>(
        future,
        initialFactory: initialFactory,
        onError: onError,
      ).bloom;

  /// Creates a reactive [Bloom] node from a Dart [Stream].
  ///
  /// Bridges asynchronous event streams into the synchronous reactive LPDAG graph,
  /// establishing a subscription upon activation and cancelling it when all downstream
  /// consumers disconnect.
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
  /// 3. **Built-In Distinct Filtering**: Suppresses duplicate consecutive event pulses when [distinct] is `true`.
  ///
  /// * [stream]: The source [Stream] to bridge into the reactive LPDAG graph.
  /// * [initialFactory]: Optional callback providing an initial state before the Stream emits its first event.
  /// * [onError]: Optional error recovery callback invoked if the Stream emits an error event.
  /// * [cancelOnError]: If `true`, cancels the stream subscription on error.
  /// * [distinct]: When `true`, suppresses dirty notifications on identical consecutive values. Defaults to `true`.
  /// * [equals]: Custom equality comparator used when [distinct] is `true`.
  /// * [graceful]: Optional [Graceful] policy delaying subscription cancellation upon deactivation.
  ///
  /// **Ensures:**
  /// * Returns a reactive [Bloom<T>] node reflecting the latest events of [stream].
  ///
  /// **Warning (Single-Subscription Streams & Reactivation):**
  /// - Dart's single-subscription streams (e.g. from standard `StreamController()`) cannot be
  ///   listened to again after cancellation. If downstream consumers deactivate and subsequently
  ///   reactivate, re-listening to a single-subscription stream throws a [StateError], moving the
  ///   node into an error state.
  /// - For streams shared across components that frequently activate and deactivate, prefer:
  ///   1. Converting the stream to a broadcast stream via `stream.asBroadcastStream()`, or
  ///   2. Using `StreamController.broadcast()` at the producer source, or
  ///   3. Supervising dynamic stream connection lifetimes with [Bloom.managed].
  ///
  /// **Warning (Anti-Pattern Prevention):**
  /// - Do NOT invoke `Bloom.stream(...)` inside Flutter build methods or reactive derivations without caching,
  ///   as it opens and closes redundant stream subscriptions on every frame.
  ///
  /// **BAD:**
  /// ```dart
  /// // [Anti-Pattern] Opening stream subscription inside build method
  /// Widget build(BuildContext context) {
  ///   final stockBloom = Bloom.stream(stockStream); // Re-subscribes every frame!
  ///   return Text('${untracked.state(stockBloom).dataOrNull}');
  /// }
  /// ```
  ///
  /// **GOOD:**
  /// ```dart
  /// // [Recommended] Instantiate Bloom.stream once in a controller or state holder
  /// class StockController {
  ///   late final stockBloom = Bloom.stream(stockStream, initialFactory: () => 0.0);
  /// }
  /// ```
  ///
  /// ## Examples
  /// ```dart
  /// final stockBloom = Bloom.stream(
  ///   stockPriceStream,
  ///   initialFactory: () => 0.0,
  ///   distinct: true,
  /// );
  /// ```
  factory Bloom.stream(
    Stream<T> stream, {
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  }) =>
      _StreamBloomBridge.create<T>(
        stream,
        initialFactory: initialFactory,
        onError: onError,
        cancelOnError: cancelOnError,
        distinct: distinct,
        equals: equals,
        graceful: graceful,
      ).bloom;

  // ===========================================================================
  // Dynamic Triad Namespaced Functor Accessors
  // ===========================================================================

  /// Static entrypoint to the [computed] functor for discoverability and namespace disambiguation.
  ///
  /// ```dart
  /// final sum = Bloom.computed((via) => via(a) + via(b));
  /// final profile = Bloom.computed.future((via) => api.fetchUser(via(id)));
  /// final messages = Bloom.computed.stream((via) => socket.watchMessages(via(room)));
  /// ```
  static const computed = ComputedFunctor._();

  /// Static entrypoint to the [switched] functor for discoverability and namespace disambiguation.
  ///
  /// ```dart
  /// final active = Bloom.switched((via) => via(isVip) ? vipFeed : publicFeed);
  /// ```
  static const switched = SwitchedFunctor._();

  /// Static entrypoint to the [managed] functor for discoverability and namespace disambiguation.
  ///
  /// ```dart
  /// final client = Bloom.managed<HttpClient>(
  ///   create: (via) => HttpClient(),
  ///   dispose: (c) => c.close(),
  /// );
  /// ```
  static const managed = ManagedFunctor._();
}

/// Declarative computation and pipeline transformation operators on [Bloom].
///
/// Provides fluent combinators to decorate reactive nodes with distinct filtering,
/// rate limiting (debounce/throttle), microtask batching, and cache retention policies.
extension BloomComputationExtension<T> on Bloom<T> {
  /// Filters out consecutive duplicate payloads using [equals] (or identical / operator ==).
  ///
  /// During the 2-phase LPDAG lazy-pull evaluation pass, this node pulls the upstream payload
  /// and compares it with the previous payload. If identical, this node's version does not advance
  /// ([_isNewerThan] returns `false`), short-circuiting downstream recomputations.
  ///
  /// ## Data Propagation Flow
  /// ```text
  /// Upstream:   ──[A]──[A]──[B]──[B]──[C]──>
  /// Distinct:   ──[A]───────[B]───────[C]──>
  /// ```
  ///
  /// * [equals]: Optional custom equality comparator. Defaults to `identical(a, b) || a == b`.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<T>] node that only propagates dirty notifications when values change.
  ///
  /// ## Examples
  /// ```dart
  /// final distinctUser = userBloom.distinct((prev, next) => prev.id == next.id);
  /// ```
  @pragma('vm:prefer-inline')
  Bloom<T> distinct([bool Function(T previous, T next)? equals]) => _DistinctBloom<T>(this, equals: equals);

  /// Coalesces multiple synchronous invalidations into a single microtask flush.
  ///
  /// Collapses bursty upstream mutations occurring in the same event-loop turn into
  /// a single downstream dirty pulse, minimizing redundant UI layout and render passes.
  ///
  /// ## Data Propagation Flow
  /// ```text
  /// Upstream (Same Tick): ──[A][B][C]───────────────────────>
  /// Coalesced (Trailing): ──────────────[C (Microtask Flush)]─>
  /// ```
  ///
  /// * [leading]: If `true`, propagates the first dirty pulse immediately upon invalidation.
  /// * [trailing]: If `true`, schedules a deferred dirty pulse on the microtask queue. Defaults to `true`.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<T>] node that batches synchronous invalidation bursts.
  ///
  /// ## Examples
  /// ```dart
  /// final batchedSearch = searchResultsBloom.coalesced();
  /// ```
  @pragma('vm:prefer-inline')
  Bloom<T> coalesced({bool leading = false, bool trailing = true}) =>
      _CoalescedBloom<T>(this, leading: leading, trailing: trailing);

  /// Debounces downstream invalidation pulses across quiet periods of [duration].
  ///
  /// Postpones downstream dirty propagation until [duration] has elapsed without
  /// any new upstream mutations. Useful for search autocomplete queries and window resizing.
  ///
  /// ## Data Propagation Flow
  /// ```text
  /// Upstream:   ──[A]──[B]──[C]────────────────────[D]─────────>
  /// Debounced:  ───────────────────[C (after silence)]────[D]───>
  /// ```
  ///
  /// * [duration]: The quiet window duration to wait before firing.
  /// * [leading]: If `true`, emits an immediate pulse on the first incoming mutation. Defaults to `false`.
  /// * [trailing]: If `true`, emits a pulse after [duration] of silence. Defaults to `true`.
  ///
  /// **Dormant State Semantics (Raw Reads):**
  /// While this node is inactive (unobserved by active terminals or effects), reading
  /// `untracked(node)` or `untracked.state(node)` bypasses temporal timers and synchronously pulls the latest
  /// upstream state on demand (Subscriber-driven Inactive Dormancy).
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<T>] node rate-limiting notifications via debounce.
  ///
  /// ## Examples
  /// ```dart
  /// final debouncedQuery = searchInputBloom.debounced(const Duration(milliseconds: 300));
  /// ```
  @pragma('vm:prefer-inline')
  Bloom<T> debounced(
    Duration duration, {
    bool leading = false,
    bool trailing = true,
  }) =>
      _DebouncedBloom<T>(this, duration, leading: leading, trailing: trailing);

  /// Throttles downstream invalidation pulses to at most once per [duration].
  ///
  /// Enforces a maximum execution frequency across continuous mutation streams
  /// such as scroll listeners, sensor streams, or drag gestures.
  ///
  /// ## Data Propagation Flow
  /// ```text
  /// Upstream:   ──[A]──[B]──[C]──────────[D]──[E]──[F]─────────>
  /// Throttled:  ──[A]───────────────[C]──[D]───────────────[F]──>
  /// ```
  ///
  /// * [duration]: The minimum interval between downstream dirty notifications.
  /// * [leading]: If `true`, emits a pulse immediately on the first event. Defaults to `true`.
  /// * [trailing]: If `true`, emits a pulse at the close of the throttle window if new events arrived. Defaults to `true`.
  ///
  /// **Dormant State Semantics (Raw Reads):**
  /// While this node is inactive (unobserved by active terminals or effects), reading
  /// `untracked(node)` or `untracked.state(node)` bypasses temporal timers and synchronously pulls the latest
  /// upstream state on demand (Subscriber-driven Inactive Dormancy).
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<T>] node rate-limiting notifications via throttle.
  ///
  /// ## Examples
  /// ```dart
  /// final throttledScroll = scrollOffsetBloom.throttled(const Duration(milliseconds: 50));
  /// ```
  @pragma('vm:prefer-inline')
  Bloom<T> throttled(
    Duration duration, {
    bool leading = true,
    bool trailing = true,
  }) =>
      _ThrottledBloom<T>(this, duration, leading: leading, trailing: trailing);

  /// Buffers deactivation of this node with a [graceful] policy when downstream subscribers drop to zero.
  ///
  /// Prevents premature disposal and rapid tear-down/re-setup of expensive upstream resources
  /// (e.g. WebSockets, hardware sensors, camera feeds) during brief UI route transitions or tab switches.
  ///
  /// ## System Architectural Flow
  /// ```text
  /// Subscribers Drop to 0 ──> [Graceful Timer Started]
  ///                                  │
  ///            ┌─────────────────────┴─────────────────────┐
  ///            ▼ (New Subscriber Arrives)                  ▼ (Timer Expires)
  ///    [Timer Cancelled, Node Kept Alive]          [Node Safely Deactivated]
  /// ```
  ///
  /// * [graceful]: The deactivation grace policy configuration. Defaults to [Graceful.microtask] if omitted.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<T>] node shielded by the specified deactivation grace policy.
  ///
  /// ## Examples
  /// ```dart
  /// // 1. Shields against rapid UI route transitions using default microtask deferral:
  /// final resilientNode = liveFeedBloom.graceful();
  ///
  /// // 2. Shields with time-based mooring:
  /// final cachedFeed = liveFeedBloom.graceful(
  ///   const Graceful.period(Duration(seconds: 30)),
  /// );
  /// ```
  @pragma('vm:prefer-inline')
  Bloom<T> graceful([
    Graceful graceful = Graceful.microtask,
  ]) =>
      _GracefulBloom<T>(this, graceful: graceful);

  /// Creates a retained node maintaining prior valid data during pending re-evaluations (SWR).
  ///
  /// Implements the Stale-While-Revalidate pattern by masking intermediate Empty states
  /// while an upstream asynchronous refresh is in progress, ensuring zero UI flickering.
  ///
  /// ## System Architectural Flow
  /// ```text
  /// Upstream:   [Data 1] ───> [Empty (Pending Fetch)] ───> [Data 2]
  /// Retained:   [Data 1] ───> [Data 1 (Retained)]    ───> [Data 2]
  /// Pending:    (false)  ───> (true)                 ───> (false)
  /// ```
  ///
  /// * [pending]: Optional [BloomCoupler<bool>] dynamically synchronized with the internal pending facet.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<T>] node preserving the last valid payload across pending recomputations.
  ///
  /// ## Examples
  /// ```dart
  /// final pendingCoupler = BloomCoupler<bool>.late();
  /// final swrFeed = remoteFeedBloom.retained(pending: pendingCoupler);
  /// ```
  @pragma('vm:prefer-inline')
  Bloom<T> retained({BloomCoupler<bool>? pending}) => _RetainedBloom<T>(this, pending);
}

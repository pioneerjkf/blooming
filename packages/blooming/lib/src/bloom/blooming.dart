// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// Top-Level State Producer Instantiation Functor (blooming)
// =============================================================================

/// Core declarative state producer instantiation functor for the Bloom reactive DAG engine.
///
/// Serves as the primary unified ergonomic entry point for creating distinct-filtered
/// state producers ([BloomController]), high-throughput raw producers ([RawBloomController]),
/// transactional reactive collections ([BloomListController], [BloomSetController],
/// and [BloomMapController]), and discrete event triggers ([BloomSignalController]).
///
/// ## System Architectural Flow
/// ```text
/// [User Input / Event] ──> blooming(0) ──> [BloomController<int>]
///                                            ├─ .data = 1  ──> [Push-Dirty Pulse]
///                                            └─ .bloom     ──> [Read-Only Bloom<int>]
/// ```
///
/// ## Architectural Benefits
/// 1. **Unified Functor Ecosystem**: Unifies state creation with reactive pipeline functors
///    ([computed], [switched], [managed], [untracked]) under a consistent lowercase entry point.
/// 2. **Hierarchical Sub-Functor Pathways**: Combines state storage kinds
///    (scalar, raw, list, set, map) with initialization states (immediate, late, error),
///    alongside discrete event notification triggers ([BloomingFunctor.signal]).
/// 3. **Producer/Consumer Separation**: Instantiates encapsulated state producers while
///    preserving strict CQRS boundaries (downstream consumers receive read-only `.bloom`).
/// 4. **Zero Functor Abstraction Overhead**: All functor instances are compile-time constants
///    with `@pragma('vm:prefer-inline')` call methods, compiling directly down to native
///    controller instantiation without intermediate closure or wrapper allocations.
///
/// ## Sub-Functor & Factory Pathways
/// ```text
/// blooming(...)               ──> Distinct-filtered scalar state ([BloomController])
///   ├─ .late(...)             ──> Uninitialized empty scalar state ([BloomController.late])
///   ├─ .error(...)            ──> Pre-faulted error scalar state ([BloomController.error])
///   ├─ .raw(...)              ──> Unfiltered high-throughput state ([RawBloomController])
///   │    ├─ .late(...)        ──> Uninitialized raw state ([RawBloomController.late])
///   │    └─ .error(...)       ──> Pre-faulted raw state ([RawBloomController.error])
///   ├─ .list(...)             ──> Transactional reactive list ([BloomListController])
///   │    ├─ .late(...)        ──> Uninitialized reactive list ([BloomListController.late])
///   │    └─ .error(...)       ──> Pre-faulted reactive list ([BloomListController.error])
///   ├─ .set(...)              ──> Transactional reactive set ([BloomSetController])
///   │    ├─ .late(...)        ──> Uninitialized reactive set ([BloomSetController.late])
///   │    └─ .error(...)       ──> Pre-faulted reactive set ([BloomSetController.error])
///   ├─ .map(...)              ──> Transactional reactive map ([BloomMapController])
///   │    ├─ .late(...)        ──> Uninitialized reactive map ([BloomMapController.late])
///   │    └─ .error(...)       ──> Pre-faulted reactive map ([BloomMapController.error])
///   └─ .signal(...)           ──> Discrete event notification signal ([BloomSignalController])
/// ```
///
/// See [BloomingFunctor.call] for primary distinct state creation details.
///
/// ## Examples
/// ```dart
/// // 1. Distinct-filtered scalar state
/// final counter = blooming(0);
/// counter.data = 1;
///
/// // 2. Uninitialized late state
/// final user = blooming.late<User>(reason: 'AwaitingAuthentication');
///
/// // 3. Transactional collection state
/// final todos = blooming.list<String>(['Task 1', 'Task 2']);
/// todos.edit((draft) => draft.add('Task 3'));
/// ```
const blooming = BloomingFunctor._();

/// Callable implementation class for the top-level [blooming] state creation functor.
@immutable
final class BloomingFunctor {
  const BloomingFunctor._();

  /// Sub-functor for unfiltered high-throughput state producers ([RawBloomController]).
  BloomingRawFunctor get raw => const BloomingRawFunctor._();

  /// Sub-functor for transactional reactive list state producers ([BloomListController]).
  BloomingListFunctor get list => const BloomingListFunctor._();

  /// Sub-functor for transactional reactive set state producers ([BloomSetController]).
  BloomingSetFunctor get set => const BloomingSetFunctor._();

  /// Sub-functor for transactional reactive map state producers ([BloomMapController]).
  BloomingMapFunctor get map => const BloomingMapFunctor._();

  /// Sub-functor for discrete event notification signals ([BloomSignalController]).
  BloomingSignalFunctor get signal => const BloomingSignalFunctor._();

  /// Creates a distinct-filtered [BloomController] initialized with [data].
  ///
  /// Filters out duplicate consecutive value assignments using [equals]
  /// (or identical / operator ==) to suppress redundant downstream dirty pulses.
  ///
  /// * [data]: The initial value to populate the node with.
  /// * [distinct]: When `true`, suppresses dirty notifications on identical values.
  ///   Defaults to `true`.
  /// * [equals]: Custom equality comparator used when [distinct] is `true`.
  /// * [onActivated]: Callback triggered when the first downstream subscriber connects.
  /// * [onDeactivated]: Callback triggered when all downstream subscribers disconnect.
  /// * [graceful]: Optional [Graceful] policy delaying deactivation when subscribers drop to zero.
  ///
  /// **Ensures:**
  /// * Returns an active [BloomController] in the Data state ([BloomState.hasData] == true).
  ///
  /// **Warning (Anti-Pattern Prevention):**
  /// - Do NOT instantiate `blooming(...)` inside Flutter `build()` methods or derivation closures;
  ///   always cache instances in `final` class fields or state controllers.
  ///
  /// **BAD:**
  /// ```dart
  /// // [Anti-Pattern] Per-frame state re-instantiation in build (state reset)
  /// Widget build(BuildContext context) {
  ///   final count = blooming(0); // State lost on every render!
  ///   return Text('${untracked(count.bloom)}');
  /// }
  /// ```
  ///
  /// **GOOD:**
  /// ```dart
  /// // [Recommended] Cached in controller/store field and exposed via read-only bloom view
  /// class CounterStore {
  ///   final _count = blooming(0);
  ///   Bloom<int> get count => _count.bloom;
  /// }
  /// ```
  @pragma('vm:prefer-inline')
  BloomController<T> call<T>(
    T data, {
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    void Function()? onActivated,
    void Function()? onDeactivated,
    Graceful? graceful,
  }) =>
      BloomController<T>(
        data,
        distinct: distinct,
        equals: equals,
        onActivated: onActivated,
        onDeactivated: onDeactivated,
        graceful: graceful,
      );

  /// Creates a distinct-filtered [BloomController] in an uninitialized (Empty) state.
  ///
  /// Useful for asynchronous resources or data fetched after initialization. Reading `.data`
  /// before setting a value throws [BloomEmptyExtractionException].
  ///
  /// * [reason]: Optional reason explaining why this controller is uninitialized or empty.
  /// * [distinct]: When `true`, suppresses dirty notifications on identical values.
  ///   Defaults to `true`.
  /// * [equals]: Custom equality comparator used when [distinct] is `true`.
  /// * [onActivated]: Callback triggered when the first downstream subscriber connects.
  /// * [onDeactivated]: Callback triggered when all downstream subscribers disconnect.
  /// * [graceful]: Optional [Graceful] policy delaying deactivation when subscribers drop to zero.
  ///
  /// **Ensures:**
  /// * Returns a [BloomController] initialized in the Empty state
  ///   ([BloomState.isEmpty] == true).
  ///
  /// **Throws:**
  /// * Reading [BloomController.data] before setting a value throws
  ///   [BloomEmptyExtractionException]. Use [BloomState.dataOrNull] or
  ///   [BloomState.dataOrElse] for safe total inspection.
  @pragma('vm:prefer-inline')
  BloomController<T> late<T>({
    Object? reason,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    void Function()? onActivated,
    void Function()? onDeactivated,
    Graceful? graceful,
  }) =>
      BloomController<T>.late(
        reason: reason,
        distinct: distinct,
        equals: equals,
        onActivated: onActivated,
        onDeactivated: onDeactivated,
        graceful: graceful,
      );

  /// Creates a distinct-filtered [BloomController] initialized in an Error state.
  ///
  /// * [error]: The initial exception or error payload.
  /// * [stackTrace]: Optional stack trace associated with the failure.
  /// * [distinct]: When `true`, suppresses dirty notifications on identical values.
  ///   Defaults to `true`.
  /// * [equals]: Custom equality comparator used when [distinct] is `true`.
  /// * [onActivated]: Callback triggered when the first downstream subscriber connects.
  /// * [onDeactivated]: Callback triggered when all downstream subscribers disconnect.
  /// * [graceful]: Optional [Graceful] policy delaying deactivation when subscribers drop to zero.
  ///
  /// **Ensures:**
  /// * Returns a [BloomController] initialized in the Error state
  ///   ([BloomState.hasError] == true).
  ///
  /// **Throws:**
  /// * Reading [BloomController.data] while in the Error state throws
  ///   [BloomErrorExtractionException]. Inspect [BloomState.error] or
  ///   use [BloomState.dataOrNull] for safe recovery.
  @pragma('vm:prefer-inline')
  BloomController<T> error<T>(
    Object error, {
    StackTrace? stackTrace,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    void Function()? onActivated,
    void Function()? onDeactivated,
    Graceful? graceful,
  }) =>
      BloomController<T>.error(
        error,
        stackTrace: stackTrace,
        distinct: distinct,
        equals: equals,
        onActivated: onActivated,
        onDeactivated: onDeactivated,
        graceful: graceful,
      );
}

// =============================================================================
// Sub-Functor: blooming.raw
// =============================================================================

/// Sub-functor managing unfiltered high-throughput state producers ([RawBloomController]).
///
/// Bypasses equality checks entirely for ultra-hot mutation sequences or in-place mutable objects.
@immutable
final class BloomingRawFunctor {
  const BloomingRawFunctor._();

  /// Creates an unfiltered [RawBloomController] initialized with [data].
  ///
  /// Bypasses equality checks entirely for high-throughput mutation sequences
  /// or in-place mutable objects.
  ///
  /// * [data]: The initial value to populate the node with.
  /// * [onActivated]: Callback triggered when the first downstream subscriber connects.
  /// * [onDeactivated]: Callback triggered when all downstream subscribers disconnect.
  /// * [graceful]: Optional [Graceful] policy delaying deactivation when subscribers drop to zero.
  ///
  /// **Ensures:**
  /// * Returns an unfiltered [RawBloomController] in the Data state
  ///   ([BloomState.hasData] == true).
  @pragma('vm:prefer-inline')
  RawBloomController<T> call<T>(
    T data, {
    void Function()? onActivated,
    void Function()? onDeactivated,
    Graceful? graceful,
  }) =>
      RawBloomController<T>(
        data,
        onActivated: onActivated,
        onDeactivated: onDeactivated,
        graceful: graceful,
      );

  /// Creates an unfiltered [RawBloomController] in an uninitialized (Empty) state.
  ///
  /// * [reason]: Optional reason explaining why this controller is uninitialized or empty.
  /// * [onActivated]: Callback triggered when the first downstream subscriber connects.
  /// * [onDeactivated]: Callback triggered when all downstream subscribers disconnect.
  /// * [graceful]: Optional [Graceful] policy delaying deactivation when subscribers drop to zero.
  ///
  /// **Ensures:**
  /// * Returns an unfiltered [RawBloomController] initialized in the Empty state.
  ///
  /// **Throws:**
  /// * Reading [RawBloomController.data] before setting a value throws
  ///   [BloomEmptyExtractionException].
  @pragma('vm:prefer-inline')
  RawBloomController<T> late<T>({
    Object? reason,
    void Function()? onActivated,
    void Function()? onDeactivated,
    Graceful? graceful,
  }) =>
      RawBloomController<T>.late(
        reason: reason,
        onActivated: onActivated,
        onDeactivated: onDeactivated,
        graceful: graceful,
      );

  /// Creates an unfiltered [RawBloomController] initialized in an Error state.
  ///
  /// * [error]: The initial exception or error payload.
  /// * [stackTrace]: Optional stack trace associated with the failure.
  /// * [onActivated]: Callback triggered when the first downstream subscriber connects.
  /// * [onDeactivated]: Callback triggered when all downstream subscribers disconnect.
  /// * [graceful]: Optional [Graceful] policy delaying deactivation when subscribers drop to zero.
  ///
  /// **Ensures:**
  /// * Returns an unfiltered [RawBloomController] initialized in the Error state.
  ///
  /// **Throws:**
  /// * Reading [RawBloomController.data] while in the Error state throws
  ///   [BloomErrorExtractionException]. Inspect [BloomState.error] for details.
  @pragma('vm:prefer-inline')
  RawBloomController<T> error<T>(
    Object error, {
    StackTrace? stackTrace,
    void Function()? onActivated,
    void Function()? onDeactivated,
    Graceful? graceful,
  }) =>
      RawBloomController<T>.error(
        error,
        stackTrace: stackTrace,
        onActivated: onActivated,
        onDeactivated: onDeactivated,
        graceful: graceful,
      );
}

// =============================================================================
// Sub-Functor: blooming.list
// =============================================================================

/// Sub-functor managing transactional reactive list state producers ([BloomListController]).
///
/// Provides transactional draft `.edit((draft) => ...)` editing and
/// automatic unmodifiable freezing.
@immutable
final class BloomingListFunctor {
  const BloomingListFunctor._();

  /// Creates a [BloomListController] initialized with [data].
  ///
  /// Freezes [data] into an unmodifiable list to enforce transactional immutability.
  /// Mutate elements strictly via [BloomListController.edit].
  ///
  /// * [data]: The initial collection elements to populate this controller with.
  /// * [equals]: Optional custom equality comparator (e.g. for nested collections).
  ///
  /// **Ensures:**
  /// * Returns a [BloomListController] initialized in the Data state with an unmodifiable list.
  ///
  /// **Throws:**
  /// * Attempting to mutate [BloomListController.data] directly throws [UnsupportedError].
  ///   Always apply modifications inside a [BloomListController.edit] draft.
  @pragma('vm:prefer-inline')
  BloomListController<T> call<T>(
    Iterable<T> data, {
    bool Function(List<T> previous, List<T> next)? equals,
  }) =>
      BloomListController<T>(data, equals: equals);

  /// Creates an uninitialized (Empty) [BloomListController].
  ///
  /// * [equals]: Optional custom equality comparator.
  ///
  /// **Ensures:**
  /// * Returns an empty [BloomListController] awaiting initial assignment.
  @pragma('vm:prefer-inline')
  BloomListController<T> late<T>({
    bool Function(List<T> previous, List<T> next)? equals,
  }) =>
      BloomListController<T>.late(equals: equals);

  /// Creates a [BloomListController] in an Error state.
  ///
  /// * [error]: The caught failure or exception object.
  /// * [stackTrace]: Optional stack trace associated with the failure.
  /// * [equals]: Optional custom equality comparator.
  ///
  /// **Ensures:**
  /// * Returns a [BloomListController] initialized in the Error state.
  @pragma('vm:prefer-inline')
  BloomListController<T> error<T>(
    Object error, {
    StackTrace? stackTrace,
    bool Function(List<T> previous, List<T> next)? equals,
  }) =>
      BloomListController<T>.error(
        error,
        stackTrace: stackTrace,
        equals: equals,
      );
}

// =============================================================================
// Sub-Functor: blooming.set
// =============================================================================

/// Sub-functor managing transactional reactive set state producers ([BloomSetController]).
///
/// Provides transactional draft `.edit((draft) => ...)` editing and
/// automatic unmodifiable freezing.
@immutable
final class BloomingSetFunctor {
  const BloomingSetFunctor._();

  /// Creates a [BloomSetController] initialized with [data].
  ///
  /// Freezes [data] into an unmodifiable set to enforce transactional immutability.
  /// Mutate elements strictly via [BloomSetController.edit].
  ///
  /// * [data]: The initial set elements to populate this controller with.
  /// * [equals]: Optional custom equality comparator.
  ///
  /// **Ensures:**
  /// * Returns a [BloomSetController] initialized in the Data state with an unmodifiable set.
  ///
  /// **Throws:**
  /// * Attempting to mutate [BloomSetController.data] directly throws [UnsupportedError].
  ///   Always apply modifications inside a [BloomSetController.edit] draft.
  @pragma('vm:prefer-inline')
  BloomSetController<E> call<E>(
    Iterable<E> data, {
    bool Function(Set<E> previous, Set<E> next)? equals,
  }) =>
      BloomSetController<E>(data, equals: equals);

  /// Creates an uninitialized (Empty) [BloomSetController].
  ///
  /// * [equals]: Optional custom equality comparator.
  ///
  /// **Ensures:**
  /// * Returns an empty [BloomSetController] awaiting initial assignment.
  @pragma('vm:prefer-inline')
  BloomSetController<E> late<E>({
    bool Function(Set<E> previous, Set<E> next)? equals,
  }) =>
      BloomSetController<E>.late(equals: equals);

  /// Creates a [BloomSetController] in an Error state.
  ///
  /// * [error]: The caught failure or exception object.
  /// * [stackTrace]: Optional stack trace associated with the failure.
  /// * [equals]: Optional custom equality comparator.
  ///
  /// **Ensures:**
  /// * Returns a [BloomSetController] initialized in the Error state.
  @pragma('vm:prefer-inline')
  BloomSetController<E> error<E>(
    Object error, {
    StackTrace? stackTrace,
    bool Function(Set<E> previous, Set<E> next)? equals,
  }) =>
      BloomSetController<E>.error(
        error,
        stackTrace: stackTrace,
        equals: equals,
      );
}

// =============================================================================
// Sub-Functor: blooming.map
// =============================================================================

/// Sub-functor managing transactional reactive map state producers ([BloomMapController]).
///
/// Provides transactional draft `.edit((draft) => ...)` editing and
/// automatic unmodifiable freezing.
@immutable
final class BloomingMapFunctor {
  const BloomingMapFunctor._();

  /// Creates a [BloomMapController] initialized with [data].
  ///
  /// Freezes [data] into an unmodifiable map to enforce transactional immutability.
  /// Mutate key-value pairs strictly via [BloomMapController.edit].
  ///
  /// * [data]: The initial key-value map to populate this controller with.
  /// * [equals]: Optional custom equality comparator.
  ///
  /// **Ensures:**
  /// * Returns a [BloomMapController] initialized in the Data state with an unmodifiable map.
  ///
  /// **Throws:**
  /// * Attempting to mutate [BloomMapController.data] directly throws [UnsupportedError].
  ///   Always apply modifications inside a [BloomMapController.edit] draft.
  @pragma('vm:prefer-inline')
  BloomMapController<K, V> call<K, V>(
    Map<K, V> data, {
    bool Function(Map<K, V> previous, Map<K, V> next)? equals,
  }) =>
      BloomMapController<K, V>(data, equals: equals);

  /// Creates an uninitialized (Empty) [BloomMapController].
  ///
  /// * [equals]: Optional custom equality comparator.
  ///
  /// **Ensures:**
  /// * Returns an empty [BloomMapController] awaiting initial assignment.
  @pragma('vm:prefer-inline')
  BloomMapController<K, V> late<K, V>({
    bool Function(Map<K, V> previous, Map<K, V> next)? equals,
  }) =>
      BloomMapController<K, V>.late(equals: equals);

  /// Creates a [BloomMapController] in an Error state.
  ///
  /// * [error]: The caught failure or exception object.
  /// * [stackTrace]: Optional stack trace associated with the failure.
  /// * [equals]: Optional custom equality comparator.
  ///
  /// **Ensures:**
  /// * Returns a [BloomMapController] initialized in the Error state.
  @pragma('vm:prefer-inline')
  BloomMapController<K, V> error<K, V>(
    Object error, {
    StackTrace? stackTrace,
    bool Function(Map<K, V> previous, Map<K, V> next)? equals,
  }) =>
      BloomMapController<K, V>.error(
        error,
        stackTrace: stackTrace,
        equals: equals,
      );
}

// =============================================================================
// Sub-Functor: blooming.signal
// =============================================================================

/// Sub-functor managing discrete reactive event triggers ([BloomSignalController]).
///
/// Emits monotonic sequence ticks on `.emit()` to notify downstream
/// subscribers without maintaining state payload.
@immutable
final class BloomingSignalFunctor {
  const BloomingSignalFunctor._();

  /// Creates a discrete event notification signal producer handle.
  ///
  /// Discrete signals emit monotonic version sequence ticks on [BloomSignalController.emit]
  /// to trigger downstream derivations without maintaining state payload.
  ///
  /// * [onActivated]: Callback triggered when the signal transitions from 0 to 1
  ///   active downstream subscriber.
  /// * [onDeactivated]: Callback triggered when the signal drops to 0 active subscribers.
  ///
  /// **Ensures:**
  /// * Returns an active [BloomSignalController].
  @pragma('vm:prefer-inline')
  BloomSignalController call({
    void Function()? onActivated,
    void Function()? onDeactivated,
  }) =>
      BloomSignalController(
        onActivated: onActivated,
        onDeactivated: onDeactivated,
      );
}

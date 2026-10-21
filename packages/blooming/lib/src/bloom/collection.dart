// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// Reactive Collection Controllers (List, Set, Map)
// =============================================================================

/// Producer controller managing a reactive collection of elements ([List<T>]).
///
/// Combines zero-overhead immutable replacement ([set], [data]) with
/// transactional draft edits ([edit], [editGuarded]).
///
/// ## System Architectural Flow
/// ```text
/// [BloomListController] ──> .edit((draft) { draft.add(item); })
///                                  │
///                                  ▼ (Compares Equality with Previous)
///                       [Modified? ── Yes ──> Freezes List.unmodifiable & Push-Dirty (1 Pulse)]
///                                  └── No   ──> No-Op (Zero Downstream Recomputations)
/// ```
///
/// ## Architectural Benefits
/// 1. **Atomic Draft Transactions**: Edits are applied to an isolated draft buffer and committed in a single pulse.
/// 2. **Deep/Shallow Equality Guarding**: Suppresses downstream notifications if the draft results in no net changes.
/// 3. **Immutability Enforcement**: The underlying payload is stored as [List.unmodifiable] to prevent external mutation leaks.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT attempt to mutate `.data` in-place directly (e.g. `controller.data.add(...)`), as `.data` returns an
///   unmodifiable list and throws an [UnsupportedError]. Always use [edit] or assign a new list via `.data = [...]`.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Mutating unmodifiable list directly throws UnsupportedError
/// final listCtrl = BloomListController<int>([1, 2]);
/// listCtrl.data.add(3); // Throws UnsupportedError!
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Use transactional edit to safely mutate draft and commit
/// final listCtrl = BloomListController<int>([1, 2]);
/// listCtrl.edit((draft) => draft.add(3)); // Commits atomically as immutable list
/// ```
///
/// ## Examples
/// ```dart
/// final numbers = BloomListController<int>([1, 2, 3]);
/// numbers.edit((draft) {
///   draft.add(4);
///   draft.remove(1);
/// });
/// print(numbers.data); // [2, 3, 4]
/// ```
abstract base class BloomListController<T> implements BloomController<List<T>> {
  /// Creates a [BloomListController] initialized with [data].
  ///
  /// * [data]: The initial collection elements to populate this controller with.
  /// * [equals]: Optional custom equality comparator (e.g. for nested collections or deep comparison).
  ///
  /// **Ensures:**
  /// * Returns a [BloomListController<T>] initialized in the Data state with an unmodifiable list.
  factory BloomListController(
    Iterable<T> data, {
    bool Function(List<T> previous, List<T> next)? equals,
  }) = _BloomListControllerImpl<T>;

  /// Creates an uninitialized (Empty) [BloomListController].
  ///
  /// * [equals]: Optional custom equality comparator.
  ///
  /// **Ensures:**
  /// * Returns an empty [BloomListController<T>] awaiting initial assignment.
  factory BloomListController.late({
    bool Function(List<T> previous, List<T> next)? equals,
  }) = _BloomListControllerImpl<T>.late;

  /// Creates a [BloomListController] in an Error state.
  ///
  /// * [error]: The caught failure or exception object.
  /// * [stackTrace]: Optional stack trace associated with the failure.
  /// * [equals]: Optional custom equality comparator.
  ///
  /// **Ensures:**
  /// * Returns a [BloomListController<T>] initialized in the Error state.
  factory BloomListController.error(
    Object error, {
    StackTrace? stackTrace,
    bool Function(List<T> previous, List<T> next)? equals,
  }) = _BloomListControllerImpl<T>.error;

  /// Edits the current collection in-place via a temporary draft buffer.
  ///
  /// The [recipe] callback receives a mutable copy of the current list.
  /// Upon completion, changes are compared via equality (`equals` or `_listEquals`).
  /// If modified, the new collection is frozen as an unmodifiable list and
  /// commits at most one Push-Dirty invalidation downstream.
  void edit(void Function(List<T> draft) recipe);

  /// Safely executes [recipe] on a temporary draft buffer and commits modifications,
  /// or catches any thrown exceptions and transitions this controller to an error state.
  void editGuarded(void Function(List<T> draft) recipe);

  @override
  Bloom<List<T>> get bloom;
}

/// Producer controller managing a reactive set of unique elements ([Set<E>]).
///
/// Combines zero-overhead immutable replacement ([set], [data]) with
/// transactional draft edits ([edit], [editGuarded]).
///
/// ## System Architectural Flow
/// ```text
/// [BloomSetController] ──> .edit((draft) { draft.add(item); })
///                                 │
///                                 ▼ (Compares Equality with Previous)
///                      [Modified? ── Yes ──> Freezes Set.unmodifiable & Push-Dirty (1 Pulse)]
///                                 └── No   ──> No-Op (Zero Downstream Recomputations)
/// ```
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT attempt to mutate `.data` in-place directly; always use [edit] or assign a new set.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] In-place mutation throws UnsupportedError on unmodifiable set
/// final setCtrl = BloomSetController<String>({'a'});
/// setCtrl.data.add('b'); // Throws UnsupportedError!
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Use edit to safely mutate draft
/// final setCtrl = BloomSetController<String>({'a'});
/// setCtrl.edit((draft) => draft.add('b'));
/// ```
///
/// ## Examples
/// ```dart
/// final tags = BloomSetController<String>({'flutter', 'dart'});
/// tags.edit((draft) => draft.add('reactive'));
/// print(tags.data); // {'flutter', 'dart', 'reactive'}
/// ```
abstract base class BloomSetController<E> implements BloomController<Set<E>> {
  /// Creates a [BloomSetController] initialized with [data].
  ///
  /// * [data]: The initial set elements to populate this controller with.
  /// * [equals]: Optional custom equality comparator (e.g. for nested collections).
  ///
  /// **Ensures:**
  /// * Returns a [BloomSetController<E>] initialized in the Data state with an unmodifiable set.
  factory BloomSetController(
    Iterable<E> data, {
    bool Function(Set<E> previous, Set<E> next)? equals,
  }) = _BloomSetControllerImpl<E>;

  /// Creates an uninitialized (Empty) [BloomSetController].
  ///
  /// * [equals]: Optional custom equality comparator.
  ///
  /// **Ensures:**
  /// * Returns an empty [BloomSetController<E>] awaiting initial assignment.
  factory BloomSetController.late({
    bool Function(Set<E> previous, Set<E> next)? equals,
  }) = _BloomSetControllerImpl<E>.late;

  /// Creates a [BloomSetController] in an Error state.
  ///
  /// * [error]: The caught failure or exception object.
  /// * [stackTrace]: Optional stack trace associated with the failure.
  /// * [equals]: Optional custom equality comparator.
  ///
  /// **Ensures:**
  /// * Returns a [BloomSetController<E>] initialized in the Error state.
  factory BloomSetController.error(
    Object error, {
    StackTrace? stackTrace,
    bool Function(Set<E> previous, Set<E> next)? equals,
  }) = _BloomSetControllerImpl<E>.error;

  /// Edits the current set in-place via a temporary draft buffer.
  ///
  /// The [recipe] callback receives a mutable copy of the current set.
  /// Upon completion, changes are compared via equality (`equals` or `_setEquals`).
  /// If modified, the new collection is frozen as an unmodifiable set and
  /// commits at most one Push-Dirty invalidation downstream.
  void edit(void Function(Set<E> draft) recipe);

  /// Safely executes [recipe] on a temporary draft buffer and commits modifications,
  /// or catches any thrown exceptions and transitions this controller to an error state.
  void editGuarded(void Function(Set<E> draft) recipe);

  @override
  Bloom<Set<E>> get bloom;
}

/// Producer controller managing a reactive key-value dictionary ([Map<K, V>]).
///
/// Combines zero-overhead immutable replacement ([set], [data]) with
/// transactional draft edits ([edit], [editGuarded]).
///
/// ## System Architectural Flow
/// ```text
/// [BloomMapController] ──> .edit((draft) { draft[key] = value; })
///                                 │
///                                 ▼ (Compares Equality with Previous)
///                      [Modified? ── Yes ──> Freezes Map.unmodifiable & Push-Dirty (1 Pulse)]
///                                 └── No   ──> No-Op (Zero Downstream Recomputations)
/// ```
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT attempt to mutate `.data` in-place directly; always use [edit] or assign a new map.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] In-place mutation throws UnsupportedError on unmodifiable map
/// final mapCtrl = BloomMapController<String, int>({'a': 1});
/// mapCtrl.data['b'] = 2; // Throws UnsupportedError!
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Use edit to safely mutate draft
/// final mapCtrl = BloomMapController<String, int>({'a': 1});
/// mapCtrl.edit((draft) => draft['b'] = 2);
/// ```
///
/// ## Examples
/// ```dart
/// final scores = BloomMapController<String, int>({'Alice': 90});
/// scores.edit((draft) => draft['Bob'] = 85);
/// print(scores.data); // {'Alice': 90, 'Bob': 85}
/// ```
abstract base class BloomMapController<K, V> implements BloomController<Map<K, V>> {
  /// Creates a [BloomMapController] initialized with [data].
  ///
  /// * [data]: The initial key-value map to populate this controller with.
  /// * [equals]: Optional custom equality comparator (e.g. for nested collections).
  ///
  /// **Ensures:**
  /// * Returns a [BloomMapController<K, V>] initialized in the Data state with an unmodifiable map.
  factory BloomMapController(
    Map<K, V> data, {
    bool Function(Map<K, V> previous, Map<K, V> next)? equals,
  }) = _BloomMapControllerImpl<K, V>;

  /// Creates an uninitialized (Empty) [BloomMapController].
  ///
  /// * [equals]: Optional custom equality comparator.
  ///
  /// **Ensures:**
  /// * Returns an empty [BloomMapController<K, V>] awaiting initial assignment.
  factory BloomMapController.late({
    bool Function(Map<K, V> previous, Map<K, V> next)? equals,
  }) = _BloomMapControllerImpl<K, V>.late;

  /// Creates a [BloomMapController] in an Error state.
  ///
  /// * [error]: The caught failure or exception object.
  /// * [stackTrace]: Optional stack trace associated with the failure.
  /// * [equals]: Optional custom equality comparator.
  ///
  /// **Ensures:**
  /// * Returns a [BloomMapController<K, V>] initialized in the Error state.
  factory BloomMapController.error(
    Object error, {
    StackTrace? stackTrace,
    bool Function(Map<K, V> previous, Map<K, V> next)? equals,
  }) = _BloomMapControllerImpl<K, V>.error;

  /// Edits the current map in-place via a temporary draft buffer.
  ///
  /// The [recipe] callback receives a mutable copy of the current map.
  /// Upon completion, changes are compared via equality (`equals` or `_mapEquals`).
  /// If modified, the new collection is frozen as an unmodifiable map and
  /// commits at most one Push-Dirty invalidation downstream.
  void edit(void Function(Map<K, V> draft) recipe);

  /// Safely executes [recipe] on a temporary draft buffer and commits modifications,
  /// or catches any thrown exceptions and transitions this controller to an error state.
  void editGuarded(void Function(Map<K, V> draft) recipe);

  @override
  Bloom<Map<K, V>> get bloom;
}

// =============================================================================
// Reactive Iterable & Collection Operators
// =============================================================================

/// Core aggregation extension for [Bloom] holding any [Iterable] collection.
extension BloomIterableComputationExtension<T> on Bloom<Iterable<T>> {
  /// Reduces multiple inbound elements into a reactive [Bloom<R>].
  ///
  /// * [aggregator]: Transformation callback reducing the collection elements into a single result [R].
  ///
  /// **Ensures:**
  /// * Returns a reactive [Bloom<R>] reflecting the aggregated result.
  Bloom<R> aggregate<R>(R Function(Iterable<T> elements) aggregator) => computed((via) => aggregator(via(this)));
}

/// Reactive collection operators on a collection of [Bloom] nodes (`Bloom<Iterable<Bloom<T>>>`).
extension BloomIterableBloomExtension<T> on Bloom<Iterable<Bloom<T>>> {
  /// Unifies all member payloads into a reactive [Bloom<List<T>>].
  ///
  /// **Ensures:**
  /// * Returns a reactive [Bloom<List<T>>] bundling all member payloads into an unmodifiable list.
  Bloom<List<T>> combine() => computed((via) => List<T>.unmodifiable(via(this).map((e) => via(e))));

  /// Folds the payloads of all members into a single reactive [Bloom<R>].
  ///
  /// * [initialValue]: The initial accumulator value.
  /// * [combine]: The folder function combining accumulator and current element payload.
  ///
  /// **Ensures:**
  /// * Returns a reactive [Bloom<R>] holding the folded result.
  Bloom<R> fold<R>(R initialValue, R Function(R accumulator, T item) combine) =>
      computed((via) => via(this).fold(initialValue, (acc, item) => combine(acc, via(item))));

  /// Reduces the payloads of all members into a single reactive [Bloom<T>].
  ///
  /// * [combine]: The reducer function combining previous and current element payloads.
  ///
  /// **Requires:**
  /// * The collection must not be empty when evaluated.
  ///
  /// **Ensures:**
  /// * Returns a reactive [Bloom<T>] holding the reduced payload.
  Bloom<T> reduce(T Function(T previous, T current) combine) =>
      computed((via) => via(this).map((e) => via(e)).reduce(combine));

  /// Evaluates whether every element in the collection satisfies [predicate].
  ///
  /// * [predicate]: Optional predicate testing each element payload. If omitted and elements are [bool], checks truthiness.
  ///
  /// **Ensures:**
  /// * Returns a reactive [Bloom<bool>] evaluating to `true` if all elements satisfy the predicate.
  Bloom<bool> every([bool Function(T item)? predicate]) => computed((via) {
        for (final item in via(this)) {
          final val = via(item);
          if (predicate != null) {
            if (!predicate(val)) return false;
          } else if (val is bool) {
            if (!val) return false;
          }
        }
        return true;
      });

  /// Evaluates whether at least one element in the collection satisfies [predicate].
  ///
  /// * [predicate]: Optional predicate testing each element payload. If omitted and elements are [bool], checks truthiness.
  ///
  /// **Ensures:**
  /// * Returns a reactive [Bloom<bool>] evaluating to `true` if at least one element satisfies the predicate.
  Bloom<bool> any([bool Function(T item)? predicate]) => computed((via) {
        for (final item in via(this)) {
          final val = via(item);
          if (predicate != null) {
            if (predicate(val)) return true;
          } else if (val is bool) {
            if (val) return true;
          }
        }
        return false;
      });
}

/// Reactive numeric aggregation extensions on a collection of numeric [Bloom] nodes.
extension BloomIterableBloomNumericExtension<T extends num> on Bloom<Iterable<Bloom<T>>> {
  /// Aggregates all numbers in the collection into their mathematical sum as a reactive [Bloom<T>].
  ///
  /// **Ensures:**
  /// * Returns a reactive [Bloom<T>] holding the mathematical sum of all member payloads.
  Bloom<T> sum() => computed((via) {
        T total = (T == double ? 0.0 : 0) as T;
        for (final item in via(this)) {
          total = (total + via(item)) as T;
        }
        return total;
      });
}

// =============================================================================
// Dart Iterable Convenience Extensions (Nodes, Controllers, Snapshots, States)
// =============================================================================

/// Convenience data extraction extensions on an [Iterable] of [BloomState] entities
/// (such as [BloomController], [BloomSnapshot], [RawBloomTerminal], or [Computation]).
extension BloomStateCollectionPayloadExtension<T> on Iterable<BloomState<T>> {
  /// Extracts the underlying data synchronously from all [BloomState] entities in this collection.
  ///
  /// **Requires:**
  /// * Every entity in this collection must be in a [BloomState.hasData] state.
  ///
  /// **Throws:**
  /// * [BloomSnapshotExtractionException] if any entity is in an Empty or Error state.
  Iterable<T> get data => map((state) => state.data);

  /// Safely extracts the data payload (or `null` if empty/error) from all [BloomState] entities.
  ///
  /// **Ensures:**
  /// * Returns an iterable yielding each entity's payload or `null` if not in a data state.
  Iterable<T?> get dataOrNull => map((state) => state.dataOrNull);
}

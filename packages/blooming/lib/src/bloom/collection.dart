// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// Reactive Collection Controllers (List, Set, Map)
// =============================================================================

/// Producer controller managing a reactive collection state with transactional draft edits.
///
/// Combines zero-overhead immutable replacement ([set], [data]) with
/// transactional draft edits ([edit], [editGuarded]).
///
/// Modifying elements inside an [edit] closure guarantees that changes are
/// compared via equality, frozen into an unmodifiable collection, and
/// committed in at most one downstream Push-Dirty pulse.
///
/// ## System Architectural Flow
/// ```text
/// [BloomDraftController] ──> .edit((draft) { draft.add(item); })
///                                    │
///                                    ▼ (Compares Equality with Previous)
///                         [Modified? ── Yes ──> Freezes Unmodifiable & Push-Dirty (1 Pulse)]
///                                    └── No   ──> No-Op (Zero Downstream Recomputations)
/// ```
///
/// ## Architectural Benefits
/// 1. **Atomic Draft Transactions**: Edits are applied to an isolated draft buffer and committed in a single pulse.
/// 2. **Deep/Shallow Equality Guarding**: Suppresses downstream notifications if the draft results in no net changes.
/// 3. **Immutability Enforcement**: The underlying payload is stored as unmodifiable collections to prevent mutation leaks.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT attempt to mutate `.data` in-place directly (e.g. `controller.data.add(...)`), as `.data` returns an
///   unmodifiable collection and throws an [UnsupportedError]. Always use [edit] or assign a new collection via [set].
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Mutating unmodifiable collection directly throws UnsupportedError
/// final listCtrl = blooming.list([1, 2]);
/// listCtrl.data.add(3); // Throws UnsupportedError!
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Use transactional edit to safely mutate draft and commit
/// final listCtrl = blooming.list([1, 2]);
/// listCtrl.edit((draft) => draft.add(3)); // Commits atomically as immutable list
/// ```
///
/// ## Examples
/// ```dart
/// // Primary: construct via blooming functor
/// final numbers = blooming.list([1, 2, 3]);
/// numbers.edit((draft) {
///   draft.add(4);
///   draft.remove(1);
/// });
/// print(numbers.data); // [2, 3, 4]
///
/// // Direct namespace construction
/// final tags = BloomDraftController.set({'flutter', 'dart'});
/// tags.edit((draft) => draft.add('reactive'));
///
/// final scores = BloomDraftController.map({'Alice': 90});
/// scores.edit((draft) => draft['Bob'] = 85);
/// ```
abstract base class BloomDraftController<C> implements BloomController<C> {
  /// Edits the current state in-place via a temporary draft buffer.
  ///
  /// The [recipe] callback receives a mutable copy of the current collection.
  /// Upon completion, changes are compared via equality (`equals` or collection-specific equality).
  /// If modified, the new collection is frozen as an unmodifiable collection and
  /// commits at most one Push-Dirty invalidation downstream.
  void edit(void Function(C draft) recipe);

  /// Safely executes [recipe] on a temporary draft buffer and commits modifications,
  /// or catches any thrown exceptions and transitions this controller to an error state.
  void editGuarded(void Function(C draft) recipe);

  @override
  Bloom<C> get bloom;

  // ===========================================================================
  // Namespace Functors
  // ===========================================================================

  /// Sub-functor managing transactional reactive list state producers.
  static const list = BloomingListFunctor();

  /// Alias for [list] adhering to standard collection naming.
  static const listOf = BloomingListFunctor();

  /// Sub-functor managing transactional reactive set state producers.
  ///
  /// Named `setOf` to prevent colliding with inherited instance method [BloomController.set].
  static const setOf = BloomingSetFunctor();

  /// Sub-functor managing transactional reactive map state producers.
  static const map = BloomingMapFunctor();

  /// Alias for [map] adhering to standard collection naming.
  static const mapOf = BloomingMapFunctor();
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

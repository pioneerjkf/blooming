// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

// ignore_for_file: deprecated_member_use

import 'dart:math' show Random;
import 'package:collection/collection.dart';
import 'package:collection/collection.dart' as col;
import 'package:blooming/blooming.dart';

// =============================================================================
// Reactive General Iterable Extensions
// =============================================================================

/// Reactive extensions on [BloomIterableElements] providing collection utilities.
///
/// ## Architectural Benefits
/// All transformation methods (such as [sorted], [shuffled], [whereNot], [slices], [groupListsBy])
/// compute lazily and return immutable [List.unmodifiable] collections to prevent
/// unexpected side-effects and preserve reactive state isolation.
///
/// ## Data Propagation Flow
/// ```text
/// [Source Bloom<Iterable<E>>]
///        │ (Push-Dirty)
///        ▼
/// [Grouping & Slicing Operator Pipeline]
///        ├─► .slices(3)         ──► Chunked Bloom<List<List<E>>>
///        ├─► .groupListsBy(key) ──► Grouped Bloom<Map<K, List<E>>>
///        ├─► .sample(n)         ──► Randomized Bloom<List<E>>
///        └─► .sortedBy(key)     ──► Sorted Bloom<List<E>>
/// ```
///
/// ## Examples
/// ```dart
/// final numbers = blooming([1, 2, 3, 4, 5, 6, 7]);
/// final chunks = numbers.bloom.elements.slices(3);
/// final evenOdd = numbers.bloom.elements.groupListsBy((n) => n % 2 == 0 ? 'even' : 'odd');
///
/// print(untracked(chunks));  // [[1, 2, 3], [4, 5, 6], [7]]
/// print(untracked(evenOdd)); // {'odd': [1, 3, 5, 7], 'even': [2, 4, 6]}
/// ```
extension GeneralBloomElementsExtension<E> on BloomIterableElements<E> {
  /// Selects [count] elements at random from this collection reactively.
  ///
  /// * [count]: The number of random elements to sample.
  /// * [random]: Optional random number generator.
  Bloom<List<E>> sample(int count, [Random? random]) =>
      computed((via) => List.unmodifiable(via(bloom).sample(count, random)));

  /// Returns a list of elements that do not satisfy [test] reactively.
  ///
  /// * [test]: Predicate returning `true` for elements to exclude.
  Bloom<List<E>> whereNot(bool Function(E element) test) =>
      computed((via) => List.unmodifiable(via(bloom).whereNot(test)));

  /// Returns a list containing the elements of this collection sorted by [compare] reactively.
  ///
  /// * [compare]: Comparator defining the sort order.
  Bloom<List<E>> sorted(int Function(E a, E b) compare) =>
      computed((via) => List.unmodifiable(via(bloom).sorted(compare)));

  /// Returns a list containing the elements of this collection shuffled reactively.
  ///
  /// * [random]: Optional random number generator.
  Bloom<List<E>> shuffled([Random? random]) =>
      computed((via) => List.unmodifiable(via(bloom).shuffled(random)));

  /// Returns a list containing the elements of this collection sorted by [keyOf] reactively.
  ///
  /// * [keyOf]: Function extracting the comparable sort key from each element.
  Bloom<List<E>> sortedBy<K extends Comparable<dynamic>>(
          K Function(E element) keyOf) =>
      computed((via) => List.unmodifiable(
          via(bloom).sortedByCompare<K>(keyOf, (a, b) => a.compareTo(b))));

  /// Returns a list containing the elements of this collection sorted by [compare] of [keyOf] reactively.
  ///
  /// * [keyOf]: Function extracting the sort key from each element.
  /// * [compare]: Comparator comparing extracted sort keys.
  Bloom<List<E>> sortedByCompare<K>(
          K Function(E element) keyOf, int Function(K a, K b) compare) =>
      computed((via) =>
          List.unmodifiable(via(bloom).sortedByCompare<K>(keyOf, compare)));

  /// Returns `true` if this collection is sorted by [compare] reactively.
  ///
  /// * [compare]: Comparator defining the expected sort order.
  Bloom<bool> isSorted(int Function(E a, E b) compare) =>
      computed((via) => via(bloom).isSorted(compare));

  /// Returns `true` if this collection is sorted by the natural order of [keyOf] reactively.
  ///
  /// * [keyOf]: Function extracting the comparable key from each element.
  Bloom<bool> isSortedBy<K extends Comparable<dynamic>>(
          K Function(E element) keyOf) =>
      computed((via) =>
          via(bloom).isSortedByCompare<K>(keyOf, (a, b) => a.compareTo(b)));

  /// Returns `true` if this collection is sorted by [compare] of [keyOf] reactively.
  ///
  /// * [keyOf]: Function extracting the sort key from each element.
  /// * [compare]: Comparator comparing extracted sort keys.
  Bloom<bool> isSortedByCompare<K>(
          K Function(E element) keyOf, int Function(K a, K b) compare) =>
      computed((via) => via(bloom).isSortedByCompare<K>(keyOf, compare));

  /// Maps each element of this collection along with its index reactively.
  ///
  /// * [convert]: Transformation function receiving the element index and value.
  Bloom<List<T>> mapIndexed<T>(T Function(int index, E element) convert) =>
      computed((via) => List.unmodifiable(via(bloom).mapIndexed(convert)));

  /// Filters elements of this collection based on an indexed predicate [test] reactively.
  ///
  /// * [test]: Indexed predicate returning `true` for elements to retain.
  Bloom<List<E>> whereIndexed(bool Function(int index, E element) test) =>
      computed((via) => List.unmodifiable(via(bloom).whereIndexed(test)));

  /// Filters elements of this collection based on an indexed predicate [test] reactively, returning those that do not satisfy it.
  ///
  /// * [test]: Indexed predicate returning `true` for elements to exclude.
  Bloom<List<E>> whereNotIndexed(bool Function(int index, E element) test) =>
      computed((via) => List.unmodifiable(via(bloom).whereNotIndexed(test)));

  /// Flattens this collection along with element indices reactively.
  ///
  /// * [toElements]: Indexed function expanding each element into an iterable.
  Bloom<List<T>> expandIndexed<T>(
          Iterable<T> Function(int index, E element) toElements) =>
      computed(
          (via) => List.unmodifiable(via(bloom).expandIndexed(toElements)));

  /// Reduces this collection to a single value by iteratively combining elements along with their index reactively.
  ///
  /// * [combine]: Indexed reducer function combining the accumulator and current element.
  ///
  /// **Requires:**
  /// * The collection must not be empty when evaluated.
  ///
  /// **Throws:**
  /// * [StateError] if the collection is empty upon evaluation.
  Bloom<E> reduceIndexed(
          E Function(int index, E previous, E element) combine) =>
      computed((via) => via(bloom).reduceIndexed(combine));

  /// Reduces this collection to a single value by iteratively combining elements along with their index and an initial value reactively.
  ///
  /// * [initialValue]: Initial accumulator value.
  /// * [combine]: Indexed folder function combining the accumulator and current element.
  Bloom<T> foldIndexed<T>(T initialValue,
          T Function(int index, T previous, E element) combine) =>
      computed((via) => via(bloom).foldIndexed<T>(initialValue, combine));

  /// Returns the first element that satisfies [test] reactively, or `null` if none.
  ///
  /// * [test]: Predicate evaluated against elements in order.
  Bloom<E?> firstWhereOrNull(bool Function(E element) test) =>
      computed((via) => via(bloom).firstWhereOrNull(test));

  /// Returns the first element that satisfies an indexed predicate [test] reactively, or `null` if none.
  ///
  /// * [test]: Indexed predicate evaluated against elements in order.
  Bloom<E?> firstWhereIndexedOrNull(bool Function(int index, E element) test) =>
      computed((via) => via(bloom).firstWhereIndexedOrNull(test));

  /// Returns the last element that satisfies [test] reactively, or `null` if none.
  ///
  /// * [test]: Predicate evaluated against elements.
  Bloom<E?> lastWhereOrNull(bool Function(E element) test) =>
      computed((via) => via(bloom).lastWhereOrNull(test));

  /// Returns the last element that satisfies an indexed predicate [test] reactively, or `null` if none.
  ///
  /// * [test]: Indexed predicate evaluated against elements.
  Bloom<E?> lastWhereIndexedOrNull(bool Function(int index, E element) test) =>
      computed((via) => via(bloom).lastWhereIndexedOrNull(test));

  /// Returns the single element that satisfies [test] reactively, or `null` if none.
  ///
  /// * [test]: Predicate evaluated against elements.
  Bloom<E?> singleWhereOrNull(bool Function(E element) test) =>
      computed((via) => via(bloom).singleWhereOrNull(test));

  /// Returns the single element that satisfies an indexed predicate [test] reactively, or `null` if none.
  ///
  /// * [test]: Indexed predicate evaluated against elements.
  Bloom<E?> singleWhereIndexedOrNull(
          bool Function(int index, E element) test) =>
      computed((via) => via(bloom).singleWhereIndexedOrNull(test));

  /// Returns the [index]th element reactively, or `null` if out of range.
  ///
  /// * [index]: Non-negative zero-based index of the element.
  Bloom<E?> elementAtOrNull(int index) =>
      computed((via) => via(bloom).elementAtOrNull(index));

  /// Groups elements by [key] reactively, keeping only the last element for each key.
  ///
  /// * [key]: Function extracting the grouping key from each element.
  Bloom<Map<K, E>> lastBy<K>(K Function(E element) key) =>
      computed((via) => Map<K, E>.unmodifiable(via(bloom).lastBy<K>(key)));

  /// Groups and folds elements by a key computed from each element reactively.
  ///
  /// * [key]: Function extracting the grouping key from each element.
  /// * [fold]: Function combining the previous group value (or `null`) with the current element.
  Bloom<Map<K, G>> groupFoldBy<K, G>({
    required K Function(E element) key,
    required G Function(G? previous, E element) fold,
  }) =>
      computed((via) =>
          Map<K, G>.unmodifiable(via(bloom).groupFoldBy<K, G>(key, fold)));

  /// Groups elements into sets by [keyOf] reactively.
  ///
  /// * [keyOf]: Function extracting the grouping key from each element.
  Bloom<Map<K, Set<E>>> groupSetsBy<K>(K Function(E element) keyOf) =>
      computed((via) => Map<K, Set<E>>.unmodifiable(
            via(bloom)
                .groupSetsBy<K>(keyOf)
                .map((k, v) => MapEntry<K, Set<E>>(k, Set<E>.unmodifiable(v))),
          ));

  /// Groups elements into lists by [keyOf] reactively.
  ///
  /// * [keyOf]: Function extracting the grouping key from each element.
  Bloom<Map<K, List<E>>> groupListsBy<K>(K Function(E element) keyOf) =>
      computed((via) => Map<K, List<E>>.unmodifiable(
            via(bloom).groupListsBy<K>(keyOf).map(
                (k, v) => MapEntry<K, List<E>>(k, List<E>.unmodifiable(v))),
          ));

  /// Legacy alias of [groupListsBy].
  ///
  /// * [key]: Function extracting the grouping key from each element.
  Bloom<Map<K, List<E>>> groupBy<K>(K Function(E element) key) =>
      computed((via) => Map<K, List<E>>.unmodifiable(
            col.groupBy<E, K>(via(bloom), key).map(
                (k, v) => MapEntry<K, List<E>>(k, List<E>.unmodifiable(v))),
          ));

  /// Splits this collection into chunks before elements satisfying [test] reactively.
  ///
  /// * [test]: Predicate identifying chunk boundary elements.
  Bloom<List<List<E>>> splitBefore(bool Function(E element) test) =>
      computed((via) => List<List<E>>.unmodifiable(
            via(bloom).splitBefore(test).map((s) => List<E>.unmodifiable(s)),
          ));

  /// Splits this collection after elements satisfying [test] reactively.
  ///
  /// * [test]: Predicate identifying chunk boundary elements.
  Bloom<List<List<E>>> splitAfter(bool Function(E element) test) =>
      computed((via) => List<List<E>>.unmodifiable(
            via(bloom).splitAfter(test).map((s) => List<E>.unmodifiable(s)),
          ));

  /// Splits this collection into chunks between elements satisfying [test] reactively.
  ///
  /// * [test]: Predicate evaluated on adjacent element pairs.
  Bloom<List<List<E>>> splitBetween(bool Function(E first, E second) test) =>
      computed((via) => List<List<E>>.unmodifiable(
            via(bloom).splitBetween(test).map((s) => List<E>.unmodifiable(s)),
          ));

  /// Splits this collection into chunks before elements satisfying an indexed predicate [test] reactively.
  ///
  /// * [test]: Indexed predicate identifying chunk boundary elements.
  Bloom<List<List<E>>> splitBeforeIndexed(
          bool Function(int index, E element) test) =>
      computed((via) => List<List<E>>.unmodifiable(
            via(bloom)
                .splitBeforeIndexed(test)
                .map((s) => List<E>.unmodifiable(s)),
          ));

  /// Splits this collection into chunks after elements satisfying an indexed predicate [test] reactively.
  ///
  /// * [test]: Indexed predicate identifying chunk boundary elements.
  Bloom<List<List<E>>> splitAfterIndexed(
          bool Function(int index, E element) test) =>
      computed((via) => List<List<E>>.unmodifiable(
            via(bloom)
                .splitAfterIndexed(test)
                .map((s) => List<E>.unmodifiable(s)),
          ));

  /// Splits this collection into chunks between elements satisfying an indexed predicate [test] reactively.
  ///
  /// * [test]: Indexed predicate evaluated on adjacent element pairs.
  Bloom<List<List<E>>> splitBetweenIndexed(
          bool Function(int index, E first, E second) test) =>
      computed((via) => List<List<E>>.unmodifiable(
            via(bloom)
                .splitBetweenIndexed(test)
                .map((s) => List<E>.unmodifiable(s)),
          ));

  /// Returns `true` if no elements satisfy [test] reactively.
  ///
  /// * [test]: Predicate evaluated against elements.
  Bloom<bool> none(bool Function(E element) test) =>
      computed((via) => via(bloom).none(test));

  /// Returns `true` if no elements satisfy an indexed predicate [test] reactively.
  ///
  /// * [test]: Indexed predicate evaluated against elements.
  Bloom<bool> noneIndexed(bool Function(int index, E element) test) => computed(
      (via) => !via(bloom).indexed.any((pair) => test(pair.$1, pair.$2)));

  /// Returns `true` if any element satisfies an indexed predicate [test] reactively.
  ///
  /// * [test]: Indexed predicate evaluated against elements.
  Bloom<bool> anyIndexed(bool Function(int index, E element) test) => computed(
      (via) => via(bloom).indexed.any((pair) => test(pair.$1, pair.$2)));

  /// Returns `true` if all elements satisfy an indexed predicate [test] reactively.
  ///
  /// * [test]: Indexed predicate evaluated against elements.
  Bloom<bool> everyIndexed(bool Function(int index, E element) test) =>
      computed(
          (via) => via(bloom).indexed.every((pair) => test(pair.$1, pair.$2)));

  /// Splits this collection into chunks of [size] elements reactively.
  ///
  /// * [size]: The maximum number of elements per chunk (must be at least `1`).
  ///
  /// **Requires:**
  /// * [size] must be greater than or equal to `1`.
  ///
  /// **Throws:**
  /// * [RangeError] if [size] is less than `1`.
  Bloom<List<List<E>>> slices(int size) =>
      computed((via) => List<List<E>>.unmodifiable(
            via(bloom).slices(size).map((s) => List<E>.unmodifiable(s)),
          ));
}

/// Reactive extensions for collections of nullable elements.
extension NullableBloomElementsExtension<E extends Object>
    on BloomIterableElements<E?> {
  /// Returns an unmodifiable list of all non-null elements of this collection reactively.
  Bloom<List<E>> get whereNotNull =>
      computed((via) => List.unmodifiable(via(bloom).whereNotNull()));
}

/// Reactive extensions for nested collections of iterables.
extension IterableIterableBloomElementsExtension<T>
    on BloomIterableElements<Iterable<T>> {
  /// Flattens this collection of iterables into a single unmodifiable list reactively.
  Bloom<List<T>> get flattenedToList =>
      computed((via) => List.unmodifiable(via(bloom).flattened));

  /// Flattens this collection of iterables into a single unmodifiable set reactively.
  Bloom<Set<T>> get flattenedToSet =>
      computed((via) => Set.unmodifiable(via(bloom).flattened.toSet()));
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:math' show Random;
import 'package:collection/collection.dart';
import 'package:collection/collection.dart' as col;
import 'package:blooming/blooming.dart';

// =============================================================================
// Reactive List Extensions
// =============================================================================

/// Reactive extensions on [BloomListElements] providing high-performance list operations.
///
/// ## Architectural Benefits
/// All transformations operating on [BloomListElements] return new reactive [Bloom] nodes.
/// List-producing operations immediately wrap returned lists with [List.unmodifiable]
/// to guarantee state immutability across reactive cycles.
///
/// ## Data Propagation Flow
/// ```text
/// [Source Bloom<List<E>>]
///        │ (Push-Dirty)
///        ▼
/// [Reactive List Extension Operators]
///        ├─► .binarySearch(target) ──► Reactive Index Bloom<int> (O(log N))
///        ├─► .sortedRange(0, 5)    ──► Immutable Sub-range Sorted Bloom<List<E>>
///        ├─► .swapped(i, j)        ──► Immutable Swapped Bloom<List<E>>
///        └─► .slices(pageSize)     ──► Paginated Bloom<List<List<E>>>
/// ```
///
/// ## Examples
/// ```dart
/// final listController = blooming<List<int>>([10, 20, 30, 40, 50]);
/// final indexBloom = listController.bloom.elements.binarySearch(30, (a, b) => a.compareTo(b));
/// final swappedList = listController.bloom.elements.swapped(0, 4);
///
/// print(untracked(indexBloom)); // 2
/// ```
extension ListBloomElementsExtension<E> on BloomListElements<E> {
  Bloom<List<E>> get _listBloom => bloom as Bloom<List<E>>;

  /// Returns the index of [element] in this sorted list via binary search.
  ///
  /// * [element]: The target element to search for.
  /// * [compare]: Custom comparison function returning negative, zero, or positive.
  ///
  /// **Requires:**
  /// * The underlying list MUST be sorted according to [compare].
  ///
  /// **Ensures:**
  /// * Returns the zero-based index of [element] in O(log N), or negative value if not found.
  Bloom<int> binarySearch(E element, int Function(E a, E b) compare) =>
      computed((via) =>
          col.ListExtensions(via(_listBloom)).binarySearch(element, compare));

  /// Returns the index of [element] in this sorted list by comparing key extracted via [keyOf].
  ///
  /// * [element]: The target element to search for.
  /// * [keyOf]: Function extracting the sort key from each element.
  /// * [compare]: Comparator comparing extracted keys.
  /// * [start]: Optional inclusive start index. Defaults to `0`.
  /// * [end]: Optional exclusive end index.
  Bloom<int> binarySearchByCompare<K>(E element, K Function(E element) keyOf,
          int Function(K a, K b) compare, [int start = 0, int? end]) =>
      computed((via) => col.ListExtensions(via(_listBloom))
          .binarySearchByCompare<K>(element, keyOf, compare, start, end));

  /// Returns the index of [element] in this sorted list by key natural order.
  ///
  /// * [element]: The target element to search for.
  /// * [keyOf]: Function extracting the comparable key from each element.
  /// * [start]: Optional inclusive start index. Defaults to `0`.
  /// * [end]: Optional exclusive end index.
  Bloom<int> binarySearchBy<K extends Comparable<dynamic>>(
          E element, K Function(E element) keyOf, [int start = 0, int? end]) =>
      computed((via) => col.ListExtensions(via(_listBloom))
          .binarySearchByCompare<K>(
              element, keyOf, (a, b) => a.compareTo(b), start, end));

  /// Returns the index where [element] should be inserted in this sorted list.
  ///
  /// * [element]: The target element to locate the lower bound for.
  /// * [compare]: Comparator defining the sort order.
  Bloom<int> lowerBound(E element, int Function(E a, E b) compare) =>
      computed((via) =>
          col.ListExtensions(via(_listBloom)).lowerBound(element, compare));

  /// Returns the index where [element] should be inserted by comparing key extracted via [keyOf].
  ///
  /// * [element]: The target element to locate the lower bound for.
  /// * [keyOf]: Function extracting the sort key from each element.
  /// * [compare]: Comparator comparing extracted keys.
  /// * [start]: Optional inclusive start index. Defaults to `0`.
  /// * [end]: Optional exclusive end index.
  Bloom<int> lowerBoundByCompare<K>(E element, K Function(E element) keyOf,
          int Function(K a, K b) compare, [int start = 0, int? end]) =>
      computed((via) => col.ListExtensions(via(_listBloom))
          .lowerBoundByCompare<K>(element, keyOf, compare, start, end));

  /// Returns the index where [element] should be inserted by key natural order.
  ///
  /// * [element]: The target element to locate the lower bound for.
  /// * [keyOf]: Function extracting the comparable key from each element.
  /// * [start]: Optional inclusive start index. Defaults to `0`.
  /// * [end]: Optional exclusive end index.
  Bloom<int> lowerBoundBy<K extends Comparable<dynamic>>(
          E element, K Function(E element) keyOf, [int start = 0, int? end]) =>
      computed((via) => col.ListExtensions(via(_listBloom))
          .lowerBoundByCompare<K>(
              element, keyOf, (a, b) => a.compareTo(b), start, end));

  /// Returns a new unmodifiable list containing a sorted range of elements from this list.
  ///
  /// * [start]: Inclusive start index of the range to sort.
  /// * [end]: Exclusive end index of the range to sort.
  /// * [compare]: Comparator defining the sort order.
  Bloom<List<E>> sortedRange(
          int start, int end, int Function(E a, E b) compare) =>
      computed((via) {
        final copy = via(_listBloom).toList();
        col.ListExtensions(copy).sortRange(start, end, compare);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new unmodifiable list containing elements sorted by [compare] of key extracted via [keyOf].
  ///
  /// * [keyOf]: Function extracting the sort key from each element.
  /// * [compare]: Comparator comparing extracted keys.
  /// * [start]: Optional inclusive start index. Defaults to `0`.
  /// * [end]: Optional exclusive end index.
  Bloom<List<E>> sortedByCompare<K>(
          K Function(E element) keyOf, int Function(K a, K b) compare,
          [int start = 0, int? end]) =>
      computed((via) {
        final copy = via(_listBloom).toList();
        col.ListExtensions(copy).sortByCompare<K>(keyOf, compare, start, end);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new unmodifiable list containing elements sorted by key extracted via [keyOf].
  ///
  /// * [keyOf]: Function extracting the comparable key from each element.
  /// * [start]: Optional inclusive start index. Defaults to `0`.
  /// * [end]: Optional exclusive end index.
  Bloom<List<E>> sortedBy<K extends Comparable<dynamic>>(
          K Function(E element) keyOf,
          [int start = 0,
          int? end]) =>
      computed((via) {
        final copy = via(_listBloom).toList();
        col.ListExtensions(copy)
            .sortByCompare<K>(keyOf, (a, b) => a.compareTo(b), start, end);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new unmodifiable list with a range of elements shuffled reactively.
  ///
  /// * [start]: Inclusive start index of the range to shuffle.
  /// * [end]: Exclusive end index of the range to shuffle.
  /// * [random]: Optional random number generator.
  Bloom<List<E>> shuffledRange(int start, int end, [Random? random]) =>
      computed((via) {
        final copy = via(_listBloom).toList();
        col.ListExtensions(copy).shuffleRange(start, end, random);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new unmodifiable list with a range of elements reversed reactively.
  ///
  /// * [start]: Inclusive start index of the range to reverse.
  /// * [end]: Exclusive end index of the range to reverse.
  Bloom<List<E>> reversedRange(int start, int end) => computed((via) {
        final copy = via(_listBloom).toList();
        col.ListExtensions(copy).reverseRange(start, end);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new unmodifiable list with two elements swapped reactively.
  ///
  /// * [index1]: Index of the first element to swap.
  /// * [index2]: Index of the second element to swap.
  Bloom<List<E>> swapped(int index1, int index2) => computed((via) {
        final copy = via(_listBloom).toList();
        col.ListExtensions(copy).swap(index1, index2);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a sublist of this list reactively.
  ///
  /// * [start]: Inclusive start index of the sublist.
  /// * [end]: Optional exclusive end index of the sublist.
  Bloom<List<E>> slice(int start, [int? end]) => sublist(start, end);

  /// Whether [other] has the same elements as this list reactively.
  ///
  /// * [other]: The candidate list to compare against.
  /// * [equality]: Element equality comparator. Defaults to [DefaultEquality].
  Bloom<bool> equals(List<E> other,
          [Equality<E> equality = const DefaultEquality()]) =>
      computed(
          (via) => col.ListExtensions(via(_listBloom)).equals(other, equality));

  /// Returns the [index]th element reactively, or `null` if out of range.
  ///
  /// * [index]: Non-negative zero-based index of the element.
  Bloom<E?> elementAtOrNull(int index) => computed(
      (via) => col.ListExtensions(via(_listBloom)).elementAtOrNull(index));

  /// Contiguous slices of this list with the given [length] reactively.
  ///
  /// * [length]: Maximum number of elements per slice.
  Bloom<List<List<E>>> slices(int length) =>
      computed((via) => List<List<E>>.unmodifiable(
            col.ListExtensions(via(_listBloom))
                .slices(length)
                .map((s) => List<E>.unmodifiable(s)),
          ));
}

/// Reactive extensions on [BloomListElements] holding [Comparable] elements.
extension ListComparableBloomElementsExtension<E extends Comparable<dynamic>>
    on BloomListElements<E> {
  Bloom<List<E>> get _listBloom => bloom as Bloom<List<E>>;

  /// Returns the index of [element] in this sorted list.
  ///
  /// * [element]: The target element to search for.
  /// * [compare]: Optional comparator overriding [Comparable.compareTo].
  Bloom<int> binarySearch(E element, [int Function(E a, E b)? compare]) =>
      computed((via) => col.ListExtensions(via(_listBloom))
          .binarySearch(element, compare ?? (a, b) => a.compareTo(b)));

  /// Returns the index where [element] should be in this sorted list.
  ///
  /// * [element]: The target element to locate the lower bound for.
  /// * [compare]: Optional comparator overriding [Comparable.compareTo].
  Bloom<int> lowerBound(E element, [int Function(E a, E b)? compare]) =>
      computed((via) => col.ListExtensions(via(_listBloom))
          .lowerBound(element, compare ?? (a, b) => a.compareTo(b)));

  /// Returns a new unmodifiable list containing a sorted range of elements from this list.
  ///
  /// * [start]: Inclusive start index of the range to sort.
  /// * [end]: Exclusive end index of the range to sort.
  /// * [compare]: Optional comparator overriding [Comparable.compareTo].
  Bloom<List<E>> sortedRange(int start, int end,
          [int Function(E a, E b)? compare]) =>
      computed((via) {
        final copy = via(_listBloom).toList();
        col.ListExtensions(copy)
            .sortRange(start, end, compare ?? (a, b) => a.compareTo(b));
        return List<E>.unmodifiable(copy);
      });
}

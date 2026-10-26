// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

/// Extension on [Bloom<Iterable<E>>] providing reactive element-wise operations via `.elements`.
///
/// Encapsulates collection operations behind a dedicated `.elements` proxy namespace to avoid
/// polluting the root [Bloom] API while providing clean, defensive, and immutable transformations.
///
/// ## Sub-Functor & Invocation Pathways
/// ```text
/// iterableBloom.elements
///  ├── .map((e) => ...)                  --> Bloom<List<T>>
///  ├── .where((e) => ...)                --> Bloom<List<E>>
///  ├── .expand((e) => ...)               --> Bloom<List<T>>
///  ├── .take(count)                      --> Bloom<List<E>>
///  ├── .skip(count)                      --> Bloom<List<E>>
///  ├── .first / .last / .length          --> Bloom<E> / Bloom<int>
///  └── .contains(element)                --> Bloom<bool>
/// ```
///
/// ## System Architectural Flow
/// ```text
/// [Source Bloom<Iterable<E>>]
///        │ (Push-Dirty Invalidation)
///        ▼
/// [iterableBloom.elements.map(...)]
///        │ (Pull-Data on Read)
///        ▼
/// [Immutable Bloom<List<T>>] (List.unmodifiable)
/// ```
///
/// ## Examples
/// ```dart
/// final numbersController = blooming([1, 2, 3, 4, 5]);
/// final evenNumbersBloom = numbersController.bloom.elements.where((n) => n.isEven);
/// ```
extension BloomIterableElementsExtension<E> on Bloom<Iterable<E>> {
  /// Opens a dedicated namespace for operating on the individual elements of this [Iterable] reactively.
  ///
  /// **Ensures:**
  /// * Returns a [BloomIterableElements] proxy wrapping this [Bloom].
  BloomIterableElements<E> get elements => BloomIterableElements<E>._(this);
}

/// Extension on [Bloom<Iterable<E>>] providing keyed element-wise transformations via `.keyed`.
///
/// Keyed operations preserve downstream value/node cache across source collection updates,
/// eliminating expensive re-evaluations by caching results based on stable unique keys.
///
/// ## Sub-Functor & Invocation Pathways
/// ```text
/// iterableBloom.keyed
///  └── .map(key: (e) => ..., convert: (e) => ...)  --> Bloom<List<R>>
/// ```
///
/// ## System Architectural Flow
/// ```text
/// [Source Collection] ──(Updates)──> [Keyed Cache Diffing (key: e.id)]
///                                           │
///                                           ├── [Existing Key: Reuses Cached Node]
///                                           └── [New Key: Evaluates & Caches]
/// ```
///
/// ## Examples
/// ```dart
/// final users = blooming([User(id: '1', name: 'Alice')]);
/// final userViewModels = users.bloom.keyed.map(
///   key: (user) => user.id,
///   convert: (user) => UserViewModel(user),
///   update: (vm, user) => vm.update(user),
/// );
/// ```
extension BloomKeyedIterableElementsExtension<E> on Bloom<Iterable<E>> {
  /// Opens a dedicated namespace for operating on keyed elements of this [Iterable] reactively.
  ///
  /// **Ensures:**
  /// * Returns a [BloomKeyedIterableElements] proxy wrapping this [Bloom].
  BloomKeyedIterableElements<E> get keyed => BloomKeyedIterableElements<E>._(this);
}

/// Extension on [Bloom<List<E>>] providing reactive list-specific index and slicing operations via `.elements`.
///
/// ## Sub-Functor & Invocation Pathways
/// ```text
/// listBloom.elements
///  ├── [index]                           --> Bloom<E> (Reactive element lookup)
///  ├── .sublist(start, [end])            --> Bloom<List<E>>
///  └── .reversed                         --> Bloom<List<E>>
/// ```
///
/// ## Examples
/// ```dart
/// final itemsController = blooming(['A', 'B', 'C']);
/// final firstItemBloom = itemsController.bloom.elements[0]; // Bloom<String> holding 'A'
/// ```
extension BloomListElementsExtension<E> on Bloom<List<E>> {
  /// Opens a dedicated namespace for operating on the individual elements of this [List] reactively.
  ///
  /// **Ensures:**
  /// * Returns a [BloomListElements] proxy wrapping this [Bloom].
  BloomListElements<E> get elements => BloomListElements<E>._(this);
}

/// Extension on [Bloom<Set<E>>] providing reactive set operations (union, intersection, difference) via `.elements`.
///
/// ## Sub-Functor & Invocation Pathways
/// ```text
/// setBloom.elements
///  ├── .union(other)                     --> Bloom<Set<E>>
///  ├── .intersection(other)              --> Bloom<Set<E>>
///  └── .difference(other)                --> Bloom<Set<E>>
/// ```
///
/// ## Examples
/// ```dart
/// final setAController = blooming({'a', 'b'});
/// final unionBloom = setAController.bloom.elements.union({'c', 'd'});
/// ```
extension BloomSetElementsExtension<E> on Bloom<Set<E>> {
  /// Opens a dedicated namespace for operating on the individual elements of this [Set] reactively.
  ///
  /// **Ensures:**
  /// * Returns a [BloomSetElements] proxy wrapping this [Bloom].
  BloomSetElements<E> get elements => BloomSetElements<E>._(this);
}

/// Extension on [Bloom<Map<K, V>>] providing reactive map entry transformations and key/value accessors via `.elements`.
///
/// ## Sub-Functor & Invocation Pathways
/// ```text
/// mapBloom.elements
///  ├── [key]                             --> Bloom<V?> (Reactive value lookup)
///  ├── .keys                             --> Bloom<List<K>>
///  ├── .values                           --> Bloom<List<V>>
///  ├── .length                           --> Bloom<int>
///  └── .isEmpty / .isNotEmpty            --> Bloom<bool>
/// ```
///
/// ## Examples
/// ```dart
/// final scoresController = blooming({'Alice': 100, 'Bob': 85});
/// final aliceScoreBloom = scoresController.bloom.elements['Alice']; // Bloom<int?> holding 100
/// ```
extension BloomMapElementsExtension<K, V> on Bloom<Map<K, V>> {
  /// Opens a dedicated namespace for operating on the individual elements of this [Map] reactively.
  ///
  /// **Ensures:**
  /// * Returns a [BloomMapElements] proxy wrapping this [Bloom].
  BloomMapElements<K, V> get elements => BloomMapElements<K, V>._(this);
}

/// A dedicated proxy wrapper for [Bloom<Iterable<E>>] to perform element-wise transformations safely and defensively.
///
/// Under the hood, all collection-returning operations immediately compute and package
/// results into an immutable list ([List.unmodifiable]) to prevent lazy computation exceptions
/// outside the reactive boundary and to enforce state immutability.
///
/// **Data Propagation Flow:**
/// ```text
/// [Source Bloom<Iterable<E>>]
///        │ (Push-Dirty)
///        ▼
/// [BloomIterableElements<E> Proxy]
///        │ (Pull-Data on evaluate: maps/filters elements defensively)
///        ▼
/// Returns immutable [Bloom<List<T>>] or scalar aggregation in O(1)
/// ```
extension type BloomIterableElements<E>._(Bloom<Iterable<E>> _bloom) {
  /// Exposes the underlying [Bloom] node of this elements proxy.
  Bloom<Iterable<E>> get bloom => _bloom;

  /// Maps each element of this collection to another object [T].
  ///
  /// * [convert]: The mapping transformation callback applied to each element.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<List<T>>] holding an unmodifiable list of mapped items.
  Bloom<List<T>> map<T>(T Function(E element) convert) =>
      computed((via) => List.unmodifiable(via(_bloom).map(convert)));

  /// Filters elements of this collection based on [test].
  ///
  /// * [test]: The predicate used to filter elements.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<List<E>>] containing only elements that satisfy [test].
  Bloom<List<E>> where(bool Function(E element) test) => computed((via) => List.unmodifiable(via(_bloom).where(test)));

  /// Returns a list of elements that have type [T] reactively.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<List<T>>] containing unmodifiable filtered items of type [T].
  Bloom<List<T>> whereType<T>() => computed((via) => List.unmodifiable(via(_bloom).whereType<T>()));

  /// Returns a list of (index, element) pairs reactively.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<List<(int, E)>>] holding paired indices and elements.
  Bloom<List<(int, E)>> get indexed => computed((via) => List.unmodifiable(via(_bloom).indexed));

  /// Flattens this collection by mapping each element to an [Iterable] and concatenating.
  ///
  /// * [toElements]: A function that transforms each element into an iterable of [T].
  ///
  /// **Ensures:**
  /// * Returns an unmodifiable [Bloom<List<T>>] containing the concatenated results.
  Bloom<List<T>> expand<T>(Iterable<T> Function(E element) toElements) =>
      computed((via) => List.unmodifiable(via(_bloom).expand(toElements)));

  /// Checks whether the collection contains an element equal to [element] reactively.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<bool>] yielding `true` if [element] is present, `false` otherwise.
  Bloom<bool> contains(Object? element) => computed((via) => via(_bloom).contains(element));

  /// Reduces a collection to a single value by iteratively combining elements reactively.
  ///
  /// * [combine]: The reducer function combining accumulator and current element.
  ///
  /// **Requires:**
  /// * The collection must not be empty when evaluated.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<E>] holding the reduced scalar result.
  Bloom<E> reduce(E Function(E value, E element) combine) => computed((via) => via(_bloom).reduce(combine));

  /// Reduces a collection to a single value by iteratively combining elements with an initial value reactively.
  ///
  /// * [initialValue]: The initial accumulator value.
  /// * [combine]: The folder function combining accumulator and current element.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<T>] holding the folded result.
  Bloom<T> fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      computed((via) => via(_bloom).fold(initialValue, combine));

  /// Checks if all elements satisfy [test].
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<bool>] that evaluates to `true` if every element satisfies [test].
  Bloom<bool> every(bool Function(E element) test) => computed((via) => via(_bloom).every(test));

  /// Converts each element to a [String] and concatenates the results reactively.
  ///
  /// * [separator]: The delimiter string placed between elements. Defaults to empty string.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<String>] with the joined representation.
  Bloom<String> join([String separator = '']) => computed((via) => via(_bloom).join(separator));

  /// Checks if any element satisfies [test].
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<bool>] yielding `true` if at least one element satisfies [test].
  Bloom<bool> any(bool Function(E element) test) => computed((via) => via(_bloom).any(test));

  /// Returns a list containing the elements of this iterable reactively.
  ///
  /// * [growable]: Whether the resulting list should be growable. Defaults to `false`.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<List<E>>] with the collection contents.
  Bloom<List<E>> toList({bool growable = false}) =>
      computed((via) => growable ? List.of(via(_bloom), growable: true) : List.unmodifiable(via(_bloom)));

  /// Returns a set containing the elements of this iterable reactively.
  ///
  /// * [unmodifiable]: Whether the resulting set is immutable. Defaults to `true`.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<Set<E>>] containing unique elements from this iterable.
  Bloom<Set<E>> toSet({bool unmodifiable = true}) =>
      computed((via) => unmodifiable ? Set.unmodifiable(via(_bloom).toSet()) : via(_bloom).toSet());

  /// Returns the number of elements reactively.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<int>] reflecting the current collection length.
  Bloom<int> get length => computed((via) => via(_bloom).length);

  /// Checks if this collection is empty.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<bool>] that is `true` if the collection contains no elements.
  Bloom<bool> get isEmpty => computed((via) => via(_bloom).isEmpty);

  /// Checks if this collection is not empty.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<bool>] that is `true` if the collection contains at least one element.
  Bloom<bool> get isNotEmpty => computed((via) => via(_bloom).isNotEmpty);

  /// Takes the first [count] elements of this collection.
  ///
  /// * [count]: The number of initial elements to include.
  ///
  /// **Ensures:**
  /// * Returns an unmodifiable [Bloom<List<E>>] holding up to [count] elements.
  Bloom<List<E>> take(int count) => computed((via) => List.unmodifiable(via(_bloom).take(count)));

  /// Skips the first [count] elements of this collection.
  ///
  /// * [count]: The number of initial elements to discard.
  ///
  /// **Ensures:**
  /// * Returns an unmodifiable [Bloom<List<E>>] without the first [count] elements.
  Bloom<List<E>> skip(int count) => computed((via) => List.unmodifiable(via(_bloom).skip(count)));

  /// Returns the first element of this collection reactively.
  ///
  /// **Requires:**
  /// * The source collection must not be empty when evaluated.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<E>] yielding the first element.
  Bloom<E> get first => computed((via) => via(_bloom).first);

  /// Returns the first element of this collection reactively, or null if empty.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<E?>] yielding the first element or `null` if empty.
  Bloom<E?> get firstOrNull => computed((via) => via(_bloom).firstOrNull);

  /// Returns the last element of this collection reactively.
  ///
  /// **Requires:**
  /// * The source collection must not be empty when evaluated.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<E>] yielding the last element.
  Bloom<E> get last => computed((via) => via(_bloom).last);

  /// Returns the last element of this collection reactively, or null if empty.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<E?>] yielding the last element or `null` if empty.
  Bloom<E?> get lastOrNull => computed((via) => via(_bloom).lastOrNull);

  /// Checks that this collection has only one element, and returns that element reactively.
  ///
  /// **Requires:**
  /// * The collection must have exactly one element when evaluated.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<E>] yielding the single element.
  Bloom<E> get single => computed((via) => via(_bloom).single);

  /// Checks that this collection has only one element, and returns that element reactively, or null if empty/multiple.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<E?>] yielding the single element or `null` otherwise.
  Bloom<E?> get singleOrNull => computed((via) => via(_bloom).singleOrNull);

  /// Returns the first element that satisfies the given predicate [test] reactively.
  ///
  /// * [test]: Predicate callback to test elements against.
  /// * [orElse]: Optional fallback generator if no matching element is found.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<E>] yielding the first matching element.
  Bloom<E> firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      computed((via) => via(_bloom).firstWhere(test, orElse: orElse));

  /// Returns the last element that satisfies the given predicate [test] reactively.
  ///
  /// * [test]: Predicate callback to test elements against.
  /// * [orElse]: Optional fallback generator if no matching element is found.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<E>] yielding the last matching element.
  Bloom<E> lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      computed((via) => via(_bloom).lastWhere(test, orElse: orElse));

  /// Returns the single element that satisfies [test] reactively.
  ///
  /// * [test]: Predicate callback to test elements against.
  /// * [orElse]: Optional fallback generator if no matching element is found.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<E>] yielding the matching single element.
  Bloom<E> singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      computed((via) => via(_bloom).singleWhere(test, orElse: orElse));

  /// Returns the [index]th element reactively.
  ///
  /// * [index]: The zero-based index of the element to retrieve.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<E>] holding the element at [index].
  Bloom<E> elementAt(int index) => computed((via) => via(_bloom).elementAt(index));
}

/// A dedicated proxy wrapper for [Bloom<Iterable<E>>] to perform keyed element-wise transformations safely and lazily.
///
/// ## System Architectural Flow (Keyed Dynamic Divergence)
/// ```text
/// [Source Bloom<Iterable<E>>]
///        │ (Push-Dirty on list mutation)
///        ▼
/// [Keyed Divergence Engine]
///        ├─► Matches existing Key ──► Reuses existing mapped instance (preserves state)
///        ├─► New Key Detected      ──► Invokes convert() & caches mapped instance
///        └─► Removed Key           ──► Releases obsolete cached instance
///        │
///        ▼
/// [Output Bloom<List<T>>] (Composite list of cached and newly mapped instances)
/// ```
extension type BloomKeyedIterableElements<E>._(Bloom<Iterable<E>> _bloom) {
  /// Exposes the underlying [Bloom] node.
  Bloom<Iterable<E>> get bloom => _bloom;

  /// Maps an `Iterable` to a `List` of objects while safely caching the mapped objects by unique keys.
  ///
  /// This operator is highly optimized for maintaining expensive custom Dart objects
  /// (such as widgets, controllers, or ViewModels) across iterable state changes.
  /// By reusing instances whose keys haven't changed, this method minimizes object
  /// instantiation overhead and preserves local state within the mapped objects
  /// across frequent updates of the source iterable.
  ///
  /// * [key]: A function that extracts a unique identifier from a source element.
  /// * [convert]: A function that constructs a new mapped object `T` from a source element.
  /// * [update]: An optional callback invoked on the existing cached instance when a matching key
  ///   is found. Use this to update underlying data or reactive properties in the existing instance
  ///   (e.g., updating an immutable model reference inside a stable ViewModel) without recreating it.
  ///
  /// **Requires:**
  /// * The [key] function must return a stable, unique identifier for each logically
  ///   distinct element. Keys within the same source collection snapshot must be strictly unique;
  ///   duplicate keys violate collection integrity and trigger assertions in debug mode.
  ///
  /// **Ensures:**
  /// * Returns a `Bloom<List<T>>` containing the newly mapped or cached objects.
  /// * If a source element's key matches a cached object, the cached object is reused
  ///   instead of calling [convert] again. If [update] is provided, it is invoked on the cached instance.
  /// * If an unhandled exception is thrown inside [key], [convert], or [update], the node
  ///   transitions immediately to an error state without emitting partial results downstream.
  ///   The internal cache pool is atomically cleared (Fail-Safe Clean Slate) to prevent
  ///   partially corrupted instances from persisting across subsequent re-evaluations.
  ///
  /// **Identity Preservation vs. Pure Transformations:**
  /// - `.keyed.map()` is designed for stateful or expensive instances where identity must be preserved.
  /// - For pure, stateless data transformations (e.g. `(user) => user.name.toUpperCase()`),
  ///   use `.elements.map()` instead. Using `.keyed.map()` for pure value projections without
  ///   an `update` mechanism will yield stale data because [convert] is not re-evaluated for existing keys.
  ///
  /// **Warning (Anti-Pattern Prevention):**
  /// - Non-stable or random keys (e.g. `DateTime.now()` or `Object()`) defeat the keyed caching mechanism.
  ///   Always use persistent, immutable entity IDs.
  ///
  /// **BAD:**
  /// ```dart
  /// // [Anti-Pattern] Using unstable keys recreates mapped objects every frame
  /// final cardsBloom = usersBloom.keyed.map(
  ///   key: (user) => Object(), // New key each evaluation!
  ///   convert: (user) => UserCard(user),
  /// );
  /// ```
  ///
  /// **GOOD:**
  /// ```dart
  /// // [Recommended] Use stable unique entity IDs for keyed instance reuse
  /// final cardsBloom = usersBloom.keyed.map(
  ///   key: (user) => user.id,
  ///   convert: (user) => UserCardViewModel(user),
  ///   update: (vm, user) => vm.updateUser(user),
  /// );
  /// ```
  Bloom<List<T>> map<K, T>({
    required K Function(E data) key,
    required T Function(E data) convert,
    void Function(T cached, E data)? update,
  }) =>
      _KeyedMapBloom<E, K, T>(_bloom, key: key, convert: convert, update: update);
}

/// A dedicated proxy wrapper for [Bloom<List<E>>] to perform list-specific lookup and slicing computations.
extension type BloomListElements<E>._(Bloom<List<E>> _bloom) implements BloomIterableElements<E> {
  /// Look up the element at [index] reactively.
  ///
  /// * [index]: The zero-based position in the list.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<E>] holding the element at [index].
  Bloom<E> operator [](int index) => computed((via) => via(_bloom)[index]);

  /// Returns a reversed view of this list reactively.
  ///
  /// **Ensures:**
  /// * Returns an unmodifiable [Bloom<List<E>>] with elements in reverse order.
  Bloom<List<E>> get reversed => computed((via) => List.unmodifiable(via(_bloom).reversed));

  /// Returns the first index of [element] reactively.
  ///
  /// * [element]: The target element to search for.
  /// * [start]: The starting position for the search. Defaults to 0.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<int>] with the index of [element] or `-1` if not found.
  Bloom<int> indexOf(E element, [int start = 0]) => computed((via) => via(_bloom).indexOf(element, start));

  /// Returns the first index in the list that satisfies [test] reactively.
  ///
  /// * [test]: Predicate callback to evaluate list elements.
  /// * [start]: The starting position for the search. Defaults to 0.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<int>] with the first matching index or `-1` if none match.
  Bloom<int> indexWhere(bool Function(E element) test, [int start = 0]) =>
      computed((via) => via(_bloom).indexWhere(test, start));

  /// Returns the last index in the list that satisfies [test] reactively.
  ///
  /// * [test]: Predicate callback to evaluate list elements.
  /// * [start]: Optional starting position searching backward.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<int>] with the last matching index or `-1` if none match.
  Bloom<int> lastIndexWhere(bool Function(E element) test, [int? start]) =>
      computed((via) => via(_bloom).lastIndexWhere(test, start));

  /// Returns the last index of [element] reactively.
  ///
  /// * [element]: The target element to locate.
  /// * [start]: Optional starting position searching backward.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<int>] with the last occurrence index or `-1` if not found.
  Bloom<int> lastIndexOf(E element, [int? start]) => computed((via) => via(_bloom).lastIndexOf(element, start));

  /// Returns a sublist of this list reactively.
  ///
  /// * [start]: The beginning index (inclusive).
  /// * [end]: Optional ending index (exclusive).
  ///
  /// **Ensures:**
  /// * Returns an unmodifiable [Bloom<List<E>>] with the sliced subrange.
  Bloom<List<E>> sublist(int start, [int? end]) =>
      computed((via) => List.unmodifiable(via(_bloom).sublist(start, end)));

  /// Returns an unmodifiable [Map] view of this list reactively.
  ///
  /// **Ensures:**
  /// * Returns an unmodifiable [Bloom<Map<int, E>>] mapping indices to values.
  Bloom<Map<int, E>> asMap() => computed((via) => Map.unmodifiable(via(_bloom).asMap()));

  /// Adapts this list to be a `Bloom<List<T>>` reactively.
  ///
  /// **Ensures:**
  /// * Returns a type-cast [Bloom<List<T>>].
  Bloom<List<T>> cast<T>() => computed((via) => List.castFrom<E, T>(via(_bloom)));

  /// Returns an unmodifiable list containing all elements of this list reactively.
  ///
  /// **Ensures:**
  /// * Returns an immutable [Bloom<List<E>>].
  Bloom<List<E>> toUnmodifiable() => computed((via) => List.unmodifiable(via(_bloom)));
}

/// A dedicated proxy wrapper for [Bloom<Set<E>>] to perform set-specific operations while preserving set immutability.
extension type BloomSetElements<E>._(Bloom<Set<E>> _bloom) implements BloomIterableElements<E> {
  /// Looks up [object] in the set reactively.
  ///
  /// * [object]: The target object to lookup.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<E?>] yielding the matched object or `null` if absent.
  Bloom<E?> lookup(Object? object) => computed((via) => via(_bloom).lookup(object));

  /// Computes the intersection of this set and [other] reactively.
  ///
  /// * [other]: The secondary set to intersect with.
  ///
  /// **Ensures:**
  /// * Returns an unmodifiable [Bloom<Set<E>>] containing common elements.
  Bloom<Set<E>> intersection(Set<E> other) => computed((via) => Set.unmodifiable(via(_bloom).intersection(other)));

  /// Computes the union of this set and [other] reactively.
  ///
  /// * [other]: The secondary set to unite with.
  ///
  /// **Ensures:**
  /// * Returns an unmodifiable [Bloom<Set<E>>] containing elements from both sets.
  Bloom<Set<E>> union(Set<E> other) => computed((via) => Set.unmodifiable(via(_bloom).union(other)));

  /// Computes the difference between this set and [other] reactively.
  ///
  /// * [other]: The secondary set whose elements will be excluded.
  ///
  /// **Ensures:**
  /// * Returns an unmodifiable [Bloom<Set<E>>] containing elements not in [other].
  Bloom<Set<E>> difference(Set<E> other) => computed((via) => Set.unmodifiable(via(_bloom).difference(other)));

  /// Adapts this set to be a `Bloom<Set<T>>` reactively.
  ///
  /// **Ensures:**
  /// * Returns a type-cast [Bloom<Set<T>>].
  Bloom<Set<T>> cast<T>() => computed((via) => Set.castFrom<E, T>(via(_bloom)));

  /// Returns an unmodifiable set containing all elements of this set reactively.
  ///
  /// **Ensures:**
  /// * Returns an immutable [Bloom<Set<E>>].
  Bloom<Set<E>> toUnmodifiable() => computed((via) => Set.unmodifiable(via(_bloom)));
}

/// A dedicated proxy wrapper for [Bloom<Map<K, V>>] to perform map lookup, mapping, and filtering operations.
extension type BloomMapElements<K, V>._(Bloom<Map<K, V>> _bloom) {
  /// Exposes the underlying [Bloom] node of this elements proxy.
  Bloom<Map<K, V>> get bloom => _bloom;

  /// Look up the value associated with [key] reactively.
  ///
  /// * [key]: The key to locate in the map.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<V?>] holding the mapped value or `null` if absent.
  Bloom<V?> operator [](K key) => computed((via) => via(_bloom)[key]);

  /// Checks whether this map contains the given [key] reactively.
  ///
  /// * [key]: The key to check for presence.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<bool>] that is `true` if [key] exists in the map.
  Bloom<bool> containsKey(Object? key) => computed((via) => via(_bloom).containsKey(key));

  /// Checks whether this map contains the given [value] reactively.
  ///
  /// * [value]: The value to check for presence.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<bool>] that is `true` if [value] exists in the map.
  Bloom<bool> containsValue(Object? value) => computed((via) => via(_bloom).containsValue(value));

  /// Maps the entries of this map reactively to a new map.
  ///
  /// * [convert]: Mapping callback transforming key-value pairs into new [MapEntry] instances.
  ///
  /// **Ensures:**
  /// * Returns an unmodifiable [Bloom<Map<K2, V2>>] with the transformed entries.
  Bloom<Map<K2, V2>> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) convert) =>
      computed((via) => Map.unmodifiable(via(_bloom).map(convert)));

  /// Filters the entries of this map based on [test] reactively.
  ///
  /// * [test]: Predicate callback testing key-value pairs.
  ///
  /// **Ensures:**
  /// * Returns an unmodifiable [Bloom<Map<K, V>>] retaining only entries that satisfy [test].
  Bloom<Map<K, V>> where(bool Function(K key, V value) test) {
    return computed((via) {
      final source = via(_bloom);
      final filtered = Map<K, V>.from(source)..removeWhere((k, v) => !test(k, v));
      return Map.unmodifiable(filtered);
    });
  }

  /// Returns the keys of this map reactively.
  ///
  /// **Ensures:**
  /// * Returns an unmodifiable [Bloom<List<K>>] containing all map keys.
  Bloom<List<K>> get keys => computed((via) => List.unmodifiable(via(_bloom).keys));

  /// Returns the values of this map reactively.
  ///
  /// **Ensures:**
  /// * Returns an unmodifiable [Bloom<List<V>>] containing all map values.
  Bloom<List<V>> get values => computed((via) => List.unmodifiable(via(_bloom).values));

  /// Returns the number of key-value pairs reactively.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<int>] reflecting the map entry count.
  Bloom<int> get length => computed((via) => via(_bloom).length);

  /// Checks if this map is empty.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<bool>] that is `true` if the map contains no entries.
  Bloom<bool> get isEmpty => computed((via) => via(_bloom).isEmpty);

  /// Checks if this map is not empty.
  ///
  /// **Ensures:**
  /// * Returns a [Bloom<bool>] that is `true` if the map contains at least one entry.
  Bloom<bool> get isNotEmpty => computed((via) => via(_bloom).isNotEmpty);

  /// Adapts this map to be a `Bloom<Map<K2, V2>>` reactively.
  ///
  /// **Ensures:**
  /// * Returns a type-cast [Bloom<Map<K2, V2>>].
  Bloom<Map<K2, V2>> cast<K2, V2>() => computed((via) => Map.castFrom<K, V, K2, V2>(via(_bloom)));

  /// Returns an unmodifiable map containing all entries of this map reactively.
  ///
  /// **Ensures:**
  /// * Returns an immutable [Bloom<Map<K, V>>].
  Bloom<Map<K, V>> toUnmodifiable() => computed((via) => Map.unmodifiable(via(_bloom)));
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

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

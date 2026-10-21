// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

final class _KeyedMapBloom<E, K, T> extends _StaticUnaryRelay<Bloom<Iterable<E>>>
    with _BloomStateMixin<List<T>>, _PullResolver<List<T>>, _PullRelay<List<T>>
    implements Bloom<List<T>> {
  _KeyedMapBloom(
    super.inbound, {
    required K Function(E data) key,
    required T Function(E data) convert,
    void Function(T cached, E data)? update,
  })  : _keySelector = key,
        _convert = convert,
        _update = update;

  final K Function(E data) _keySelector;

  final T Function(E data) _convert;

  final void Function(T cached, E data)? _update;

  /// Internal map caching converted values [T] indexed by key [K].
  ///
  /// ### Cache Retention & Lifecycle:
  /// - **Do NOT clear on dirty marking or when source has error**:
  ///   When [_source] emits dirty notifications, node state is invalidated.
  ///   Clearing `_internalCache` on invalidation would defeat the caching purpose of
  ///   `keyed.map`, causing re-evaluation of `_convert` for existing keys.
  /// - **Fail-Safe Clean Slate on Unhandled Exception**:
  ///   Cleared when [_source] is empty (`_source.isEmpty`) or when an unhandled computation
  ///   exception occurs inside user callbacks ([_convert], [_update], [_keySelector]).
  ///   This guarantees transactional integrity: if an in-place mutation or transformation fails
  ///   mid-flight, partially mutated/corrupted instances are eradicated from the cache pool
  ///   rather than permanently lingering as invalid state or producing inconsistent downstream lists.
  /// - **Garbage Sweeping**: Inactive keys are removed via [Map.removeWhere] when cache
  ///   length exceeds active keys (Pigeonhole Principle).
  final Map<K, T> _internalCache = {};

  @override
  @pragma('vm:prefer-inline')
  _BloomState<List<T>> _pull() {
    _version++;
    return _state = _compute();
  }

  _BloomState<List<T>> _compute() {
    try {
      final source = _source._read();
      if (source.isEmpty) {
        _internalCache.clear();
        final reason = source.emptyReason;
        return reason != null ? _EmptyBloomState(reason) : const _EmptyBloomState();
      } else if (source.hasError) {
        return _ErrorBloomState(source.error, source.stackTrace);
      } else {
        final newResult = <T>[];
        final activeKeys = <K>{};

        try {
          for (final data in source.data) {
            final key = _keySelector(data);
            assert(
              !activeKeys.contains(key),
              'Duplicate key "$key" detected in keyed.map. '
              'Keys within the same collection snapshot must be strictly unique.',
            );
            activeKeys.add(key);
            var cached = _internalCache[key];
            // Architectural Invariant (Null Value Caching & Short-Circuit Performance):
            // 1. Hot Path (cached != null): 99.9% non-null values immediately short-circuit with 0 extra lookup.
            // 2. Cold Path (cached == null): When T is nullable and _convert() returned null,
            //    containsKey(key) distinguishes an explicitly cached null value from a true cache miss,
            //    preventing redundant re-execution of _convert(). DO NOT remove containsKey(key).
            if (cached != null || _internalCache.containsKey(key)) {
              final value = cached as T;
              _update?.call(value, data);
              newResult.add(value);
            } else {
              final converted = _convert(data);
              _internalCache[key] = converted;
              newResult.add(converted);
            }
          }
        } catch (error, stackTrace) {
          // Fail-Safe Clean Slate: eradicate potentially corrupted or partially-mutated
          // instances to guarantee a clean slate upon next successful evaluation.
          _internalCache.clear();
          return _ErrorBloomState(error, stackTrace);
        }

        // Optimization: Sweeping the internal cache via removeWhere is an O(N) operation.
        // By checking if the cache size exceeds activeKeys.length (Pigeonhole Principle),
        // we skip the full map traversal in O(1) when no keys have been removed.
        if (_internalCache.length > activeKeys.length) {
          _internalCache.removeWhere((key, _) => !activeKeys.contains(key));
        }

        final unmodifiable = List<T>.unmodifiable(newResult);
        final current = _state;
        if (current case final _ValidBloomState<List<T>> s) {
          s.update(unmodifiable);
          return s;
        }
        return _ValidBloomState<List<T>>(unmodifiable);
      }
    } catch (error, stackTrace) {
      return _ErrorBloomState(error, stackTrace);
    }
  }
}

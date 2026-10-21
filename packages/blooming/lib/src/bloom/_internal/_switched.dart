// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

// ============================================================================
// Dynamic Cascade (Switched Bloom)
// ============================================================================

/// Common functional selection mixin for dynamically switched implementations.
base mixin _SwitchedSelectionMixin<T> on _DeltaBloom<T> implements Bloom<T> {
  BloomGuard Function(BloomVia via)? get _guard;
  Bloom<T> Function(BloomVia via) get _select;

  @override
  bool get _isGuarded => _guard != null;

  @override
  Bloom<T> _evaluateDelta(BloomVia via) {
    final guard = _guard;
    if (guard != null) {
      final decision = guard.call(via);
      if (!decision.isPass) {
        return Bloom.empty(decision.reason);
      }
    }

    return _select(via);
  }
}

base class _LazySwitchedBloom<T> extends _LazyDeltaBloom<T> with _SwitchedSelectionMixin<T> {
  _LazySwitchedBloom({
    BloomGuard Function(BloomVia via)? guard,
    required Bloom<T> Function(BloomVia via) select,
  })  : _guard = guard,
        _select = select;

  @override
  final BloomGuard Function(BloomVia via)? _guard;
  @override
  final Bloom<T> Function(BloomVia via) _select;
}

base class _EagerSwitchedBloom<T> extends _EagerDeltaBloom<T> with _SwitchedSelectionMixin<T> {
  _EagerSwitchedBloom({
    BloomGuard Function(BloomVia via)? guard,
    required Bloom<T> Function(BloomVia via) select,
  })  : _guard = guard,
        _select = select;

  @override
  final BloomGuard Function(BloomVia via)? _guard;
  @override
  final Bloom<T> Function(BloomVia via) _select;
}

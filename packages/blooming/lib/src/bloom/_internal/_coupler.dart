// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

// =============================================================================
// Coupled Bloom Node
// =============================================================================

/// Internal reactive relay node for [BloomCoupler].
///
/// Implements [Bloom<T>] as a 1-tier relay node in the DAG, delegating its state
/// and edge connections dynamically to the currently coupled upstream source.
base class _CoupledBloom<T> extends _CoupledUnaryRelay<Bloom<T>>
    with _BloomStateMixin<T>
    implements Bloom<T>, LpdagStatus {
  _CoupledBloom(super.inbound);

  _CoupledBloom.late() : super.late();

  _CoupledBloom.error(Object error, [StackTrace? stackTrace]) : super(Bloom.error(error, stackTrace));

  bool _isResolving = false;

  @override
  @pragma('vm:prefer-inline')
  void _resolve() {
    if (_isResolving) {
      throw LpdagCycleError(
        'Cyclic coupling loop detected in $runtimeType while resolving upstream source.',
      );
    }
    _isResolving = true;
    try {
      _source._resolve();
      if (_source._version != _pulledVersion) {
        _version++;
        _pullVersion();
      }
    } finally {
      _isResolving = false;
    }
  }

  @override
  @pragma('vm:prefer-inline')
  _BloomState<T> _read() {
    _resolve();
    return _source._read();
  }

  @override
  Bloom<T> _catchEmpty() => Bloom.empty();

  @override
  Bloom<T> _catchError(Object error, StackTrace? stackTrace) => Bloom.error(error, stackTrace);
}

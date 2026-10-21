// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

// =============================================================================
// Foundation: Base Class & Pull Mixin
// =============================================================================

/// Abstract base class for reactive computed nodes that track dependencies via [_BloomViaEpochMixin].
abstract base class _ComputedBloomBase<T> extends _NaryRelay<_Node>
    with _BloomViaEpochMixin, _BloomStateMixin<T>, _PullResolver<T>, _PullRelay<T>
    implements Bloom<T> {}

/// Dynamic dependency tracking and compute execution mixin via [BloomVia].
///
/// Encapsulates explicit dependency tracking, guard evaluations, exception
/// isolation, and 1-pass epoch sweeping for any node that evaluates a [BloomVia] closure.
base mixin _ComputedPullMixin<T> on _PullResolver<T>, _BloomViaEpochMixin {
  T Function(BloomVia via) get _compute;
  BloomGuard Function(BloomVia via)? get _guard;

  @override
  @pragma('vm:prefer-inline')
  _BloomState<T> _pull() {
    if (this case final _Node node) {
      // Note: Version is bumped unconditionally on pull for zero-overhead performance.
      // Implicit Object.== checks are intentionally omitted to avoid virtual dispatch
      // penalties on hot paths and mutable state hazards. For value-equality early cutoff,
      // explicitly chain `.distinct([equals])`.
      node._version++;
    }
    final currentEpoch = _beginEpoch();
    _BloomState<T> state;
    var succeeded = true;
    try {
      final guard = _guard;
      if (guard != null) {
        final decision = guard(_via);
        if (!decision.isPass) {
          state = _EmptyBloomState<T>(decision.reason);
          return state;
        }
      }
      final result = _compute(_via);
      final current = _state;
      if (current case final _ValidBloomState<T> s) {
        s.update(result);
        state = s;
      } else {
        state = _ValidBloomState<T>(result);
      }
    } on _ViaShortCircuit catch (e) {
      succeeded = true;
      state = e.state._retype<T>();
    } catch (error, stackTrace) {
      succeeded = false;
      state = _BloomState.fromCaught(error, stackTrace);
    } finally {
      _endEpoch(currentEpoch, succeeded: succeeded, commitVersions: false);
    }
    return state;
  }
}

// =============================================================================
// 1. Synchronous Computed Nodes
// =============================================================================

/// A reactive [Bloom] node that computes its value dynamically with explicit [BloomVia] dependency tracking.
base class _ComputedBloom<T> extends _ComputedBloomBase<T> with _ComputedPullMixin<T> {
  _ComputedBloom(
    this._compute, {
    BloomGuard Function(BloomVia via)? guard,
  }) : _guard = guard;

  @override
  final T Function(BloomVia via) _compute;
  @override
  final BloomGuard Function(BloomVia via)? _guard;
}

/// Internal reactive node powering a [Computation] component.
base class _ComputationBloom<T> extends _ComputedBloomBase<T> {
  _ComputationBloom(this._computation);

  static Bloom<T> create<T>(Computation<T> computation) {
    try {
      if (computation is BloomLifecycleAware) {
        return _LifecycleAwareComputationBloom<T>(computation);
      }
      return _ComputationBloom<T>(computation);
    } catch (error, stackTrace) {
      return Bloom.error(error, stackTrace);
    }
  }

  final Computation<T> _computation;

  @override
  @pragma('vm:prefer-inline')
  _BloomState<T> _pull() {
    _version++;
    final currentEpoch = _beginEpoch();

    _BloomState<T> state;
    var succeeded = true;
    try {
      final decision = _computation.guard(_via);
      if (!decision.isPass) {
        state = _EmptyBloomState<T>(decision.reason);
      } else {
        final result = _computation.compute(_via);
        final current = _state;
        if (current case final _ValidBloomState<T> s) {
          s.update(result);
          state = s;
        } else {
          state = _ValidBloomState<T>(result);
        }
      }
    } on _ViaShortCircuit catch (e) {
      succeeded = true;
      state = e.state._retype<T>();
    } catch (error, stackTrace) {
      succeeded = false;
      state = _BloomState.fromCaught(error, stackTrace);
    } finally {
      _endEpoch(currentEpoch, succeeded: succeeded, commitVersions: false);
    }

    return _state = state;
  }
}

/// Lifecycle-aware variant of [_ComputationBloom].
base class _LifecycleAwareComputationBloom<T> extends _ComputationBloom<T> {
  _LifecycleAwareComputationBloom(super.computation);

  BloomLifecycleAware get _lifecycleAware => _computation as BloomLifecycleAware;

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _activate() {
    super._activate();
    try {
      _lifecycleAware.didActivate();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _deactivate() {
    super._deactivate();
    try {
      _lifecycleAware.didDeactivate();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }
}

// =============================================================================
// 2. Asynchronous Computed Nodes (Future & Stream)
// =============================================================================

/// Future-based asynchronous computation node backed by [_FutureBloomBridge] and dynamic delta.
final class _FutureComputedBloom<T> extends _EagerDeltaBloom<T> implements Bloom<T> {
  _FutureComputedBloom(
    Future<T> Function(BloomVia via) compute, {
    BloomGuard Function(BloomVia via)? guard,
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
  })  : _computeFuture = compute,
        _guard = guard,
        _initialFactory = initialFactory,
        _onError = onError;

  final Future<T> Function(BloomVia via) _computeFuture;
  final BloomGuard Function(BloomVia via)? _guard;
  final T Function()? _initialFactory;
  final T Function(Object error, [StackTrace? stackTrace])? _onError;

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
    final future = _computeFuture(via);
    return _FutureBloomBridge<T>(
      future,
      initialFactory: _initialFactory,
      onError: _onError,
    ).bloom;
  }
}

/// Stream-based asynchronous computation node backed by [_StreamBloomBridge] and dynamic delta.
final class _StreamComputedBloom<T> extends _EagerDeltaBloom<T> implements Bloom<T> {
  _StreamComputedBloom(
    Stream<T> Function(BloomVia via) compute, {
    BloomGuard Function(BloomVia via)? guard,
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  })  : _computeStream = compute,
        _guard = guard,
        _initialFactory = initialFactory,
        _onError = onError,
        _cancelOnError = cancelOnError,
        _distinct = distinct,
        _equals = equals,
        _graceful = graceful;

  final Stream<T> Function(BloomVia via) _computeStream;
  final BloomGuard Function(BloomVia via)? _guard;
  final T Function()? _initialFactory;
  final T Function(Object error, [StackTrace? stackTrace])? _onError;
  final bool? _cancelOnError;
  final bool _distinct;
  final bool Function(T previous, T next)? _equals;
  final Graceful? _graceful;

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
    final stream = _computeStream(via);
    return _StreamBloomBridge.create<T>(
      stream,
      initialFactory: _initialFactory,
      onError: _onError,
      cancelOnError: _cancelOnError,
      distinct: _distinct,
      equals: _equals,
      graceful: _graceful,
    ).bloom;
  }
}

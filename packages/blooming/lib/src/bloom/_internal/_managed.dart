// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

// ignore_for_file: must_call_super

abstract base class _ManagedBloom<T> extends _NaryRelay<_Node>
    with _BloomViaEpochMixin, _BloomStateMixin<T>, _PullResolver<T>, _PullRelay<T>
    implements Bloom<T> {
  _ManagedBloom({
    BloomGuard Function(BloomVia via)? guard,
    required T Function(BloomVia via) create,
    T Function(BloomVia via, T current)? update,
    required void Function(T resource) dispose,
  })  : _guard = guard,
        _createResource = create,
        _updateResource = update,
        _disposeResource = dispose;

  final BloomGuard Function(BloomVia via)? _guard;
  final T Function(BloomVia via) _createResource;
  final T Function(BloomVia via, T current)? _updateResource;
  final void Function(T resource) _disposeResource;

  void _disposeCurrent() {
    final oldState = _state;
    _state = null;
    _dirtyState = _DirtyState.dirty;
    if (oldState != null && oldState.hasData) {
      try {
        _disposeResource.call(oldState.data);
      } catch (error, stackTrace) {
        _handleUncaughtError(error, stackTrace);
      }
    }
  }

  @override
  @pragma('vm:prefer-inline')
  _BloomState<T> _pull() {
    final currentEpoch = _beginEpoch();
    var succeeded = true;
    try {
      final guard = _guard;
      if (guard != null) {
        final decision = guard(_via);
        if (!decision.isPass) {
          final oldState = _state;
          _disposeCurrent();
          final reason = decision.reason;
          if (oldState is! _EmptyBloomState<T> || !identical(oldState.emptyReason, reason)) {
            _version++;
          }
          return _state = reason != null ? _EmptyBloomState<T>(reason) : const _EmptyBloomState();
        }
      }

      final currentState = _state;
      if (currentState != null && currentState.hasData && _updateResource != null) {
        final current = currentState.data;
        final next = _updateResource.call(_via, current);
        if (!identical(current, next)) {
          _version++;
          try {
            _disposeResource.call(current);
          } catch (error, stackTrace) {
            _handleUncaughtError(error, stackTrace);
          }
        }
        if (currentState case final _ValidBloomState<T> s) {
          s.update(next);
          return _state = s;
        } else {
          return _state = _ValidBloomState(next);
        }
      } else {
        _disposeCurrent();
        _version++;
        final res = _createResource.call(_via);
        final current = _state;
        if (current case final _ValidBloomState<T> s) {
          s.update(res);
          return _state = s;
        } else {
          return _state = _ValidBloomState(res);
        }
      }
    } on _ViaShortCircuit catch (e) {
      succeeded = true;
      _disposeCurrent();
      _version++;
      return _state = e.state._retype<T>();
    } catch (error, stackTrace) {
      succeeded = false;
      _disposeCurrent();
      _version++;
      return _state = _BloomState.fromCaught(error, stackTrace);
    } finally {
      _endEpoch(currentEpoch, succeeded: succeeded, commitVersions: false);
    }
  }

  @override
  @pragma('vm:prefer-inline')
  void _resolve() {
    if (_isResolving) {
      throw LpdagCycleError(
        'Cyclic evaluation loop detected in $runtimeType while resolving state.',
      );
    }
    if (!_lifecycle.isActive) {
      _state ??= _EmptyBloomState<T>();
      return;
    }
    super._resolve();
  }

  @override
  @pragma('vm:prefer-inline')
  _BloomState<T> _read() {
    _resolve();
    return _state ??= _EmptyBloomState<T>();
  }

  @mustCallSuper
  @override
  void _activate() {
    super._activate();
    if (_state != null && !_state!.hasData) {
      _state = null;
      _dirtyState = _DirtyState.dirty;
    }
  }

  @mustCallSuper
  @override
  void _deactivate() {
    _disposeCurrent();
    super._deactivate();
  }

  @mustCallSuper
  @override
  void _debugInvalidateSelf() {
    _disposeCurrent();
    super._debugInvalidateSelf();
  }
}

/// Lifecycle-managed resource node with on-demand Lazy allocation and updates.
base class _LazyManagedBloom<T> extends _ManagedBloom<T> {
  _LazyManagedBloom({
    super.guard,
    required super.create,
    super.update,
    required super.dispose,
  });
}

/// Eager variant of [_ManagedBloom] that pre-emptively allocates and updates in microtask.
base class _EagerManagedBloom<T> extends _ManagedBloom<T> implements _EagerSchedulable {
  _EagerManagedBloom({
    super.guard,
    required super.create,
    super.update,
    required super.dispose,
  });

  @mustCallSuper
  @override
  void _activate() {
    super._activate();
    if (_dirtyState != _DirtyState.clean || _state == null || !_state!.hasData) {
      _resolve();
    }
  }

  @mustCallSuper
  @override
  void _deactivate() {
    _Scheduler.instance._cancelEager(this);
    super._deactivate();
  }

  @override
  void _invalidate() {
    super._invalidate();
    if (_lifecycle.isActive) {
      _Scheduler.instance._scheduleEager(this);
    }
  }

  @override
  void _performScheduledEager() {
    if (!_lifecycle.isActive || _dirtyState == _DirtyState.clean) return;
    _resolve();
  }
}

/// Lifecycle-managed resource node with graceful deactivation (Lazy).
final class _LazyGracefulManagedBloom<T> extends _LazyManagedBloom<T> with _GracefulNodeMixin {
  _LazyGracefulManagedBloom({
    super.guard,
    required super.create,
    super.update,
    required super.dispose,
    required Graceful graceful,
  }) : _graceful = graceful;

  @override
  final Graceful _graceful;
}

/// Lifecycle-managed resource node with graceful deactivation (Eager).
final class _EagerGracefulManagedBloom<T> extends _EagerManagedBloom<T> with _GracefulNodeMixin {
  _EagerGracefulManagedBloom({
    super.guard,
    required super.create,
    super.update,
    required super.dispose,
    required Graceful graceful,
  }) : _graceful = graceful;

  @override
  final Graceful _graceful;
}

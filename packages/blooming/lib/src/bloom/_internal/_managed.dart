// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

// ignore_for_file: must_call_super

abstract base class _ManagedBloom<T> extends _NaryRelay<_Node>
    with _ViaEpochMixin<BloomVia>, _BloomViaEpochMixin, _BloomStateMixin<T>, _PullResolver<T>, _PullRelay<T>
    implements Bloom<T> {
  _ManagedBloom({
    void Function(BloomVia via)? guard,
    required T Function(BloomVia via) create,
    T Function(BloomVia via, T current)? update,
    required void Function(T resource) dispose,
  })  : _guard = guard,
        _createResource = create,
        _updateResource = update,
        _disposeResource = dispose;

  final void Function(BloomVia via)? _guard;
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
    final oldState = _state;
    try {
      _guard?.call(_via);

      final currentState = _state;
      if (currentState != null && currentState.hasData && _updateResource != null) {
        final current = currentState.data;
        final next = _updateResource.call(_via, current);
        _switchViaScope(next);
        _version++;
        if (!identical(current, next)) {
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
        final res = _createResource.call(_via);
        _switchViaScope(res);
        _version++;
        return _state = _ValidBloomState(res);
      }
    } on _ViaShortCircuit catch (e) {
      succeeded = true;
      _disposeCurrent();
      final newState = e.state._retype<T>();
      final isSameEmpty = oldState is _EmptyBloomState<T> &&
          newState is _EmptyBloomState<T> &&
          identical(oldState.emptyReason, newState.emptyReason);
      if (!isSameEmpty) {
        _version++;
      }
      return _state = newState;
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

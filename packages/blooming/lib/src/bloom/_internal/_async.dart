// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

/// [Easter Egg Base] Named after the DeLorean time machine from *Back to the Future*.
/// Provides time-traveling async value injection into the Bloom topology upon arrival.
base class _DeLorean<T> {
  _DeLorean(
    Future<T> future, {
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
  })  : _future = future,
        _onError = onError {
    _pendingController = blooming<bool>(true);
    if (initialFactory != null) {
      try {
        final early = initialFactory();
        _controller = blooming<T>(early);
      } catch (e, s) {
        _controller = blooming.error<T>(e, stackTrace: s);
      }
    } else {
      _controller = blooming.late<T>();
    }
    _backToTheFuture();
  }

  final Future<T> _future;
  final T Function(Object error, [StackTrace? stackTrace])? _onError;

  late final BloomController<T> _controller;
  late final BloomController<bool> _pendingController;

  /// Immediately attaches listeners to [_future] upon construction to prevent unhandled
  /// asynchronous errors in the Dart event loop if the future completes with error while dormant.
  void _backToTheFuture() {
    try {
      _future.then(
        (value) {
          _controller.set(value);
          _pendingController.set(false);
        },
        onError: (Object error, StackTrace stackTrace) {
          try {
            final onError = _onError;
            if (onError != null) {
              try {
                _controller.set(onError.call(error, stackTrace));
                return;
              } catch (e, s) {
                _controller.setError(e, s);
                return;
              }
            }
            _controller.setError(error, stackTrace);
          } finally {
            _pendingController.set(false);
          }
        },
      );
    } catch (error, stackTrace) {
      // Synchronous failure in `_future.then` itself is a contract violation, not a Future completion error.
      // Bypass `_onError` so structural errors are never silently masked as fallback data.
      _controller.setError(error, stackTrace);
      _pendingController.set(false);
    }
  }

  Bloom<T> get bloom => _controller.bloom;

  Bloom<bool> get pending => _pendingController.bloom;

  ({Bloom<T> data, Bloom<bool> pending}) get tuple => (data: bloom, pending: pending);

  bool get isActive => _controller.isActive || _pendingController.isActive;
}

/// Formal reactive bridge connecting a native Dart [Future] to the [Bloom] topology.
final class _FutureBloomBridge<T> extends _DeLorean<T> {
  _FutureBloomBridge(
    super.future, {
    super.initialFactory,
    super.onError,
  });
}

/// [Easter Egg Base] Factory variant of [_DeLorean] that defers flux-capacitor ignition
/// (invoking the [Future] factory) until downstream consumers actively observe the node,
/// and enforces a strict bulkhead by spawning a brand-new [_FutureBloomBridge] on each turn.
base class _FactoryDeLorean<T> with _AsyncFactoryMixin<T> {
  _FactoryDeLorean(
    Future<T> Function() futureFactory, {
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    Graceful? graceful,
  })  : _futureFactory = futureFactory,
        _initialFactory = initialFactory,
        _onError = onError {
    _initFactoryProxies(graceful);
  }

  final Future<T> Function() _futureFactory;
  @override
  final T Function()? _initialFactory;
  @override
  final T Function(Object error, [StackTrace? stackTrace])? _onError;

  @override
  void _activateBridge() {
    try {
      final future = _futureFactory();
      // Spawn a brand-new isolated bridge (with fresh internal Bloom instances) for this turn.
      final bridge = _FutureBloomBridge<T>(
        future,
        initialFactory: _initialFactory,
        onError: _onError,
      );
      // _dataProxy is not active yet (called before super._activate()), so notify = false.
      // super._activate() will immediately attach to bridge.bloom and pull its fresh state.
      _dataProxy._performCouple(bridge.bloom, false);
      _pendingProxy._performCouple(bridge.pending, true);
    } catch (error, stackTrace) {
      _dataProxy._performCouple(_resolveErrorBloom(error, stackTrace), false);
      _pendingProxy._performCouple(Bloom<bool>.constant(false), true);
    }
  }

  @override
  void _deactivateBridge() {
    // Immediately replace the coupled Bloom with a brand-new initial Bloom before any
    // future reactivation, guaranteeing a complete bulkhead from the previous Future's traces.
    _dataProxy._performCouple(_createFreshInitialBloom(), false);
    _pendingProxy._performCouple(Bloom<bool>.constant(false), true);
  }

  bool get isActive => _dataProxy.isActive || _pendingProxy.isActive;
}

/// Formal reactive bridge connecting a Dart [Future] factory to the [Bloom] topology.
final class _FutureFactoryBloomBridge<T> extends _FactoryDeLorean<T> {
  _FutureFactoryBloomBridge(
    super.futureFactory, {
    super.initialFactory,
    super.onError,
    super.graceful,
  });
}

/// [Easter Egg Base] Named after Smetana's symphonic poem *Vltava* flowing through Prague.
/// Represents a majestic, continuous asynchronous stream river flowing into the Bloom topology.
base class _PragueVltava<T> {
  _PragueVltava(
    this._stream, {
    T Function()? initialFactory,
    this.onError,
    this.cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  }) {
    _pendingController = blooming<bool>(
      false,
      distinct: distinct,
    );
    if (initialFactory != null) {
      try {
        _controller = blooming<T>(
          initialFactory(),
          distinct: distinct,
          equals: equals,
          graceful: graceful,
          onActivated: _subscribe,
          onDeactivated: _unsubscribe,
        );
      } catch (e, s) {
        _controller = blooming.error<T>(
          e,
          stackTrace: s,
          distinct: distinct,
          equals: equals,
          graceful: graceful,
          onActivated: _subscribe,
          onDeactivated: _unsubscribe,
        );
      }
    } else {
      _controller = blooming.late<T>(
        distinct: distinct,
        equals: equals,
        graceful: graceful,
        onActivated: _subscribe,
        onDeactivated: _unsubscribe,
      );
    }
    _doneController = blooming<bool>(
      false,
      distinct: distinct,
    );
  }

  final Stream<T> _stream;
  final T Function(Object error, [StackTrace? stackTrace])? onError;
  final bool? cancelOnError;

  late final BloomController<T> _controller;
  late final BloomController<bool> _pendingController;
  late final BloomController<bool> _doneController;

  StreamSubscription<T>? _subscription;

  bool _isDone = false;

  void _subscribe() {
    // Only guard when the stream has naturally completed (`onDone`) or is already subscribed.
    // Do NOT set `_isDone` on mid-flight deactivation (`1 -> 0`) or `cancelOnError == true`:
    // - Broadcast streams must be allowed to re-subscribe and recover on reactivation (`0 -> 1`).
    // - Canceled single-subscription streams must fail fast with `StateError` on reactivation
    //   rather than silently freezing on incomplete/partial data (use `(() => stream).toBloom()` instead).
    if (_isDone || _subscription != null) return;

    _pendingController.set(true);

    try {
      _subscription = _stream.listen(
        (value) {
          _controller.set(value);
          _pendingController.set(false);
        },
        onError: (Object error, StackTrace stackTrace) {
          try {
            if (onError != null) {
              try {
                _controller.set(onError!.call(error, stackTrace));
              } catch (e, s) {
                _controller.setError(e, s);
              }
            } else {
              _controller.setError(error, stackTrace);
            }
            // Deliberately keep `_isDone == false` here instead of marking it done:
            // - Although marking `_isDone = true` would preserve the error/fallback state on a fixed
            //   single-subscription stream across `1 -> 0 -> 1`, it would permanently block broadcast
            //   streams from re-subscribing and recovering on the next `0 -> 1` activation.
            // - Single-subscription streams requiring reactivation recovery should use `(() => stream).toBloom()`.
            if (cancelOnError == true) _unsubscribe();
          } finally {
            _pendingController.set(false);
          }
        },
        onDone: () {
          _isDone = true;
          _doneController.set(true);
          _unsubscribe();
        },
        cancelOnError: cancelOnError,
      );
    } catch (error, stackTrace) {
      // Synchronous failure in `_stream.listen` itself (e.g., `StateError` when re-listening
      // to a canceled single-subscription stream) is a lifecycle violation, not a stream error event.
      // Bypass `onError` so `StateError` is never silently masked as fallback data.
      _controller.setError(error, stackTrace);
      _pendingController.set(false);
    }
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
    _pendingController.set(false);
  }

  Bloom<T> get bloom => _controller.bloom;

  Bloom<bool> get pending => _pendingController.bloom;

  Bloom<bool> get done => _doneController.bloom;

  ({Bloom<T> data, Bloom<bool> pending}) get tuple => (data: bloom, pending: pending);

  ({Bloom<T> data, Bloom<bool> pending, Bloom<bool> done}) get triple => (data: bloom, pending: pending, done: done);
}

/// Formal reactive bridge connecting a native Dart [Stream] to the [Bloom] topology.
final class _StreamBloomBridge<T> extends _PragueVltava<T> {
  _StreamBloomBridge(
    super.stream, {
    super.initialFactory,
    super.onError,
    super.cancelOnError,
    super.distinct = true,
    super.equals,
    super.graceful,
  });

  /// Factory creating the reactive stream bridge.
  static _StreamBloomBridge<T> create<T>(
    Stream<T> stream, {
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  }) {
    return _StreamBloomBridge<T>(
      stream,
      initialFactory: initialFactory,
      onError: onError,
      cancelOnError: cancelOnError,
      distinct: distinct,
      equals: equals,
      graceful: graceful,
    );
  }
}

/// [Easter Egg Base] Factory variant of [_PragueVltava] that spawns a brand-new isolated
/// [_StreamBloomBridge] per activation cycle and immediately resets to a fresh initial
/// [Bloom] upon deactivation to maintain a strict bulkhead.
base class _FactoryPragueVltava<T> with _AsyncFactoryMixin<T> {
  _FactoryPragueVltava(
    Stream<T> Function() streamFactory, {
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    this.cancelOnError,
    this.distinct = true,
    this.equals,
    Graceful? graceful,
  })  : _streamFactory = streamFactory,
        _initialFactory = initialFactory,
        _onError = onError {
    _initFactoryProxies(graceful);
    _doneProxy = _CoupledBloom<bool>(Bloom<bool>.constant(false));
  }

  final Stream<T> Function() _streamFactory;
  @override
  final T Function()? _initialFactory;
  @override
  final T Function(Object error, [StackTrace? stackTrace])? _onError;
  final bool? cancelOnError;
  final bool distinct;
  final bool Function(T previous, T next)? equals;

  late final _CoupledBloom<bool> _doneProxy;

  @override
  void _activateBridge() {
    try {
      final stream = _streamFactory();
      // Spawn a brand-new isolated bridge (with fresh internal Bloom instances) for this turn.
      final bridge = _StreamBloomBridge<T>(
        stream,
        initialFactory: _initialFactory,
        onError: _onError,
        cancelOnError: cancelOnError,
        distinct: distinct,
        equals: equals,
      );
      // _dataProxy is not active yet (called before super._activate()), so notify = false.
      // super._activate() will immediately attach to bridge.bloom, triggering _subscribe().
      _dataProxy._performCouple(bridge.bloom, false);
      _pendingProxy._performCouple(bridge.pending, true);
      _doneProxy._performCouple(bridge.done, true);
    } catch (error, stackTrace) {
      _dataProxy._performCouple(_resolveErrorBloom(error, stackTrace), false);
      _pendingProxy._performCouple(Bloom<bool>.constant(false), true);
      _doneProxy._performCouple(Bloom<bool>.constant(false), true);
    }
  }

  @override
  void _deactivateBridge() {
    // Immediately replace the coupled Blooms with brand-new initial Blooms before any
    // future reactivation, guaranteeing a complete bulkhead from the previous Stream's traces.
    _dataProxy._performCouple(_createFreshInitialBloom(), false);
    _pendingProxy._performCouple(Bloom<bool>.constant(false), true);
    _doneProxy._performCouple(Bloom<bool>.constant(false), true);
  }

  Bloom<bool> get done => _doneProxy;

  ({Bloom<T> data, Bloom<bool> pending, Bloom<bool> done}) get triple => (data: bloom, pending: pending, done: done);
}

/// Formal reactive bridge connecting a Dart [Stream] factory to the [Bloom] topology.
final class _StreamFactoryBloomBridge<T> extends _FactoryPragueVltava<T> {
  _StreamFactoryBloomBridge(
    super.streamFactory, {
    super.initialFactory,
    super.onError,
    super.cancelOnError,
    super.distinct = true,
    super.equals,
    super.graceful,
  });

  /// Factory creating the reactive stream factory bridge.
  static _StreamFactoryBloomBridge<T> create<T>(
    Stream<T> Function() streamFactory, {
    T Function()? initialFactory,
    T Function(Object error, [StackTrace? stackTrace])? onError,
    bool? cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  }) {
    return _StreamFactoryBloomBridge<T>(
      streamFactory,
      initialFactory: initialFactory,
      onError: onError,
      cancelOnError: cancelOnError,
      distinct: distinct,
      equals: equals,
      graceful: graceful,
    );
  }
}

/// Shared mixin providing identical proxy initialization, initial/error [Bloom] resolution,
/// and common getters for asynchronous factory bridges ([_FactoryDeLorean] & [_FactoryPragueVltava]).
base mixin _AsyncFactoryMixin<T> {
  T Function()? get _initialFactory;
  T Function(Object error, [StackTrace? stackTrace])? get _onError;

  late final _LifecycleCoupledBloom<T> _dataProxy;
  late final _CoupledBloom<bool> _pendingProxy;

  void _activateBridge();
  void _deactivateBridge();

  void _initFactoryProxies(Graceful? graceful) {
    final initialBloom = _createFreshInitialBloom();
    _pendingProxy = _CoupledBloom<bool>(Bloom<bool>.constant(false));
    if (graceful != null) {
      _dataProxy = _GracefulLifecycleCoupledBloom<T>(
        initialBloom,
        graceful: graceful,
        onActivate: _activateBridge,
        onDeactivate: _deactivateBridge,
      );
    } else {
      _dataProxy = _LifecycleCoupledBloom<T>(
        initialBloom,
        onActivate: _activateBridge,
        onDeactivate: _deactivateBridge,
      );
    }
  }

  Bloom<T> _createFreshInitialBloom() {
    final initialFactory = _initialFactory;
    if (initialFactory != null) {
      try {
        return Bloom<T>.constant(initialFactory());
      } catch (e, s) {
        return Bloom<T>.error(e, s);
      }
    }
    return Bloom<T>.empty();
  }

  Bloom<T> _resolveErrorBloom(Object error, StackTrace stackTrace) {
    final onError = _onError;
    if (onError != null) {
      try {
        return Bloom<T>.constant(onError.call(error, stackTrace));
      } catch (e, s) {
        return Bloom<T>.error(e, s);
      }
    }
    return Bloom<T>.error(error, stackTrace);
  }

  Bloom<T> get bloom => _dataProxy;

  Bloom<bool> get pending => _pendingProxy;

  ({Bloom<T> data, Bloom<bool> pending}) get tuple => (data: bloom, pending: pending);
}

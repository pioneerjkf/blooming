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
    _pendingController = BloomController<bool>(true);
    if (initialFactory != null) {
      try {
        final early = initialFactory();
        _controller = BloomController<T>(early);
      } catch (e, s) {
        _controller = BloomController<T>.error(e, stackTrace: s);
      }
    } else {
      _controller = BloomController<T>.late();
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

/// [Easter Egg Base] Named after Smetana's symphonic poem *Vltava* flowing through Prague.
/// Represents a majestic, continuous asynchronous stream river flowing into the Bloom topology.
base class _PragueVltava<T> {
  _PragueVltava(
    Stream<T> stream, {
    T Function()? initialFactory,
    this.onError,
    this.cancelOnError,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  }) : _stream = stream {
    if (initialFactory != null) {
      _pendingController = BloomController<bool>(
        false,
        distinct: distinct,
        graceful: graceful,
        onActivated: _handleActivated,
        onDeactivated: _handleDeactivated,
      );
      try {
        _controller = BloomController<T>(
          initialFactory(),
          distinct: distinct,
          equals: equals,
          graceful: graceful,
          onActivated: _handleActivated,
          onDeactivated: _handleDeactivated,
        );
      } catch (e, s) {
        _controller = BloomController<T>.error(
          e,
          stackTrace: s,
          distinct: distinct,
          equals: equals,
          graceful: graceful,
          onActivated: _handleActivated,
          onDeactivated: _handleDeactivated,
        );
      }
    } else {
      _pendingController = BloomController<bool>(
        true,
        distinct: distinct,
        graceful: graceful,
        onActivated: _handleActivated,
        onDeactivated: _handleDeactivated,
      );
      _controller = BloomController<T>.late(
        distinct: distinct,
        equals: equals,
        graceful: graceful,
        onActivated: _handleActivated,
        onDeactivated: _handleDeactivated,
      );
    }
    _doneController = BloomController<bool>(
      false,
      distinct: distinct,
      graceful: graceful,
      onActivated: _handleActivated,
      onDeactivated: _handleDeactivated,
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

  bool get _isActive => _controller.isActive || _pendingController.isActive || _doneController.isActive;

  void _handleActivated() {
    if (_subscription == null) {
      _subscribe();
    }
  }

  void _handleDeactivated() {
    if (!_isActive) {
      _unsubscribe();
    }
  }

  void _subscribe() {
    if (_isDone) return;

    if (_subscription != null) {
      throw StateError('Already subscribed to Stream(-> $_stream).');
    }

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
            if (cancelOnError == true) _unsubscribe();
          } finally {
            _pendingController.set(false);
          }
        },
        onDone: () {
          _isDone = true;
          _pendingController.set(false);
          _doneController.set(true);
          _unsubscribe();
        },
        cancelOnError: cancelOnError,
      );
    } catch (error, stackTrace) {
      try {
        if (onError != null) {
          try {
            _controller.set(onError!.call(error, stackTrace));
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
    }
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  Bloom<T> get bloom => _controller.bloom;

  Bloom<bool> get pending => _pendingController.bloom;

  Bloom<bool> get done => _doneController.bloom;

  ({Bloom<T> data, Bloom<bool> pending}) get tuple => (data: bloom, pending: pending);

  bool get isActive => _isActive;
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

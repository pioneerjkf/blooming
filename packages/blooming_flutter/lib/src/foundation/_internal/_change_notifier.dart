// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../framework.dart';

// =============================================================================
// Internal ValueListenable <-> Bloom Pipes & Listenables
// =============================================================================

final class _ValueListenableBloomPipe<T> {
  /// Creates a demand-driven bridge pipe wrapping [listenable].
  _ValueListenableBloomPipe(
    ValueListenable<T> listenable, {
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  }) : _listenable = listenable {
    _controller = BloomController<T>(
      listenable.value,
      distinct: distinct,
      equals: equals,
      graceful: graceful,
      onActivated: _onActivate,
      onDeactivated: _onDeactivate,
    );
  }

  final ValueListenable<T> _listenable;
  late final BloomController<T> _controller;

  /// Activates the bridge, synchronizing the current value and registering the listener.
  void _onActivate() {
    _controller.setGuarded(() => _listenable.value);
    _listenable.addListener(_listen);
  }

  /// Deactivates the bridge, removing the listener from the source listenable.
  void _onDeactivate() {
    _listenable.removeListener(_listen);
  }

  /// Handles incoming notifications from the source listenable.
  void _listen() {
    _controller.setGuarded(() => _listenable.value);
  }

  /// The read-only [Bloom<T>] consumer view of this bridge.
  Bloom<T> get bloom => _controller.bloom;
}

/// An internal demand-driven selector pipe extracting a derived reactive slice [R] from a [Listenable] [N].
///
/// Evaluates `select` upon construction with fault containment: exceptions thrown during initial
/// slice evaluation initialize the underlying [BloomController] into an Error state rather than aborting
/// element inflation. When active, subsequent notifications re-evaluate `select` via `setGuarded`.
final class _ListenableSelectorBloomPipe<N extends Listenable, R> {
  /// Creates a demand-driven selector pipe extracting [R] from [listenable] via [select].
  _ListenableSelectorBloomPipe(
    N listenable, {
    required R Function(N target) select,
    bool distinct = true,
    bool Function(R previous, R next)? equals,
    Graceful? graceful,
  })  : _listenable = listenable,
        _select = select {
    try {
      _controller = BloomController<R>(
        select(listenable),
        distinct: distinct,
        equals: equals,
        graceful: graceful,
        onActivated: _onActivate,
        onDeactivated: _onDeactivate,
      );
    } catch (error, stackTrace) {
      _controller = BloomController<R>.error(
        error,
        stackTrace: stackTrace,
        distinct: distinct,
        equals: equals,
        graceful: graceful,
        onActivated: _onActivate,
        onDeactivated: _onDeactivate,
      );
    }
  }

  final N _listenable;
  final R Function(N target) _select;
  late final BloomController<R> _controller;

  /// Activates the selector pipe, pulling the latest value and registering the listener.
  void _onActivate() {
    _controller.setGuarded(() => _select(_listenable));
    _listenable.addListener(_listen);
  }

  /// Deactivates the selector pipe, removing the listener from the source listenable.
  void _onDeactivate() {
    _listenable.removeListener(_listen);
  }

  /// Handles incoming notifications by re-evaluating `select` within `setGuarded`.
  void _listen() {
    _controller.setGuarded(() => _select(_listenable));
  }

  /// The read-only [Bloom<R>] consumer view of this selector pipe.
  Bloom<R> get bloom => _controller.bloom;
}

final class _ListenerEdge {
  _ListenerEdge(this.listener);

  final VoidCallback listener;
  _ListenerEdge? next;
  _ListenerEdge? prev;
}

/// An internal [ValueListenable] adapter exposing a reactive [Bloom] node to Flutter consumers.
///
/// Manages a demand-driven [RawBloomTerminal] that is moored to the reactive DAG if and only if
/// one or more Flutter listeners are registered. Dispatches listener callbacks with individual
/// exception containment via [FlutterError.reportError].
///
/// Uses an intrusive doubly-linked list for zero-allocation traversal and O(1) safe mutation
/// during notification dispatching via [_notifyingTarget] caching.
final class _BloomValueListenable<T> implements ValueListenable<T> {
  /// Creates a [ValueListenable] adapter backed by [_bloom].
  _BloomValueListenable(this._bloom, {this.sync = true});

  final Bloom<T> _bloom;

  /// Whether mutations dispatch notifications synchronously (`true`) or coalesce into microtasks (`false`).
  final bool sync;

  _ListenerEdge? _head;
  _ListenerEdge? _tail;
  _ListenerEdge? _notifyingTarget;
  RawBloomTerminal<T>? _terminal;

  @override
  T get value => untracked(_bloom);

  @override
  void addListener(VoidCallback listener) {
    final edge = _ListenerEdge(listener);
    final wasEmpty = _head == null;

    if (wasEmpty) {
      _head = _tail = edge;
    } else {
      _tail!.next = edge;
      edge.prev = _tail;
      _tail = edge;
    }

    if (wasEmpty) {
      if (_terminal case final terminal?) {
        terminal.activate();
      } else {
        final effectiveSource = sync ? _bloom : _bloom.coalesced();
        _terminal = RawBloomTerminal<T>(
          effectiveSource,
          onInvalidated: _notify,
        )..activate();
      }
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    var curr = _head;
    while (curr != null) {
      if (curr.listener == listener) {
        if (identical(_notifyingTarget, curr)) {
          _notifyingTarget = curr.next;
        }

        final prev = curr.prev;
        final next = curr.next;

        if (prev != null) {
          prev.next = next;
        } else {
          _head = next;
        }
        if (next != null) {
          next.prev = prev;
        } else {
          _tail = prev;
        }

        curr.prev = null;
        curr.next = null;

        if (_head == null) {
          _terminal?.deactivate();
        }
        break;
      }
      curr = curr.next;
    }
  }

  /// Notifies all registered listeners safely, catching and reporting any callback errors.
  /// Listeners removed during traversal advance [_notifyingTarget] to prevent post-dispose callbacks.
  void _notify() {
    final prevNotifying = _notifyingTarget;
    _notifyingTarget = _head;
    try {
      while (_notifyingTarget != null) {
        final curr = _notifyingTarget!;
        _notifyingTarget = curr.next;
        try {
          curr.listener();
        } catch (error, stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'blooming_flutter',
              context: ErrorDescription(
                'while notifying listener in _BloomValueListenable',
              ),
            ),
          );
        }
      }
    } finally {
      _notifyingTarget = prevNotifying;
    }
  }
}

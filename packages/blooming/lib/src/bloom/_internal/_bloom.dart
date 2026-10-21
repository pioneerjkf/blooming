// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

base class _ConstantBloom<T> extends Bloom<T> with _BloomStateMixin<T> {
  _ConstantBloom(T data)
      : _state = _ValidBloomState<T>(data),
        super._();

  _ConstantBloom.error(Object error, [StackTrace? stackTrace])
      : _state = _ErrorBloomState<T>(error, stackTrace),
        super._();

  _ConstantBloom.empty([Object? emptyReason])
      : _state = _EmptyBloomState<T>(emptyReason),
        super._();

  @override
  @pragma('vm:prefer-inline')
  bool _isNewerThan(int version) => false;

  final _BloomState<T> _state;

  @override
  @pragma('vm:prefer-inline')
  _BloomState<T> _read() => _state;
}

/// Internal reactive node filtering out consecutive duplicate payloads.
final class _DistinctBloom<T> extends _StaticUnaryRelay<Bloom<T>>
    with _BloomStateMixin<T>, _PullResolver<T>, _PullRelay<T>
    implements Bloom<T> {
  _DistinctBloom(super.source, {bool Function(T previous, T next)? equals}) : _equals = equals;

  final bool Function(T previous, T next)? _equals;

  @override
  @pragma('vm:prefer-inline')
  _BloomState<T> _pull() {
    final source = _source._read();
    final prev = _state;

    if (prev != null) {
      if (source is _ValidBloomState) {
        if (prev case final _ValidBloomState<T> p) {
          final prevData = p.data;
          final nextData = source.data;
          bool isUnchanged = false;
          try {
            isUnchanged =
                identical(prevData, nextData) || (null != _equals ? _equals(prevData, nextData) : prevData == nextData);
          } catch (error, stackTrace) {
            _version++;
            return _state = _ErrorBloomState<T>(error, stackTrace);
          }
          if (isUnchanged) {
            return prev;
          }
          p.update(nextData);
          _version++;
          return prev;
        }
      } else if (source.isEmpty) {
        if (prev.isEmpty && prev.emptyReason == source.emptyReason) {
          return prev;
        }
      } else {
        if (prev is _ErrorBloomState) {
          if (prev.error == source.error && prev.stackTrace == source.stackTrace) {
            return prev;
          }
        }
      }
    }

    _version++;
    if (source is _ValidBloomState) {
      return _state = _ValidBloomState<T>(source.data);
    } else if (source.isEmpty) {
      return _state = _EmptyBloomState<T>(source.emptyReason);
    } else {
      return _state = _ErrorBloomState<T>(source.error, source.stackTrace);
    }
  }
}

// =============================================================================
// Temporal & Scheduled Control Relays (Coalesce, Debounce & Throttle)
// =============================================================================

/// Foundational base relay for temporal and scheduled gatekeeper nodes.
///
/// ### 2-Phase Gatekeeping Lifecycle & Cache Invariant
///
/// In Bloom's Lazy Push-Dirty, Pull-Evaluation DAG (LPDAG), temporal nodes act
/// as "dirty gatekeepers" across the asynchronous time domain:
///
/// 1. **Upstream Invalidation & Suppression (Ticking Window)**:
///    When upstream mutates, [_invalidate] intercepts the event. Instead of marking
///    itself dirty or propagating dirty flags downstream, it starts/resets a timer.
///    During this window, `_dirtyState` remains [_DirtyState.clean].
/// 2. **Cache Integrity (Read Committed)**:
///    If any downstream node or external caller reads `untracked(node)` (or evaluates via `BloomVia`) during
///    this window, [_PullResolver._resolve] sees `_dirtyState == _DirtyState.clean`, **completely
///    bypasses [_pull]**, and immediately returns the cached, previous [_state].
///    This guarantees that uncommitted, intermediate mutations never contaminate
///    downstream computations.
/// 3. **Timer Expiration & Gate Unlocking ([_emitTrailing])**:
///    When the timer elapses, [_emitTrailing] sets `_dirtyState = _DirtyState.dirty`
///    and enqueues this node into [_PushScope]. Only then are downstream
///    observers notified, and subsequent state reads finally invoke [_pull]
///    to fetch the fresh upstream state.
abstract base class _GatedRelayBloom<T> extends _StaticUnaryRelay<Bloom<T>>
    with _BloomStateMixin<T>, _PullResolver<T>, _PullRelay<T>, _PushOriginMixin
    implements Bloom<T> {
  _GatedRelayBloom(
    super.source, {
    required this.leading,
    required this.trailing,
  }) : assert(leading || trailing, 'At least one of leading or trailing must be true.');

  final bool leading;
  final bool trailing;

  bool _hasTrailingPending = false;

  /// Fetches and caches the fresh upstream state.
  ///
  /// **Crucial Architectural Invariant (Deferred Pull)**:
  /// This method is **NEVER** called directly during the active temporal delay window.
  /// Because [_invalidate] intentionally leaves `_dirtyState == _DirtyState.clean`,
  /// [_PullResolver._resolve] bypasses this method and serves the previous [_state]
  /// until the delay elapses and [_emitTrailing] unlocks the dirty gate.
  @override
  @pragma('vm:prefer-inline')
  _BloomState<T> _pull() {
    final next = _source._read();
    if (_source._version != _pulledVersion) {
      _version++;
    }
    return _state = next;
  }

  /// Unlocks the dirty gate upon timer/scheduler expiration, allowing [_pull]
  /// to fetch fresh upstream data and pushing dirty notifications downstream.
  @pragma('vm:prefer-inline')
  void _emitTrailing() {
    _hasTrailingPending = false;
    _dirtyState = _DirtyState.dirty;
    _PushScope.queueOrigin(this);
  }

  @mustCallSuper
  @override
  void _deactivate() {
    _hasTrailingPending = false;
    super._deactivate();
  }

  @mustCallSuper
  @override
  void _debugInvalidateSelf() {
    super._debugInvalidateSelf();
    _hasTrailingPending = false;
  }
}

/// Concrete relay node that coalesces burst dirty notifications occurring within the
/// same event loop turn into a single downstream push using [_Scheduler].
final class _CoalescedBloom<T> extends _GatedRelayBloom<T> implements _CoalescedSchedulable {
  _CoalescedBloom(
    super.source, {
    super.leading = false,
    super.trailing = true,
  });

  bool _isCoalesceScheduled = false;
  bool _isLeadingCooldown = false;

  @override
  @pragma('vm:prefer-inline')
  void _invalidate() {
    if (!_lifecycle.isActive) {
      return;
    }

    if (leading && !_isLeadingCooldown) {
      _isLeadingCooldown = true;
      if (!_isCoalesceScheduled) {
        _isCoalesceScheduled = true;
        _Scheduler.instance._scheduleCoalesced(this);
      }
      super._invalidate();
      return;
    }

    if (trailing) {
      _hasTrailingPending = true;
    }

    if (!_isCoalesceScheduled) {
      _isCoalesceScheduled = true;
      _Scheduler.instance._scheduleCoalesced(this);
    }
  }

  @override
  void _performCoalesce() {
    _isCoalesceScheduled = false;
    _isLeadingCooldown = false;
    if (!_lifecycle.isActive) return;

    if (_hasTrailingPending && trailing) {
      _emitTrailing();
    }
  }

  @mustCallSuper
  @override
  void _deactivate() {
    if (_isCoalesceScheduled) {
      _Scheduler.instance._cancelCoalesced(this);
      _isCoalesceScheduled = false;
    }
    _isLeadingCooldown = false;
    super._deactivate();
  }

  @mustCallSuper
  @override
  void _debugInvalidateSelf() {
    super._debugInvalidateSelf();
    if (_isCoalesceScheduled) {
      _Scheduler.instance._cancelCoalesced(this);
      _isCoalesceScheduled = false;
    }
    _isLeadingCooldown = false;
  }
}

/// Base relay for temporal control nodes ([_DebouncedBloom] and [_ThrottledBloom]).
///
/// ### Architectural Concept: Temporal Dirty Gatekeeper
/// In Bloom's Lazy Push-Dirty, Pull-Evaluation DAG (LPDAG), temporal nodes act
/// as "dirty gatekeepers" across the asynchronous time domain:
///
/// 1. **Upstream Invalidation & Suppression**: When the upstream [_source] mutates,
///    [_invalidate] intercepts the event. Instead of immediately propagating dirty
///    flags downstream or marking itself dirty, it schedules or resets a [Timer].
/// 2. **Temporal Isolation (Shielding Downstream)**: While the timer is ticking,
///    `_dirtyState` remains [_DirtyState.clean]. If any downstream node (or external caller)
///    reads `untracked(node)` or evaluates via [BloomVia] during this window, [_PullResolver._resolve] bypasses [_pull]
///    and immediately returns the cached, previous [_state]. This guarantees that
///    downstream computations (e.g. SWR, search API calls) are never contaminated
///    by intermediate, uncommitted mutations.
/// 3. **Timer Expiration & Propagation**: When the timer elapses, [_emitTrailing]
///    sets `_dirtyState = _DirtyState.dirty` and enqueues this node into [_PushScope].
///    Only then are downstream observers marked dirty and notified to pull the
///    fresh upstream state via [_pull].
abstract base class _TemporalRelayBloom<T> extends _GatedRelayBloom<T> {
  _TemporalRelayBloom(
    super.source,
    this.duration, {
    required super.leading,
    required super.trailing,
  });

  final Duration duration;
  Timer? _timer;

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @mustCallSuper
  @override
  void _deactivate() {
    _cancelTimer();
    super._deactivate();
  }

  @mustCallSuper
  @override
  void _debugInvalidateSelf() {
    super._debugInvalidateSelf();
    _cancelTimer();
  }
}

final class _DebouncedBloom<T> extends _TemporalRelayBloom<T> {
  _DebouncedBloom(
    super.source,
    super.duration, {
    super.leading = false,
    super.trailing = true,
  });

  bool _isLeadingCooldown = false;

  @override
  @pragma('vm:prefer-inline')
  void _invalidate() {
    if (!_lifecycle.isActive) {
      return;
    }

    if (leading && !_isLeadingCooldown) {
      _isLeadingCooldown = true;
      _cancelTimer();
      _timer = Timer(duration, _onTimerExpired);
      super._invalidate();
      return;
    }

    if (trailing) {
      _hasTrailingPending = true;
    }

    // Intentional Suppression: Do NOT call super._invalidate() or mark dirty here!
    // Keeping _dirtyState == clean ensures that any intermediate untracked(...) / _read() reads
    // return the previous committed cached state without invoking _pull().
    _cancelTimer();
    _timer = Timer(duration, _onTimerExpired);
  }

  void _onTimerExpired() {
    _timer = null;
    _isLeadingCooldown = false;
    if (!_lifecycle.isActive) return;

    if (_hasTrailingPending && trailing) {
      _emitTrailing();
    }
  }

  @mustCallSuper
  @override
  void _deactivate() {
    _isLeadingCooldown = false;
    super._deactivate();
  }

  @mustCallSuper
  @override
  void _debugInvalidateSelf() {
    _isLeadingCooldown = false;
    super._debugInvalidateSelf();
  }
}

final class _ThrottledBloom<T> extends _TemporalRelayBloom<T> {
  _ThrottledBloom(
    super.source,
    super.duration, {
    super.leading = true,
    super.trailing = true,
  });

  @override
  @pragma('vm:prefer-inline')
  void _invalidate() {
    if (!_lifecycle.isActive) {
      return;
    }

    if (_timer == null) {
      if (leading) {
        super._invalidate();
      } else if (trailing) {
        // Intentional Suppression: Keep _dirtyState == clean during throttle cooldown
        _hasTrailingPending = true;
      }
      _timer = Timer(duration, _onTimerExpired);
    } else if (trailing) {
      // Intentional Suppression: Suppress dirty while cooldown timer is ticking
      _hasTrailingPending = true;
    }
  }

  void _onTimerExpired() {
    _timer = null;
    if (!_lifecycle.isActive) return;

    if (_hasTrailingPending && trailing) {
      _emitTrailing();
      _timer = Timer(duration, _onTimerExpired);
    }
  }
}

// =============================================================================
// Internal Graceful Bloom Implementation
// =============================================================================

final class _GracefulBloom<T> extends _StaticUnaryRelay<Bloom<T>>
    with _BloomStateMixin<T>, _PullResolver<T>, _PullRelay<T>, _GracefulNodeMixin
    implements Bloom<T> {
  _GracefulBloom(
    super.source, {
    Graceful graceful = Graceful.microtask,
  }) : _graceful = graceful;

  @override
  final Graceful _graceful;

  @override
  @pragma('vm:prefer-inline')
  _BloomState<T> _pull() {
    _version++;
    return _state = _source._read();
  }
}

// =============================================================================
// Internal Retained Bloom Implementation
// =============================================================================

base class _RetainedBloom<T> extends _StaticUnaryRelay<Bloom<T>>
    with _BloomStateMixin<T>, _PullResolver<T>, _PullRelay<T>
    implements Bloom<T> {
  _RetainedBloom(super.source, [BloomCoupler<bool>? pendingCoupler]) {
    if (pendingCoupler != null) {
      pendingCoupler.couple(_PendingFacetBloom<T>(this));
    }
  }

  _BloomState<T>? _retainedState;
  bool _isPending = false;
  int _pendingVersion = 0;

  @override
  @pragma('vm:prefer-inline')
  void _invalidate() {
    super._invalidate();
  }

  @override
  @pragma('vm:prefer-inline')
  _BloomState<T> _pull() {
    final sourceState = _source._read();
    final wasPending = _isPending;

    if (sourceState is _ValidBloomState) {
      _retainedState = sourceState;
      _isPending = false;
      if (wasPending) {
        _pendingVersion++;
      }
      _version++;
      return _state = sourceState;
    } else if (sourceState.isEmpty) {
      if (_retainedState != null) {
        _isPending = true;
        if (!wasPending) {
          _pendingVersion++;
        }
        if (!identical(_state, _retainedState)) {
          _version++;
          _state = _retainedState;
        }
        return _state!;
      }
      _isPending = false;
      if (wasPending) {
        _pendingVersion++;
      }
      _version++;
      return _state = sourceState;
    } else {
      _retainedState = null;
      _isPending = false;
      if (wasPending) {
        _pendingVersion++;
      }
      _version++;
      return _state = sourceState;
    }
  }

  @mustCallSuper
  @override
  void _debugInvalidateSelf() {
    super._debugInvalidateSelf();
    _retainedState = null;
    _isPending = false;
  }
}

/// Secondary facet node representing the independent [Bloom<bool>] pending notification pipeline.
final class _PendingFacetBloom<T> extends _StaticUnaryRelay<_RetainedBloom<T>>
    with _BloomStateMixin<bool>, _PullResolver<bool>, _PullRelay<bool>
    implements Bloom<bool> {
  _PendingFacetBloom(super.source) {
    _pulledVersion = _source._pendingVersion;
  }

  @override
  @pragma('vm:prefer-inline')
  void _invalidate() {
    super._invalidate();
  }

  @override
  @pragma('vm:prefer-inline')
  bool get _isSourceDirty => _source._pendingVersion != _pulledVersion;

  @override
  @pragma('vm:prefer-inline')
  void _pullVersion() {
    _pulledVersion = _source._pendingVersion;
  }

  @override
  @pragma('vm:prefer-inline')
  _BloomState<bool> _pull() {
    _source._read();
    final current = _source._isPending;
    final s = _state;
    if (s case final _ValidBloomState<bool> vs) {
      if (vs.data == current) {
        return vs;
      }
      vs.update(current);
      _version++;
      return vs;
    }
    _version++;
    return _state = _ValidBloomState<bool>(current);
  }
}

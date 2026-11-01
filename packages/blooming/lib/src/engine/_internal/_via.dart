// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

/// Internal short-circuit sentinel thrown when [BloomVia.call] encounters
/// a non-data state (empty or error).
///
/// Implements [Error] to avoid being accidentally intercepted by standard
/// `on Exception catch` blocks in application logic.
final class _ViaShortCircuit implements Error {
  const _ViaShortCircuit(this.state);

  final _BloomState<Object?> state;

  @override
  StackTrace? get stackTrace => null;
}

/// Tracking mode for a [_BloomViaEpochMixin] evaluation epoch.
enum _ViaTrack {
  /// Synchronous evaluation finished; late or escaped `via` calls are ignored.
  closed,

  /// Active synchronous evaluation (`_beginEpoch` .. `_endEpoch`).
  sync,

  /// Active asynchronous evaluation (returned a [Future] or [Stream]).
  ///
  /// Post-`await` / post-`yield` `via` calls for the latest `_via` instance remain tracked,
  /// and the next `_beginEpoch` allocates a fresh [BloomVia] to invalidate stale turns.
  async;
}

/// Mixin that provides dynamic epoch-based explicit dependency tracking and 1-pass pruning
/// for n-ary nodes and terminals via [BloomVia].
base mixin _BloomViaEpochMixin on _NaryEdgeMixin<_Node> {
  int _epoch = 0;
  _Edge? _cursor;
  _ViaTrack _viaTrack = _ViaTrack.closed;

  /// [BloomVia] instance passed into compute and build callbacks.
  late BloomVia _via = BloomVia._(this);

  @mustCallSuper
  @override
  void _deactivate() {
    if (_viaTrack == _ViaTrack.async) {
      _via = BloomVia._(this);
      _viaTrack = _ViaTrack.closed;
    }
    super._deactivate();
  }

  /// Prepares dependency tracking for a new evaluation cycle, returning the new monotonic epoch.
  @pragma('vm:prefer-inline')
  int _beginEpoch() {
    if (_viaTrack == _ViaTrack.async) {
      _via = BloomVia._(this);
    }
    _viaTrack = _ViaTrack.sync;
    _cursor = _sourceHead;
    return ++_epoch;
  }

  /// Concludes dependency tracking for [currentEpoch].
  ///
  /// If [succeeded] is true, runs a single [_sweepObsoleteEdges] pass that detaches edges from
  /// previous branches and, when [commitVersions] is true, commits the observed versions of
  /// retained edges in the same traversal.
  ///
  /// * Terminals pass `commitVersions: true` — nothing else commits their versions.
  /// * [_PullResolver] relays pass `commitVersions: false` — [_PullResolver._resolve] commits
  ///   right after `_pull()` (including the error path, since errors are cached states).
  ///
  /// If [succeeded] is false, edges and pulled versions are left untouched so terminals stay
  /// dirty and re-evaluate on the next upstream pulse.
  @pragma('vm:prefer-inline')
  void _endEpoch(int currentEpoch, {required bool succeeded, required bool commitVersions}) {
    _cursor = null;
    if (!succeeded || _viaTrack != _ViaTrack.async) {
      _viaTrack = _ViaTrack.closed;
    }
    if (succeeded) {
      _sweepObsoleteEdges(currentEpoch, commitVersions: commitVersions);
    }
  }

  /// Transitions [_viaTrack] to [_ViaTrack.async] when the callback returns a [Future] or [Stream].
  @pragma('vm:prefer-inline')
  R _resultViaTrack<R>(R result) {
    if (result is Future || result is Stream) {
      _viaTrack = _ViaTrack.async;
    }
    return result;
  }

  /// Records [source] as an upstream dependency for the current evaluation epoch
  /// when [via] is the active tracker for this node.
  @pragma('vm:prefer-inline')
  void _trackDependency(BloomVia via, _Node source) {
    if (_viaTrack == _ViaTrack.closed || !identical(_via, via)) return;

    // 1. Fast-path: Check expected cursor position (O(1) sequential match).
    final cursor = _cursor;
    if (cursor != null && identical(cursor._source, source)) {
      cursor._seenEpoch = _epoch;
      _cursor = cursor._nextSource;
      return;
    }

    _trackDependencySlow(source, _epoch, cursor);
  }

  /// Cold-path fallback for branch changes, shifted ordering, or new dependencies.
  /// Marked never-inline to preserve inlining budget and instruction-cache locality
  /// for the hot sequential fast-path in [_trackDependency].
  @pragma('vm:never-inline')
  void _trackDependencySlow(_Node source, int currentEpoch, _Edge? cursor) {
    var edge = _findSourceEdge(source);
    if (edge != null) {
      if (edge._seenEpoch != currentEpoch) {
        // Re-align edge order to match the evaluation sequence so future evaluations
        // recover the O(1) sequential fast-path.
        if (cursor != null) {
          _moveSourceEdgeBefore(edge, cursor);
        }
        edge._seenEpoch = currentEpoch;
      }
    } else {
      // New dependency: insert before cursor (or at tail if cursor is null)
      // to preserve evaluation sequence in the edge list.
      edge = _lifecycle.isActive
          ? (cursor != null ? _addAndAttachSourceEdgeBefore(source, cursor) : _addAndAttachSourceEdge(source))
          : (cursor != null ? _addSourceEdgeBefore(source, cursor) : _addSourceEdge(source));
      edge._seenEpoch = currentEpoch;
    }
    if (_viaTrack == _ViaTrack.async) {
      source._resolve();
      edge._pulledVersion = source._version;
    }
  }

  /// 1-Pass Sweep over the source list for [currentEpoch]:
  /// * Edges not observed in [currentEpoch] are detached and unlinked.
  /// * If [commitVersions], observed edges commit the current upstream version in the same pass.
  ///
  /// Versions are committed only after the evaluator has finished, because lazy upstreams bump
  /// their version while being read.
  @pragma('vm:prefer-inline')
  void _sweepObsoleteEdges(int currentEpoch, {required bool commitVersions}) {
    final isActive = _lifecycle.isActive;
    var curr = _sourceHead;
    while (curr != null) {
      final next = curr._nextSource;
      if (curr._seenEpoch != currentEpoch) {
        if (isActive) {
          _detachAndRemoveSourceEdge(curr);
        } else {
          _removeSourceEdge(curr);
        }
      } else if (commitVersions) {
        curr._pulledVersion = curr._source._version;
      }
      curr = next;
    }
  }
}

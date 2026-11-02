// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

final _debugLabels = Expando<String>();
final _debugLocations = Expando<String>();

void _captureDebugTrace(Object target, String? label, int traceCount) {
  assert(() {
    if (label != null) _debugLabels[target] = label;
    try {
      final fullTrace = StackTrace.current.toString().split('\n');
      if (fullTrace.length > 2) {
        // skip(2) to bypass `_captureDebugTrace` AND the `debugTrace` caller.
        _debugLocations[target] = fullTrace.skip(2).take(traceCount).join('\n');
      }
    } catch (_) {}
    return true;
  }());
}

int _countTargets(_Node target) {
  var count = 0;
  for (var curr = target._targetHead; curr != null; curr = curr._nextTarget) {
    count++;
  }
  return count;
}

int _countSources(_Node target) {
  if (target case final _NaryEdgeMixin nary) {
    var count = 0;
    for (var curr = nary._sourceHead; curr != null; curr = curr._nextSource) {
      count++;
    }
    return count;
  }
  if (target case final _UnaryEdgeMixin _) {
    return 1;
  }
  return 0;
}

BloomDebugSnapshot _createDebugSnapshot(Bloom node) {
  final target = node as _Node;
  final label = _debugLabels[node];
  final count = _countTargets(target);
  final custom = <String, dynamic>{};

  if (target case final _DeltaBloom delta) {
    custom['needsSwitch'] = delta._needsSwitch;
    final source = delta._source;
    custom['activeSource'] = _debugLabels[source] ?? source.runtimeType.toString();
  } else if (target case final _ManagedBloom managed) {
    custom['hasResource'] = managed._state?.phase == BloomPhase.valid;
    if (managed._state case final state?) {
      custom['stateType'] = state.runtimeType.toString();
    }
  } else if (target case final _RetainedBloom retained) {
    custom['isPending'] = retained._isPending;
    custom['hasRetainedData'] = retained.hasData;
  }

  final state = _safeReadBloomState(node);
  if (state == null) {
    return BloomDebugSnapshot(
      node: node,
      debugLabel: label,
      nodeType: node.runtimeType,
      version: target._version,
      isActive: target.isActive,
      targetCount: count,
      customProperties: custom,
      phase: BloomPhase.empty,
      emptyReason: 'pending',
    );
  }

  return switch (state.phase) {
    BloomPhase.valid => BloomDebugSnapshot(
        node: node,
        debugLabel: label,
        nodeType: node.runtimeType,
        version: target._version,
        isActive: target.isActive,
        targetCount: count,
        customProperties: custom,
        phase: BloomPhase.valid,
        data: state.data,
      ),
    BloomPhase.empty => BloomDebugSnapshot(
        node: node,
        debugLabel: label,
        nodeType: node.runtimeType,
        version: target._version,
        isActive: target.isActive,
        targetCount: count,
        customProperties: custom,
        phase: BloomPhase.empty,
        emptyReason: state.emptyReason,
      ),
    BloomPhase.error => BloomDebugSnapshot(
        node: node,
        debugLabel: label,
        nodeType: node.runtimeType,
        version: target._version,
        isActive: target.isActive,
        targetCount: count,
        customProperties: custom,
        phase: BloomPhase.error,
        error: state.error,
      ),
  };
}

String _formatDebugSummary(_Node target) {
  final label = _debugLabels[target];
  final count = _countTargets(target);
  final header = label != null ? '${target.runtimeType}#$label' : target.runtimeType.toString();
  return '[$header] active: ${target.isActive}, targets: $count, version: ${target._version}';
}

List<BloomDebugSnapshot> _collectTerminalDebugDependencies(_Terminal terminal) {
  if (terminal case final _NaryEdgeMixin nary) {
    final list = <BloomDebugSnapshot>[];
    for (var curr = nary._sourceHead; curr != null; curr = curr._nextSource) {
      final source = curr._source;
      if (source case final Bloom bloomNode) {
        list.add(_createDebugSnapshot(bloomNode));
      }
    }
    return list;
  }
  if (terminal case final _UnaryEdgeMixin unary) {
    final source = unary._source;
    if (source case final Bloom bloomNode) {
      return [_createDebugSnapshot(bloomNode)];
    }
  }
  return const [];
}

List<Tether> _collectTerminalDebugTethers(_Terminal terminal) {
  if (terminal case final _NaryEdgeMixin nary) {
    final list = <Tether>[];
    for (var curr = nary._sourceHead; curr != null; curr = curr._nextSource) {
      final source = curr._source;
      if (source case final Tether tether) {
        list.add(tether);
      }
    }
    return list;
  }
  return const [];
}

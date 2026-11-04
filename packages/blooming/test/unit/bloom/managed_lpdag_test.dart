// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

class _TestResource {
  _TestResource(this.id, {this.label = ''});
  final int id;
  String label;
  bool isDisposed = false;

  void dispose() {
    isDisposed = true;
  }
}

class _EqualThrowingReason {
  _EqualThrowingReason(this.tag);
  final String tag;

  @override
  bool operator ==(Object other) {
    throw StateError('Custom operator == must not be called during emptyReason comparison');
  }

  @override
  int get hashCode => tag.hashCode;
}

void main() {
  group('ManagedBloom 2-Phase LPDAG Normalization & Distinct Short-Circuit', () {
    test('1. Upstream distinct short-circuit prevents resource disposal & recreation', () {
      final source = blooming<int>(10);
      // Upstream distinct derivation: stays true for even numbers
      final isEven = computed<bool>((via) => via(source.bloom) % 2 == 0).distinct();

      int createCount = 0;
      int disposeCount = 0;
      final createdResources = <_TestResource>[];

      final managedNode = managed<_TestResource>(
        create: (via) {
          createCount++;
          final res = _TestResource(via(isEven) ? 1 : 0);
          createdResources.add(res);
          return res;
        },
        dispose: (res) {
          disposeCount++;
          res.dispose();
        },
      );

      final terminal = RawBloomTerminal(managedNode, onInvalidated: () {});
      terminal.activate();

      expect(createCount, 0, reason: 'Pure lazy: resource not allocated on activate');
      expect(terminal.data.id, 1);
      expect(createCount, 1);
      expect(disposeCount, 0);
      expect(createdResources[0].isDisposed, isFalse);

      // Mutate source: 10 -> 12 (isEven remains true)
      source.data = 12;

      // Access terminal data - should short-circuit because upstream distinct is unchanged
      expect(terminal.data.id, 1);
      expect(createCount, 1, reason: 'Resource MUST NOT be recreated when upstream distinct is unchanged');
      expect(disposeCount, 0, reason: 'Existing resource MUST NOT be disposed when upstream distinct is unchanged');
      expect(createdResources[0].isDisposed, isFalse);

      // Mutate source: 12 -> 13 (isEven changes to false)
      source.data = 13;

      expect(terminal.data.id, 0);
      expect(createCount, 2, reason: 'Resource MUST be recreated when upstream distinct actually changes');
      expect(disposeCount, 1, reason: 'Old resource MUST be disposed when upstream distinct changes');
      expect(createdResources[0].isDisposed, isTrue);
      expect(createdResources[1].isDisposed, isFalse);

      terminal.deactivate();
      expect(disposeCount, 2);
      expect(createdResources[1].isDisposed, isTrue);
    });

    test('2. updateResource returning identical instance skips dispose and properly invalidates downstream', () {
      final source = blooming<int>(1);
      int updateCallCount = 0;
      int disposeCount = 0;

      final managedNode = managed<_TestResource>(
        create: (via) {
          final s = via(source.bloom);
          return _TestResource(s, label: 'initial');
        },
        update: (via, current) {
          updateCallCount++;
          final s = via(source.bloom);
          // In-place mutation returning identical instance
          current.label = 'updated_$s';
          return current;
        },
        dispose: (res) {
          disposeCount++;
          res.dispose();
        },
      );

      // Downstream computed observing managed
      int downstreamComputeCount = 0;
      final downstream = computed<String>((via) {
        downstreamComputeCount++;
        return via(managedNode).label;
      });

      final terminal = RawBloomTerminal(downstream, onInvalidated: () {});
      terminal.activate();

      expect(terminal.data, 'initial');
      expect(downstreamComputeCount, 1);
      expect(updateCallCount, 0);
      expect(disposeCount, 0);

      // Mutate source -> updateResource is called and returns identical instance
      source.data = 2;

      expect(terminal.data, 'updated_2', reason: 'Downstream MUST observe the updated resource');
      expect(downstreamComputeCount, 2, reason: 'downstreamComputeCount must advance on update');
      expect(updateCallCount, 1);
      expect(disposeCount, 0, reason: 'Identical instance must NOT be disposed during update');

      terminal.deactivate();
      expect(disposeCount, 1, reason: 'Resource disposed on terminal deactivation');
    });

    test('3. Guarded managed node honors distinct short-circuit without recreating resources', () {
      final source = blooming<int>(10);
      final flag = blooming<bool>(true);
      final isEven = computed<bool>((via) => via(source.bloom) % 2 == 0).distinct();

      int createCount = 0;
      int disposeCount = 0;

      final managedNode = managed<_TestResource>(
        guard: (via) {
          if (!via(flag.bloom)) via.exit();
        },
        create: (via) {
          createCount++;
          return _TestResource(via(isEven) ? 100 : 0);
        },
        dispose: (res) {
          disposeCount++;
          res.dispose();
        },
      );

      final terminal = RawBloomTerminal(managedNode, onInvalidated: () {});
      terminal.activate();

      expect(createCount, 0, reason: 'Pure lazy: resource not allocated on activate');
      expect(terminal.data.id, 100);
      expect(createCount, 1);
      expect(disposeCount, 0);

      // Mutate source: 10 -> 20 (isEven remains true)
      source.data = 20;

      expect(terminal.data.id, 100);
      expect(createCount, 1, reason: 'Guarded managed resource must not recreate on distinct short-circuit');
      expect(disposeCount, 0);

      // Block guard: flag -> false
      flag.data = false;
      expect(terminal.hasData, isFalse);
      expect(disposeCount, 1, reason: 'Guarded managed resource must dispose when guard blocks');

      terminal.deactivate();
    });

    test('4. Guarded managed node: emptyReason changes while remaining empty must invalidate downstream', () {
      final step = blooming<int>(1);
      final managedNode = managed<String>(
        guard: (via) {
          final s = via(step.bloom);
          if (s == 1) via.exit(emptyReason: 'Step 1 not ready');
          if (s == 2) via.exit(emptyReason: 'Step 2 not ready');
        },
        create: (via) => 'Resource',
        dispose: (_) {},
      );

      int downstreamComputeCount = 0;
      final downstream = computed<String>((via) {
        downstreamComputeCount++;
        final state = via.state(managedNode);
        if (state.isEmpty) {
          return 'Blocked: ${state.emptyReason}';
        }
        return 'Ready: ${state.data}';
      });

      final terminal = RawBloomTerminal(downstream, onInvalidated: () {});
      terminal.activate();

      expect(terminal.data, 'Blocked: Step 1 not ready');
      expect(downstreamComputeCount, 1);

      // Step changes from 1 to 2: guard is still blocked, but emptyReason changed
      step.data = 2;

      expect(terminal.data, 'Blocked: Step 2 not ready', reason: 'Downstream MUST recompute when emptyReason changes');
      expect(downstreamComputeCount, 2, reason: 'downstreamComputeCount must increment when emptyReason changes');

      terminal.deactivate();
    });

    test('5. Guarded managed node: repeated empty transitions with identical emptyReason do not increment version', () {
      final flag = blooming<bool>(false);
      final trigger = blooming<int>(1);

      final managedNode = managed<String>(
        guard: (via) {
          via(trigger.bloom); // triggers re-evaluation of guard
          if (!via(flag.bloom)) via.exit(emptyReason: 'NotAllowed');
        },
        create: (via) => 'Resource',
        dispose: (_) {},
      );

      var downstreamComputeCount = 0;
      final downstream = computed<String>((via) {
        downstreamComputeCount++;
        final state = via.state(managedNode);
        return state.isEmpty ? 'Empty: ${state.emptyReason}' : 'Data: ${state.data}';
      });

      final terminal = RawBloomTerminal(downstream, onInvalidated: () {});
      terminal.activate();

      expect(terminal.data, 'Empty: NotAllowed');
      expect(downstreamComputeCount, 1);

      // Mutate trigger: guard re-evaluates, but still exits with the identical reason 'NotAllowed'
      trigger.data = 2;
      expect(terminal.data, 'Empty: NotAllowed');
      expect(downstreamComputeCount, 1, reason: 'Downstream must NOT recompute when emptyReason is identical');

      trigger.data = 3;
      expect(terminal.data, 'Empty: NotAllowed');
      expect(downstreamComputeCount, 1);

      terminal.deactivate();
    });

    test(
        '6. Guarded managed node: transition from empty (null reason) to error via via() short-circuit bumps version and invalidates downstream',
        () {
      final upstream = blooming.late<int>();

      final managedNode = managed<String>(
        guard: (via) {
          // When upstream is late (empty with null reason), via(upstream) short-circuits with _EmptyBloomState(null).
          // When upstream is error, via(upstream) short-circuits with _ErrorBloomState.
          via(upstream.bloom);
        },
        create: (via) => 'Resource',
        dispose: (_) {},
      );

      var downstreamComputeCount = 0;
      final downstream = computed<String>((via) {
        downstreamComputeCount++;
        final state = via.state(managedNode);
        if (state.isEmpty) return 'Empty';
        if (state.hasError) return 'Error: ${state.error}';
        return 'Data: ${state.data}';
      });

      final terminal = RawBloomTerminal(downstream, onInvalidated: () {});
      terminal.activate();

      expect(terminal.data, 'Empty');
      expect(downstreamComputeCount, 1);

      // Now set upstream to error: short-circuits with _ErrorBloomState
      upstream.setError('NetworkFailed');

      expect(terminal.data, 'Error: NetworkFailed',
          reason: 'Downstream MUST recompute when transitioning from Empty to Error');
      expect(downstreamComputeCount, 2);

      terminal.deactivate();
    });

    test('7. Guarded managed node: repeated empty with null reason suppresses version increment', () {
      final trigger = blooming<int>(1);

      final managedNode = managed<String>(
        guard: (via) {
          via(trigger.bloom);
          via.exit(); // null emptyReason
        },
        create: (via) => 'Resource',
        dispose: (_) {},
      );

      var downstreamComputeCount = 0;
      final downstream = computed<String>((via) {
        downstreamComputeCount++;
        final state = via.state(managedNode);
        return state.isEmpty ? 'Empty' : 'Data: ${state.data}';
      });

      final terminal = RawBloomTerminal(downstream, onInvalidated: () {});
      terminal.activate();

      expect(terminal.data, 'Empty');
      expect(downstreamComputeCount, 1);

      // Trigger changes, guard exits with null reason again
      trigger.data = 2;
      expect(terminal.data, 'Empty');
      expect(downstreamComputeCount, 1, reason: 'Downstream must not recompute when both are null emptyReason');

      terminal.deactivate();
    });

    test('8. Guarded managed node: emptyReason comparison uses identical without invoking user operator ==', () {
      final trigger = blooming<int>(1);
      final customReason1 = _EqualThrowingReason('err');
      final customReason2 = _EqualThrowingReason('err');

      var currentReason = customReason1;

      final managedNode = managed<String>(
        guard: (via) {
          via(trigger.bloom);
          via.exit(emptyReason: currentReason);
        },
        create: (via) => 'Resource',
        dispose: (_) {},
      );

      var downstreamComputeCount = 0;
      final downstream = computed<String>((via) {
        downstreamComputeCount++;
        final state = via.state(managedNode);
        return state.isEmpty ? 'Empty: ${(state.emptyReason as _EqualThrowingReason).tag}' : 'Data: ${state.data}';
      });

      final terminal = RawBloomTerminal(downstream, onInvalidated: () {});
      terminal.activate();

      expect(terminal.data, 'Empty: err');
      expect(downstreamComputeCount, 1);

      // 1. Same identical instance: does not invoke operator ==, version not bumped
      trigger.data = 2;
      expect(terminal.data, 'Empty: err');
      expect(downstreamComputeCount, 1, reason: 'Identical reason instance must not trigger downstream recomputation');

      // 2. Different instance (even if operator == would consider them equal or throw):
      // identical is false, so version is bumped and downstream recomputes without calling operator ==
      currentReason = customReason2;
      trigger.data = 3;
      expect(terminal.data, 'Empty: err');
      expect(downstreamComputeCount, 2, reason: 'Non-identical reason must increment version');

      terminal.deactivate();
    });

    test('9. via.exit() inside managed.create suppresses version increment on repeated identical emptyReason', () {
      final trigger = blooming<int>(1);
      final allowCreate = blooming<bool>(false);

      final managedNode = managed<String>(
        create: (via) {
          via(trigger.bloom); // triggers re-execution of create
          if (!via(allowCreate.bloom)) {
            via.exit(emptyReason: 'AwaitingApproval');
          }
          return 'ApprovedResource';
        },
        dispose: (_) {},
      );

      var downstreamComputeCount = 0;
      final downstream = computed<String>((via) {
        downstreamComputeCount++;
        final state = via.state(managedNode);
        return state.isEmpty ? 'Empty: ${state.emptyReason}' : 'Data: ${state.data}';
      });

      final terminal = RawBloomTerminal(downstream, onInvalidated: () {});
      terminal.activate();

      expect(terminal.data, 'Empty: AwaitingApproval');
      expect(downstreamComputeCount, 1);

      // Trigger changes, re-executing create() which calls via.exit(emptyReason: 'AwaitingApproval')
      trigger.data = 2;
      expect(terminal.data, 'Empty: AwaitingApproval');
      expect(
        downstreamComputeCount,
        1,
        reason: 'Downstream must NOT recompute when create() exits with identical emptyReason repeatedly',
      );

      trigger.data = 3;
      expect(terminal.data, 'Empty: AwaitingApproval');
      expect(downstreamComputeCount, 1);

      terminal.deactivate();
    });

    test(
        '10. via.exit() inside managed.create increments version and invalidates downstream on Valid -> Empty transition',
        () {
      final allowCreate = blooming<bool>(true);
      int disposeCount = 0;

      final managedNode = managed<String>(
        create: (via) {
          if (!via(allowCreate.bloom)) {
            via.exit(emptyReason: 'Revoked');
          }
          return 'ValidResource';
        },
        dispose: (_) {
          disposeCount++;
        },
      );

      var downstreamComputeCount = 0;
      final downstream = computed<String>((via) {
        downstreamComputeCount++;
        final state = via.state(managedNode);
        return state.isEmpty ? 'Empty: ${state.emptyReason}' : 'Data: ${state.data}';
      });

      final terminal = RawBloomTerminal(downstream, onInvalidated: () {});
      terminal.activate();

      expect(terminal.data, 'Data: ValidResource');
      expect(downstreamComputeCount, 1);
      expect(disposeCount, 0);

      // Transition from Valid to Empty via via.exit in create
      allowCreate.data = false;
      expect(terminal.data, 'Empty: Revoked');
      expect(
        downstreamComputeCount,
        2,
        reason: 'Downstream MUST recompute when transitioning from Valid to Empty in create',
      );
      expect(disposeCount, 1, reason: 'Previous resource must be disposed upon transition to Empty');

      // Transition back from Empty to Valid in create
      allowCreate.data = true;
      expect(terminal.data, 'Data: ValidResource');
      expect(downstreamComputeCount, 3,
          reason: 'Downstream MUST recompute when transitioning back from Empty to Valid');

      terminal.deactivate();
    });
  });
}

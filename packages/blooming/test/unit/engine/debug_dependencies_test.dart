// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';

void main() {
  group('BloomDebugSnapshot & Terminal debugDependencies Tests', () {
    test('BloomController and RawBloomController attach debugLabel', () {
      final a = BloomController(10)..debugLabel = 'counterA';
      final b = RawBloomController('hello').withDebugLabel('rawB');
      final c = BloomController<double>.late()..debugLabel = 'lateC';
      final d = BloomController<String>.error('initError').withDebugLabel('errorD');

      expect(a.debugLabel, equals('counterA'));
      expect(b.debugLabel, equals('rawB'));
      expect(c.debugLabel, equals('lateC'));
      expect(d.debugLabel, equals('errorD'));
    });

    test('computed attaches debugLabel and reflects in debugDependencies', () {
      final a = BloomController(1)..debugLabel = 'sourceA';
      final b = BloomController(2)..debugLabel = 'sourceB';
      final sum = computed<int>(
        (via) => via(a.bloom) + via(b.bloom),
      )..debugLabel = 'sumComputed';

      expect(sum.debugLabel, equals('sumComputed'));
      expect(untracked(sum), equals(3));

      final terminal = RawViaTerminal<int>(
        (via) => via(sum) * 2,
        onInvalidated: () {},
      )..activate();

      expect(terminal.evaluate(), equals(6));

      final deps = terminal.debugDependencies;
      expect(deps.length, equals(1));
      expect(deps.first.debugLabel, equals('sumComputed'));
      expect(deps.first.data, equals(3));
      expect(deps.first.hasData, isTrue);
      expect(deps.first.hasError, isFalse);
      expect(deps.first.name, equals('sumComputed'));
      expect(deps.first.description, contains('3'));
      expect(deps.first.isActive, isTrue);
      expect(deps.first.targetCount, equals(1));

      terminal.deactivate();
    });

    test('RawViaTerminal dynamic branching updates debugDependencies correctly', () {
      final flag = BloomController(true)..debugLabel = 'flag';
      final optionA = BloomController('A').withDebugLabel('optionA');
      final optionB = BloomController('B').withDebugLabel('optionB');

      final terminal = RawViaTerminal<String>(
        (via) {
          if (via(flag.bloom)) {
            return via(optionA.bloom);
          } else {
            return via(optionB.bloom);
          }
        },
        onInvalidated: () {},
      )..activate();

      // Branch 1: flag is true -> depends on flag and optionA
      expect(terminal.evaluate(), equals('A'));
      var deps = terminal.debugDependencies;
      var labels = deps.map((d) => d.debugLabel).toSet();
      expect(labels, equals({'flag', 'optionA'}));

      // Branch 2: flag is false -> depends on flag and optionB (optionA is swept!)
      flag.set(false);
      expect(terminal.evaluate(), equals('B'));
      deps = terminal.debugDependencies;
      labels = deps.map((d) => d.debugLabel).toSet();
      expect(labels, equals({'flag', 'optionB'}));

      terminal.deactivate();
    });

    test('RawBloomTerminal reflects single source in debugDependencies', () {
      final count = BloomController(42)..debugLabel = 'counter';
      final terminal = RawBloomTerminal<int>(
        count.bloom,
        onInvalidated: () {},
      )..activate();

      final deps = terminal.debugDependencies;
      expect(deps.length, equals(1));
      expect(deps.first.debugLabel, equals('counter'));
      expect(deps.first.data, equals(42));
      expect(deps.first.hasData, isTrue);
      expect(deps.first.isActive, isTrue);

      terminal.deactivate();
    });

    test('BloomDebugSnapshot describes empty and error states correctly', () {
      final validNode = BloomController<double>(3.14)..debugLabel = 'validNode';
      final lateNode = BloomController<String>.late()..debugLabel = 'lateNode';
      final errorNode = BloomController<int>.error('Failed').withDebugLabel('errorNode');

      final terminal = RawViaTerminal<void>(
        (via) {
          via.state(validNode.bloom);
          via.state(lateNode.bloom);
          via.state(errorNode.bloom);
        },
        onInvalidated: () {},
      )..activate();

      terminal.evaluate();
      final deps = terminal.debugDependencies;
      final validDep = deps.firstWhere((d) => d.debugLabel == 'validNode');
      final lateDep = deps.firstWhere((d) => d.debugLabel == 'lateNode');
      final errDep = deps.firstWhere((d) => d.debugLabel == 'errorNode');

      expect(validDep.phase, equals(BloomPhase.valid));
      expect(validDep.hasData, isTrue);
      expect(validDep.data, equals(3.14));

      expect(lateDep.phase, equals(BloomPhase.empty));
      expect(lateDep.isEmpty, isTrue);
      expect(lateDep.description, contains('<empty>'));

      expect(errDep.phase, equals(BloomPhase.error));
      expect(errDep.hasError, isTrue);
      expect(errDep.error, equals('Failed'));
      expect(errDep.description, contains('Error: Failed'));

      // Verify switch (snapshot.phase) exhaustiveness and jump table behavior
      final labels = deps
          .map((d) => switch (d.phase) {
                BloomPhase.valid => 'Data: ${d.data}',
                BloomPhase.empty => 'Empty',
                BloomPhase.error => 'Error: ${d.error}',
              })
          .toList();

      expect(labels, equals(['Data: 3.14', 'Empty', 'Error: Failed']));

      terminal.deactivate();
    });

    test('terminal.debugTethers tracks tethered effects and separates from debugDependencies', () {
      final trigger = BloomController(10)..debugLabel = 'trigger';
      var effectRuns = 0;

      final effectA = Effect([trigger.bloom], () => effectRuns++).withDebugLabel('syncEffectA');
      final effectB = Effect([trigger.bloom], () => effectRuns++).withDebugLabel('syncEffectB');

      expect(effectA.debugLabel, equals('syncEffectA'));
      expect(effectA.debugDependencies.length, equals(1));
      expect(effectA.debugDependencies.first.debugLabel, equals('trigger'));

      final flag = BloomController(true);

      final terminal = RawViaTerminal<int>(
        (via) {
          final val = via(trigger.bloom);
          if (via(flag.bloom)) {
            via.tether(effectA);
          } else {
            via.tether(effectB);
          }
          return val;
        },
        onInvalidated: () {},
      )..activate();

      // Branch 1: flag is true -> tethered to effectA
      expect(terminal.evaluate(), equals(10));
      expect(terminal.debugDependencies.length, equals(2)); // trigger, flag
      expect(terminal.debugDependencies.map((d) => d.debugLabel).toSet(), equals({'trigger', null}));

      expect(terminal.debugTethers.length, equals(1));
      expect(terminal.debugTethers.first.debugLabel, equals('syncEffectA'));

      // Branch 2: flag is false -> effectA is swept, effectB is tethered
      flag.set(false);
      expect(terminal.evaluate(), equals(10));
      expect(terminal.debugTethers.length, equals(1));
      expect(terminal.debugTethers.first.debugLabel, equals('syncEffectB'));

      terminal.deactivate();
    });
  });
}

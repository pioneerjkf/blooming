// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

void main() {
  group('Bloom Observability & Debugging (Step 5)', () {
    test('1.1 debugLabel assigns label and debug.debugLabel retrieves it', () {
      final counter = blooming(0).bloom.withDebugLabel('CounterState');
      expect(counter.debug.debugLabel, 'CounterState');
      expect(counter.debugLabel, 'CounterState');
    });

    test('1.2 Fluent pipeline chaining with withDebugLabel', () {
      final base = blooming(10)..bloom.withDebugLabel('BaseNumber');
      final doubled = computed((via) => via(base.bloom) * 2).withDebugLabel('DoubledNumber');

      expect(base.bloom.debug.debugLabel, 'BaseNumber');
      expect(doubled.debug.debugLabel, 'DoubledNumber');
      expect(untracked(doubled), 20);

      base.data = 15;
      expect(untracked(doubled), 30);
    });

    test('1.3 targetCount and hasTargets reflect active terminal lifecycle', () {
      final source = blooming('Hello').bloom.withDebugLabel('Greeting');

      // Initially no targets attached
      expect(source.debug.targetCount, 0);
      expect(source.debug.hasTargets, false);

      // Connect first terminal target
      final sub1 = RawBloomTerminal(source, onInvalidated: () {});
      sub1.activate();

      expect(source.debug.targetCount, 1);
      expect(source.debug.hasTargets, true);
      expect(source.isActive, true);

      // Connect second terminal target
      final sub2 = RawBloomTerminal(source, onInvalidated: () {});
      sub2.activate();

      expect(source.debug.targetCount, 2);
      expect(source.debug.hasTargets, true);

      // Deactivate one target
      sub1.deactivate();
      expect(source.debug.targetCount, 1);
      expect(source.debug.hasTargets, true);
      expect(source.isActive, true);

      // Deactivate remaining target -> dormant
      sub2.deactivate();
      expect(source.debug.targetCount, 0);
      expect(source.debug.hasTargets, false);
      expect(source.isActive, false);
    });

    test('1.4 debug.snapshot() captures structured diagnostic snapshot', () {
      final node = blooming(42).bloom.withDebugLabel('AnswerNode');
      final BloomDebugSnapshot snapshot = node.debug.snapshot();

      expect(snapshot.name, 'AnswerNode');
      expect(snapshot.targetCount, 0);
      expect(snapshot.hasTargets, false);
      expect(snapshot.isActive, false);
      expect(snapshot.version, node.debugVersion);
      expect(snapshot.hasData, isTrue);
      expect(snapshot.data, equals(42));

      final terminal = RawBloomTerminal(node, onInvalidated: () {})..activate();
      final activeSnapshot = node.debug.snapshot();

      expect(activeSnapshot.targetCount, 1);
      expect(activeSnapshot.hasTargets, true);
      expect(activeSnapshot.isActive, true);

      terminal.deactivate();
    });

    test('1.5 switched node inspection captures activeSource and switchPending', () {
      final isDark = blooming(false)..bloom.withDebugLabel('ThemeToggle');
      final lightTheme = blooming('Light Theme')..bloom.withDebugLabel('LightThemeNode');
      final darkTheme = blooming('Dark Theme')..bloom.withDebugLabel('DarkThemeNode');

      final currentTheme = switched(
        (via) => via(isDark.bloom) ? darkTheme.bloom : lightTheme.bloom,
      ).withDebugLabel('CurrentThemeSwitch');

      final terminal = RawBloomTerminal(currentTheme, onInvalidated: () {})..activate();

      // Read data to evaluate switch
      expect(untracked(currentTheme), 'Light Theme');

      final snapshot1 = currentTheme.debug.snapshot();
      expect(snapshot1.name, 'CurrentThemeSwitch');
      expect(snapshot1.customProperties['activeSource'], 'LightThemeNode');
      expect(snapshot1.customProperties['needsSwitch'], false);

      // Toggle condition
      isDark.data = true;
      expect(untracked(currentTheme), 'Dark Theme');

      final snapshot2 = currentTheme.debug.snapshot();
      expect(snapshot2.customProperties['activeSource'], 'DarkThemeNode');

      terminal.deactivate();
    });

    test('1.6 managed node inspection tracks resource allocation status', () {
      var createCount = 0;
      var disposeCount = 0;

      final resBloom = managed<List<int>>(
        create: (_) {
          createCount++;
          return [1, 2, 3];
        },
        dispose: (list) {
          disposeCount++;
        },
      ).withDebugLabel('ManagedList');

      // Before activation: no resource allocated
      final initialSnapshot = resBloom.debug.snapshot();
      expect(initialSnapshot.customProperties['hasResource'], false);

      // Activate via terminal (pure lazy: still not allocated until read)
      final terminal = RawBloomTerminal(resBloom, onInvalidated: () {})..activate();
      expect(createCount, 0);
      expect(resBloom.debug.snapshot().customProperties['hasResource'], false);

      // Read data: now allocates
      expect(terminal.data, [1, 2, 3]);
      expect(createCount, 1);

      final activeSnapshot = resBloom.debug.snapshot();
      expect(activeSnapshot.customProperties['hasResource'], true);
      expect(activeSnapshot.isActive, true);
      expect(activeSnapshot.targetCount, 1);

      // Deactivate: resource disposed
      terminal.deactivate();
      expect(disposeCount, 1);

      final dormantSnapshot = resBloom.debug.snapshot();
      expect(dormantSnapshot.customProperties['hasResource'], false);
      expect(dormantSnapshot.isActive, false);
      expect(dormantSnapshot.targetCount, 0);
    });

    test('1.7 describe() returns clean one-line summary', () {
      final user = blooming('Alice').bloom.withDebugLabel('CurrentUser');
      final summary = user.debug.describe();

      expect(summary, contains('CurrentUser'));
      expect(summary, contains('active: false'));
      expect(summary, contains('targets: 0'));
    });

    test('1.8 RawTerminalDebugExtension works seamlessly on RawBloomTerminal, RawViaTerminal, and RawComputedTerminal',
        () {
      final source = blooming(100);

      // 1. RawBloomTerminal test
      final bloomTerminal = RawBloomTerminal<int>(source.bloom, onInvalidated: () {});
      expect(bloomTerminal.debugLabel, isNull);
      expect(bloomTerminal.debugCreationLocation, isNull);

      bloomTerminal.debugTrace('MyRawBloomTerminal');
      expect(bloomTerminal.debugLabel, 'MyRawBloomTerminal');
      expect(bloomTerminal.debugCreationLocation, isNotNull);

      // 2. RawViaTerminal test
      final viaTerminal = RawViaTerminal<int>((via) => via(source.bloom), onInvalidated: () {});
      expect(viaTerminal.debugLabel, isNull);
      expect(viaTerminal.debugCreationLocation, isNull);

      viaTerminal.debugTrace('MyRawViaTerminal');
      expect(viaTerminal.debugLabel, 'MyRawViaTerminal');
      expect(viaTerminal.debugCreationLocation, isNotNull);

      // 3. RawComputedTerminal test
      final computedTerminal = RawComputedTerminal<int>((via) => via(source.bloom) * 2, onInvalidated: () {});
      expect(computedTerminal.debugLabel, isNull);
      expect(computedTerminal.debugCreationLocation, isNull);

      computedTerminal.debugTrace('MyRawComputedTerminal');
      expect(computedTerminal.debugLabel, 'MyRawComputedTerminal');
      expect(computedTerminal.debugCreationLocation, isNotNull);
    });

    test('1.9 ComputationDebugExtension provides debugLabel and debug.snapshot()', () {
      final a = blooming(10);
      final b = blooming(20);

      final comp = _TestAddComputation(a.bloom, b.bloom).withDebugLabel('AddComp');
      expect(comp.debugLabel, 'AddComp');
      expect(comp.bloom.debugLabel, 'AddComp');

      final snapshot = comp.debug.snapshot();
      expect(snapshot.name, 'AddComp');
      expect(snapshot.isActive, isFalse);
      expect(snapshot.targetCount, 0);

      expect(comp.data, 30);
      final evaluatedSnapshot = comp.debug.snapshot();
      expect(evaluatedSnapshot.hasData, isTrue);
      expect(evaluatedSnapshot.data, 30);
    });
  });
}

final class _TestAddComputation extends Computation<int> {
  _TestAddComputation(this.a, this.b);
  final Bloom<int> a;
  final Bloom<int> b;

  @override
  int compute(BloomVia via) => via(a) + via(b);
}

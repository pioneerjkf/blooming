// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blooming_flutter/framework.dart';

void main() {
  group('Flutter DevTools Inspector & Diagnostics Properties Tests', () {
    testWidgets(
        'exposes active Bloom dependencies in DiagnosticsNode properties',
        (tester) async {
      final counter = blooming(10)..debugLabel = 'counterState';
      final title = blooming('Hello').withDebugLabel('titleState');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _InspectorProbeWidget(
            builder: (context, via) {
              return Text('${via(title.bloom)}: ${via(counter.bloom)}');
            },
          ),
        ),
      );

      final element = tester.element(find.byType(_InspectorProbeWidget));
      final diagnostics = element.toDiagnosticsNode();
      final properties = diagnostics.getProperties();

      final depProperties = properties
          .where((p) => p.name?.startsWith('bloom[') ?? false)
          .toList();
      expect(depProperties.length, equals(2));

      final titleProp = depProperties
          .firstWhere((p) => p.name?.contains('titleState') ?? false);
      expect(titleProp.value, contains('Hello'));

      final counterProp = depProperties
          .firstWhere((p) => p.name?.contains('counterState') ?? false);
      expect(counterProp.value, contains('10'));
    });

    testWidgets('real-time updates of inspector properties on Bloom mutation',
        (tester) async {
      final count = blooming(0)..debugLabel = 'liveCounter';

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _InspectorProbeWidget(
            builder: (context, via) => Text('Count: ${via(count.bloom)}'),
          ),
        ),
      );

      final element = tester.element(find.byType(_InspectorProbeWidget));
      var countProp = element
          .toDiagnosticsNode()
          .getProperties()
          .firstWhere((p) => p.name?.contains('liveCounter') ?? false);
      expect(countProp.value, contains('0 (v0)'));

      // Mutate state and pump frame
      count.set(42);
      await tester.pump();

      countProp = element
          .toDiagnosticsNode()
          .getProperties()
          .firstWhere((p) => p.name?.contains('liveCounter') ?? false);
      expect(countProp.value, contains('42 (v1)'));
    });

    testWidgets(
        'dynamic branching in build sweeps inactive dependencies in inspector properties',
        (tester) async {
      final showExtra = blooming(true)..debugLabel = 'showFlag';
      final branchA = blooming('Branch A').withDebugLabel('branchA');
      final branchB = blooming('Branch B').withDebugLabel('branchB');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _InspectorProbeWidget(
            builder: (context, via) {
              if (via(showExtra.bloom)) {
                return Text(via(branchA.bloom));
              } else {
                return Text(via(branchB.bloom));
              }
            },
          ),
        ),
      );

      final element = tester.element(find.byType(_InspectorProbeWidget));

      // Phase 1: showExtra is true -> depends on showFlag and branchA
      var depNames = element
          .toDiagnosticsNode()
          .getProperties()
          .where((p) => p.name?.startsWith('bloom[') ?? false)
          .map((p) => p.name ?? '')
          .toList();
      expect(depNames.any((n) => n.contains('showFlag')), isTrue);
      expect(depNames.any((n) => n.contains('branchA')), isTrue);
      expect(depNames.any((n) => n.contains('branchB')), isFalse);

      // Phase 2: switch to false -> branchA swept, branchB subscribed
      showExtra.set(false);
      await tester.pump();

      depNames = element
          .toDiagnosticsNode()
          .getProperties()
          .where((p) => p.name?.startsWith('bloom[') ?? false)
          .map((p) => p.name ?? '')
          .toList();
      expect(depNames.any((n) => n.contains('showFlag')), isTrue);
      expect(depNames.any((n) => n.contains('branchA')), isFalse);
      expect(depNames.any((n) => n.contains('branchB')), isTrue);
    });

    testWidgets(
        'exposes "none (no active subscriptions)" when terminal has 0 dependencies',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _InspectorProbeWidget(
            builder: (context, via) => const Text('Static'),
          ),
        ),
      );

      final element = tester.element(find.byType(_InspectorProbeWidget));
      final properties = element.toDiagnosticsNode().getProperties();
      final emptyProp =
          properties.firstWhere((p) => p.name == 'bloomDependencies');
      expect(emptyProp.value, equals('none (no active subscriptions)'));
    });

    testWidgets('exposes tethered effects in inspector properties',
        (tester) async {
      final counter = blooming(10)..debugLabel = 'counter';
      final eff =
          Effect([counter.bloom], () {}).withDebugLabel('CounterLogger');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _InspectorProbeWidget(
            builder: (context, via) {
              via.tether(eff);
              return Text('Count: ${via(counter.bloom)}');
            },
          ),
        ),
      );

      final element = tester.element(find.byType(_InspectorProbeWidget));
      final properties = element.toDiagnosticsNode().getProperties();

      final tetherProp = properties.firstWhere((p) => p.name == 'tether[0]');
      expect(tetherProp.value, contains('CounterLogger'));

      final depProp =
          properties.firstWhere((p) => p.name?.contains('counter') ?? false);
      expect(depProp.value, contains('10'));
    });
  });
}

base class _InspectorProbeWidget extends BloomWidget {
  const _InspectorProbeWidget({required this.builder});
  final Widget Function(BuildContext context, BloomVia via) builder;

  @override
  Widget build(BuildContext context, BloomVia via) => builder(context, via);
}

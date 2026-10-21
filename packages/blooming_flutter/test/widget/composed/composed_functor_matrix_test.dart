// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blooming_flutter/framework.dart';

void main() {
  group('Canonical Build Functor Hierarchy & Child Caching Tests', () {
    testWidgets('1. Canonical Single-Bloom Functor Pathways render and react',
        (tester) async {
      final ctrl = BloomController<int>(10);

      // 1. Direct call
      final w1 = ctrl.bloom.build((context, d) => Text('W1: $d'));

      // 2. Child
      final w2 = ctrl.bloom.build.child(
        (context, d, child) => Column(children: [Text('W2: $d'), child]),
        child: const Text('Child2'),
      );

      // 3. Children
      final w3 = ctrl.bloom.build.children(
        (context, d, children) =>
            Column(children: [Text('W3: $d'), ...children]),
        children: const [Text('Child3A'), Text('Child3B')],
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [w1, w2, w3],
          ),
        ),
      );

      expect(find.text('W1: 10'), findsOneWidget);
      expect(find.text('W2: 10'), findsOneWidget);
      expect(find.text('W3: 10'), findsOneWidget);

      expect(find.text('Child2'), findsOneWidget);
      expect(find.text('Child3A'), findsOneWidget);
      expect(find.text('Child3B'), findsOneWidget);

      // Mutate controller
      ctrl.set(99);
      await tester.pump();

      expect(find.text('W1: 99'), findsOneWidget);
      expect(find.text('W2: 99'), findsOneWidget);
      expect(find.text('W3: 99'), findsOneWidget);
    });

    testWidgets(
        '2. Multi-Bloom composed inline (2..5 elements) builds correctly',
        (tester) async {
      final c1 = BloomController<int>(1);
      final c2 = BloomController<int>(2);
      final c3 = BloomController<int>(3);
      final c4 = BloomController<int>(4);
      final c5 = BloomController<int>(5);

      final w2 = composed(
          (context, via) => Text('T2: ${via(c1.bloom) + via(c2.bloom)}'));
      final w3 = composed((context, via) =>
          Text('T3: ${via(c1.bloom) + via(c2.bloom) + via(c3.bloom)}'));
      final w4 = composed((context, via) => Text(
          'T4: ${via(c1.bloom) + via(c2.bloom) + via(c3.bloom) + via(c4.bloom)}'));
      final w5 = composed((context, via) => Text(
          'T5: ${via(c1.bloom) + via(c2.bloom) + via(c3.bloom) + via(c4.bloom) + via(c5.bloom)}'));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(children: [w2, w3, w4, w5]),
        ),
      );

      expect(find.text('T2: 3'), findsOneWidget);
      expect(find.text('T3: 6'), findsOneWidget);
      expect(find.text('T4: 10'), findsOneWidget);
      expect(find.text('T5: 15'), findsOneWidget);

      c1.set(10);
      await tester.pump();

      expect(find.text('T2: 12'), findsOneWidget);
      expect(find.text('T3: 15'), findsOneWidget);
      expect(find.text('T4: 19'), findsOneWidget);
      expect(find.text('T5: 24'), findsOneWidget);
    });

    testWidgets(
        '3. Cached child preserves widget instance identity across parent rebuilds',
        (tester) async {
      final countCtrl = BloomController<int>(0);
      int childBuildCount = 0;

      final staticChild = Builder(
        builder: (context) {
          childBuildCount++;
          return const Text('StaticChildContent');
        },
      );

      int parentBuildCount = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: countCtrl.bloom.build.child(
            (context, data, child) {
              parentBuildCount++;
              return Column(
                children: [
                  Text('Count: $data'),
                  child,
                ],
              );
            },
            child: staticChild,
          ),
        ),
      );

      expect(parentBuildCount, 1);
      expect(childBuildCount, 1);
      expect(find.text('Count: 0'), findsOneWidget);
      expect(find.text('StaticChildContent'), findsOneWidget);

      // Mutate parent count
      countCtrl.set(1);
      await tester.pump();

      expect(parentBuildCount, 2);
      // Static child should NOT rebuild because its element was preserved
      expect(childBuildCount, 1);
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets(
        '4. composed.drive renders and ticks with BloomVia and BuildContext',
        (tester) async {
      int tickCount = 0;
      final w1 = composed.drive<int>(
        (elapsed) => elapsed == Duration.zero ? 0 : ++tickCount,
        (context, via, val) => Text('Drive: $val'),
      );

      final w2 = composed.drive<int>(
        (elapsed) => elapsed == Duration.zero ? 0 : tickCount * 2,
        (context, via, val) => Text('DriveContext: $val'),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(children: [w1, w2]),
        ),
      );

      expect(find.text('Drive: 0'), findsOneWidget);
      expect(find.text('DriveContext: 0'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Drive: 1'), findsOneWidget);
      expect(find.text('DriveContext: 2'), findsOneWidget);
    });

    testWidgets(
        '5. composed.animate entrypoint variations (call, child, children)',
        (tester) async {
      final ctrl = DurableAnimationController(
        policy: DurabilityPolicy.catchUp,
        duration: const Duration(milliseconds: 300),
      );
      ctrl.value = 0.5;

      final w1 = composed.animate(
        ctrl,
        (context, via, c) => Text('AnimCall: ${(c.value * 100).toInt()}'),
      );
      final w2 = composed.animate.child(
        ctrl,
        (context, via, c, child) => Column(
          children: [
            Text('AnimChild: ${(c.value * 100).toInt()}'),
            child,
          ],
        ),
        child: const Text('ChildW'),
      );
      final w3 = composed.animate.children(
        ctrl,
        (context, via, c, children) => Column(
          children: [
            Text('AnimChildren: ${(c.value * 100).toInt()}'),
            ...children,
          ],
        ),
        children: const [Text('ChildrenW')],
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(children: [w1, w2, w3]),
        ),
      );

      expect(find.text('AnimCall: 50'), findsOneWidget);
      expect(find.text('AnimChild: 50'), findsOneWidget);
      expect(find.text('AnimChildren: 50'), findsOneWidget);

      expect(find.text('ChildW'), findsOneWidget);
      expect(find.text('ChildrenW'), findsOneWidget);

      ctrl.hibernate();
    });

    testWidgets(
        '6. composed.drive reparenting with GlobalKey triggers activate() and update()',
        (tester) async {
      final key1 = GlobalKey();
      final key2 = GlobalKey();
      final switchContainer = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<bool>(
            valueListenable: switchContainer,
            builder: (context, switched, _) {
              final driveWidget = composed.drive<int>(
                (elapsed) => 1,
                (context, via, val) => Text('DriveKey: $val'),
                key: key1,
              );
              final driveContextWidget = composed.drive<int>(
                (elapsed) => 2,
                (context, via, val) => Text('DriveContextKey: $val'),
                key: key2,
              );

              return switched
                  ? Row(children: [driveWidget, driveContextWidget])
                  : Column(children: [driveWidget, driveContextWidget]);
            },
          ),
        ),
      );

      expect(find.textContaining('DriveKey:'), findsOneWidget);
      expect(find.textContaining('DriveContextKey:'), findsOneWidget);

      // Trigger reparenting: switches from Column to Row
      switchContainer.value = true;
      await tester.pump();

      expect(find.textContaining('DriveKey:'), findsOneWidget);
      expect(find.textContaining('DriveContextKey:'), findsOneWidget);
    });

    testWidgets(
        '6. debugFillProperties covers dependencies and tethers (with and without label)',
        (tester) async {
      // 1. Empty dependencies
      final emptyWidget =
          composed((context, via) => const Text('Empty Composed'));
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: emptyWidget,
        ),
      );
      final emptyElement = tester.element(find.byWidget(emptyWidget));
      expect(
        emptyElement.toDiagnosticsNode().toStringDeep(),
        contains('none (no active subscriptions)'),
      );

      // 2. Dependencies and tethers
      final ctrl = BloomController<int>(42);
      final eff1 = Effect([ctrl.bloom], () {}).withDebugLabel('LabeledEffect');
      final eff2 = Effect([ctrl.bloom], () {}); // debugLabel is null

      final widget = composed((context, via) {
        via(ctrl.bloom);
        via.tether(eff1);
        via.tether(eff2);
        return const Text('Composed With Tethers');
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: widget,
        ),
      );

      final element = tester.element(find.byWidget(widget));
      final diagnostics = element.toDiagnosticsNode().toStringDeep();

      expect(diagnostics, contains('bloom[0]'));
      expect(diagnostics, contains('LabeledEffect'));
      expect(diagnostics, contains('tether[1]'));
    });
  });
}

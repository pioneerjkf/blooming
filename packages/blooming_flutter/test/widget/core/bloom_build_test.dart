// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blooming_flutter/framework.dart';

void main() {
  group(
      'BloomFlutterExtension (bloom.build) and _InlineSingleBloomWidget Tests',
      () {
    testWidgets(
        'renders initial data correctly via bloom.build((context, data) => ...)',
        (tester) async {
      final controller = BloomController<int>(10);
      final targetBloom = controller.bloom;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: targetBloom.build((context, count) {
            expect(context, isNotNull);
            return Text('Count: $count');
          }),
        ),
      );

      expect(find.text('Count: 10'), findsOneWidget);
    });

    testWidgets('rebuilds reactively when controller value changes',
        (tester) async {
      final controller = BloomController<String>('Hello');
      final targetBloom = controller.bloom;
      var buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: targetBloom.build((context, message) {
            buildCount++;
            return Text('Message: $message');
          }),
        ),
      );

      expect(find.text('Message: Hello'), findsOneWidget);
      expect(buildCount, 1);

      // Update state
      controller.set('World');
      await tester.pump();

      expect(find.text('Message: World'), findsOneWidget);
      expect(buildCount, 2);
    });

    testWidgets('does not rebuild when value is distinct (same value)',
        (tester) async {
      final controller = BloomController<int>(42, distinct: true);
      final targetBloom = controller.bloom;
      var buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: targetBloom.build((context, value) {
            buildCount++;
            return Text('Value: $value');
          }),
        ),
      );

      expect(buildCount, 1);

      // Setting same value with distinct: true
      controller.set(42);
      await tester.pump();

      expect(buildCount, 1);
    });

    testWidgets('handles nullable Bloom<T?> values gracefully', (tester) async {
      final controller = BloomController<String?>('Initial');
      final targetBloom = controller.bloom;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: targetBloom.build((context, val) {
            return Text(val ?? 'No Data');
          }),
        ),
      );

      expect(find.text('Initial'), findsOneWidget);

      controller.set(null);
      await tester.pump();
      expect(find.text('No Data'), findsOneWidget);

      controller.set('Recovered');
      await tester.pump();
      expect(find.text('Recovered'), findsOneWidget);
    });

    testWidgets(
        'updates correctly when widget configuration changes (same or new node)',
        (tester) async {
      final controller1 = BloomController<int>(1);
      final controller2 = BloomController<int>(2);

      Widget createHost(Bloom<int> node) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: node.build(
            key: const ValueKey('bloom_widget'),
            (context, val) => Text('Val: $val'),
          ),
        );
      }

      // Initial pump with controller1
      await tester.pumpWidget(createHost(controller1.bloom));
      expect(find.text('Val: 1'), findsOneWidget);

      // Pump update with controller2
      await tester.pumpWidget(createHost(controller2.bloom));
      expect(find.text('Val: 2'), findsOneWidget);

      // Mutate controller2
      controller2.set(200);
      await tester.pump();
      expect(find.text('Val: 200'), findsOneWidget);

      // Controller1 should no longer drive the widget
      controller1.set(100);
      await tester.pump();
      expect(find.text('Val: 200'), findsOneWidget);
    });

    testWidgets('cleans up and deactivates RawBloomTerminal upon unmounting',
        (tester) async {
      final controller = BloomController<int>(100);
      final targetBloom = controller.bloom;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: targetBloom.build((context, val) => Text('Active: $val')),
        ),
      );

      expect(find.text('Active: 100'), findsOneWidget);

      // Unmount by replacing with empty Container
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      expect(find.text('Active: 100'), findsNothing);

      // Setting value after unmount must not throw or cause dirty leaks
      expect(() => controller.set(200), returnsNormally);
      await tester.pump();
    });

    testWidgets(
        'always provides local BuildContext allowing local InheritedWidget lookup',
        (tester) async {
      final controller = BloomController<String>('Alpha');
      final targetBloom = controller.bloom;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: targetBloom.build((context, data) {
            return Text('ContextData: $data (${context.runtimeType})');
          }),
        ),
      );

      expect(find.textContaining('ContextData: Alpha'), findsOneWidget);

      controller.set('Beta');
      await tester.pump();
      expect(find.textContaining('ContextData: Beta'), findsOneWidget);
    });

    testWidgets(
        'targetBloom.build.child passes context, data, and cached child',
        (tester) async {
      final controller = BloomController<int>(10);
      final targetBloom = controller.bloom;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: targetBloom.build.child(
            (context, count, child) =>
                Row(children: [Text('Count: $count'), child]),
            child: const Text('StaticChild'),
          ),
        ),
      );

      expect(find.text('Count: 10'), findsOneWidget);
      expect(find.text('StaticChild'), findsOneWidget);

      controller.set(20);
      await tester.pump();
      expect(find.text('Count: 20'), findsOneWidget);
      expect(find.text('StaticChild'), findsOneWidget);
    });

    testWidgets(
        'targetBloom.build.children passes context, data, and cached children list',
        (tester) async {
      final controller = BloomController<String>('Title');
      final targetBloom = controller.bloom;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: targetBloom.build.children(
            (context, title, children) =>
                Column(children: [Text('Title: $title'), ...children]),
            children: const [Text('Item1'), Text('Item2')],
          ),
        ),
      );

      expect(find.text('Title: Title'), findsOneWidget);
      expect(find.text('Item1'), findsOneWidget);
      expect(find.text('Item2'), findsOneWidget);

      controller.set('UpdatedTitle');
      await tester.pump();
      expect(find.text('Title: UpdatedTitle'), findsOneWidget);
      expect(find.text('Item1'), findsOneWidget);
    });
  });
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blooming_flutter/framework.dart';

void main() {
  group('Top-Level Composed Functor Tests', () {
    testWidgets(
        '1. composed((context, via) => ...) dynamically tracks multiple Blooms',
        (WidgetTester tester) async {
      final userCtrl = BloomController<String>('Alice');
      final scoreCtrl = BloomController<int>(100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: composed((context, via) {
              final user = via(userCtrl.bloom);
              final score = via(scoreCtrl.bloom);
              return Text('$user: $score pts');
            }),
          ),
        ),
      );

      expect(find.text('Alice: 100 pts'), findsOneWidget);

      // Mutate user
      userCtrl.data = 'Bob';
      await tester.pump();
      expect(find.text('Bob: 100 pts'), findsOneWidget);

      // Mutate score
      scoreCtrl.data = 250;
      await tester.pump();
      expect(find.text('Bob: 250 pts'), findsOneWidget);
    });

    testWidgets('2. composed((context, via) => ...) accesses Theme and Bloom',
        (WidgetTester tester) async {
      final themeNameCtrl = BloomController<String>('Dark');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: Colors.purple),
          home: Scaffold(
            body: composed((context, via) {
              final name = via(themeNameCtrl.bloom);
              final primaryColor = Theme.of(context).primaryColor;
              return Container(
                color: primaryColor,
                child: Text('Theme: $name'),
              );
            }),
          ),
        ),
      );

      expect(find.text('Theme: Dark'), findsOneWidget);

      themeNameCtrl.data = 'Light';
      await tester.pump();
      expect(find.text('Theme: Light'), findsOneWidget);
    });

    testWidgets('3. composed.child isolates static child from rebuilds',
        (WidgetTester tester) async {
      final colorCtrl = BloomController<bool>(false);
      int childBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: composed.child(
              (context, via, child) {
                final isRed = via(colorCtrl.bloom);
                return Container(
                  color: isRed ? Colors.red : Colors.blue,
                  child: child,
                );
              },
              child: Builder(
                builder: (context) {
                  childBuildCount++;
                  return const Text('Static Heavy Child');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Static Heavy Child'), findsOneWidget);
      expect(childBuildCount, equals(1));

      // Mutate bloom
      colorCtrl.data = true;
      await tester.pump();

      // Static child must stay at 1 build
      expect(childBuildCount, equals(1));

      colorCtrl.data = false;
      await tester.pump();

      expect(childBuildCount, equals(1));
    });

    testWidgets('4. composed.children(...) caches static widget list',
        (WidgetTester tester) async {
      final titleCtrl = BloomController<String>('Menu');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: composed.children(
              (context, via, children) {
                final title = via(titleCtrl.bloom);
                return Column(
                  children: [
                    Text('Title: $title'),
                    ...children,
                  ],
                );
              },
              children: const [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Title: Menu'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);

      titleCtrl.data = 'Nav';
      await tester.pump();

      expect(find.text('Title: Nav'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets(
        '5. Nested composed calls allow independent micro-rebuilds without shadowing issues',
        (WidgetTester tester) async {
      final outerCtrl = BloomController<String>('Outer');
      final innerCtrl = BloomController<int>(1);

      int outerBuildCount = 0;
      int innerBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: composed((context, via) {
              outerBuildCount++;
              final outerVal = via(outerCtrl.bloom);
              return Column(
                children: [
                  Text('Outer: $outerVal'),
                  // Nested composed call!
                  composed((context, innerVia) {
                    innerBuildCount++;
                    final innerVal = innerVia(innerCtrl.bloom);
                    return Text('Inner: $innerVal');
                  }),
                ],
              );
            }),
          ),
        ),
      );

      expect(find.text('Outer: Outer'), findsOneWidget);
      expect(find.text('Inner: 1'), findsOneWidget);
      expect(outerBuildCount, equals(1));
      expect(innerBuildCount, equals(1));

      // Mutate ONLY inner bloom: outer must NOT rebuild!
      innerCtrl.data = 2;
      await tester.pump();

      expect(find.text('Inner: 2'), findsOneWidget);
      expect(outerBuildCount, equals(1)); // Isolated!
      expect(innerBuildCount, equals(2));

      // Mutate outer bloom: outer rebuilds
      outerCtrl.data = 'OuterUpdated';
      await tester.pump();

      expect(find.text('Outer: OuterUpdated'), findsOneWidget);
      expect(outerBuildCount, equals(2));
    });

    testWidgets(
        '6. Composed entrypoints (call, child, children) render correctly',
        (WidgetTester tester) async {
      final textBloom = BloomController<String>('Alpha');

      final a1 =
          composed((context, via) => Text('A1: ${via(textBloom.bloom)}'));
      final a2 = composed.child(
        (context, via, child) =>
            Column(children: [Text('A2: ${via(textBloom.bloom)}'), child]),
        child: const Text('ChildA2'),
      );
      final a3 = composed.children(
        (context, via, children) => Column(
            children: [Text('A3: ${via(textBloom.bloom)}'), ...children]),
        children: const [Text('ChildA3')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [a1, a2, a3],
            ),
          ),
        ),
      );

      expect(find.text('A1: Alpha'), findsOneWidget);
      expect(find.text('A2: Alpha'), findsOneWidget);
      expect(find.text('ChildA2'), findsOneWidget);
      expect(find.text('A3: Alpha'), findsOneWidget);
      expect(find.text('ChildA3'), findsOneWidget);
    });

    testWidgets(
        '7. composed.child and composed.children work seamlessly with context',
        (WidgetTester tester) async {
      final valBloom = BloomController<String>('Gamma');

      final b1 = composed.child(
        (context, via, child) => Row(children: [
          Text(
              'B1: ${Theme.of(context).brightness == Brightness.light} ${via(valBloom.bloom)}'),
          child
        ]),
        child: const Text('ChildB1'),
      );

      final b2 = composed.children(
        (context, via, children) => Column(children: [
          Text(
              'B2: ${Theme.of(context).brightness == Brightness.light} ${via(valBloom.bloom)}'),
          ...children
        ]),
        children: const [Text('ChildB2')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [b1, b2],
            ),
          ),
        ),
      );

      expect(find.text('B1: true Gamma'), findsOneWidget);
      expect(find.text('ChildB1'), findsOneWidget);
      expect(find.text('B2: true Gamma'), findsOneWidget);
      expect(find.text('ChildB2'), findsOneWidget);
    });

    testWidgets(
        '8. 1st-Depth composed.drive Functors Suite (direct frame ticker)',
        (WidgetTester tester) async {
      int driveBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: composed.drive<int>(
              (elapsed) => elapsed.inMilliseconds,
              (context, via, ms) {
                driveBuildCount++;
                return Text('DriveMS: $ms');
              },
            ),
          ),
        ),
      );

      expect(find.text('DriveMS: 0'), findsOneWidget);
      expect(driveBuildCount, equals(1));

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('DriveMS: 100'), findsOneWidget);
      expect(driveBuildCount, equals(2));
    });

    testWidgets(
        '9. 1st-Depth composed.animate Functors Suite (direct animation controller + Bloom)',
        (WidgetTester tester) async {
      final controller = DurableAnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final labelBloom = BloomController<String>('Score');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: composed.animate(
              controller,
              (context, via, ctrl) => Text(
                  '${via(labelBloom.bloom)}: ${(ctrl.value * 100).toInt()}'),
            ),
          ),
        ),
      );

      expect(find.text('Score: 0'), findsOneWidget);

      // Start animation
      controller.forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Score: 50'), findsOneWidget);

      // Mutate external Bloom - should reactively update with current animation value
      labelBloom.data = 'Points';
      await tester.pump();
      expect(find.text('Points: 50'), findsOneWidget);

      controller.hibernate();
    });

    testWidgets('10. composed.animate.child isolates static child',
        (WidgetTester tester) async {
      int childBuildCount = 0;
      final controller = DurableAnimationController(
        duration: const Duration(milliseconds: 200),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: composed.animate.child(
              controller,
              (context, via, ctrl, child) => Column(
                children: [
                  Text('Progress: ${(ctrl.value * 100).toInt()}'),
                  child,
                ],
              ),
              child: Builder(
                builder: (context) {
                  childBuildCount++;
                  return const Text('MemoizedChild');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Progress: 0'), findsOneWidget);
      expect(find.text('MemoizedChild'), findsOneWidget);
      expect(childBuildCount, equals(1));

      // Advance animation
      controller.forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Progress: 50'), findsOneWidget);
      // Memoized child must NOT rebuild
      expect(childBuildCount, equals(1));

      controller.hibernate();
    });
  });
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blooming_flutter/testing.dart';

void main() {
  group('composed.drive Functor Widget Tests', () {
    testWidgets(
        '1. composed.drive() evaluates onTick and continuously updates inline widget on frame ticks',
        (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed.drive<int>(
            (elapsed) => elapsed.inMilliseconds,
            (context, via, ms) {
              buildCount++;
              return Text('Elapsed: $ms ms');
            },
          ),
        ),
      );

      expect(find.text('Elapsed: 0 ms'), findsOneWidget);
      expect(buildCount, equals(1));

      // Advance time by 50ms
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Elapsed: 50 ms'), findsOneWidget);
      expect(buildCount, equals(2));

      // Advance time by another 100ms
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Elapsed: 150 ms'), findsOneWidget);
      expect(buildCount, equals(3));
    });

    testWidgets('2. composed.drive() accesses BuildContext', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed.drive<int>(
            (elapsed) => elapsed.inMilliseconds,
            (context, via, ms) =>
                Text('ContextDir: ${Directionality.of(context).name} $ms'),
          ),
        ),
      );

      expect(find.text('ContextDir: ltr 0'), findsOneWidget);
    });

    testWidgets(
        '3. composed.drive.child() isolates heavy static child during 120fps ticks',
        (tester) async {
      int childBuildCount = 0;
      int vsyncBuildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed.drive.child<int>(
            (elapsed) => elapsed.inMilliseconds,
            (context, via, ms, child) {
              vsyncBuildCount++;
              return Row(
                children: [
                  Text('Tick: $ms'),
                  child,
                ],
              );
            },
            child: Builder(
              builder: (context) {
                childBuildCount++;
                return const Text('HeavyChild');
              },
            ),
          ),
        ),
      );

      expect(find.text('Tick: 0'), findsOneWidget);
      expect(find.text('HeavyChild'), findsOneWidget);
      expect(vsyncBuildCount, equals(1));
      expect(childBuildCount, equals(1));

      // Advance multiple frames
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Tick: 100'), findsOneWidget);
      expect(vsyncBuildCount, equals(3));
      // HeavyChild MUST NOT rebuild on ticker ticks
      expect(childBuildCount, equals(1));
    });

    testWidgets('4. composed.drive with hoisted children and context work',
        (tester) async {
      const child1 = Text('Child1');
      const child2 = Text('Child2');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              composed.drive<int>(
                (elapsed) => elapsed.inMilliseconds,
                (context, via, ms) => Row(children: [
                  child1,
                  Text('Val1: $ms ${Directionality.of(context).name}'),
                ]),
              ),
              composed.drive<int>(
                (elapsed) => elapsed.inMilliseconds,
                (context, via, ms) => Row(children: [
                  Text('Val2: ${Directionality.of(context).name} $ms'),
                  child2,
                ]),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Child1'), findsOneWidget);
      expect(find.text('Val1: 0 ltr'), findsOneWidget);
      expect(find.text('Child2'), findsOneWidget);
      expect(find.text('Val2: ltr 0'), findsOneWidget);
    });

    testWidgets(
        '5. composed.drive.children provides context, tick value, and children',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed.drive.children<int>(
            (elapsed) => elapsed.inMilliseconds,
            (context, via, ms, children) => Column(children: [
              Text('A: $ms ${Directionality.of(context).name}'),
              ...children,
            ]),
            children: const [Text('Item 1'), Text('Item 2')],
          ),
        ),
      );

      expect(find.text('A: 0 ltr'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets(
        '6. composed.drive continuously fires on frame ticks regardless of value equality',
        (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed.drive<int>(
            // Always returns constant 42
            (elapsed) => 42,
            (context, via, val) {
              buildCount++;
              return Text('Val: $val');
            },
          ),
        ),
      );

      expect(find.text('Val: 42'), findsOneWidget);
      expect(buildCount, equals(1));

      // Advance by 30ms -> continuous frame ticker rebuilds even though value is unchanged
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('Val: 42'), findsOneWidget);
      expect(buildCount, equals(2));

      // Advance by another 30ms -> rebuilds again
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('Val: 42'), findsOneWidget);
      expect(buildCount, equals(3));
    });

    testWidgets(
        '7. composed.drive.child continuously fires on frame ticks regardless of value equality',
        (tester) async {
      int buildCount = 0;
      int childBuildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed.drive.child<int>(
            // Constant value
            (elapsed) => 100,
            (context, via, val, child) {
              buildCount++;
              return Column(
                children: [
                  Text('Val: $val'),
                  child,
                ],
              );
            },
            child: Builder(
              builder: (context) {
                childBuildCount++;
                return const Text('StaticChild');
              },
            ),
          ),
        ),
      );

      expect(find.text('Val: 100'), findsOneWidget);
      expect(find.text('StaticChild'), findsOneWidget);
      expect(buildCount, equals(1));
      expect(childBuildCount, equals(1));

      // Advance by 30ms -> continuous frame ticker rebuilds even though value is unchanged
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('Val: 100'), findsOneWidget);
      expect(buildCount, equals(2));
      expect(childBuildCount, equals(1)); // Child remains cached

      // Advance by another 30ms -> rebuilds again
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('Val: 100'), findsOneWidget);
      expect(buildCount, equals(3));
      expect(childBuildCount, equals(1));
    });

    testWidgets(
        '8. composed.drive cancels internal ticker upon unmount preventing leaks',
        (tester) async {
      final showBloom = BloomController<bool>(true);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed(
            (context, via) => via(showBloom.bloom)
                ? composed.drive<int>(
                    (elapsed) => elapsed.inMilliseconds,
                    (context, via, ms) => Text('Ticking: $ms'),
                  )
                : const Text('Dead'),
          ),
        ),
      );

      expect(find.text('Ticking: 0'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Ticking: 50'), findsOneWidget);

      // Unmount the driven widget
      showBloom.data = false;
      await tester.pump();

      expect(find.text('Dead'), findsOneWidget);

      // Advance frames - must not crash or invoke onTick
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Dead'), findsOneWidget);
    });

    testWidgets(
        '9. Multiple composed.drive widgets run independently without interference',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              composed.drive<int>(
                (elapsed) => elapsed.inMilliseconds * 2, // 2x speed
                (context, via, ms) => Text('DriveA: $ms'),
              ),
              composed.drive<int>(
                (elapsed) => elapsed.inMilliseconds * 10, // 10x speed
                (context, via, ms) => Text('DriveB: $ms'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('DriveA: 0'), findsOneWidget);
      expect(find.text('DriveB: 0'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('DriveA: 100'), findsOneWidget);
      expect(find.text('DriveB: 500'), findsOneWidget);
    });
  });

  group('composed.drive Reactive Tracking Tests', () {
    testWidgets(
        '10. composed.drive automatically tracks external Bloom mutations via RawViaTerminal',
        (tester) async {
      final prefixBloom = BloomController<String>('Speed:');
      int buildCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed.drive<int>(
            (elapsed) => elapsed.inMilliseconds,
            (context, via, ms) {
              buildCount++;
              final prefix = via(prefixBloom.bloom);
              return Text('$prefix $ms');
            },
          ),
        ),
      );

      expect(find.text('Speed: 0'), findsOneWidget);
      expect(buildCount, equals(1));

      // Advance time
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Speed: 50'), findsOneWidget);
      expect(buildCount, equals(2));

      // Mutate external Bloom without tick advancement!
      prefixBloom.data = 'Velocity:';
      await tester.pump(); // No frame duration advance

      // Must have rebuilt reactively!
      expect(find.text('Velocity: 50'), findsOneWidget);
      expect(buildCount, equals(3));
    });

    testWidgets(
        '11. composed.drive tracks external Blooms with hoisted widgets',
        (tester) async {
      final tagBloom = BloomController<String>('Tag');
      const staticChild = Text('ChildStatic');
      const staticChildren = [Text('Item 1')];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              composed.drive<int>(
                (elapsed) => elapsed.inMilliseconds,
                (context, via, ms) => Text(
                    'CtxWatch: ${Directionality.of(context).name} ${via(tagBloom.bloom)} $ms'),
              ),
              composed.drive<int>(
                (elapsed) => elapsed.inMilliseconds,
                (context, via, ms) => Row(children: [
                  Text('WatchChild: ${via(tagBloom.bloom)} $ms'),
                  staticChild,
                ]),
              ),
              composed.drive<int>(
                (elapsed) => elapsed.inMilliseconds,
                (context, via, ms) => Column(children: [
                  Text('WatchChildren: ${via(tagBloom.bloom)} $ms'),
                  ...staticChildren,
                ]),
              ),
            ],
          ),
        ),
      );

      expect(find.text('CtxWatch: ltr Tag 0'), findsOneWidget);
      expect(find.text('WatchChild: Tag 0'), findsOneWidget);
      expect(find.text('ChildStatic'), findsOneWidget);
      expect(find.text('WatchChildren: Tag 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);

      tagBloom.data = 'Updated';
      await tester.pump();

      expect(find.text('CtxWatch: ltr Updated 0'), findsOneWidget);
      expect(find.text('WatchChild: Updated 0'), findsOneWidget);
      expect(find.text('WatchChildren: Updated 0'), findsOneWidget);
    });
  });

  group('composed.animate Functor Widget Tests', () {
    testWidgets(
        '12. composed.animate drives DurableAnimationController with automatic resync',
        (tester) async {
      final controller = DurableAnimationController(
        duration: const Duration(milliseconds: 300),
      )..forward();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed.animate(
            controller,
            (context, via, ctrl) =>
                Text('Progress: ${(ctrl.value * 100).toInt()}%'),
          ),
        ),
      );

      expect(find.text('Progress: 0%'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Progress: 50%'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Progress: 100%'), findsOneWidget);

      controller.hibernate();
    });

    testWidgets(
        '13. composed.animate in composed tracks external Bloom alongside controller',
        (tester) async {
      final modeBloom = BloomController<String>('Linear');
      final controller = DurableAnimationController(
        duration: const Duration(milliseconds: 200),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed(
            (context, via) {
              final mode = via(modeBloom.bloom);
              return composed.animate(
                controller,
                (context, via, ctrl) {
                  return Text('$mode: ${(ctrl.value * 100).toInt()}%');
                },
              );
            },
          ),
        ),
      );

      expect(find.text('Linear: 0%'), findsOneWidget);

      controller.forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Linear: 50%'), findsOneWidget);

      modeBloom.data = 'EaseInOut';
      await tester.pump();
      expect(find.text('EaseInOut: 50%'), findsOneWidget);

      controller.hibernate();
    });

    testWidgets(
        '14. composed.animate with context and hoisted children work as expected',
        (tester) async {
      final controller = DurableAnimationController(
        duration: const Duration(milliseconds: 100),
      );
      const resStaticChild = Text('ResStaticChild');
      const resStaticChildCtx = Text('ResStaticChildCtx');
      const resStaticCtxChild = Text('ResStaticCtxChild');
      const resItem1 = [Text('ResItem 1')];
      const resItem2 = [Text('ResItem 2')];
      const resItem3 = [Text('ResItem 3')];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              composed.animate(
                controller,
                (context, via, ctrl) =>
                    Text('ResCtx: ${Directionality.of(context).name}'),
              ),
              composed.animate(
                controller,
                (context, via, ctrl) => Row(children: [
                  Text('ResChild: ${ctrl.value}'),
                  resStaticChild
                ]),
              ),
              composed.animate(
                controller,
                (context, via, ctrl) => Row(children: [
                  Text(
                      'ResChildCtx: ${Directionality.of(context).name} ${ctrl.value}'),
                  resStaticChildCtx,
                ]),
              ),
              composed.animate(
                controller,
                (context, via, ctrl) => Row(children: [
                  Text(
                      'ResCtxChild: ${Directionality.of(context).name} ${ctrl.value}'),
                  resStaticCtxChild,
                ]),
              ),
              composed.animate(
                controller,
                (context, via, ctrl) => Column(children: [
                  Text('ResChildren: ${ctrl.value}'),
                  ...resItem1,
                ]),
              ),
              composed.animate(
                controller,
                (context, via, ctrl) => Row(children: [
                  Text(
                      'ResChildrenCtx: ${Directionality.of(context).name} ${ctrl.value}'),
                  ...resItem2,
                ]),
              ),
              composed.animate(
                controller,
                (context, via, ctrl) => Row(children: [
                  Text(
                      'ResCtxChildren: ${Directionality.of(context).name} ${ctrl.value}'),
                  ...resItem3,
                ]),
              ),
            ],
          ),
        ),
      );

      expect(find.text('ResCtx: ltr'), findsOneWidget);
      expect(find.text('ResChild: 0.0'), findsOneWidget);
      expect(find.text('ResStaticChild'), findsOneWidget);
      expect(find.text('ResChildCtx: ltr 0.0'), findsOneWidget);
      expect(find.text('ResStaticChildCtx'), findsOneWidget);
      expect(find.text('ResCtxChild: ltr 0.0'), findsOneWidget);
      expect(find.text('ResStaticCtxChild'), findsOneWidget);
      expect(find.text('ResChildren: 0.0'), findsOneWidget);
      expect(find.text('ResItem 1'), findsOneWidget);
      expect(find.text('ResChildrenCtx: ltr 0.0'), findsOneWidget);
      expect(find.text('ResItem 2'), findsOneWidget);
      expect(find.text('ResCtxChildren: ltr 0.0'), findsOneWidget);
      expect(find.text('ResItem 3'), findsOneWidget);

      controller.hibernate();
    });

    testWidgets(
        '15. composed.animate enters dormancy on unmount and wakes on remount',
        (tester) async {
      final showBloom = BloomController<bool>(true);
      final controller = DurableAnimationController(
        duration: const Duration(milliseconds: 300),
      )..forward();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed(
            (context, via) => via(showBloom.bloom)
                ? composed.animate(
                    controller,
                    (context, via, ctrl) =>
                        Text('Value: ${(ctrl.value * 100).toInt()}%'),
                  )
                : const Text('Hidden'),
          ),
        ),
      );

      expect(controller.isActive, isTrue);
      expect(find.text('Value: 0%'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Value: 50%'), findsOneWidget);

      // Unmount the wake widget
      showBloom.data = false;
      await tester.pumpAndSettle();

      expect(controller.isDormant, isTrue);
      expect(find.text('Hidden'), findsOneWidget);

      // Remount the wake widget
      showBloom.data = true;
      await tester.pumpAndSettle();

      expect(controller.isActive, isTrue);

      controller.hibernate();
    });

    testWidgets(
        '16. composed.animate inside composed renders and tracks dormancy properly',
        (tester) async {
      final showBloom = BloomController<bool>(true);
      final titleBloom = BloomController<String>('TitleA');
      final controller = DurableAnimationController(
        duration: const Duration(milliseconds: 200),
      )..forward();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed(
            (context, via) {
              final show = via(showBloom.bloom);
              final title = via(titleBloom.bloom);
              return show
                  ? composed.animate(
                      controller,
                      (context, via, ctrl) =>
                          Text('$title: ${(ctrl.value * 100).toInt()}%'),
                    )
                  : const Text('Off');
            },
          ),
        ),
      );

      expect(controller.isActive, isTrue);
      expect(find.text('TitleA: 0%'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('TitleA: 50%'), findsOneWidget);

      titleBloom.data = 'TitleB';
      await tester.pump();
      expect(find.text('TitleB: 50%'), findsOneWidget);

      // Unmount
      showBloom.data = false;
      await tester.pumpAndSettle();
      expect(controller.isDormant, isTrue);

      controller.hibernate();
    });
  });

  group('composed.animate Unified Tests', () {
    testWidgets(
        '17. composed.animate automatically updates on frame ticks without AnimatedBuilder',
        (tester) async {
      final controller = DurableAnimationController(
        duration: const Duration(milliseconds: 300),
      )..forward();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed.animate(
            controller,
            (context, via, ctrl) =>
                Text('Progress: ${(ctrl.value * 100).toInt()}%'),
          ),
        ),
      );

      // Frame 0ms (0%)
      expect(find.text('Progress: 0%'), findsOneWidget);

      // Frame 150ms (50%)
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Progress: 50%'), findsOneWidget);

      // Frame 300ms (100%)
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Progress: 100%'), findsOneWidget);

      controller.hibernate();
    });

    testWidgets(
        '18. composed.animate.child isolates heavy static child during 60/120fps ticks',
        (tester) async {
      int staticChildBuildCount = 0;
      int dynamicBuilderCount = 0;
      final controller = DurableAnimationController(
        duration: const Duration(milliseconds: 200),
      )..forward();

      final staticChild = Builder(
        builder: (context) {
          staticChildBuildCount++;
          return const Text('Static Heavy Graphic');
        },
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed.animate.child(
            controller,
            (context, via, ctrl, child) {
              dynamicBuilderCount++;
              return Column(
                children: [
                  child,
                  Text('Progress: ${(ctrl.value * 100).toInt()}%'),
                ],
              );
            },
            child: staticChild,
          ),
        ),
      );

      expect(staticChildBuildCount, equals(1));
      expect(dynamicBuilderCount, equals(1));
      expect(find.text('Static Heavy Graphic'), findsOneWidget);
      expect(find.text('Progress: 0%'), findsOneWidget);

      // Advance frames
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Progress: 50%'), findsOneWidget);
      expect(staticChildBuildCount, equals(1),
          reason: 'Static child must not rebuild on ticks');
      expect(dynamicBuilderCount, greaterThan(1));

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Progress: 100%'), findsOneWidget);
      expect(staticChildBuildCount, equals(1));

      controller.hibernate();
    });

    testWidgets(
        '19. composed.animate tracks both frame ticks and external Bloom mutations',
        (tester) async {
      final labelBloom = BloomController<String>('Alpha');
      final controller = DurableAnimationController(
        duration: const Duration(milliseconds: 200),
      )..forward();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed.animate(
            controller,
            (context, via, ctrl) => Text(
                '${via(labelBloom.bloom)}: ${(ctrl.value * 100).toInt()}%'),
          ),
        ),
      );

      expect(find.text('Alpha: 0%'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Alpha: 50%'), findsOneWidget);

      labelBloom.data = 'Beta';
      await tester.pump();
      expect(find.text('Beta: 50%'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Beta: 100%'), findsOneWidget);

      controller.hibernate();
    });

    testWidgets('20. composed.animate.child provides context, ctrl, and child',
        (tester) async {
      final controller = DurableAnimationController(
        duration: const Duration(milliseconds: 200),
      )..forward();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed.animate.child(
            controller,
            (context, via, ctrl, child) => Column(
              children: [
                child,
                Text('Val: ${(ctrl.value * 100).toInt()}'),
              ],
            ),
            child: const Text('Cached Header'),
          ),
        ),
      );

      expect(find.text('Cached Header'), findsOneWidget);
      expect(find.text('Val: 0'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Val: 50'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Val: 100'), findsOneWidget);

      controller.hibernate();
    });

    testWidgets(
        '21. composed.animate unmount/remount dormant and lifecycle safety',
        (tester) async {
      final showBloom = BloomController<bool>(true);
      final controller = DurableAnimationController(
        duration: const Duration(milliseconds: 300),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed(
            (context, via) => via(showBloom.bloom)
                ? composed.animate(
                    controller,
                    (context, via, ctrl) =>
                        Text('Coord: ${ctrl.value.toStringAsFixed(1)}'),
                  )
                : const Text('Dormant'),
          ),
        ),
      );

      expect(controller.isActive, isTrue);
      expect(find.text('Coord: 0.0'), findsOneWidget);

      // Start animation to 0.5 (half duration = 150ms)
      controller.forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Coord: 0.5'), findsOneWidget);

      // Unmount mid-flight -> deactivates and detaches listener
      showBloom.data = false;
      await tester.pump();
      await tester.pump();

      expect(controller.isDormant, isTrue);
      expect(find.text('Dormant'), findsOneWidget);
      expect(controller.value, equals(0.5)); // Frozen freezes

      // Remount -> reactivates and reattaches listener
      showBloom.data = true;
      await tester.pump();
      await tester.pump();

      expect(controller.isActive, isTrue);
      expect(find.text('Coord: 0.5'), findsOneWidget);

      controller.hibernate();
    });
  });
}

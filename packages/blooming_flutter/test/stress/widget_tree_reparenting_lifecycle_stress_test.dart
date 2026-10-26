// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blooming_flutter/framework.dart';

base class ReparentableCounterWidget extends BloomWidget {
  const ReparentableCounterWidget({super.key, required this.counterBloom});

  final Bloom<int> counterBloom;

  @override
  Widget build(BuildContext context, BloomVia via) {
    return Text('Count: ${via(counterBloom)}');
  }
}

base class ScopedThemeConsumerWidget extends BloomWidget {
  const ScopedThemeConsumerWidget({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context, BloomVia via) {
    final theme = context.bloomOf<String>();
    return Text('$label: ${via(theme)}');
  }
}

base class OptionalThemeConsumerWidget extends BloomWidget {
  const OptionalThemeConsumerWidget({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final optionalTheme = context.maybeBloomOf<String>();
    return Text('Theme: ${via(optionalTheme) ?? "none"}');
  }
}

void main() {
  group('Widget Tree Reparenting, Scoping & Lifecycle Stress Tests', () {
    testWidgets(
        '1.1 GlobalKey reparenting preserves reactive bindings across subtrees',
        (tester) async {
      final counter = blooming<int>(10);
      final widgetKey = GlobalKey();
      final swapNotifier = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<bool>(
            valueListenable: swapNotifier,
            builder: (context, swap, _) {
              final targetWidget = ReparentableCounterWidget(
                key: widgetKey,
                counterBloom: counter.bloom,
              );
              return Row(
                children: [
                  Container(
                      child: swap ? const SizedBox.shrink() : targetWidget),
                  Container(
                      child: swap ? targetWidget : const SizedBox.shrink()),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Count: 10'), findsOneWidget);

      // Mutate counter in Slot 1
      counter.set(20);
      await tester.pump();
      expect(find.text('Count: 20'), findsOneWidget);

      // Reparent to Slot 2 via GlobalKey
      swapNotifier.value = true;
      await tester.pump();

      expect(find.text('Count: 20'), findsOneWidget);

      // Mutate counter in Slot 2
      counter.set(30);
      await tester.pump();
      expect(find.text('Count: 30'), findsOneWidget);
    });

    testWidgets(
        '1.2 Nested BloomProvider scoping and independent branch overriding',
        (tester) async {
      final rootThemeController = blooming<String>('RootTheme');
      final nestedThemeController = blooming<String>('NestedTheme');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomProvider<String>(
            bloom: rootThemeController.bloom,
            child: Column(
              children: [
                ScopedThemeConsumerWidget(label: 'Sibling'),
                BloomProvider<String>(
                  bloom: nestedThemeController.bloom,
                  child: ScopedThemeConsumerWidget(label: 'Nested'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Sibling: RootTheme'), findsOneWidget);
      expect(find.text('Nested: NestedTheme'), findsOneWidget);

      // Mutate root theme -> updates Sibling only
      rootThemeController.set('RootThemeV2');
      await tester.pump();

      expect(find.text('Sibling: RootThemeV2'), findsOneWidget);
      expect(find.text('Nested: NestedTheme'), findsOneWidget);

      // Mutate nested theme -> updates Nested only
      nestedThemeController.set('NestedThemeV2');
      await tester.pump();

      expect(find.text('Sibling: RootThemeV2'), findsOneWidget);
      expect(find.text('Nested: NestedThemeV2'), findsOneWidget);
    });

    testWidgets(
        '1.3 Dynamically wrapping and unwrapping optional BloomProvider ancestor',
        (tester) async {
      final hasAncestorNotifier = ValueNotifier<bool>(false);
      final themeController = blooming<String>('DynamicTheme');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<bool>(
            valueListenable: hasAncestorNotifier,
            builder: (context, hasAncestor, _) {
              final child = OptionalThemeConsumerWidget();
              if (hasAncestor) {
                return BloomProvider<String>(
                  bloom: themeController.bloom,
                  child: child,
                );
              }
              return child;
            },
          ),
        ),
      );

      expect(find.text('Theme: none'), findsOneWidget);

      // Inject ancestor
      hasAncestorNotifier.value = true;
      await tester.pump();
      expect(find.text('Theme: DynamicTheme'), findsOneWidget);

      // Mutate theme
      themeController.set('SuperTheme');
      await tester.pump();
      expect(find.text('Theme: SuperTheme'), findsOneWidget);

      // Remove ancestor
      hasAncestorNotifier.value = false;
      await tester.pump();
      expect(find.text('Theme: none'), findsOneWidget);
    });

    testWidgets(
        '1.4 Rapid 20-cycle mount/unmount flapping does not leak listeners or hang',
        (tester) async {
      final showNotifier = ValueNotifier<bool>(true);
      final counter = blooming<int>(0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<bool>(
            valueListenable: showNotifier,
            builder: (context, show, _) {
              return show
                  ? ReparentableCounterWidget(counterBloom: counter.bloom)
                  : const SizedBox.shrink();
            },
          ),
        ),
      );

      for (int i = 0; i < 20; i++) {
        showNotifier.value = !showNotifier.value;
        counter.set(i);
        await tester.pump();
      }

      showNotifier.value = true;
      counter.set(999);
      await tester.pump();
      expect(find.text('Count: 999'), findsOneWidget);
    });
  });
}

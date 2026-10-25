// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blooming_flutter/framework.dart';

// Test BloomWidget implementations
base class CounterBloomWidget extends BloomWidget {
  const CounterBloomWidget({
    super.key,
    required this.counterBloom,
    this.prefix = 'Count',
  });

  final Bloom<int> counterBloom;
  final String prefix;

  @override
  Widget build(BuildContext context, BloomVia via) {
    return Text('$prefix: ${via(counterBloom)}');
  }
}

base class ContextAwareBloomWidget extends BloomWidget {
  const ContextAwareBloomWidget({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final themeState = context.bloomOf<String>();
    return Text('Theme: ${via(themeState)}');
  }
}

base class OptionalContextBloomWidget extends BloomWidget {
  const OptionalContextBloomWidget({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final optionalTheme = context.maybeBloomOf<String>();
    return Text('Theme: ${via(optionalTheme) ?? "default"}');
  }
}

base class ViaOfBloomWidget extends BloomWidget {
  const ViaOfBloomWidget({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final theme = via.of<String>(context);
    return Text('Theme: $theme');
  }
}

base class ViaMaybeOfBloomWidget extends BloomWidget {
  const ViaMaybeOfBloomWidget({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final optionalTheme = via.maybeOf<String>(context);
    return Text('Theme: ${optionalTheme ?? "default"}');
  }
}

abstract class _TestBaseClass {
  String get val;
}

class _TestChildClass implements _TestBaseClass {
  _TestChildClass(this.val);
  @override
  final String val;
}

void main() {
  group('BloomWidget & BloomElement Tests', () {
    testWidgets('renders initial data and updates on Bloom state mutation',
        (tester) async {
      final controller = BloomController<int>(0);
      final targetBloom = controller.bloom;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CounterBloomWidget(counterBloom: targetBloom),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      controller.set(1);
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      controller.set(42);
      await tester.pump();
      expect(find.text('Count: 42'), findsOneWidget);
    });

    testWidgets(
        'rebuilds with force: true when parent passes new widget configuration',
        (tester) async {
      final controller1 = BloomController<int>(10);
      final controller2 = BloomController<int>(20);

      Widget createHost({
        required Bloom<int> targetBloom,
        required String prefix,
      }) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: CounterBloomWidget(
            key: const ValueKey('counter_bloom'),
            counterBloom: targetBloom,
            prefix: prefix,
          ),
        );
      }

      await tester.pumpWidget(
          createHost(targetBloom: controller1.bloom, prefix: 'Initial'));
      expect(find.text('Initial: 10'), findsOneWidget);

      // Update widget with new prefix and new controller
      await tester.pumpWidget(
          createHost(targetBloom: controller2.bloom, prefix: 'Updated'));
      expect(find.text('Updated: 20'), findsOneWidget);

      controller2.set(99);
      await tester.pump();
      expect(find.text('Updated: 99'), findsOneWidget);
    });

    testWidgets(
        'upstream distinct short-circuits build evaluation when state value is unchanged',
        (tester) async {
      final source = BloomController<int>(0, distinct: false);
      final isEven = computed((via) => via(source.bloom) % 2 == 0).distinct();

      int buildCount = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: composed((context, via) {
            buildCount++;
            return Text('Even: ${via(isEven)}');
          }),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('Even: true'), findsOneWidget);

      // Mutate source: 0 -> 2 (both even).
      source.data = 2;
      await tester.pump();

      // buildCount MUST remain 1 because isEven evaluated to identical state (distinct)!
      expect(buildCount, 1);
      expect(find.text('Even: true'), findsOneWidget);

      // Mutate source: 2 -> 3 (even -> odd).
      source.data = 3;
      await tester.pump();

      // buildCount increments because isEven mutated to false!
      expect(buildCount, 2);
      expect(find.text('Even: false'), findsOneWidget);
    });

    testWidgets('cleans up RawViaTerminal on unmount', (tester) async {
      final controller = BloomController<int>(5);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CounterBloomWidget(counterBloom: controller.bloom),
        ),
      );

      expect(find.text('Count: 5'), findsOneWidget);

      // Unmount
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.shrink(),
        ),
      );

      expect(find.text('Count: 5'), findsNothing);

      // Mutation after unmount should not throw or cause errors
      expect(() => controller.set(10), returnsNormally);
      await tester.pump();
    });

    testWidgets('supports const BloomWidget instantiation', (tester) async {
      final theme = BloomController<String>('Dark');

      // Const instantiation verification:
      const staticWidget = ContextAwareBloomWidget();
      expect(staticWidget, isNotNull);

      await tester.pumpWidget(
        theme.bloom.provide(
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: ContextAwareBloomWidget(),
          ),
        ),
      );

      expect(find.text('Theme: Dark'), findsOneWidget);
    });
  });

  group('BloomProvider & BloomBuildContextExtension Tests', () {
    testWidgets('bloomOf<T>() reactively subscribes to BloomProvider<T>',
        (tester) async {
      final themeController = BloomController<String>('Dark');

      await tester.pumpWidget(
        themeController.bloom.provide(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ContextAwareBloomWidget(),
          ),
        ),
      );

      expect(find.text('Theme: Dark'), findsOneWidget);

      themeController.set('Light');
      await tester.pump();
      expect(find.text('Theme: Light'), findsOneWidget);
    });

    testWidgets('maybeBloomOf<T>() handles absent BloomProvider<T> gracefully',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: OptionalContextBloomWidget(),
        ),
      );

      expect(find.text('Theme: default'), findsOneWidget);
    });

    testWidgets('maybeBloomOf<T>() subscribes when BloomProvider<T> is present',
        (tester) async {
      final themeController = BloomController<String>('Custom');

      await tester.pumpWidget(
        themeController.bloom.provide(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: OptionalContextBloomWidget(),
          ),
        ),
      );

      expect(find.text('Theme: Custom'), findsOneWidget);

      themeController.set('Custom2');
      await tester.pump();
      expect(find.text('Theme: Custom2'), findsOneWidget);
    });

    testWidgets('via.of<T>(context) reactively subscribes to BloomProvider<T>',
        (tester) async {
      final themeController = BloomController<String>('Dark');

      await tester.pumpWidget(
        themeController.bloom.provide(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: const ViaOfBloomWidget(),
          ),
        ),
      );

      expect(find.text('Theme: Dark'), findsOneWidget);

      themeController.set('Light');
      await tester.pump();
      expect(find.text('Theme: Light'), findsOneWidget);
    });

    testWidgets(
        'via.maybeOf<T>(context) handles absent BloomProvider<T> gracefully',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: const ViaMaybeOfBloomWidget(),
        ),
      );

      expect(find.text('Theme: default'), findsOneWidget);
    });

    testWidgets(
        'via.maybeOf<T>(context) subscribes when BloomProvider<T> is present',
        (tester) async {
      final themeController = BloomController<String>('Custom');

      await tester.pumpWidget(
        themeController.bloom.provide(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: const ViaMaybeOfBloomWidget(),
          ),
        ),
      );

      expect(find.text('Theme: Custom'), findsOneWidget);

      themeController.set('Custom2');
      await tester.pump();
      expect(find.text('Theme: Custom2'), findsOneWidget);
    });

    testWidgets(
        'BloomProvider updateShouldNotify returns false for identical bloom reference',
        (tester) async {
      final controller = BloomController<int>(0);

      final widget1 = BloomProvider<int>(
        bloom: controller.bloom,
        child: const SizedBox.shrink(),
      );

      final widget2 = BloomProvider<int>(
        bloom: controller.bloom,
        child: const SizedBox.shrink(),
      );

      expect(widget1.updateShouldNotify(widget2), isFalse);

      final otherController = BloomController<int>(0);
      final widget3 = BloomProvider<int>(
        bloom: otherController.bloom,
        child: const SizedBox.shrink(),
      );

      expect(widget1.updateShouldNotify(widget3), isTrue);
    });

    testWidgets(
        'bloomOf<T>() throws FlutterError when BloomProvider<T> is absent',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              return Text('${context.bloomOf<int>()}');
            },
          ),
        ),
      );

      final dynamic exception = tester.takeException();
      expect(exception, isA<FlutterError>());
      expect(
        exception.toString(),
        contains('No ancestor BloomProvider<int> found'),
      );
    });

    testWidgets(
        'maybeBloomOf<T>() returns canonical Bloom.constantNull singleton when absent',
        (tester) async {
      late Bloom<int?> extracted1;
      late Bloom<String?> extracted2;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              extracted1 = context.maybeBloomOf<int>();
              extracted2 = context.maybeBloomOf<String>();
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(identical(extracted1, Bloom.constantNull), isTrue);
      expect(identical(extracted2, Bloom.constantNull), isTrue);
      expect(identical(extracted1, extracted2), isTrue);
    });

    testWidgets(
        'bloomOf<T>() requires exact type match and fails on supertype unless explicitly provided',
        (tester) async {
      final childBloom =
          BloomController<_TestChildClass>(_TestChildClass('exact_payload'))
              .bloom;

      // 1. Provided as BloomProvider<_TestChildClass>
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomProvider<_TestChildClass>(
            bloom: childBloom,
            child: Builder(
              builder: (context) {
                // Exact type succeeds
                expect(
                  untracked(context.bloomOf<_TestChildClass>()).val,
                  equals('exact_payload'),
                );
                // Supertype lookup fails with FlutterError
                expect(
                  () => context.bloomOf<_TestBaseClass>(),
                  throwsA(isA<FlutterError>()),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      // 2. Explicitly provided as BloomProvider<_TestBaseClass>
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BloomProvider<_TestBaseClass>(
            bloom: childBloom,
            child: Builder(
              builder: (context) {
                // Supertype lookup succeeds now that it is explicitly provisioned
                expect(
                  untracked(context.bloomOf<_TestBaseClass>()).val,
                  equals('exact_payload'),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets(
        'bloom.provide and controller.provide wrap child in BloomProvider<T>',
        (tester) async {
      final controller = BloomController<String>('controller_data');
      final directBloom = Bloom.constant('bloom_data');

      // Test controller.provide
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: controller.provide(
            child: Builder(
              builder: (context) {
                expect(
                  untracked(context.bloomOf<String>()),
                  equals('controller_data'),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      // Test bloom.provide
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: directBloom.provide(
            child: Builder(
              builder: (context) {
                expect(
                  untracked(context.bloomOf<String>()),
                  equals('bloom_data'),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });
  });

  group('Animation & Vsync Lifecycle Tests', () {
    testWidgets('provides vsync and drives animation via Bloom.managed',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AnimatedBoxWidget(),
        ),
      );

      expect(find.text('Progress: 0%'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Progress: 50%'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Progress: 100%'), findsOneWidget);
    });

    testWidgets('cleanly disposes tickers when unmounted', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AnimatedBoxWidget(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Progress: 50%'), findsOneWidget);

      // Unmount the widget by replacing it with an empty container
      await tester.pumpWidget(const SizedBox.shrink());
      expect(find.byType(AnimatedBoxWidget), findsNothing);
    });

    testWidgets('mutes ticker when TickerMode is disabled', (tester) async {
      Widget createHost(bool enabled, Widget child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: TickerMode(
            enabled: enabled,
            child: child,
          ),
        );
      }

      final animatedBox = AnimatedBoxWidget();

      await tester.pumpWidget(createHost(true, animatedBox));
      expect(find.text('Progress: 0%'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Progress: 50%'), findsOneWidget);

      // Disable TickerMode with same widget instance
      await tester.pumpWidget(createHost(false, animatedBox));

      // Advancing time should not advance animation while muted
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Progress: 50%'), findsOneWidget);

      // Re-enable TickerMode
      await tester.pumpWidget(createHost(true, animatedBox));

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Progress: 100%'), findsOneWidget);
    });

    testWidgets(
        'Uncaught error inside terminal invalidation is reported to FlutterError',
        (tester) async {
      final ctrl = BloomController<int>(1);
      FlutterErrorDetails? reportedDetails;
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        reportedDetails = details;
      };

      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ctrl.bloom.build((_, data) => Text('Count: $data')),
          ),
        );

        expect(find.text('Count: 1'), findsOneWidget);

        // Find the reactive element
        final reactiveElement = tester.allElements.firstWhere(
          (e) =>
              e.runtimeType.toString().contains('Bloom') ||
              e.runtimeType.toString().contains('Bloom'),
        );

        final dynamic dynamicElement = reactiveElement;
        dynamicElement.handleTerminalUncaughtError(
          Exception('Terminal unhandled failure'),
          StackTrace.current,
        );

        expect(reportedDetails, isNotNull);
        expect(reportedDetails!.library, 'blooming_flutter');
        expect(reportedDetails!.exception.toString(),
            contains('Terminal unhandled failure'));
      } finally {
        FlutterError.onError = prevOnError;
      }
    });

    testWidgets(
        'BloomVsyncWidget provides active vsync and tracks Bloom dependencies',
        (tester) async {
      final counter = BloomController<int>(0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CounterVsyncBloomWidget(counterBloom: counter.bloom),
        ),
      );

      expect(find.text('Count: 0, Vsync: true'), findsOneWidget);

      counter.set(1);
      await tester.pump();
      expect(find.text('Count: 1, Vsync: true'), findsOneWidget);
    });

    testWidgets(
        'BloomWidget couples external controller via controller.animate and disposes cleanly on unmount',
        (tester) async {
      final ctrl = DurableAnimationController(
        duration: const Duration(milliseconds: 300),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AnimatedVsyncBloomWidget(controller: ctrl),
        ),
      );

      expect(find.text('Value: 0.0'), findsOneWidget);

      ctrl.value = 0.5;
      await tester.pump();
      expect(find.text('Value: 0.5'), findsOneWidget);

      // Unmount safely
      await tester.pumpWidget(const SizedBox.shrink());
      expect(find.byType(AnimatedVsyncBloomWidget), findsNothing);
    });

    testWidgets(
        'BloomAnimatedWidget rebuilds on controller tick and tracks Bloom dependencies',
        (tester) async {
      final ctrl = DurableAnimationController(
        duration: const Duration(milliseconds: 300),
      );
      final counter = BloomController<int>(0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TestBloomAnimatedWidget(
            controller: ctrl,
            counterBloom: counter.bloom,
          ),
        ),
      );

      expect(find.text('Value: 0.0, Count: 0'), findsOneWidget);

      ctrl.value = 0.7;
      await tester.pump();
      expect(find.text('Value: 0.7, Count: 0'), findsOneWidget);

      counter.set(99);
      await tester.pump();
      expect(find.text('Value: 0.7, Count: 99'), findsOneWidget);

      // Unmount safely
      await tester.pumpWidget(const SizedBox.shrink());
      expect(find.byType(TestBloomAnimatedWidget), findsNothing);
    });
  });
}

base class TestBloomAnimatedWidget extends BloomAnimatedWidget {
  const TestBloomAnimatedWidget({
    super.key,
    required super.controller,
    required this.counterBloom,
  });

  final Bloom<int> counterBloom;

  @override
  Widget build(
    BuildContext context,
    BloomVia via,
    ScopedAnimationController controller,
  ) {
    final count = via(counterBloom);
    return Text('Value: ${controller.value.toStringAsFixed(1)}, Count: $count');
  }
}

base class CounterVsyncBloomWidget extends BloomVsyncWidget {
  const CounterVsyncBloomWidget({
    super.key,
    required this.counterBloom,
  });

  final Bloom<int> counterBloom;

  @override
  Widget build(
    BuildContext context,
    BloomVia via,
    TickerProvider vsync,
  ) {
    final count = via(counterBloom);
    return Text(
        'Count: $count, Vsync: ${(vsync as dynamic) is TickerProvider}');
  }
}

base class AnimatedVsyncBloomWidget extends BloomWidget {
  const AnimatedVsyncBloomWidget({
    super.key,
    required this.controller,
  });

  final DurableAnimationController controller;

  @override
  Widget build(
    BuildContext context,
    BloomVia via,
  ) {
    return composed.animate(
      controller,
      (context, via, ctrl) => Text('Value: ${ctrl.value.toStringAsFixed(1)}'),
    );
  }
}

class AnimatedBoxWidget extends StatefulWidget {
  const AnimatedBoxWidget({super.key});

  @override
  State<AnimatedBoxWidget> createState() => _AnimatedBoxWidgetState();
}

class _AnimatedBoxWidgetState extends State<AnimatedBoxWidget>
    with SingleTickerProviderStateMixin {
  late final Bloom<AnimationController> animation = Bloom.managed(
    create: (via) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward(),
    dispose: (c) => c.dispose(),
  );

  @override
  Widget build(BuildContext context) {
    return composed((context, via) {
      final animCtrl = via(animation);
      return AnimatedBuilder(
        animation: animCtrl,
        builder: (context, child) {
          return Text('Progress: ${(animCtrl.value * 100).toInt()}%');
        },
      );
    });
  }
}

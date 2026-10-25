// Canonical lint cases for widget API design rules:
// `prefer_composed_child` and `prefer_bloom_over_controller`.
// Grammar: see blooming_lints/test/harness/lint_harness.dart

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

final count = BloomController(0).bloom;

// =============================================================================
// BAD
// =============================================================================

// #case prefer_composed_child/bad/const-subtree-inside-composed
// expect_lint: prefer_composed_child
Widget badComposed() => composed((context, via) => Row(
      children: [
        Text('${via(count)}'),
        const Icon(Icons.star),
        const Text('Favorite'),
      ],
    ));

// #case prefer_composed_child/bad/const-subtree-inside-composed-context
// expect_lint: prefer_composed_child
Widget badComposedContext() => composed.vsync((context, via, vsync) => Row(
      children: [
        Text('${via(count)}'),
        const Icon(Icons.star),
        const Text('Favorite'),
      ],
    ));

// #case prefer_bloom_over_controller/bad/controller-widget-parameter
class BadCounterDisplay extends StatelessWidget {
  const BadCounterDisplay({
    super.key,
    // expect_lint: prefer_bloom_over_controller
    required this.counter,
  });

  final BloomController<int> counter;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          composed((context, via) => Text('${via(counter.bloom)}')),
        ],
      );
}

// #case prefer_bloom_over_controller/bad/vsync-widget-controller-parameter
final class BadVsyncWidgetDisplay extends BloomVsyncWidget {
  const BadVsyncWidgetDisplay({
    super.key,
    // expect_lint: prefer_bloom_over_controller
    required this.counter,
  });

  final BloomController<int> counter;

  @override
  Widget build(BuildContext context, BloomVia via, TickerProvider vsync) =>
      Text('${via(counter.bloom)}');
}

// =============================================================================
// GOOD
// =============================================================================

// #case prefer_composed_child/good/static-subtree-in-child
Widget goodComposedChild() => composed.child(
      (context, via, child) => Row(children: [Text('${via(count)}'), child]),
      child: const Icon(Icons.star),
    );

// #case prefer_composed_child/good/only-non-widget-consts
Widget goodNonWidgetConsts() => composed((context, via) => Padding(
      padding: const EdgeInsets.all(8),
      child: Text('${via(count)}'),
    ));

// #case prefer_composed_child/good/trivial-spacers-and-single-label
Widget goodTrivialSpacersAndSingleLabel() => composed((context, via) => Row(
      children: [
        const Text('Cupertino Switch: '),
        const SizedBox(width: 8),
        Text('${via(count)}'),
      ],
    ));

// #case prefer_composed_child/good/dynamic-branch-router
Widget goodDynamicBranchRouter() => composed((context, via) {
      final val = via(count);
      if (val < 0) {
        return const SizedBox();
      }
      return switch (val) {
        0 => const Icon(Icons.star),
        1 => const Icon(Icons.favorite),
        _ => const Icon(Icons.thumb_up),
      };
    });

// #case prefer_composed_child/good/segmented-button-atomic-control
Widget goodSegmentedButtonAtomicControl() =>
    composed((context, via) => SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Planetary Orbit (0~1)'),
              icon: Icon(Icons.rotate_right_rounded, size: 16),
            ),
            ButtonSegment(
              value: true,
              label: Text('Unbounded Space (-1000~+5000)'),
              icon: Icon(Icons.all_inclusive_rounded, size: 16),
            ),
          ],
          selected: {via(count) == 0},
          onSelectionChanged: (_) {},
        ));

// #case prefer_bloom_over_controller/good/bloom-widget-parameter
class GoodCounterDisplay extends StatelessWidget {
  const GoodCounterDisplay({
    super.key,
    required this.counter,
  });

  final Bloom<int> counter;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          composed((context, via) => Text('${via(counter)}')),
        ],
      );
}

// #case prefer_bloom_widget/bad/stateless-wraps-composed
// expect_lint: prefer_bloom_widget
class RedundantStatelessWrapper extends StatelessWidget {
  const RedundantStatelessWrapper({super.key, required this.counter});
  final Bloom<int> counter;

  @override
  Widget build(BuildContext context) =>
      composed((context, via) => Text('${via(counter)}'));
}

// #case prefer_bloom_widget/good/direct-bloom-widget
base class DirectBloomWidgetComponent extends BloomWidget {
  const DirectBloomWidgetComponent({super.key, required this.counter});
  final Bloom<int> counter;

  @override
  Widget build(BuildContext context, BloomVia via) =>
      Text('${via(counter)}');
}

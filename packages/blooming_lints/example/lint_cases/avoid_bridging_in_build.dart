// Canonical lint cases for `avoid_bridging_in_build`.
// Grammar: see blooming_lints/test/harness/lint_harness.dart

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

final notifier = ValueNotifier<int>(0);

// =============================================================================
// BAD
// =============================================================================

// #case avoid_bridging_in_build/bad/to-bloom-in-build
class BadBridgeInBuild extends StatelessWidget {
  const BadBridgeInBuild({super.key});

  @override
  Widget build(BuildContext context) {
    // expect_lint: avoid_bridging_in_build
    final bridged = notifier.toBloom();
    return composed((context, via) => Text('${via(bridged)}'));
  }
}

// #case avoid_bridging_in_build/bad/to-listenable-in-computed
final source = BloomController(0).bloom;
final badInComputed = computed((via) {
  // expect_lint: avoid_bridging_in_build
  final listenable = source.toListenable();
  return via(source) + listenable.value;
});

// =============================================================================
// GOOD
// =============================================================================

// #case avoid_bridging_in_build/good/bridge-cached-outside-build
final cachedBridge = notifier.toBloom();

class GoodCachedBridge extends StatelessWidget {
  const GoodCachedBridge({super.key});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          composed((context, via) => Text('${via(cachedBridge)}')),
        ],
      );
}

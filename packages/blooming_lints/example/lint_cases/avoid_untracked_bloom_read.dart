// Canonical lint cases for `avoid_untracked_bloom_read`.
// Grammar: see blooming_lints/test/harness/lint_harness.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

final counter = BloomController(0);
final count = counter.bloom;
final other = BloomController(1).bloom;

// =============================================================================
// BAD
// =============================================================================

// #case avoid_untracked_bloom_read/bad/data-in-computed
final badComputed = computed((via) {
  final factor = via(other);
  // expect_lint: avoid_untracked_bloom_read
  return untracked(count) * factor;
});

// #case avoid_untracked_bloom_read/bad/mixed-tracked-and-untracked
final badMixed = computed((via) {
  // expect_lint: avoid_untracked_bloom_read
  return via(count) + untracked(other);
});

// #case avoid_untracked_bloom_read/bad/method-read-in-computed
final badMethod = computed((via) {
  final factor = via(other);
  // expect_lint: avoid_untracked_bloom_read
  return untracked.state(count).dataOrElse(() => 0) * factor;
});

// #case avoid_untracked_bloom_read/bad/data-in-effect-via
final badEffect = Effect.via((via) {
  // expect_lint: avoid_untracked_bloom_read
  print(untracked(count));
});

// #case avoid_untracked_bloom_read/bad/data-in-bloom-widget-build
final class BadCounterText extends BloomWidget {
  const BadCounterText({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    // expect_lint: avoid_untracked_bloom_read
    return Text('${untracked(count)}');
  }
}

// #case avoid_untracked_bloom_read/bad/data-in-composed
Widget badComposed() => composed((context, via) {
      // expect_lint: avoid_untracked_bloom_read
      return Text('${untracked(count)}');
    });

// =============================================================================
// GOOD
// =============================================================================

// #case avoid_untracked_bloom_read/good/tracked-via
final goodComputed = computed((via) => via(count) + via(other));

// #case avoid_untracked_bloom_read/good/raw-read-outside-scope
int goodRawRead() => untracked(count);

// #case avoid_untracked_bloom_read/good/raw-read-in-event-callback
final class GoodCounterButton extends BloomWidget {
  const GoodCounterButton({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    return TextButton(
      onPressed: () => print(untracked(count)),
      child: Text('${via(count)}'),
    );
  }
}

// #case avoid_untracked_bloom_read/good/regression-P1-snapshot-variable-after-via
final goodSnapshotVar = computed((via) {
  final snap = via.state(count).snapshot;
  return snap.dataOrElse(() => 0);
});

// #case avoid_untracked_bloom_read/good/regression-P2-snapshot-match-after-via
final goodSnapshotMatch = computed((via) {
  final snap = via.state(count).snapshot;
  return switch (snap.phase) {
    BloomPhase.valid => snap.data,
    BloomPhase.empty => 0,
    BloomPhase.error => -1,
  };
});

// #case avoid_untracked_bloom_read/good/regression-P3-aliased-via-result
final goodAlias = computed((via) {
  final tracked = via.state(count);
  return tracked.data;
});

// #case avoid_untracked_bloom_read/good/regression-P4-renamed-via-parameter
final goodRenamed = computed((BloomVia v) => v(count));

// #case avoid_untracked_bloom_read/good/regression-P5-guard-with-bloom-guard
final goodGuard = computed(
  (via) => via(count),
  guard: (via) => (via(other) > 0).guarded('otherNonPositive'),
);

// #case avoid_untracked_bloom_read/good/regression-P10-manifest-effect-targets
final goodManifestEffect = Effect([count], () => print(untracked(count)));

// #case avoid_untracked_bloom_read/good/regression-P12-terminal-effect-in-build
final class GoodTerminalEffectInBuild extends BloomWidget {
  const GoodTerminalEffectInBuild({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    via.tether(count.effect(() {
      if (untracked(count) > 0) {
        print('count=${untracked(count)}');
      }
    }));
    return const SizedBox();
  }
}

// #case avoid_untracked_bloom_read/good/regression-P13-tracked-state-read-in-closure
final class GoodTrackedStateReadInClosure extends BloomWidget {
  const GoodTrackedStateReadInClosure({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final state = via.state(count);
    return switch (state.phase) {
      BloomPhase.valid => Text('Count: ${state.data}'),
      BloomPhase.empty => Text('Empty (${state.emptyReason})'),
      BloomPhase.error => Text('Error: ${state.error}'),
    };
  }
}

// Canonical lint cases for `avoid_async_in_computed`.
// Grammar: see blooming_lints/test/harness/lint_harness.dart

import 'dart:async';
import 'package:blooming/blooming.dart';

final count = blooming(0).bloom;

// =============================================================================
// BAD
// =============================================================================

// #case avoid_async_in_computed/bad/async-closure
final badAsync = computed(
  // expect_lint: avoid_async_in_computed
  (via) async {
    final value = via(count);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return value * 2;
  },
);

// #case avoid_async_in_computed/bad/async-generator
final badAsyncGen = computed(
  // expect_lint: avoid_async_in_computed
  (via) async* {
    yield via(count);
  },
);

// #case avoid_async_in_computed/bad/direct-future-return
final badDirectFuture = computed(
  // expect_lint: avoid_async_in_computed
  (via) => Future.value(via(count)),
);

// #case avoid_async_in_computed/bad/guard-before-compute
final badGuardBefore = computed(
  guard: (via) => BloomGuard.pass,
  // expect_lint: avoid_async_in_computed
  (via) async => via(count),
);

// =============================================================================
// GOOD
// =============================================================================

// #case avoid_async_in_computed/good/sync-closure
final goodSync = computed((via) => via(count) * 2);

// #case avoid_async_in_computed/good/computed-future
final goodAsync = computed.future((via) async {
  final value = via(count);
  await Future<void>.delayed(const Duration(milliseconds: 10));
  return value * 2;
});


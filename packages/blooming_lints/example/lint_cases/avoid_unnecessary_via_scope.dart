// Canonical lint cases for `avoid_unnecessary_via_scope`.
// Grammar: see blooming_lints/test/harness/lint_harness.dart

import 'package:blooming/blooming.dart';

final count = BloomController(0).bloom;
final fallback = BloomController(1).bloom;

// =============================================================================
// BAD
// =============================================================================

// #case avoid_unnecessary_via_scope/bad/computed-never-tracks
// expect_lint: avoid_unnecessary_via_scope
final badComputed = computed((via) {
  return 42 * 2;
});

// #case avoid_unnecessary_via_scope/bad/switched-never-tracks
// expect_lint: avoid_unnecessary_via_scope
final badSwitched = switched((via) => fallback);

// #case avoid_unnecessary_via_scope/bad/computed-future-never-tracks
// expect_lint: avoid_unnecessary_via_scope
final badFuture = computed.future((via) async => 42);

// =============================================================================
// GOOD
// =============================================================================

// #case avoid_unnecessary_via_scope/good/computed-tracks
final goodComputed = computed((via) => via(count) * 2);

// #case avoid_unnecessary_via_scope/good/switched-tracks
final goodSwitched = switched((via) => via(count) > 0 ? count : fallback);

// #case avoid_unnecessary_via_scope/good/computed-future-tracks
final goodFuture = computed.future((via) async => via(count));

// Canonical lint cases for `avoid_async_in_managed`.
// Grammar: see blooming_lints/test/harness/lint_harness.dart

import 'dart:async';
import 'dart:isolate';

import 'package:blooming/blooming.dart';

// =============================================================================
// BAD
// =============================================================================

// #case avoid_async_in_managed/bad/async-create
final badCreate = managed<Object?>(
  // expect_lint: avoid_async_in_managed
  create: (via) async => Timer.periodic(const Duration(seconds: 1), (_) {}),
  dispose: (resource) {},
);

// #case avoid_async_in_managed/bad/async-dispose-via-static-entrypoint
final badDispose = Bloom.managed<Timer>(
  create: (via) => Timer.periodic(const Duration(seconds: 1), (_) {}),
  // expect_lint: avoid_async_in_managed
  dispose: (timer) async => timer.cancel(),
);

// #case avoid_async_in_managed/bad/direct-future-return
final badDirectFutureManaged = managed<Object?>(
  // expect_lint: avoid_async_in_managed
  create: (via) => Future.value(42),
  dispose: (_) {},
);

// =============================================================================
// GOOD
// =============================================================================

// #case avoid_async_in_managed/good/synchronous-lifecycle
final goodManaged = managed<Timer>(
  create: (via) => Timer.periodic(const Duration(seconds: 1), (_) {}),
  dispose: (timer) => timer.cancel(),
);

// #case avoid_async_in_managed/good/receive-port-stream-resource
final goodReceivePort = managed<ReceivePort>(
  create: (via) => ReceivePort(),
  dispose: (p) => p.close(),
);

// Canonical lint cases for `avoid_escaping_via`.
// Grammar: see blooming_lints/test/harness/lint_harness.dart
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

final source = blooming(1).bloom;

// =============================================================================
// BAD
// =============================================================================

// #case avoid_escaping_via/bad/via-in-timer-callback
final badInTimer = computed((via) {
  final initial = via(source);
  Timer.run(() {
    // expect_lint: avoid_escaping_via
    print(via(source));
  });
  return initial;
});

// #case avoid_escaping_via/bad/via-in-nested-async-after-await
final badNestedAsync = computed((via) {
  Future<void> helper() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // expect_lint: avoid_escaping_via
    print(via(source));
  }

  unawaited(helper());
  return via(source);
});

// #case avoid_escaping_via/bad/via-in-event-callback
final class BadEscapeInCallback extends BloomWidget {
  const BadEscapeInCallback({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    return TextButton(
      // expect_lint: avoid_escaping_via
      onPressed: () => print(via(source)),
      child: const Text('tap'),
    );
  }
}

// =============================================================================
// GOOD
// =============================================================================

// #case avoid_escaping_via/good/via-after-await-in-owning-async-closure
final goodAfterAwait = computed.future((via) async {
  final initial = via(source);
  await Future<void>.delayed(const Duration(milliseconds: 10));
  final postAwait = via(source);
  return initial + postAwait;
});

// #case avoid_escaping_via/good/raw-read-in-event-callback
final class GoodRawReadInCallback extends BloomWidget {
  const GoodRawReadInCallback({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    return TextButton(
      onPressed: () => print(untracked(source)),
      child: Text('${via(source)}'),
    );
  }
}

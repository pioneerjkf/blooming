// Canonical lint cases for `avoid_escaping_via`.
// Grammar: see blooming_lints/test/harness/lint_harness.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

final source = blooming(1).bloom;

// =============================================================================
// BAD
// =============================================================================

// #case avoid_escaping_via/bad/via-after-await
final badAfterAwait = computed.future((via) async {
  final initial = via(source);
  await Future<void>.delayed(const Duration(milliseconds: 10));
  // expect_lint: avoid_escaping_via
  final escaped = via(source);
  return initial + escaped;
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

// #case avoid_escaping_via/good/all-via-before-await
final goodBeforeAwait = computed.future((via) async {
  final initial = via(source);
  final secondary = via(source);
  await Future<void>.delayed(const Duration(milliseconds: 10));
  return initial + secondary;
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

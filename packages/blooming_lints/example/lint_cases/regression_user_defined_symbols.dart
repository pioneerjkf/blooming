// Regression cases: user-defined symbols that merely share a name with Bloom
// APIs must never be treated as Bloom constructs.
// Grammar: see blooming_lints/test/harness/lint_harness.dart
// ignore_for_file: avoid_print

import 'package:blooming/blooming.dart';

final count = BloomController(0).bloom;

// #case regression/good/P9-user-defined-effect-class
class Effect {
  Effect(this.action);
  final void Function() action;
}

final userEffect = Effect(() => print(untracked(count)));

// #case regression/good/P11-user-defined-computed-function
int computedLocally(int Function(Object via) body) => body(Object());

final userComputed = computedLocally((via) => untracked(count));

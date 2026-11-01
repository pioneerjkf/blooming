// Regression cases: user-defined symbols that merely share a name with Bloom
// APIs must never be treated as Bloom constructs.
// Grammar: see blooming_lints/test/harness/lint_harness.dart
// ignore_for_file: avoid_print

import 'dart:async' as dart_async;
import 'package:blooming/blooming.dart';

final count = blooming(0).bloom;

// #case regression/good/P9-user-defined-effect-class
class Effect {
  Effect(this.action);
  final void Function() action;
}

final userEffect = Effect(() => print(untracked(count)));

// #case regression/good/P11-user-defined-computed-function
int computedLocally(int Function(Object via) body) => body(Object());

final userComputed = computedLocally((via) => untracked(count));

// #case regression/good/user-defined-computed-with-async
dart_async.Future<int> computed(
  dart_async.Future<int> Function(Object via) body,
) =>
    body(Object());

final userComputedAsync = computed((via) async => untracked(count));

// #case regression/good/user-defined-future-type-in-computed
class Future<T> {
  const Future(this.value);
  final T value;
}

final userLocalFuture = Bloom.computed(
  (via) => Future<int>(via(count)),
);

// #case regression/good/user-defined-stream-type-in-computed
class Stream<T> {
  const Stream(this.value);
  final T value;
}

final userLocalStream = Bloom.computed(
  (via) => Stream<int>(via(count)),
);

// #case regression/good/user-defined-timer-class
class Timer {
  Timer(Duration duration, void Function() callback) {
    callback();
  }

  static void run(void Function() callback) {
    callback();
  }
}

final userLocalTimer = Bloom.computed(
  (via) {
    Timer(Duration.zero, () {
      print(via(count));
    });
    Timer.run(() {
      print(via(count));
    });
    return via(count);
  },
);


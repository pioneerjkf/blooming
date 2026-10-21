// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:blooming_test/blooming_test.dart';

class CounterStore {
  CounterStore([int initial = 0]) : count = BloomController(initial);

  final BloomController<int> count;

  void increment() {
    count.data++;
  }

  void multiply(int factor) {
    count.data *= factor;
  }
}

class SearchStore {
  SearchStore() {
    // SWR / Debounce search simulation using Timer
    query.bloom.effect(() {
      final term = untracked(query.bloom);
      if (term.isEmpty) {
        results.empty('empty-query');
      } else {
        _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 300), () {
          results.data = ['result for $term'];
        });
      }
    }).run();
  }

  final query = BloomController('');
  final results = BloomController<List<String>>.late(reason: 'empty-query');
  Timer? _timer;

  void dispose() {
    _timer?.cancel();
  }
}

void main() {
  group('bloomTest Declarative Runner Suite', () {
    var teardownInvoked = false;
    var verifyCallCount = 0;

    bloomTest<CounterStore>(
      '1. Basic synchronous build, act, target observation, and snapshot assertion',
      build: () => CounterStore(0),
      target: (store) => store.count.bloom,
      act: (store) {
        store.increment();
        store.increment();
      },
      expect: () => [
        const BloomSnapshot(0),
        const BloomSnapshot(1),
        const BloomSnapshot(2),
      ],
      verify: (store) {
        verifyCallCount++;
        expect(store.count.data, 2);
      },
      tearDown: (store) {
        teardownInvoked = true;
      },
    );

    test('verifies that previous test called verify and tearDown cleanly', () {
      expect(verifyCallCount, 1);
      expect(teardownInvoked, true);
    });

    bloomTest<CounterStore>(
      '2. Matching raw value sequences in expect callback',
      build: () => CounterStore(10),
      target: (store) => store.count.bloom,
      act: (store) {
        store.increment();
        store.multiply(3);
      },
      expect: () => [10, 11, 33],
    );

    bloomTest<SearchStore>(
      '3. Virtual time-skipping with wait and FakeAsync integration',
      build: () => SearchStore(),
      target: (store) => store.results.bloom,
      act: (store) {
        store.query.data = 'bloom_framework';
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        const BloomSnapshot<List<String>>.empty('empty-query'),
        const BloomSnapshot<List<String>>(['result for bloom_framework']),
      ],
      tearDown: (store) => store.dispose(),
    );

    late CounterStore storeRef;

    bloomTest<CounterStore>(
      '4. Auto-deactivation guarantees zero-leak dormant state after test completion',
      build: () {
        storeRef = CounterStore(0);
        return storeRef;
      },
      target: (store) => store.count.bloom,
      act: (store) => store.increment(),
      expect: () => [0, 1],
      tearDown: (store) {
        expect(store.count, isDormant);
      },
    );

    bloomTest<CounterStore>(
      '5. Asynchronous act with Future and zero wait',
      build: () => CounterStore(5),
      target: (store) => store.count.bloom,
      act: (store) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        store.increment();
      },
      expect: () => [5, 6],
    );

    bloomTest<CounterStore>(
      '6. Derived computation pipeline observation',
      build: () => CounterStore(2),
      target: (store) => computed((via) => via(store.count.bloom) * 10),
      act: (store) {
        store.increment();
        store.increment();
      },
      expect: () => [20, 30, 40],
    );

    bloomTest<CounterStore>(
      '7. seed initializes state before target observation',
      build: () => CounterStore(0),
      seed: (store) => store.count.data = 50,
      target: (store) => store.count.bloom,
      act: (store) => store.increment(),
      expect: () => [50, 51],
    );

    bloomTest<CounterStore>(
      '8. errors catches and asserts thrown exceptions during act',
      build: () => CounterStore(0),
      target: (store) => store.count.bloom,
      act: (store) {
        throw StateError('Mutation prohibited');
      },
      errors: () => [isA<StateError>()],
      expect: () => [0],
    );

    bloomTest<CounterStore>(
      '9. errors catches and asserts asynchronous thrown exceptions during act with wait',
      build: () => CounterStore(0),
      target: (store) => store.count.bloom,
      act: (store) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        throw StateError('Async mutation prohibited');
      },
      wait: const Duration(milliseconds: 100),
      errors: () => [isA<StateError>()],
      expect: () => [0],
    );

    bloomTest<CounterStore>(
      '10. errors catches and asserts synchronous thrown exceptions during act with wait',
      build: () => CounterStore(0),
      target: (store) => store.count.bloom,
      act: (store) {
        throw ArgumentError('Sync mutation prohibited with wait');
      },
      wait: const Duration(milliseconds: 50),
      errors: () => [isA<ArgumentError>()],
      expect: () => [0],
    );
  });
}

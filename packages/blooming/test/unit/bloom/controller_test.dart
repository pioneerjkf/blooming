// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:test/test.dart';
import '../../test_utils.dart';

void main() {
  group('BloomController / bloom', () {
    test('initializes with given value and provides standard getters', () {
      final count = BloomController(10);

      expect(count.data, 10);
      expect(count.dataOrNull, 10);
      expect(count.dataOrElse(() => 0), 10);
      expect(count.hasData, isTrue);
      expect(count.isEmpty, isFalse);
      expect(count.hasError, isFalse);
      expect(count.snapshot.data, 10);
    });

    test('mutates data via .data setter and .set()', () {
      final count = BloomController(0);

      count.data = 1;
      expect(count.data, 1);

      count.data = 2;
      expect(count.data, 2);

      count.set(3);
      expect(count.data, 3);
    });

    test('BloomController() class constructor produces identical behavior', () {
      final text = BloomController('hello');
      expect(text.data, 'hello');

      text.data = 'world';
      expect(text.data, 'world');
    });

    test('distinct filtering ignores identical value assignments by default', () async {
      final count = BloomController(10);

      var dirtyCount = 0;
      final effectDispose = effect((via) {
        via(count.bloom);
        dirtyCount++;
      });

      await Future<void>.delayed(Duration.zero);
      // Initial execution
      expect(dirtyCount, 1);

      // Same value assignment
      count.data = 10;
      // Microtask will not be triggered for identical distinct values
      expect(dirtyCount, 1);

      effectDispose();
    });

    test('BloomController.bloom provides read-only reactive view with tracking', () async {
      final mutable = BloomController(42);
      final proxyView = mutable.bloom;

      expect(proxyView, isA<Bloom<int>>());
      expect(proxyView, isNot(isA<BloomController<int>>()));
      expect(untracked(proxyView), 42);

      // Mutating source reflects in proxy view
      mutable.data = 99;
      expect(untracked(proxyView), 99);

      // Auto-tracking works through proxy view
      var observed = 0;
      final effectDispose = effect((via) {
        observed = via(proxyView);
      });

      await Future<void>.delayed(Duration.zero);
      expect(observed, 99);
      mutable.data = 100;
      expect(untracked(proxyView), 100);

      effectDispose();
    });

    test('BloomController(distinct: false) allows duplicate value assignments to trigger effects', () async {
      final count = BloomController(10, distinct: false);

      var effectRuns = 0;
      final dispose = effect((via) {
        effectRuns++;
        via(count.bloom);
      });

      await Future<void>.delayed(Duration.zero);
      expect(effectRuns, 1);

      // Same value assignment with distinct=false
      count.data = 10;
      await Future.microtask(() {});

      expect(effectRuns, 2); // Re-executed!

      count.data = 10;
      await Future.microtask(() {});
      expect(effectRuns, 3);

      dispose();
    });

    test('supports nullable values where null is a valid payload', () {
      final nullableBloom = BloomController<String?>(null);

      expect(nullableBloom.hasData, isTrue);
      expect(nullableBloom.isEmpty, isFalse);
      expect(nullableBloom.hasError, isFalse);
      expect(nullableBloom.data, isNull);
      expect(nullableBloom.dataOrNull, isNull);

      nullableBloom.data = 'hello';
      expect(nullableBloom.data, 'hello');

      nullableBloom.data = null;
      expect(nullableBloom.data, isNull);
    });

    test('accessing .bloom provides direct access to underlying Bloom node', () {
      final count = BloomController(5);
      final node = count.bloom;

      expect(node, isA<Bloom<int>>());
      expect(untracked(node), 5);

      count.data = 25;
      expect(untracked(node), 25);
    });

    test('setGuarded gracefully catches errors and injects error state', () {
      final value = BloomController(10);

      value.setGuarded(() => 20);
      expect(value.data, 20);
      expect(value.hasData, isTrue);

      value.setGuarded(() => throw Exception('calculation failed'));
      expect(value.hasError, isTrue);
      expect(value.hasData, isFalse);
      expect(value.error, isA<Exception>());
      expect(() => value.data, throwsA(isA<BloomSnapshotExtractionException>()));
    });

    test('setError manually injects error state and stack trace', () {
      final state = BloomController('initial');

      state.setError('Network failure');
      expect(state.hasError, isTrue);
      expect(state.error, 'Network failure');
      expect(state.hasData, isFalse);

      state.set('recovered');
      expect(state.hasData, isTrue);
      expect(state.data, 'recovered');
    });

    test('empty resets node to uninitialized state', () {
      final count = BloomController(100);
      expect(count.hasData, isTrue);

      count.empty();
      expect(count.isEmpty, isTrue);
      expect(count.hasData, isFalse);
      expect(() => count.data, throwsA(isA<BloomSnapshotExtractionException>()));

      count.set(200);
      expect(count.hasData, isTrue);
      expect(count.data, 200);

      count.empty();
      expect(count.isEmpty, isTrue);
      expect(count.hasData, isFalse);
    });
  });
}

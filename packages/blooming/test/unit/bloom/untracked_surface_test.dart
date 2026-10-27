// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:blooming/effect.dart';
import 'package:blooming/blooming.dart';

void main() {
  group('Bloom Read Surface: untracked and untracked.state', () {
    test('untracked(x) returns value, throws BloomSnapshotExtractionException on Empty/Error', () {
      final ctrl = blooming<int>(42);
      expect(untracked(ctrl.bloom), equals(42));

      ctrl.set(100);
      expect(untracked(ctrl.bloom), equals(100));

      ctrl.empty('reset');
      expect(() => untracked(ctrl.bloom), throwsA(isA<BloomSnapshotExtractionException>()));

      ctrl.setError('fail');
      expect(() => untracked(ctrl.bloom), throwsA(isA<BloomSnapshotExtractionException>()));
    });

    test('x.bloom has zero public read getters (untracked reads require untracked() or untracked.state())', () {
      // Invariant: Bloom<T> is strictly an opaque node handle and does not implement BloomState<T>
      // or expose any public read getters on its public surface.
      // Therefore, inside or outside closures:
      //   ctrl.bloom.data       --> Compile-time Error: undefined_getter
      //   ctrl.bloom.isEmpty    --> Compile-time Error: undefined_getter
      // Untracked reads must explicitly route through untracked(x) or untracked.state(x).
      final ctrl = blooming<int>(10);
      expect(untracked(ctrl.bloom), equals(10));
      expect(untracked.state(ctrl.bloom).hasData, isTrue);
      expect(untracked.state(ctrl.bloom).isEmpty, isFalse);
    });

    test('identical(via.state(x), untracked.state(x)) - both return the node itself', () {
      final ctrl = blooming<int>(10);
      BloomState<int>? viaState;

      final comp = computed((via) {
        viaState = via.state(ctrl.bloom);
        return via(ctrl.bloom) * 2;
      });

      // Trigger computation
      final r = comp.effect(() {}).start();

      expect(viaState, isNotNull);
      expect(identical(viaState, ctrl.bloom), isTrue);
      expect(identical(untracked.state(ctrl.bloom), ctrl.bloom), isTrue);
      expect(identical(viaState, untracked.state(ctrl.bloom)), isTrue);

      r.stop();
    });

    test('via.state(x) captured view observes current live state across Valid->Valid and Valid->Empty->Valid',
        () async {
      final src = blooming<int>(1);
      final captured = <BloomState<int>>[];

      final derived = computed((via) {
        final s = via.state(src.bloom);
        captured.add(s);
        return via(src.bloom) * 10;
      });

      final r = derived.effect(() {}).start();
      await Future<void>.delayed(Duration.zero);

      expect(captured.length, equals(1));
      expect(captured[0].hasData, isTrue);
      expect(captured[0].data, equals(1));

      // Valid -> Valid
      src.set(2);
      await Future<void>.delayed(Duration.zero);
      expect(captured.length, equals(2));
      // Both captured instances are the node itself
      expect(identical(captured[0], src.bloom), isTrue);
      expect(identical(captured[1], src.bloom), isTrue);
      expect(captured[0].data, equals(2));
      expect(captured[1].data, equals(2));

      src.set(3);
      await Future<void>.delayed(Duration.zero);
      expect(captured.length, equals(3));
      expect(captured[0].data, equals(3));
      expect(captured[2].data, equals(3));

      // Valid -> Empty
      src.empty('reset');
      await Future<void>.delayed(Duration.zero);
      expect(captured.length, equals(4));
      expect(captured[0].isEmpty, isTrue);
      expect(captured[0].emptyReason, equals('reset'));

      // Empty -> Valid
      src.set(4);
      await Future<void>.delayed(Duration.zero);
      expect(captured.length, equals(5));
      expect(captured[0].hasData, isTrue);
      expect(captured[0].data, equals(4));
      expect(identical(captured[0], captured.last), isTrue);

      r.stop();
    });

    test('untracked.state(x).snapshot captures an immutable snapshot unaffected by subsequent mutations', () {
      final ctrl = blooming<String>('initial');
      final snapshot1 = untracked.state(ctrl.bloom).snapshot;

      expect(snapshot1.hasData, isTrue);
      expect(snapshot1.data, equals('initial'));

      ctrl.set('updated');
      final snapshot2 = untracked.state(ctrl.bloom).snapshot;

      expect(snapshot1.data, equals('initial'));
      expect(snapshot2.data, equals('updated'));
      expect(untracked(ctrl.bloom), equals('updated'));

      ctrl.empty('cleared');
      final snapshot3 = untracked.state(ctrl.bloom).snapshot;

      expect(snapshot1.data, equals('initial'));
      expect(snapshot2.data, equals('updated'));
      expect(snapshot3.isEmpty, isTrue);
    });

    test('BloomController, RawBloomTerminal, and BloomSnapshot retain BloomState implementation', () {
      final ctrl = blooming<int>(7);
      // BloomController implements BloomState
      BloomState<int> stateRef = ctrl;
      expect(stateRef.data, equals(7));
      expect(stateRef.hasData, isTrue);

      // RawBloomTerminal implements BloomState
      final terminal = RawBloomTerminal<int>(ctrl.bloom, onInvalidated: () {});
      stateRef = terminal;
      expect(stateRef.data, equals(7));

      // BloomSnapshot implements BloomState
      final snap = BloomSnapshot<int>(7);
      stateRef = snap;
      expect(stateRef.data, equals(7));
    });
  });
}

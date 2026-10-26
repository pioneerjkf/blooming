// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

void main() {
  group('BloomPhase Enum', () {
    test('values contains exactly valid, empty, and error in order', () {
      expect(BloomPhase.values, equals([BloomPhase.valid, BloomPhase.empty, BloomPhase.error]));
    });

    test('phases are mutually exclusive and distinct', () {
      expect(BloomPhase.valid, isNot(equals(BloomPhase.empty)));
      expect(BloomPhase.valid, isNot(equals(BloomPhase.error)));
      expect(BloomPhase.empty, isNot(equals(BloomPhase.error)));
    });
  });

  group('BloomSnapshot.phase', () {
    test('valid snapshot yields BloomPhase.valid', () {
      const snapshot = BloomSnapshot<int>(42);
      expect(snapshot.phase, equals(BloomPhase.valid));
    });

    test('empty snapshot yields BloomPhase.empty', () {
      const snapshot = BloomSnapshot<int>.empty('AwaitingValue');
      expect(snapshot.phase, equals(BloomPhase.empty));
    });

    test('error snapshot yields BloomPhase.error', () {
      final snapshot = BloomSnapshot<int>.error(FormatException('invalid'));
      expect(snapshot.phase, equals(BloomPhase.error));
    });
  });

  group('BloomController.phase & State Transitions', () {
    test('initial phases align with constructor variants', () {
      final validController = blooming<int>(10);
      final emptyController = blooming.late<int>();
      final errorController = blooming.error<int>(Exception('initial error'));

      expect(validController.phase, equals(BloomPhase.valid));
      expect(emptyController.phase, equals(BloomPhase.empty));
      expect(errorController.phase, equals(BloomPhase.error));
    });

    test('transitions update phase reactively', () {
      final controller = blooming.late<int>();
      expect(controller.phase, equals(BloomPhase.empty));

      // Transition: empty -> valid
      controller.data = 100;
      expect(controller.phase, equals(BloomPhase.valid));

      // Transition: valid -> error
      controller.setError(StateError('failure'));
      expect(controller.phase, equals(BloomPhase.error));

      // Transition: error -> empty
      controller.empty('cleared');
      expect(controller.phase, equals(BloomPhase.empty));

      // Transition: empty -> valid
      controller.set(200);
      expect(controller.phase, equals(BloomPhase.valid));
    });
  });

  group('untracked.state(bloom).phase & Computed DAG Propagation', () {
    test('untracked.state reflects the underlying node phase', () {
      final controller = blooming<String>('hello');
      expect(untracked.state(controller.bloom).phase, equals(BloomPhase.valid));

      controller.empty();
      expect(untracked.state(controller.bloom).phase, equals(BloomPhase.empty));

      controller.setError('bad');
      expect(untracked.state(controller.bloom).phase, equals(BloomPhase.error));
    });

    test('computed derivation propagates upstream phase deterministically', () {
      final a = blooming<int>(5);
      final b = blooming<int>(10);
      final sum = computed((via) => via(a.bloom) + via(b.bloom));

      expect(untracked.state(sum).phase, equals(BloomPhase.valid));
      expect(untracked(sum), equals(15));

      // Upstream empty short-circuit -> computed becomes empty
      a.empty('prereq missing');
      expect(untracked.state(sum).phase, equals(BloomPhase.empty));

      // Upstream error short-circuit -> computed becomes error
      b.setError(RangeError('out of bounds'));
      expect(untracked.state(sum).phase, equals(BloomPhase.empty)); // a is still empty and short-circuits first

      a.data = 5;
      expect(untracked.state(sum).phase, equals(BloomPhase.error)); // now b's error surfaces
    });
  });

  group('Dart 3 Exhaustive Pattern Matching on phase', () {
    String describeState(BloomState<int> state) {
      return switch (state.phase) {
        BloomPhase.valid => 'Data: ${state.data}',
        BloomPhase.empty => 'Empty: ${state.emptyReason}',
        BloomPhase.error => 'Error: ${state.error}',
      };
    }

    test('exhaustive switch executes correct branches without wildcard', () {
      final valid = BloomSnapshot<int>(99);
      final empty = BloomSnapshot<int>.empty('no input');
      final error = BloomSnapshot<int>.error('crash');

      expect(describeState(valid), equals('Data: 99'));
      expect(describeState(empty), equals('Empty: no input'));
      expect(describeState(error), equals('Error: crash'));
    });

    test('Dart 3 Object Pattern matching on BloomState with phase', () {
      String matchObject(BloomState<int> state) {
        return switch (state) {
          BloomState(phase: BloomPhase.valid, :final data) => 'Resolved: $data',
          BloomState(phase: BloomPhase.empty, :final emptyReason) => 'Pending: $emptyReason',
          BloomState(phase: BloomPhase.error, :final error) => 'Failed: $error',
        };
      }

      expect(matchObject(BloomSnapshot(1)), equals('Resolved: 1'));
      expect(matchObject(BloomSnapshot.empty('wait')), equals('Pending: wait'));
      expect(matchObject(BloomSnapshot.error('fail')), equals('Failed: fail'));
    });
  });

  group('BloomStateCollectionExtension.wherePhase', () {
    test('filters collection by operational phase', () {
      final list = <BloomState<int>>[
        BloomSnapshot(1),
        BloomSnapshot.empty(),
        BloomSnapshot(2),
        BloomSnapshot.error('e1'),
        BloomSnapshot.empty('reason'),
      ];

      final validItems = list.wherePhase(BloomPhase.valid).toList();
      final emptyItems = list.wherePhase(BloomPhase.empty).toList();
      final errorItems = list.wherePhase(BloomPhase.error).toList();

      expect(validItems, hasLength(2));
      expect(validItems.map((e) => e.data), equals([1, 2]));

      expect(emptyItems, hasLength(2));
      expect(errorItems, hasLength(1));
    });
  });
}

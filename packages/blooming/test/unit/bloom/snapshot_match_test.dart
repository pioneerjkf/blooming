// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.
import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

void main() {
  // ─────────────────────────────────────────────
  // BloomSnapshot switch (phase) Pattern Matching
  // ─────────────────────────────────────────────
  group('BloomSnapshot switch (phase)', () {
    test('valid  → data branch evaluated', () {
      const snap = BloomSnapshot<int>(42);
      final result = switch (snap.phase) {
        BloomPhase.valid => 'data:${snap.data}',
        BloomPhase.empty => 'empty',
        BloomPhase.error => 'error',
      };
      expect(result, 'data:42');
    });

    test('empty  → empty branch evaluated', () {
      const snap = BloomSnapshot<int>.empty();
      final result = switch (snap.phase) {
        BloomPhase.valid => 'data:${snap.data}',
        BloomPhase.empty => 'empty',
        BloomPhase.error => 'error',
      };
      expect(result, 'empty');
    });

    test('error  → error branch evaluated', () {
      final snap = BloomSnapshot<int>.error(Exception('boom'));
      final result = switch (snap.phase) {
        BloomPhase.valid => 'data:${snap.data}',
        BloomPhase.empty => 'empty',
        BloomPhase.error => 'error:${snap.error}',
      };
      expect(result, 'error:Exception: boom');
    });
  });

  group('BloomSnapshot switch fallback with default clause', () {
    test('valid  → evaluated with transformation', () {
      const snap = BloomSnapshot<int>(10);
      final res = switch (snap.phase) {
        BloomPhase.valid => snap.data * 2,
        _ => -1,
      };
      expect(res, 20);
    });

    test('empty  → fallback returned', () {
      const snap = BloomSnapshot<int>.empty();
      final res = switch (snap.phase) {
        BloomPhase.valid => snap.data,
        _ => -1,
      };
      expect(res, -1);
    });

    test('error  → error branch returned', () {
      final snap = BloomSnapshot<int>.error(Exception('x'));
      final res = switch (snap.phase) {
        BloomPhase.error => 99,
        _ => 0,
      };
      expect(res, 99);
    });
  });

  group('BloomSnapshot conditional null-coalescing with hasData / hasError / dataOrNull', () {
    test('valid  → returns value', () {
      const snap = BloomSnapshot<int>(5);
      final res = snap.hasData ? snap.data + 1 : null;
      expect(res, 6);
      expect(snap.dataOrNull != null ? snap.dataOrNull! + 1 : null, 6);
    });

    test('empty  → returns null', () {
      const snap = BloomSnapshot<int>.empty();
      final res = snap.hasData ? snap.data : null;
      expect(res, isNull);
      expect(snap.dataOrNull, isNull);
    });

    test('error  → returns error string', () {
      final snap = BloomSnapshot<int>.error(Exception('fail'));
      final res = snap.hasError ? snap.error.toString() : null;
      expect(res, 'Exception: fail');
      expect(snap.dataOrNull, isNull);
    });
  });

  // ─────────────────────────────────────────────
  // Bloom (BloomState) — live node switch (phase)
  // ─────────────────────────────────────────────
  group('Bloom switch (phase) on live node', () {
    test('valid bloom → data branch', () {
      final node = BloomController(7);
      final res = switch (node.phase) {
        BloomPhase.valid => node.data,
        BloomPhase.empty => 0,
        BloomPhase.error => -1,
      };
      expect(res, 7);
    });

    test('late bloom → empty branch', () {
      final node = BloomController<int>.late();
      final res = switch (node.phase) {
        BloomPhase.valid => node.data,
        BloomPhase.empty => 0,
        BloomPhase.error => -1,
      };
      expect(res, 0);
    });

    test('error bloom → error branch', () {
      final node = BloomController<int>.error(Exception('bloom fail'));
      final res = switch (node.phase) {
        BloomPhase.valid => node.data,
        BloomPhase.empty => 0,
        BloomPhase.error => -1,
      };
      expect(res, -1);
    });
  });

  // ─────────────────────────────────────────────
  // BloomSnapshot<List<Bloom>> switch (phase)
  // ─────────────────────────────────────────────
  group('BloomSnapshot<List<Bloom>> switch (phase)', () {
    final g1 = BloomController(1);
    final g2 = BloomController(2);

    test('hasData → data branch', () {
      final snap = BloomSnapshot([g1, g2]);
      final result = switch (snap.phase) {
        BloomPhase.valid => snap.data.length,
        BloomPhase.empty => 0,
        BloomPhase.error => -1,
      };
      expect(result, 2);
    });

    test('empty group snapshot → empty branch', () {
      const snap = BloomSnapshot<List<Bloom<int>>>.empty();
      final result = switch (snap.phase) {
        BloomPhase.valid => snap.data.length,
        BloomPhase.empty => -99,
        BloomPhase.error => -1,
      };
      expect(result, -99);
    });

    test('error group snapshot → error branch', () {
      final snap = BloomSnapshot<List<Bloom<int>>>.error(Exception('group fail'));
      final result = switch (snap.phase) {
        BloomPhase.valid => snap.data.length,
        BloomPhase.empty => 0,
        BloomPhase.error => -1,
      };
      expect(result, -1);
    });
  });

  // ─────────────────────────────────────────────
  // BloomListController live node — switch (phase)
  // ─────────────────────────────────────────────
  group('BloomListController switch (phase) on live node', () {
    test('valid group → data branch', () {
      final c = blooming.list([BloomController(1).bloom, BloomController(2).bloom]);
      final res = switch (c.phase) {
        BloomPhase.valid => c.data.length,
        BloomPhase.empty => 0,
        BloomPhase.error => -1,
      };
      expect(res, 2);
    });

    test('empty group → empty branch', () {
      final c = blooming.list.late<Bloom<int>>();
      final res = switch (c.phase) {
        BloomPhase.valid => c.data.length,
        BloomPhase.empty => -99,
        BloomPhase.error => -1,
      };
      expect(res, -99);
    });

    test('error group → error branch', () {
      final c = blooming.list.late<Bloom<int>>();
      c.setError(Exception('x'));
      final res = switch (c.phase) {
        BloomPhase.valid => c.data.length,
        BloomPhase.empty => 0,
        BloomPhase.error => -1,
      };
      expect(res, -1);
    });
  });

  // ─────────────────────────────────────────────
  // Reactive dependency tracking — switch (phase) via BloomVia
  // ─────────────────────────────────────────────
  group('Reactive pattern matching tracking', () {
    test('switch (via.state(controller.bloom).phase) inside RawViaTerminal registers dependency', () {
      final controller = BloomController(0);
      var invalidateCount = 0;

      final terminal = RawViaTerminal(
        (BloomVia via) {
          final state = via.state(controller.bloom);
          return switch (state.phase) {
            BloomPhase.valid => 'data:${state.data}',
            BloomPhase.empty => 'empty',
            BloomPhase.error => 'error',
          };
        },
        onInvalidated: () => invalidateCount++,
      );

      expect(terminal.evaluate(), 'data:0');
      terminal.activate();

      controller.set(1);
      expect(invalidateCount, 1);

      terminal.deactivate();
    });
  });

  // ─────────────────────────────────────────────
  // BloomStateCollectionExtension
  // ─────────────────────────────────────────────
  group('BloomStateCollectionExtension', () {
    test('allHaveData, hasAnyEmpty, hasAnyError', () {
      final a = BloomController(1);
      final b = BloomController(2);
      final c = BloomController(3);

      final listAllData = [a, b, c];
      expect(listAllData.allHaveData(), isTrue);
      expect(listAllData.hasAnyEmpty(), isFalse);
      expect(listAllData.hasAnyError(), isFalse);

      final empty = BloomController<int>.late();
      final listWithEmpty = [a, empty, c];
      expect(listWithEmpty.allHaveData(), isFalse);
      expect(listWithEmpty.hasAnyEmpty(), isTrue);
      expect(listWithEmpty.hasAnyError(), isFalse);

      final error = Bloom<int>.error('err');
      final listWithError = [a, b, untracked.state(error)];
      expect(listWithError.allHaveData(), isFalse);
      expect(listWithError.hasAnyEmpty(), isFalse);
      expect(listWithError.hasAnyError(), isTrue);
    });

    test('whereHasData, whereEmpty, whereError filtering', () {
      final v1 = BloomController('v1');
      final v2 = BloomController('v2');
      final e1 = BloomController<String>.late();
      final err1 = Bloom<String>.error('error1');

      final mixed = [v1, e1, v2, untracked.state(err1)];

      expect(mixed.whereHasData().toList(), [v1, v2]);
      expect(mixed.whereEmpty().toList(), [e1]);
      expect(mixed.whereError().toList(), [untracked.state(err1)]);
    });

    test('Works seamlessly with computed(guard)', () {
      final a = BloomController<int>.late();
      final b = BloomController<int>.late();
      final c = BloomController<int>.late();

      final comp = computed<int>(
        (via) => (via(a.bloom) + via(b.bloom) + via(c.bloom)).toInt(),
        guard: (via) => (via.state(a.bloom), via.state(b.bloom), via.state(c.bloom)).guarded('Waiting'),
      );

      expect(untracked.state(comp).isEmpty, isTrue);
      expect(untracked.state(comp).snapshot.emptyReason, 'Waiting');

      a.set(10);
      expect(untracked.state(comp).isEmpty, isTrue);

      b.set(20);
      expect(untracked.state(comp).isEmpty, isTrue);

      c.set(30);
      expect(untracked.state(comp).hasData, isTrue);
      expect(untracked(comp), 60);
    });
  });

  // ─────────────────────────────────────────────
  // BloomState Record Tuple Extensions (Zero Allocation)
  // ─────────────────────────────────────────────
  group('BloomState Record Tuple Extensions', () {
    test('(a, b) status checks: allHaveData, hasAnyEmpty, hasAnyError', () {
      final a = BloomController<int>.late();
      final b = BloomController('hello');

      expect((a, b).allHaveData(), isFalse);
      expect((a, b).hasAnyEmpty(), isTrue);
      expect((a, b).hasAnyError(), isFalse);

      a.set(42);
      expect((a, b).allHaveData(), isTrue);
      expect((a, b).hasAnyEmpty(), isFalse);
      expect((a, b).hasAnyError(), isFalse);
    });

    test('(a, b, c).allHaveData in guard with zero heap allocation', () {
      final a = BloomController<int>.late();
      final b = BloomController<int>.late();
      final c = BloomController<int>.late();

      final comp = computed<int>(
        (via) => (via(a.bloom) + via(b.bloom) + via(c.bloom)).toInt(),
        guard: (via) => (via.state(a.bloom), via.state(b.bloom), via.state(c.bloom)).guarded('Waiting'),
      );

      expect(untracked.state(comp).isEmpty, isTrue);

      a.set(10);
      expect(untracked.state(comp).isEmpty, isTrue);

      b.set(20);
      expect(untracked.state(comp).isEmpty, isTrue);

      c.set(30);
      expect(untracked.state(comp).hasData, isTrue);
      expect(untracked(comp), 60);
      expect((a, b, c).allHaveData(), isTrue);
    });

    test('Record tuple status extensions (2 to 9 elements, heterogeneous)', () {
      final intBloom = BloomController(10);
      final strBloom = BloomController('hello');
      final boolBloom = BloomController<bool>.late();
      final doubleBloom = BloomController(3.14);
      final listBloom = BloomController([1, 2]);
      final mapBloom = BloomController({'key': 'val'});
      final setBloom = BloomController({1, 2, 3});
      final symBloom = BloomController(#symbol);
      final objBloom = BloomController(Object());

      final t2 = (intBloom, strBloom);
      expect(t2.allHaveData(), isTrue);
      expect(t2.hasAnyEmpty(), isFalse);

      final t3 = (intBloom, strBloom, boolBloom);
      expect(t3.allHaveData(), isFalse);
      expect(t3.hasAnyEmpty(), isTrue);

      boolBloom.set(true);
      expect(t3.allHaveData(), isTrue);
      expect(t3.hasAnyEmpty(), isFalse);

      final t4 = (intBloom, strBloom, boolBloom, doubleBloom);
      expect(t4.allHaveData(), isTrue);

      final t5 = (intBloom, strBloom, boolBloom, doubleBloom, listBloom);
      expect(t5.allHaveData(), isTrue);

      final t6 = (intBloom, strBloom, boolBloom, doubleBloom, listBloom, mapBloom);
      expect(t6.allHaveData(), isTrue);
      expect(t6.hasAnyError(), isFalse);

      final t7 = (intBloom, strBloom, boolBloom, doubleBloom, listBloom, mapBloom, setBloom);
      expect(t7.allHaveData(), isTrue);
      expect(t7.hasAnyEmpty(), isFalse);

      final t8 = (intBloom, strBloom, boolBloom, doubleBloom, listBloom, mapBloom, setBloom, symBloom);
      expect(t8.allHaveData(), isTrue);

      final t9 = (intBloom, strBloom, boolBloom, doubleBloom, listBloom, mapBloom, setBloom, symBloom, objBloom);
      expect(t9.allHaveData(), isTrue);
      expect(t9.hasAnyEmpty(), isFalse);
      expect(t9.hasAnyError(), isFalse);

      // Dedicated error and empty branch coverage across tuples 3 to 9
      final errBloom = BloomController<int>.error(StateError('error'));
      final emptyBloom = BloomController<int>.late();
      final validBloom = BloomController(1);

      // t3 error
      expect((validBloom, validBloom, errBloom).hasAnyError(), isTrue);
      expect((validBloom, validBloom, validBloom).hasAnyError(), isFalse);

      // t4 empty & error
      expect((validBloom, validBloom, validBloom, emptyBloom).hasAnyEmpty(), isTrue);
      expect((validBloom, validBloom, validBloom, validBloom).hasAnyEmpty(), isFalse);
      expect((validBloom, validBloom, validBloom, errBloom).hasAnyError(), isTrue);
      expect((validBloom, validBloom, validBloom, validBloom).hasAnyError(), isFalse);

      // t5 empty & error
      expect((validBloom, validBloom, validBloom, validBloom, emptyBloom).hasAnyEmpty(), isTrue);
      expect((validBloom, validBloom, validBloom, validBloom, validBloom).hasAnyEmpty(), isFalse);
      expect((validBloom, validBloom, validBloom, validBloom, errBloom).hasAnyError(), isTrue);
      expect((validBloom, validBloom, validBloom, validBloom, validBloom).hasAnyError(), isFalse);

      // t6 empty & error
      expect((validBloom, validBloom, validBloom, validBloom, validBloom, emptyBloom).hasAnyEmpty(), isTrue);
      expect((validBloom, validBloom, validBloom, validBloom, validBloom, validBloom).hasAnyEmpty(), isFalse);
      expect((validBloom, validBloom, validBloom, validBloom, validBloom, errBloom).hasAnyError(), isTrue);

      // t7 empty & error
      expect(
          (validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, emptyBloom).hasAnyEmpty(), isTrue);
      expect((validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, errBloom).hasAnyError(), isTrue);
      expect(
          (validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, validBloom).hasAnyError(), isFalse);

      // t8 empty & error
      expect(
          (validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, emptyBloom)
              .hasAnyEmpty(),
          isTrue);
      expect(
          (validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, validBloom)
              .hasAnyEmpty(),
          isFalse);
      expect(
          (validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, errBloom).hasAnyError(),
          isTrue);
      expect(
          (validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, validBloom)
              .hasAnyError(),
          isFalse);

      // t9 empty & error
      expect(
          (validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, emptyBloom)
              .hasAnyEmpty(),
          isTrue);
      expect(
          (validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, validBloom, errBloom)
              .hasAnyError(),
          isTrue);
    });
  });
}

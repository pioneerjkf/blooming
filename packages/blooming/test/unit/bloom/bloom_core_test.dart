// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

final class _TestBinaryComputation extends Computation<int> {
  _TestBinaryComputation(this.a, this.b);

  final Bloom<int> a;
  final Bloom<int> b;

  int computeCallCount = 0;

  @override
  int compute(BloomVia via) {
    computeCallCount++;
    return via(a) + via(b);
  }
}

void main() {
  group('Bloom Core, Controller, Snapshot & Operators Unit Tests', () {
    // =========================================================================
    // 1. BloomSnapshot 3-State Exclusivity, Equality & Sound Null-Safety
    // =========================================================================
    group('1. BloomSnapshot Core & Invariants', () {
      test('1.1 Snapshot 3-State exclusivity and extraction contracts', () {
        final sValid1 = const BloomSnapshot<int>(100);
        final sValid2 = const BloomSnapshot<int>(100);
        final sValid3 = const BloomSnapshot<int>(200);
        final sEmpty = const BloomSnapshot<int>.empty();
        final sError = BloomSnapshot<int>.error('Error');

        expect(sValid1.hasData, isTrue);
        expect(sValid1.data, 100);
        expect(sValid1.dataOrNull, 100);
        expect(sValid1.dataOrElse(() => 999), 100);

        expect(sEmpty.isEmpty, isTrue);
        expect(sEmpty.dataOrNull, isNull);
        expect(sEmpty.dataOrElse(() => 999), 999);
        expect(() => sEmpty.data, throwsA(isA<BloomSnapshotExtractionException>()));

        expect(sError.hasError, isTrue);
        expect(sError.error, 'Error');
        expect(sError.dataOrNull, isNull);
        expect(sError.dataOrElse(() => 999), 999);
        expect(() => sError.data, throwsA(isA<BloomSnapshotExtractionException>()));

        expect(sValid1.equals(sValid2), isTrue);
        expect(sValid1.equals(sValid3), isFalse);
        expect(sValid1.equals(sValid3, (a, b) => a % 100 == b % 100), isTrue);
      });

      test('1.2 Valid Snapshot containing explicit null (Sound Null Safety)', () {
        const snapshot = BloomSnapshot<String?>(null);

        expect(snapshot.hasData, isTrue);
        expect(snapshot.isEmpty, isFalse);
        expect(snapshot.hasError, isFalse);

        expect(snapshot.data, isNull);
        expect(snapshot.dataOrNull, isNull);
        expect(snapshot.dataOrElse(() => 'fallback'), isNull);

        expect(
          () => snapshot.error,
          throwsA(isA<BloomSnapshotStateException>().having((e) => e.state, 'state', 'Valid')),
        );
        expect(
          () => snapshot.stackTrace,
          throwsA(isA<BloomSnapshotStateException>().having((e) => e.state, 'state', 'Valid')),
        );
      });

      test('1.3 Empty Snapshot invariants and fail-fast extraction behavior', () {
        const snapshot = BloomSnapshot<int>.empty();

        expect(snapshot.hasData, isFalse);
        expect(snapshot.isEmpty, isTrue);
        expect(snapshot.hasError, isFalse);

        expect(
          () => snapshot.data,
          throwsA(isA<BloomSnapshotExtractionException>().having((e) => e.state, 'state', 'Empty')),
        );

        expect(snapshot.dataOrNull, isNull);
        expect(snapshot.dataOrElse(() => 42), 42);

        expect(
          () => snapshot.error,
          throwsA(isA<BloomSnapshotStateException>().having((e) => e.state, 'state', 'Empty')),
        );
      });

      test('1.4 Error Snapshot invariants, error payload, and fail-fast extraction', () {
        final customError = StateError('Corrupted Pipeline');
        final customTrace = StackTrace.current;
        final snapshot = BloomSnapshot<double>.error(customError, customTrace);

        expect(snapshot.hasData, isFalse);
        expect(snapshot.isEmpty, isFalse);
        expect(snapshot.hasError, isTrue);

        expect(
          () => snapshot.data,
          throwsA(
            isA<BloomSnapshotExtractionException>()
                .having((e) => e.state, 'state', 'Error')
                .having((e) => e.error, 'error', customError)
                .having((e) => e.stackTrace, 'stackTrace', customTrace),
          ),
        );

        expect(snapshot.dataOrNull, isNull);
        expect(snapshot.dataOrElse(() => 3.14), 3.14);
        expect(snapshot.error, same(customError));
        expect(snapshot.stackTrace, same(customTrace));
      });

      test('1.5 Snapshot Equality matrix across nulls, records, and comparators', () {
        const nullSnap1 = BloomSnapshot<String?>(null);
        const nullSnap2 = BloomSnapshot<String?>(null);
        const nonNullSnap = BloomSnapshot<String?>('test');
        const emptySnap = BloomSnapshot<String?>.empty();
        final errorSnap = BloomSnapshot<String?>.error('Err');

        expect(nullSnap1.equals(nullSnap2), isTrue);
        expect(nullSnap1.equals(nonNullSnap), isFalse);
        expect(nullSnap1.equals(emptySnap), isFalse);
        expect(nullSnap1.equals(errorSnap), isFalse);

        final snapCaseA = const BloomSnapshot<String>('HELLO');
        final snapCaseB = const BloomSnapshot<String>('hello');
        expect(snapCaseA.equals(snapCaseB), isFalse);
        expect(
          snapCaseA.equals(snapCaseB, (a, b) => a.toLowerCase() == b.toLowerCase()),
          isTrue,
        );

        const recordSnap1 = BloomSnapshot<(int, String)>((1, 'A'));
        const recordSnap2 = BloomSnapshot<(int, String)>((1, 'A'));
        const recordSnap3 = BloomSnapshot<(int, String)>((2, 'A'));
        expect(recordSnap1.equals(recordSnap2), isTrue);
        expect(recordSnap1.equals(recordSnap3), isFalse);

        const empty1 = BloomSnapshot<int>.empty();
        const empty2 = BloomSnapshot<int>.empty();
        expect(empty1.equals(empty2), isTrue);

        final trace = StackTrace.current;
        final err1 = BloomSnapshot<int>.error('ErrA', trace);
        final err2 = BloomSnapshot<int>.error('ErrA', trace);
        final err3 = BloomSnapshot<int>.error('ErrB', trace);
        expect(err1.equals(err2), isTrue);
        expect(err1.equals(err3), isFalse);
        expect(err1.equals(empty1), isFalse);
      });
    });

    // =========================================================================
    // 2. Nullable Pipeline & Combinator Soundness
    // =========================================================================
    group('2. Nullable Pipeline & Combinator Soundness', () {
      test('2.1 BloomController with nullable type and computed derivations', () {
        final controller = BloomController<String?>(null);
        final lengthBloom = computed((via) => via(controller.bloom)?.length);
        final upperBloom = computed((via) => via(controller.bloom)?.toUpperCase());

        final lenTerminal = RawBloomTerminal(lengthBloom, onInvalidated: () {});
        final upTerminal = RawBloomTerminal(upperBloom, onInvalidated: () {});
        lenTerminal.activate();
        upTerminal.activate();

        expect(lenTerminal.hasData, isTrue);
        expect(lenTerminal.data, isNull);
        expect(upTerminal.hasData, isTrue);
        expect(upTerminal.data, isNull);

        controller.set('flutter');
        expect(lenTerminal.data, 7);
        expect(upTerminal.data, 'FLUTTER');

        controller.set(null);
        expect(lenTerminal.hasData, isTrue);
        expect(lenTerminal.data, isNull);
        expect(upTerminal.hasData, isTrue);
        expect(upTerminal.data, isNull);

        lenTerminal.deactivate();
        upTerminal.deactivate();
      });

      test('2.2 Distinct combinator coalesces consecutive null and non-null transitions', () {
        final controller = BloomController<String?>(null);
        int distinctDirtyCount = 0;

        final distinctBloom = controller.bloom.distinct();
        final terminal = RawBloomTerminal(distinctBloom, onInvalidated: () {
          distinctDirtyCount++;
        });
        terminal.activate();

        expect(terminal.data, isNull);
        expect(distinctDirtyCount, 0);

        controller.set(null);
        expect(distinctDirtyCount, 0);
        expect(terminal.data, isNull);

        controller.set('alpha');
        expect(distinctDirtyCount, 1);
        expect(terminal.data, 'alpha');

        controller.set('alpha');
        expect(distinctDirtyCount, 1);

        controller.set(null);
        expect(distinctDirtyCount, 2);
        expect(terminal.data, isNull);

        terminal.deactivate();
      });

      test('2.3 Fallback and null recovery with Nullable Flows via computed', () {
        final emptyController = BloomController<String?>.late();
        final fallbackToDefault = computed((via) {
          final s = via.state(emptyController.bloom).snapshot;
          if (s.isEmpty) return 'DEFAULT_VALUE';
          if (s.hasError) return 'ERROR_RECOVERED';
          return s.data;
        });
        final fallbackToNull = computed<String?>((via) {
          final s = via.state(emptyController.bloom).snapshot;
          if (s.isEmpty) return null;
          if (s.hasError) throw s.error;
          return s.data;
        });

        final defTerminal = RawBloomTerminal(fallbackToDefault, onInvalidated: () {});
        final nullTerminal = RawBloomTerminal(fallbackToNull, onInvalidated: () {});
        defTerminal.activate();
        nullTerminal.activate();

        expect(defTerminal.data, 'DEFAULT_VALUE');
        expect(nullTerminal.hasData, isTrue);
        expect(nullTerminal.data, isNull);

        emptyController.set(null);
        expect(defTerminal.hasData, isTrue);
        expect(defTerminal.data, isNull);
        expect(nullTerminal.hasData, isTrue);
        expect(nullTerminal.data, isNull);

        emptyController.setError(Exception('Boom'));
        expect(defTerminal.data, 'ERROR_RECOVERED');
        expect(nullTerminal.hasError, isTrue);

        emptyController.empty();
        expect(defTerminal.data, 'DEFAULT_VALUE');
        expect(nullTerminal.hasData, isTrue);
        expect(nullTerminal.data, isNull);

        defTerminal.deactivate();
        nullTerminal.deactivate();
      });
    });

    // =========================================================================
    // 3. BloomController Lifecycle & Callbacks
    // =========================================================================
    group('3. BloomController Lifecycle & Callbacks', () {
      test('3.1 BloomController with onActivated and onDeactivated callbacks', () {
        int activatedCount = 0;
        int deactivatedCount = 0;

        final controller = BloomController<int>(
          10,
          onActivated: () => activatedCount++,
          onDeactivated: () => deactivatedCount++,
        );

        expect(activatedCount, 0);
        expect(deactivatedCount, 0);

        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () {});
        expect(activatedCount, 0);

        terminal.activate();
        expect(activatedCount, 1);
        expect(deactivatedCount, 0);

        terminal.deactivate();
        expect(activatedCount, 1);
        expect(deactivatedCount, 1);
      });

      test('3.2 BloomController.late with onActivated and onDeactivated callbacks', () {
        int activatedCount = 0;
        int deactivatedCount = 0;

        final controller = BloomController<int>.late(
          onActivated: () => activatedCount++,
          onDeactivated: () => deactivatedCount++,
        );

        expect(activatedCount, 0);
        expect(deactivatedCount, 0);

        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () {});
        expect(activatedCount, 0);

        terminal.activate();
        expect(activatedCount, 1);
        expect(deactivatedCount, 0);

        controller.set(42);
        expect(terminal.data, 42);

        terminal.deactivate();
        expect(activatedCount, 1);
        expect(deactivatedCount, 1);
      });
    });

    // =========================================================================
    // 4. Bloom Operators & Extensions (distinct, select, fallback, map)
    // =========================================================================
    group('4. Bloom Operators & Extensions', () {
      test('4.1 RawBloomTerminal attaches directly to source', () {
        int dirtyCount = 0;
        final controller = BloomController<int>(10);
        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () {
          dirtyCount++;
        });

        terminal.activate();
        expect(terminal.snapshot.data, 10);

        controller.set(20);
        expect(dirtyCount, 1);
        expect(terminal.snapshot.data, 20);

        terminal.deactivate();
      });

      test('4.2 distinct suppresses duplicate snapshots', () {
        final controller = BloomController<int>(10);
        int dirtyCount = 0;

        final distinctBloom = controller.bloom.distinct();
        final terminal = RawBloomTerminal(distinctBloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(untracked(distinctBloom), 10);

        controller.set(10);
        expect(dirtyCount, 0);

        controller.set(20);
        expect(dirtyCount, 1);
        expect(untracked(distinctBloom), 20);

        terminal.deactivate();
      });

      test('4.3 computed with distinct projects slice and suppresses duplicate snapshots', () {
        final controller = BloomController<({String name, int age})>((name: 'Alice', age: 20));
        int dirtyCount = 0;

        final nameBloom = computed((via) => via(controller.bloom).name).distinct();
        final terminal = RawBloomTerminal(nameBloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(untracked(nameBloom), 'Alice');

        controller.set((name: 'Alice', age: 21));
        // Under 2-Phase Lazy-Pull: Dirty pulse notifies terminal without eager computation
        expect(dirtyCount, 1);
        final baseVersion = nameBloom.debugVersion;
        expect(terminal.data, 'Alice');
        // When pulled, since the selected slice 'Alice' didn't change, version is NOT incremented!
        expect(nameBloom.debugVersion, equals(baseVersion));

        controller.set((name: 'Bob', age: 21));
        expect(dirtyCount, 2);
        expect(terminal.data, 'Bob');
        expect(nameBloom.debugVersion, greaterThan(baseVersion));

        final ageCategoryBloom = computed((via) => via(controller.bloom).age).distinct(
          (prev, next) => (prev ~/ 10) == (next ~/ 10),
        );
        int ageCategoryDirty = 0;
        final t2 = RawBloomTerminal(ageCategoryBloom, onInvalidated: () => ageCategoryDirty++);
        t2.activate();

        expect(t2.data, 21);

        controller.set((name: 'Bob', age: 25));
        expect(ageCategoryDirty, 1);
        final baseAgeVersion = ageCategoryBloom.debugVersion;
        expect(t2.data, 21);
        expect(ageCategoryBloom.debugVersion, equals(baseAgeVersion));

        controller.set((name: 'Bob', age: 30));
        expect(ageCategoryDirty, 2);
        expect(t2.data, 30);
        expect(ageCategoryBloom.debugVersion, greaterThan(baseAgeVersion));

        terminal.deactivate();
        t2.deactivate();
      });

      test('4.3.1 equals callback exception in _DistinctEntry safely converges to error state without rethrow', () {
        final controller = BloomController<int>(
          1,
          equals: (prev, next) {
            if (next == 42) throw const FormatException('Forbidden number 42');
            return prev == next;
          },
        );

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.data, 1);
        expect(dirtyCount, 0);

        // Mutating with 42 causes equals to throw.
        // Should NOT rethrow from set(), but should transition controller to error state and notify terminal.
        expect(() => controller.set(42), returnsNormally);
        expect(dirtyCount, 1);
        expect(controller.hasError, isTrue);
        expect(controller.error, isA<FormatException>());
        expect(terminal.hasError, isTrue);
        expect(terminal.error, isA<FormatException>());

        terminal.deactivate();
      });

      test('4.3.2 equals callback exception in _DistinctBloom._pull safely transitions node to error state', () {
        final source = BloomController<int>(1);
        final distinctBloom = source.bloom.distinct((prev, next) {
          if (next == 99) throw StateError('99 is invalid');
          return prev == next;
        });

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(distinctBloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.data, 1);
        expect(dirtyCount, 0);

        source.set(99);
        expect(dirtyCount, 1);

        // Pulling terminal should safely yield error state rather than throwing unhandled exception
        expect(() => terminal.hasError, returnsNormally);
        expect(terminal.hasError, isTrue);
        expect(terminal.error, isA<StateError>());
        expect(untracked.state(distinctBloom).hasError, isTrue);
        expect(untracked.state(distinctBloom).error, isA<StateError>());

        terminal.deactivate();
      });

      test('4.4 computed recovers empty and error states via dataOrElse or snapshot', () {
        final cEmpty = Bloom<String>.empty();
        final cError = Bloom<String>.error('Failure');

        final recoveredEmpty = computed((via) => via.state(cEmpty).dataOrElse(() => 'RecoveredEmpty'));
        final recoveredError = computed((via) {
          final s = via.state(cError).snapshot;
          if (s.hasError) return 'RecoveredError: ${s.error}';
          return s.data;
        });

        final t1 = RawBloomTerminal(recoveredEmpty, onInvalidated: () {});
        final t2 = RawBloomTerminal(recoveredError, onInvalidated: () {});
        t1.activate();
        t2.activate();

        expect(untracked(recoveredEmpty), 'RecoveredEmpty');
        expect(untracked(recoveredError), 'RecoveredError: Failure');

        t1.deactivate();
        t2.deactivate();
      });

      test('4.5 dataOrElse converts empty state to valid null', () {
        final cEmpty = Bloom<String>.empty();
        final nullBloom = computed<String?>((via) => via.state(cEmpty).hasData ? via(cEmpty) : null);

        final t = RawBloomTerminal(nullBloom, onInvalidated: () {});
        t.activate();

        expect(untracked.state(nullBloom).hasData, isTrue);
        expect(untracked(nullBloom), isNull);

        t.deactivate();
      });

      test('4.6 Iterable<BloomState<T>> and Iterable<BloomSnapshot<T>> data accessors', () {
        final list = <Bloom<int>>[Bloom.constant(10), Bloom.constant(20), Bloom.constant(30)];
        final terminals = list.map((c) => RawBloomTerminal(c, onInvalidated: () {})).toList();
        for (final t in terminals) {
          t.activate();
        }

        expect(list.map((w) => untracked.state(w)).data.toList(), [10, 20, 30]);
        for (final t in terminals) {
          t.deactivate();
        }

        final snapshots = <BloomSnapshot<String>>[
          const BloomSnapshot<String>('first'),
          const BloomSnapshot<String>('second'),
        ];
        expect(snapshots.data.toList(), ['first', 'second']);

        final emptySnapshots = <BloomSnapshot<String>>[
          const BloomSnapshot<String>('valid'),
          const BloomSnapshot<String>.empty(),
        ];
        expect(() => emptySnapshots.data.toList(), throwsA(isA<BloomSnapshotExtractionException>()));
        expect(emptySnapshots.dataOrNull.toList(), ['valid', null]);

        final mixedBlooms = <Bloom<int>>[
          Bloom.constant(100),
          Bloom<int>.empty(),
        ];
        expect(mixedBlooms.map((w) => untracked.state(w)).dataOrNull.toList(), [100, null]);
      });

      test('4.7 Bloom.constant creates a Bloom node list from Iterable<Bloom<T>>', () {
        final list = <Bloom<String>>[Bloom.constant('a'), Bloom.constant('b')];
        final group = Bloom.constant(list);
        expect(group, isA<Bloom<List<Bloom<String>>>>());

        final terminal = RawBloomTerminal(group, onInvalidated: () {});
        terminal.activate();

        expect(untracked(group).map((c) => untracked(c)).toList(), ['a', 'b']);
        terminal.deactivate();
      });
    });

    // =========================================================================
    // 5. Reactive Guards via Bloom.computed
    // =========================================================================
    group('5. Reactive Guards via Bloom.computed Comprehensive Matrix', () {
      test('5.1 Repeated controller mutations while isReady == false with terminal reading snapshot', () {
        final controller = BloomController<int>(0);
        final isReady = BloomController<bool>(false);

        final guarded = computed(
          (via) => via(controller.bloom),
          guard: (via) => (via(controller.bloom) >= 0 && via(isReady.bloom)).guarded(),
        );

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(guarded, onInvalidated: () {
          dirtyCount++;
        });
        terminal.activate();

        expect(terminal.snapshot.isEmpty, isTrue);
        expect(dirtyCount, 0);

        controller.set(10);
        expect(dirtyCount, 1);
        expect(terminal.snapshot.isEmpty, isTrue);

        controller.set(20);
        expect(dirtyCount, 2);
        expect(terminal.snapshot.isEmpty, isTrue);

        controller.set(30);
        expect(dirtyCount, 3);
        expect(terminal.snapshot.isEmpty, isTrue);

        isReady.set(true);
        controller.set(35);
        expect(dirtyCount, 4);
        expect(terminal.data, 35);

        controller.set(40);
        expect(dirtyCount, 5);
        expect(terminal.data, 40);

        terminal.deactivate();
      });

      test('5.2 Dynamic Flapping of isReady Guard Conditions (Blocked <-> Unblocked Cycles)', () {
        final controller = BloomController<int>(0);
        final isReady = BloomController<bool>(true);

        final guarded = computed(
          (via) => via(controller.bloom),
          guard: (via) => via(isReady.bloom).guarded(),
        );

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(guarded, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.data, 0);
        expect(dirtyCount, 0);

        // Cycle 1: Blocked
        isReady.set(false);
        expect(dirtyCount, 1);
        expect(terminal.snapshot.isEmpty, isTrue);

        // Cycle 2: Unblocked
        isReady.set(true);
        controller.set(200);
        expect(dirtyCount, 2);
        expect(terminal.data, 200);

        // Cycle 3: Re-Blocked
        isReady.set(false);
        expect(dirtyCount, 3);
        expect(terminal.snapshot.isEmpty, isTrue);

        // Cycle 4: Re-Unblocked
        isReady.set(true);
        controller.set(400);
        expect(dirtyCount, 4);
        expect(terminal.data, 400);

        terminal.deactivate();
      });

      test('5.3 Guard with dynamic reason function reflects latest error reason when blocked', () {
        final controller = BloomController<int>(10);
        final blockReason = BloomController<String?>('Error 401: Unauthorized');

        final guarded = computed(
          (via) => via(controller.bloom),
          guard: (via) {
            final reason = via(blockReason.bloom);
            if (reason != null) return BloomGuard.block(reason);
            return BloomGuard.pass;
          },
        );

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(guarded, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.snapshot.isEmpty, isTrue);
        expect(terminal.snapshot.emptyReason, 'Error 401: Unauthorized');
        expect(dirtyCount, 0);

        // Block with Reason B
        blockReason.set('Error 403: Forbidden');
        expect(dirtyCount, 1);
        expect(terminal.snapshot.isEmpty, isTrue);
        expect(terminal.snapshot.emptyReason, 'Error 403: Forbidden');

        // Unblock
        blockReason.set(null);
        expect(dirtyCount, 2);
        expect(terminal.data, 10);

        controller.set(40);
        expect(dirtyCount, 3);
        expect(terminal.data, 40);

        terminal.deactivate();
      });

      test('5.4 Guarded pipeline feeding downstream computed transformer', () {
        final controller = BloomController<int>(5);
        final isReady = BloomController<bool>(false);
        int mapExecCount = 0;

        final guarded = computed(
          (via) => via(controller.bloom),
          guard: (via) => via(isReady.bloom).guarded(),
        );
        final doubled = computed(
          (via) {
            mapExecCount++;
            return via(guarded) * 2;
          },
          guard: (via) => via(isReady.bloom).guarded(),
        );

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(doubled, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.snapshot.isEmpty, isTrue);
        expect(mapExecCount, 0);

        controller.set(10);
        expect(terminal.snapshot.isEmpty, isTrue);
        expect(mapExecCount, 0);

        isReady.set(true);
        controller.set(16);
        expect(terminal.data, 32);
        expect(mapExecCount, 1);

        terminal.deactivate();
      });

      test('5.5 Asymmetric Fan-Out: Single Controller with 3 Independent Guarded Branches', () {
        final controller = BloomController<int>(100);

        final permAdmin = BloomController<bool>(false);
        final permUser = BloomController<bool>(true);

        final rawBranch = controller;
        int rawDirty = 0;
        final rawTerminal = RawBloomTerminal(rawBranch.bloom, onInvalidated: () => rawDirty++);

        final adminBranch = computed(
          (via) => via(controller.bloom),
          guard: (via) => via(permAdmin.bloom).guarded(),
        );
        int adminDirty = 0;
        final adminTerminal = RawBloomTerminal(adminBranch, onInvalidated: () => adminDirty++);

        final userBranch = computed(
          (via) => via(controller.bloom),
          guard: (via) => via(permUser.bloom).guarded(),
        );
        int userDirty = 0;
        final userTerminal = RawBloomTerminal(userBranch, onInvalidated: () => userDirty++);

        rawTerminal.activate();
        adminTerminal.activate();
        userTerminal.activate();

        expect(rawTerminal.data, 100);
        expect(adminTerminal.snapshot.isEmpty, isTrue);
        expect(userTerminal.data, 100);

        controller.set(200);
        expect(rawDirty, 1);
        expect(userDirty, 1);

        expect(rawTerminal.data, 200);
        expect(adminTerminal.snapshot.isEmpty, isTrue);
        expect(userTerminal.data, 200);

        permAdmin.set(true);
        controller.set(300);
        expect(rawDirty, 2);
        expect(adminDirty, 1);
        expect(userDirty, 2);

        expect(rawTerminal.data, 300);
        expect(adminTerminal.data, 300);
        expect(userTerminal.data, 300);

        rawTerminal.deactivate();
        adminTerminal.deactivate();
        userTerminal.deactivate();
      });

      test('5.6 guard throwing an exception is cleanly caught and isolated into Error state', () {
        final controllerA = BloomController<int>(10);
        final controllerB = BloomController<int>(20);

        final computation = _TestBinaryComputation(
          controllerA.bloom,
          controllerB.bloom,
        );

        final throwInGuard = BloomController<bool>(true);
        final guardedBloom = computed(
          (via) => via(computation.bloom),
          guard: (via) {
            if (via(throwInGuard.bloom)) {
              throw const FormatException('Unexpected guard internal error');
            }
            return BloomGuard.pass;
          },
        );

        final terminal = RawBloomTerminal(guardedBloom, onInvalidated: () {});
        terminal.activate();

        expect(terminal.snapshot.hasError, isTrue);
        expect(terminal.snapshot.error, isA<FormatException>());

        throwInGuard.set(false);
        controllerA.set(15);

        expect(terminal.snapshot.hasData, isTrue);
        expect(terminal.data, 35); // 15 + 20

        terminal.deactivate();
      });
    });
  });
}

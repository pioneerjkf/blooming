// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

void main() {
  group('Reentrancy Resilience & Fault Containment Stress Suite', () {
    // =========================================================================
    // 1. Reentrancy Resilience in Comparators & Lifecycle Hooks
    // =========================================================================
    group('1. Reentrancy Resilience in Comparators & Lifecycle', () {
      test('1.1 Reentrant Controller Mutations inside Custom Equality (equals) Comparators', () {
        late final BloomController<int> ctrlA;
        late final BloomController<int> ctrlB;

        ctrlB = BloomController<int>(0);
        ctrlA = BloomController<int>(
          0,
          equals: (prev, next) {
            ctrlB.set(next * 10);
            return prev == next;
          },
        );

        final sumBloom = computed((via) => via(ctrlA.bloom) + via(ctrlB.bloom));

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(sumBloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.data, 0); // 0 + 0
        expect(dirtyCount, 0);

        ctrlA.set(5); // Mutation of A sets B to 50
        expect(terminal.data, 55); // 5 + 50
        expect(dirtyCount, 1);

        terminal.deactivate();
      });

      test('1.2 Reentrant Controller Mutations inside onActivated Lifecycle Callbacks', () {
        late final BloomController<int> ctrlSource;
        late final BloomController<int> ctrlSecondary;

        ctrlSecondary = BloomController<int>(100);
        ctrlSource = BloomController<int>(
          1,
          onActivated: () {
            ctrlSecondary.set(200);
          },
        );

        final pipeline = computed((via) => via(ctrlSource.bloom) * via(ctrlSecondary.bloom));

        final terminal = RawBloomTerminal(pipeline, onInvalidated: () {});
        expect(ctrlSecondary.data, 100);

        terminal.activate(); // Triggers onActivated on ctrlSource -> sets ctrlSecondary to 200

        expect(untracked(pipeline), 200); // 1 * 200

        terminal.deactivate();
      });

      test('1.3 Reentrant Terminal Evaluation & Reentrancy during Deactivation Grace Period', () {
        final ctrlA = BloomController<int>(
          10,
          graceful: const Graceful(),
          onDeactivated: () {},
        );
        final ctrlB = BloomController<int>(
          20,
          graceful: const Graceful(),
          onDeactivated: () {},
        );

        final terminalA = RawBloomTerminal(ctrlA.bloom, onInvalidated: () {});
        final terminalB = RawBloomTerminal(ctrlB.bloom, onInvalidated: () {});

        terminalA.activate();
        terminalB.activate();

        ctrlA.set(100);
        ctrlB.set(50);

        expect(terminalA.snapshot.hasData, isTrue);
        expect(terminalA.data, 100);
        expect(terminalB.snapshot.hasData, isTrue);
        expect(terminalB.data, 50);

        terminalA.deactivate();
        terminalB.deactivate();
      });

      test('1.4 Reentrant Mutation in onInvalidated is safely drained by Trampoline', () {
        final source = BloomController<int>(0);
        int invalidations = 0;

        late final RawBloomTerminal<int> terminal;
        terminal = RawBloomTerminal<int>(
          source.bloom,
          onInvalidated: () {
            invalidations++;
            if (terminal.data == 1) {
              source.set(999);
            }
          },
        );

        terminal.activate();
        source.set(1);

        expect(source.data, 999);
        expect(invalidations, 2);
        terminal.deactivate();
      });

      test('1.5 Self-referencing circular computed dependency handles without unhandled hang', () {
        late final Bloom<int> circular;
        circular = computed((via) {
          return via(circular) + 1;
        });

        final terminal = RawBloomTerminal(circular, onInvalidated: () {});
        terminal.activate();

        expect(
          () => terminal.data,
          throwsA(
            isA<BloomSnapshotExtractionException>().having(
              (e) => e.error,
              'error',
              isA<LpdagCycleError>(),
            ),
          ),
        );

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 2. Reactive Scope Isolation & Exception Containment
    // =========================================================================
    group('2. Reactive Scope Isolation & Exception Containment', () {
      test('2.1 Reactive scope isolation when computed function throws', () {
        final source = BloomController<int>(10);

        final faultyComputed = computed((via) {
          if (via(source.bloom) == 10) {
            throw FormatException('Intentional Failure');
          }
          return via(source.bloom) * 2;
        });

        final healthyComputed = computed((via) {
          return via(source.bloom) + 5;
        });

        final termFaulty = RawBloomTerminal(faultyComputed, onInvalidated: () {});
        final termHealthy = RawBloomTerminal(healthyComputed, onInvalidated: () {});
        termFaulty.activate();
        termHealthy.activate();

        expect(termFaulty.snapshot.hasError, isTrue);
        expect(termFaulty.snapshot.error, isA<FormatException>());

        expect(termHealthy.snapshot.hasData, isTrue);
        expect(termHealthy.data, 15);

        source.set(20);
        expect(termFaulty.snapshot.hasData, isTrue);
        expect(termFaulty.data, 40);
        expect(termHealthy.data, 25);

        termFaulty.deactivate();
        termHealthy.deactivate();
      });

      test('2.2 Nested Reactive Scope Execution with Inner Failure Containment', () {
        final outerController = BloomController<int>(1);
        final innerController = BloomController<int>(2);

        final innerFailing = computed<int>((via) {
          via(innerController.bloom);
          throw StateError('Simulated Failure inside Scope');
        });

        int innerErrors = 0;
        final outer = computed<int>((via) {
          via(outerController.bloom);
          try {
            via(innerFailing);
          } catch (_) {
            innerErrors++;
          }
          return via(outerController.bloom) * 10;
        });

        final terminal = RawBloomTerminal(outer, onInvalidated: () {});
        terminal.activate();

        expect(terminal.data, 10);
        expect(innerErrors, 1);

        outerController.set(5);
        expect(terminal.data, 50);
        expect(innerErrors, 2);

        terminal.deactivate();
      });
    });
  });
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';
import 'package:test/test.dart';

void main() {
  group('terminal.dart Constructors & Public API Comprehensive Tests', () {
    group('RawBloomTerminal Constructors & Inbound/Intent Properties', () {
      test('1.1 Source reference holds the underlying Bloom node', () {
        final source = Bloom.constant('test_value');
        final terminal = RawBloomTerminal(source, onInvalidated: () {});

        expect(terminal.source, same(source));
      });

      test('1.2 Generic type preservation', () {
        final source = Bloom.constant(123);
        final terminal = RawBloomTerminal(source, onInvalidated: () {});

        terminal.activate();

        expect(terminal.snapshot, isA<BloomSnapshot<int>>());
        expect(terminal.hasData, isTrue);
        expect(terminal.isEmpty, isFalse);
        expect(terminal.hasError, isFalse);
        expect(terminal.data, 123);
        expect(terminal.dataOrNull, 123);
        expect(terminal.dataOrElse(() => 999), 123);

        terminal.deactivate();
      });
    });

    group('Bloom<List> with RawBloomTerminal & Inbound/Intent Properties', () {
      test('Bloom<List> RawBloomTerminal sets default and matches inbound', () {
        final listBloom = Bloom.constant([Bloom.constant('a'), Bloom.constant('b')]);
        final terminal = RawBloomTerminal(listBloom, onInvalidated: () {});

        expect(terminal.source, same(listBloom));
      });

      test('Bloom<List> terminal delegates snapshot properties directly', () {
        final listBloom = Bloom.constant([Bloom.constant(10), Bloom.constant(20)]);
        final terminal = RawBloomTerminal(listBloom, onInvalidated: () {});

        terminal.activate();

        expect(terminal.snapshot, isA<BloomSnapshot<List<Bloom<int>>>>());
        expect(terminal.hasData, isTrue);
        expect(terminal.isEmpty, isFalse);
        expect(terminal.hasError, isFalse);
        expect(terminal.data.map((c) => untracked(c)).toList(), [10, 20]);
        expect(terminal.dataOrNull?.map((c) => untracked(c)).toList(), [10, 20]);
        expect(terminal.dataOrElse(() => const []).map((c) => untracked(c)).toList(), [10, 20]);

        terminal.deactivate();
      });
    });

    group('Terminal Lifecycle Methods & Status Getters (activate, deactivate)', () {
      test('Complete lifecycle state machine and idempotency checks', () {
        final controller = BloomController<int>(1);
        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () {});

        // Initial state before activation
        expect(terminal.isActive, isFalse);
        expect(terminal.isActive, isFalse);

        // 1. Activate
        terminal.activate();
        expect(terminal.isActive, isTrue);
        expect(terminal.isActive, isTrue);

        // Idempotent activate()
        terminal.activate();
        expect(terminal.isActive, isTrue);

        // 2. Deactivate
        terminal.deactivate();
        expect(terminal.isActive, isFalse);
        expect(terminal.isActive, isFalse);

        // Idempotent deactivate()
        terminal.deactivate();
        expect(terminal.isActive, isFalse);
      });
    });

    group('Zero Spurious Invalidation & Clean Initial Lifecycle Tests', () {
      test('RawBloomTerminal: instantiation and initial activation never fire spurious invalidations', () {
        final controller = BloomController<int>(10);
        var invalidateCount = 0;
        final terminal = RawBloomTerminal<int>(controller.bloom, onInvalidated: () => invalidateCount++);

        // Inactive state on creation
        expect(invalidateCount, 0);
        expect(terminal.isActive, isFalse);

        // Activation should establish subscriptions without firing invalidations
        terminal.activate();
        expect(invalidateCount, 0);
        expect(terminal.isActive, isTrue);
        expect(terminal.data, 10);

        // Only genuine subsequent mutations should invalidate
        controller.set(20);
        expect(invalidateCount, 1);
        expect(terminal.data, 20);

        terminal.deactivate();
      });

      test('RawBloomTerminal: synchronizes pulledVersion AFTER lazy computed source resolves state', () {
        var computedCount = 0;
        final trigger = BloomController<int>(1);
        final lazySource = computed((via) {
          computedCount++;
          return via(trigger.bloom) * 10;
        });

        var invalidateCount = 0;
        final terminal = RawBloomTerminal(lazySource, onInvalidated: () => invalidateCount++);

        terminal.activate();
        expect(computedCount, 0);
        expect(invalidateCount, 0);

        // First read: lazySource computes for the first time, advancing its version to 1.
        // terminal._read() MUST synchronize _pulledVersion AFTER source resolves,
        // so that terminal's pulledVersion becomes 1.
        expect(terminal.data, 10);
        expect(computedCount, 1);
        expect(invalidateCount, 0);

        // Subsequence reads without upstream change must not trigger any side-effects
        expect(terminal.data, 10);
        expect(computedCount, 1);

        // Mutating trigger pushes dirty invalidation to terminal
        trigger.data = 2;
        expect(invalidateCount, 1);
        expect(terminal.data, 20);
        expect(computedCount, 2);

        terminal.deactivate();
      });

      test('RawBloomTerminal on BloomListController: instantiation and activation never fire spurious invalidations',
          () {
        final c1 = BloomController<int>(1);
        final c2 = BloomController<int>(2);
        final group = blooming.list([c1.bloom, c2.bloom]);

        var invalidateCount = 0;
        final terminal = RawBloomTerminal(group.bloom, onInvalidated: () => invalidateCount++);

        expect(invalidateCount, 0);
        terminal.activate();
        expect(invalidateCount, 0);
        expect(terminal.data.length, 2);

        group.set([c1.bloom]);
        expect(invalidateCount, 1);

        terminal.deactivate();
      });

      test('BloomListController & downstream pipeline: construction does not fire spurious invalidations', () {
        final c1 = BloomController<int>(10);
        final c2 = BloomController<int>(20);
        final groupCtrl = blooming.list([c1.bloom, c2.bloom]);

        // Downstream aggregation
        final sumBloom = computed((via) => via(groupCtrl.bloom).fold<int>(0, (int sum, item) => sum + via(item)));

        var invalidateCount = 0;
        final terminal = RawBloomTerminal(sumBloom, onInvalidated: () => invalidateCount++);

        // Activation must not trigger an immediate flush
        terminal.activate();
        expect(invalidateCount, 0);
        expect(terminal.data, 30);

        // Mutation triggers exactly 1 invalidation
        c1.set(15);
        expect(invalidateCount, 1);
        expect(terminal.data, 35);

        // BloomListController dynamic swap triggers exactly 1 invalidation
        final c3 = BloomController<int>(100);
        groupCtrl.set([c1.bloom, c2.bloom, c3.bloom]);
        expect(invalidateCount, 2);
        expect(terminal.data, 135);

        terminal.deactivate();
      });

      test('BloomController mutated while inactive: subsequent terminal attachment has zero spurious invalidations',
          () {
        final c = BloomController<int>(1);
        c.set(2); // mutated while inactive

        var invalidateCount = 0;
        final terminal = RawBloomTerminal(c.bloom, onInvalidated: () => invalidateCount++);

        terminal.activate();
        expect(invalidateCount, 0);
        expect(terminal.data, 2);

        c.set(3);
        expect(invalidateCount, 1);
        expect(terminal.data, 3);

        terminal.deactivate();
      });

      test('Cascading dynamic branching: activation does not fire spurious invalidations', () {
        final triggerCtrl = BloomController<String>('alpha');
        final c1 = BloomController<int>(100);
        final c2 = BloomController<int>(200);

        // 1. Dynamic branching computed node
        final branch = computed((via) {
          return via(triggerCtrl.bloom) == 'alpha' ? [c1] : [c2];
        });

        var invalidateCount = 0;
        final terminal = RawBloomTerminal(branch, onInvalidated: () => invalidateCount++);

        // Activation must NOT trigger invalidation
        terminal.activate();
        expect(invalidateCount, 0);
        expect(terminal.data.length, 1);
        expect(terminal.data.first.data, 100);

        // Trigger mutation triggers exactly 1 invalidation
        triggerCtrl.set('beta');
        expect(invalidateCount, 1);
        expect(terminal.data.first.data, 200);

        terminal.deactivate();
      });

      test('All terminals support clean reconnection with zero spurious invalidations', () {
        // 1. RawBloomTerminal with mutated source while inactive
        final ctrl = BloomController<int>(1);
        var invalidateCount = 0;
        final term = RawBloomTerminal<int>(ctrl.bloom, onInvalidated: () => invalidateCount++);
        term.activate();
        term.deactivate();

        // Mutate source while terminal is deactivated
        ctrl.set(2);
        expect(invalidateCount, 0);

        // Re-activating drops the reconnect invalidation (2-Phase Lazy-Pull)
        term.activate();
        expect(invalidateCount, 0);
        expect(term.data, 2);

        // Subsequent mutations fire normally
        ctrl.set(3);
        expect(invalidateCount, 1);
        expect(term.data, 3);
        term.deactivate();

        // 2. RawViaTerminal clean reconnection
        var viaTermInvalidateCount = 0;
        final viaTerm =
            RawViaTerminal<int>((via) => via(ctrl.bloom) + 10, onInvalidated: () => viaTermInvalidateCount++);
        viaTerm.evaluate(); // registers ctrl.bloom
        viaTerm.activate();
        viaTerm.deactivate();

        ctrl.set(6);
        viaTerm.activate();
        expect(viaTermInvalidateCount, 0);
        expect(viaTerm.evaluate(), 16);

        ctrl.set(7);
        expect(viaTermInvalidateCount, 1);
        viaTerm.deactivate();

        // 3. RawComputedTerminal clean reconnection
        var computedTermInvalidateCount = 0;
        final computedTerm = RawComputedTerminal<int>(
          (via) => via(ctrl.bloom) + 100,
          onInvalidated: () => computedTermInvalidateCount++,
        );
        expect(computedTerm.data, 107);
        computedTerm.activate();
        computedTerm.deactivate();

        ctrl.set(8);
        computedTerm.activate();
        expect(computedTermInvalidateCount, 0);
        expect(computedTerm.data, 108);

        ctrl.set(9);
        expect(computedTermInvalidateCount, 1);
        computedTerm.deactivate();
      });
    });

    group('RawTerminal.debugForceInvalidate Tests', () {
      test('debugForceInvalidate invalidates intermediate Relay caches and forces recomputation', () {
        final ctrl = BloomController<int>(5);
        var multiplier = 2;

        // intermediate computed bloom capturing `multiplier`
        final mapped = computed((via) => via(ctrl.bloom) * multiplier);
        final terminal = RawBloomTerminal(mapped, onInvalidated: () {});
        terminal.activate();

        // 1. Initial computation
        expect(terminal.data, 10);

        // 2. Simulate hot reload changing the closure behavior without changing controller data
        multiplier = 10;
        // Without debugForceInvalidate, cached _state in `mapped` still returns 10
        expect(terminal.data, 10);

        // 3. Call debugForceInvalidate()
        terminal.debugForceInvalidate();

        // 4. Next read must pull fresh recomputed value (5 * 10 = 50)
        expect(terminal.data, 50);

        terminal.deactivate();
      });

      test('debugForceInvalidate walks multi-level DAG with diamond dependencies correctly', () {
        final root = BloomController<int>(2);
        var addend = 1;

        final branchA = computed((via) => via(root.bloom) + addend);
        final branchB = computed((via) => via(root.bloom) * addend);
        final combined = computed((via) => via(branchA) + via(branchB));

        final terminal = RawBloomTerminal(combined, onInvalidated: () {});
        terminal.activate();

        // Initial: (2 + 1) + (2 * 1) = 3 + 2 = 5
        expect(terminal.data, 5);

        // Simulate code patch: addend changed
        addend = 5;
        expect(terminal.data, 5); // Still cached

        terminal.debugForceInvalidate();

        // After force invalidate: (2 + 5) + (2 * 5) = 7 + 10 = 17
        expect(terminal.data, 17);

        terminal.deactivate();
      });

      test('debugForceInvalidate works with RawViaTerminal and dynamic dependencies', () {
        final ctrlA = BloomController<int>(10);
        final ctrlB = BloomController<int>(20);
        var useCtrlB = false;

        final terminal = RawViaTerminal<int>(
          (via) => useCtrlB ? via(ctrlB.bloom) : via(ctrlA.bloom),
          onInvalidated: () {},
        );
        terminal.activate();

        expect(terminal.evaluate(), 10);

        // Simulate hot reload logic change
        useCtrlB = true;
        terminal.debugForceInvalidate();

        expect(terminal.evaluate(), 20);

        terminal.deactivate();
      });

      test('debugForceInvalidate propagates to scope-bound effect', () {
        final ctrl = BloomController<int>(10);
        var factor = 2;
        final mapped = computed((via) => via(ctrl.bloom) * factor);

        final effect = Effect([mapped], () {});

        final parentTerminal = RawViaTerminal<void>(
          (via) {
            via.tether(effect);
          },
          onInvalidated: () {},
        );
        parentTerminal.activate();
        parentTerminal.evaluate();

        expect(untracked(mapped), 20);

        // Simulate hot reload logic change
        factor = 3;
        expect(untracked(mapped), 20); // Still cached before debugForceInvalidate

        // Force invalidate from parent terminal
        parentTerminal.debugForceInvalidate();

        // Cached state in mapped is invalidated through effect lifecycle anchor!
        expect(untracked(mapped), 30);

        parentTerminal.deactivate();
      });
    });

    group('Terminal onUncaughtError Custom Handler & Zone Fallback Tests', () {
      test('onUncaughtError catches exceptions thrown inside onInvalidated callback', () {
        final ctrl = BloomController<int>(1);
        Object? caughtError;
        StackTrace? caughtStackTrace;

        final terminal = RawBloomTerminal(ctrl.bloom, onInvalidated: () {
          throw StateError('Invalidation failed intentionally');
        }, onUncaughtError: (error, stackTrace) {
          caughtError = error;
          caughtStackTrace = stackTrace;
        });
        terminal.activate();

        // Mutate controller to trigger onInvalidated -> throws -> caught by onUncaughtError
        ctrl.set(2);

        expect(caughtError, isA<StateError>());
        expect((caughtError as StateError).message, 'Invalidation failed intentionally');
        expect(caughtStackTrace, isNotNull);

        terminal.deactivate();
      });

      test('onUncaughtError in RawBloomTerminal', () {
        final ctrl = BloomController<int>(1);
        final caughtList = <String>[];

        final bloomTerminal = RawBloomTerminal(
          ctrl.bloom,
          onInvalidated: () => throw StateError('RawBloomTerminal invalidation error'),
          onUncaughtError: (e, s) => caughtList.add('blooming:${(e as StateError).message}'),
        )..activate();

        ctrl.set(2);

        expect(caughtList, contains('blooming:RawBloomTerminal invalidation error'));
        bloomTerminal.deactivate();
      });

      test('onUncaughtError in RawViaTerminal', () {
        final ctrl = BloomController<int>(10);
        final caughtList = <String>[];

        final viaTerminal = RawViaTerminal(
          (via) => via(ctrl.bloom),
          onInvalidated: () => throw StateError('RawViaTerminal invalidation error'),
          onUncaughtError: (e, s) => caughtList.add('via:${(e as StateError).message}'),
        )..activate();
        viaTerminal.evaluate();

        // Trigger invalidations
        ctrl.set(20);

        expect(caughtList, contains('via:RawViaTerminal invalidation error'));

        viaTerminal.deactivate();
      });

      test('onUncaughtError in RawComputedTerminal', () {
        final ctrl = BloomController<int>(10);
        final caughtList = <String>[];

        final computedTerminal = RawComputedTerminal<int>(
          (via) => via(ctrl.bloom) * 2,
          onInvalidated: () => throw StateError('RawComputedTerminal invalidation error'),
          onUncaughtError: (e, s) => caughtList.add('computed:${(e as StateError).message}'),
        )..activate();
        expect(computedTerminal.data, 20);

        // Trigger invalidations
        ctrl.set(20);

        expect(caughtList, contains('computed:RawComputedTerminal invalidation error'));

        computedTerminal.deactivate();
      });

      test('When onUncaughtError throws, both original error and handler error fallback to Zone', () {
        final ctrl = BloomController<int>(1);
        final zoneErrors = <Object>[];

        runZonedGuarded(() {
          final terminal = RawBloomTerminal(
            ctrl.bloom,
            onInvalidated: () => throw StateError('Original Invalidation Error'),
            onUncaughtError: (error, stackTrace) {
              throw StateError('Secondary Handler Failure');
            },
          );
          terminal.activate();

          ctrl.set(2);
          terminal.deactivate();
        }, (error, stackTrace) {
          zoneErrors.add(error);
        });

        expect(zoneErrors.length, 2);
        expect(zoneErrors[0].toString(), contains('Original Invalidation Error'));
        expect(zoneErrors[1].toString(), contains('Secondary Handler Failure'));
      });
    });

    group('Zero-Copy Synchronous Gateway & Direct Source Access (P1)', () {
      test('Direct source read does NOT permanently mute subsequent invalidations', () {
        final source = BloomController(1);
        int invalidationCount = 0;
        final terminal = RawBloomTerminal(source.bloom, onInvalidated: () => invalidationCount++);
        terminal.activate();

        expect(terminal.data, 1);
        expect(invalidationCount, 0);

        // First mutation
        source.data = 2;
        expect(invalidationCount, 1);

        // Direct read of source.hasData / source.data bypassing terminal.data
        expect(source.hasData, isTrue);
        expect(source.data, 2);

        // Second mutation: MUST NOT be muted despite terminal.data not being pulled directly
        source.data = 3;
        expect(invalidationCount, 2, reason: 'Terminal invalidation must not be muted by direct source access');
        expect(terminal.data, 3);

        terminal.deactivate();
      });

      test('Bursty mutations coalesce into single notification within bloom.batch', () {
        final source = BloomController(0, distinct: false);
        int invalidationCount = 0;
        final terminal = RawBloomTerminal(source.bloom, onInvalidated: () => invalidationCount++);
        terminal.activate();

        // Rapid burst within batch transaction
        batch(() {
          for (int i = 1; i <= 10; i++) {
            source.data = i;
          }
        });
        expect(invalidationCount, 1, reason: 'Bursty mutations within batch transaction coalesced to 1');

        // Next mutation outside batch fires again
        source.data = 99;
        expect(invalidationCount, 2, reason: 'Subsequent mutation outside batch notifies cleanly');
        expect(terminal.data, 99);

        terminal.deactivate();
      });
    });

    // =========================================================================
    // RawComputedTerminal (1-Hop Leaf Computed Node with BloomStateMixin)
    // =========================================================================
    group('RawComputedTerminal Comprehensive Tests', () {
      test('data & snapshot reads lazily resolve value without evaluate() method', () {
        final ctrlA = BloomController<int>(10);
        final ctrlB = BloomController<int>(20);
        int computeCount = 0;
        int invalidations = 0;

        final terminal = RawComputedTerminal<int>(
          (via) {
            computeCount++;
            return via(ctrlA.bloom) + via(ctrlB.bloom);
          },
          onInvalidated: () => invalidations++,
        )..activate();

        // 1. Initial state before any read
        expect(computeCount, 0);

        // 2. First read resolves on-demand
        expect(terminal.data, 30);
        expect(computeCount, 1);
        expect(terminal.snapshot.data, 30);
        expect(terminal.hasData, isTrue);

        // 3. Uninvalidated reads return cached result (0-Compute)
        expect(terminal.data, 30);
        expect(terminal.data, 30);
        expect(terminal.snapshot.data, 30);
        expect(computeCount, 1, reason: 'Zero-compute caching when clean');

        // 4. Source update triggers 1-hop push-dirty directly to terminal
        ctrlA.data = 15;
        expect(invalidations, 1);
        expect(computeCount, 1, reason: 'Push-dirty phase does NOT compute');

        // 5. Subsequent read lazily pulls updated value
        expect(terminal.data, 35);
        expect(computeCount, 2);

        // 6. Again clean: returns cached
        expect(terminal.data, 35);
        expect(computeCount, 2);

        terminal.deactivate();
      });

      test('dynamic dependency switching & epoch sweep', () {
        final cond = BloomController<bool>(true);
        final a = BloomController<int>(1);
        final b = BloomController<int>(100);

        final terminal = RawComputedTerminal<int>(
          (via) => via(cond.bloom) ? via(a.bloom) : via(b.bloom),
          onInvalidated: () {},
        )..activate();

        expect(terminal.data, 1);
        expect(a.bloom.debug.targetCount, 1);
        expect(b.bloom.debug.targetCount, 0);

        // Switch branch
        cond.data = false;
        expect(terminal.data, 100);
        expect(a.bloom.debug.targetCount, 0, reason: 'Swept inactive edge');
        expect(b.bloom.debug.targetCount, 1);

        terminal.deactivate();
      });

      test('guard and reason support', () {
        final count = BloomController<int>(0);
        final terminal = RawComputedTerminal<int>(
          (via) => via(count.bloom) * 2,
          guard: (via) => (via(count.bloom) > 0).guarded('Count must be positive'),
          onInvalidated: () {},
        )..activate();

        expect(terminal.isEmpty, isTrue);
        expect(terminal.emptyReason, 'Count must be positive');
        expect(terminal.hasData, isFalse);

        count.data = 5;
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 10);

        terminal.deactivate();
      });

      test('error containment and exception propagation', () {
        final trigger = BloomController<bool>(false);
        final terminal = RawComputedTerminal<int>(
          (via) {
            if (via(trigger.bloom)) {
              throw FormatException('Malformed state');
            }
            return 42;
          },
          onInvalidated: () {},
        )..activate();

        expect(terminal.data, 42);
        expect(terminal.hasError, isFalse);

        trigger.data = true;
        expect(terminal.hasError, isTrue);
        expect(terminal.error, isA<FormatException>());
        expect(() => terminal.data, throwsA(isA<BloomSnapshotExtractionException>()));
        expect(terminal.snapshot.hasError, isTrue);

        terminal.deactivate();
      });

      test('markDirty forces re-resolution on next read', () {
        int computeCount = 0;
        final terminal = RawComputedTerminal<int>(
          (via) => ++computeCount,
          onInvalidated: () {},
        )..activate();

        expect(terminal.data, 1);
        expect(terminal.data, 1);

        terminal.markDirty();
        expect(terminal.data, 2);

        terminal.markDirty();
        expect(terminal.data, 3);

        terminal.deactivate();
      });
    });

    // =========================================================================

    group('RawViaTerminal Dynamic Invariants & 1-Pass Epoch Sweep', () {
      test('dynamic branching and 1-pass epoch sweep detach inactive branch edges', () {
        final condition = BloomController<bool>(true);
        final branchA = BloomController<String>('A');
        final branchB = BloomController<String>('B');
        int invalidationCount = 0;

        final terminal = RawViaTerminal<String>(
          (via) => via(condition.bloom) ? via(branchA.bloom) : via(branchB.bloom),
          onInvalidated: () {
            invalidationCount++;
          },
        )..activate();

        expect(terminal.evaluate(), 'A');
        expect(branchA.bloom.debug.targetCount, 1);
        expect(branchB.bloom.debug.targetCount, 0);

        // Switch to branchB
        condition.data = false;
        expect(invalidationCount, 1);
        expect(terminal.evaluate(), 'B');

        // branchA must be swept and detached; branchB attached
        expect(branchA.bloom.debug.targetCount, 0);
        expect(branchB.bloom.debug.targetCount, 1);

        // Mutating detached branchA produces 0 invalidations
        branchA.data = 'A_modified';
        expect(invalidationCount, 1); // unchanged!

        // Mutating active branchB triggers invalidation
        branchB.data = 'B_modified';
        expect(invalidationCount, 2);
        expect(terminal.evaluate(), 'B_modified');

        terminal.deactivate();
      });

      test('LpdagCycleError is thrown and cycle guard resets on cyclic evaluation', () {
        late final RawViaTerminal<int> terminal;
        terminal = RawViaTerminal<int>(
          (via) => terminal.evaluate(),
          onInvalidated: () {},
        );

        expect(() => terminal.evaluate(), throwsA(isA<LpdagCycleError>()));
      });
    });
  });
}

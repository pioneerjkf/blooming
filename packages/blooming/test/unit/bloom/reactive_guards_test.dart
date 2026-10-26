// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.
import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

void main() {
  group('Reactive Guards Triad (resource, computed, switched) & Empty(emptyReason) Suite', () {
    // =========================================================================
    // 1. Bloom.resource Guard & Lifecycle Invariants
    // =========================================================================
    group('1. Bloom.resource with guard & reason', () {
      test('1.1 guard == false prevents create() and holds Empty(emptyReason)', () {
        final token = blooming.late<String>();
        int createCount = 0;
        int disposeCount = 0;

        final clientRes = managed<String>(
          guard: (via) => via.state(token.bloom).hasData.guarded('AwaitingAuthToken'),
          create: (via) {
            createCount++;
            return 'Client(${via(token.bloom)})';
          },
          dispose: (_) => disposeCount++,
        );

        final terminal = RawBloomTerminal(clientRes, onInvalidated: () {});
        terminal.activate();

        // 1. Initial State: token is late (empty), so guard is false
        expect(terminal.isEmpty, isTrue);
        expect(terminal.hasData, isFalse);
        expect(terminal.snapshot.emptyReason, 'AwaitingAuthToken');
        expect(createCount, 0);
        expect(disposeCount, 0);

        // 2. Reading snapshot multiple times does not trigger create or recompute
        expect(terminal.snapshot.emptyReason, 'AwaitingAuthToken');
        expect(createCount, 0);

        // 3. Mutate token to valid data: guard becomes true
        token.set('jwt-secret-123');
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'Client(jwt-secret-123)');
        expect(terminal.snapshot.emptyReason, isNull);
        expect(createCount, 1);
        expect(disposeCount, 0);

        // 4. Mutate token to another value
        token.set('jwt-secret-456');
        expect(terminal.data, 'Client(jwt-secret-456)');
        expect(createCount, 2);
        expect(disposeCount, 1);

        // 5. Deactivate
        terminal.deactivate();
        expect(disposeCount, 2);
      });

      test('1.2 Dynamic condition toggling: Valid -> Empty(emptyReason) triggers dispose()', () {
        final isOnline = blooming(true);
        int createCount = 0;
        final disposedList = <String>[];

        final socketRes = managed<String>(
          guard: (via) => via(isOnline.bloom).guarded('NetworkOffline'),
          create: (via) {
            createCount++;
            return 'SocketConnection-$createCount';
          },
          dispose: (s) => disposedList.add(s),
        );

        final terminal = RawBloomTerminal(socketRes, onInvalidated: () {});
        terminal.activate();

        // Initial online
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'SocketConnection-1');
        expect(createCount, 1);
        expect(disposedList, isEmpty);

        // Go offline: under 2-Phase LPDAG, dirty push is non-destructive;
        // reading terminal pulls new state: guard is false, so resource is cleanly disposed!
        isOnline.data = false;
        expect(terminal.isEmpty, isTrue);
        expect(terminal.snapshot.emptyReason, 'NetworkOffline');
        expect(disposedList, ['SocketConnection-1']);

        // Go online again: guard is true, resource is reallocated!
        isOnline.data = true;
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'SocketConnection-2');
        expect(createCount, 2);

        terminal.deactivate();
        expect(disposedList, ['SocketConnection-1', 'SocketConnection-2']);
      });

      test('1.3 update callback with guard & reason', () {
        final server = blooming('alpha');
        final enabled = blooming(true);
        int createCount = 0;
        int updateCount = 0;
        final disposed = <String>[];

        final poolRes = managed<String>(
          guard: (via) => via(enabled.bloom).guarded('PoolDisabled'),
          create: (via) {
            createCount++;
            return 'Pool(${via(server.bloom)})';
          },
          update: (via, curr) {
            updateCount++;
            return 'Pool(${via(server.bloom)})';
          },
          dispose: (p) => disposed.add(p),
        );

        final terminal = RawBloomTerminal(poolRes, onInvalidated: () {});
        terminal.activate();

        expect(terminal.data, 'Pool(alpha)');
        expect(createCount, 1);
        expect(updateCount, 0);

        // Mutate server with enabled == true: update is called.
        // Since 'Pool(beta)' != 'Pool(alpha)', old instance is disposed!
        server.data = 'beta';
        expect(terminal.data, 'Pool(beta)');
        expect(createCount, 1);
        expect(updateCount, 1);
        expect(disposed, ['Pool(alpha)']);

        // Disable: goes into emptyReason, dispose is called on current instance
        enabled.data = false;
        expect(terminal.isEmpty, isTrue);
        expect(terminal.snapshot.emptyReason, 'PoolDisabled');
        expect(disposed, ['Pool(alpha)', 'Pool(beta)']);

        terminal.deactivate();
      });

      test('1.4 dispose() callback is strictly Untracked (preventing zombie edges and loops)', () {
        final trigger = blooming(1);
        final counter = blooming(100);
        int disposeCount = 0;

        final res = managed<int>(
          create: (via) => via(trigger.bloom) * 10,
          dispose: (val) {
            disposeCount++;
            // Read or mutate another bloom inside dispose
            final _ = counter.data;
            counter.data = counter.data + 1;
          },
        );

        final terminal = RawBloomTerminal(res, onInvalidated: () {});
        terminal.activate();

        expect(terminal.data, 10);
        expect(disposeCount, 0);
        expect(counter.data, 100);

        // Mutating trigger marks dirty; pull triggers recreation and calls dispose()
        trigger.data = 2;
        expect(terminal.data, 20);
        expect(disposeCount, 1);
        expect(counter.data, 101);

        // Mutating counter should NOT dirty or trigger res, because dispose was untracked!
        counter.data = 200;
        // terminal should not be marked dirty because of counter
        expect(terminal.data, 20);
        expect(disposeCount, 1); // No redundant disposal

        terminal.deactivate();
        expect(disposeCount, 2);
      });

      test('1.5 Unified Class Architecture: Bloom.managed creates _LazyManagedBloom or _LazyGracefulManagedBloom', () {
        final pure = managed<int>(create: (_) => 42, dispose: (_) {});
        final guarded = managed<int>(create: (_) => 42, dispose: (_) {}, guard: (_) => BloomGuard.pass);
        final pureGraceful = managed<int>(create: (_) => 42, dispose: (_) {}, graceful: const Graceful());
        final guardedGraceful =
            managed<int>(create: (_) => 42, dispose: (_) {}, guard: (_) => BloomGuard.pass, graceful: const Graceful());

        // Standard managed nodes are unified under _LazyManagedBloom
        expect(pure.runtimeType.toString(), contains('_LazyManagedBloom'));
        expect(guarded.runtimeType.toString(), contains('_LazyManagedBloom'));

        // Graceful managed nodes are unified under _LazyGracefulManagedBloom
        expect(pureGraceful.runtimeType.toString(), contains('_LazyGracefulManagedBloom'));
        expect(guardedGraceful.runtimeType.toString(), contains('_LazyGracefulManagedBloom'));
      });

      test('1.6 Error handling during guard, create, and update', () {
        final shouldThrow = blooming(false);
        final disposed = <String>[];

        final errorRes = managed<String>(
          guard: (via) {
            if (via(shouldThrow.bloom)) throw StateError('GuardEvaluationFailed');
            return BloomGuard.pass;
          },
          create: (_) => 'ActiveResource',
          dispose: (r) => disposed.add(r),
        );

        final terminal = RawBloomTerminal(errorRes, onInvalidated: () {});
        terminal.activate();

        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'ActiveResource');
        expect(disposed, isEmpty);

        // Trigger error in guard: previously active resource is cleanly disposed!
        shouldThrow.data = true;
        expect(terminal.hasError, isTrue);
        expect(terminal.error, isA<StateError>());
        expect((terminal.error as StateError).message, 'GuardEvaluationFailed');
        expect(disposed, ['ActiveResource']);

        terminal.deactivate();
      });

      test('1.7 Graceful resource deactivation with guard', () async {
        final online = blooming(true);
        int disposeCount = 0;

        final res = managed<String>(
          guard: (via) => via(online.bloom).guarded('Offline'),
          create: (_) => 'GracefulClient',
          dispose: (_) => disposeCount++,
          graceful: const Graceful(),
        );

        final terminal = RawBloomTerminal(res, onInvalidated: () {});
        terminal.activate();

        expect(terminal.data, 'GracefulClient');
        expect(disposeCount, 0);

        // Deactivate terminal (graceful disposal scheduled on microtask)
        terminal.deactivate();
        expect(disposeCount, 0); // Not disposed synchronously

        // Reactivate before microtask fires: resource preserved!
        terminal.activate();
        expect(terminal.data, 'GracefulClient');
        expect(disposeCount, 0);

        // Deactivate and let microtask expire
        terminal.deactivate();
        await Future.delayed(Duration.zero);
        expect(disposeCount, 1);
      });
    });

    // =========================================================================
    // 2. Bloom.computed Guard & Zero-Cost Specialization
    // =========================================================================
    group('2. Bloom.computed with guard & reason', () {
      test('2.1 guard controls pure computation and suspends with emptyReason', () {
        final ready = blooming(false);
        final count = blooming(10);
        int computeCallCount = 0;

        final calc = computed(
          (via) {
            computeCallCount++;
            return via(count.bloom) * 2;
          },
          guard: (via) => via(ready.bloom).guarded('NotReadyYet'),
        );

        final terminal = RawBloomTerminal(calc, onInvalidated: () {});
        terminal.activate();

        // Initially blocked
        expect(terminal.isEmpty, isTrue);
        expect(terminal.snapshot.emptyReason, 'NotReadyYet');
        expect(computeCallCount, 0);

        // Mutating count while blocked does NOT trigger compute
        count.data = 20;
        expect(terminal.isEmpty, isTrue);
        expect(terminal.snapshot.emptyReason, 'NotReadyYet');
        expect(computeCallCount, 0);

        // Set ready = true -> triggers compute
        ready.data = true;
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 40);
        expect(computeCallCount, 1);

        // Mutating count now recomputes
        count.data = 25;
        expect(terminal.data, 50);
        expect(computeCallCount, 2);

        // Toggle ready back to false -> returns to Empty(emptyReason)
        ready.data = false;
        expect(terminal.isEmpty, isTrue);
        expect(terminal.snapshot.emptyReason, 'NotReadyYet');

        terminal.deactivate();
      });

      test('2.2 Unified Class Architecture: Bloom.computed creates _ComputedBloom', () {
        final pure = computed((via) => 42);
        final guarded = computed((via) => 42, guard: (via) => BloomGuard.pass);

        // Both pure and guarded computed nodes are unified under _ComputedBloom
        expect(pure.runtimeType.toString(), contains('_ComputedBloom'));
        expect(guarded.runtimeType.toString(), contains('_ComputedBloom'));

        final num = blooming(42);
        final pureComputed = computed((via) => via(num.bloom) + 1);
        expect(untracked(pureComputed), 43);
        num.data = 100;
        expect(untracked(pureComputed), 101);
      });

      test('2.3 top-level computed() forwarding', () {
        final ready = blooming(false);
        final name = blooming('Bloom');

        final comp = computed(
          (via) => 'Hello, ${via(name.bloom)}',
          guard: (via) => via(ready.bloom).guarded('WaitingReady'),
        );

        expect(untracked.state(comp).isEmpty, isTrue);
        expect(untracked.state(comp).snapshot.emptyReason, 'WaitingReady');

        ready.data = true;
        expect(untracked.state(comp).hasData, isTrue);
        expect(untracked(comp), 'Hello, Bloom');
      });

      test('2.4 Exception in guard transitions computed into error state', () {
        final shouldFail = blooming(false);
        final comp = computed(
          (via) => 100,
          guard: (via) {
            if (via(shouldFail.bloom)) throw FormatException('GuardCheckFailed');
            return BloomGuard.pass;
          },
        );

        final terminal = RawBloomTerminal(comp, onInvalidated: () {});
        terminal.activate();

        expect(terminal.data, 100);

        shouldFail.data = true;
        expect(terminal.hasError, isTrue);
        expect(terminal.error, isA<FormatException>());
        expect((terminal.error as FormatException).message, 'GuardCheckFailed');

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 3. Bloom.switched with guard & reason
    // =========================================================================
    group('3. Bloom.switched with guard & reason', () {
      test('3.1 guard controls dynamic switching with emptyReason', () {
        final loggedIn = blooming(false);
        final mode = blooming('light');
        final lightTheme = blooming('Theme-Light');
        final darkTheme = blooming('Theme-Dark');
        int switchCallCount = 0;

        final currentTheme = switched(
          (via) {
            switchCallCount++;
            return via(mode.bloom) == 'dark' ? darkTheme.bloom : lightTheme.bloom;
          },
          guard: (via) => via(loggedIn.bloom).guarded('UserLoggedOut'),
        );

        final terminal = RawBloomTerminal(currentTheme, onInvalidated: () {});
        terminal.activate();

        // 1. Logged out: blocked
        expect(terminal.isEmpty, isTrue);
        expect(terminal.snapshot.emptyReason, 'UserLoggedOut');
        expect(switchCallCount, 0);

        // 2. Log in: executes switched
        loggedIn.data = true;
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'Theme-Light');
        expect(switchCallCount, 1);

        // 3. Switch mode: dynamic delegate updates
        mode.data = 'dark';
        expect(terminal.data, 'Theme-Dark');
        expect(switchCallCount, 2);

        // 4. Log out: returns to Empty(emptyReason)
        loggedIn.data = false;
        expect(terminal.isEmpty, isTrue);
        expect(terminal.snapshot.emptyReason, 'UserLoggedOut');

        terminal.deactivate();
      });

      test('3.2 Eager switched respects guard and reason', () {
        final ready = blooming(false);
        final branchA = blooming('BranchA');

        final eagerSwitched = switched(
          (_) => branchA.bloom,
          guard: (via) => via(ready.bloom).guarded('EagerNotReady'),
          eager: true,
        );

        final terminal = RawBloomTerminal(eagerSwitched, onInvalidated: () {});
        terminal.activate();

        expect(terminal.isEmpty, isTrue);
        expect(terminal.snapshot.emptyReason, 'EagerNotReady');

        ready.data = true;
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'BranchA');

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 4. Bloom.guard with reason
    // =========================================================================
    group('4. Bloom.computed with guard and reason', () {
      test('4.1 guard with reason returns Empty(emptyReason) when blocked', () {
        final controller = blooming<int>(10);
        final isAllowed = blooming<bool>(true);

        final guarded = computed(
          (via) => via(controller.bloom),
          guard: (via) => via(isAllowed.bloom).guarded('InsufficientPermissions'),
        );

        final terminal = RawBloomTerminal(guarded, onInvalidated: () {});
        terminal.activate();

        expect(terminal.hasData, isTrue);
        expect(terminal.data, 10);

        isAllowed.set(false);
        controller.set(20);

        expect(terminal.isEmpty, isTrue);
        expect(terminal.snapshot.emptyReason, 'InsufficientPermissions');

        isAllowed.set(true);
        controller.set(30);

        expect(terminal.hasData, isTrue);
        expect(terminal.data, 30);

        terminal.deactivate();
      });

      test('4.2 distinct() suppresses consecutive identical emptyReason', () {
        final reason = blooming('ReasonA');

        final comp = computed(
          (via) => 42,
          guard: (via) {
            final r = via(reason.bloom);
            return BloomGuard.block(r);
          },
        );
        final distinct = comp.distinct();

        int invalidationCount = 0;
        final terminal = RawBloomTerminal(distinct, onInvalidated: () => invalidationCount++);
        terminal.activate();

        expect(terminal.isEmpty, isTrue);
        expect(terminal.snapshot.emptyReason, 'ReasonA');
        expect(invalidationCount, 0);

        // Mutate reason to different string: invalidation fired!
        reason.data = 'ReasonB';
        expect(invalidationCount, 1);
        expect(terminal.snapshot.emptyReason, 'ReasonB');

        // Mutate reason to identical string: distinct suppresses invalidation!
        reason.data = 'ReasonB';
        expect(invalidationCount, 1);

        terminal.deactivate();
      });

      test('4.3 computed forwards emptyReason and dataOrElse recovers empty state', () {
        final guarded = Bloom<int>.empty('GuardedEmpty');

        // computed with guard forwards empty state and emptyReason without executing mapper
        int computeCount = 0;
        final mapped = computed(
          (via) {
            computeCount++;
            return via(guarded) * 10;
          },
          guard: (via) =>
              via.state(guarded).hasData.guarded(untracked.state(guarded).emptyReason ?? 'PrerequisiteNotMet'),
        );
        expect(untracked.state(mapped).isEmpty, isTrue);
        expect(untracked.state(mapped).snapshot.emptyReason, 'GuardedEmpty');
        expect(computeCount, 0);

        // dataOrElse intercepts empty and recovers with valid value
        final recovered = computed((via) => via.state(guarded).dataOrElse(() => 999));
        expect(untracked.state(recovered).hasData, isTrue);
        expect(untracked(recovered), 999);
      });
    });

    // =========================================================================
    // 5. Dart 3 Pattern Matching & BloomSnapshot Symmetry
    // =========================================================================
    group('5. Dart 3 Pattern Matching on BloomSnapshot & BloomState', () {
      test('5.1 Pattern matching on emptyReason in Dart 3 switch expressions', () {
        String classify(BloomSnapshot<String> s) => switch (s) {
              BloomSnapshot(phase: BloomPhase.valid, :final data) => 'Data: $data',
              BloomSnapshot(phase: BloomPhase.empty, emptyReason: 'WaitingAuth') => 'AuthRequired',
              BloomSnapshot(phase: BloomPhase.empty, :final emptyReason) => 'Empty: $emptyReason',
              BloomSnapshot(phase: BloomPhase.error, :final error) => 'Error: $error',
            };

        expect(classify(const BloomSnapshot('Hello')), 'Data: Hello');
        expect(classify(const BloomSnapshot.empty('WaitingAuth')), 'AuthRequired');
        expect(classify(const BloomSnapshot.empty('CustomReason')), 'Empty: CustomReason');
        expect(classify(const BloomSnapshot.empty()), 'Empty: null');
        expect(classify(const BloomSnapshot.error('Boom')), 'Error: Boom');
      });

      test('5.2 Snapshot equality reflects emptyReason', () {
        const snap1 = BloomSnapshot<int>.empty('ReasonA');
        const snap2 = BloomSnapshot<int>.empty('ReasonA');
        const snap3 = BloomSnapshot<int>.empty('ReasonB');
        const snapEmpty = BloomSnapshot<int>.empty();

        expect(snap1, equals(snap2));
        expect(snap1 == snap3, isFalse);
        expect(snap1 == snapEmpty, isFalse);
      });

      test('5.3 Bloom.empty([emptyReason]) static leaf node carries emptyReason', () {
        final leaf = Bloom<String>.empty('StaticReason');
        expect(untracked.state(leaf).isEmpty, isTrue);
        expect(untracked.state(leaf).snapshot.emptyReason, 'StaticReason');
      });

      test('5.4 Direct .emptyReason getter access across Bloom hierarchy', () {
        final leaf = Bloom.empty('LeafReason');
        expect(untracked.state(leaf).emptyReason, 'LeafReason');

        final writeableLate = blooming.late<int>();
        expect(writeableLate.emptyReason, isNull);

        final guarded = computed(
          (via) => via(writeableLate.bloom),
          guard: (via) => BloomGuard.block('GuardReason'),
        );
        expect(untracked.state(guarded).emptyReason, 'GuardReason');

        final bloomView = writeableLate.bloom;
        expect(untracked.state(bloomView).emptyReason, isNull);
        expect(() => (bloomView as dynamic) as BloomController, throwsA(isA<TypeError>()));
      });

      test('5.5 BloomController and RawBloomController support optional reason on .late and .empty()', () {
        final ctrl = blooming.late<String>(reason: 'AwaitingLogin');
        expect(ctrl.isEmpty, isTrue);
        expect(ctrl.emptyReason, 'AwaitingLogin');
        expect(untracked.state(ctrl.bloom).emptyReason, 'AwaitingLogin');

        ctrl.set('Alice');
        expect(ctrl.hasData, isTrue);
        expect(ctrl.emptyReason, isNull);

        ctrl.empty('UserLoggedOut');
        expect(ctrl.isEmpty, isTrue);
        expect(ctrl.emptyReason, 'UserLoggedOut');
        expect(untracked.state(ctrl.bloom).emptyReason, 'UserLoggedOut');

        // Test RawBloomController as well
        final rawCtrl = blooming.raw.late<int>(reason: 'RawPending');
        expect(rawCtrl.isEmpty, isTrue);
        expect(rawCtrl.emptyReason, 'RawPending');
        expect(untracked.state(rawCtrl.bloom).emptyReason, 'RawPending');

        rawCtrl.set(42);
        expect(rawCtrl.hasData, isTrue);
        expect(rawCtrl.emptyReason, isNull);

        rawCtrl.empty('RawReset');
        expect(rawCtrl.isEmpty, isTrue);
        expect(rawCtrl.emptyReason, 'RawReset');
        expect(untracked.state(rawCtrl.bloom).emptyReason, 'RawReset');
      });

      test('5.6 BloomGuard.block supports const factory construction and prerequisiteNotMet', () {
        expect(BloomGuard.prerequisiteNotMet, 'PrerequisiteNotMet');

        const defaultBlock = BloomGuard.block();
        expect(defaultBlock.isBlock, isTrue);
        expect(defaultBlock.isPass, isFalse);
        expect(defaultBlock.reason, BloomGuard.prerequisiteNotMet);

        const customBlock = BloomGuard.block('CustomPrecondition');
        expect(customBlock.isBlock, isTrue);
        expect(customBlock.reason, 'CustomPrecondition');

        expect(identical(defaultBlock, const BloomGuard.block()), isTrue);
        expect(identical(customBlock, const BloomGuard.block('CustomPrecondition')), isTrue);
      });
    });
  });
}

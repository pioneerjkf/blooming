// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  group('ComputedFunctor (computed.future, computed.stream, computed.async)', () {
    test('1.1 computed.future completes and transitions state', () async {
      final completer = Completer<String>();
      final greeting = computed.future((_) => completer.future);

      expect(untracked.state(greeting).isEmpty, isTrue);
      expect(untracked.state(greeting).hasData, isFalse);

      String? observed;
      final dispose = effect((via) {
        if (via.state(greeting).hasData) {
          observed = via(greeting);
        }
      });

      expect(observed, isNull);

      completer.complete('Hello, World!');
      await Future<void>.delayed(Duration.zero);

      expect(untracked.state(greeting).hasData, isTrue);
      expect(untracked(greeting), 'Hello, World!');
      expect(observed, 'Hello, World!');

      dispose();
    });

    test('1.2 computed.async alias behaves identically to computed.future', () async {
      final completer = Completer<int>();
      final count = computed.async((_) => completer.future);

      expect(untracked.state(count).isEmpty, isTrue);

      int? observed;
      final dispose = effect((via) {
        if (via.state(count).hasData) {
          observed = via(count);
        }
      });

      completer.complete(999);
      await Future<void>.delayed(Duration.zero);

      expect(untracked.state(count).hasData, isTrue);
      expect(untracked(count), 999);
      expect(observed, 999);

      dispose();
    });

    test('1.3 computed.future supports initialFactory', () async {
      final completer = Completer<String>();
      final withInitialFactory = computed.future(
        (_) => completer.future,
        initialFactory: () => 'FactoryValue',
      );

      expect(untracked.state(withInitialFactory).hasData, isTrue);
      expect(untracked(withInitialFactory), 'FactoryValue');

      String? observedFactory;
      final dispose = effect((via) {
        observedFactory = via(withInitialFactory);
      });

      await Future<void>.delayed(Duration.zero);
      expect(observedFactory, 'FactoryValue');

      completer.complete('UpdatedValue');
      await Future<void>.delayed(Duration.zero);

      expect(untracked(withInitialFactory), 'UpdatedValue');
      expect(observedFactory, 'UpdatedValue');

      dispose();
    });

    test('2.1 computed.future automatically tracks upstream synchronous dependencies', () async {
      final userId = blooming(1);
      var fetchCount = 0;

      final userProfile = computed.future((via) async {
        fetchCount++;
        final id = via(userId.bloom);
        return 'User-$id';
      });

      String? currentProfile;
      final dispose = effect((via) {
        if (via.state(userProfile).hasData) {
          currentProfile = via(userProfile);
        }
      });

      await Future<void>.delayed(Duration.zero);
      expect(fetchCount, 1);
      expect(currentProfile, 'User-1');

      // Update upstream dependency
      userId.data = 2;
      await Future<void>.delayed(Duration.zero);

      expect(fetchCount, 2);
      expect(currentProfile, 'User-2');

      dispose();
    });

    test('3.1 Out-of-order race condition immunity (slow old request ignored after fast new request)', () async {
      final query = blooming('initial');
      final slowCompleter = Completer<String>();
      final fastCompleter = Completer<String>();

      final searchResult = computed.future((via) {
        final q = via(query.bloom);
        if (q == 'slow') {
          return slowCompleter.future;
        } else if (q == 'fast') {
          return fastCompleter.future;
        }
        return Future.value('Default');
      });

      String? observedResult;
      final dispose = effect((via) {
        if (via.state(searchResult).hasData) {
          observedResult = via(searchResult);
        }
      });

      await Future<void>.delayed(Duration.zero);
      expect(observedResult, 'Default');

      // Trigger slow request
      query.data = 'slow';
      await Future<void>.delayed(Duration.zero);

      // Trigger fast request while slow request is still pending
      query.data = 'fast';
      await Future<void>.delayed(Duration.zero);

      // Fast request resolves first
      fastCompleter.complete('FastResult');
      await Future<void>.delayed(Duration.zero);

      expect(observedResult, 'FastResult');
      expect(untracked(searchResult), 'FastResult');

      // Slow request resolves later - MUST be ignored due to LPDAG topology swap
      slowCompleter.complete('StaleSlowResult');
      await Future<void>.delayed(Duration.zero);

      expect(observedResult, 'FastResult');
      expect(untracked(searchResult), 'FastResult');

      dispose();
    });

    test('4.1 computed.future propagates errors to ErrorBloomState and supports onError fallback', () async {
      final shouldFail = blooming(false);

      final result = computed.future((via) async {
        if (via(shouldFail.bloom)) {
          throw FormatException('Malformed payload');
        }
        return 'Success';
      });

      Object? lastError;
      String? lastData;
      final dispose = effect((via) {
        if (via.state(result).hasError) {
          lastError = via.state(result).snapshot.error;
        } else if (via.state(result).hasData) {
          lastData = via(result);
        }
      });

      await Future<void>.delayed(Duration.zero);
      expect(lastData, 'Success');
      expect(untracked.state(result).hasError, isFalse);

      // Trigger failure
      shouldFail.data = true;
      await Future<void>.delayed(Duration.zero);

      expect(untracked.state(result).hasError, isTrue);
      expect(lastError, isA<FormatException>());

      dispose();

      // Test with onError fallback
      final fallbackResult = computed.future<String>(
        (_) async => throw StateError('Boom'),
        onError: (error, [st]) => 'Recovered',
      );

      String? fallbackObserved;
      final disposeFallback = effect((via) {
        if (via.state(fallbackResult).hasData) {
          fallbackObserved = via(fallbackResult);
        }
      });

      await Future<void>.delayed(Duration.zero);
      expect(untracked.state(fallbackResult).hasData, isTrue);
      expect(untracked(fallbackResult), 'Recovered');
      expect(fallbackObserved, 'Recovered');

      disposeFallback();
    });

    test('5.1 computed.future respects reactive guards (guard and reason)', () async {
      final isReady = blooming(false);
      var computeCalled = false;

      final guarded = computed.future(
        (_) async {
          computeCalled = true;
          return 42;
        },
        guard: (via) => via(isReady.bloom).guarded('AwaitingReadyState'),
      );

      int? observed;
      final dispose = effect((via) {
        if (via.state(guarded).hasData) {
          observed = via(guarded);
        }
      });

      expect(untracked.state(guarded).isEmpty, isTrue);
      expect(untracked.state(guarded).snapshot.emptyReason, 'AwaitingReadyState');
      expect(computeCalled, isFalse);
      expect(observed, isNull);

      // Enable guard
      isReady.data = true;
      await Future<void>.delayed(Duration.zero);

      expect(computeCalled, isTrue);
      expect(untracked.state(guarded).hasData, isTrue);
      expect(untracked(guarded), 42);
      expect(observed, 42);

      dispose();
    });

    test('6.1 computed.stream receives sequential events and auto-cancels old stream on dependency change', () async {
      final channel = blooming('A');
      final scA = StreamController<String>.broadcast();
      final scB = StreamController<String>.broadcast();

      final activeStream = computed.stream((via) {
        if (via(channel.bloom) == 'A') {
          return scA.stream;
        } else {
          return scB.stream;
        }
      });

      final received = <String>[];
      final dispose = effect((via) {
        if (via.state(activeStream).hasData) {
          received.add(via(activeStream));
        }
      });

      await Future<void>.delayed(Duration.zero);

      // Stream A events
      scA.add('A1');
      await Future<void>.delayed(Duration.zero);
      expect(received, ['A1']);

      scA.add('A2');
      await Future<void>.delayed(Duration.zero);
      expect(received, ['A1', 'A2']);

      // Switch to Channel B
      channel.data = 'B';
      await Future<void>.delayed(Duration.zero);

      // Emitting on old stream A must be completely ignored
      scA.add('A3-Orphan');
      await Future<void>.delayed(Duration.zero);
      expect(received, ['A1', 'A2']);

      // Emitting on new stream B
      scB.add('B1');
      await Future<void>.delayed(Duration.zero);
      expect(received, ['A1', 'A2', 'B1']);

      dispose();
      await scA.close();
      await scB.close();
    });

    test('6.2 computed.stream auto-cancels subscription when deactivated', () async {
      final controller = StreamController<int>();
      final streamNode = computed.stream((_) => controller.stream);

      expect(controller.hasListener, isFalse);

      final dispose = effect((via) {
        if (via.state(streamNode).hasData) {
          // observe
        }
      });

      await Future<void>.delayed(Duration.zero);
      // While active, stream is subscribed
      expect(controller.hasListener, isTrue);

      // When deactivated (dispose effect), subscription is automatically cancelled
      dispose();
      expect(controller.hasListener, isFalse);

      await controller.close();
    });

    test('7.1 Synchronous computed(...) preserves 100% backward compatibility and inlined speed', () {
      final a = blooming(10);
      final b = blooming(20);

      // Standard top-level computed
      final sum = computed((via) => via(a.bloom) + via(b.bloom));
      expect(untracked(sum), 30);

      a.data = 15;
      expect(untracked(sum), 35);

      // bloom.computed factory accessor
      final product = computed((via) => via(a.bloom) * via(b.bloom));
      expect(untracked(product), 300);

      b.data = 2;
      expect(untracked(product), 30);
    });

    // =========================================================================
    // 8. _DeLorean (Future Bridge) Error Recovery & Sync Failure Edge Cases
    // =========================================================================
    group('8. Future Bridge (_DeLorean) Error Recovery & Sync Failures', () {
      test('8.1 initialFactory exception initializes node into ErrorBloomState', () {
        final node = computed.future(
          (_) => Completer<String>().future,
          initialFactory: () => throw StateError('InitFactoryFailed'),
        );

        final terminal = RawBloomTerminal(node, onInvalidated: () {})..activate();
        expect(terminal.hasError, isTrue);
        expect(terminal.snapshot.error, isA<StateError>());
        terminal.deactivate();
      });

      test('8.2 Async onError callback throws exception falling back to setError', () async {
        final node = computed.future<String>(
          (_) => Future.error(StateError('OriginalAsyncError')),
          onError: (e, [s]) => throw FormatException('OnErrorFailed'),
        );

        final terminal = RawBloomTerminal(node, onInvalidated: () {})..activate();
        await Future<void>.delayed(Duration.zero);

        expect(terminal.hasError, isTrue);
        expect(terminal.snapshot.error, isA<FormatException>());
        terminal.deactivate();
      });

      test('8.3 Synchronous future.then failure bypasses onError and sets error directly', () {
        // Case A: Even when onError is provided, synchronous .then() contract failure sets error directly
        final withOnErrorNode = computed.future<String>(
          (_) => _SyncThrowingFuture<String>(),
          onError: (e, [s]) => 'SyncRecovered',
        );
        final tRec = RawBloomTerminal(withOnErrorNode, onInvalidated: () {})..activate();
        expect(tRec.hasError, isTrue);
        expect(tRec.snapshot.error, isA<StateError>());
        tRec.deactivate();

        // Case B: No onError provided
        final directFailNode = computed.future<String>(
          (_) => _SyncThrowingFuture<String>(),
        );
        final tDir = RawBloomTerminal(directFailNode, onInvalidated: () {})..activate();
        expect(tDir.hasError, isTrue);
        expect(tDir.snapshot.error, isA<StateError>());
        tDir.deactivate();
      });

      test('8.4 Future.toBloom() encapsulates error without unhandled exception while dormant', () async {
        final failingFuture = Future<String>.error(StateError('DormantAsyncFailure'));
        final bloom = failingFuture.toBloom();

        // Allow microtask to complete while bloom is dormant (no active subscribers)
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // When terminal activates later, error is safely encapsulated in BloomState.error
        final terminal = RawBloomTerminal(bloom, onInvalidated: () {})..activate();
        expect(terminal.hasError, isTrue);
        expect(terminal.snapshot.error, isA<StateError>());
        terminal.deactivate();
      });

      test('8.5 Future.toBloom() with onError recovers dormant error to data', () async {
        final failingFuture = Future<String>.error(StateError('RecoverableDormantFailure'));
        final bloom = failingFuture.toBloom(
          onError: (e, [s]) => 'RecoveredFromDormantError',
        );

        // Allow microtask to settle while dormant
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final terminal = RawBloomTerminal(bloom, onInvalidated: () {})..activate();
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'RecoveredFromDormantError');
        terminal.deactivate();
      });

      test('8.6 Future.toBloom() settles while dormant and provides instant data upon activation', () async {
        final fastFuture = Future<String>.value('DormantResolvedData');
        final bloom = fastFuture.toBloom();

        // Settle while dormant
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final terminal = RawBloomTerminal(bloom, onInvalidated: () {})..activate();
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'DormantResolvedData');
        terminal.deactivate();
      });
    });

    // =========================================================================
    // 9. _PragueVltava (Stream Bridge) Lifecycle, InitialFactory & Error Handling
    // =========================================================================
    group('9. Stream Bridge (_PragueVltava) Edge Cases', () {
      test('9.1 initialFactory provides synchronous initial value before stream events', () async {
        final sc = StreamController<String>();
        final streamNode = computed.stream(
          (_) => sc.stream,
          initialFactory: () => 'InitialStreamValue',
        );

        final terminal = RawBloomTerminal(streamNode, onInvalidated: () {})..activate();
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'InitialStreamValue');

        sc.add('FirstStreamEvent');
        await Future<void>.delayed(Duration.zero);
        expect(terminal.data, 'FirstStreamEvent');

        terminal.deactivate();
        await sc.close();
      });

      test('9.2 initialFactory exception initializes stream node into ErrorBloomState', () {
        final sc = StreamController<String>();
        final streamNode = computed.stream(
          (_) => sc.stream,
          initialFactory: () => throw StateError('StreamInitFailed'),
        );

        final terminal = RawBloomTerminal(streamNode, onInvalidated: () {})..activate();
        expect(terminal.hasError, isTrue);
        expect(terminal.snapshot.error, isA<StateError>());

        terminal.deactivate();
        sc.close();
      });

      test('9.3 Stream event error handling with recovery, secondary throw, or direct error', () async {
        // Case A: onError recovers error event to value
        final scA = StreamController<String>();
        final nodeA = computed.stream<String>(
          (_) => scA.stream,
          onError: (e, [s]) => 'RecoveredStreamError',
        );
        final tA = RawBloomTerminal(nodeA, onInvalidated: () {})..activate();
        scA.addError(StateError('OriginalStreamError'));
        await Future<void>.delayed(Duration.zero);
        expect(tA.hasData, isTrue);
        expect(tA.data, 'RecoveredStreamError');
        tA.deactivate();
        await scA.close();

        // Case B: onError throws secondary error
        final scB = StreamController<String>();
        final nodeB = computed.stream<String>(
          (_) => scB.stream,
          onError: (e, [s]) => throw FormatException('StreamOnErrorFailed'),
        );
        final tB = RawBloomTerminal(nodeB, onInvalidated: () {})..activate();
        scB.addError(StateError('Original'));
        await Future<void>.delayed(Duration.zero);
        expect(tB.hasError, isTrue);
        expect(tB.snapshot.error, isA<FormatException>());
        tB.deactivate();
        await scB.close();

        // Case C: No onError provided
        final scC = StreamController<String>();
        final nodeC = computed.stream<String>(
          (_) => scC.stream,
        );
        final tC = RawBloomTerminal(nodeC, onInvalidated: () {})..activate();
        scC.addError(StateError('StreamFatal'));
        await Future<void>.delayed(Duration.zero);
        expect(tC.hasError, isTrue);
        expect(tC.snapshot.error, isA<StateError>());
        tC.deactivate();
        await scC.close();
      });

      test('9.4 cancelOnError: true unsubscribes stream upon error', () async {
        final sc = StreamController<String>();
        final streamNode = computed.stream<String>(
          (_) => sc.stream,
          cancelOnError: true,
        );

        final terminal = RawBloomTerminal(streamNode, onInvalidated: () {})..activate();
        expect(sc.hasListener, isTrue);

        sc.addError(StateError('AbortError'));
        await Future<void>.delayed(Duration.zero);

        expect(terminal.hasError, isTrue);
        // Subscription is canceled
        expect(sc.hasListener, isFalse);

        terminal.deactivate();
        await sc.close();
      });

      test('9.5 Stream onDone closes subscription and marks done', () async {
        final sc = StreamController<String>();
        final streamNode = computed.stream<String>(
          (_) => sc.stream,
        );

        final terminal = RawBloomTerminal(streamNode, onInvalidated: () {})..activate();
        expect(sc.hasListener, isTrue);

        sc.add('PreClose');
        await Future<void>.delayed(Duration.zero);
        expect(terminal.data, 'PreClose');

        // Close stream -> triggers onDone
        await sc.close();
        await Future<void>.delayed(Duration.zero);
        expect(sc.hasListener, isFalse);

        // Deactivate and re-activate does not re-subscribe because _isDone is true
        terminal.deactivate();
        terminal.activate();
        expect(sc.hasListener, isFalse);
        terminal.deactivate();
      });

      test('9.6 Synchronous stream.listen failure bypasses onError and sets error directly', () {
        // Case A: Even when onError is provided, synchronous .listen() failure sets error directly
        final recNode = computed.stream<String>(
          (_) => _SyncThrowingStream<String>(),
          onError: (e, [s]) => 'StreamSyncRecovered',
        );
        final tRec = RawBloomTerminal(recNode, onInvalidated: () {})..activate();
        expect(tRec.hasError, isTrue);
        expect(tRec.snapshot.error, isA<StateError>());
        tRec.deactivate();

        // Case B: No onError
        final failNode = computed.stream<String>(
          (_) => _SyncThrowingStream<String>(),
        );
        final tFail = RawBloomTerminal(failNode, onInvalidated: () {})..activate();
        expect(tFail.hasError, isTrue);
        expect(tFail.snapshot.error, isA<StateError>());
        tFail.deactivate();
      });
    });

    // =========================================================================
    // 10. On-Demand Async BloomVia Isolation & Multi-Step Await / Yield Tracking
    // =========================================================================
    group('10. On-Demand Async BloomVia Isolation & Multi-Step Await / Yield Tracking', () {
      test(
          '10.1 Synchronous nodes reuse the exact same BloomVia instance (0 allocations) and ignore leaked async via calls',
          () async {
        final mainSource = blooming(10);
        final leakedSource = blooming(100);
        final observedVias = <BloomVia>[];
        var evalCount = 0;

        final syncNode = computed<int>((via) {
          evalCount++;
          observedVias.add(via);
          // Leaked async closure inside a synchronous computed callback
          Future<void>(() async {
            await Future<void>.delayed(Duration.zero);
            via(leakedSource.bloom);
          });
          return via(mainSource.bloom) * 2;
        });

        final terminal = RawBloomTerminal(syncNode, onInvalidated: () {})..activate();
        expect(terminal.data, 20);
        expect(evalCount, 1);

        // Wait for the leaked Future to execute `via(leakedSource.bloom)`
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        // Mutating leakedSource must NOT trigger re-evaluation of syncNode
        leakedSource.set(200);
        expect(terminal.data, 20);
        expect(evalCount, 1);

        // Mutating mainSource triggers Turn 2 and reuses the exact same `via` instance (identical)
        mainSource.set(15);
        expect(terminal.data, 30);
        expect(evalCount, 2);
        expect(identical(observedVias[0], observedVias[1]), isTrue);

        terminal.deactivate();
      });

      test(
          '10.2 computed.future((via) async) tracks sequential await dependencies and forwards Empty/Error without onError',
          () async {
        final step1 = blooming('A');
        final step2 = blooming.late<String>(reason: 'Step2Pending');
        final step3 = blooming('C');
        var onErrorCalled = false;

        final node = computed.future<String>(
          (via) async {
            final a = via(step1.bloom);
            await Future<void>.delayed(Duration.zero);
            final b = via(step2.bloom);
            await Future<void>.delayed(Duration.zero);
            final c = via(step3.bloom);
            return '$a:$b:$c';
          },
          onError: (e, [s]) {
            onErrorCalled = true;
            return 'ErrorFallback';
          },
        );

        final terminal = RawBloomTerminal(node, onInvalidated: () {})..activate();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        // 1. Short-circuited at step2 with Empty('Step2Pending') without calling onError
        expect(terminal.isEmpty, isTrue);
        expect(terminal.emptyReason, 'Step2Pending');
        expect(onErrorCalled, isFalse);

        // 2. step2 transitions to Error -> forwarded without calling onError
        step2.setError(StateError('Step2Failed'));
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(terminal.hasError, isTrue);
        expect(terminal.error, isA<StateError>());
        expect(onErrorCalled, isFalse);

        // 3. step2 transitions to Valid -> completes all 3 sequential await steps
        step2.set('B');
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'A:B:C');
        expect(onErrorCalled, isFalse);

        // 4. Mutating step3 (registered after the 2nd await) triggers re-evaluation
        step3.set('C2');
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(terminal.data, 'A:B:C2');

        terminal.deactivate();
      });

      test('10.3 Stale async turn waking up after newer turn starts ignores source edge registration', () async {
        final mode = blooming('A');
        final branchAOnly = blooming('a1');
        final branchBOnly = blooming('b1');
        final step1CompleterA = Completer<void>();

        var evalCount = 0;

        final node = computed.future<String>((via) async {
          evalCount++;
          final currentMode = via(mode.bloom);
          if (currentMode == 'A') {
            await step1CompleterA.future;
            // By the time step1CompleterA completes, mode has already switched to 'B' (Turn 2)!
            final _ = via.state(branchAOnly.bloom);
            final a = via(branchAOnly.bloom);
            return 'ModeA:$a';
          } else {
            await Future<void>.delayed(Duration.zero);
            final b = via(branchBOnly.bloom);
            return 'ModeB:$b';
          }
        });

        final terminal = RawBloomTerminal(node, onInvalidated: () {})..activate();
        await Future<void>.delayed(Duration.zero);
        expect(evalCount, 1);

        // Switch mode to 'B' while Turn 1 ('A') is suspended at step1CompleterA
        mode.set('B');
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(evalCount, 2);
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'ModeB:b1');

        // Now complete Turn 1's suspended await (out-of-order completion!)
        step1CompleterA.complete();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(terminal.data, 'ModeB:b1');

        // `branchAOnly` was NOT registered onto Turn 2 -> mutating it does NOT trigger re-evaluation!
        branchAOnly.set('a2');
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(evalCount, 2);

        // `branchBOnly` IS registered -> mutating it triggers Turn 3!
        branchBOnly.set('b2');
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(evalCount, 3);
        expect(terminal.data, 'ModeB:b2');

        terminal.deactivate();
      });

      test('10.4 computed.stream((via) async*) tracks dependencies across sequential yield and yield*', () async {
        final channel = blooming.late<String>(reason: 'NoChannel');
        final middle = blooming('m1');
        final suffix = blooming('v1');
        var onErrorCalled = false;

        final streamNode = computed.stream<String>(
          (via) async* {
            final ch = via(channel.bloom);
            yield 'init:$ch';
            final m = via(middle.bloom);
            yield* Stream<String>.fromIterable(['mid1:$ch:$m', 'mid2:$ch:$m']);
            final s = via(suffix.bloom);
            yield 'live:$ch:$m:$s';
          },
          cancelOnError: true,
          onError: (e, [s]) {
            onErrorCalled = true;
            return 'StreamFallback';
          },
        );

        final terminal = RawBloomTerminal(streamNode, onInvalidated: () {})..activate();
        await Future<void>.delayed(Duration.zero);

        // 1. Upstream is Empty('NoChannel') -> forwarded without calling onError
        expect(terminal.isEmpty, isTrue);
        expect(terminal.emptyReason, 'NoChannel');
        expect(onErrorCalled, isFalse);

        // 2. Upstream transitions to Valid -> yields through yield and yield* to final yield
        channel.set('general');
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'live:general:m1:v1');

        // 3. Post-yield* dependency `suffix` mutates -> triggers re-subscription
        suffix.set('v2');
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(terminal.data, 'live:general:m1:v2');

        terminal.deactivate();
      });

      test('10.5 Effect.via((via) async) tracks post-await dependencies on latest turn and ignores stale turns',
          () async {
        final mode = blooming('A');
        final branchA = blooming('a1');
        final branchB = blooming('b1');
        final completerA = Completer<void>();
        final log = <String>[];

        final dispose = effect((BloomVia via) async {
          final m = via(mode.bloom);
          if (m == 'A') {
            await completerA.future;
            final a = via(branchA.bloom);
            log.add('A:$a');
          } else {
            await Future<void>.delayed(Duration.zero);
            final b = via(branchB.bloom);
            log.add('B:$b');
          }
        });

        await Future<void>.delayed(Duration.zero);

        // Switch mode to 'B' while Turn 1 ('A') is still awaiting completerA
        mode.set('B');
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(log, ['B:b1']);

        // Now complete Turn 1's completerA -> branchA must NOT be registered as a dependency!
        completerA.complete();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        log.clear();
        branchA.set('a2');
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(log, isEmpty);

        // Mutating branchB (registered after await in Turn 2) triggers Turn 3!
        branchB.set('b2');
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(log, ['B:b2']);

        dispose();
      });

      test('10.6 Deactivating node during await isolates in-flight async via across dormant and reactivated states',
          () async {
        final trigger = blooming(1);
        final lateDep = blooming(100);
        final completer = Completer<void>();
        var evalCount = 0;

        final node = computed.future<int>((via) async {
          evalCount++;
          final t = via(trigger.bloom);
          if (t == 1) {
            await completer.future;
            return t + via(lateDep.bloom);
          }
          return t * 10;
        });

        final terminal = RawBloomTerminal(node, onInvalidated: () {})..activate();
        expect(terminal.isEmpty, isTrue);
        expect(evalCount, 1);

        // Deactivate while Turn 1 is suspended at `await completer.future`
        terminal.deactivate();

        // Complete Turn 1 while node is inactive -> `via(lateDep.bloom)` must be ignored!
        completer.complete();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        // Reactivate with trigger = 2
        trigger.set(2);
        terminal.activate();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(terminal.data, 20);
        expect(evalCount, 2);

        // Mutating lateDep must NOT trigger re-evaluation because Turn 1's post-deactivate via was isolated
        lateDep.set(200);
        await Future<void>.delayed(Duration.zero);
        expect(evalCount, 2);

        terminal.deactivate();
      });
    });

    group('11. Native FutureOr<T> Support in computed.future', () {
      test('11.1 Synchronous value returned from FutureOr resolves instantly in 0ms (zero microtask delay)', () {
        final node = computed.future<String>((via) => 'instant_cached_data');

        final terminal = RawBloomTerminal(node, onInvalidated: () {})..activate();

        // Must be immediately Valid without needing any `await Future.delayed`!
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'instant_cached_data');

        terminal.deactivate();
      });

      test('11.2 Dynamic switching between synchronous cache hit and asynchronous Future fallback', () async {
        final memoryCache = <String, String>{'user_1': 'Alice (Cached)'};
        final currentUserId = blooming('user_1');
        var completer = Completer<String>();

        final userNode = computed.future<String>((via) {
          final id = via(currentUserId.bloom);
          final cached = memoryCache[id];
          if (cached != null) {
            return cached; // 0ms instant sync return
          }
          return completer.future; // Async remote fetch
        });

        final terminal = RawBloomTerminal(userNode, onInvalidated: () {})..activate();

        // 1. Initial observation with cache hit: 0ms instant sync data!
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'Alice (Cached)');

        // 2. Switch to uncached user: transitions to pending (no data yet)
        completer = Completer<String>();
        currentUserId.set('user_2');
        expect(terminal.hasData, isFalse); // Pending async fetch

        // 3. Remote fetch completes: transitions to valid
        completer.complete('Bob (Remote)');
        await Future<void>.delayed(Duration.zero);
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'Bob (Remote)');

        // 4. Switch back to cached user: instant 0ms restoration without microtask latency!
        currentUserId.set('user_1');
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'Alice (Cached)');

        terminal.deactivate();
      });

      test('11.3 Guarded FutureOr node emits Empty immediately when guard blocks', () {
        final isAuthReady = blooming(false);

        final secretData = computed.future<String>(
          (via) => 'secret_payload',
          guard: (via) => via(isAuthReady.bloom).guarded('NotAuthenticated'),
        );

        final terminal = RawBloomTerminal(secretData, onInvalidated: () {})..activate();

        expect(terminal.isEmpty, isTrue);
        expect(terminal.emptyReason, 'NotAuthenticated');

        // Unblock guard -> immediately resolves synchronously!
        isAuthReady.set(true);
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'secret_payload');

        terminal.deactivate();
      });

      test('11.4 Untyped or dynamic Future correctly unwraps without being mistaken as synchronous payload', () async {
        final completer = Completer<dynamic>();
        final node = computed.future<dynamic>((via) => completer.future);

        final terminal = RawBloomTerminal(node, onInvalidated: () {})..activate();

        // Must be in pending state initially (not constant Future object)
        expect(terminal.hasData, isFalse);

        completer.complete('untyped_resolved');
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'untyped_resolved');

        terminal.deactivate();
      });
    });
  });
}

class _SyncThrowingFuture<T> implements Future<T> {
  @override
  Stream<T> asStream() => throw UnimplementedError();

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) => throw UnimplementedError();

  @override
  Future<S> then<S>(FutureOr<S> Function(T value) onValue, {Function? onError}) {
    throw StateError('SyncFutureThenFailed');
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) => throw UnimplementedError();

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) => throw UnimplementedError();
}

class _SyncThrowingStream<T> extends Stream<T> {
  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    throw StateError('SyncStreamListenFailed');
  }
}

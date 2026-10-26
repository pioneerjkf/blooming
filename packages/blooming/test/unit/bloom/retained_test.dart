// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  group('retained (Stale-While-Revalidate Functor & Coupler Integration) Suite', () {
    test('1.1 Basic SWR transition retains previous data and toggles pending via coupler', () async {
      final query = BloomController('apple');
      Completer<String>? activeCompleter;

      final rawFuture = computed.future((via) {
        via(query.bloom);
        final completer = Completer<String>();
        activeCompleter = completer;
        return completer.future;
      });

      final pendingCoupler = BloomCoupler<bool>.late();
      final smooth = rawFuture.retained(pending: pendingCoupler);
      final pending = pendingCoupler.bloom;

      // Initially empty before first resolution
      expect(untracked.state(smooth).isEmpty, isTrue);
      expect(untracked.state(smooth).hasData, isFalse);
      expect(untracked(pending), isFalse);

      final observedData = <String>[];
      final observedPending = <bool>[];

      final disposeData = effect((via) {
        if (via.state(smooth).hasData) observedData.add(via(smooth));
      });
      final disposePending = effect((via) {
        observedPending.add(via(pending));
      });

      await Future<void>.delayed(Duration.zero);

      // 1. Resolve first request ('apple')
      activeCompleter!.complete('AppleResults');
      await Future<void>.delayed(Duration.zero);

      expect(untracked.state(smooth).hasData, isTrue);
      expect(untracked(smooth), equals('AppleResults'));
      expect(untracked(pending), isFalse);
      expect(observedData, contains('AppleResults'));

      // 2. Change query to 'banana' -> starts background transition
      query.data = 'banana';
      await Future<void>.delayed(Duration.zero);

      // FLICKER-FREE: Previous data is retained!
      expect(untracked.state(smooth).hasData, isTrue);
      expect(untracked(smooth), equals('AppleResults'));
      expect(untracked(pending), isTrue);
      expect(observedPending.last, isTrue);

      // 3. Resolve 'banana' request
      activeCompleter!.complete('BananaResults');
      await Future<void>.delayed(Duration.zero);

      expect(untracked.state(smooth).hasData, isTrue);
      expect(untracked(smooth), equals('BananaResults'));
      expect(untracked(pending), isFalse);
      expect(observedData.last, equals('BananaResults'));

      disposeData();
      disposePending();
    });

    test('1.2 Chained .retained() creates working pure Bloom<T> with zero-alloc pending', () async {
      final query = BloomController('cat');
      Completer<String>? activeCompleter;

      final smooth = computed.future((via) {
        via(query.bloom);
        final c = Completer<String>();
        activeCompleter = c;
        return c.future;
      }).retained();

      final terminal = RawBloomTerminal(smooth, onInvalidated: () {});
      terminal.activate();

      activeCompleter!.complete('CatData');
      await Future<void>.delayed(Duration.zero);
      expect(untracked(smooth), equals('CatData'));

      // Mutate upstream
      query.data = 'dog';
      await Future<void>.delayed(Duration.zero);

      // Retains CatData while dog is in-flight without allocating secondary facet
      expect(untracked(smooth), equals('CatData'));

      activeCompleter!.complete('DogData');
      await Future<void>.delayed(Duration.zero);

      expect(untracked(smooth), equals('DogData'));

      terminal.deactivate();
    });

    test('2.1 Coupler surgical reactivity: pending facet pulses independently from data', () async {
      final id = BloomController(1);
      Completer<String>? activeCompleter;

      final pendingCoupler = BloomCoupler<bool>.late();
      final user = computed.future((via) {
        via(id.bloom);
        final c = Completer<String>();
        activeCompleter = c;
        return c.future;
      }).retained(pending: pendingCoupler);
      final pending = pendingCoupler.bloom;

      var dataPulseCount = 0;
      var pendingPulseCount = 0;
      var dataDownstreamRuns = 0;

      final downstream = computed((via) {
        dataDownstreamRuns++;
        return 'User: ${via(user)}';
      });

      final termDownstream = RawBloomTerminal(downstream, onInvalidated: () {});
      final termData = RawBloomTerminal(user, onInvalidated: () => dataPulseCount++);
      final termPending = RawBloomTerminal(pending, onInvalidated: () => pendingPulseCount++);
      termDownstream.activate();
      termData.activate();
      termPending.activate();

      // Initial load completes
      activeCompleter!.complete('User#1');
      await Future<void>.delayed(Duration.zero);
      expect(untracked(user), 'User#1');
      expect(untracked(pending), isFalse);
      expect(termDownstream.data, equals('User: User#1'));
      expect(dataDownstreamRuns, 1);

      final basePendingPulses = pendingPulseCount;
      final baseUserVersion = user.debug.snapshot().version;

      // Switch to ID 2 (in-flight)
      id.data = 2;
      await Future<void>.delayed(Duration.zero);

      // Pending facet MUST pulse dirty (false -> true)
      expect(pendingPulseCount, greaterThan(basePendingPulses));
      // In 2-Phase LPDAG, dirty propagates downstream during Push-Dirty phase to
      // preserve lazy-pull, but retained data preserves its version to drop redundant recomputation!
      expect(user.debug.snapshot().version, equals(baseUserVersion));
      expect(termDownstream.data, equals('User: User#1'));
      expect(
        dataDownstreamRuns,
        1,
        reason: 'Downstream computed must NOT re-evaluate while retaining stale data',
      );
      expect(untracked(pending), isTrue);

      // Data is still User#1
      expect(untracked(user), 'User#1');

      // Complete ID 2
      activeCompleter!.complete('User#2');
      await Future<void>.delayed(Duration.zero);

      expect(untracked(user), 'User#2');
      expect(untracked(pending), isFalse);
      expect(termDownstream.data, equals('User: User#2'));
      expect(dataDownstreamRuns, 2);

      termDownstream.deactivate();
      termData.deactivate();
      termPending.deactivate();
    });

    test('3.1 Zero-Zombie out-of-order race condition immunity', () async {
      final query = BloomController('initial');
      final slowCompleter = Completer<String>();
      final fastCompleter = Completer<String>();

      final pendingCoupler = BloomCoupler<bool>.late();
      final search = computed.future((via) {
        final q = via(query.bloom);
        if (q == 'slow') return slowCompleter.future;
        if (q == 'fast') return fastCompleter.future;
        return Future.value('InitialData');
      }).retained(pending: pendingCoupler);

      final terminal = RawBloomTerminal(search, onInvalidated: () {});
      terminal.activate();
      await Future<void>.delayed(Duration.zero);

      expect(untracked(search), equals('InitialData'));
      expect(untracked(pendingCoupler.bloom), isFalse);

      // Trigger slow
      query.data = 'slow';
      await Future<void>.delayed(Duration.zero);
      expect(untracked(search), equals('InitialData'));
      expect(untracked(pendingCoupler.bloom), isTrue);

      // Trigger fast while slow is still in-flight
      query.data = 'fast';
      await Future<void>.delayed(Duration.zero);
      expect(untracked(search), equals('InitialData'));
      expect(untracked(pendingCoupler.bloom), isTrue);

      // Fast completes first
      fastCompleter.complete('FastResult');
      await Future<void>.delayed(Duration.zero);

      expect(untracked(search), equals('FastResult'));
      expect(untracked(pendingCoupler.bloom), isFalse);

      // Slow completes later -> MUST be ignored due to LPDAG topology switch
      slowCompleter.complete('StaleSlowResult');
      await Future<void>.delayed(Duration.zero);

      expect(untracked(search), equals('FastResult'));
      expect(untracked(pendingCoupler.bloom), isFalse);

      terminal.deactivate();
    });

    test('4.1 Returning empty data (Future.value) smoothly transitions and settles pending', () async {
      final query = BloomController('search');
      final pendingCoupler = BloomCoupler<bool>.late();

      final search = computed.future((via) {
        final q = via(query.bloom);
        if (q.isEmpty) return Future.value(<String>[]);
        return Future.value(<String>['Result for $q']);
      }).retained(pending: pendingCoupler);

      final term = RawBloomTerminal(search, onInvalidated: () {});
      term.activate();
      await Future<void>.delayed(Duration.zero);

      expect(untracked.state(search).hasData, isTrue);
      expect(untracked(search), equals(['Result for search']));
      expect(untracked(pendingCoupler.bloom), isFalse);

      // Clear query
      query.data = '';
      await Future<void>.delayed(Duration.zero);

      // Smoothly transitions to empty list and pending is false
      expect(untracked.state(search).hasData, isTrue);
      expect(untracked(search), isEmpty);
      expect(untracked(pendingCoupler.bloom), isFalse);

      term.deactivate();
    });

    test('5.1 Errors immediately clear retained data, surface error state, and clear pending', () async {
      final trigger = BloomController(1);
      Completer<String>? completer;
      final pendingCoupler = BloomCoupler<bool>.late();

      final node = computed.future((via) {
        final t = via(trigger.bloom);
        if (t == 2) return Future.error(StateError('FetchFailed'));
        final c = Completer<String>();
        completer = c;
        return c.future;
      }).retained(pending: pendingCoupler);

      final term = RawBloomTerminal(node, onInvalidated: () {});
      term.activate();

      completer!.complete('Success1');
      await Future<void>.delayed(Duration.zero);
      expect(untracked(node), equals('Success1'));

      // Trigger error
      trigger.data = 2;
      await Future<void>.delayed(Duration.zero);

      // Clears retained data and honestly propagates error
      expect(untracked.state(node).hasData, isFalse);
      expect(untracked.state(node).hasError, isTrue);
      expect(untracked.state(node).error, isA<StateError>());
      expect(untracked(pendingCoupler.bloom), isFalse);

      term.deactivate();
    });

    test('6.1 Stream transition retains last stream value while new stream prepares', () async {
      final channel = BloomController('A');
      StreamController<String>? controller;
      final pendingCoupler = BloomCoupler<bool>.late();

      final streamNode = computed.stream((via) {
        via(channel.bloom);
        final c = StreamController<String>();
        controller = c;
        return c.stream;
      }).retained(pending: pendingCoupler);

      final term = RawBloomTerminal(streamNode, onInvalidated: () {});
      term.activate();

      // Emit first value on Channel A
      controller!.add('MsgA1');
      await Future<void>.delayed(Duration.zero);
      expect(untracked(streamNode), equals('MsgA1'));
      expect(untracked(pendingCoupler.bloom), isFalse);

      // Switch to Channel B (new stream hasn't emitted yet)
      channel.data = 'B';
      await Future<void>.delayed(Duration.zero);

      // Stale-While-Revalidate: MsgA1 retained!
      expect(untracked(streamNode), equals('MsgA1'));
      expect(untracked(pendingCoupler.bloom), isTrue);

      // Emit first value on Channel B
      controller!.add('MsgB1');
      await Future<void>.delayed(Duration.zero);

      expect(untracked(streamNode), equals('MsgB1'));
      expect(untracked(pendingCoupler.bloom), isFalse);

      term.deactivate();
    });

    test('7.1 Observing pending coupler alone activates upstream pipeline', () async {
      var isComputedActivated = false;
      final query = BloomController('start');

      final pendingCoupler = BloomCoupler<bool>.late();
      computed.future((via) async {
        isComputedActivated = true;
        return 'Computed:${via(query.bloom)}';
      }).retained(pending: pendingCoupler);

      expect(isComputedActivated, isFalse);

      // Attach only to pending coupler!
      final pendingTerminal = RawBloomTerminal(pendingCoupler.bloom, onInvalidated: () {});
      pendingTerminal.activate();

      await Future<void>.delayed(Duration.zero);

      // Upstream MUST have been activated!
      expect(isComputedActivated, isTrue);

      pendingTerminal.deactivate();
    });

    test('8.1 Chained .retained() and managed(...).retained() compatibility', () async {
      final count = BloomController(10);
      final raw = computed((via) => 'Count: ${via(count.bloom)}');
      final smooth = raw.retained();

      expect(untracked(smooth), equals('Count: 10'));

      // Managed retained
      var disposed = false;
      final managedNode = managed(
        create: (_) => 'ManagedResource',
        dispose: (res) => disposed = true,
      ).retained();

      final term = RawBloomTerminal(managedNode, onInvalidated: () {});
      term.activate();

      expect(untracked(managedNode), equals('ManagedResource'));

      term.deactivate();
      expect(disposed, isTrue);
    });

    test('9.1 Debug observability reflects retained properties', () async {
      final source = BloomController('val');
      final pendingCoupler = BloomCoupler<bool>.late();
      final smooth = source.bloom.retained(pending: pendingCoupler)..debugTrace('SmoothNode');

      final snapshot = smooth.debug.snapshot();
      expect(snapshot.name, equals('SmoothNode'));
      expect(snapshot.customProperties['isPending'], isFalse);
      expect(snapshot.customProperties['hasRetainedData'], isTrue);
    });

    // =========================================================================
    // 10. Distinct Invariant & Diamond Consistency on Pending Facet
    // =========================================================================
    test('10.1 Pending facet does NOT increment version when pending state remains unchanged', () async {
      final source = BloomController('Data1');
      final pendingCoupler = BloomCoupler<bool>.late();
      source.bloom.retained(pending: pendingCoupler);
      final pending = pendingCoupler.bloom;

      int pendingDownstreamRuns = 0;
      final pendingDownstream = computed((via) {
        pendingDownstreamRuns++;
        return 'Pending: ${via(pending)}';
      });

      final term = RawBloomTerminal(pendingDownstream, onInvalidated: () {});
      term.activate();

      expect(term.data, equals('Pending: false'));
      expect(pendingDownstreamRuns, 1);

      // Mutate source: Data1 -> Data2.
      // Normal synchronous mutation: smooth updates data, pending stays false (false -> false).
      source.data = 'Data2';

      // Pull term:
      expect(term.data, equals('Pending: false'));
      expect(
        pendingDownstreamRuns,
        1,
        reason: 'Pending facet must NOT trigger downstream re-computation if pending remained false',
      );

      term.deactivate();
    });

    test('10.2 Diamond graph observing both retained and pending facet resolves consistently', () async {
      final query = BloomController('A');
      Completer<String>? completer;

      final rawFuture = computed.future((via) {
        via(query.bloom);
        final c = Completer<String>();
        completer = c;
        return c.future;
      });

      final pendingCoupler = BloomCoupler<bool>.late();
      final smooth = rawFuture.retained(pending: pendingCoupler);
      final pending = pendingCoupler.bloom;

      int diamondRuns = 0;
      final diamond = computed((via) {
        diamondRuns++;
        final hasData = via.state(smooth).hasData;
        final d = hasData ? via(smooth) : 'NONE';
        final p = via(pending);
        return '$d|$p';
      });

      final term = RawBloomTerminal(diamond, onInvalidated: () {});
      term.activate();

      // Initial state: NONE|false
      expect(term.data, equals('NONE|false'));
      expect(diamondRuns, 1);

      // Complete initial load
      completer!.complete('ValueA');
      await Future<void>.delayed(Duration.zero);

      expect(term.data, equals('ValueA|false'));
      expect(diamondRuns, 2);

      // Trigger background mutation
      query.data = 'B';
      await Future<void>.delayed(Duration.zero);

      // SWR: ValueA retained, pending=true
      expect(term.data, equals('ValueA|true'));
      expect(diamondRuns, 3);

      // Complete background load
      completer!.complete('ValueB');
      await Future<void>.delayed(Duration.zero);

      // Completed: ValueB, pending=false
      expect(term.data, equals('ValueB|false'));
      expect(diamondRuns, 4);

      term.deactivate();
    });

    test('10.3 Pending facet pull suppresses version bump when current pending matches previous state', () {
      final source = BloomController('A');
      final pendingCoupler = BloomCoupler<bool>.late();
      source.bloom.retained(pending: pendingCoupler);
      final pending = pendingCoupler.bloom;

      // Initial read
      expect(untracked(pending), isFalse);
      final initialVersion = pending.debug.snapshot().version;

      // Force a pull cycle on pending facet directly
      untracked(pending);
      expect(
        pending.debug.snapshot().version,
        equals(initialVersion),
        reason: 'Repeated reads must not bump version',
      );
    });

    test('11.1 retainedTuple() returns ({data, pending}) named record and retains prior data without coupler',
        () async {
      final query = BloomController('alpha');
      Completer<String>? activeCompleter;

      final rawFuture = computed.future((via) {
        via(query.bloom);
        final completer = Completer<String>();
        activeCompleter = completer;
        return completer.future;
      });

      // Use retainedTuple directly (zero BloomCoupler allocation)
      final (:data, :pending) = rawFuture.retainedTuple();

      // Initially empty before first resolution
      expect(untracked.state(data).isEmpty, isTrue);
      expect(untracked(pending), isFalse);

      final tData = RawBloomTerminal(data, onInvalidated: () {});
      final tPending = RawBloomTerminal(pending, onInvalidated: () {});
      tData.activate();
      tPending.activate();

      // 1. Resolve first request ('alpha')
      activeCompleter!.complete('AlphaPayload');
      await Future<void>.delayed(Duration.zero);

      expect(tData.data, 'AlphaPayload');
      expect(tPending.data, isFalse);

      // 2. Query changes to 'beta' -> starts background fetch
      query.data = 'beta';
      await Future<void>.delayed(Duration.zero);

      // FLICKER-FREE: Prior data retained, pending is true
      expect(tData.data, 'AlphaPayload');
      expect(tPending.data, isTrue);

      // 3. Resolve 'beta' request
      activeCompleter!.complete('BetaPayload');
      await Future<void>.delayed(Duration.zero);

      expect(tData.data, 'BetaPayload');
      expect(tPending.data, isFalse);

      tData.deactivate();
      tPending.deactivate();
    });

    test('11.2 retainedTuple() handles deactivation and reactivation lifecycle', () {
      final source = BloomController('Original');
      final (data: dataBloom, pending: pendingBloom) = source.bloom.retainedTuple();

      expect(untracked(dataBloom), 'Original');
      expect(untracked(pendingBloom), isFalse);

      source.set('Updated');
      expect(untracked(dataBloom), 'Updated');
      expect(untracked(pendingBloom), isFalse);
    });
  });
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

void main() {
  group('Async Reactivity & Stream/Future Bridge Unit Tests', () {
    // =========================================================================
    // 1. Future.toBloom() Tests
    // =========================================================================
    group('1. Future.toBloom()', () {
      test('1.1 resolves with a value when Future completes successfully', () async {
        final completer = Completer<int>();
        final asyncBloom = completer.future.toBloom();

        expect(untracked.state(asyncBloom).snapshot.isEmpty, isTrue);

        final terminal = RawBloomTerminal(asyncBloom, onInvalidated: () {});
        terminal.activate();

        completer.complete(42);
        await Future<void>.delayed(Duration.zero);

        expect(terminal.snapshot.hasData, isTrue);
        expect(terminal.data, 42);

        terminal.deactivate();
      });

      test('1.2 resolves with an error when Future completes with an error', () async {
        final completer = Completer<int>();
        final asyncBloom = completer.future.toBloom();

        final terminal = RawBloomTerminal(asyncBloom, onInvalidated: () {});
        terminal.activate();

        final exception = Exception('Something went wrong');
        completer.completeError(exception);
        await Future<void>.delayed(Duration.zero);

        expect(terminal.snapshot.hasError, isTrue);
        expect(terminal.error, exception);

        terminal.deactivate();
      });

      test('1.3 prevents multiple subscriptions to the same Future', () async {
        final completer = Completer<int>();
        final asyncBloom = completer.future.toBloom();

        int onDirtyCount = 0;
        final terminal = RawBloomTerminal(asyncBloom, onInvalidated: () {
          onDirtyCount++;
        });

        terminal.activate();
        terminal.deactivate();
        terminal.activate();

        completer.complete(100);
        await Future<void>.delayed(Duration.zero);

        expect(terminal.data, 100);
        expect(onDirtyCount, 1);

        terminal.deactivate();
      });

      test('1.4 toBloomTuple returns ({data, pending}) named record and pending transitions to false on completion',
          () async {
        final completer = Completer<String>();
        final (data: dataBloom, pending: pendingBloom) = completer.future.toBloomTuple();

        expect(untracked(pendingBloom), isTrue);
        expect(untracked.state(dataBloom).isEmpty, isTrue);

        completer.complete('SuccessValue');
        await Future<void>.delayed(Duration.zero);

        expect(untracked(pendingBloom), isFalse);
        expect(untracked(dataBloom), 'SuccessValue');
      });

      test('1.5 toBloomTuple with initialFactory keeps pending true until future completes', () async {
        final completer = Completer<int>();
        final (data: dataBloom, pending: pendingBloom) = completer.future.toBloomTuple(
          initialFactory: () => 10,
        );

        expect(untracked(pendingBloom), isTrue);
        expect(untracked(dataBloom), 10);

        completer.complete(999);
        await Future<void>.delayed(Duration.zero);

        expect(untracked(pendingBloom), isFalse);
        expect(untracked(dataBloom), 999);
      });

      test('1.6 Bloom.empty() handles emptyReason', () {
        final emptyNode = Bloom<String>.empty();
        expect(untracked.state(emptyNode).isEmpty, isTrue);
        expect(untracked.state(emptyNode).emptyReason, isNull);

        final customEmptyNode = Bloom<String>.empty('CustomSearchMissing');
        expect(untracked.state(customEmptyNode).isEmpty, isTrue);
        expect(untracked.state(customEmptyNode).emptyReason, 'CustomSearchMissing');
      });

      test('1.7 toBloomTuple tracks pending state from true to false on success', () async {
        final completer = Completer<void>();
        final (data: _, :pending) = completer.future.toBloomTuple();

        int onDirtyCount = 0;
        final terminal = RawBloomTerminal(pending, onInvalidated: () {
          onDirtyCount++;
        });
        terminal.activate();

        expect(untracked(pending), isTrue);
        expect(terminal.data, isTrue);

        completer.complete();
        await Future<void>.delayed(Duration.zero);

        expect(untracked(pending), isFalse);
        expect(terminal.data, isFalse);
        expect(onDirtyCount, 1);

        terminal.deactivate();
      });

      test('1.8 toBloomTuple tracks pending state from true to false on error without unhandled error', () async {
        final completer = Completer<void>();
        final (data: _, :pending) = completer.future.toBloomTuple();

        int onDirtyCount = 0;
        final terminal = RawBloomTerminal(pending, onInvalidated: () {
          onDirtyCount++;
        });
        terminal.activate();

        expect(untracked(pending), isTrue);
        expect(terminal.data, isTrue);

        completer.completeError('SimulatedFailure');
        await Future<void>.delayed(Duration.zero);

        expect(untracked(pending), isFalse);
        expect(terminal.data, isFalse);
        expect(onDirtyCount, 1);

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 2. Iterable<Future>.toBloom() Tests
    // =========================================================================
    group('2. Iterable<Future>.toBloom()', () {
      test('2.1 transforms a list of Futures into a list of Bloom nodes', () async {
        final completer1 = Completer<String>();
        final completer2 = Completer<String>();
        final futures = [completer1.future, completer2.future];

        final group = futures.toBloom();
        expect(untracked(group).length, 2);

        final t1 = RawBloomTerminal(untracked(group)[0], onInvalidated: () {});
        final t2 = RawBloomTerminal(untracked(group)[1], onInvalidated: () {});
        t1.activate();
        t2.activate();

        completer1.complete('Hello');
        completer2.complete('World');
        await Future<void>.delayed(Duration.zero);

        expect(t1.data, 'Hello');
        expect(t2.data, 'World');

        t1.deactivate();
        t2.deactivate();
      });
    });

    // =========================================================================
    // 3. Stream.toBloom() Tests
    // =========================================================================
    group('3. Stream.toBloom()', () {
      test('3.1 updates bloom data as stream events occur', () async {
        final controller = StreamController<int>();
        final asyncBloom = controller.stream.toBloom();

        int onDirtyCount = 0;
        final terminal = RawBloomTerminal(asyncBloom, onInvalidated: () {
          onDirtyCount++;
        });
        terminal.activate();

        expect(terminal.snapshot.isEmpty, isTrue);

        controller.add(1);
        await Future<void>.delayed(Duration.zero);
        expect(terminal.data, 1);
        expect(onDirtyCount, 1);

        controller.add(2);
        await Future<void>.delayed(Duration.zero);
        expect(terminal.data, 2);
        expect(onDirtyCount, 2);

        await controller.close();
        terminal.deactivate();
      });

      test('3.2 handles distinct correctly', () async {
        final controller = StreamController<int>();
        final asyncBloom = controller.stream.toBloom(distinct: true);

        int onDirtyCount = 0;
        late final RawBloomTerminal<int> terminal;
        terminal = RawBloomTerminal(asyncBloom, onInvalidated: () {
          onDirtyCount++;
          terminal.snapshot;
        });
        terminal.activate();

        controller.add(1);
        await Future<void>.delayed(Duration.zero);

        controller.add(1); // Ignored
        await Future<void>.delayed(Duration.zero);

        controller.add(2);
        await Future<void>.delayed(Duration.zero);

        expect(terminal.data, 2);
        expect(onDirtyCount, 2);

        await controller.close();
        terminal.deactivate();
      });

      test('3.3 handles errors and cancelOnError correctly', () async {
        final controller = StreamController<int>();
        final asyncBloom = controller.stream.toBloom(cancelOnError: true);

        final terminal = RawBloomTerminal(asyncBloom, onInvalidated: () {});
        terminal.activate();

        final exception = Exception('Stream error');
        controller.addError(exception);
        await Future<void>.delayed(Duration.zero);

        expect(terminal.snapshot.hasError, isTrue);
        expect(terminal.error, exception);
        expect(controller.hasListener, isFalse);

        await controller.close();
        terminal.deactivate();
      });

      test('3.4 unsubscribes when terminal is deactivated', () async {
        final controller = StreamController<int>();
        final asyncBloom = controller.stream.toBloom();

        final terminal = RawBloomTerminal(asyncBloom, onInvalidated: () {});
        terminal.activate();

        expect(controller.hasListener, isTrue);

        terminal.deactivate();
        expect(controller.hasListener, isFalse);

        await controller.close();
      });

      test('3.5 broadcast stream can be deactivated and reactivated successfully', () async {
        final controller = StreamController<int>.broadcast();
        final asyncBloom = controller.stream.toBloom();

        final terminal = RawBloomTerminal(asyncBloom, onInvalidated: () {});
        terminal.activate();

        controller.add(1);
        await Future<void>.delayed(Duration.zero);
        expect(terminal.data, 1);

        terminal.deactivate();
        expect(controller.hasListener, isFalse);

        terminal.activate();
        expect(controller.hasListener, isTrue);

        controller.add(2);
        await Future<void>.delayed(Duration.zero);
        expect(terminal.data, 2);

        terminal.deactivate();
        await controller.close();
      });

      test('3.6 single-subscription stream transitions to error state upon reactivation', () async {
        final controller = StreamController<int>();
        final asyncBloom = controller.stream.toBloom();

        final terminal = RawBloomTerminal(asyncBloom, onInvalidated: () {});
        terminal.activate();

        controller.add(10);
        await Future<void>.delayed(Duration.zero);
        expect(terminal.data, 10);

        terminal.deactivate();
        expect(controller.hasListener, isFalse);

        // Reactivating attempts to re-listen to single-subscription stream, throwing StateError
        terminal.activate();
        expect(terminal.snapshot.hasError, isTrue);
        expect(terminal.error, isA<StateError>());

        terminal.deactivate();
        await controller.close();
      });

      test('3.7 toBloomTuple transitions pending to false on first event', () async {
        final controller = StreamController<String>();
        final (data: dataBloom, pending: pendingBloom) = controller.stream.toBloomTuple();

        final terminal = RawBloomTerminal(dataBloom, onInvalidated: () {});
        terminal.activate();

        expect(untracked(pendingBloom), isTrue);
        expect(terminal.snapshot.isEmpty, isTrue);

        controller.add('Chunk 1');
        await Future<void>.delayed(Duration.zero);

        expect(terminal.data, 'Chunk 1');
        expect(untracked(pendingBloom), isFalse);

        controller.add('Chunk 2');
        await Future<void>.delayed(Duration.zero);

        expect(terminal.data, 'Chunk 2');
        expect(untracked(pendingBloom), isFalse);

        terminal.deactivate();
        await controller.close();
      });

      test('3.8 toBloomTuple with initialFactory keeps pending true while awaiting first event', () async {
        final controller = StreamController<String>();
        final (data: dataBloom, pending: pendingBloom) = controller.stream.toBloomTuple(
          initialFactory: () => 'Initial',
        );

        // Before activation, pending is passive false
        expect(untracked(pendingBloom), isFalse);

        final terminal = RawBloomTerminal(dataBloom, onInvalidated: () {});
        terminal.activate();

        expect(terminal.data, 'Initial');
        expect(untracked(pendingBloom), isTrue);

        controller.add('Event 1');
        await Future<void>.delayed(Duration.zero);

        expect(terminal.data, 'Event 1');
        expect(untracked(pendingBloom), isFalse);

        terminal.deactivate();
        await controller.close();
      });

      test('3.9 toBloomTuple transitions pending to false on error when data is active', () async {
        final controller = StreamController<int>();
        final (data: dataBloom, pending: pendingBloom) = controller.stream.toBloomTuple();

        final tData = RawBloomTerminal(dataBloom, onInvalidated: () {});
        final tPending = RawBloomTerminal(pendingBloom, onInvalidated: () {});

        // Prior to data activation, pending is passive false
        expect(untracked(pendingBloom), isFalse);

        tData.activate();
        tPending.activate();

        expect(untracked(pendingBloom), isTrue);

        controller.addError(Exception('Fail'));
        await Future<void>.delayed(Duration.zero);
        expect(untracked(pendingBloom), isFalse);

        tData.deactivate();
        tPending.deactivate();
        await controller.close();
      });

      test('3.10 multiple terminals activating data node is idempotent and does not throw', () async {
        final controller = StreamController<int>();
        final asyncBloom = controller.stream.toBloom();

        final t1 = RawBloomTerminal(asyncBloom, onInvalidated: () {});
        final t2 = RawBloomTerminal(asyncBloom, onInvalidated: () {});

        t1.activate();
        expect(controller.hasListener, isTrue);

        // Activating second terminal on the same bloom node must be idempotent and not throw StateError
        expect(() => t2.activate(), returnsNormally);

        controller.add(42);
        await Future<void>.delayed(Duration.zero);
        expect(t1.data, 42);
        expect(t2.data, 42);

        t1.deactivate();
        expect(controller.hasListener, isTrue);

        t2.deactivate();
        expect(controller.hasListener, isFalse);

        await controller.close();
      });
    });

    // =========================================================================
    // 4. Iterable<Stream>.toBloom() Tests
    // =========================================================================
    group('4. Iterable<Stream>.toBloom()', () {
      test('4.1 transforms a list of Streams into a list of Bloom nodes', () async {
        final controller1 = StreamController<String>();
        final controller2 = StreamController<String>();
        final streams = [controller1.stream, controller2.stream];

        final group = streams.toBloom();
        expect(untracked(group).length, 2);

        final t1 = RawBloomTerminal(untracked(group)[0], onInvalidated: () {});
        final t2 = RawBloomTerminal(untracked(group)[1], onInvalidated: () {});
        t1.activate();
        t2.activate();

        controller1.add('Hello');
        controller2.add('World');
        await Future<void>.delayed(Duration.zero);

        expect(t1.data, 'Hello');
        expect(t2.data, 'World');

        t1.deactivate();
        t2.deactivate();
        await controller1.close();
        await controller2.close();
      });
    });

    // =========================================================================
    // 5. Bloom.future() & Bloom.stream() Factory Constructor Tests
    // =========================================================================
    group('5. Bloom.future() & Bloom.stream() Factory Constructors', () {
      test('5.1 Bloom.future bridges Future and resolves upon activation', () async {
        final completer = Completer<String>();
        final asyncBloom = Bloom.future(completer.future, initialFactory: () => 'Loading');

        expect(untracked.state(asyncBloom).snapshot.hasData, isTrue);
        expect(untracked(asyncBloom), 'Loading');

        final terminal = RawBloomTerminal(asyncBloom, onInvalidated: () {});
        terminal.activate();

        completer.complete('ResolvedValue');
        await Future<void>.delayed(Duration.zero);

        expect(terminal.data, 'ResolvedValue');
        terminal.deactivate();
      });

      test('5.2 Bloom.stream bridges Stream with lifecycle and distinct comparator', () async {
        final streamController = StreamController<int>();
        final asyncBloom = Bloom.stream(
          streamController.stream,
          initialFactory: () => 0,
          distinct: true,
        );

        expect(untracked(asyncBloom), 0);

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(asyncBloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        streamController.add(10);
        await Future<void>.delayed(Duration.zero);
        expect(terminal.data, 10);
        expect(dirtyCount, 1);

        // Duplicate value with distinct: true should not trigger dirty notification
        streamController.add(10);
        await Future<void>.delayed(Duration.zero);
        expect(dirtyCount, 1);

        streamController.add(20);
        await Future<void>.delayed(Duration.zero);
        expect(terminal.data, 20);
        expect(dirtyCount, 2);

        terminal.deactivate();
        await streamController.close();
      });
    });

    // =========================================================================
    // 6. Asynchronous Tuple & Single-Subscription Synchronization Tests
    // =========================================================================
    group('6. Asynchronous Tuple & Single-Subscription Synchronization', () {
      test('6.1 Future.toBloomTuple() returns synchronized data and pending nodes', () async {
        final completer = Completer<String>();
        final (data: bloom, :pending) = completer.future.toBloomTuple(
          initialFactory: () => 'Initial',
        );

        expect(untracked(bloom), 'Initial');
        expect(untracked(pending), isTrue);

        completer.complete('Settled');
        await Future<void>.delayed(Duration.zero);

        expect(untracked(bloom), 'Settled');
        expect(untracked(pending), isFalse);
      });

      test('6.2 Future.toBloomTuple() with onError intercepts error safely', () async {
        final completer = Completer<int>();
        final (data: bloom, :pending) = completer.future.toBloomTuple(
          onError: (error, [stackTrace]) => -1,
        );

        expect(untracked(pending), isTrue);

        completer.completeError(Exception('Failure'));
        await Future<void>.delayed(Duration.zero);

        expect(untracked(bloom), -1);
        expect(untracked(pending), isFalse);
      });

      test('6.3 Stream.toBloomTuple() single-subscription safety across data and pending blooms', () async {
        // Crucial test: standard single-subscription stream
        final controller = StreamController<String>();
        final (data: dataBloom, pending: pendingBloom) = controller.stream.toBloomTuple();

        // Attach terminals to data and pending simultaneously
        final tData = RawBloomTerminal(dataBloom, onInvalidated: () {});
        final tPending = RawBloomTerminal(pendingBloom, onInvalidated: () {});

        // Activating both must share ONE subscription and NOT throw Bad state!
        tData.activate();
        tPending.activate();

        expect(tPending.data, isTrue);
        expect(tData.snapshot.isEmpty, isTrue);

        // Emit first event
        controller.add('Event 1');
        await Future<void>.delayed(Duration.zero);

        expect(tData.data, 'Event 1');
        expect(tPending.data, isFalse);

        // Emit second event
        controller.add('Event 2');
        await Future<void>.delayed(Duration.zero);

        expect(tData.data, 'Event 2');
        expect(tPending.data, isFalse);

        // Close stream
        await controller.close();
        await Future<void>.delayed(Duration.zero);

        expect(tData.data, 'Event 2');
        expect(tPending.data, isFalse);

        tData.deactivate();
        tPending.deactivate();
      });

      test('6.4 Stream.toBloomTuple() with initialFactory seeds pending as false when dormant', () async {
        final controller = StreamController<int>();
        final (:data, :pending) = controller.stream.toBloomTuple(
          initialFactory: () => 100,
        );

        expect(untracked(data), 100);
        expect(untracked(pending), isFalse); // dormant: pending is false

        final terminal = RawBloomTerminal(data, onInvalidated: () {});
        terminal.activate();

        expect(untracked(pending), isTrue); // active: waiting for first stream event

        controller.add(200);
        await Future<void>.delayed(Duration.zero);
        expect(terminal.data, 200);
        expect(untracked(pending), isFalse);

        await controller.close();
        terminal.deactivate();
      });

      test('6.5 Stream.toBloomTuple() activates upstream only when data is active and pending is a passive facet', () async {
        var isSubscribed = false;
        late final StreamController<String> controller;
        controller = StreamController<String>(
          onListen: () => isSubscribed = true,
          onCancel: () => isSubscribed = false,
        );

        final (data: dataBloom, pending: pendingBloom) = controller.stream.toBloomTuple();
        expect(isSubscribed, isFalse);

        final tData = RawBloomTerminal(dataBloom, onInvalidated: () {});
        final tPending = RawBloomTerminal(pendingBloom, onInvalidated: () {});

        // Activating pending alone does NOT trigger upstream listen (passive observer guarantee)
        tPending.activate();
        expect(isSubscribed, isFalse);
        expect(tPending.data, isFalse);

        // Activating data triggers upstream listen and transitions pending to true
        tData.activate();
        expect(isSubscribed, isTrue);
        expect(tPending.data, isTrue);

        // Deactivating data unbinds upstream immediately, even if pending is still observed
        tData.deactivate();
        expect(isSubscribed, isFalse);
        expect(tPending.data, isFalse);

        tPending.deactivate();
        await controller.close();
      });

      test('6.6 Stream.toBloomTriple() returns ({data, pending, done}) and tracks full lifecycle', () async {
        final controller = StreamController<String>();
        final (:data, :pending, :done) = controller.stream.toBloomTriple();

        final tData = RawBloomTerminal(data, onInvalidated: () {});
        final tPending = RawBloomTerminal(pending, onInvalidated: () {});
        final tDone = RawBloomTerminal(done, onInvalidated: () {});

        tData.activate();
        tPending.activate();
        tDone.activate();

        // Initial phase: pending=true, done=false, data is empty
        expect(tPending.data, isTrue);
        expect(tDone.data, isFalse);
        expect(untracked.state(data).isEmpty, isTrue);

        // First event: pending=false, done=false, data emitted
        controller.add('Message 1');
        await Future<void>.delayed(Duration.zero);
        expect(tPending.data, isFalse);
        expect(tDone.data, isFalse);
        expect(tData.data, 'Message 1');

        // Second event: data updates
        controller.add('Message 2');
        await Future<void>.delayed(Duration.zero);
        expect(tPending.data, isFalse);
        expect(tDone.data, isFalse);
        expect(tData.data, 'Message 2');

        // Stream closes: done=true, pending=false
        await controller.close();
        await Future<void>.delayed(Duration.zero);
        expect(tDone.data, isTrue);
        expect(tPending.data, isFalse);
        expect(tData.data, 'Message 2');

        tData.deactivate();
        tPending.deactivate();
        tDone.deactivate();
      });

      test('6.7 Stream.toBloomTriple() activates upstream only on data demand and preserves passive pending/done facets', () async {
        var isSubscribed = false;
        late final StreamController<String> controller;
        controller = StreamController<String>(
          onListen: () => isSubscribed = true,
          onCancel: () => isSubscribed = false,
        );

        final (:data, :pending, :done) = controller.stream.toBloomTriple();
        expect(isSubscribed, isFalse);

        final tData = RawBloomTerminal(data, onInvalidated: () {});
        final tPending = RawBloomTerminal(pending, onInvalidated: () {});
        final tDone = RawBloomTerminal(done, onInvalidated: () {});

        // Activating done or pending alone does NOT trigger upstream listen
        tDone.activate();
        expect(isSubscribed, isFalse);
        expect(tDone.data, isFalse);

        tPending.activate();
        expect(isSubscribed, isFalse);
        expect(tPending.data, isFalse);

        // Only data activation triggers upstream
        tData.activate();
        expect(isSubscribed, isTrue);
        expect(tPending.data, isTrue);

        // Deactivating data unbinds upstream cleanly even while done and pending are active
        tData.deactivate();
        expect(isSubscribed, isFalse);

        tDone.deactivate();
        tPending.deactivate();
        await controller.close();
      });
    });
  });
}


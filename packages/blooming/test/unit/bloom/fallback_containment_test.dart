// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

void main() {
  group('Bloom Native Fallback & Callback Error Containment Suite', () {
    // =========================================================================
    // 1. Bloom.computed Fallback & Exception Containment
    // =========================================================================
    group('1. Bloom.computed Fallback & Error Containment', () {
      test('1.1 computed transforms valid data normally when fallbacks are provided', () {
        final controller = blooming<int>(5);
        final mapped = computed((via) {
          final s = via.state(controller.bloom).snapshot;
          if (s.isEmpty) return 'Count: 0';
          if (s.hasError) return 'Count: Error';
          return 'Count: ${s.data}';
        });

        expect(untracked.state(mapped).hasData, isTrue);
        expect(untracked(mapped), equals('Count: 5'));

        controller.set(10);
        expect(untracked(mapped), equals('Count: 10'));
      });

      test('1.2 computed uses onEmpty fallback when upstream is empty', () {
        final controller = blooming.late<int>();
        final mapped = computed((via) {
          final s = via.state(controller.bloom).snapshot;
          if (s.isEmpty) return 'Count: Default';
          if (s.hasError) return 'Count: Error';
          return 'Count: ${s.data}';
        });

        expect(untracked.state(mapped).hasData, isTrue);
        expect(untracked(mapped), equals('Count: Default'));

        controller.set(42);
        expect(untracked(mapped), equals('Count: 42'));

        controller.empty();
        expect(untracked(mapped), equals('Count: Default'));
      });

      test('1.3 computed uses onError fallback when upstream has error', () {
        final controller = blooming.late<int>();
        final mapped = computed((via) {
          final s = via.state(controller.bloom).snapshot;
          if (s.isEmpty) return 'Count: Default';
          if (s.hasError) return 'Recovered: ${s.error}';
          return 'Count: ${s.data}';
        });

        controller.setError('NetworkFailed');
        expect(untracked.state(mapped).hasData, isTrue);
        expect(untracked(mapped), equals('Recovered: NetworkFailed'));
      });

      test('1.4 computed catches exception thrown inside computation callback and isolates to Error', () {
        final controller = blooming<int>(0);
        final mapped = computed<int>((via) {
          final c = via(controller.bloom);
          if (c == 0) throw FormatException('Zero division forbidden');
          return 100 ~/ c;
        });

        // compute threw FormatException -> transitions to error state
        expect(untracked.state(mapped).hasError, isTrue);
        expect(untracked.state(mapped).error, isA<FormatException>());

        // Mutating to valid input clears error
        controller.set(2);
        expect(untracked.state(mapped).hasData, isTrue);
        expect(untracked(mapped), equals(50));
      });

      test('1.5 computed catches exception thrown inside onEmpty and onError branches gracefully', () {
        final controller = blooming.late<int>();
        final mapped = computed((via) {
          final s = via.state(controller.bloom).snapshot;
          if (s.isEmpty) throw StateError('Empty fallback failed');
          if (s.hasError) throw StateError('Error fallback failed');
          return 'Count: ${s.data}';
        });

        // onEmpty threw StateError
        expect(untracked.state(mapped).hasError, isTrue);
        expect(untracked.state(mapped).error, isA<StateError>());

        // Trigger error
        controller.setError('OriginalError');
        expect(untracked.state(mapped).hasError, isTrue);
        expect(untracked.state(mapped).error, isA<StateError>());
      });
    });

    // =========================================================================
    // 2. Bloom.computed with distinct Fallback & Error Containment
    // =========================================================================
    group('2. Bloom.computed with distinct Fallback & Deduplication', () {
      test('2.1 computed with distinct projects with deduplication and fallbacks', () {
        final controller = blooming.late<({String name, int age})>();
        final selected = computed((via) {
          final s = via.state(controller.bloom).snapshot;
          if (s.isEmpty) return 'Guest';
          if (s.hasError) return 'Recovered: ${s.error}';
          return s.data.name;
        }).distinct();

        expect(untracked.state(selected).hasData, isTrue);
        expect(untracked(selected), equals('Guest'));

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(selected, onInvalidated: () => dirtyCount++);
        terminal.activate();

        controller.set((name: 'Alice', age: 20));
        expect(terminal.data, equals('Alice'));
        expect(dirtyCount, 1);

        // Under 2-Phase LPDAG: dirty push reaches terminal; semantic deduplication is verified upon pull
        controller.set((name: 'Alice', age: 21));
        expect(dirtyCount, 2);
        expect(terminal.data, equals('Alice'));

        // Error -> recovered by onError
        controller.setError('NetworkLost');
        expect(terminal.data, equals('Recovered: NetworkLost'));
        expect(dirtyCount, 3);

        terminal.deactivate();
      });

      test('2.2 computed catches exception in selector and isolates to Error', () {
        final controller = blooming<int>(0);
        final selected = computed<int>((via) {
          final c = via(controller.bloom);
          if (c == 0) throw ArgumentError('Zero is forbidden');
          return 10 ~/ c;
        });

        expect(untracked.state(selected).hasError, isTrue);
        expect(untracked.state(selected).error, isA<ArgumentError>());

        controller.set(2);
        expect(untracked.state(selected).hasData, isTrue);
        expect(untracked(selected), equals(5));
      });
    });

    // =========================================================================
    // 3. Bloom.switched Native Fallback & Error Containment
    // =========================================================================
    group('3. Bloom.switched Native Fallback & Error Containment', () {
      test('2.1 switched switches branch with empty and error handling', () {
        final trigger = blooming.late<String?>();
        final fallbackBranch = Bloom.constant('DefaultBranch');

        final switchedBloom = switched<String>((via) {
          final t = via.state(trigger.bloom);
          if (t.isEmpty) return fallbackBranch;
          if (t.hasError) return Bloom.constant('ErrorBranch: ${t.error}');
          return Bloom.constant('Active: ${t.data}');
        });

        expect(untracked.state(switchedBloom).hasData, isTrue);
        expect(untracked(switchedBloom), equals('DefaultBranch'));

        trigger.set('User1');
        expect(untracked(switchedBloom), equals('Active: User1'));

        trigger.setError('TriggerFailed');
        expect(untracked(switchedBloom), equals('ErrorBranch: TriggerFailed'));
      });

      test('2.2 switched catches exception in switched builder callback', () {
        final trigger = blooming<int>(0);

        final switchedBloom = switched<String>((via) {
          final data = via(trigger.bloom);
          if (data == 0) throw ArgumentError('Invalid branch ID');
          return Bloom.constant('Branch $data');
        });

        expect(untracked.state(switchedBloom).hasError, isTrue);
        expect(untracked.state(switchedBloom).error, isA<ArgumentError>());

        trigger.set(1);
        expect(untracked.state(switchedBloom).hasData, isTrue);
        expect(untracked(switchedBloom), equals('Branch 1'));
      });
    });

    // =========================================================================
    // 3. Future.toBloom & Stream.toBloom Native Fallback & Initial State
    // =========================================================================
    group('3. Future.toBloom & Stream.toBloom Native Fallbacks', () {
      test('3.1 Future.toBloom with initialFactory starts in valid data state', () async {
        final completer = Completer<String>();
        final futureBloom = completer.future.toBloom(initialFactory: () => 'Initial');

        expect(untracked.state(futureBloom).hasData, isTrue);
        expect(untracked(futureBloom), equals('Initial'));

        final terminal = RawBloomTerminal(futureBloom, onInvalidated: () {});
        terminal.activate();

        completer.complete('Resolved');
        await Future<void>.delayed(Duration.zero);

        expect(untracked(futureBloom), equals('Resolved'));
        terminal.deactivate();
      });

      test('3.2 Future.toBloom with onError recovers from future failure', () async {
        final completer = Completer<int>();
        final futureBloom = completer.future.toBloom(
          initialFactory: () => 0,
          onError: (err, [stack]) => -999,
        );

        expect(untracked(futureBloom), equals(0));

        final terminal = RawBloomTerminal(futureBloom, onInvalidated: () {});
        terminal.activate();

        completer.completeError(Exception('API error'));
        await Future<void>.delayed(Duration.zero);

        expect(untracked.state(futureBloom).hasData, isTrue);
        expect(untracked(futureBloom), equals(-999));
        terminal.deactivate();
      });

      test('3.3 Stream.toBloom with initialFactory and onError', () async {
        final streamController = StreamController<int>();
        final streamBloom = streamController.stream.toBloom(
          initialFactory: () => 100,
          onError: (err, [stack]) => -1,
        );

        // Terminal activation to start stream subscription
        final terminal = RawBloomTerminal(streamBloom, onInvalidated: () {});
        terminal.activate();

        expect(untracked(streamBloom), equals(100));

        streamController.add(200);
        await Future<void>.delayed(Duration.zero);
        expect(untracked(streamBloom), equals(200));

        streamController.addError('StreamCrash');
        await Future<void>.delayed(Duration.zero);
        expect(untracked.state(streamBloom).hasData, isTrue);
        expect(untracked(streamBloom), equals(-1));

        terminal.deactivate();
        await streamController.close();
      });
    });

    // =========================================================================
    // 5. BloomController & BloomListController .error Native Constructors
    // =========================================================================
    group('5. BloomController & BloomListController .error', () {
      test('5.1 BloomController.error starts in error state and recovers on set', () {
        final error = FormatException('Initial format error');
        final controller = blooming.error<int>(error);

        expect(controller.hasError, isTrue);
        expect(controller.hasData, isFalse);
        expect(controller.isEmpty, isFalse);
        expect(controller.error, equals(error));
        expect(() => controller.data, throwsA(isA<BloomSnapshotExtractionException>()));

        // Downstream terminal receives invalidation on recovery
        int dirtyCount = 0;
        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () => dirtyCount++)..activate();

        controller.set(100);
        expect(controller.hasData, isTrue);
        expect(controller.data, equals(100));
        expect(dirtyCount, 1);

        terminal.deactivate();
      });

      test('5.2 BloomController.error with distinct and lifecycle hooks', () {
        bool activated = false;
        bool deactivated = false;

        final controller = blooming.error<String>(
          'InitError',
          onActivated: () => activated = true,
          onDeactivated: () => deactivated = true,
        );

        expect(controller.isActive, isFalse);
        expect(controller.hasError, isTrue);

        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () {});
        terminal.activate();
        expect(activated, isTrue);
        expect(controller.isActive, isTrue);

        // Deduplication on set
        controller.set('Hello');
        expect(controller.data, equals('Hello'));

        terminal.deactivate();
        expect(deactivated, isTrue);
      });

      test('5.3 BloomListController.error starts in error state and recovers on set', () {
        final controller = blooming.list.error<Bloom<int>>('GroupError');

        expect(controller.snapshot.hasError, isTrue);
        expect(controller.snapshot.hasData, isFalse);
        expect(controller.snapshot.error, equals('GroupError'));
        expect(() => controller.data, throwsA(isA<BloomSnapshotExtractionException>()));

        final bloom1 = Bloom.constant(1);
        final bloom2 = Bloom.constant(2);
        controller.set([bloom1, bloom2]);

        expect(controller.snapshot.hasData, isTrue);
        expect(controller.data, equals([bloom1, bloom2]));
      });
    });

    // =========================================================================
    // =========================================================================
    // 6. BloomCoupler .error Sockets
    // =========================================================================
    group('6. BloomCoupler .error', () {
      test('6.1 BloomCoupler.error starts in error state and recovers on couple', () {
        final coupler = BloomCoupler<String>.error('SocketUnavailable');

        expect(coupler.hasError, isTrue);
        expect(coupler.error, equals('SocketUnavailable'));

        final liveSource = Bloom.constant('LivePayload');
        coupler.couple(liveSource);

        expect(coupler.hasData, isTrue);
        expect(coupler.data, equals('LivePayload'));
      });

      test('6.2 BloomCoupler<List> .error starts in error state and recovers on couple', () {
        final coupler = BloomCoupler<List<Bloom<int>>>.error('BundleError');

        expect(coupler.snapshot.hasError, isTrue);
        expect(coupler.snapshot.error, equals('BundleError'));

        final liveBundle = Bloom.constant([Bloom.constant(10), Bloom.constant(20)]);
        coupler.couple(liveBundle);

        expect(coupler.snapshot.hasData, isTrue);
        expect(untracked(coupler.bloom).map((g) => untracked(g)).toList(), equals([10, 20]));
      });
    });

    // =========================================================================
    // 7. BloomListController Fallback & Exception Containment
    // =========================================================================
    group('7. BloomListController Fallback & Exception Containment', () {
      test('7.1 BloomListController.late starts empty and recovers with data assignment', () {
        final controller = blooming.list.late<Bloom<int>>();

        expect(controller.snapshot.isEmpty, isTrue);
        expect(controller.snapshot.hasData, isFalse);

        // Recovering with data
        controller.data = [Bloom.constant(1), Bloom.constant(2)];
        expect(controller.snapshot.hasData, isTrue);
        expect(controller.data.map((g) => untracked(g)).toList(), equals([1, 2]));
      });

      test('7.2 BloomListController.setGuarded catches exception and isolates failure to error state', () {
        final controller = blooming.list<Bloom<int>>([Bloom.constant(10)]);

        controller.setGuarded(() {
          throw FormatException('Invalid nodes generation');
        });

        expect(controller.snapshot.hasError, isTrue);
        expect(controller.snapshot.error, isA<FormatException>());
      });

      test('7.3 BloomListController.error initializes in error state and fails fast on data access', () {
        final controller = blooming.list.error<Bloom<int>>(StateError('Group failed'));

        expect(controller.snapshot.hasError, isTrue);
        expect(controller.snapshot.error, isA<StateError>());
        expect(() => controller.data, throwsA(isA<BloomSnapshotExtractionException>()));
      });

      test('7.4 BloomListController.error recovers to valid state on subsequent data assignment', () {
        final controller = blooming.list.error<Bloom<int>>('OriginalError');

        expect(controller.snapshot.hasError, isTrue);

        // Recovery
        controller.data = [Bloom.constant(100)];
        expect(controller.snapshot.hasData, isTrue);
        expect(untracked(controller.data.first), equals(100));
      });
    });

    // =========================================================================
    // 9. BloomListController Dynamic Aggregation & Exception Containment
    // =========================================================================
    group('9. BloomListController Dynamic Aggregation & Exception Containment', () {
      test('9.1 dynamic aggregation collapses data into bloom normally with fallbacks provided', () {
        final controller = blooming.list<Bloom<int>>([Bloom.constant(10), Bloom.constant(20)]);
        final converged = computed((via) {
          if (via.state(controller.bloom).hasError) return -1;
          if (via.state(controller.bloom).isEmpty) return 0;
          return via(controller.bloom).map((g) => via(g)).reduce((a, b) => a + b);
        });

        expect(untracked.state(converged).hasData, isTrue);
        expect(untracked(converged), equals(30));

        controller.set([Bloom.constant(1), Bloom.constant(2), Bloom.constant(3)]);
        expect(untracked(converged), equals(6));
      });

      test('9.2 dynamic aggregation handles empty upstream bloom list', () {
        final controller = blooming.list.late<Bloom<int>>();
        final converged = computed((via) {
          if (via.state(controller.bloom).hasError) return -1;
          if (via.state(controller.bloom).isEmpty) return 100;
          return via(controller.bloom).map((g) => via(g)).reduce((a, b) => a + b);
        });

        expect(untracked.state(converged).hasData, isTrue);
        expect(untracked(converged), equals(100));

        controller.set([Bloom.constant(5), Bloom.constant(5)]);
        expect(untracked(converged), equals(10));

        controller.empty();
        expect(untracked(converged), equals(100));
      });

      test('9.3 dynamic aggregation handles error or throwing callback', () {
        final controller = blooming.list.error<Bloom<int>>('GroupExploded');
        final converged = computed((via) {
          if (via.state(controller.bloom).hasError) return 555;
          return via(controller.bloom).map((g) => via(g)).reduce((a, b) => a + b);
        });

        expect(untracked.state(converged).hasData, isTrue);
        expect(untracked(converged), equals(555));

        // When callback throws
        final liveController = blooming.list<Bloom<int>>([Bloom.constant(1)]);
        final throwingConverged = computed((via) {
          if (via(liveController.bloom).isNotEmpty) throw FormatException('Converge parse error');
          return 888;
        });

        expect(untracked.state(throwingConverged).hasError, isTrue);
        expect(untracked.state(throwingConverged).error, isA<FormatException>());
      });

      test('9.4 dynamic aggregation with throwing isolates to error state without crashing', () {
        final controller = blooming.list.late<Bloom<int>>();
        final converged = computed((via) {
          if (via.state(controller.bloom).isEmpty) throw 'onEmptyThrows';
          return 1;
        });

        expect(untracked.state(converged).hasError, isTrue);
        expect(untracked.state(converged).error, equals('onEmptyThrows'));
      });
    });
  });
}

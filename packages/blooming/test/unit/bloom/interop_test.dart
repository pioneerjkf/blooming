// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:blooming/blooming.dart';
import 'package:test/test.dart';
import '../../test_utils.dart';

void main() {
  group('Bloom Interop & Proxy Delegation', () {
    test('BloomController.bloom wraps reactive node and tracks automatically', () async {
      final controller = BloomController<int>(100);
      final bloomView = controller.bloom;

      expect(untracked(bloomView), 100);

      var effectRuns = 0;
      var lastValue = 0;

      final dispose = effect((via) {
        effectRuns++;
        lastValue = via(bloomView);
      });

      await Future<void>.delayed(Duration.zero);
      expect(effectRuns, 1);
      expect(lastValue, 100);

      controller.data = 200;
      await Future.microtask(() {});

      expect(effectRuns, 2);
      expect(lastValue, 200);

      dispose();
    });

    test('untracked function and member bypass reactive tracking', () async {
      final trigger = BloomController(0);
      final untrackedData = BloomController('Secret');

      var effectRuns = 0;
      String? observedSecret;

      final dispose = effect((via) {
        effectRuns++;
        via(trigger.bloom); // Only trigger is tracked

        // untrackedData is read via raw read WITHOUT registering tracking
        observedSecret = untrackedData.data;
      });

      await Future<void>.delayed(Duration.zero);
      expect(effectRuns, 1);
      expect(observedSecret, 'Secret');

      // Mutating untrackedData should NOT trigger the effect!
      untrackedData.data = 'NewSecret';
      await Future.microtask(() {});

      expect(effectRuns, 1); // Effect did not run!

      // Also verify direct raw read .data
      expect(untrackedData.data, 'NewSecret');

      // Mutating trigger DOES trigger the effect and picks up the latest untracked secret
      trigger.data = 1;
      await Future.microtask(() {});

      expect(effectRuns, 2);
      expect(observedSecret, 'NewSecret');

      dispose();
    });

    test('works smoothly with BloomListController pipelines', () {
      final a = BloomController(10);
      final b = BloomController(20);

      final group = blooming.list([a.bloom, b.bloom]);
      expect(group.data.map((g) => untracked(g)).toList(), [10, 20]);

      a.data = 100;
      expect(group.data.map((g) => untracked(g)).toList(), [100, 20]);
    });

    test('BloomController implements BloomState directly', () {
      final r1 = BloomController(10);
      final r2 = BloomController<int>.late();

      expect(r1, isA<BloomState<int>>());
      expect(r1.hasData, isTrue);
      expect(r1.isEmpty, isFalse);
      expect(r1.snapshot.data, equals(10));

      expect(r2, isA<BloomState<int>>());
      expect(r2.isEmpty, isTrue);
      expect(r2.hasData, isFalse);

      r2.data = 20;
      expect(r2.hasData, isTrue);
      expect(r2.snapshot.data, equals(20));
    });

    test('BloomIterableExtension combines and folds multiple Blooms reactively', () async {
      final a = BloomController('Hello');
      final b = BloomController('World');

      final combined = Bloom.constant([a.bloom, b.bloom]).combine();
      final folded = Bloom.constant([a.bloom, b.bloom]).fold('>>', (acc, item) => '$acc $item');
      final reduced = Bloom.constant([a.bloom, b.bloom]).reduce((prev, item) => '$prev+$item');

      var combinedRuns = 0;
      List<String>? latestList;
      String? latestFolded;
      String? latestReduced;

      final dispose = effect((via) {
        combinedRuns++;
        latestList = via(combined);
        latestFolded = via(folded);
        latestReduced = via(reduced);
      });

      await Future<void>.delayed(Duration.zero);
      expect(combinedRuns, 1);
      expect(latestList, ['Hello', 'World']);
      expect(latestFolded, '>> Hello World');
      expect(latestReduced, 'Hello+World');

      a.data = 'Hi';
      await Future.microtask(() {});

      expect(combinedRuns, 2);
      expect(latestList, ['Hi', 'World']);
      expect(latestFolded, '>> Hi World');
      expect(latestReduced, 'Hi+World');

      dispose();
    });

    test('BloomIterableNumericExtension sum computes reactive sum via Bloom.constant().sum()', () async {
      final p1 = BloomController(100);
      final p2 = BloomController(250);
      final p3 = BloomController(50);

      final total = Bloom.constant([p1.bloom, p2.bloom, p3.bloom]).sum();

      var effectRuns = 0;
      var lastSum = 0;
      final dispose = effect((via) {
        effectRuns++;
        lastSum = via(total);
      });

      await Future<void>.delayed(Duration.zero);
      expect(effectRuns, 1);
      expect(lastSum, 400);

      p2.data = 300;
      await Future.microtask(() {});

      expect(effectRuns, 2);
      expect(lastSum, 450);

      dispose();
    });

    test('BloomIterableExtension evaluates logical AND (every) and OR (any)', () async {
      final isNameValid = BloomController(true);
      final isEmailValid = BloomController(true);
      final isAgreed = BloomController(false);

      final formReady = Bloom.constant([isNameValid.bloom, isEmailValid.bloom, isAgreed.bloom]).every();
      final hasAnyValid = Bloom.constant([isNameValid.bloom, isEmailValid.bloom, isAgreed.bloom]).any();

      var runs = 0;
      bool? isReady;
      bool? hasValid;

      final dispose = effect((via) {
        runs++;
        isReady = via(formReady);
        hasValid = via(hasAnyValid);
      });

      await Future<void>.delayed(Duration.zero);
      expect(runs, 1);
      expect(isReady, isFalse);
      expect(hasValid, isTrue);

      isAgreed.data = true;
      await Future.microtask(() {});

      expect(runs, 2);
      expect(isReady, isTrue);
      expect(hasValid, isTrue);

      dispose();
    });

    test('Bloom.computed with distinct projects slice and suppresses downstream effect runs when slice unchanged',
        () async {
      final user = BloomController((name: 'Alice', age: 20));

      final name = computed((via) => via(user.bloom).name).distinct();

      var effectRuns = 0;
      String? lastName;

      final dispose = effect((via) {
        effectRuns++;
        lastName = via(name);
      });

      await Future<void>.delayed(Duration.zero);
      expect(effectRuns, 1);
      expect(lastName, 'Alice');

      // Age changes, name remains the same -> effect should NOT re-run!
      user.data = (name: 'Alice', age: 21);
      await Future.microtask(() {});

      expect(effectRuns, 1);
      expect(lastName, 'Alice');

      // Name changes -> effect runs!
      user.data = (name: 'Bob', age: 21);
      await Future.microtask(() {});

      expect(effectRuns, 2);
      expect(lastName, 'Bob');

      // Custom comparator support
      final decade = computed((via) => via(user.bloom).age).distinct(
        (prev, next) => (prev ~/ 10) == (next ~/ 10),
      );

      var decadeRuns = 0;
      int? lastAge;
      final disposeDecade = effect((via) {
        decadeRuns++;
        lastAge = via(decade);
      });

      await Future<void>.delayed(Duration.zero);
      expect(decadeRuns, 1);
      expect(lastAge, 21);

      user.data = (name: 'Bob', age: 29); // same decade
      await Future.microtask(() {});
      expect(decadeRuns, 1);

      user.data = (name: 'Bob', age: 30); // new decade
      await Future.microtask(() {});
      expect(decadeRuns, 2);
      expect(lastAge, 30);

      dispose();
      disposeDecade();
    });

    test('Bloom.error creates error bloom and handles errors safely', () {
      final r1 = Bloom<int>.error('ErrorMsg');
      final r2 = Bloom<int>.error('ConstructorError');

      expect(untracked.state(r1).hasError, isTrue);
      expect(untracked.state(r1).error, 'ErrorMsg');
      expect(() => untracked(r1), throwsA(isA<BloomSnapshotExtractionException>()));
      expect(untracked.state(r1).dataOrNull, isNull);
      expect(untracked.state(r1).dataOrElse(() => 999), 999);

      expect(untracked.state(r2).hasError, isTrue);
      expect(untracked.state(r2).error, 'ConstructorError');
    });

    test('Bloom.resource creates topology-aware resource bound to subscriptions', () async {
      var createCalls = 0;
      var disposeCalls = 0;

      final resBloom = managed<String>(
        create: (_) {
          createCalls++;
          return 'DynamicResource';
        },
        dispose: (res) {
          disposeCalls++;
        },
      );

      // Inactive initially -> not created yet
      expect(createCalls, 0);
      expect(disposeCalls, 0);

      final dispose = effect((via) {
        via(resBloom);
      });

      await Future<void>.delayed(Duration.zero);
      expect(createCalls, 1);
      expect(untracked(resBloom), 'DynamicResource');

      dispose();
      expect(disposeCalls, 1);
    });

    test('Bloom.computed and Bloom.distinct transform and deduplicate reactively', () async {
      final count = BloomController(5);
      final multiplied = computed((via) => via(count.bloom) * 2);
      final isEven = computed((via) => via(multiplied) % 2 == 0).distinct();

      var isEvenRuns = 0;
      bool? lastIsEven;

      final dispose = effect((via) {
        isEvenRuns++;
        lastIsEven = via(isEven);
      });

      await Future<void>.delayed(Duration.zero);
      expect(isEvenRuns, 1);
      expect(lastIsEven, isTrue);

      // count 5 -> 7: multiplied 10 -> 14 (both even): isEven distinct prevents re-run
      count.data = 7;
      await Future.microtask(() {});

      expect(isEvenRuns, 1);
      expect(untracked(multiplied), 14);

      dispose();
    });

    test('Bloom.computed with guard conditionally blocks computation and becomes empty state', () async {
      final secret = BloomController('TopSecret');
      var authorized = true;

      final guarded = computed(
        (via) => via(secret.bloom),
        guard: (via) => authorized.guarded('Access Denied'),
      );

      var effectRuns = 0;
      String? observed;
      Object? observedReason;

      final dispose = effect((via) {
        effectRuns++;
        final g = via.state(guarded);
        if (g.hasData) {
          observed = g.data;
        } else if (g.isEmpty) {
          observedReason = g.snapshot.emptyReason;
        }
      });

      await Future<void>.delayed(Duration.zero);
      expect(effectRuns, 1);
      expect(observed, 'TopSecret');

      authorized = false;
      secret.data = 'UpdatedSecret';
      await Future.microtask(() {});

      expect(effectRuns, 2);
      expect(untracked.state(guarded).isEmpty, isTrue);
      expect(observedReason, 'Access Denied');

      dispose();
    });

    test('Bloom dataOrElse and computed recover uninitialized and error states', () {
      final uninit = BloomController<String>.late();
      final failing = Bloom<String>.error('NetworkError');

      final safeUninit = computed((via) => via.state(uninit.bloom).dataOrElse(() => 'DefaultUninit'));
      final safeFailing = computed((via) {
        final s = via.state(failing).snapshot;
        if (s.hasError) return 'Safe: ${s.error}';
        return s.data;
      });
      final nullView = computed<String?>((via) => via.state(uninit.bloom).hasData ? via(uninit.bloom) : null);

      expect(untracked(safeUninit), 'DefaultUninit');
      expect(untracked(safeFailing), 'Safe: NetworkError');
      expect(untracked(nullView), isNull);
      expect(untracked.state(nullView).hasData, isTrue);
    });

    test('bloom.resource auto-tracks upstream and creates lifecycle-bound resource', () async {
      final factor = BloomController(2);
      var disposedResource = '';

      final derivedRes = managed<String>(
        create: (via) => 'Resource_x${via(factor.bloom)}',
        update: (via, current) => 'Resource_x${via(factor.bloom)}',
        dispose: (res) => disposedResource = res,
      );

      final dispose = effect((via) {
        via(derivedRes);
      });

      await Future<void>.delayed(Duration.zero);
      expect(untracked(derivedRes), 'Resource_x2');

      dispose();
      expect(disposedResource, 'Resource_x2');
    });

    test('bloom.resource disposes previous and creates new resource on upstream change when update is omitted',
        () async {
      final config = BloomController('wss://server-1');
      final disposedList = <String>[];
      final createdList = <String>[];

      final sessionBloom = managed<String>(
        create: (via) {
          final session = 'Session(${via(config.bloom)})';
          createdList.add(session);
          return session;
        },
        dispose: (session) {
          disposedList.add(session);
        },
      );

      // Before activation, no resource created
      expect(untracked.state(sessionBloom).isEmpty, isTrue);
      expect(createdList, isEmpty);

      String? activeSession;
      final disposeEffect = effect((via) {
        activeSession = via(sessionBloom);
      });

      await Future<void>.delayed(Duration.zero);
      expect(activeSession, 'Session(wss://server-1)');
      expect(createdList, ['Session(wss://server-1)']);
      expect(disposedList, isEmpty);

      // Upstream changes -> old session is disposed, new session is created upon read
      config.data = 'wss://server-2';
      expect(untracked(sessionBloom), 'Session(wss://server-2)');
      expect(disposedList, ['Session(wss://server-1)']);
      expect(createdList, ['Session(wss://server-1)', 'Session(wss://server-2)']);

      // After effect microtask runs, activeSession in effect is updated
      await Future.microtask(() {});
      expect(activeSession, 'Session(wss://server-2)');

      // Downstream deactivates (e.g. unmount) -> active session is disposed
      disposeEffect();
      expect(disposedList, ['Session(wss://server-1)', 'Session(wss://server-2)']);
      expect(untracked.state(sessionBloom).isEmpty, isTrue);
    });

    test('BloomCollectionExtension extracts data and dataOrNull with fail-fast validation', () {
      final r1 = BloomController(10);
      final r2 = BloomController(20);
      final rEmpty = BloomController<int>.late();
      final rError = Bloom<int>.error('Err');

      final validList = [r1, r2];
      expect(validList.data.toList(), [10, 20]);
      expect(validList.dataOrNull.toList(), [10, 20]);

      final mixedList = [r1, rEmpty, untracked.state(rError)];
      expect(mixedList.dataOrNull.toList(), [10, null, null]);
      expect(() => mixedList.data.toList(), throwsA(isA<BloomSnapshotExtractionException>()));
    });

    test('Bloom.computed with distinct and custom comparator suppresses downstream effect executions', () async {
      final user = BloomController((name: 'Alice', score: 100));
      var effectRuns = 0;
      String? observedName;

      // Select name only; changes in score should not trigger effect
      final nameBloom = computed((via) => via(user.bloom).name).distinct();

      final dispose = effect((via) {
        effectRuns++;
        observedName = via(nameBloom);
      });

      await Future<void>.delayed(Duration.zero);
      expect(effectRuns, 1);
      expect(observedName, 'Alice');

      // Mutate score only -> name remains 'Alice'
      user.data = (name: 'Alice', score: 200);
      await Future.microtask(() {});

      expect(effectRuns, 1); // No re-run!
      expect(observedName, 'Alice');

      // Mutate name -> triggers effect
      user.data = (name: 'Bob', score: 200);
      await Future.microtask(() {});

      expect(effectRuns, 2);
      expect(observedName, 'Bob');

      dispose();
    });

    test('Bloom.computed with guard dynamically blocks and restores downstream pipeline based on condition', () async {
      final allowed = BloomController(false);
      final query = BloomController('sensitive_data');
      final guarded = computed(
        (via) => via(query.bloom),
        guard: (via) => via(allowed.bloom).guarded('Access Denied'),
      );

      var effectRuns = 0;
      final dispose = effect((via) {
        effectRuns++;
        via.state(guarded).dataOrNull;
      });

      await Future<void>.delayed(Duration.zero);
      expect(effectRuns, 1);
      expect(untracked.state(guarded).isEmpty, isTrue);
      expect(untracked.state(guarded).snapshot.emptyReason, 'Access Denied');
      expect(untracked.state(guarded).dataOrNull, isNull);

      // Change permission & update query
      allowed.data = true;
      query.data = 'sensitive_data_v2';
      await Future.microtask(() {});

      expect(effectRuns, 2);
      expect(untracked.state(guarded).hasData, isTrue);
      expect(untracked(guarded), 'sensitive_data_v2');

      dispose();
    });

    test('bloom.resource with graceful=true defers disposal to microtask', () async {
      final source = BloomController('res_1');
      var disposedResource = '';

      final derivedRes = managed<String>(
        create: (via) => 'Managed(${via(source.bloom)})',
        dispose: (res) => disposedResource = res,
        graceful: const Graceful(),
      );

      final dispose = effect((via) {
        via(derivedRes);
      });

      await Future<void>.delayed(Duration.zero);
      expect(untracked(derivedRes), 'Managed(res_1)');

      // Unsubscribe (deactivate)
      dispose();

      // Graceful = true defers disposal; NOT synchronously disposed yet
      expect(disposedResource, '');

      // After microtask runs -> disposed!
      await Future.microtask(() {});
      expect(disposedResource, 'Managed(res_1)');
    });

    test('bloom.resource dispose cleans up resources on update or deactivation', () async {
      final source = BloomController('initial_endpoint');
      final disposals = <String>[];

      final derivedRes = managed<String>(
        create: (via) => 'Client(${via(source.bloom)})',
        update: (via, current) => 'Client(${via(source.bloom)})',
        dispose: (res) {
          disposals.add(res);
        },
      );

      final dispose = effect((via) {
        via(derivedRes);
      });

      await Future<void>.delayed(Duration.zero);
      expect(untracked(derivedRes), 'Client(initial_endpoint)');
      expect(disposals, isEmpty);

      source.set('new_endpoint');
      expect(untracked(derivedRes), 'Client(new_endpoint)');
      expect(disposals, equals(['Client(initial_endpoint)']));

      dispose();
      expect(
          disposals,
          equals([
            'Client(initial_endpoint)',
            'Client(new_endpoint)',
          ]));
    });

    test('Bloom and BloomListController check physical node identity via identical', () {
      final bloom1 = Bloom.constant(100);
      final bloom2 = Bloom.constant(100);

      final r1 = bloom1;
      final r2 = bloom1;
      final r3 = bloom2;

      final writable = BloomController(100);
      final bloomView = writable.bloom;

      expect(identical(r1, r2), isTrue);
      expect(identical(r1, r3), isFalse);
      expect(identical(writable, bloomView), isFalse);
      expect(identical(writable, r1), isFalse);
      expect(() => (writable.bloom as dynamic) as BloomController, throwsA(isA<TypeError>()));

      final group1 = Bloom.constant([bloom1]);
      final group2 = Bloom.constant([bloom1]);

      final rs1 = group1;
      final rs2 = group1;
      final rs3 = group2;

      final writableGroup = blooming.list([bloom1]);
      final groupView = writableGroup.bloom;

      expect(identical(rs1, rs2), isTrue);
      expect(identical(rs1, rs3), isFalse);
      expect(identical(writableGroup, groupView), isFalse);
      expect(identical(writableGroup, rs1), isFalse);
      expect(() => (writableGroup.bloom as dynamic) as BloomDraftController, throwsA(isA<TypeError>()));
    });
  });
}

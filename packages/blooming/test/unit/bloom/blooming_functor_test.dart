// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

void main() {
  group('Hierarchical blooming Functor Suite', () {
    // =========================================================================
    // 1. Const Singleton Sub-Functor Identity (0-Alloc Proof)
    // =========================================================================
    test('1.1 sub-functor getters return canonical identical compile-time singletons', () {
      expect(identical(blooming.raw, blooming.raw), isTrue);
      expect(identical(blooming.list, blooming.list), isTrue);
      expect(identical(blooming.set, blooming.set), isTrue);
      expect(identical(blooming.map, blooming.map), isTrue);
      expect(identical(blooming.signal, blooming.signal), isTrue);
    });

    // =========================================================================
    // 2. Primary Distinct Scalar Functor (blooming, .late, .error)
    // =========================================================================
    group('2. Scalar Functor: blooming(...)', () {
      test('2.1 blooming(value) initializes active BloomController with distinct filtering', () {
        final count = blooming(10);
        expect(count, isA<BloomController<int>>());
        expect(count.data, 10);
        expect(count.hasData, isTrue);

        count.data = 20;
        expect(count.data, 20);

        count.set(30);
        expect(count.data, 30);
      });

      test('2.2 blooming.late() initializes empty state and transitions upon set', () {
        final user = blooming.late<String>(reason: 'AwaitingLogin');
        expect(user, isA<BloomController<String>>());
        expect(user.isEmpty, isTrue);
        expect(user.emptyReason, 'AwaitingLogin');
        expect(() => user.data, throwsA(isA<BloomSnapshotExtractionException>()));

        user.set('Alice');
        expect(user.hasData, isTrue);
        expect(user.data, 'Alice');
      });

      test('2.3 blooming.error() initializes error state and transitions upon set', () {
        final errorNode = blooming.error<int>(Exception('FailedToLoad'));
        expect(errorNode, isA<BloomController<int>>());
        expect(errorNode.hasError, isTrue);
        expect(errorNode.error.toString(), contains('FailedToLoad'));

        errorNode.set(100);
        expect(errorNode.hasData, isTrue);
        expect(errorNode.data, 100);
      });

      test('2.4 blooming(...) respects distinct suppression and custom equals', () {
        int activations = 0;
        int deactivations = 0;
        final c = blooming<int>(
          0,
          onActivated: () => activations++,
          onDeactivated: () => deactivations++,
        );

        final terminal = RawBloomTerminal(c.bloom, onInvalidated: () {});
        expect(activations, 0);

        terminal.activate();
        expect(activations, 1);
        expect(terminal.data, 0);

        // Same value -> distinct suppresses notification
        c.data = 0;
        expect(terminal.data, 0);

        // Changed value -> pushes dirty
        c.data = 5;
        expect(terminal.data, 5);

        terminal.deactivate();
        expect(deactivations, 1);
      });
    });

    // =========================================================================
    // 3. Raw Sub-Functor (blooming.raw, .late, .error)
    // =========================================================================
    group('3. Raw Functor: blooming.raw(...)', () {
      test('3.1 blooming.raw(data) creates RawBloomController with markDirty support', () {
        final listHolder = blooming.raw(<int>[1, 2, 3]);
        expect(listHolder, isA<RawBloomController<List<int>>>());
        expect(listHolder.data, [1, 2, 3]);

        int computeCount = 0;
        final countBloom = computed((via) {
          computeCount++;
          return via(listHolder.bloom).length;
        });

        final terminal = RawBloomTerminal(countBloom, onInvalidated: () {});
        terminal.activate();
        expect(terminal.data, 3);
        expect(computeCount, 1);

        // In-place mutation + markDirty
        listHolder.data.add(4);
        listHolder.markDirty();

        expect(terminal.data, 4);
        expect(computeCount, 2);

        terminal.deactivate();
      });

      test('3.2 blooming.raw.late() and blooming.raw.error() instantiate raw controllers', () {
        final lateRaw = blooming.raw.late<String>(reason: 'DeferredRaw');
        expect(lateRaw, isA<RawBloomController<String>>());
        expect(lateRaw.isEmpty, isTrue);
        expect(lateRaw.emptyReason, 'DeferredRaw');

        final errorRaw = blooming.raw.error<String>('RawFailure');
        expect(errorRaw, isA<RawBloomController<String>>());
        expect(errorRaw.hasError, isTrue);
      });
    });

    // =========================================================================
    // 4. Reactive List Sub-Functor (blooming.list, .late, .error)
    // =========================================================================
    group('4. List Functor: blooming.list(...)', () {
      test('4.1 blooming.list(items) creates BloomListController with transactional edit', () {
        final todos = blooming.list<String>(['A', 'B']);
        expect(todos, isA<BloomListController<String>>());
        expect(todos.data, ['A', 'B']);
        expect(() => todos.data.add('C'), throwsUnsupportedError);

        todos.edit((draft) {
          draft.add('C');
          draft.remove('A');
        });
        expect(todos.data, ['B', 'C']);
      });

      test('4.2 blooming.list.late() and blooming.list.error()', () {
        final lateList = blooming.list.late<int>();
        expect(lateList, isA<BloomListController<int>>());
        expect(lateList.isEmpty, isTrue);

        lateList.set([10, 20]);
        expect(lateList.data, [10, 20]);

        final errorList = blooming.list.error<int>('ListLoadFailed');
        expect(errorList, isA<BloomListController<int>>());
        expect(errorList.hasError, isTrue);
      });
    });

    // =========================================================================
    // 5. Reactive Set Sub-Functor (blooming.set, .late, .error)
    // =========================================================================
    group('5. Set Functor: blooming.set(...)', () {
      test('5.1 blooming.set(items) creates BloomSetController with transactional edit', () {
        final tags = blooming.set<String>({'alpha', 'beta'});
        expect(tags, isA<BloomSetController<String>>());
        expect(tags.data, {'alpha', 'beta'});
        expect(() => tags.data.add('gamma'), throwsUnsupportedError);

        tags.edit((draft) {
          draft.add('gamma');
          draft.remove('alpha');
        });
        expect(tags.data, {'beta', 'gamma'});
      });

      test('5.2 blooming.set.late() and blooming.set.error()', () {
        final lateSet = blooming.set.late<String>();
        expect(lateSet, isA<BloomSetController<String>>());
        expect(lateSet.isEmpty, isTrue);

        lateSet.set({'x', 'y'});
        expect(lateSet.data, {'x', 'y'});

        final errorSet = blooming.set.error<String>('SetLoadFailed');
        expect(errorSet, isA<BloomSetController<String>>());
        expect(errorSet.hasError, isTrue);
      });
    });

    // =========================================================================
    // 6. Reactive Map Sub-Functor (blooming.map, .late, .error)
    // =========================================================================
    group('6. Map Functor: blooming.map(...)', () {
      test('6.1 blooming.map(dict) creates BloomMapController with transactional edit', () {
        final config = blooming.map<String, int>({'timeout': 30});
        expect(config, isA<BloomMapController<String, int>>());
        expect(config.data, {'timeout': 30});
        expect(() => config.data['retries'] = 3, throwsUnsupportedError);

        config.edit((draft) {
          draft['retries'] = 3;
          draft['timeout'] = 60;
        });
        expect(config.data, {'timeout': 60, 'retries': 3});
      });

      test('6.2 blooming.map.late() and blooming.map.error()', () {
        final lateMap = blooming.map.late<String, String>();
        expect(lateMap, isA<BloomMapController<String, String>>());
        expect(lateMap.isEmpty, isTrue);

        lateMap.set({'k': 'v'});
        expect(lateMap.data, {'k': 'v'});

        final errorMap = blooming.map.error<String, String>('MapFailed');
        expect(errorMap, isA<BloomMapController<String, String>>());
        expect(errorMap.hasError, isTrue);
      });
    });

    // =========================================================================
    // 7. Event Signal Sub-Functor (blooming.signal)
    // =========================================================================
    group('7. Signal Functor: blooming.signal(...)', () {
      test('7.1 blooming.signal() creates BloomSignalController and emits monotonic pulses', () {
        final trigger = blooming.signal();
        expect(trigger, isA<BloomSignalController>());

        int pulseCount = 0;
        final derivation = computed((via) {
          via(trigger.bloom);
          pulseCount++;
          return pulseCount;
        });

        final terminal = RawBloomTerminal(derivation, onInvalidated: () {});
        terminal.activate();
        expect(terminal.data, 1);

        trigger.emit();
        expect(terminal.data, 2);

        trigger.emit();
        expect(terminal.data, 3);

        terminal.deactivate();
      });
    });
  });
}

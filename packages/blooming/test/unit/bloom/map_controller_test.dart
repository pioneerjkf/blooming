// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

void main() {
  group('BloomMapController & Reactive Map Evolution Tests', () {
    // =========================================================================
    // 1. Instantiation & Factory Constructors
    // =========================================================================
    group('1. Instantiation & Factory Constructors', () {
      test('1.1 BloomMapController default factory creates unmodifiable map', () {
        final controller = blooming.map<String, int>({'a': 1, 'b': 2});

        expect(controller.hasData, isTrue);
        expect(controller.data, equals({'a': 1, 'b': 2}));
        expect(untracked(controller.bloom), equals({'a': 1, 'b': 2}));

        // Immutability check: data must be unmodifiable
        expect(() => controller.data['c'] = 3, throwsUnsupportedError);
      });

      test('1.2 BloomMapController empty explicit initialization', () {
        final controller = blooming.map<String, int>({});

        expect(controller.hasData, isTrue);
        expect(controller.data, isEmpty);
      });

      test('1.3 BloomMapController.late initialization', () {
        final controller = blooming.map.late<String, int>();

        expect(controller.isEmpty, isTrue);
        expect(controller.hasData, isFalse);
        expect(() => controller.data, throwsA(isA<BloomSnapshotExtractionException>()));

        controller.set({'x': 10, 'y': 20});
        expect(controller.hasData, isTrue);
        expect(controller.data, equals({'x': 10, 'y': 20}));
      });

      test('1.4 BloomMapController.error initialization', () {
        final controller = blooming.map.error<String, int>('Failed to load map');

        expect(controller.hasError, isTrue);
        expect(controller.hasData, isFalse);
        expect(controller.error, equals('Failed to load map'));
      });
    });

    // =========================================================================
    // 2. Immutable Whole Replacement (.set, .data =)
    // =========================================================================
    group('2. Immutable Whole Replacement (.set, .data =)', () {
      test('2.1 Whole replacement updates payload and notifies downstream', () {
        final controller = blooming.map<String, int>({'a': 1});
        var notifyCount = 0;
        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () {
          notifyCount++;
        });
        terminal.activate();

        expect(notifyCount, equals(0));

        controller.set({'b': 2, 'c': 3});
        expect(notifyCount, equals(1));
        expect(controller.data, equals({'b': 2, 'c': 3}));

        controller.data = {'d': 4};
        expect(notifyCount, equals(2));
        expect(controller.data, equals({'d': 4}));

        terminal.deactivate();
      });

      test('2.2 _mapEquals suppresses redundant Push-Dirty pulses on identical entries', () {
        final controller = blooming.map<String, int>({'a': 1, 'b': 2});
        var notifyCount = 0;
        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () {
          notifyCount++;
        });
        terminal.activate();

        // Assigning a new map instance with identical entries
        controller.set({'a': 1, 'b': 2});
        expect(notifyCount, equals(0), reason: 'Identical entries must suppress dirty pulse');

        controller.data = {'b': 2, 'a': 1};
        expect(notifyCount, equals(0), reason: 'Different insertion order but same entries must suppress dirty pulse');

        // Modifying one value must trigger notification
        controller.set({'a': 1, 'b': 99});
        expect(notifyCount, equals(1));

        // Adding a new key must trigger notification
        controller.set({'a': 1, 'b': 99, 'c': 3});
        expect(notifyCount, equals(2));

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 3. Transactional Draft Edit (.edit((draft) => ...))
    // =========================================================================
    group('3. Transactional Draft Edit (.edit)', () {
      test('3.1 Single draft modification applies atomically and freezes result', () {
        final controller = blooming.map<String, String>({'theme': 'light'});
        var notifyCount = 0;
        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () {
          notifyCount++;
        });
        terminal.activate();

        controller.edit((draft) {
          draft['theme'] = 'dark';
        });

        expect(notifyCount, equals(1));
        expect(controller.data, equals({'theme': 'dark'}));
        expect(() => controller.data['theme'] = 'solarized', throwsUnsupportedError);

        terminal.deactivate();
      });

      test('3.2 Multiple operations inside edit emit AT MOST 1 dirty pulse (Atomic Commit)', () {
        final controller = blooming.map<String, int>({'k1': 1, 'k2': 2});
        var notifyCount = 0;
        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () {
          notifyCount++;
        });
        terminal.activate();

        controller.edit((draft) {
          draft['k3'] = 3;
          draft['k4'] = 4;
          draft.remove('k1');
        });

        expect(notifyCount, equals(1));
        expect(controller.data, equals({'k2': 2, 'k3': 3, 'k4': 4}));

        terminal.deactivate();
      });

      test('3.3 No-op edit suppresses Push-Dirty pulse completely', () {
        final controller = blooming.map<String, int>({'x': 10});
        var notifyCount = 0;
        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () {
          notifyCount++;
        });
        terminal.activate();

        controller.edit((draft) {
          // Re-assign same value
          draft['x'] = 10;
        });

        expect(notifyCount, equals(0), reason: 'No-op edit must not emit dirty pulse');
        terminal.deactivate();
      });

      test('3.4 edit on late() controller starts with empty map', () {
        final controller = blooming.map.late<String, int>();
        expect(controller.isEmpty, isTrue);

        controller.edit((draft) {
          draft['first'] = 1;
        });

        expect(controller.hasData, isTrue);
        expect(controller.data, equals({'first': 1}));
      });

      test('3.5 edit on error controller transitions to valid data', () {
        final controller = blooming.map.error<String, int>('Initial error');
        expect(controller.hasError, isTrue);

        controller.edit((draft) {
          draft['recovered'] = 42;
        });

        expect(controller.hasData, isTrue);
        expect(controller.data, equals({'recovered': 42}));
      });

      test('3.6 edit failure preserves original state and rethrows (Atomicity / Rollback)', () {
        final controller = blooming.map<String, int>({'a': 1, 'b': 2});
        var notifyCount = 0;
        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () {
          notifyCount++;
        });
        terminal.activate();

        expect(
          () => controller.edit((draft) {
            draft['c'] = 3;
            throw StateError('Recipe transaction boom!');
          }),
          throwsA(isA<StateError>()),
        );

        // State must remain intact and no dirty pulses must be emitted
        expect(notifyCount, equals(0));
        expect(controller.data, equals({'a': 1, 'b': 2}));

        terminal.deactivate();
      });

      test('3.7 editGuarded successfully updates payload and notifies', () {
        final controller = blooming.map<String, String>({'lang': 'en'});
        var notifyCount = 0;
        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () {
          notifyCount++;
        });
        terminal.activate();

        controller.editGuarded((draft) {
          draft['lang'] = 'ko';
        });

        expect(notifyCount, equals(1));
        expect(controller.data, equals({'lang': 'ko'}));

        terminal.deactivate();
      });

      test('3.8 editGuarded catches exception and safely transitions to error state', () {
        final controller = blooming.map<String, int>({'x': 10});
        var notifyCount = 0;
        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () {
          notifyCount++;
        });
        terminal.activate();

        // Must not throw in caller stack
        controller.editGuarded((draft) {
          draft['y'] = 20;
          throw RangeError('Value invalid');
        });

        expect(notifyCount, equals(1));
        expect(controller.hasError, isTrue);
        expect(controller.hasData, isFalse);
        expect(controller.error, isA<RangeError>());

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 4. Downstream Pipeline & ComputedBloom Integration
    // =========================================================================
    group('4. Downstream Pipeline & ComputedBloom Integration', () {
      test('4.1 ComputedBloom seamlessly tracks BloomMapController edits', () {
        final store = blooming.map<String, int>({'apple': 3});
        final totalFruits = computed((via) => via(store.bloom).values.fold(0, (a, b) => a + b));
        final hasBanana = computed((via) => via(store.bloom).containsKey('banana'));

        final terminal = RawBloomTerminal(totalFruits, onInvalidated: () {});
        terminal.activate();

        expect(untracked(totalFruits), equals(3));
        expect(untracked(hasBanana), isFalse);

        store.edit((draft) {
          draft['banana'] = 5;
          draft['orange'] = 2;
        });

        expect(untracked(totalFruits), equals(10));
        expect(untracked(hasBanana), isTrue);

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 5. Custom Equality for Nested Collections
    // =========================================================================
    group('5. Custom Equality for Nested Collections', () {
      bool deepMapEquals(Map<String, List<int>> a, Map<String, List<int>> b) {
        if (identical(a, b)) return true;
        if (a.length != b.length) return false;
        for (final entry in a.entries) {
          final bVal = b[entry.key];
          if (bVal == null) return false;
          final aVal = entry.value;
          if (aVal.length != bVal.length) return false;
          for (var i = 0; i < aVal.length; i++) {
            if (aVal[i] != bVal[i]) return false;
          }
        }
        return true;
      }

      test('5.1 Custom equals suppresses dirty pulses when nested maps are equal', () {
        final controller = blooming.map<String, List<int>>(
          {
            'nums': [1, 2],
          },
          equals: deepMapEquals,
        );

        var notifyCount = 0;
        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () => notifyCount++);
        terminal.activate();

        controller.set({
          'nums': [1, 2],
        });
        expect(notifyCount, equals(0));

        controller.set({
          'nums': [1, 3],
        });
        expect(notifyCount, equals(1));

        terminal.deactivate();
      });

      test('5.2 BloomMapController.late propagates custom equals comparator', () {
        final controller = blooming.map.late<String, List<int>>(
          equals: deepMapEquals,
        );

        var notifyCount = 0;
        final terminal = RawBloomTerminal(controller.bloom, onInvalidated: () => notifyCount++);
        terminal.activate();

        controller.set({
          'scores': [100],
        });
        expect(notifyCount, equals(1));

        // Setting identical nested contents must not notify
        controller.set({
          'scores': [100],
        });
        expect(notifyCount, equals(1));

        // Setting different nested contents must notify
        controller.set({
          'scores': [200],
        });
        expect(notifyCount, equals(2));

        terminal.deactivate();
      });
    });
  });
}

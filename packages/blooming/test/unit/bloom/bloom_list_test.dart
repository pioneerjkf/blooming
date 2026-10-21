// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

void main() {
  group('Bloom Node List Core, Controller, Snapshot & Operators Unit Tests', () {
    // =========================================================================
    // 1. Bloom Node List BloomSnapshot Tests
    // =========================================================================
    group('1. Bloom Node List BloomSnapshot Core & Invariants', () {
      test('1.1 Valid Bloom node list BloomSnapshot properties and fail-safe getters', () {
        final c1 = Bloom.constant(1);
        final c2 = Bloom.constant(2);
        final snapshot = BloomSnapshot([c1, c2]);

        expect(snapshot.hasData, isTrue);
        expect(snapshot.isEmpty, isFalse);
        expect(snapshot.hasError, isFalse);
        expect(snapshot.data, [c1, c2]);
        expect(snapshot.dataOrNull, [c1, c2]);
        expect(snapshot.dataOrElse(() => const []), [c1, c2]);
      });

      test('1.2 Empty Bloom node list BloomSnapshot throws extraction exception on data', () {
        const snapshot = BloomSnapshot<List<Bloom<int>>>.empty();

        expect(snapshot.isEmpty, isTrue);
        expect(snapshot.hasData, isFalse);
        expect(snapshot.hasError, isFalse);
        expect(snapshot.dataOrNull, isNull);
        expect(snapshot.dataOrElse(() => const []), isEmpty);
        expect(() => snapshot.data, throwsA(isA<BloomSnapshotExtractionException>()));
      });

      test('1.3 Error Bloom node list BloomSnapshot exposes error and throws extraction exception', () {
        final err = const FormatException('Bloom list Error');
        final stack = StackTrace.current;
        final snapshot = BloomSnapshot<List<Bloom<int>>>.error(err, stack);

        expect(snapshot.hasData, isFalse);
        expect(snapshot.isEmpty, isFalse);
        expect(snapshot.hasError, isTrue);
        expect(snapshot.error, same(err));
        expect(snapshot.stackTrace, same(stack));
        expect(snapshot.dataOrNull, isNull);
        expect(snapshot.dataOrElse(() => const []), isEmpty);
        expect(() => snapshot.data, throwsA(isA<BloomSnapshotExtractionException>()));
      });
    });

    // =========================================================================
    // 2. Bloom Node List Factory Constructors
    // =========================================================================
    group('2. Bloom Node List Factory Constructors', () {
      test('2.1 Bloom.constant creates valid sealed list', () {
        final c1 = Bloom.constant('x');
        final c2 = Bloom.constant('y');
        final group = Bloom.constant([c1, c2]);

        final terminal = RawBloomTerminal(group, onInvalidated: () {});
        terminal.activate();

        expect(untracked.state(group).hasData, isTrue);
        expect(untracked.state(group).isEmpty, isFalse);
        expect(untracked.state(group).hasError, isFalse);
        expect(untracked(group), [c1, c2]);

        terminal.deactivate();
      });

      test('2.2 Bloom.constant supports composite nested lists', () {
        final c1 = Bloom.constant('a');
        final c2 = Bloom.constant('b');

        final s1 = Bloom.constant([c1]);
        final s2 = Bloom.constant([c2]);

        final compositeGroup = Bloom.constant([s1, s2]);

        expect(untracked.state(compositeGroup).hasData, isTrue);
        expect(untracked(compositeGroup), [s1, s2]);
        expect(untracked.state(Bloom.constant([c1, c2])).hasData, isTrue);
      });

      test('2.3 Bloom.empty and Bloom.error factories for lists', () {
        final groupEmpty = Bloom<List<Bloom<int>>>.empty();
        expect(untracked.state(groupEmpty).isEmpty, isTrue);
        expect(untracked.state(groupEmpty).hasData, isFalse);
        expect(untracked.state(groupEmpty).dataOrElse(() => const []), isEmpty);

        final groupError = Bloom<List<Bloom<int>>>.error('Error in group');
        expect(untracked.state(groupError).hasError, isTrue);
        expect(untracked.state(groupError).hasData, isFalse);
        expect(untracked.state(groupError).error, 'Error in group');
      });
    });

    // =========================================================================
    // 3. BloomListController Tests
    // =========================================================================
    group('3. BloomListController Lifecycle & Mutation', () {
      test('3.1 Standard BloomListController initialization and set mutation', () {
        final bloom1 = BloomController<int>(10);
        final bloom2 = BloomController<int>(20);
        final controller = BloomListController<Bloom<int>>([bloom1.bloom, bloom2.bloom]);

        expect(controller.hasData, isTrue);
        expect(controller.data.length, equals(2));
        expect(untracked.state(controller.data[0]).snapshot.data, equals(10));
        expect(untracked.state(controller.data[1]).snapshot.data, equals(20));

        final bloom3 = BloomController<int>(30);
        controller.set([bloom3.bloom]);

        expect(controller.data.length, equals(1));
        expect(untracked.state(controller.data[0]).snapshot.data, equals(30));
      });

      test('3.2 BloomListController.late initialization and delayed set', () {
        final controller = BloomListController<Bloom<int>>.late();

        expect(controller.isEmpty, isTrue);
        expect(controller.hasData, isFalse);
        expect(() => controller.data, throwsA(isA<BloomSnapshotExtractionException>()));

        final bloom1 = BloomController<int>(100);
        controller.set([bloom1.bloom]);

        expect(controller.hasData, isTrue);
        expect(controller.data.length, equals(1));
        expect(untracked.state(controller.data[0]).snapshot.data, equals(100));
      });

      test('3.3 BloomListController setGuarded, setError, and empty', () {
        final controller = BloomListController<Bloom<int>>.late();

        controller.setGuarded(() => throw Exception('Calculation error'));
        expect(controller.hasError, isTrue);
        expect(controller.hasData, isFalse);
        expect(controller.error, isA<Exception>());

        final bloom1 = BloomController<int>(50);
        controller.setGuarded(() => [bloom1.bloom]);
        expect(controller.hasData, isTrue);
        expect(controller.data.length, equals(1));

        controller.setError('Manual Error');
        expect(controller.hasError, isTrue);
        expect(controller.hasData, isFalse);
        expect(controller.error, equals('Manual Error'));

        controller.empty();
        expect(controller.isEmpty, isTrue);
        expect(controller.hasData, isFalse);
      });

      test('3.4 BloomListController does not emit dirty when identical node elements are re-assigned (_nodeListEquals)',
          () {
        final a = Bloom.constant(1);
        final b = Bloom.constant(2);
        final group = BloomListController([a, b]);

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(group.bloom, onInvalidated: () => dirtyCount++);
        terminal.activate();
        expect(dirtyCount, 0);

        // Re-assign identical list instance
        group.set([a, b]);
        expect(dirtyCount, 0); // [Suppressed]

        // In-place assignment via data setter
        group.data = [a, b];
        expect(dirtyCount, 0); // [Suppressed]

        // Actual modification
        final c = Bloom.constant(3);
        group.set([a, c]);
        expect(dirtyCount, 1);

        terminal.deactivate();
      });

      test('3.5 Bloom node list data guarantees unmodifiable list', () {
        final a = Bloom.constant(1);
        final group = BloomListController([a]);

        expect(() => (group.data as dynamic).add(Bloom.constant(2)), throwsUnsupportedError);
      });

      test('3.6 BloomListController handles standard data assignment and setGuarded', () {
        final a = Bloom.constant(1);
        final b = Bloom.constant(2);
        final c = Bloom.constant(3);
        final group = BloomListController([a]);

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(group.bloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        // data = assignment
        group.data = [...group.data, b];
        expect(dirtyCount, 1);
        expect(terminal.data, [a, b]);

        // remove via list filtering
        group.data = group.data.where((e) => !identical(e, a)).toList();
        expect(dirtyCount, 2);
        expect(terminal.data, [b]);

        // re-assigning identical elements emits zero dirty pulses
        group.data = [b];
        expect(dirtyCount, 2);
        expect(terminal.data, [b]);

        // setGuarded executes safely and emits single dirty pulse
        group.setGuarded(() {
          return [...group.data, c, a];
        });
        expect(dirtyCount, 3);
        expect(terminal.data, [b, c, a]);

        // setGuarded catches exception and transitions to error state
        group.setGuarded(() => throw Exception('Calculation Error'));
        expect(group.hasError, isTrue);

        terminal.deactivate();
      });

      test('3.7 BloomListController.late handles set and setGuarded safely', () {
        final group = BloomListController<Bloom<int>>.late();
        expect(group.isEmpty, isTrue);

        final a = Bloom.constant(10);
        group.set([a]);
        expect(group.hasData, isTrue);
        expect(group.data, [a]);

        group.empty();
        expect(group.isEmpty, isTrue);

        group.setGuarded(() => [a]);
        expect(group.hasData, isTrue);
        expect(group.data, [a]);
      });

      test('3.8 BloomListController<int> manages primitive value lists with distinct shallow equality', () {
        final group = BloomListController<int>([1, 2, 3]);
        expect(group.hasData, isTrue);
        expect(group.data, [1, 2, 3]);

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(group.bloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        // Assigning new list with same values suppresses dirty pulse (distinct)
        group.set([1, 2, 3]);
        expect(dirtyCount, 0);

        // Assigning new list with changed values triggers dirty pulse
        group.set([1, 2, 4]);
        expect(dirtyCount, 1);
        expect(terminal.data, [1, 2, 4]);

        // Aggregate operator works seamlessly on primitive list
        final sum = group.bloom.aggregate((nums) => nums.reduce((a, b) => a + b));
        expect(untracked(sum), 7);

        terminal.deactivate();
      });

      test('3.9 aggregate works polymorphically on Bloom<Set<T>> and Bloom<Iterable<T>>', () {
        final setBloom = BloomController<Set<int>>({10, 20, 30});
        final total = setBloom.bloom.aggregate((elements) => elements.fold<int>(0, (a, b) => a + b));
        expect(untracked(total), 60);

        setBloom.set({10, 20, 40});
        expect(untracked(total), 70);
      });
    });

    // =========================================================================
    // 4. Bloom Node List Operators (combine, fold, reduce, sum, every, any)
    // =========================================================================
    group('4. Bloom Node List Operators & Combinators', () {
      test('4.1 computed aggregation reduces group elements into a single scalar bloom', () {
        final c1 = Bloom.constant(10);
        final c2 = Bloom.constant(20);
        final c3 = Bloom.constant(30);
        final group = Bloom.constant([c1, c2, c3]);

        final aggregated = computed((via) => via(group).fold<int>(0, (sum, item) => sum + via(item)));
        final terminal = RawBloomTerminal(aggregated, onInvalidated: () {});
        terminal.activate();

        expect(untracked(aggregated), 60);

        terminal.deactivate();
      });

      test('4.2 combine bundles all element data into Bloom<List<T>>', () {
        final c1 = Bloom.constant('apple');
        final c2 = Bloom.constant('banana');
        final group = Bloom.constant([c1, c2]);

        final combined = group.combine();
        final terminal = RawBloomTerminal(combined, onInvalidated: () {});
        terminal.activate();

        expect(untracked(combined), ['apple', 'banana']);

        terminal.deactivate();
      });

      test('4.3 computed conditionally returns a value based on group elements', () {
        final c1 = BloomController<int>(10);
        final c2 = BloomController<int>(20);
        final group = BloomListController([c1.bloom, c2.bloom]);

        final converged = computed((via) {
          final sum = via(group.bloom).fold<int>(0, (acc, g) => acc + via(g));
          return sum > 25 ? 'HIGH' : 'LOW';
        });

        final terminal = RawBloomTerminal(converged, onInvalidated: () {});
        terminal.activate();

        expect(untracked(converged), 'HIGH');

        c1.set(0);
        c2.set(10);
        expect(untracked(converged), 'LOW');

        terminal.deactivate();
      });

      test('4.4 fold operator reduces values iteratively with an initial seed', () {
        final g1 = Bloom.constant(1);
        final g2 = Bloom.constant(2);
        final g3 = Bloom.constant(3);
        final group = Bloom.constant([g1, g2, g3]);

        final folded = group.fold<int>(100, (acc, val) => acc + val);
        final terminal = RawBloomTerminal(folded, onInvalidated: () {});
        terminal.activate();

        expect(untracked(folded), 106);
        terminal.deactivate();
      });

      test('4.5 reduce operator iteratively combines all values without an initial seed', () {
        final g1 = Bloom.constant('a');
        final g2 = Bloom.constant('b');
        final g3 = Bloom.constant('c');
        final group = Bloom.constant([g1, g2, g3]);

        final reduced = group.reduce((acc, val) => '$acc-$val');
        final terminal = RawBloomTerminal(reduced, onInvalidated: () {});
        terminal.activate();

        expect(untracked(reduced), 'a-b-c');
        terminal.deactivate();
      });

      test('4.6 sum operator calculates arithmetic sum for numeric groups (num, int, double)', () {
        final n1 = Bloom.constant(10);
        final n2 = Bloom.constant(25);
        final groupInt = Bloom.constant([n1, n2]);
        final sumInt = groupInt.sum();

        final d1 = Bloom.constant(1.5);
        final d2 = Bloom.constant(2.5);
        final groupDouble = Bloom.constant([d1, d2]);
        final sumDouble = groupDouble.sum();

        final tInt = RawBloomTerminal(sumInt, onInvalidated: () {});
        final tDouble = RawBloomTerminal(sumDouble, onInvalidated: () {});
        tInt.activate();
        tDouble.activate();

        expect(untracked(sumInt), 35);
        expect(untracked(sumDouble), 4.0);

        tInt.deactivate();
        tDouble.deactivate();
      });

      test('4.7 every and any boolean logical reduction operators', () {
        final g1 = BloomController<int>(10);
        final g2 = BloomController<int>(20);
        final group = Bloom.constant([g1.bloom, g2.bloom]);

        final allEven = group.every((x) => x % 2 == 0);
        final anyGreaterThan15 = group.any((x) => x > 15);

        final tEvery = RawBloomTerminal(allEven, onInvalidated: () {});
        final tAny = RawBloomTerminal(anyGreaterThan15, onInvalidated: () {});
        tEvery.activate();
        tAny.activate();

        expect(untracked(allEven), isTrue);
        expect(untracked(anyGreaterThan15), isTrue);

        g1.set(11);
        expect(untracked(allEven), isFalse);

        g2.set(10);
        expect(untracked(anyGreaterThan15), isFalse);

        tEvery.deactivate();
        tAny.deactivate();
      });
    });

    // =========================================================================
    // 5. Complex Bloom Node List Lifecycle & Dynamic Topology Integration
    // =========================================================================
    group('5. Complex Bloom Node List Topology & Dynamic Lifecycle', () {
      test('5.1 Dynamic Bloom node list elements mutating trigger single dirty notification via combined pipeline', () {
        final c1 = BloomController<int>(1);
        final c2 = BloomController<int>(2);
        final group = Bloom.constant([c1.bloom, c2.bloom]);

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(group.combine(), onInvalidated: () {
          dirtyCount++;
        });

        terminal.activate();
        expect(dirtyCount, 0);
        expect(terminal.data, [1, 2]);

        c1.set(10);
        expect(dirtyCount, 1);

        // Pull to clear dirty
        expect(terminal.data, [10, 2]);

        c2.set(20);
        expect(dirtyCount, 2);
        expect(terminal.data, [10, 20]);

        terminal.deactivate();
      });

      test('5.2 Bloom node list combine reacts lazily to inner controllers while active', () {
        final c1 = BloomController<String>('A');
        final c2 = BloomController<String>('B');
        final group = Bloom.constant([c1.bloom, c2.bloom]);
        final combined = group.combine();

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(combined, onInvalidated: () {
          dirtyCount++;
        });

        expect(dirtyCount, 0);
        terminal.activate();

        expect(untracked(combined), ['A', 'B']);

        c1.set('Alpha');
        expect(dirtyCount, 1);

        // Compute only on pull
        expect(untracked(combined), ['Alpha', 'B']);

        terminal.deactivate();
      });

      test('5.3 Dynamic Re-parenting in BloomListController (Swap In, Swap Out & Mooring GC)', () {
        final g1 = BloomController<String>('Item 1');
        final g2 = BloomController<String>('Item 2');
        final g3 = BloomController<String>('Item 3');

        final groupController = BloomListController<Bloom<String>>([g1.bloom, g2.bloom]);
        int dirtyCount = 0;
        final complexTerminal = RawBloomTerminal(groupController.bloom.combine(), onInvalidated: () => dirtyCount++);

        complexTerminal.activate();
        expect(complexTerminal.data.length, 2);

        // Swap topology: [g1, g2] -> [g2, g3] (g1 removed, g3 added)
        groupController.set([g2.bloom, g3.bloom]);
        expect(dirtyCount, 1);
        expect(complexTerminal.data.length, 2);

        // Reset dirty counter
        dirtyCount = 0;

        // Mutate detached g1 -> MUST NOT trigger notification
        g1.set('Item 1 Mutated Detached');
        expect(dirtyCount, 0);

        // Mutate retained g2 -> MUST trigger notification
        g2.set('Item 2 Updated');
        expect(dirtyCount, 1);
        expect(complexTerminal.data.length, 2);

        // Mutate newly added g3 -> MUST trigger notification
        g3.set('Item 3 Updated');
        expect(dirtyCount, 2);

        complexTerminal.deactivate();
      });

      test('5.4 Nested Bloom Node List Hierarchy: List of Lists with Deep Leaf Mutations', () {
        final leafA1 = BloomController<String>('A1');
        final leafA2 = BloomController<String>('A2');
        final leafB1 = BloomController<String>('B1');

        final groupA = Bloom.constant([leafA1.bloom, leafA2.bloom]);
        final groupB = Bloom.constant([leafB1.bloom]);

        final rootGroup = Bloom.constant([groupA, groupB]);
        final rootCombined = computed(
          (via) => via(rootGroup).expand((s) => via(s.combine())).toList(),
        );

        int rootDirtyCount = 0;
        final rootTerminal = RawBloomTerminal(rootCombined, onInvalidated: () => rootDirtyCount++);
        rootTerminal.activate();

        expect(rootTerminal.data.length, 3);

        leafA1.set('A1-v2');
        expect(rootDirtyCount, 1);
        expect(rootTerminal.data.first, 'A1-v2');

        leafA1.set('A1-v3');
        expect(rootDirtyCount, 2);
        expect(rootTerminal.data.first, 'A1-v3');

        leafB1.set('B1-v2');
        expect(rootDirtyCount, 3);
        expect(rootTerminal.data.last, 'B1-v2');

        rootTerminal.deactivate();
      });

      test('5.5 Single element transitioning to Error and recovering to Valid in Bloom node list', () {
        final g1 = BloomController<int>(10);
        final g2 = BloomController<int>(20);

        final group = Bloom.constant([g1.bloom, g2.bloom]);
        final combined = group.combine();

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(combined, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.snapshot.hasData, isTrue);

        g1.setError('Database connection lost');
        expect(dirtyCount, 1);
        expect(terminal.snapshot.hasError, isTrue);

        g1.set(15);
        expect(dirtyCount, 2);
        expect(terminal.snapshot.hasData, isTrue);

        g1.set(25);
        expect(dirtyCount, 3);

        terminal.deactivate();
      });

      test('5.6 BloomListController downstream pipeline integration via computed', () {
        final c1 = BloomController<int>(10);
        final c2 = BloomController<int>(20);
        final groupController = BloomListController<Bloom<int>>([c1.bloom, c2.bloom]);

        final sumBloom = computed(
          (via) => via(groupController.bloom).fold<int>(0, (int sum, item) => sum + via(item)),
        );

        var dirtyCount = 0;
        final terminal = RawBloomTerminal(sumBloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.data, equals(30));

        c1.set(15);
        expect(dirtyCount, equals(1));
        expect(terminal.data, equals(35));

        final c3 = BloomController<int>(100);
        groupController.set([c1.bloom, c2.bloom, c3.bloom]);
        expect(dirtyCount, equals(2));
        expect(terminal.data, equals(135));

        terminal.deactivate();
      });

      test('5.7 BloomListController multiple heterogeneous elements creates active reactive Bloom node list', () {
        final c1 = BloomController<int>(10);
        final c2 = BloomController<String>('hello');
        final c3 = BloomController<bool>(true);
        final c4 = BloomController<double>(3.14);
        final c5 = BloomController<int>(50);

        final group = BloomListController<Bloom<dynamic>>([c1.bloom, c2.bloom, c3.bloom, c4.bloom, c5.bloom]);
        expect(group.hasData, isTrue);
        expect(group.data.length, 5);

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(group.bloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        group.set([c1.bloom, c2.bloom]);
        expect(dirtyCount, 1);
        expect(terminal.data.length, 2);

        group.set([c1.bloom, c2.bloom, c3.bloom, c4.bloom, c5.bloom]);
        expect(dirtyCount, 2);
        expect(terminal.data.length, 5);

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 6. Unified Collection Convenience Extensions (bloom.dart export)
    // =========================================================================
    group('6. Unified Collection Convenience Extensions (Single Entrypoint)', () {
      test('6.1 Iterable<BloomState<T>> via untracked.state data and dataOrNull extract values correctly', () {
        final w1 = Bloom.constant(10);
        final w2 = Bloom.constant(20);
        final w3 = Bloom<int>.empty();
        final list = [untracked.state(w1), untracked.state(w2)];

        expect(list.data.toList(), equals([10, 20]));
        expect(list.dataOrNull.toList(), equals([10, 20]));

        final mixed = [untracked.state(w1), untracked.state(w3)];
        expect(mixed.dataOrNull.toList(), equals([10, null]));
        expect(() => mixed.data.toList(), throwsA(isA<BloomSnapshotExtractionException>()));
      });

      test('6.2 Iterable<BloomController<T>>.data and dataOrNull extract values correctly', () {
        final c1 = BloomController<String>('alpha');
        final c2 = BloomController<String>('beta');
        final c3 = BloomController<String>('gamma')..empty();
        final list = [c1, c2];

        expect(list.data.toList(), equals(['alpha', 'beta']));
        expect(list.dataOrNull.toList(), equals(['alpha', 'beta']));

        final mixed = [c1, c3];
        expect(mixed.dataOrNull.toList(), equals(['alpha', null]));
        expect(() => mixed.data.toList(), throwsA(isA<BloomSnapshotExtractionException>()));
      });

      test('6.3 Iterable<BloomSnapshot<T>>.data and dataOrNull extract values correctly', () {
        final s1 = BloomSnapshot<int>(1);
        final s2 = BloomSnapshot<int>(2);
        final sEmpty = const BloomSnapshot<int>.empty();
        final list = [s1, s2];

        expect(list.data.toList(), equals([1, 2]));
        expect(list.dataOrNull.toList(), equals([1, 2]));

        final mixed = [s1, sEmpty];
        expect(mixed.dataOrNull.toList(), equals([1, null]));
        expect(() => mixed.data.toList(), throwsA(isA<BloomSnapshotExtractionException>()));
      });

      test('6.4 Iterable<BloomState<T>>.data and dataOrNull extract values correctly', () {
        final state1 = BloomSnapshot<String>('hello');
        final state2 = Bloom<String>.constant('world');
        final stateEmpty = const BloomSnapshot<String>.empty();
        final List<BloomState<String>> list = [state1, untracked.state(state2)];

        expect(list.data.toList(), equals(['hello', 'world']));
        expect(list.dataOrNull.toList(), equals(['hello', 'world']));

        final List<BloomState<String>> mixed = [state1, stateEmpty];
        expect(mixed.dataOrNull.toList(), equals(['hello', null]));
        expect(() => mixed.data.toList(), throwsA(isA<BloomSnapshotExtractionException>()));
      });
    });
  });
}

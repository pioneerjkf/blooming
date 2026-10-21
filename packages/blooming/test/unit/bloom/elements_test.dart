// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

class _UserItem {
  _UserItem(this.id, this.name);
  final String id;
  final String name;
}

class _UserViewModel {
  _UserViewModel(this.item);
  final _UserItem item;
}

class _UpdatableUserViewModel {
  _UpdatableUserViewModel(this.item);
  _UserItem item;
  void update(_UserItem newItem) {
    item = newItem;
  }
}

void main() {
  group('Bloom Elements, Reactive Collections & Keyed Operations Unit Tests', () {
    // =========================================================================
    // 1. BloomIterableElements, BloomListElements, BloomSetElements & Type Conversions
    // =========================================================================
    group('1. Collection Elements & Type Factories', () {
      test('1.1 elements.toList converts Bloom<Iterable<T>> into Bloom<List<T>>', () {
        final setController = BloomController<Set<int>>({1, 2, 3});

        final listBloomProxy = setController.bloom.elements.toList();
        final proxyTerminal = RawBloomTerminal(listBloomProxy, onInvalidated: () {});
        proxyTerminal.activate();

        expect(proxyTerminal.snapshot.data, equals([1, 2, 3]));
        expect(() => proxyTerminal.snapshot.data.add(4), throwsUnsupportedError);

        setController.set({10, 20});
        expect(proxyTerminal.snapshot.data, equals([10, 20]));

        proxyTerminal.deactivate();
      });

      test('1.2 elements.cast downcasts dynamic iterable into Bloom<List<T>>', () {
        final dynamicListController = BloomController<List<dynamic>>(['a', 'b', 'c']);

        final stringListBloomProxy = dynamicListController.bloom.elements.cast<String>();
        final proxyTerminal = RawBloomTerminal(stringListBloomProxy, onInvalidated: () {});
        proxyTerminal.activate();

        expect(proxyTerminal.snapshot.data, equals(['a', 'b', 'c']));

        proxyTerminal.deactivate();
      });

      test('1.3 elements.cast adapts List<S> to List<T>', () {
        final numListController = BloomController<List<num>>([1, 2, 3]);

        final castProxyBloom = numListController.bloom.elements.cast<int>();
        final proxyTerminal = RawBloomTerminal(castProxyBloom, onInvalidated: () {});
        proxyTerminal.activate();

        expect(proxyTerminal.snapshot.data, equals([1, 2, 3]));

        numListController.set([10, 20]);
        expect(proxyTerminal.snapshot.data, equals([10, 20]));

        proxyTerminal.deactivate();
      });
    });

    // =========================================================================
    // 2. List Elements Operators (index, length, first, last, where, map)
    // =========================================================================
    group('2. List Elements Operators', () {
      test('2.1 List elements indexing, length, where, map, first and last', () {
        final controller = BloomController<List<int>>([10, 20, 30, 40]);

        final lengthBloom = controller.bloom.elements.length;
        final firstBloom = controller.bloom.elements.first;
        final lastBloom = controller.bloom.elements.last;
        final atIndex1 = controller.bloom.elements[1];
        final doubled = controller.bloom.elements.map((x) => x * 2);
        final filtered = controller.bloom.elements.where((x) => x > 25);

        final tLen = RawBloomTerminal(lengthBloom, onInvalidated: () {});
        final tFirst = RawBloomTerminal(firstBloom, onInvalidated: () {});
        final tLast = RawBloomTerminal(lastBloom, onInvalidated: () {});
        final tAt1 = RawBloomTerminal(atIndex1, onInvalidated: () {});
        final tDouble = RawBloomTerminal(doubled, onInvalidated: () {});
        final tFiltered = RawBloomTerminal(filtered, onInvalidated: () {});

        tLen.activate();
        tFirst.activate();
        tLast.activate();
        tAt1.activate();
        tDouble.activate();
        tFiltered.activate();

        expect(tLen.data, 4);
        expect(tFirst.data, 10);
        expect(tLast.data, 40);
        expect(tAt1.data, 20);
        expect(tDouble.data, [20, 40, 60, 80]);
        expect(tFiltered.data, [30, 40]);

        // Mutate list
        controller.set([100, 200]);
        expect(tLen.data, 2);
        expect(tFirst.data, 100);
        expect(tLast.data, 200);
        expect(tAt1.data, 200);
        expect(tDouble.data, [200, 400]);
        expect(tFiltered.data, [100, 200]);

        tLen.deactivate();
        tFirst.deactivate();
        tLast.deactivate();
        tAt1.deactivate();
        tDouble.deactivate();
        tFiltered.deactivate();
      });
    });

    // =========================================================================
    // 3. Map Elements Operators (index, keys, values, containsKey, containsValue)
    // =========================================================================
    group('3. Map Elements Operators', () {
      test('3.1 Map elements indexing, keys, values, containsKey, and containsValue', () {
        final controller = BloomController<Map<String, int>>({'a': 1, 'b': 2});

        final valA = controller.bloom.elements['a'];
        final valNonExistent = controller.bloom.elements['z'];
        final hasKeyA = controller.bloom.elements.containsKey('a');
        final hasKeyZ = controller.bloom.elements.containsKey('z');
        final hasVal2 = controller.bloom.elements.containsValue(2);
        final keysList = controller.bloom.elements.keys;
        final valuesList = controller.bloom.elements.values;

        final tValA = RawBloomTerminal(valA, onInvalidated: () {});
        final tValZ = RawBloomTerminal(valNonExistent, onInvalidated: () {});
        final tHasA = RawBloomTerminal(hasKeyA, onInvalidated: () {});
        final tHasZ = RawBloomTerminal(hasKeyZ, onInvalidated: () {});
        final tHasV2 = RawBloomTerminal(hasVal2, onInvalidated: () {});
        final tKeys = RawBloomTerminal(keysList, onInvalidated: () {});
        final tValues = RawBloomTerminal(valuesList, onInvalidated: () {});

        tValA.activate();
        tValZ.activate();
        tHasA.activate();
        tHasZ.activate();
        tHasV2.activate();
        tKeys.activate();
        tValues.activate();

        expect(tValA.data, 1);
        expect(tValZ.data, isNull);
        expect(tHasA.data, isTrue);
        expect(tHasZ.data, isFalse);
        expect(tHasV2.data, isTrue);
        expect(tKeys.data, ['a', 'b']);
        expect(tValues.data, [1, 2]);

        // Mutate map
        controller.set({'z': 99});
        expect(tValA.data, isNull);
        expect(tValZ.data, 99);
        expect(tHasA.data, isFalse);
        expect(tHasZ.data, isTrue);
        expect(tHasV2.data, isFalse);
        expect(tKeys.data, ['z']);
        expect(tValues.data, [99]);

        tValA.deactivate();
        tValZ.deactivate();
        tHasA.deactivate();
        tHasZ.deactivate();
        tHasV2.deactivate();
        tKeys.deactivate();
        tValues.deactivate();
      });
    });

    // =========================================================================
    // 4. Keyed Elements (keyed.map) Caching & Identity Retention
    // =========================================================================
    group('4. Keyed Elements Caching & Identity Retention', () {
      test('4.1 Keyed map reuses cached objects when list is reordered or partially updated', () {
        final u1 = _UserItem('1', 'Alice');
        final u2 = _UserItem('2', 'Bob');
        final u3 = _UserItem('3', 'Charlie');

        final controller = BloomController<List<_UserItem>>([u1, u2, u3]);
        int convertCount = 0;

        final keyedBloom = controller.bloom.keyed.map(
          key: (u) => u.id,
          convert: (u) {
            convertCount++;
            return _UserViewModel(u);
          },
        );

        final terminal = RawBloomTerminal(keyedBloom, onInvalidated: () {});
        terminal.activate();

        // Lazy computation: convert is not called on activate
        expect(convertCount, 0);

        // First pull evaluates convert
        final initialList = terminal.data;
        expect(convertCount, 3);
        final vm1 = initialList[0];
        final vm2 = initialList[1];
        final vm3 = initialList[2];

        // Reorder list: [u3, u1, u2]
        controller.set([u3, u1, u2]);

        // Convert should NOT be called again because all 3 keys are cached
        final reorderedList = terminal.data;
        expect(convertCount, 3);
        expect(reorderedList.length, 3);
        expect(identical(reorderedList[0], vm3), isTrue);
        expect(identical(reorderedList[1], vm1), isTrue);
        expect(identical(reorderedList[2], vm2), isTrue);

        // Add 1 new user: [u1, u4]
        final u4 = _UserItem('4', 'David');
        controller.set([u1, u4]);

        // Only u4 should be converted
        final updatedList = terminal.data;
        expect(convertCount, 4);
        expect(updatedList.length, 2);
        expect(identical(updatedList[0], vm1), isTrue);
        expect(updatedList[1].item.name, 'David');

        terminal.deactivate();
      });

      test('4.2 Empty and Error state transitions reset or preserve cache correctly in keyed.map', () {
        final u1 = _UserItem('1', 'Alice');
        final controller = BloomController<List<_UserItem>>([u1]);
        int convertCount = 0;

        final keyedBloom = controller.bloom.keyed.map(
          key: (u) => u.id,
          convert: (u) {
            convertCount++;
            return _UserViewModel(u);
          },
        );

        final terminal = RawBloomTerminal(keyedBloom, onInvalidated: () {});
        terminal.activate();

        expect(terminal.data.length, 1);
        expect(convertCount, 1);

        // Empty source resets cache
        controller.empty();
        expect(terminal.isEmpty, isTrue);

        // Re-adding u1 should re-convert because empty cleared cache
        controller.set([u1]);
        expect(terminal.data.length, 1);
        expect(convertCount, 2);

        // Error on source preserves pipeline error
        controller.setError('Upstream Error');
        expect(terminal.hasError, isTrue);

        // Recovery
        controller.set([u1]);
        expect(terminal.hasData, isTrue);

        terminal.deactivate();
      });

      test('4.3 Keyed map retains Bloom instances across list mutations and deletions', () {
        final controller = BloomController<List<String>>(['A', 'B', 'C']);
        int builderCount = 0;

        final mappedGroup = controller.bloom.keyed.map(
          key: (item) => item,
          convert: (item) {
            builderCount++;
            return BloomController<String>('Node-$item');
          },
        );

        final countBloom = computed((via) => via(mappedGroup).length);
        final terminal = RawBloomTerminal(countBloom, onInvalidated: () {});
        terminal.activate();

        expect(terminal.data, 3);
        expect(builderCount, 3);

        final groupSnapshot1 = untracked.state(mappedGroup).snapshot;
        final nodeA = groupSnapshot1.data[0];
        final nodeB = groupSnapshot1.data[1];
        final nodeC = groupSnapshot1.data[2];

        // Mutate list: reverse order ['C', 'B', 'A']
        controller.set(['C', 'B', 'A']);

        // Builder should NOT be called again
        expect(builderCount, 3);
        final groupSnapshot2 = untracked.state(mappedGroup).snapshot;
        expect(groupSnapshot2.data.length, 3);
        expect(identical(groupSnapshot2.data[0], nodeC), isTrue);
        expect(identical(groupSnapshot2.data[1], nodeB), isTrue);
        expect(identical(groupSnapshot2.data[2], nodeA), isTrue);

        // Remove B: ['A', 'C']
        controller.set(['A', 'C']);
        expect(builderCount, 3);
        final groupSnapshot3 = untracked.state(mappedGroup).snapshot;
        expect(groupSnapshot3.data.length, 2);
        expect(identical(groupSnapshot3.data[0], nodeA), isTrue);
        expect(identical(groupSnapshot3.data[1], nodeC), isTrue);

        terminal.deactivate();
      });

      test('4.4 Keyed map update callback propagates element updates to cached instances', () {
        final u1 = _UserItem('1', 'Alice');
        final u2 = _UserItem('2', 'Bob');
        final controller = BloomController<List<_UserItem>>([u1, u2]);

        int convertCount = 0;
        final updateCalls = <String, String>{};

        final keyedBloom = controller.bloom.keyed.map(
          key: (u) => u.id,
          convert: (u) {
            convertCount++;
            return _UpdatableUserViewModel(u);
          },
          update: (vm, u) {
            updateCalls[u.id] = u.name;
            vm.update(u);
          },
        );

        final terminal = RawBloomTerminal(keyedBloom, onInvalidated: () {});
        terminal.activate();

        // Initial evaluation
        final initialList = terminal.data;
        expect(convertCount, 2);
        expect(updateCalls, isEmpty); // Initial conversion does not invoke update
        final vm1 = initialList[0];
        final vm2 = initialList[1];
        expect(vm1.item.name, 'Alice');
        expect(vm2.item.name, 'Bob');

        // Update u1's name without changing key: '1' -> 'Alicia'
        final u1Updated = _UserItem('1', 'Alicia');
        controller.set([u1Updated, u2]);

        final updatedList = terminal.data;
        // Convert count must not increase
        expect(convertCount, 2);
        // Identity must be preserved
        expect(identical(updatedList[0], vm1), isTrue);
        expect(identical(updatedList[1], vm2), isTrue);
        // Update callback must have been called for u1
        expect(updateCalls['1'], 'Alicia');
        // ViewModel must have updated data
        expect(vm1.item.name, 'Alicia');

        terminal.deactivate();
      });

      test('4.5 Keyed map update callback exception triggers error state and resets cache', () {
        final u1 = _UserItem('1', 'Alice');
        final controller = BloomController<List<_UserItem>>([u1]);
        bool shouldThrow = false;

        final keyedBloom = controller.bloom.keyed.map(
          key: (u) => u.id,
          convert: (u) => _UpdatableUserViewModel(u),
          update: (vm, u) {
            if (shouldThrow) {
              throw StateError('Update failed for ${u.name}');
            }
            vm.update(u);
          },
        );

        final terminal = RawBloomTerminal(keyedBloom, onInvalidated: () {});
        terminal.activate();

        expect(terminal.hasData, isTrue);
        expect(terminal.data[0].item.name, 'Alice');

        // Trigger update failure
        shouldThrow = true;
        controller.set([_UserItem('1', 'Alice Mutated')]);

        expect(terminal.hasError, isTrue);
        expect(terminal.error, isA<StateError>());

        // Recovery: cache was cleared upon exception, so next valid pull re-evaluates convert
        shouldThrow = false;
        controller.set([_UserItem('1', 'Alice Recovered')]);
        expect(terminal.hasData, isTrue);
        expect(terminal.data[0].item.name, 'Alice Recovered');

        terminal.deactivate();
      });

      test('4.6 Keyed map triggers assertion error when duplicate keys exist in the same collection snapshot', () {
        final u1 = _UserItem('1', 'Alice');
        final u2 = _UserItem('1', 'Duplicate Alice');
        final controller = BloomController<List<_UserItem>>([u1, u2]);

        final keyedBloom = controller.bloom.keyed.map(
          key: (u) => u.id,
          convert: (u) => _UserViewModel(u),
        );

        final terminal = RawBloomTerminal(keyedBloom, onInvalidated: () {});
        terminal.activate();

        expect(terminal.hasError, isTrue);
        expect(terminal.error, isA<AssertionError>());

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 5. BloomIterableElements Exhaustive Operators
    // =========================================================================
    group('5. BloomIterableElements Exhaustive Operators', () {
      test('5.1 whereType, indexed, expand, contains, reduce, fold, every, any, join', () {
        final controller = BloomController<Iterable<Object>>([1, 'two', 3, 'four', 5]);

        final numbersOnly = controller.bloom.elements.whereType<int>();
        final indexedList = controller.bloom.elements.indexed;
        final expanded = controller.bloom.elements.expand((e) => [e, e]);
        final hasThree = controller.bloom.elements.contains(3);
        final hasNine = controller.bloom.elements.contains(9);
        final reduced = controller.bloom.elements.whereType<int>().elements.reduce((a, b) => a + b);
        final folded = controller.bloom.elements.fold('Prefix:', (prev, e) => '$prev $e');
        final allStrings = controller.bloom.elements.every((e) => e is String);
        final anyStrings = controller.bloom.elements.any((e) => e is String);
        final joined = controller.bloom.elements.join('-');

        final tNum = RawBloomTerminal(numbersOnly, onInvalidated: () {})..activate();
        final tIdx = RawBloomTerminal(indexedList, onInvalidated: () {})..activate();
        final tExp = RawBloomTerminal(expanded, onInvalidated: () {})..activate();
        final tHas3 = RawBloomTerminal(hasThree, onInvalidated: () {})..activate();
        final tHas9 = RawBloomTerminal(hasNine, onInvalidated: () {})..activate();
        final tRed = RawBloomTerminal(reduced, onInvalidated: () {})..activate();
        final tFold = RawBloomTerminal(folded, onInvalidated: () {})..activate();
        final tAllStr = RawBloomTerminal(allStrings, onInvalidated: () {})..activate();
        final tAnyStr = RawBloomTerminal(anyStrings, onInvalidated: () {})..activate();
        final tJoin = RawBloomTerminal(joined, onInvalidated: () {})..activate();

        expect(tNum.data, [1, 3, 5]);
        expect(tIdx.data, [(0, 1), (1, 'two'), (2, 3), (3, 'four'), (4, 5)]);
        expect(tExp.data, [1, 1, 'two', 'two', 3, 3, 'four', 'four', 5, 5]);
        expect(tHas3.data, isTrue);
        expect(tHas9.data, isFalse);
        expect(tRed.data, 9);
        expect(tFold.data, 'Prefix: 1 two 3 four 5');
        expect(tAllStr.data, isFalse);
        expect(tAnyStr.data, isTrue);
        expect(tJoin.data, '1-two-3-four-5');

        // Test proxy .bloom getter
        expect(identical(controller.bloom.elements.bloom, controller.bloom), isTrue);

        tNum.deactivate();
        tIdx.deactivate();
        tExp.deactivate();
        tHas3.deactivate();
        tHas9.deactivate();
        tRed.deactivate();
        tFold.deactivate();
        tAllStr.deactivate();
        tAnyStr.deactivate();
        tJoin.deactivate();
      });

      test('5.2 toSet (unmodifiable and mutable), isEmpty, isNotEmpty, take, skip, elementAt', () {
        final controller = BloomController<Iterable<int>>([1, 2, 2, 3]);

        final unmodSet = controller.bloom.elements.toSet(unmodifiable: true);
        final modSet = controller.bloom.elements.toSet(unmodifiable: false);
        final emptyBloom = controller.bloom.elements.isEmpty;
        final notEmptyBloom = controller.bloom.elements.isNotEmpty;
        final taken = controller.bloom.elements.take(2);
        final skipped = controller.bloom.elements.skip(2);
        final elemAt1 = controller.bloom.elements.elementAt(1);

        final tUnmod = RawBloomTerminal(unmodSet, onInvalidated: () {})..activate();
        final tMod = RawBloomTerminal(modSet, onInvalidated: () {})..activate();
        final tEmpty = RawBloomTerminal(emptyBloom, onInvalidated: () {})..activate();
        final tNotEmpty = RawBloomTerminal(notEmptyBloom, onInvalidated: () {})..activate();
        final tTaken = RawBloomTerminal(taken, onInvalidated: () {})..activate();
        final tSkipped = RawBloomTerminal(skipped, onInvalidated: () {})..activate();
        final tElemAt = RawBloomTerminal(elemAt1, onInvalidated: () {})..activate();

        expect(tUnmod.data, {1, 2, 3});
        expect(() => tUnmod.data.add(99), throwsUnsupportedError);
        expect(tMod.data, {1, 2, 3});
        tMod.data.add(99); // Mutable copy allowed
        expect(tEmpty.data, isFalse);
        expect(tNotEmpty.data, isTrue);
        expect(tTaken.data, [1, 2]);
        expect(tSkipped.data, [2, 3]);
        expect(tElemAt.data, 2);

        // Update to empty
        controller.set([]);
        expect(tEmpty.data, isTrue);
        expect(tNotEmpty.data, isFalse);

        tUnmod.deactivate();
        tMod.deactivate();
        tEmpty.deactivate();
        tNotEmpty.deactivate();
        tTaken.deactivate();
        tSkipped.deactivate();
        tElemAt.deactivate();
      });

      test('5.3 firstOrNull, lastOrNull, single, singleOrNull, firstWhere, lastWhere, singleWhere', () {
        final controller = BloomController<List<int>>([10, 20, 30, 20]);

        final firstNullBloom = controller.bloom.elements.firstOrNull;
        final lastNullBloom = controller.bloom.elements.lastOrNull;
        final singleNullBloom = controller.bloom.elements.singleOrNull;
        final firstWhereBloom = controller.bloom.elements.firstWhere((x) => x > 15);
        final firstWhereOrElse = controller.bloom.elements.firstWhere((x) => x > 100, orElse: () => -1);
        final lastWhereBloom = controller.bloom.elements.lastWhere((x) => x == 20);
        final lastWhereOrElse = controller.bloom.elements.lastWhere((x) => x > 100, orElse: () => -2);
        final singleWhereBloom = controller.bloom.elements.singleWhere((x) => x == 30);
        final singleWhereOrElse = controller.bloom.elements.singleWhere((x) => x > 100, orElse: () => -3);

        final tFirstN = RawBloomTerminal(firstNullBloom, onInvalidated: () {})..activate();
        final tLastN = RawBloomTerminal(lastNullBloom, onInvalidated: () {})..activate();
        final tSingleN = RawBloomTerminal(singleNullBloom, onInvalidated: () {})..activate();
        final tFW = RawBloomTerminal(firstWhereBloom, onInvalidated: () {})..activate();
        final tFWO = RawBloomTerminal(firstWhereOrElse, onInvalidated: () {})..activate();
        final tLW = RawBloomTerminal(lastWhereBloom, onInvalidated: () {})..activate();
        final tLWO = RawBloomTerminal(lastWhereOrElse, onInvalidated: () {})..activate();
        final tSW = RawBloomTerminal(singleWhereBloom, onInvalidated: () {})..activate();
        final tSWO = RawBloomTerminal(singleWhereOrElse, onInvalidated: () {})..activate();

        expect(tFirstN.data, 10);
        expect(tLastN.data, 20);
        expect(tSingleN.data, isNull); // Multiple elements
        expect(tFW.data, 20);
        expect(tFWO.data, -1);
        expect(tLW.data, 20);
        expect(tLWO.data, -2);
        expect(tSW.data, 30);
        expect(tSWO.data, -3);

        // Single element test
        controller.set([42]);
        final singleBloom = controller.bloom.elements.single;
        final tSingle = RawBloomTerminal(singleBloom, onInvalidated: () {})..activate();
        expect(tSingle.data, 42);
        expect(tSingleN.data, 42);

        // Empty list test
        controller.set([]);
        expect(tFirstN.data, isNull);
        expect(tLastN.data, isNull);
        expect(tSingleN.data, isNull);

        tFirstN.deactivate();
        tLastN.deactivate();
        tSingleN.deactivate();
        tFW.deactivate();
        tFWO.deactivate();
        tLW.deactivate();
        tLWO.deactivate();
        tSW.deactivate();
        tSWO.deactivate();
        tSingle.deactivate();
      });
    });

    // =========================================================================
    // 6. BloomListElements Additional Operators
    // =========================================================================
    group('6. BloomListElements Additional Operators', () {
      test('6.1 reversed, indexOf, indexWhere, lastIndexWhere, lastIndexOf, sublist, asMap, toUnmodifiable', () {
        final controller = BloomController<List<String>>(['a', 'b', 'c', 'b']);

        final reversedBloom = controller.bloom.elements.reversed;
        final idxOfB = controller.bloom.elements.indexOf('b', 0);
        final idxWhereC = controller.bloom.elements.indexWhere((s) => s == 'c');
        final lastIdxWhereB = controller.bloom.elements.lastIndexWhere((s) => s == 'b');
        final lastIdxB = controller.bloom.elements.lastIndexOf('b');
        final sublistBloom = controller.bloom.elements.sublist(1, 3);
        final asMapBloom = controller.bloom.elements.asMap();
        final unmodifiableBloom = controller.bloom.elements.toUnmodifiable();

        final tRev = RawBloomTerminal(reversedBloom, onInvalidated: () {})..activate();
        final tIdxB = RawBloomTerminal(idxOfB, onInvalidated: () {})..activate();
        final tIdxC = RawBloomTerminal(idxWhereC, onInvalidated: () {})..activate();
        final tLIdxWhereB = RawBloomTerminal(lastIdxWhereB, onInvalidated: () {})..activate();
        final tLIdxB = RawBloomTerminal(lastIdxB, onInvalidated: () {})..activate();
        final tSub = RawBloomTerminal(sublistBloom, onInvalidated: () {})..activate();
        final tMap = RawBloomTerminal(asMapBloom, onInvalidated: () {})..activate();
        final tUnmod = RawBloomTerminal(unmodifiableBloom, onInvalidated: () {})..activate();

        expect(tRev.data, ['b', 'c', 'b', 'a']);
        expect(tIdxB.data, 1);
        expect(tIdxC.data, 2);
        expect(tLIdxWhereB.data, 3);
        expect(tLIdxB.data, 3);
        expect(tSub.data, ['b', 'c']);
        expect(tMap.data, {0: 'a', 1: 'b', 2: 'c', 3: 'b'});
        expect(tUnmod.data, ['a', 'b', 'c', 'b']);
        expect(() => tUnmod.data.add('d'), throwsUnsupportedError);

        tRev.deactivate();
        tIdxB.deactivate();
        tIdxC.deactivate();
        tLIdxWhereB.deactivate();
        tLIdxB.deactivate();
        tSub.deactivate();
        tMap.deactivate();
        tUnmod.deactivate();
      });
    });

    // =========================================================================
    // 7. BloomSetElements Operators
    // =========================================================================
    group('7. BloomSetElements Operators', () {
      test('7.1 lookup, intersection, union, difference, cast, toUnmodifiable, bloom getter', () {
        final setController = BloomController<Set<int>>({1, 2, 3});

        final lookup2 = setController.bloom.elements.lookup(2);
        final lookup99 = setController.bloom.elements.lookup(99);
        final intersectionBloom = setController.bloom.elements.intersection({2, 3, 4});
        final unionBloom = setController.bloom.elements.union({4, 5});
        final diffBloom = setController.bloom.elements.difference({1, 2});
        final castBloom = setController.bloom.elements.cast<num>();
        final unmodBloom = setController.bloom.elements.toUnmodifiable();

        final tLook2 = RawBloomTerminal(lookup2, onInvalidated: () {})..activate();
        final tLook99 = RawBloomTerminal(lookup99, onInvalidated: () {})..activate();
        final tInter = RawBloomTerminal(intersectionBloom, onInvalidated: () {})..activate();
        final tUnion = RawBloomTerminal(unionBloom, onInvalidated: () {})..activate();
        final tDiff = RawBloomTerminal(diffBloom, onInvalidated: () {})..activate();
        final tCast = RawBloomTerminal(castBloom, onInvalidated: () {})..activate();
        final tUnmod = RawBloomTerminal(unmodBloom, onInvalidated: () {})..activate();

        expect(tLook2.data, 2);
        expect(tLook99.data, isNull);
        expect(tInter.data, {2, 3});
        expect(tUnion.data, {1, 2, 3, 4, 5});
        expect(tDiff.data, {3});
        expect(tCast.data, {1, 2, 3});
        expect(tUnmod.data, {1, 2, 3});
        expect(() => tUnmod.data.add(99), throwsUnsupportedError);

        // proxy bloom getter
        expect(identical(setController.bloom.elements.bloom, setController.bloom), isTrue);

        tLook2.deactivate();
        tLook99.deactivate();
        tInter.deactivate();
        tUnion.deactivate();
        tDiff.deactivate();
        tCast.deactivate();
        tUnmod.deactivate();
      });
    });

    // =========================================================================
    // 8. BloomMapElements Additional Operators
    // =========================================================================
    group('8. BloomMapElements Additional Operators', () {
      test('8.1 map, where, length, isEmpty, isNotEmpty, cast, toUnmodifiable, bloom getter', () {
        final mapController = BloomController<Map<String, int>>({'apple': 100, 'banana': 200});

        final mappedEntries = mapController.bloom.elements.map((k, v) => MapEntry(k.toUpperCase(), v * 2));
        final filteredEntries = mapController.bloom.elements.where((k, v) => v > 150);
        final lenBloom = mapController.bloom.elements.length;
        final emptyBloom = mapController.bloom.elements.isEmpty;
        final notEmptyBloom = mapController.bloom.elements.isNotEmpty;
        final castBloom = mapController.bloom.elements.cast<Object, Object>();
        final unmodBloom = mapController.bloom.elements.toUnmodifiable();

        final tMap = RawBloomTerminal(mappedEntries, onInvalidated: () {})..activate();
        final tWhere = RawBloomTerminal(filteredEntries, onInvalidated: () {})..activate();
        final tLen = RawBloomTerminal(lenBloom, onInvalidated: () {})..activate();
        final tEmpty = RawBloomTerminal(emptyBloom, onInvalidated: () {})..activate();
        final tNotEmpty = RawBloomTerminal(notEmptyBloom, onInvalidated: () {})..activate();
        final tCast = RawBloomTerminal(castBloom, onInvalidated: () {})..activate();
        final tUnmod = RawBloomTerminal(unmodBloom, onInvalidated: () {})..activate();

        expect(tMap.data, {'APPLE': 200, 'BANANA': 400});
        expect(tWhere.data, {'banana': 200});
        expect(tLen.data, 2);
        expect(tEmpty.data, isFalse);
        expect(tNotEmpty.data, isTrue);
        expect(tCast.data, {'apple': 100, 'banana': 200});
        expect(tUnmod.data, {'apple': 100, 'banana': 200});
        expect(() => tUnmod.data['kiwi'] = 300, throwsUnsupportedError);

        // proxy bloom getter
        expect(identical(mapController.bloom.elements.bloom, mapController.bloom), isTrue);

        // empty map
        mapController.set({});
        expect(tEmpty.data, isTrue);
        expect(tNotEmpty.data, isFalse);
        expect(tLen.data, 0);

        tMap.deactivate();
        tWhere.deactivate();
        tLen.deactivate();
        tEmpty.deactivate();
        tNotEmpty.deactivate();
        tCast.deactivate();
        tUnmod.deactivate();
      });
    });

    // =========================================================================
    // 9. Bloom.elements.bloom and BloomKeyedIterableElements.bloom consistency
    // =========================================================================
    group('9. Bloom.elements.bloom and BloomKeyedIterableElements.bloom consistency', () {
      test('9.1 Bloom Iterable/List/Set/Map .elements & .keyed proxies', () {
        final BloomController<Iterable<int>> iterCtrl = BloomController<Iterable<int>>([1, 2]);
        final BloomController<List<int>> listCtrl = BloomController<List<int>>([3, 4]);
        final BloomController<Set<int>> setCtrl = BloomController<Set<int>>({5, 6});
        final BloomController<Map<String, int>> mapCtrl = BloomController<Map<String, int>>({'k': 1});

        expect(iterCtrl.bloom.elements.bloom, equals(iterCtrl.bloom));
        expect(iterCtrl.bloom.keyed.bloom, equals(iterCtrl.bloom));
        expect(listCtrl.bloom.elements.bloom, equals(listCtrl.bloom));
        expect(listCtrl.bloom.keyed.bloom, equals(listCtrl.bloom));
        expect(setCtrl.bloom.elements.bloom, equals(setCtrl.bloom));
        expect(mapCtrl.bloom.elements.bloom, equals(mapCtrl.bloom));

        final Bloom<Iterable<int>> rawIterBloom = iterCtrl.bloom;
        expect(rawIterBloom.elements.bloom, equals(rawIterBloom));
        expect(rawIterBloom.keyed.bloom, equals(rawIterBloom));
      });
    });
  });
}

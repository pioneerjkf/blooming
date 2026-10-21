// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:test/test.dart';
import '../../test_utils.dart';

void main() {
  group('Bloom.switched & bloom.switched Comprehensive Unit Tests', () {
    test('bloom.switched dynamically switches target Bloom based on reactive state', () {
      final isDark = BloomController(false);
      final lightTheme = BloomController('Light Mode');
      final darkTheme = BloomController('Dark Mode');

      final activeTheme = switched((via) {
        return via(isDark.bloom) ? darkTheme.bloom : lightTheme.bloom;
      });

      expect(untracked(activeTheme), equals('Light Mode'));

      // Switch to dark
      isDark.data = true;
      expect(untracked(activeTheme), equals('Dark Mode'));

      // Mutate darkTheme inner data
      darkTheme.data = 'OLED Dark Mode';
      expect(untracked(activeTheme), equals('OLED Dark Mode'));

      // Switch back to light
      isDark.data = false;
      expect(untracked(activeTheme), equals('Light Mode'));
    });

    test('bloom.switched prunes obsolete dependencies on dynamic conditional branches', () {
      final branch = BloomController(true);
      final a = BloomController('Alpha');
      final b = BloomController('Beta');

      final targetA = BloomController(10);
      final targetB = BloomController(20);

      var evaluations = 0;
      final switchedBloom = switched((via) {
        evaluations++;
        if (via(branch.bloom)) {
          final _ = via(a.bloom);
          return targetA.bloom;
        } else {
          final _ = via(b.bloom);
          return targetB.bloom;
        }
      });

      expect(untracked(switchedBloom), equals(10));
      expect(evaluations, equals(1));

      // Mutating 'a' re-evaluates because branch is true
      a.data = 'Alpha 2';
      expect(untracked(switchedBloom), equals(10));
      expect(evaluations, equals(2));

      // Mutating 'b' should NOT re-evaluate because 'b' was never read
      b.data = 'Beta 2';
      expect(untracked(switchedBloom), equals(10));
      expect(evaluations, equals(2));

      // Switch branch to false
      branch.data = false;
      expect(untracked(switchedBloom), equals(20));
      expect(evaluations, equals(3));

      // Now mutating 'a' should NOT re-evaluate because it was pruned!
      a.data = 'Alpha 3';
      expect(untracked(switchedBloom), equals(20));
      expect(evaluations, equals(3));

      // Mutating 'b' re-evaluates
      b.data = 'Beta 3';
      expect(untracked(switchedBloom), equals(20));
      expect(evaluations, equals(4));
    });

    test('bloom.switched reacts inside effect and computed', () async {
      final selectedId = BloomController(1);
      final item1 = BloomController('Item 1: Alice');
      final item2 = BloomController('Item 2: Bob');

      final currentItem = switched((via) {
        return via(selectedId.bloom) == 1 ? item1.bloom : item2.bloom;
      });

      final summary = computed((via) => 'Summary: ${via(currentItem)}');
      expect(untracked(summary), equals('Summary: Item 1: Alice'));

      final effectLogs = <String>[];
      final dispose = effect((via) {
        effectLogs.add(via(currentItem));
      });

      await Future<void>.delayed(Duration.zero);
      expect(effectLogs, equals(['Item 1: Alice']));

      // Change inner item1 data
      item1.data = 'Item 1: Alice Updated';
      await Future<void>.delayed(Duration.zero);
      expect(untracked(summary), equals('Summary: Item 1: Alice Updated'));
      expect(effectLogs, equals(['Item 1: Alice', 'Item 1: Alice Updated']));

      // Switch selectedId
      selectedId.data = 2;
      await Future<void>.delayed(Duration.zero);
      expect(untracked(summary), equals('Summary: Item 2: Bob'));
      expect(effectLogs, equals(['Item 1: Alice', 'Item 1: Alice Updated', 'Item 2: Bob']));

      dispose();
    });

    test('bloom.switched dynamically switches target pure Bloom based on reactive state', () {
      final isDark = BloomController(false);
      final lightThemeBloom = Bloom.constant('Pure Light Bloom');
      final darkThemeBloom = Bloom.constant('Pure Dark Bloom');

      final activeTheme = switched((via) {
        return via(isDark.bloom) ? darkThemeBloom : lightThemeBloom;
      });

      expect(untracked(activeTheme), equals('Pure Light Bloom'));

      isDark.data = true;
      expect(untracked(activeTheme), equals('Pure Dark Bloom'));

      isDark.data = false;
      expect(untracked(activeTheme), equals('Pure Light Bloom'));
    });

    test('bloom.switched handles errors safely and recovers', () {
      final shouldFail = BloomController(true);

      final switchedBloom = switched<int>((via) {
        if (via(shouldFail.bloom)) {
          throw Exception('Switch failed!');
        }
        return BloomController(100).bloom;
      });

      expect(untracked.state(switchedBloom).hasError, isTrue);
      expect(() => untracked(switchedBloom), throwsA(isA<BloomSnapshotExtractionException>()));

      // Recovery
      shouldFail.data = false;
      expect(untracked.state(switchedBloom).hasError, isFalse);
      expect(untracked(switchedBloom), equals(100));
    });

    test('bloom.switched dynamically synchronizes version when switched branch is lazy computed', () {
      final selector = BloomController('A');
      final rootA = BloomController(10);
      final rootB = BloomController(20);

      var computedRunsA = 0;
      final lazyA = computed((via) {
        computedRunsA++;
        return via(rootA.bloom) * 2;
      });

      var computedRunsB = 0;
      final lazyB = computed((via) {
        computedRunsB++;
        return via(rootB.bloom) * 3;
      });

      final switchedBloom = switched((via) {
        final key = via(selector.bloom);
        return key == 'A' ? lazyA : lazyB;
      });

      // Downstream computed watching switchedBloom
      var downstreamRuns = 0;
      final downstream = computed((via) {
        downstreamRuns++;
        return 'Value: ${via(switchedBloom)}';
      });

      // Initial read
      expect(untracked(downstream), equals('Value: 20')); // 10 * 2
      expect(computedRunsA, equals(1));
      expect(computedRunsB, equals(0));
      expect(downstreamRuns, equals(1));

      // Mutate rootA -> downstream must update
      rootA.data = 15;
      expect(untracked(downstream), equals('Value: 30')); // 15 * 2
      expect(computedRunsA, equals(2));
      expect(downstreamRuns, equals(2));

      // Switch to B (which is uncomputed lazy node)
      selector.data = 'B';
      expect(untracked(downstream), equals('Value: 60')); // 20 * 3
      expect(computedRunsB, equals(1));
      expect(downstreamRuns, equals(3));

      // Mutate rootB -> downstream must update via updated version
      rootB.data = 30;
      expect(untracked(downstream), equals('Value: 90')); // 30 * 3
      expect(computedRunsB, equals(2));
      expect(downstreamRuns, equals(4));
    });
  });

  group('Dynamic List Bloom.computed Comprehensive Unit Tests', () {
    test('Bloom.computed dynamically generates collection of Blooms (e.g. Nasdaq items)', () {
      final count = BloomController(3);
      final codes = ['AAPL', 'GOOGL', 'MSFT', 'AMZN', 'NVDA'];
      final priceRubies = codes.map((code) => BloomController(100)).toList();

      final group = computed((via) {
        final currentCount = via(count.bloom);
        return List.generate(currentCount, (i) => priceRubies[i].bloom);
      });

      expect(untracked(group).length, equals(3));
      expect(untracked(group.sum()), equals(300)); // 100 + 100 + 100

      // Mutate individual item price
      priceRubies[0].data = 150;
      expect(untracked(group.sum()), equals(350)); // 150 + 100 + 100

      // Increase count to 5
      count.data = 5;
      expect(untracked(group).length, equals(5));
      expect(untracked(group.sum()), equals(550)); // 150 + 100 + 100 + 100 + 100

      // Decrease count to 2
      count.data = 2;
      expect(untracked(group).length, equals(2));
      expect(untracked(group.sum()), equals(250)); // 150 + 100
    });

    test('Bloom.computed on Bloom list combines elements reactively', () {
      final count = BloomController(2);
      final items = [BloomController('A'), BloomController('B'), BloomController('C')];

      final group = computed((via) {
        return List.generate(via(count.bloom), (i) => items[i].bloom);
      });

      final combined = group.combine();
      expect(untracked(combined), equals(['A', 'B']));

      // Mutate item
      items[0].data = 'Alpha';
      expect(untracked(combined), equals(['Alpha', 'B']));

      // Increase count
      count.data = 3;
      expect(untracked(combined), equals(['Alpha', 'B', 'C']));
    });

    test('Bloom.computed works with generic Bloom elements', () {
      final count = BloomController(2);
      final nodeA = Bloom.constant(10);
      final nodeB = Bloom.constant(20);
      final nodeC = Bloom.constant(30);
      final allNodes = [nodeA, nodeB, nodeC];

      final group = computed((via) {
        return List.generate(via(count.bloom), (i) => allNodes[i]);
      });

      expect(untracked(group).length, equals(2));
      expect(untracked(group), equals([nodeA, nodeB]));

      count.data = 3;
      expect(untracked(group).length, equals(3));
      expect(untracked(group), equals([nodeA, nodeB, nodeC]));
    });

    test('Bloom.computed on Bloom list handles error states and recovers', () {
      final shouldFail = BloomController(true);

      final group = computed<List<Bloom<int>>>((via) {
        if (via(shouldFail.bloom)) {
          throw Exception('Failed to generate group!');
        }
        return [BloomController(1).bloom, BloomController(2).bloom];
      });

      expect(untracked.state(group).hasError, isTrue);
      expect(() => untracked(group), throwsA(isA<BloomSnapshotExtractionException>()));

      // Recovery
      shouldFail.data = false;
      expect(untracked.state(group).hasError, isFalse);
      expect(untracked(group).length, equals(2));
      expect(untracked(group.sum()), equals(3));
    });
  });
}

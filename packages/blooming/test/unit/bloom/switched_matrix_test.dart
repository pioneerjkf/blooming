// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:test/test.dart';
import 'package:blooming/blooming.dart';
import '../../test_utils.dart';

void main() {
  group('Bloom Switched & Dynamic Bloom List Matrix Tests', () {
    test('1.1 bloom.switched switches target Bloom dynamically and propagates updates', () {
      final isPrimary = BloomController(true);
      final primary = BloomController('Primary-Initial');
      final secondary = BloomController('Secondary-Initial');

      final switchedBloom = switched((via) {
        return via(isPrimary.bloom) ? primary.bloom : secondary.bloom;
      });

      expect(untracked(switchedBloom), 'Primary-Initial');

      // Update primary
      primary.data = 'Primary-Updated';
      expect(untracked(switchedBloom), 'Primary-Updated');

      // Switch to secondary
      isPrimary.data = false;
      expect(untracked(switchedBloom), 'Secondary-Initial');

      // Update primary while secondary is active -> switched remains secondary
      primary.data = 'Primary-Ignored';
      expect(untracked(switchedBloom), 'Secondary-Initial');

      // Update secondary
      secondary.data = 'Secondary-Updated';
      expect(untracked(switchedBloom), 'Secondary-Updated');
    });

    test('1.2 bloom.switched switches underlying Bloom nodes dynamically', () {
      final mode = BloomController(1);
      final node1 = Bloom.constant(100);
      final node2 = Bloom.constant(200);
      final node3 = Bloom.constant(300);

      final switchedBloom = switched((via) {
        switch (via(mode.bloom)) {
          case 1:
            return node1;
          case 2:
            return node2;
          default:
            return node3;
        }
      });

      expect(untracked(switchedBloom), 100);

      mode.data = 2;
      expect(untracked(switchedBloom), 200);

      mode.data = 3;
      expect(untracked(switchedBloom), 300);
    });

    test('1.3 Bloom.computed dynamically expands and shrinks collection of Blooms', () {
      final count = BloomController(2);
      final items = List.generate(5, (i) => BloomController((i + 1) * 10)); // [10, 20, 30, 40, 50]

      final dynamicGroup = computed((via) {
        return List.generate(via(count.bloom), (i) => items[i].bloom);
      });

      final sumBloom = dynamicGroup.sum();

      expect(untracked(sumBloom), 30); // 10 + 20

      // Mutate item in active set
      items[0].data = 15;
      expect(untracked(sumBloom), 35); // 15 + 20

      // Expand group to 4 items
      count.data = 4;
      expect(untracked(sumBloom), 105); // 15 + 20 + 30 + 40

      // Mutate item outside current active count (item[4]) -> sum unchanged
      items[4].data = 999;
      expect(untracked(sumBloom), 105);

      // Shrink group to 1 item
      count.data = 1;
      expect(untracked(sumBloom), 15);
    });

    test('1.4 Deeply nested switches with effect tracking evaluate consistently', () async {
      final rootCondition = BloomController(true);
      final leafA = BloomController(10);
      final leafB = BloomController(20);

      final branchSwitched = switched((via) => via(rootCondition.bloom) ? leafA.bloom : leafB.bloom);
      final computedResult = computed((via) => via(branchSwitched) * 2);

      final loggedValues = <int>[];
      final dispose = effect((via) {
        loggedValues.add(via(computedResult));
      });

      await Future<void>.delayed(Duration.zero);
      expect(loggedValues, [20]); // 10 * 2

      leafA.data = 15;
      await Future<void>.delayed(Duration.zero);
      expect(loggedValues, [20, 30]); // 15 * 2

      // Switch branch to leafB
      rootCondition.data = false;
      await Future<void>.delayed(Duration.zero);
      expect(loggedValues, [20, 30, 40]); // 20 * 2

      leafB.data = 50;
      await Future<void>.delayed(Duration.zero);
      expect(loggedValues, [20, 30, 40, 100]); // 50 * 2

      dispose();
    });
  });
}

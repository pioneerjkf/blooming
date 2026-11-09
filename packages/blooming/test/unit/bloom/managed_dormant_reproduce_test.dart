// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

void main() {
  group('Managed Dormant Read & Activation Tests', () {
    test('1. computed observing managed while dormant resolves valid data upon initial activation', () {
      final res = managed<String>(
        create: (via) => 'Resource-A',
        dispose: (_) {},
      );
      final status = computed<String>((via) => 'Active: ${via(res)}');

      // 1. Initial dormant read: res is dormant and returns empty, caching empty in status
      expect(untracked.state(status).isEmpty, isTrue);

      // 2. Attach terminal and activate the graph
      final terminal = RawBloomTerminal(status, onInvalidated: () {});
      terminal.activate();

      // 3. After activation, res is active and status resolves fresh valid data!
      expect(
        terminal.hasData,
        isTrue,
        reason: 'Terminal should have valid data after activation',
      );
      expect(
        terminal.data,
        'Active: Resource-A',
        reason: 'Active computed node should resolve managed resource data',
      );

      terminal.deactivate();
    });

    test('2. computed observing managed when re-evaluated during dormancy re-evaluates upon re-activation', () {
      int allocations = 0;
      final trigger = blooming<int>(1);
      final res = managed<String>(
        create: (via) => 'Instance-${++allocations}',
        dispose: (_) {},
      );
      // Status depends on both trigger and managed resource
      final status = computed<String>((via) => 'T${via(trigger.bloom)}: ${via(res)}');

      // 1. Activate initially
      final terminal = RawBloomTerminal(status, onInvalidated: () {});
      terminal.activate();
      expect(terminal.data, 'T1: Instance-1');

      // 2. Deactivate: res disposes its resource
      terminal.deactivate();

      // 3. Trigger mutates while dormant, then status is read while dormant
      trigger.data = 2;
      // Status re-evaluates while dormant: sees res is dormant (Empty), caches Empty
      expect(untracked.state(status).isEmpty, isTrue);

      // 4. Re-activate: must not stay stuck in Empty!
      terminal.activate();
      expect(
        terminal.hasData,
        isTrue,
        reason: 'Re-activated terminal must transition out of dormant empty state',
      );
      expect(terminal.data, 'T2: Instance-2');

      terminal.deactivate();
    });
  });
}

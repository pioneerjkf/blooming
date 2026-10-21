// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

void main() {
  group('Cache Coherency, Versioning & Disconnect/Reconnect Integration Tests', () {
    // =========================================================================
    // 1. Single-Source Version-based Disconnection/Reconnection
    // =========================================================================
    group('1. Single-Source Version Disconnect/Reconnect Coherency', () {
      test('1.1 Computation node updates cached snapshot when source changes during disconnection', () {
        final source = BloomController<int>(10);
        int computeCount = 0;

        final mapped = computed((via) {
          computeCount++;
          return via(source.bloom) * 2;
        });

        int terminal1DirtyCount = 0;
        final terminal1 = RawBloomTerminal(mapped, onInvalidated: () {
          terminal1DirtyCount++;
        });

        // 1. Activate terminal 1 and read snapshot
        terminal1.activate();
        expect(terminal1.snapshot.data, 20);
        expect(computeCount, 1);
        expect(terminal1DirtyCount, 0);

        final sourceTerminal = RawBloomTerminal(source.bloom, onInvalidated: () {});
        sourceTerminal.activate();

        // 2. Deactivate terminal 1
        terminal1.deactivate();
        expect(mapped.isActive, isFalse);

        // 3. Mutate source while terminal 1 is disconnected
        source.set(50);
        expect(sourceTerminal.snapshot.data, 50);

        // 4. Reactivate terminal 1
        terminal1.activate();
        expect(mapped.isActive, isTrue);

        // Q2: B - Reconnection does NOT trigger onInvalidated; pending state is lazily resolved on pull.
        expect(terminal1DirtyCount, 0,
            reason: 'Reactivation preserves pending state without triggering onInvalidated (Q2: B)');
        expect(terminal1.snapshot.data, 100);
        expect(computeCount, 2);

        sourceTerminal.deactivate();
        terminal1.deactivate();
      });

      test('1.2 Computation node preserves cache when source does NOT change during disconnection', () {
        final source = BloomController<int>(10);
        int computeCount = 0;

        final mapped = computed((via) {
          computeCount++;
          return via(source.bloom) * 2;
        });

        int terminalDirtyCount = 0;
        final terminal = RawBloomTerminal(mapped, onInvalidated: () {
          terminalDirtyCount++;
        });

        terminal.activate();
        expect(terminal.snapshot.data, 20);
        expect(computeCount, 1);
        expect(terminalDirtyCount, 0);

        // Deactivate and reactivate without mutation
        terminal.deactivate();
        expect(mapped.isActive, isFalse);

        terminal.activate();
        expect(mapped.isActive, isTrue);

        expect(terminalDirtyCount, 0);
        expect(terminal.snapshot.data, 20);
        expect(computeCount, 1, reason: 'Must use cache');

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 2. Multi-Source Bloom List Inactive Partial Modification
    // =========================================================================
    group('2. Multi-Source Bloom list Inactive Partial Modification', () {
      test('2.1 Multi-source bloom list aggregator detects partial source modification during disconnection', () {
        final source1 = BloomController<int>(1);
        final source2 = BloomController<int>(2);
        final group = Bloom.constant([source1.bloom, source2.bloom]);

        int computeCount = 0;
        final aggregated = computed((via) {
          computeCount++;
          return via(group).fold<int>(0, (sum, item) => sum + via(item));
        });

        int terminalDirtyCount = 0;
        final terminal = RawBloomTerminal(aggregated, onInvalidated: () {
          terminalDirtyCount++;
        });

        final w1 = RawBloomTerminal(source1.bloom, onInvalidated: () {})..activate();
        final w2 = RawBloomTerminal(source2.bloom, onInvalidated: () {})..activate();

        terminal.activate();
        expect(terminal.snapshot.data, 3);
        expect(computeCount, 1);

        terminal.deactivate();

        // Mutate only source1
        source1.set(10);

        terminal.activate();
        // Q2: B - Reconnection does NOT trigger onInvalidated; pending state is lazily resolved on pull.
        expect(terminalDirtyCount, 0,
            reason: 'Reactivation preserves pending state without triggering onInvalidated (Q2: B)');
        expect(terminal.snapshot.data, 12); // 10 + 2
        expect(computeCount, 2);

        w1.deactivate();
        w2.deactivate();
        terminal.deactivate();
      });
    });

    // =========================================================================
    // 3. Standalone Node Inactive Evaluation Coherency
    // =========================================================================
    group('3. Standalone Node Inactive Evaluation Coherency', () {
      test('3.1 Cascading Bloom updates snapshot when inactive and trigger changes', () {
        final trigger = BloomController<int>(1);
        final bloomA = BloomController<String>('A1');
        final bloomB = BloomController<String>('B1');

        int cascadeCallCount = 0;
        final lazyCascade = switched((via) {
          cascadeCallCount++;
          return via(trigger.bloom) == 1 ? bloomA.bloom : bloomB.bloom;
        }, eager: false);

        // Inactive pull
        expect(untracked.state(lazyCascade).snapshot.data, 'A1');
        expect(cascadeCallCount, 1);

        // Mutate trigger while inactive
        trigger.set(2);

        expect(untracked.state(lazyCascade).snapshot.data, 'B1');
        expect(cascadeCallCount, 2);

        // Mutate inner node B
        bloomB.set('B2');
        expect(untracked.state(lazyCascade).snapshot.data, 'B2');
        expect(cascadeCallCount, 2);
      });
    });
  });
}

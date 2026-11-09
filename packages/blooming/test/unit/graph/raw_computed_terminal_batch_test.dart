// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

void main() {
  group('RawComputedTerminal Batch & Cross-Terminal RYOW Tests', () {
    test('1. Read-Your-Own-Writes inside batch() returns fresh computed data', () {
      final count = blooming<int>(1);
      final computedTerminal = RawComputedTerminal<int>(
        (via) => via(count.bloom) * 10,
        onInvalidated: () {},
      )..activate();

      expect(computedTerminal.data, 10);

      batch(() {
        count.data = 2;

        // Inside batch, reading computedTerminal.data must reflect the mutation (20),
        // not the stale cached value (10).
        expect(
          computedTerminal.data,
          20,
          reason: 'Read-Your-Own-Writes must be preserved inside batch()',
        );
      });

      expect(computedTerminal.data, 20);

      computedTerminal.deactivate();
    });

    test('2. Cross-terminal read during Phase 2 flush reads fresh computed data', () {
      final source = blooming<int>(1);
      int? readFromOtherTerminal;

      late final RawComputedTerminal<int> computedTerm;
      late final RawBloomTerminal<int> bloomTerm;

      computedTerm = RawComputedTerminal<int>(
        (via) => via(source.bloom) * 100,
        onInvalidated: () {},
      );

      // bloomTerm is activated first, so it queues first in Phase 2
      bloomTerm = RawBloomTerminal<int>(
        source.bloom,
        onInvalidated: () {
          readFromOtherTerminal = computedTerm.data;
        },
      );

      bloomTerm.activate();
      computedTerm.activate();

      expect(computedTerm.data, 100);

      // Mutate source: both terminals receive invalidation
      source.data = 2;

      // When bloomTerm's onInvalidated runs before computedTerm's onInvalidated,
      // computedTerm must already be marked dirty/check and return fresh data (200).
      expect(
        readFromOtherTerminal,
        200,
        reason: 'Cross-terminal read in Phase 2 must return fresh recomputed value',
      );

      bloomTerm.deactivate();
      computedTerm.deactivate();
    });
  });
}


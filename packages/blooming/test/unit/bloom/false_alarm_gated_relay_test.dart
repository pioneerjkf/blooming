// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

void main() {
  group('Gated Relay Bloom False-Alarm Suppression Tests', () {
    test('1. Bloom.debounced (leading: false, trailing: true) ignores false-alarm dirty pulses', () async {
      final source = blooming<int>(1);
      final isEven = computed<bool>((via) => via(source.bloom) % 2 == 0).distinct();
      final debounced = isEven.debounced(
        const Duration(milliseconds: 50),
        leading: false,
        trailing: true,
      );

      int invalidationCount = 0;
      final terminal = RawBloomTerminal(debounced, onInvalidated: () {
        invalidationCount++;
      });
      terminal.activate();

      // Prime the graph
      expect(terminal.data, isFalse);

      // Trigger a false alarm: 1 -> 3 (isEven remains false -> false)
      source.data = 3;

      // Wait for debounce silence window to elapse:
      await Future<void>.delayed(const Duration(milliseconds: 70));

      // Must NOT emit trailing dirty pulse to downstream terminal!
      expect(
        invalidationCount,
        0,
        reason: 'False alarm must not trigger onInvalidated on downstream terminal',
      );

      // Now trigger a genuine mutation: 3 -> 4 (false -> true)
      source.data = 4;
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(invalidationCount, 1, reason: 'Genuine mutation must trigger onInvalidated');
      expect(terminal.data, isTrue);

      terminal.deactivate();
    });

    test('2. Bloom.throttled (leading: false, trailing: true) ignores false-alarm dirty pulses', () async {
      final source = blooming<int>(1);
      final isEven = computed<bool>((via) => via(source.bloom) % 2 == 0).distinct();
      final throttled = isEven.throttled(
        const Duration(milliseconds: 50),
        leading: false,
        trailing: true,
      );

      int invalidationCount = 0;
      final terminal = RawBloomTerminal(throttled, onInvalidated: () {
        invalidationCount++;
      });
      terminal.activate();

      // Prime the graph
      expect(terminal.data, isFalse);

      // Trigger a false alarm: 1 -> 3
      source.data = 3;
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(
        invalidationCount,
        0,
        reason: 'False alarm must not trigger trailing throttle on downstream terminal',
      );

      // Real mutation: 3 -> 4
      source.data = 4;
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(invalidationCount, 1);
      expect(terminal.data, isTrue);

      terminal.deactivate();
    });

    test('3. Bloom.coalesced (leading: false, trailing: true) ignores false-alarm dirty pulses', () async {
      final source = blooming<int>(1);
      final isEven = computed<bool>((via) => via(source.bloom) % 2 == 0).distinct();
      final coalesced = isEven.coalesced(
        leading: false,
        trailing: true,
      );

      int invalidationCount = 0;
      final terminal = RawBloomTerminal(coalesced, onInvalidated: () {
        invalidationCount++;
      });
      terminal.activate();

      // Prime the graph
      expect(terminal.data, isFalse);

      // Trigger a false alarm: 1 -> 3
      source.data = 3;
      // Wait for microtask / scheduler pass
      await Future<void>.delayed(Duration.zero);

      expect(
        invalidationCount,
        0,
        reason: 'False alarm must not trigger coalesced invalidation on downstream terminal',
      );

      // Real mutation: 3 -> 4
      source.data = 4;
      await Future<void>.delayed(Duration.zero);
      expect(invalidationCount, 1);
      expect(terminal.data, isTrue);

      terminal.deactivate();
    });
  });
}

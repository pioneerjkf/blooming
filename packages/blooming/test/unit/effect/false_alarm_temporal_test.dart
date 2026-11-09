// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';
import 'package:test/test.dart';

void main() {
  group('Temporal Effects False-Alarm Invalidation Suppression Tests', () {
    test('1. Debounce (leading: false, trailing: true) ignores false-alarm dirty pulses from derived nodes', () async {
      final source = blooming<int>(1);
      final isEven = computed((via) => via(source.bloom) % 2 == 0).distinct();
      final observed = <bool>[];

      final effect = isEven.effect.debounce(
        const Duration(milliseconds: 50),
        () => observed.add(untracked(isEven)),
      );
      final runner = effect.start();

      // Trigger a false alarm: 1 -> 3. Source changes (notifying downstream in Phase 1),
      // but isEven remains false (false -> false).
      source.data = 3;

      // Wait for debounce silence window to elapse:
      await Future<void>.delayed(const Duration(milliseconds: 70));

      // Must NOT execute action because isEven never changed!
      expect(observed, isEmpty, reason: 'False alarm from derived node must not trigger debounce action');

      // Now trigger a genuine mutation: 3 -> 4 (false -> true).
      source.data = 4;
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(observed, [true], reason: 'Genuine mutation must trigger debounce action');

      runner.stop();
    });

    test('2. Debounce (leading: true, trailing: false) does not enter cooldown on false alarm', () async {
      final source = blooming<int>(1);
      final isEven = computed((via) => via(source.bloom) % 2 == 0).distinct();
      final observed = <bool>[];

      final effect = isEven.effect.debounce(
        const Duration(milliseconds: 50),
        () => observed.add(untracked(isEven)),
        leading: true,
        trailing: false,
      );
      final runner = effect.start();

      // False alarm: 1 -> 3 (false -> false)
      source.data = 3;
      await Future<void>.delayed(Duration.zero);
      expect(observed, isEmpty, reason: 'Leading edge must not fire on false alarm');

      // Immediate real mutation right after false alarm: 3 -> 4 (false -> true).
      // If cooldown was mistakenly locked, this leading execution would be suppressed.
      source.data = 4;
      await Future<void>.delayed(Duration.zero);
      expect(observed, [true], reason: 'Real mutation must immediately fire leading edge');

      runner.stop();
    });

    test('3. Debounce (leading: true, trailing: true) suppresses false alarm completely', () async {
      final source = blooming<int>(1);
      final isEven = computed((via) => via(source.bloom) % 2 == 0).distinct();
      final observed = <bool>[];

      final effect = isEven.effect.debounce(
        const Duration(milliseconds: 50),
        () => observed.add(untracked(isEven)),
        leading: true,
        trailing: true,
      );
      final runner = effect.start();

      // False alarm: 1 -> 3
      source.data = 3;
      await Future<void>.delayed(Duration.zero);
      expect(observed, isEmpty, reason: 'Leading must not fire on false alarm');

      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(observed, isEmpty, reason: 'Trailing must not fire on false alarm');

      runner.stop();
    });

    test('4. Throttle (leading: false, trailing: true) ignores false-alarm dirty pulses', () async {
      final source = blooming<int>(1);
      final isEven = computed((via) => via(source.bloom) % 2 == 0).distinct();
      final observed = <bool>[];

      final effect = isEven.effect.throttle(
        const Duration(milliseconds: 50),
        () => observed.add(untracked(isEven)),
        leading: false,
        trailing: true,
      );
      final runner = effect.start();

      // False alarm: 1 -> 3
      source.data = 3;
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(observed, isEmpty, reason: 'Trailing throttle must not fire on false alarm');

      // Real mutation: 3 -> 4
      source.data = 4;
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(observed, [true]);

      runner.stop();
    });

    test('5. Throttle (leading: true, trailing: true) suppresses false alarm completely', () async {
      final source = blooming<int>(1);
      final isEven = computed((via) => via(source.bloom) % 2 == 0).distinct();
      final observed = <bool>[];

      final effect = isEven.effect.throttle(
        const Duration(milliseconds: 50),
        () => observed.add(untracked(isEven)),
        leading: true,
        trailing: true,
      );
      final runner = effect.start();

      // False alarm: 1 -> 3
      source.data = 3;
      await Future<void>.delayed(Duration.zero);
      expect(observed, isEmpty, reason: 'Leading throttle must not fire on false alarm');

      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(observed, isEmpty, reason: 'Trailing throttle must not fire on false alarm');

      runner.stop();
    });
  }, skip: 'TODO: 잔여 과제 - Temporal Effect false-alarm suppression');
}

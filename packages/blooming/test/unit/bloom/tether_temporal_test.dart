// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';
import 'package:test/test.dart';

void main() {
  group('Tether Throttle, Debounce & Scope Effect Extensions Suite', () {
    test('1. ThrottleEffect.unary throttles mutations within scope lifecycle', () async {
      final clicks = BloomController(0);
      int runs = 0;

      final effect = ThrottleEffect.unary(
        clicks.bloom,
        const Duration(milliseconds: 50),
        () => runs++,
      );
      final terminal = RawViaTerminal((via) => via.tether(effect), onInvalidated: () {})
        ..activate()
        ..evaluate();

      clicks.data = 1;
      await Future<void>.delayed(Duration.zero);
      expect(runs, 1);

      clicks.data = 2;
      clicks.data = 3;
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(runs, 2);

      terminal.deactivate();
    });

    test('2. DebounceEffect.unary debounces mutations within scope lifecycle', () async {
      final text = BloomController('');
      final observed = <String>[];

      final effect = DebounceEffect.unary(
        text.bloom,
        const Duration(milliseconds: 50),
        () => observed.add(text.data),
      );
      final terminal = RawViaTerminal((via) => via.tether(effect), onInvalidated: () {})
        ..activate()
        ..evaluate();

      text.data = 'a';
      await Future<void>.delayed(const Duration(milliseconds: 20));
      text.data = 'ab';
      await Future<void>.delayed(const Duration(milliseconds: 20));
      text.data = 'abc';

      expect(observed, []);

      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(observed, ['abc']);

      terminal.deactivate();
    });

    test('3. Multi-target DebounceEffect([min, max])', () async {
      final min = BloomController(10);
      final max = BloomController(100);
      int runs = 0;

      final effect = DebounceEffect(
        [min.bloom, max.bloom],
        const Duration(milliseconds: 50),
        () => runs++,
      );
      final terminal = RawViaTerminal((via) => via.tether(effect), onInvalidated: () {})
        ..activate()
        ..evaluate();

      min.data = 15;
      max.data = 95;
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(runs, 1);

      terminal.deactivate();
    });

    test('4. Effect.unary(take: n) auto-deactivates after limit', () async {
      final count = BloomController(0);
      int runs = 0;

      final effect = Effect.unary(count.bloom, () {
        runs++;
      }, take: 1);
      final terminal = RawViaTerminal((via) => via.tether(effect), onInvalidated: () {})
        ..activate()
        ..evaluate();

      count.data = 1;
      await Future<void>.delayed(Duration.zero);
      expect(runs, 1);

      count.data = 2;
      await Future<void>.delayed(Duration.zero);
      expect(runs, 1);

      terminal.deactivate();
    });

    test('5. Scope-bound via.tether(bloom.throttle(...)) throttles within scope lifecycle', () async {
      final clicks = BloomController(0);
      int runs = 0;

      final terminal = RawViaTerminal(
        (via) {
          via.tether(clicks.bloom.effect.throttle(
            const Duration(milliseconds: 50),
            () => runs++,
          ));
          return true;
        },
        onInvalidated: () {},
      );

      terminal.activate();
      terminal.evaluate();

      clicks.data = 1;
      await Future<void>.delayed(Duration.zero);
      expect(runs, 1);

      clicks.data = 2;
      clicks.data = 3;
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(runs, 2);

      terminal.deactivate();
    });

    test('6. Scope-bound via.tether(bloom.debounce(...)) debounces within scope lifecycle', () async {
      final text = BloomController('');
      final observed = <String>[];

      final terminal = RawViaTerminal(
        (via) {
          via.tether(text.bloom.effect.debounce(
            const Duration(milliseconds: 50),
            () => observed.add(text.data),
          ));
          return true;
        },
        onInvalidated: () {},
      );

      terminal.activate();
      terminal.evaluate();

      text.data = 'a';
      await Future<void>.delayed(const Duration(milliseconds: 20));
      text.data = 'ab';
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(observed, ['ab']);

      terminal.deactivate();
    });
  });
}

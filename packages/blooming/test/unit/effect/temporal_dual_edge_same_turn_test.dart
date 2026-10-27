// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';
import 'package:test/test.dart';

void main() {
  group('Dual-Edge (leading: true, trailing: true) Same-Turn Multiple Mutations Suite', () {
    test('Debounce effect: leading: true, trailing: true fires trailing after burst in same turn', () async {
      final input = blooming<String>('');
      final observed = <String>[];

      final myEffect = Effect.debounce.unary(
        input.bloom,
        const Duration(milliseconds: 50),
        () => observed.add(input.data),
        leading: true,
        trailing: true,
      );
      final runner = myEffect.start();

      // Mutate twice in the same event loop turn:
      input.set('a');
      input.set('b');

      // Allow leading microtask to execute:
      await Future<void>.delayed(Duration.zero);
      expect(observed, ['b'], reason: 'Leading edge must fire');

      // Wait for debounce silence window to elapse:
      await Future<void>.delayed(const Duration(milliseconds: 70));

      // Trailing edge must fire because a second mutation occurred!
      expect(observed, ['b', 'b'], reason: 'Trailing edge must fire after silence window');

      runner.stop();
    });

    test('Throttle effect: leading: true, trailing: true fires trailing after burst in same turn', () async {
      final input = blooming<String>('');
      final observed = <String>[];

      final myEffect = Effect.throttle.unary(
        input.bloom,
        const Duration(milliseconds: 50),
        () => observed.add(input.data),
        leading: true,
        trailing: true,
      );
      final runner = myEffect.start();

      // Mutate twice in the same event loop turn:
      input.set('a');
      input.set('b');

      // Allow leading microtask to execute:
      await Future<void>.delayed(Duration.zero);
      expect(observed, ['b'], reason: 'Leading edge must fire');

      // Wait for throttle window to elapse:
      await Future<void>.delayed(const Duration(milliseconds: 70));

      // Trailing edge must fire because a second mutation occurred!
      expect(observed, ['b', 'b'], reason: 'Trailing edge must fire after throttle window');

      runner.stop();
    });

    test('Bloom.debounced: leading: true, trailing: true emits trailing after burst in same turn', () async {
      final state = blooming('A');
      final debounced = state.bloom.debounced(
        const Duration(milliseconds: 50),
        leading: true,
        trailing: true,
      );

      final observed = <String>[untracked(debounced)];
      final terminal = RawBloomTerminal(debounced, onInvalidated: () {
        observed.add(untracked(debounced));
      });
      terminal.activate();

      // Mutate twice in same turn:
      state.data = 'B';
      state.data = 'C';

      expect(observed, ['A', 'B'], reason: 'Leading edge fires synchronously on first mutation');

      // Wait for silence
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(observed, ['A', 'B', 'C'], reason: 'Trailing edge must fire after silence window');

      terminal.deactivate();
    });
  });
}

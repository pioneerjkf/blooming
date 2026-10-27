// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';
import 'package:test/test.dart';

void main() {
  group('Bloom Effect Extensions Comprehensive Unit Tests', () {
    // -------------------------------------------------------------------------
    // 1. BloomEffectExtension
    // -------------------------------------------------------------------------
    group('1. BloomEffectExtension', () {
      test('1.1 Single bloom effect, throttle, and debounce unary dispatch', () async {
        final a = blooming<int>(0);
        final observedEffect = <int>[];
        final observedThrottle = <int>[];
        final observedDebounce = <int>[];

        final e1 = a.bloom.effect(() => observedEffect.add(a.data));
        final e2 = a.bloom.effect.throttle(const Duration(milliseconds: 50), () => observedThrottle.add(a.data));
        final e3 = a.bloom.effect.debounce(
          const Duration(milliseconds: 50),
          () => observedDebounce.add(a.data),
          leading: true,
          trailing: true,
        );

        expect(e1, isA<Effect>());
        expect(e2, isA<Effect>());
        expect(e3, isA<Effect>());

        final terminal = RawViaTerminal((via) {
          via.tether(e1);
          via.tether(e2);
          via.tether(e3);
        }, onInvalidated: () {});
        terminal.activate();
        terminal.evaluate();

        // 1st mutation:
        a.set(1);
        await Future<void>.delayed(Duration.zero);
        expect(observedEffect, [1]);
        expect(observedThrottle, [1], reason: 'Throttle leading edge');
        expect(observedDebounce, [1], reason: 'Debounce leading edge');

        // Burst mutations:
        a.set(2);
        a.set(3);
        await Future<void>.delayed(Duration.zero);
        expect(observedEffect, [1, 3], reason: 'Effect fires for mutated frame');
        expect(observedThrottle, [1], reason: 'Throttle suppresses burst');
        expect(observedDebounce, [1], reason: 'Debounce suppresses burst');

        // Wait for time windows to elapse
        await Future<void>.delayed(const Duration(milliseconds: 70));
        expect(observedThrottle, [1, 3], reason: 'Throttle trailing edge');
        expect(observedDebounce, [1, 3], reason: 'Debounce trailing edge');

        terminal.deactivate();
      });
    });

    // -------------------------------------------------------------------------
    // 2. BloomRecord2EffectExtension
    // -------------------------------------------------------------------------
    // 2. BloomRecord2EffectExtension
    // -------------------------------------------------------------------------
    group('2. BloomRecord2EffectExtension', () {
      test('2.1 blooms getter exposes both nodes', () {
        final a = blooming<int>(1);
        final b = blooming<String>('x');
        final pair = (a.bloom, b.bloom);
        expect(pair.blooms, [a.bloom, b.bloom]);
      });

      test('2.2 (a.bloom, b.bloom).debounce with dual-edge (leading: true, trailing: true)', () async {
        final a = blooming<int>(0);
        final b = blooming<int>(0);
        final observed = <String>[];

        final effect = (a.bloom, b.bloom).effect.debounce(
              const Duration(milliseconds: 50),
              () => observed.add('${a.data},${b.data}'),
              leading: true,
              trailing: true,
            );

        final terminal = RawViaTerminal((via) => via.tether(effect), onInvalidated: () {})
          ..activate()
          ..evaluate();

        a.set(1);
        await Future<void>.delayed(Duration.zero);
        expect(observed, ['1,0']);

        b.set(2);
        a.set(3);
        await Future<void>.delayed(const Duration(milliseconds: 70));
        expect(observed, ['1,0', '3,2']);

        terminal.deactivate();
      });

      test('2.3 (a.bloom, b.bloom).throttle with dual-edge', () async {
        final a = blooming<int>(0);
        final b = blooming<int>(0);
        var runs = 0;

        final effect = (a.bloom, b.bloom).effect.throttle(
              const Duration(milliseconds: 40),
              () => runs++,
              leading: true,
              trailing: true,
            );

        final terminal = RawViaTerminal((via) => via.tether(effect), onInvalidated: () {})
          ..activate()
          ..evaluate();

        a.set(1);
        await Future<void>.delayed(Duration.zero);
        expect(runs, 1);

        b.set(2);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(runs, 2);

        terminal.deactivate();
      });
    });

    // -------------------------------------------------------------------------
    // 3. BloomRecord3EffectExtension ~ BloomRecord5EffectExtension
    // -------------------------------------------------------------------------
    group('3. Higher Tuple Extensions (Record3, Record4, Record5)', () {
      test('3.1 3-tuple debounce and throttle', () async {
        final a = blooming<int>(0);
        final b = blooming<int>(0);
        final c = blooming<int>(0);
        final triplet = (a.bloom, b.bloom, c.bloom);
        expect(triplet.blooms, [a.bloom, b.bloom, c.bloom]);

        final observed = <int>[];
        final effect = triplet.effect.debounce(
          const Duration(milliseconds: 40),
          () => observed.add(a.data + b.data + c.data),
          leading: true,
          trailing: true,
        );

        final terminal = RawViaTerminal((via) => via.tether(effect), onInvalidated: () {})
          ..activate()
          ..evaluate();

        a.set(1);
        await Future<void>.delayed(Duration.zero);
        expect(observed, [1]);

        b.set(2);
        c.set(3);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(observed, [1, 6]);

        terminal.deactivate();
      });

      test('3.2 4-tuple debounce and throttle', () async {
        final a = blooming<int>(1);
        final b = blooming<int>(1);
        final c = blooming<int>(1);
        final d = blooming<int>(1);
        final quad = (a.bloom, b.bloom, c.bloom, d.bloom);
        expect(quad.blooms, [a.bloom, b.bloom, c.bloom, d.bloom]);

        var runs = 0;
        final effect = quad.effect.throttle(
          const Duration(milliseconds: 40),
          () => runs++,
        );

        final terminal = RawViaTerminal((via) => via.tether(effect), onInvalidated: () {})
          ..activate()
          ..evaluate();

        d.set(10);
        await Future<void>.delayed(Duration.zero);
        expect(runs, 1);

        terminal.deactivate();
      });

      test('3.3 5-tuple debounce and throttle', () async {
        final a = blooming<int>(0);
        final b = blooming<int>(0);
        final c = blooming<int>(0);
        final d = blooming<int>(0);
        final e = blooming<int>(0);
        final pentad = (a.bloom, b.bloom, c.bloom, d.bloom, e.bloom);
        expect(pentad.blooms, [a.bloom, b.bloom, c.bloom, d.bloom, e.bloom]);

        final observed = <int>[];
        final effect = pentad.effect.debounce(
          const Duration(milliseconds: 40),
          () => observed.add(a.data + b.data + c.data + d.data + e.data),
          leading: false,
          trailing: true,
        );

        final terminal = RawViaTerminal((via) => via.tether(effect), onInvalidated: () {})
          ..activate()
          ..evaluate();

        a.set(1);
        b.set(2);
        c.set(3);
        d.set(4);
        e.set(5);
        expect(observed, []);

        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(observed, [15]);

        terminal.deactivate();
      });
    });

    // -------------------------------------------------------------------------
    // 4. BloomIterableEffectExtension
    // -------------------------------------------------------------------------
    group('4. BloomIterableEffectExtension', () {
      test('4.1 Iterable blooms getter and debounce with leading & trailing', () async {
        final list = [
          blooming<int>(10).bloom,
          blooming<int>(20).bloom,
          blooming<int>(30).bloom,
        ];
        expect(list.blooms, list);

        final a = blooming<int>(10);
        final b = blooming<int>(20);
        final c = blooming<int>(30);
        final bloomList = [a.bloom, b.bloom, c.bloom];

        final observed = <int>[];
        final effect = bloomList.effect.debounce(
          const Duration(milliseconds: 40),
          () => observed.add(a.data + b.data + c.data),
          leading: true,
          trailing: true,
        );

        final terminal = RawViaTerminal((via) => via.tether(effect), onInvalidated: () {})
          ..activate()
          ..evaluate();

        // Mutate first item: Leading edge
        a.set(15);
        await Future<void>.delayed(Duration.zero);
        expect(observed, [65]);

        // Burst mutations
        b.set(25);
        c.set(35);

        // Silence elapsed
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(observed, [65, 75]);

        terminal.deactivate();
      });

      test('4.2 Iterable throttle with take limit', () async {
        final a = blooming<int>(1);
        final b = blooming<int>(2);
        final blooms = [a.bloom, b.bloom];
        int runs = 0;

        final effect = blooms.effect.throttle(
          const Duration(milliseconds: 40),
          () => runs++,
          take: 1,
        );

        final terminal = RawViaTerminal((via) => via.tether(effect), onInvalidated: () {})
          ..activate()
          ..evaluate();

        a.set(5);
        await Future<void>.delayed(Duration.zero);
        expect(runs, 1);

        b.set(10);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(runs, 1, reason: 'take: 1 exhausts after 1 execution');

        terminal.deactivate();
      });
    });

    // -------------------------------------------------------------------------
    // 5. Guard & Ticket Preservation with Extensions
    // -------------------------------------------------------------------------
    group('5. Guard & Ticket Preservation with Extensions', () {
      test('5.1 Tuple debounce respects guard condition and preserves take tickets', () async {
        final a = blooming<int>(0);
        final b = blooming<int>(0);
        bool shouldExecute = false;
        int runs = 0;

        final effect = (a.bloom, b.bloom).effect.debounce(
              const Duration(milliseconds: 40),
              () => runs++,
              guard: () => shouldExecute,
              take: 1,
            );

        final terminal = RawViaTerminal((via) => via.tether(effect), onInvalidated: () {})
          ..activate()
          ..evaluate();

        // Mutation while guard is false:
        a.set(1);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(runs, 0, reason: 'Guard blocked execution');

        // Mutation after guard becomes true:
        shouldExecute = true;
        b.set(2);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(runs, 1, reason: 'Ticket was preserved and executed when guard was true');

        // Subsequent mutation exhausts ticket
        a.set(3);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(runs, 1, reason: 'Ticket count is now exhausted');

        terminal.deactivate();
      });
    });
  });
}

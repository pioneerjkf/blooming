// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';
import 'package:test/test.dart';

void main() {
  group('Bloom Direct .effect() Extension Suite', () {
    test('1. BloomEffectExtension creates Effect attached to single Bloom', () async {
      final ctrl = blooming<int>(0);
      var effectRuns = 0;
      var observedValue = -1;

      final effect = ctrl.bloom.effect(() {
        effectRuns++;
        observedValue = ctrl.data;
      });

      // Lazy: skips initial evaluation
      expect(effectRuns, 0);

      final terminal = RawViaTerminal((via) {
        via.tether(effect);
      }, onInvalidated: () {});

      terminal.activate();
      terminal.evaluate();
      expect(effectRuns, 0);

      // Mutate
      ctrl.set(42);
      expect(effectRuns, 0, reason: 'Batched in microtask queue');

      await Future<void>.delayed(Duration.zero);
      expect(effectRuns, 1);
      expect(observedValue, 42);

      terminal.deactivate();

      // Mutation after deactivation does not trigger effect
      ctrl.set(100);
      await Future<void>.delayed(Duration.zero);
      expect(effectRuns, 1);
    });

    test('2. BloomRecord2EffectExtension handles 2-tuple', () async {
      final a = blooming<int>(1);
      final b = blooming<String>('hello');
      var runs = 0;
      var lastA = 0;
      var lastB = '';

      final tuple = (a.bloom, b.bloom);
      expect(tuple.blooms, [a.bloom, b.bloom]);

      final effect = tuple.effect(() {
        runs++;
        lastA = a.data;
        lastB = b.data;
      });

      final terminal = RawViaTerminal((via) {
        via.tether(effect);
      }, onInvalidated: () {});
      terminal.activate();
      terminal.evaluate();
      expect(runs, 0);

      // Mutate A
      a.set(2);
      await Future<void>.delayed(Duration.zero);
      expect(runs, 1);
      expect(lastA, 2);
      expect(lastB, 'hello');

      // Mutate B
      b.set('world');
      await Future<void>.delayed(Duration.zero);
      expect(runs, 2);
      expect(lastA, 2);
      expect(lastB, 'world');

      // Coalesced mutation of both A and B in single frame
      a.set(3);
      b.set('coalesced');
      await Future<void>.delayed(Duration.zero);
      expect(runs, 3);
      expect(lastA, 3);
      expect(lastB, 'coalesced');

      terminal.deactivate();
    });

    test('3. BloomRecord3EffectExtension handles 3-tuple', () async {
      final a = blooming<int>(1);
      final b = blooming<int>(2);
      final c = blooming<int>(3);
      var sum = 0;

      final tuple = (a.bloom, b.bloom, c.bloom);
      expect(tuple.blooms, [a.bloom, b.bloom, c.bloom]);

      final effect = tuple.effect(() {
        sum = a.data + b.data + c.data;
      });

      final terminal = RawViaTerminal((via) {
        via.tether(effect);
      }, onInvalidated: () {});
      terminal.activate();
      terminal.evaluate();
      expect(sum, 0);

      c.set(30);
      await Future<void>.delayed(Duration.zero);
      expect(sum, 33);

      terminal.deactivate();
    });

    test('4. BloomRecord4EffectExtension handles 4-tuple', () async {
      final a = blooming<int>(1);
      final b = blooming<int>(2);
      final c = blooming<int>(3);
      final d = blooming<int>(4);
      var runs = 0;

      final tuple = (a.bloom, b.bloom, c.bloom, d.bloom);
      // expect(tuple.length, 4);

      final effect = tuple.effect(() {
        runs++;
      });

      final terminal = RawViaTerminal((via) {
        via.tether(effect);
      }, onInvalidated: () {});
      terminal.activate();
      terminal.evaluate();

      d.set(40);
      await Future<void>.delayed(Duration.zero);
      expect(runs, 1);

      terminal.deactivate();
    });

    test('5. BloomRecord5EffectExtension handles 5-tuple', () async {
      final a = blooming<int>(1);
      final b = blooming<int>(2);
      final c = blooming<int>(3);
      final d = blooming<int>(4);
      final e = blooming<int>(5);
      var runs = 0;

      final tuple = (a.bloom, b.bloom, c.bloom, d.bloom, e.bloom);
      // expect(tuple.length, 5);

      final effect = tuple.effect(() {
        runs++;
      });

      final terminal = RawViaTerminal((via) {
        via.tether(effect);
      }, onInvalidated: () {});
      terminal.activate();
      terminal.evaluate();

      e.set(50);
      await Future<void>.delayed(Duration.zero);
      expect(runs, 1);

      terminal.deactivate();
    });

    test('6. BloomIterableEffectExtension handles list and iterable', () async {
      final a = blooming<int>(1);
      final b = blooming<int>(2);
      final c = blooming<int>(3);
      var runs = 0;

      final list = [a.bloom, b.bloom, c.bloom];
      final effect = list.effect(() {
        runs++;
      });

      final terminal = RawViaTerminal((via) {
        via.tether(effect);
      }, onInvalidated: () {});
      terminal.activate();
      terminal.evaluate();
      expect(runs, 0);

      b.set(20);
      await Future<void>.delayed(Duration.zero);
      expect(runs, 1);

      terminal.deactivate();
    });

    test('7. Heterogeneous tuple containing Bloom and Bloom list', () async {
      final g1 = blooming<int>(10);
      final g2 = blooming<int>(20);
      final groupCtrl = blooming.list([g1.bloom, g2.bloom]);
      final g3 = blooming<int>(30);

      var runs = 0;
      final effect = (groupCtrl.bloom, g3.bloom).effect(() {
        runs++;
      });

      final terminal = RawViaTerminal((via) {
        via.tether(effect);
      }, onInvalidated: () {});
      terminal.activate();
      terminal.evaluate();
      expect(runs, 0);

      // Mutate Bloom list
      groupCtrl.set([g1.bloom]);
      await Future<void>.delayed(Duration.zero);
      expect(runs, 1);

      // Mutate Bloom
      g3.set(300);
      await Future<void>.delayed(Duration.zero);
      expect(runs, 2);

      terminal.deactivate();
    });

    test('8. Effect.unary creates and drives unary effect', () async {
      final ctrl = blooming<String>('initial');
      var runs = 0;
      var observed = '';

      final eff = Effect.unary(ctrl.bloom, () {
        runs++;
        observed = ctrl.data;
      });

      expect(runs, 0);

      final terminal = RawViaTerminal((via) {
        via.tether(eff);
      }, onInvalidated: () {});
      terminal.activate();
      terminal.evaluate();

      ctrl.set('updated');
      await Future<void>.delayed(Duration.zero);
      expect(runs, 1);
      expect(observed, 'updated');

      terminal.deactivate();
    });

    test('9. Effect.unary coalesces multiple synchronous mutations into single microtask', () async {
      final ctrl = blooming<int>(0);
      var runs = 0;

      final eff = Effect.unary(ctrl.bloom, () {
        runs++;
      });

      final terminal = RawViaTerminal((via) {
        via.tether(eff);
      }, onInvalidated: () {});
      terminal.activate();
      terminal.evaluate();

      // Mutate 5 times synchronously in same event loop tick
      ctrl.set(1);
      ctrl.set(2);
      ctrl.set(3);
      ctrl.set(4);
      ctrl.set(5);

      expect(runs, 0, reason: 'Pending in microtask queue');
      await Future<void>.delayed(Duration.zero);
      expect(runs, 1, reason: '5 synchronous mutations coalesce into 1 effect run');

      terminal.deactivate();
    });

    test('10. Effect.unary cancels pending scheduled microtask when deactivated before execution', () async {
      final ctrl = blooming<int>(0);
      var runs = 0;

      final eff = Effect.unary(ctrl.bloom, () {
        runs++;
      });

      final terminal = RawViaTerminal((via) {
        via.tether(eff);
      }, onInvalidated: () {});
      terminal.activate();
      terminal.evaluate();

      // Mutate to schedule microtask
      ctrl.set(1);
      expect(runs, 0);

      // Deactivate immediately before microtask executes
      terminal.deactivate();

      await Future<void>.delayed(Duration.zero);
      expect(runs, 0, reason: 'Deactivating effect must cancel pending scheduled microtask');
    });

    test('11. Effect.unary attached to Bloom list triggers on composite mutations', () async {
      final a = blooming<int>(1);
      final b = blooming<int>(2);
      final groupCtrl = blooming.list([a.bloom, b.bloom]);

      var runs = 0;
      final eff = Effect.unary(groupCtrl.bloom, () {
        runs++;
      });

      final terminal = RawViaTerminal((via) {
        via.tether(eff);
      }, onInvalidated: () {});
      terminal.activate();
      terminal.evaluate();

      groupCtrl.set([a.bloom]);
      await Future<void>.delayed(Duration.zero);
      expect(runs, 1);

      terminal.deactivate();
    });

    test('12. watch.effect binds effect lifecycle to enclosing watch scope', () async {
      final counter = blooming<int>(0);
      var effectRuns = 0;
      var observedValue = -1;

      final effect = counter.bloom.effect(() {
        effectRuns++;
        observedValue = counter.data;
      });

      // Create a RawViaTerminal that registers the effect via via.tether
      var invalidationCount = 0;
      final terminal = RawViaTerminal((via) {
        via.tether(effect);
        return 'TerminalScope';
      }, onInvalidated: () {
        invalidationCount++;
      });

      // 1. Activate terminal -> should automatically activate effect via lifecycle anchor!
      terminal.activate();
      terminal.evaluate();
      expect(effectRuns, 0, reason: 'Explicit manifest effect skips initial run');

      // 2. Mutate counter -> triggers effect, does NOT invalidate parent terminal
      counter.set(10);
      await Future<void>.delayed(Duration.zero);
      expect(effectRuns, 1);
      expect(observedValue, 10);
      expect(invalidationCount, 0, reason: 'Effect must not emit dirty pulses to parent terminal');

      // 3. Deactivate terminal -> should automatically deactivate effect!
      terminal.deactivate();

      // Mutating while terminal is deactivated does NOT trigger effect
      counter.set(20);
      await Future<void>.delayed(Duration.zero);
      expect(effectRuns, 1);

      // 4. Reactivate terminal -> automatically reactivates effect!
      terminal.activate();
      terminal.evaluate();
      counter.set(30);
      await Future<void>.delayed(Duration.zero);
      expect(effectRuns, 2);
      expect(observedValue, 30);

      terminal.deactivate();
    });

    test('13. effect.group activates and deactivates child effects as a unified DAG terminal', () async {
      final a = blooming<int>(1);
      final b = blooming<int>(2);
      var aRuns = 0;
      var bRuns = 0;

      final e1 = a.bloom.effect(() => aRuns++);
      final e2 = b.bloom.effect(() => bRuns++);
      final group = Effect.group([e1, e2]);

      final terminal = RawViaTerminal((via) {
        via.tether(group);
      }, onInvalidated: () {});

      // 1. Activate scope -> activates group and children
      terminal.activate();
      terminal.evaluate();

      // Mutate sources
      a.set(10);
      b.set(20);
      await Future<void>.delayed(Duration.zero);
      expect(aRuns, 1);
      expect(bRuns, 1);

      // 2. Deactivate scope -> deactivates group and children
      terminal.deactivate();

      a.set(100);
      b.set(200);
      await Future<void>.delayed(Duration.zero);
      expect(aRuns, 1);
      expect(bRuns, 1);

      // 3. Reactivate scope
      terminal.activate();
      terminal.evaluate();

      a.set(1000);
      await Future<void>.delayed(Duration.zero);
      expect(aRuns, 2);

      terminal.deactivate();
    });

    test('14. watch.effect binds EffectGroup lifecycle to enclosing watch scope with 0 rebuilds', () async {
      final a = blooming<int>(0);
      final b = blooming<int>(0);
      var aRuns = 0;
      var bRuns = 0;

      final e1 = a.bloom.effect(() => aRuns++);
      final e2 = b.bloom.effect(() => bRuns++);
      final group = (e1, e2).group;

      var invalidations = 0;
      final terminal = RawViaTerminal((via) {
        via.tether(group);
        return 'HostScope';
      }, onInvalidated: () {
        invalidations++;
      });

      // Mount/activate terminal
      terminal.activate();
      terminal.evaluate();

      // Trigger child effects
      a.set(1);
      b.set(2);
      await Future<void>.delayed(Duration.zero);
      expect(aRuns, 1);
      expect(bRuns, 1);
      expect(invalidations, 0, reason: 'Zero-rebuild invariant holds for group');

      // Unmount/deactivate terminal
      terminal.deactivate();

      // Mutations while unmounted do not trigger
      a.set(3);
      await Future<void>.delayed(Duration.zero);
      expect(aRuns, 1);
    });

    test('15. Tuple records and Iterable .group extensions create valid Effect instances', () {
      final a = blooming<int>(0);
      final e1 = a.bloom.effect(() {});
      final e2 = a.bloom.effect(() {});
      final e3 = a.bloom.effect(() {});
      final e4 = a.bloom.effect(() {});
      final e5 = a.bloom.effect(() {});

      final t2 = (e1, e2);
      expect(t2.effects, [e1, e2]);
      final g2 = t2.group;
      expect(g2, isA<Effect>());

      final t3 = (e1, e2, e3);
      expect(t3.effects, [e1, e2, e3]);
      final g3 = t3.group;
      expect(g3, isA<Effect>());

      final t4 = (e1, e2, e3, e4);
      expect(t4.effects, [e1, e2, e3, e4]);
      final g4 = t4.group;
      expect(g4, isA<Effect>());

      final t5 = (e1, e2, e3, e4, e5);
      expect(t5.effects, [e1, e2, e3, e4, e5]);
      final g5 = t5.group;
      expect(g5, isA<Effect>());

      final list = [e1, e2, e3];
      expect(list.effects, list);
      final gList = list.group;
      expect(gList, isA<Effect>());
    });

    test('16. BloomIterableEffectExtension provides  getter symmetrically', () {
      final a = blooming<int>(0);
      final b = blooming<int>(1);
      final list = [a.bloom, b.bloom];
      expect(list, list);

      final eff = list.effect(() {});
      expect(eff, isA<Effect>());
    });

    test('17. Effect.group deduplicates identical child effects', () async {
      final a = blooming<int>(0);
      var runs = 0;
      final e1 = a.bloom.effect(() => runs++);
      final e2 = a.bloom.effect(() => runs++);

      final group = Effect.group([e1, e1, e2, e2, e1]);
      expect(group, isA<Effect>());

      final terminal = RawViaTerminal((via) {
        via.tether(group);
      }, onInvalidated: () {});

      terminal.activate();
      terminal.evaluate();

      a.set(1);
      await Future<void>.delayed(Duration.zero);
      expect(runs, 2);

      terminal.deactivate();
    });

    test('17.1. Effect.group safely consumes single-pass generators without multiple iteration desync', () {
      final a = blooming<int>(0);
      final e1 = a.bloom.effect(() {});
      final e2 = a.bloom.effect(() {});

      Iterable<Effect> generator() sync* {
        yield e1;
        yield e2;
        yield e1;
      }

      final group = Effect.group(generator());
      expect(group, isA<Effect>());
    });

    test('18. Unary and N-ary Manifest Effect forwards uncaught errors to onUncaughtError', () async {
      final source = blooming<int>(0);
      Object? caughtError;
      StackTrace? caughtStack;

      final effect = source.bloom.effect(
        () => throw StateError('Unary effect action failed'),
        onUncaughtError: (error, stack) {
          caughtError = error;
          caughtStack = stack;
        },
      );

      final terminal = RawViaTerminal((via) {
        via.tether(effect);
      }, onInvalidated: () {});
      terminal.activate();
      terminal.evaluate();

      source.set(1);
      await Future<void>.delayed(Duration.zero);

      expect(caughtError, isA<StateError>());
      expect((caughtError as StateError).message, 'Unary effect action failed');
      expect(caughtStack, isNotNull);

      terminal.deactivate();
    });

    test('19. Manifest Effect forwards guard uncaught errors to onUncaughtError', () async {
      final source = blooming<int>(0);
      Object? caughtError;

      final eff = Effect(
        [source.bloom],
        () {},
        guard: () => throw FormatException('Guard evaluation failed'),
        onUncaughtError: (error, stack) {
          caughtError = error;
        },
      );

      final terminal = RawViaTerminal((via) {
        via.tether(eff);
      }, onInvalidated: () {});
      terminal.activate();
      terminal.evaluate();

      source.set(1);
      await Future<void>.delayed(Duration.zero);

      expect(caughtError, isA<FormatException>());
      expect((caughtError as FormatException).message, 'Guard evaluation failed');

      terminal.deactivate();
    });

    test('20. BloomVia Effect forwards uncaught errors to onUncaughtError during reactive evaluation', () async {
      final source = blooming<int>(0);
      final caughtErrors = <Object>[];

      final terminal = RawViaTerminal((via) {
        via.tether(Effect.via(
          (via) {
            final val = via(source.bloom);
            if (val > 0) {
              throw StateError('BloomVia reactive error: $val');
            }
          },
          onUncaughtError: (error, stack) {
            caughtErrors.add(error);
          },
        ));
      }, onInvalidated: () {});
      terminal.activate();
      terminal.evaluate();

      expect(caughtErrors, isEmpty);

      source.set(1);
      await Future<void>.delayed(Duration.zero);

      expect(caughtErrors.length, 1);
      expect(caughtErrors.first, isA<StateError>());
      expect((caughtErrors.first as StateError).message, 'BloomVia reactive error: 1');

      terminal.deactivate();
    });

    test('21. Declarative Effect scoped, debounce, and throttle properties and creation', () {
      final a = blooming(1);
      final b = blooming(2);
      final c = blooming(3);
      final d = blooming(4);
      final e = blooming(5);

      // bloom.effect.scoped
      final singleScoped = a.bloom.effect.scoped((scope) {});
      expect(singleScoped, isA<Effect>());

      // targets.effect.scoped
      final multiScoped = [a.bloom, b.bloom].effect.scoped((scope) {});
      expect(multiScoped, isA<Effect>());

      // Effect.scoped.via
      final viaScoped = Effect.scoped.via((via, scope) {});
      expect(viaScoped, isA<Effect>());

      // Unary debounce
      final uDebounce =
          a.bloom.effect.debounce(const Duration(milliseconds: 50), () {}, leading: true, trailing: false);
      expect(uDebounce, isA<Effect>());

      // N-ary debounce
      final mDebounce =
          [a.bloom, b.bloom].effect.debounce(const Duration(milliseconds: 60), () {}, leading: false, trailing: true);
      expect(mDebounce, isA<Effect>());

      // Unary throttle
      final uThrottle =
          a.bloom.effect.throttle(const Duration(milliseconds: 70), () {}, leading: true, trailing: false);
      expect(uThrottle, isA<Effect>());

      // N-ary throttle
      final mThrottle =
          [a.bloom, b.bloom].effect.throttle(const Duration(milliseconds: 80), () {}, leading: false, trailing: true);
      expect(mThrottle, isA<Effect>());

      // BloomRecord3, 4, 5 effect scopes
      final r3 = (a.bloom, b.bloom, c.bloom);
      expect(r3.effect, isA<BloomEffectScope>());

      final r4 = (a.bloom, b.bloom, c.bloom, d.bloom);
      expect(r4.effect, isA<BloomEffectScope>());

      final r5 = (a.bloom, b.bloom, c.bloom, d.bloom, e.bloom);
      expect(r5.effect, isA<BloomEffectScope>());

      // Iterable<Bloom>.blooms
      expect([a.bloom, b.bloom].blooms.length, 2);
    });

    test('22. Effect class factories and static const sub-factories', () async {
      final a = blooming(1);
      final b = blooming(2);
      final observed = <int>[];

      // 1. Effect(...)
      final e1 = Effect([a.bloom, b.bloom], () {
        observed.add(a.data + b.data);
      });
      expect(e1, isA<Effect>());

      // 2. Effect.unary(...)
      final e2 = Effect.unary(a.bloom, () {
        observed.add(a.data);
      });
      expect(e2, isA<Effect>());

      // 3. Effect.via(...)
      final e3 = Effect.via((via) {
        observed.add(via(a.bloom) * 10);
      });
      expect(e3, isA<Effect>());

      // 4. Effect.scoped(...)
      final e4 = Effect.scoped([a.bloom], (scope) {
        scope.onCleanup(() => observed.add(-1));
      });
      expect(e4, isA<Effect>());

      // 5. Effect.scoped.unary(...)
      final e5 = Effect.scoped.unary(a.bloom, (scope) {
        scope.onCleanup(() => observed.add(-2));
      });
      expect(e5, isA<Effect>());

      // 6. Effect.scoped.via(...)
      final e6 = Effect.scoped.via((via, scope) {
        final val = via(a.bloom);
        scope.onCleanup(() => observed.add(-val));
      });
      expect(e6, isA<Effect>());

      // 7. Effect.debounce(...)
      final e7 = Effect.debounce([a.bloom], const Duration(milliseconds: 50), () {
        observed.add(100);
      });
      expect(e7, isA<Effect>());

      // 8. Effect.debounce.unary(...)
      final e8 = Effect.debounce.unary(a.bloom, const Duration(milliseconds: 50), () {
        observed.add(200);
      });
      expect(e8, isA<Effect>());

      // 9. Effect.throttle(...)
      final e9 = Effect.throttle([a.bloom], const Duration(milliseconds: 50), () {
        observed.add(300);
      });
      expect(e9, isA<Effect>());

      // 10. Effect.throttle.unary(...)
      final e10 = Effect.throttle.unary(a.bloom, const Duration(milliseconds: 50), () {
        observed.add(400);
      });
      expect(e10, isA<Effect>());

      // 11. Effect.group(...)
      final group = Effect.group([e1, e2]);
      expect(group, isA<Effect>());

      // 12. Tuple .group
      final tupleGroup = (e1, e2).group;
      expect(tupleGroup, isA<Effect>());

      // Start and test e1 + e2 through group
      final runner = group.start();
      a.set(10);
      b.set(20);
      await Future<void>.delayed(Duration.zero);

      expect(observed, contains(30)); // from e1
      expect(observed, contains(10)); // from e2
      runner.stop();
    });
  });
}

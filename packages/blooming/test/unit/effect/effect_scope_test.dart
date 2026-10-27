// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:blooming/effect.dart';
import 'package:blooming/blooming.dart';

void main() {
  group('EffectScope Lifecycle & Cancellation Suite', () {
    test('1. effect.scoped executes with active scope via runner', () async {
      final counter = blooming(0);
      EffectScope? capturedScope;
      var runCount = 0;

      final runner = counter.bloom.effect.scoped((scope) {
        runCount++;
        capturedScope = scope;
      }).start();

      expect(runCount, 0); // Effects skip initial evaluation

      counter.set(1);
      await Future<void>.delayed(Duration.zero);

      expect(runCount, 1);
      expect(capturedScope, isNotNull);
      expect(capturedScope!.isActive, isTrue);
      expect(capturedScope!.isCancelled, isFalse);

      runner.stop();
      expect(capturedScope!.isActive, isFalse);
      expect(capturedScope!.isCancelled, isTrue);
    });

    test('2. Invariant 1: onCleanup is called before subsequent turn begins', () async {
      final query = blooming('a');
      final log = <String>[];
      final scopes = <EffectScope>[];

      final runner = query.bloom.effect.scoped((scope) {
        scopes.add(scope);
        final current = untracked(query.bloom);
        log.add('run: $current');

        scope.onCleanup(() {
          log.add('cleanup: $current');
          expect(scope.isActive, isFalse);
          expect(scope.isCancelled, isTrue);
        });
      }).start();

      // First trigger
      query.set('b');
      await Future<void>.delayed(Duration.zero);

      expect(log, ['run: b']);
      expect(scopes.first.isActive, isTrue);

      // Second trigger: should clean up previous before running new
      query.set('c');
      await Future<void>.delayed(Duration.zero);

      expect(log, ['run: b', 'cleanup: b', 'run: c']);
      expect(scopes[0].isActive, isFalse);
      expect(scopes[0].isCancelled, isTrue);
      expect(scopes[1].isActive, isTrue);

      runner.stop();
    });

    test('3. Invariant 2: onCleanup is called on deactivation / unmount', () async {
      final target = blooming(10);
      var cleanedUp = false;
      EffectScope? currentScope;

      final runner = target.bloom.effect.scoped((scope) {
        currentScope = scope;
        scope.onCleanup(() {
          cleanedUp = true;
        });
      }).start();

      target.set(20);
      await Future<void>.delayed(Duration.zero);

      expect(cleanedUp, isFalse);
      expect(currentScope!.isActive, isTrue);

      // Deactivate effect
      runner.stop();

      expect(cleanedUp, isTrue);
      expect(currentScope!.isActive, isFalse);
      expect(currentScope!.isCancelled, isTrue);
    });

    test('4. Multi-target effect.scoped with tuple', () async {
      final a = blooming(1);
      final b = blooming(2);
      final cleanupOrder = <int>[];

      final runner = (a.bloom, b.bloom).effect.scoped((scope) {
        final int sum = untracked(a.bloom) + untracked(b.bloom);
        scope.onCleanup(() {
          cleanupOrder.add(sum);
        });
      }).start();

      a.set(10);
      await Future<void>.delayed(Duration.zero);
      expect(cleanupOrder, isEmpty);

      b.set(20);
      await Future<void>.delayed(Duration.zero);
      expect(cleanupOrder, [12]); // Previous sum was 10 + 2 = 12

      runner.stop();
      expect(cleanupOrder, [12, 30]); // Current sum was 10 + 20 = 30
    });

    test('5. Dynamic Effect.scoped.via with 1-Pass Epoch Sweeping', () async {
      final condition = blooming(true);
      final left = blooming('L1');
      final right = blooming('R1');
      final log = <String>[];

      final runner = Effect.scoped.via((via, scope) {
        final cond = via(condition.bloom);
        final value = cond ? via(left.bloom) : via(right.bloom);
        log.add('via run: $value');

        scope.onCleanup(() {
          log.add('via cleanup: $value');
        });
      }).start();

      // Initial run happens via scheduler microtask
      await Future<void>.delayed(Duration.zero);
      expect(log, ['via run: L1']);

      // Mutate active branch
      left.set('L2');
      await Future<void>.delayed(Duration.zero);
      expect(log, ['via run: L1', 'via cleanup: L1', 'via run: L2']);

      // Switch branch to right
      condition.set(false);
      await Future<void>.delayed(Duration.zero);
      expect(log, [
        'via run: L1',
        'via cleanup: L1',
        'via run: L2',
        'via cleanup: L2',
        'via run: R1',
      ]);

      // Mutating swept branch (left) should NOT trigger anything
      left.set('L3');
      await Future<void>.delayed(Duration.zero);
      expect(log.length, 5); // Unchanged

      runner.stop();
      expect(log.last, 'via cleanup: R1');
    });

    test('6. Multiple onCleanup callbacks execute in LIFO / all guaranteed via finally', () async {
      final counter = blooming(0);
      final executed = <String>[];

      // 1. Verify exact LIFO execution order: 3 -> 2 -> 1
      final runner = counter.bloom.effect.scoped((scope) {
        scope.onCleanup(() => executed.add('cleanup 1'));
        scope.onCleanup(() => executed.add('cleanup 2'));
        scope.onCleanup(() => executed.add('cleanup 3'));
      }).start();

      counter.set(1);
      await Future<void>.delayed(Duration.zero);

      runner.stop();
      expect(executed, ['cleanup 3', 'cleanup 2', 'cleanup 1']);

      // 2. Verify exception safety under LIFO teardown
      // Even if a newer cleanup (cleanup B) throws, older cleanups (cleanup A) must still execute
      final errorLog = <String>[];
      final safetyRunner = counter.bloom.effect.scoped((scope) {
        scope.onCleanup(() {
          errorLog.add('cleanup A');
        });
        scope.onCleanup(() {
          errorLog.add('cleanup B');
          throw Exception('Intentional failure in cleanup B');
        });
      }, onUncaughtError: (error, st) {
        errorLog.add('handled error: $error');
      }).start();

      counter.set(2);
      await Future<void>.delayed(Duration.zero);

      safetyRunner.stop();
      expect(errorLog, [
        'cleanup B',
        'cleanup A',
        contains('handled error: Exception: Intentional failure in cleanup B'),
      ]);
    });

    test('7. Registering onCleanup on an already cancelled scope executes immediately', () {
      final counter = blooming(0);
      EffectScope? storedScope;

      final runner = counter.bloom.effect.scoped((scope) {
        storedScope = scope;
      }).start();

      counter.set(1);
      // Wait for execution
      Future<void>.delayed(Duration.zero).then((_) {
        runner.stop();
        expect(storedScope!.isCancelled, isTrue);

        var called = false;
        storedScope!.onCleanup(() {
          called = true;
        });
        expect(called, isTrue);
      });
    });

    test('8. Guard returning false preserves previous scope and skips execution', () async {
      final counter = blooming(0);
      var runCount = 0;
      var cleanups = 0;

      final runner = counter.bloom.effect.scoped(
        (scope) {
          runCount++;
          scope.onCleanup(() => cleanups++);
        },
        guard: () => untracked(counter.bloom).isEven,
      ).start();

      counter.set(2); // Even -> runs
      await Future<void>.delayed(Duration.zero);
      expect(runCount, 1);
      expect(cleanups, 0);

      counter.set(3); // Odd -> guard fails -> should skip run and NOT cleanup previous
      await Future<void>.delayed(Duration.zero);
      expect(runCount, 1);
      expect(cleanups, 0);

      counter.set(4); // Even -> runs -> cleans up previous (from 2)
      await Future<void>.delayed(Duration.zero);
      expect(runCount, 2);
      expect(cleanups, 1);

      runner.stop();
      expect(cleanups, 2);
    });

    test('9. take: N automatically triggers early teardown and cleans up last scope', () async {
      final counter = blooming(0);
      var runCount = 0;
      var cleanups = 0;

      final runner = counter.bloom.effect.scoped(
        (scope) {
          runCount++;
          scope.onCleanup(() => cleanups++);
        },
        take: 2,
      ).start();

      counter.set(1); // Turn 1
      await Future<void>.delayed(Duration.zero);
      expect(runCount, 1);
      expect(cleanups, 0);

      counter.set(2); // Turn 2 (takes exhausted -> deactivates)
      await Future<void>.delayed(Duration.zero);
      expect(runCount, 2);
      expect(cleanups, 2); // Previous cleanup + early teardown deactivation cleanup!
      expect(runner.isActive, isFalse);

      counter.set(3); // Dead
      await Future<void>.delayed(Duration.zero);
      expect(runCount, 2);
    });

    test('10. In-flight race condition immunity simulation', () async {
      final query = blooming('first');
      final receivedResults = <String>[];

      final runner = query.bloom.effect.scoped((scope) async {
        final currentQuery = untracked(query.bloom);
        final delayMs = currentQuery == 'first' ? 50 : 10;

        // Simulate async I/O
        await Future<void>.delayed(Duration(milliseconds: delayMs));

        if (scope.isActive) {
          receivedResults.add(currentQuery);
        }
      }).start();

      // Trigger 1: 'first' (takes 50ms)
      query.set('first');
      await Future<void>.delayed(Duration.zero);

      // Trigger 2: 'second' (takes 10ms), fired 5ms later
      await Future<void>.delayed(const Duration(milliseconds: 5));
      query.set('second');
      await Future<void>.delayed(Duration.zero);

      // Wait for all async tasks to settle
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // 'first' must have been aborted by scope.isActive check; only 'second' survived!
      expect(receivedResults, ['second']);
      runner.stop();
    });

    test('11. Cleanup errors after cancellation or disposal are routed to onUncaughtError', () async {
      final counter = blooming(0);
      EffectScope? capturedScope;
      final errors = <Object>[];

      final runner = counter.bloom.effect.scoped(
        (scope) {
          capturedScope = scope;
          scope.onCleanup(() {
            throw StateError('Teardown failure');
          });
        },
        onUncaughtError: (error, stack) {
          errors.add(error);
        },
      ).start();

      counter.set(1);
      await Future<void>.delayed(Duration.zero);

      // Deactivating disposes the current scope, triggering onCleanup exception
      runner.stop();

      expect(errors.length, 1);
      expect(errors.first, isA<StateError>());

      // Calling onCleanup after cancellation also catches and forwards to onUncaughtError
      capturedScope!.onCleanup(() {
        throw StateError('Late cleanup error');
      });

      expect(errors.length, 2);
      expect(errors.last, isA<StateError>());
    });
  });
}

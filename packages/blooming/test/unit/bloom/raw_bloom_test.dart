// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

void main() {
  group('RawBloom & markDirty() Comprehensive Unit Tests', () {
    // =========================================================================
    // 1. Sibling Architecture & Type Isolation Tests
    // =========================================================================
    group('1. Sibling Architecture & Strict Type Isolation', () {
      test('1.1 RawBloomController is a BloomController with Has-a Bloom, but NOT a Bloom itself', () {
        final raw = blooming.raw<int>(10);

        expect(raw, isA<RawBloomController<int>>());
        expect(raw, isA<BloomController<int>>());
        expect(raw, isNot(isA<Bloom>()), reason: 'BloomController must NOT be a Bloom (Has-a architecture)');
        expect(raw.bloom, isA<Bloom<int>>());
      });

      test('1.2 Standard BloomController is NOT a RawBloomController', () {
        final writable = blooming<int>(10);

        expect(writable, isA<BloomController<int>>());
        expect(writable, isNot(isA<Bloom>()), reason: 'BloomController must NOT be a Bloom (Has-a architecture)');
        expect(writable.bloom, isA<Bloom<int>>());
        expect(writable, isNot(isA<RawBloomController>()),
            reason: 'Standard BloomController must NOT be an instance of RawBloomController');
      });

      test('1.3 blooming(distinct: false) is NOT a RawBloom', () {
        final writableNonDistinct = blooming<int>(10, distinct: false);

        expect(writableNonDistinct, isA<BloomController<int>>());
        expect(writableNonDistinct, isNot(isA<RawBloomController>()),
            reason: 'Even with distinct: false, BloomController retains its distinct family identity');
      });

      test('1.4 Both BloomController and RawBloomController implement BloomController polymorphically', () {
        final writable = blooming<int>(10);
        final raw = blooming.raw<int>(20);

        expect(writable, isA<BloomController<int>>());
        expect(raw, isA<BloomController<int>>());

        void mutateEntry(BloomController<int> entry, int val) {
          entry.data = val;
        }

        mutateEntry(writable, 99);
        expect(writable.data, 99);

        mutateEntry(raw, 100);
        expect(raw.data, 100);
      });
    });

    // =========================================================================
    // 2. markDirty() Zero-Allocation Dirty Pulse Tests
    // =========================================================================
    group('2. markDirty() Zero-Allocation Dirty Pulse Invalidation', () {
      test('2.1 markDirty() broadcasts invalidation pulse without changing data', () {
        final raw = blooming.raw<int>(42);
        int invalidationCount = 0;
        final terminal = RawBloomTerminal(raw.bloom, onInvalidated: () => invalidationCount++);
        terminal.activate();

        expect(terminal.data, 42);
        expect(invalidationCount, 0);

        // Call markDirty without mutating data
        raw.markDirty();
        expect(invalidationCount, 1);
        expect(terminal.data, 42);

        // Consecutive markDirty calls
        raw.markDirty();
        expect(invalidationCount, 2);
        expect(terminal.data, 42);

        terminal.deactivate();
      });

      test('2.2 In-place collection mutation followed by markDirty()', () {
        final buffer = <String>['apple'];
        final raw = blooming.raw<List<String>>(buffer);
        int invalidationCount = 0;
        final terminal = RawBloomTerminal(raw.bloom, onInvalidated: () => invalidationCount++);
        terminal.activate();

        expect(terminal.data, equals(['apple']));
        expect(invalidationCount, 0);

        // Mutate buffer directly in-place
        raw.data.add('banana');
        expect(invalidationCount, 0, reason: 'In-place mutation alone does not notify');

        // Broadcast dirty pulse via markDirty
        raw.markDirty();
        expect(invalidationCount, 1);
        expect(terminal.data, equals(['apple', 'banana']));

        // Another in-place mutation
        raw.data.add('cherry');
        raw.markDirty();
        expect(invalidationCount, 2);
        expect(terminal.data, equals(['apple', 'banana', 'cherry']));

        terminal.deactivate();
      });

      test('2.3 markDirty() while inactive records dirty version and invalidates on reconnect', () {
        final raw = blooming.raw<int>(100);
        int invalidationCount = 0;
        final terminal = RawBloomTerminal(raw.bloom, onInvalidated: () => invalidationCount++);

        // Inactive: calling markDirty bumps dirty version internally
        raw.markDirty();
        expect(invalidationCount, 0);

        // Activation connects to upstream: Q2: B drops onInvalidated and resolves lazily on pull
        terminal.activate();
        expect(terminal.data, 100);
        expect(invalidationCount, 0, reason: 'Q2: B - Reconnection does NOT trigger onInvalidated');

        // Active mutation
        raw.markDirty();
        expect(invalidationCount, 1, reason: 'Active markDirty invalidates immediately');

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 3. Raw State Mutation & Unconditional Dirty Propagation
    // =========================================================================
    group('3. Raw State Mutation (No Distinct Filtering)', () {
      test('3.1 Setting identical value unconditionally broadcasts dirty pulse', () {
        final raw = blooming.raw<int>(5);
        int invalidationCount = 0;
        final terminal = RawBloomTerminal(raw.bloom, onInvalidated: () => invalidationCount++);
        terminal.activate();

        expect(terminal.data, 5);
        expect(invalidationCount, 0);

        // Duplicate value via property setter
        raw.data = 5;
        expect(invalidationCount, 1);
        expect(terminal.data, 5); // Pull resets pending state under Q1: A

        // Duplicate value via set()
        raw.set(5);
        expect(invalidationCount, 2);
        expect(terminal.data, 5);

        // Different value
        raw.set(10);
        expect(invalidationCount, 3);
        expect(terminal.data, 10);

        terminal.deactivate();
      });

      test('3.2 setGuarded works on RawBloom', () {
        final raw = blooming.raw<int>(1);
        int invalidationCount = 0;
        final terminal = RawBloomTerminal(raw.bloom, onInvalidated: () => invalidationCount++);
        terminal.activate();

        raw.setGuarded(() => 20);
        expect(terminal.data, 20);
        expect(invalidationCount, 1);

        // Thrown exception transitions to error state
        raw.setGuarded(() => throw Exception('GuardedFailure'));
        expect(terminal.hasError, isTrue);
        expect(invalidationCount, 2);

        terminal.deactivate();
      });

      test('3.3 empty() transitions to empty state and broadcasts dirty', () {
        final raw = blooming.raw<int>(50);
        int invalidationCount = 0;
        final terminal = RawBloomTerminal(raw.bloom, onInvalidated: () => invalidationCount++);
        terminal.activate();

        expect(terminal.hasData, isTrue);

        raw.empty();
        expect(terminal.isEmpty, isTrue);
        expect(invalidationCount, 1);

        terminal.deactivate();
      });

      test('3.4 setError() transitions to error state and broadcasts dirty', () {
        final raw = blooming.raw<int>(50);
        int invalidationCount = 0;
        final terminal = RawBloomTerminal(raw.bloom, onInvalidated: () => invalidationCount++);
        terminal.activate();

        raw.setError('CustomError');
        expect(terminal.hasError, isTrue);
        expect(terminal.error, 'CustomError');
        expect(invalidationCount, 1);

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 4. RawBloom.late & RawBloom.error Constructors
    // =========================================================================
    group('4. RawBloom.late & RawBloom.error', () {
      test('4.1 RawBloom.late starts in empty state and transitions on set', () {
        final rawLate = blooming.raw.late<String>();
        expect(rawLate.isEmpty, isTrue);

        int invalidationCount = 0;
        final terminal = RawBloomTerminal(rawLate.bloom, onInvalidated: () => invalidationCount++);
        terminal.activate();

        expect(terminal.isEmpty, isTrue);
        expect(invalidationCount, 0);

        rawLate.data = 'initialized';
        expect(terminal.data, 'initialized');
        expect(invalidationCount, 1);

        // Duplicate value on RawBloom still emits dirty pulse
        rawLate.data = 'initialized';
        expect(invalidationCount, 2);

        terminal.deactivate();
      });

      test('4.2 RawBloom.error starts in error state and propagates duplicate errors', () {
        final rawErr = blooming.raw.error<int>('InitialError');
        expect(rawErr.hasError, isTrue);

        int invalidationCount = 0;
        final terminal = RawBloomTerminal(rawErr.bloom, onInvalidated: () => invalidationCount++);
        terminal.activate();

        expect(terminal.hasError, isTrue);

        // Re-injecting error propagates in RawBloom
        rawErr.setError('InitialError');
        expect(invalidationCount, 1);
        expect(terminal.hasError, isTrue); // Pull resets pending state under Q1: A

        // Recover with set
        rawErr.set(999);
        expect(terminal.data, 999);
        expect(invalidationCount, 2);

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 5. Factory Functor: bloom.dataOrNull
    // =========================================================================
    group('5. bloom.dataOrNull Functor', () {
      test('5.1 bloom.dataOrNull creates RawBloom', () {
        final r1 = blooming.raw(123);
        expect(r1, isA<RawBloomController<int>>());
        expect(r1, isA<BloomController<int>>());
        expect(r1.data, 123);

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(r1.bloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        r1.markDirty();
        expect(dirtyCount, 1);

        terminal.deactivate();
      });

      test('5.2 bloom.dataOrNull.late and bloom.dataOrNull.error functors work', () {
        final lateRaw = blooming.raw.late<double>();
        expect(lateRaw, isA<RawBloomController<double>>());
        expect(lateRaw.isEmpty, isTrue);

        final errRaw = blooming.raw.error<double>('Err1');
        expect(errRaw, isA<RawBloomController<double>>());
        expect(errRaw.hasError, isTrue);
      });
    });

    // =========================================================================
    // 6. Lifecycle Hooks on RawBloom
    // =========================================================================
    group('6. Lifecycle Hooks on RawBloom', () {
      test('6.1 onActivated and onDeactivated are called correctly', () {
        int activatedCount = 0;
        int deactivatedCount = 0;

        final raw = blooming.raw<int>(
          0,
          onActivated: () => activatedCount++,
          onDeactivated: () => deactivatedCount++,
        );

        expect(activatedCount, 0);
        expect(deactivatedCount, 0);

        final terminal = RawBloomTerminal(raw.bloom, onInvalidated: () {});
        terminal.activate();
        expect(activatedCount, 1);
        expect(deactivatedCount, 0);

        terminal.deactivate();
        expect(activatedCount, 1);
        expect(deactivatedCount, 1);
      });

      test('6.2 Graceful deactivation works on RawBloom', () async {
        int deactivatedCount = 0;

        final raw = blooming.raw<int>(
          0,
          onActivated: () {},
          onDeactivated: () => deactivatedCount++,
          graceful: Graceful.microtask,
        );

        final terminal = RawBloomTerminal(raw.bloom, onInvalidated: () {});
        terminal.activate();
        terminal.deactivate();

        // Deferred via microtask
        expect(deactivatedCount, 0);

        await Future<void>.delayed(Duration.zero);
        expect(deactivatedCount, 1);
      });
    });
  });
}

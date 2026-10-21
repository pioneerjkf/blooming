// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.
import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

void main() {
  group('Raw & Suffix Raw Escape Hatches Comprehensive Unit Tests', () {
    // =========================================================================
    // 1. BloomController(distinct: false) vs BloomController default (distinct: true)
    // =========================================================================
    group('1. BloomController(distinct: false) vs BloomController default', () {
      test('1.1 BloomController(distinct: false) emits dirty pulses unconditionally on identical values', () {
        final raw = BloomController<int>(10, distinct: false);
        int dirtyCount = 0;
        final terminal = RawBloomTerminal(raw.bloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.data, 10);
        expect(dirtyCount, 0);

        raw.data = 10; // Same value
        expect(dirtyCount, 1);
        expect(terminal.data, 10); // Pull clears pending state under Q1: A

        raw.data = 10; // Same value again
        expect(dirtyCount, 2);
        expect(terminal.data, 10);

        terminal.deactivate();
      });

      test('1.2 BloomController default suppresses dirty pulse on identical value', () {
        final distinctBloom = BloomController<int>(10);
        int dirtyCount = 0;
        final terminal = RawBloomTerminal(distinctBloom.bloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.data, 10);
        expect(dirtyCount, 0);

        distinctBloom.data = 10; // Same value ignored
        expect(dirtyCount, 0);

        distinctBloom.data = 20; // New value emitted
        expect(dirtyCount, 1);

        terminal.deactivate();
      });

      test('1.3 BloomController(distinct: false) enables in-place mutable buffer streaming', () {
        final buffer = <int>[];
        final stream = BloomController<List<int>>(buffer, distinct: false);
        int dirtyCount = 0;
        final terminal = RawBloomTerminal(stream.bloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.data, isEmpty);
        expect(dirtyCount, 0);

        buffer.add(1);
        stream.data = buffer; // Same object identity!
        expect(dirtyCount, 1);
        expect(terminal.data, equals([1]));

        buffer.add(2);
        stream.data = buffer;
        expect(dirtyCount, 2);
        expect(terminal.data, equals([1, 2]));

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 2. BloomController(distinct: false) vs bloom default
    // =========================================================================
    group('2. BloomController(distinct: false) Functor', () {
      test('2.1 BloomController(distinct: false) emits on duplicate value assignments', () {
        final raw = BloomController('alpha', distinct: false);
        int dirtyCount = 0;
        final terminal = RawBloomTerminal(raw.bloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.data, 'alpha');

        raw.data = 'alpha';
        expect(dirtyCount, 1);
        expect(terminal.data, 'alpha'); // Pull clears pending state under Q1: A

        raw.data = 'alpha';
        expect(dirtyCount, 2);
        expect(terminal.data, 'alpha');

        terminal.deactivate();
      });

      test('2.2 bloom.late(distinct: false) starts empty and propagates duplicate assignments', () {
        final lateRaw = BloomController<int>.late(distinct: false);
        expect(lateRaw.isEmpty, isTrue);

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(lateRaw.bloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.isEmpty, isTrue);

        lateRaw.set(100);
        expect(terminal.data, 100);
        expect(dirtyCount, 1);

        lateRaw.set(100); // Duplicate value propagates in raw mode
        expect(dirtyCount, 2);

        terminal.deactivate();
      });

      test('2.3 BloomController.error(distinct: false) starts in error and propagates duplicate error assignments', () {
        final errRaw = BloomController<int>.error('InitialError', distinct: false);
        expect(errRaw.hasError, isTrue);

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(errRaw.bloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.hasError, isTrue);

        errRaw.setError('InitialError'); // Same error propagates in raw mode
        expect(dirtyCount, 1);

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 3. BloomController.late and BloomController.error with distinct: false
    // =========================================================================
    group('3. BloomController with distinct: false', () {
      test('3.1 bloom.late(distinct: false) behaves as non-distinct late state', () {
        final wLateRaw = BloomController<String>.late(distinct: false);
        expect(wLateRaw.isEmpty, isTrue);

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(wLateRaw.bloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        wLateRaw.data = 'first';
        expect(terminal.data, 'first');
        expect(dirtyCount, 1);

        wLateRaw.data = 'first';
        expect(dirtyCount, 2);

        terminal.deactivate();
      });

      test('3.2 BloomController.error(distinct: false) behaves as non-distinct error state', () {
        final wErrRaw = BloomController<int>.error('Err', distinct: false);
        expect(wErrRaw.hasError, isTrue);

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(wErrRaw.bloom, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.hasError, isTrue);

        wErrRaw.setError('Err');
        expect(dirtyCount, 1);

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 4. computed and bloom.computed (Pure Lazy LPDAG)
    // =========================================================================
    group('4. computed and bloom.computed (Pure Lazy LPDAG)', () {
      test('4.1 computed creates valid computation node that evaluates lazily', () {
        final source = BloomController(10);
        int evalCount = 0;
        final c = computed((via) {
          evalCount++;
          return via(source.bloom) * 2;
        });

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(c, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(evalCount, 0); // Lazy: not yet read
        expect(terminal.data, 20);
        expect(evalCount, 1);
        expect(dirtyCount, 0);

        source.data = 20;
        expect(dirtyCount, 1);
        expect(terminal.data, 40);
        expect(evalCount, 2);

        terminal.deactivate();
      });

      test('4.2 bloom.computed works symmetrically with top-level computed', () {
        final a = BloomController(5, distinct: false);
        final b = BloomController(10, distinct: false);
        final sum = computed((via) => via(a.bloom) + via(b.bloom));

        int dirtyCount = 0;
        final terminal = RawBloomTerminal(sum, onInvalidated: () => dirtyCount++);
        terminal.activate();

        expect(terminal.data, 15);
        expect(dirtyCount, 0);

        a.data = 5; // Emits dirty because a is raw!
        expect(dirtyCount, 1);
        expect(terminal.data, 15);

        terminal.deactivate();
      });

      test('4.3 Bloom.computed factory constructor works', () {
        final source = BloomController(1);
        final doubled = computed((via) => via(source.bloom) * 2);

        expect(untracked(doubled), 2);
        source.data = 2;
        expect(untracked(doubled), 4);
      });

      test('4.4 computed evaluates purely on pull and guarantees exactly 1 computation on diamond graph', () {
        final root = BloomController(10);
        final left = computed((via) => via(root.bloom) * 2);
        final right = computed((via) => via(root.bloom) * 3);

        int evalCount = 0;
        final diamond = computed((via) {
          evalCount++;
          return via(left) + via(right);
        });

        expect(evalCount, 0); // Lazy: not yet evaluated

        expect(untracked(diamond), 50); // 20 + 30 = 50
        expect(evalCount, 1);

        // Mutating root pushes dirty flag to diamond via both branches
        root.data = 20;
        expect(evalCount, 1); // Zero computation during push!

        // Evaluates exactly once on pull with complete, glitch-free state (40 + 60 = 100)
        expect(untracked(diamond), 100);
        expect(evalCount, 2);
      });
    });
  });
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

void main() {
  group('Bloom State Pipeline Temporal Control Suite', () {
    group('1. DebouncedBloom (Trailing Edge - Default)', () {
      test('1.1 Rapid successive mutations are collapsed to the last value after silence', () async {
        final query = BloomController('a');
        final debouncedQuery = query.bloom.debounced(const Duration(milliseconds: 50));

        final observed = <String>[untracked(debouncedQuery)];
        final terminal = RawBloomTerminal(debouncedQuery, onInvalidated: () {
          observed.add(untracked(debouncedQuery));
        });
        terminal.activate();

        expect(observed, ['a']);
        expect(untracked(debouncedQuery), 'a');

        // Type rapidly
        query.data = 'ap';
        await Future<void>.delayed(const Duration(milliseconds: 20));
        query.data = 'app';
        await Future<void>.delayed(const Duration(milliseconds: 20));
        query.data = 'appl';
        await Future<void>.delayed(const Duration(milliseconds: 20));
        query.data = 'apple';

        // Before 50ms of silence, observed remains ['a']
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(observed, ['a']);

        // Wait past 50ms of silence
        await Future<void>.delayed(const Duration(milliseconds: 35));
        expect(observed, ['a', 'apple']);
        expect(untracked(debouncedQuery), 'apple');

        terminal.deactivate();
      });

      test('1.2 Top-level factory bloom.debounced works identically', () async {
        final text = BloomController('start');
        final debouncedText = text.bloom.debounced(const Duration(milliseconds: 40));

        final notifications = <String>[untracked(debouncedText)];
        final terminal = RawBloomTerminal(debouncedText, onInvalidated: () {
          notifications.add(untracked(debouncedText));
        });
        terminal.activate();

        text.data = 'change1';
        text.data = 'change2';
        text.data = 'final';

        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(notifications, ['start', 'final']);

        terminal.deactivate();
      });
    });

    group('2. DebouncedBloom (Leading and Dual Edges)', () {
      test('2.1 Leading-only debounce propagates first mutation immediately and ignores subsequent in window',
          () async {
        final state = BloomController(1);
        final debounced = state.bloom.debounced(
          const Duration(milliseconds: 50),
          leading: true,
          trailing: false,
        );

        final observed = <int>[untracked(debounced)];
        final terminal = RawBloomTerminal(debounced, onInvalidated: () {
          observed.add(untracked(debounced));
        });
        terminal.activate();

        expect(observed, [1]);

        // First mutation: fires immediately!
        state.data = 2;
        expect(observed, [1, 2]);

        // Subsequent mutations within 50ms are ignored
        await Future<void>.delayed(const Duration(milliseconds: 20));
        state.data = 3;
        state.data = 4;
        expect(observed, [1, 2]);

        // Wait past window (timer was reset at 20ms, so wait 60ms)
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(observed, [1, 2]);

        // Next mutation after cooldown fires immediately
        state.data = 5;
        expect(observed, [1, 2, 5]);

        terminal.deactivate();
      });

      test('2.1.1 Leading-only debounce propagates immediately to downstream computed node', () async {
        final state = BloomController(1);
        final debounced = state.bloom.debounced(
          const Duration(milliseconds: 50),
          leading: true,
          trailing: false,
        );

        final downstream = computed<int>((via) => via(debounced) * 10);
        final terminal = RawBloomTerminal(downstream, onInvalidated: () {});
        terminal.activate();

        expect(terminal.data, 10);

        // Leading edge: state mutates 1 -> 2
        state.data = 2;
        expect(terminal.data, 20, reason: 'Downstream computed must evaluate leading edge');

        terminal.deactivate();
      });

      test('2.2 Dual-edge debounce (leading: true, trailing: true) fires leading then trailing after silence',
          () async {
        final state = BloomController('A');
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

        expect(observed, ['A']);

        // First change: leading edge fires immediately
        state.data = 'B';
        expect(observed, ['A', 'B']);

        // Intermediate changes
        await Future<void>.delayed(const Duration(milliseconds: 20));
        state.data = 'C';
        await Future<void>.delayed(const Duration(milliseconds: 20));
        state.data = 'D';

        // Wait for silence
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(observed, ['A', 'B', 'D']);

        terminal.deactivate();
      });
    });

    group('3. ThrottledBloom (Rate-Limiting)', () {
      test('3.1 ThrottledBloom limits downstream notifications to window interval', () async {
        final scroll = BloomController(0.0);
        final throttledScroll = scroll.bloom.throttled(
          const Duration(milliseconds: 50),
          leading: true,
          trailing: true,
        );

        final observed = <double>[untracked(throttledScroll)];
        final terminal = RawBloomTerminal(throttledScroll, onInvalidated: () {
          observed.add(untracked(throttledScroll));
        });
        terminal.activate();

        expect(observed, [0.0]);

        // Leading edge fires immediately
        scroll.data = 10.0;
        expect(observed, [0.0, 10.0]);

        // Rapid scrolling inside window
        await Future<void>.delayed(const Duration(milliseconds: 15));
        scroll.data = 25.0;
        await Future<void>.delayed(const Duration(milliseconds: 15));
        scroll.data = 50.0;

        // Inside window: not yet fired
        expect(observed, [0.0, 10.0]);

        // Past 50ms window: trailing edge fires with latest value (50.0)
        await Future<void>.delayed(const Duration(milliseconds: 35));
        expect(observed, [0.0, 10.0, 50.0]);

        terminal.deactivate();
      });

      test('3.2 bloom.throttled factory creates functioning rate limiter', () async {
        final counter = BloomController(0);
        final throttled = counter.bloom.throttled(
          const Duration(milliseconds: 40),
          leading: false,
          trailing: true,
        );

        final observed = <int>[untracked(throttled)];
        final terminal = RawBloomTerminal(throttled, onInvalidated: () {
          observed.add(untracked(throttled));
        });
        terminal.activate();

        expect(observed, [0]);

        counter.data = 1;
        counter.data = 2;
        counter.data = 3;

        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(observed, [0, 3]);

        terminal.deactivate();
      });
    });

    group('4. Zero-Leak Deactivation & Resilience', () {
      test('4.1 Deactivating node cancels running timers without leaking or throwing', () async {
        final source = BloomController('live');
        final debounced = source.bloom.debounced(const Duration(milliseconds: 50));

        final terminal = RawBloomTerminal(debounced, onInvalidated: () {});
        terminal.activate();

        source.data = 'updated';
        // Now timer is running. Deactivate terminal before timer expires:
        terminal.deactivate();

        // Wait past timer duration
        await Future<void>.delayed(const Duration(milliseconds: 70));

        // Node should safely reactivate and pull latest state on demand
        terminal.activate();
        expect(untracked(debounced), 'updated');

        terminal.deactivate();
      });

      test('4.2 Invalid configuration assert(leading || trailing) fails early', () {
        final source = BloomController(42);
        expect(
          () => source.bloom.debounced(
            const Duration(milliseconds: 50),
            leading: false,
            trailing: false,
          ),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => source.bloom.throttled(
            const Duration(milliseconds: 50),
            leading: false,
            trailing: false,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('5. Full Reactive Pipeline Integration (SWR / computed.future)', () {
      test('5.1 Debounced state seamlessly feeds computed.future with retained() SWR', () async {
        final query = BloomController('init');
        final debounced = query.bloom.debounced(const Duration(milliseconds: 40));

        var apiCallCount = 0;
        final searchResults = computed.future((via) {
          final currentQuery = via(debounced);
          apiCallCount++;
          return Future<String>.delayed(
            const Duration(milliseconds: 20),
            () => 'Result for: $currentQuery',
          );
        }).retained();

        final terminal = RawBloomTerminal(searchResults, onInvalidated: () {});
        terminal.activate();

        // Initial fetch starts
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(untracked(searchResults), 'Result for: init');
        expect(apiCallCount, 1);

        // Rapid query changes
        query.data = 'fl';
        await Future<void>.delayed(const Duration(milliseconds: 15));
        query.data = 'flu';
        await Future<void>.delayed(const Duration(milliseconds: 15));
        query.data = 'flutter';

        // Wait for debounce silence (40ms) + future computation (20ms)
        await Future<void>.delayed(const Duration(milliseconds: 75));

        expect(untracked(searchResults), 'Result for: flutter');
        // Only 1 initial call + 1 debounced call = 2 total API calls!
        expect(apiCallCount, 2);

        terminal.deactivate();
      });
    });
  });
}

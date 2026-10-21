// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming_test/blooming_test.dart';

void main() {
  group('LPDAG Custom Matchers Suite', () {
    group('isDormant & isActive', () {
      test('node with 0 subscribers is dormant and not active', () {
        final counter = BloomController(0);
        expect(counter, isDormant);
        expect(counter.bloom, isDormant);
        expect(counter, isNot(isActive));
      });

      test('node with active terminal becomes active and not dormant', () {
        final counter = BloomController(0);
        final terminal = RawBloomTerminal(counter.bloom, onInvalidated: () {});
        terminal.activate();

        expect(counter, isActive);
        expect(counter.bloom, isActive);
        expect(counter, isNot(isDormant));

        terminal.deactivate();
        expect(counter, isDormant);
        expect(counter, isNot(isActive));
      });
    });

    group('hasSubscribers', () {
      test('accurately counts downstream active subscription edges', () {
        final counter = BloomController(0);
        expect(counter, hasSubscribers(0));

        final terminal1 = RawBloomTerminal(counter.bloom, onInvalidated: () {});
        terminal1.activate();
        expect(counter, hasSubscribers(1));

        final terminal2 = RawBloomTerminal(counter.bloom, onInvalidated: () {});
        terminal2.activate();
        expect(counter, hasSubscribers(2));

        terminal1.deactivate();
        expect(counter, hasSubscribers(1));

        terminal2.deactivate();
        expect(counter, hasSubscribers(0));
      });
    });

    group('hasGlitchFreedom', () {
      test(
          'verifies diamond dependency evaluation sequence without intermediate tearing',
          () {
        // Diamond graph:
        //      a
        //     / \
        //    b   c
        //     \ /
        //      d
        final a = BloomController(1);
        final b = computed((via) => via(a.bloom) * 2);
        final c = computed((via) => via(a.bloom) + 10);
        final d = computed<int>((via) => via(b) + via(c));

        final evaluations = <int>[];
        final terminal = RawBloomTerminal(d, onInvalidated: () {
          evaluations.add(untracked(d));
        });
        terminal.activate();

        // Initial evaluation
        expect(untracked(d), 13);
        evaluations.add(untracked(d));

        // Mutate upstream source a to 2
        // If glitch-free, d evaluates b=4, c=12 -> 16 in one consolidated step
        a.data = 2;

        expect(evaluations, hasGlitchFreedom);
        expect(evaluations, [13, 16]);

        terminal.deactivate();
      });
    });

    group('isData', () {
      test('matches valid Data snapshots and payloads', () {
        const snap = BloomSnapshot<int>(42);
        expect(snap, isData(42));
        expect(snap, isData(isPositive));
        expect(snap, isNot(isData(100)));

        const emptySnap = BloomSnapshot<int>.empty('no-data');
        expect(emptySnap, isNot(isData(42)));

        final errorSnap = BloomSnapshot<int>.error(Exception('fail'));
        expect(errorSnap, isNot(isData(42)));
      });

      test('matches Bloom nodes and controllers in Data state', () {
        final ctrl = BloomController('active');
        expect(ctrl, isData('active'));
        expect(ctrl.bloom, isData('active'));
      });
    });

    group('isEmptyState', () {
      test('matches Empty snapshots and empty reasons', () {
        const emptyWithReason = BloomSnapshot<String>.empty('loading');
        expect(emptyWithReason, isEmptyState());
        expect(emptyWithReason, isEmptyState('loading'));
        expect(emptyWithReason, isNot(isEmptyState('other')));

        const snap = BloomSnapshot<String>('valid');
        expect(snap, isNot(isEmptyState()));
      });
    });

    group('isErrorState', () {
      test('matches Error snapshots and exception objects', () {
        final err = FormatException('bad format');
        final errSnap = BloomSnapshot<int>.error(err);

        expect(errSnap, isErrorState());
        expect(errSnap, isErrorState(isA<FormatException>()));
        expect(errSnap, isErrorState(err));

        const snap = BloomSnapshot<int>(10);
        expect(snap, isNot(isErrorState()));
      });
    });
  });
}

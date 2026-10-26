// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';
import 'package:test/test.dart';

void main() {
  group('BloomVia Value Semantics & Short-Circuit Propagation Suite (D1, D2, D7)', () {
    test('1. via(x) returns T and dynamically tracks dependency', () {
      final a = blooming(10);
      final b = blooming(20);

      final sum = computed((via) => via(a.bloom) + via(b.bloom));

      expect(untracked(sum), 30);

      a.data = 15;
      expect(untracked(sum), 35);

      b.data = 25;
      expect(untracked(sum), 40);
    });

    test('2. Upstream Empty short-circuits and preserves emptyReason (D2)', () {
      final a = blooming.late<int>(reason: 'WaitingForInput');
      final derived = computed((via) => via(a.bloom) * 2);

      expect(untracked.state(derived).isEmpty, isTrue);
      expect(untracked.state(derived).emptyReason, 'WaitingForInput');
      expect(untracked.state(derived).hasError, isFalse);
      expect(untracked.state(derived).hasData, isFalse);
    });

    test('3. Upstream Error short-circuits and preserves original error without double-wrapping (D2)', () {
      final err = StateError('OriginalError');
      final a = blooming.error<int>(err);
      final derived = computed((via) => via(a.bloom) * 2);

      expect(untracked.state(derived).hasError, isTrue);
      expect(untracked.state(derived).error, same(err));
      expect(untracked.state(derived).isEmpty, isFalse);
      expect(untracked.state(derived).hasData, isFalse);
    });

    test('4. 2-step chain (a -> b -> c) preserves Empty reason across hops', () {
      final a = blooming.late<int>(reason: 'Step1Reason');
      final b = computed((via) => via(a.bloom) + 1);
      final c = computed((via) => via(b) * 2);

      expect(untracked.state(c).isEmpty, isTrue);
      expect(untracked.state(c).emptyReason, 'Step1Reason');
    });

    test('5. Self-healing: When upstream changes from Empty to Data, downstream recovers', () {
      final a = blooming.late<int>(reason: 'InitialEmpty');
      final derived = computed((via) => via(a.bloom) * 2);

      expect(untracked.state(derived).isEmpty, isTrue);

      a.data = 21;
      expect(untracked.state(derived).hasData, isTrue);
      expect(untracked(derived), 42);
    });

    test('6. 1-Pass Epoch Sweeping on short-circuit: unreached branches are pruned', () {
      final cond = blooming(true);
      final t = blooming.late<int>(reason: 'EmptyTrueBranch');
      final f = blooming(100);

      var fEvaluations = 0;
      final fDerived = computed((via) {
        fEvaluations++;
        return via(f.bloom);
      });

      final res = computed((via) => via(cond.bloom) ? via(t.bloom) : via(fDerived));

      // Initial evaluation: cond is true, t is empty -> short-circuits at t.
      // fDerived should NOT have been evaluated.
      expect(untracked.state(res).isEmpty, isTrue);
      expect(fEvaluations, 0);

      // Mutating f should not trigger res or fDerived because fDerived was never tracked or was pruned.
      f.data = 200;
      expect(fEvaluations, 0);
      expect(untracked.state(res).isEmpty, isTrue);

      // Switching cond to false activates the fDerived branch.
      cond.data = false;
      expect(untracked.state(res).hasData, isTrue);
      expect(untracked(res), 200);
      expect(fEvaluations, 1);
    });

    test('7. via.state(x) returns BloomState<T> without short-circuiting', () {
      final a = blooming.late<int>(reason: 'NoData');

      final status = computed((via) {
        final state = via.state(a.bloom);
        if (state.isEmpty) {
          return 'Empty: ${state.emptyReason}';
        }
        return 'Has: ${state.data}';
      });

      expect(untracked(status), 'Empty: NoData');

      a.data = 10;
      expect(untracked(status), 'Has: 10');
    });

    test('8. Guard condition evaluates and takes precedence over short-circuit', () {
      final a = blooming<int>(5);

      final derived = computed(
        (via) => via(a.bloom) * 2,
        guard: (via) {
          final state = via.state(a.bloom);
          return (state.hasData && state.data > 10) ? BloomGuard.pass : BloomGuard.block('ValueTooLow');
        },
      );

      expect(untracked.state(derived).isEmpty, isTrue);
      expect(untracked.state(derived).emptyReason, 'ValueTooLow');

      a.data = 15;
      expect(untracked.state(derived).hasData, isTrue);
      expect(untracked(derived), 30);
    });

    test('9. Effect.via short-circuits silently without calling action on Empty', () async {
      final a = blooming.late<int>(reason: 'NotReady');
      var actionRuns = 0;

      final terminal = RawViaTerminal((via) {
        via.tether(
          Effect.via((v) {
            v(a.bloom);
            actionRuns++;
          }),
        );
      }, onInvalidated: () {})
        ..activate()
        ..evaluate();

      await Future<void>.delayed(Duration.zero);
      expect(actionRuns, 0);

      a.data = 42;
      await Future<void>.delayed(Duration.zero);
      expect(actionRuns, 1);

      terminal.deactivate();
    });

    test('10. User exceptions are caught and become Error(exception)', () {
      final customEx = FormatException('UserCustomException');
      final derived = computed<int>((via) {
        throw customEx;
      });

      expect(untracked.state(derived).hasError, isTrue);
      expect(untracked.state(derived).error, same(customEx));
    });
  });
}

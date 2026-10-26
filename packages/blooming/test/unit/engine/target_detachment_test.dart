// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';
import 'package:test/test.dart';

void main() {
  group('LPDAG Target Detachment During Dirty Propagation Suite', () {
    test('Downstream target detachment during _propagateDirty does not drop notifications for subsequent targets', () {
      final source = blooming<int>(0);

      var countA = 0;
      var countB = 0;
      var countC = 0;
      var countD = 0;

      late final RawBloomTerminal<int> termA;
      late final RawBloomTerminal<int> termB;
      late final RawBloomTerminal<int> termC;
      late final RawBloomTerminal<int> termD;

      termA = RawBloomTerminal(source.bloom, onInvalidated: () {
        countA++;
        termB.deactivate();
      });

      termB = RawBloomTerminal(source.bloom, onInvalidated: () {
        countB++;
      });

      termC = RawBloomTerminal(source.bloom, onInvalidated: () {
        countC++;
      });

      termD = RawBloomTerminal(source.bloom, onInvalidated: () {
        countD++;
      });

      // Because _attachTargetEdgeOptimistically prepends to _targetHead,
      // activating in order D -> C -> B -> A creates the linked list:
      // A -> B -> C -> D
      termD.activate();
      termC.activate();
      termB.activate();
      termA.activate();

      expect(countA, 0);
      expect(countB, 0);
      expect(countC, 0);
      expect(countD, 0);

      // Mutate source: should propagate dirty to all active targets
      source.set(10);

      // termA is at the head, executed first
      expect(countA, 1);
      // termB was detached while termA was executing, so termB may be skipped
      // BUT termC and termD MUST NOT be dropped!
      expect(countC, 1, reason: 'termC notification must not be dropped when termB is detached');
      expect(countD, 1, reason: 'termD notification must not be dropped when termB is detached');

      termA.deactivate();
      termC.deactivate();
      termD.deactivate();
    });

    test('Multiple targets deactivating each other during dirty propagation preserves iteration safety', () {
      final source = blooming<int>(100);

      final events = <String>[];

      late final RawBloomTerminal<int> t1;
      late final RawBloomTerminal<int> t2;
      late final RawBloomTerminal<int> t3;
      late final RawBloomTerminal<int> t4;

      t1 = RawBloomTerminal(source.bloom, onInvalidated: () {
        events.add('t1');
        t2.deactivate();
        t3.deactivate();
      });

      t2 = RawBloomTerminal(source.bloom, onInvalidated: () {
        events.add('t2');
      });

      t3 = RawBloomTerminal(source.bloom, onInvalidated: () {
        events.add('t3');
      });

      t4 = RawBloomTerminal(source.bloom, onInvalidated: () {
        events.add('t4');
      });

      t4.activate();
      t3.activate();
      t2.activate();
      t1.activate();

      source.set(200);

      expect(events.contains('t1'), isTrue);
      // t4 must still receive the invalidation signal even though t2 and t3 were detached
      expect(events.contains('t4'), isTrue, reason: 't4 must be reached even when intermediate nodes are detached');

      t1.deactivate();
      t4.deactivate();
    });

    test('Reentrant _propagateDirty on the same source node preserves outer target loop iteration', () {
      final source = blooming<int>(0);

      var countA = 0;
      var countB = 0;
      var reentrantFired = false;

      late final RawBloomTerminal<int> termA;
      late final RawBloomTerminal<int> termB;

      termA = RawBloomTerminal(source.bloom, onInvalidated: () {
        countA++;
        if (!reentrantFired) {
          reentrantFired = true;
          // Reentrantly mutate the same source during termA's invalidation.
          source.set(100);
        }
      });

      termB = RawBloomTerminal(source.bloom, onInvalidated: () {
        countB++;
      });

      // B activated first, then A -> list is A -> B
      termB.activate();
      termA.activate();

      source.set(1);

      expect(countA, greaterThanOrEqualTo(1));
      expect(countB, greaterThanOrEqualTo(1), reason: 'termB must not be skipped during reentrant dirty propagation');

      termA.deactivate();
      termB.deactivate();
    });
  });

  // Duplicate sources (e.g. `Effect([a, a])`) yield a second source edge that
  // `_attachSourceEdges` intentionally never attaches. Detaching it must be a no-op
  // and must never unlink or deactivate other subscribers of the shared source.
  group('LPDAG Target Detachment with Duplicate & Shared Sources Suite', () {
    test('Effect([a, a]) subscribes once and releases the source across repeated lifecycles', () async {
      final a = blooming(0);
      var runs = 0;
      final host = _hostEffect(Effect([a.bloom, a.bloom], () => runs++))
        ..activate()
        ..evaluate();
      await _tick();
      expect(a.isActive, isTrue);
      final base = runs;

      a.data = 1;
      await _tick();
      expect(runs, base + 1, reason: 'One mutation must trigger exactly one run (no double subscription)');

      host.deactivate();
      expect(a.isActive, isFalse, reason: 'Unattached duplicate edge must not keep the source alive');

      for (var i = 0; i < 3; i++) {
        host
          ..activate()
          ..evaluate();
        await _tick();
        expect(a.isActive, isTrue);
        host.deactivate();
        expect(a.isActive, isFalse);
      }
    });

    test('Detaching an effect with duplicate sources preserves a subscriber attached after it', () async {
      final a = blooming(0);
      final b = blooming(0);
      var invalidations = 0;

      final host = _hostEffect(Effect([a.bloom, b.bloom, a.bloom], () {}))
        ..activate()
        ..evaluate();
      await _tick();
      final other = RawBloomTerminal(a.bloom, onInvalidated: () => invalidations++)..activate();

      host.deactivate();
      expect(a.isActive, isTrue, reason: 'Remaining subscriber still holds the source');
      expect(b.isActive, isFalse);

      a.data = 1;
      expect(invalidations, 1, reason: 'Remaining subscriber must not be unlinked');

      other.deactivate();
      expect(a.isActive, isFalse);
    });

    test('Detaching an effect with duplicate sources preserves a subscriber attached before it', () async {
      final a = blooming(0);
      var invalidations = 0;
      final other = RawBloomTerminal(a.bloom, onInvalidated: () => invalidations++)..activate();

      final host = _hostEffect(Effect([a.bloom, a.bloom], () {}))
        ..activate()
        ..evaluate();
      await _tick();

      host.deactivate();
      expect(a.isActive, isTrue);
      a.data = 1;
      expect(invalidations, 1);

      other.deactivate();
      expect(a.isActive, isFalse);
    });

    test('Dynamic via: repeated reads and branch switch-back attach/detach each source exactly once', () {
      final a = blooming(1);
      final b = blooming(2);
      final useA = blooming(true);
      final terminal = RawViaTerminal<int>(
        (via) {
          if (via(useA.bloom)) return via(a.bloom) + via(a.bloom);
          return via(b.bloom);
        },
        onInvalidated: () {},
      )..activate();

      expect(terminal.evaluate(), 2);
      useA.data = false;
      expect(terminal.evaluate(), 2);
      expect(a.isActive, isFalse, reason: 'Swept edge must be detached');

      useA.data = true;
      expect(terminal.evaluate(), 2);
      expect(a.isActive, isTrue);
      expect(b.isActive, isFalse);

      terminal.deactivate();
      expect(a.isActive, isFalse);
      expect(useA.isActive, isFalse);
    });
  });
}

/// Hosts [effect] the way production code does: tethered from a via terminal.
RawViaTerminal<Effect> _hostEffect(Effect effect) => RawViaTerminal((via) => via.tether(effect), onInvalidated: () {});

Future<void> _tick() => Future<void>.delayed(Duration.zero);

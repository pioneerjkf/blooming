// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

void main() {
  group('BloomCoupler Comprehensive Unit Tests', () {
    // =========================================================================
    // 1. BloomCoupler Core API & Lifecycle
    // =========================================================================
    group('1. BloomCoupler Core API & Lifecycle', () {
      test('1.1 BloomCoupler proxies active downstream subscriber count and snapshot via .bloom', () {
        final source = blooming<int>(10);
        final coupler = BloomCoupler<int>(source.bloom);

        expect(coupler, isA<BloomCoupler<int>>());
        expect(coupler.bloom, isA<Bloom<int>>());
        expect(coupler.isActive, isFalse);
        expect(coupler.snapshot.data, 10);

        // Chain terminal on coupler.bloom
        final terminal = RawBloomTerminal(coupler.bloom, onInvalidated: () {});
        terminal.activate();

        expect(coupler.isActive, isTrue);
        expect(source.isActive, isTrue);

        source.set(20);
        expect(coupler.snapshot.data, 20);

        terminal.deactivate();
        expect(coupler.isActive, isFalse);
        expect(source.isActive, isFalse);
      });

      test('1.2 BloomCoupler couple, decouple, tryDecoupling, and coupleGuarded methods', () {
        final coupler = BloomCoupler<String>.late();
        expect(coupler.isEmpty, isTrue);

        final source1 = Bloom.constant('source_1');
        coupler.couple(source1);
        expect(coupler.hasData, isTrue);
        expect(coupler.data, 'source_1');

        coupler.coupleGuarded(() => throw Exception('Guard Failed'));
        expect(coupler.hasError, isTrue);
        expect(coupler.error, isA<Exception>());

        coupler.coupleGuarded(() => Bloom.constant('source_guarded'));
        expect(coupler.hasData, isTrue);
        expect(coupler.data, 'source_guarded');

        coupler.setError('Manual Error');
        expect(coupler.hasError, isTrue);
        expect(coupler.error, 'Manual Error');

        coupler.decouple();
        expect(coupler.isEmpty, isTrue);
      });

      test('1.3 BloomCoupler late and dynamic binding lifecycle', () {
        final source = Bloom.constant(100);
        final coupler = BloomCoupler<int>(source);

        expect(coupler.hasData, isTrue);
        expect(coupler.data, 100);

        coupler.couple(Bloom.constant(200));
        expect(coupler.data, 200);

        coupler.decouple();
        expect(coupler.isEmpty, isTrue);
      });

      test('1.4 BloomCoupler tryDecoupling method', () {
        final sourceA = Bloom.constant('A');
        final sourceB = Bloom.constant('B');
        final coupler = BloomCoupler<String>(sourceA);

        expect(coupler, isA<BloomCoupler<String>>());
        expect(coupler.bloom, isA<Bloom<String>>());
        expect(coupler.data, 'A');
        expect(untracked(coupler.bloom), 'A');

        coupler.couple(sourceB);
        expect(coupler.data, 'B');

        final failedDecouple = coupler.tryDecoupling(sourceA);
        expect(failedDecouple, isFalse);
        expect(coupler.hasData, isTrue);

        final successDecouple = coupler.tryDecoupling(sourceB);
        expect(successDecouple, isTrue);
        expect(coupler.isEmpty, isTrue);

        coupler.coupleGuarded(() => Bloom.constant('C'));
        expect(coupler.data, 'C');

        coupler.decouple();
        expect(coupler.isEmpty, isTrue);
      });
    });

    // =========================================================================
    // 2. BloomCoupler<List<T>> Core API & Lifecycle
    // =========================================================================
    group('2. BloomCoupler<List<T>> Core API & Lifecycle', () {
      test('2.1 BloomCoupler<List<T>> proxies active downstream subscriber count and snapshot', () {
        final source1 = blooming<int>(1);
        final source2 = blooming<int>(2);
        final group = Bloom.constant([source1.bloom, source2.bloom]);

        final coupler = BloomCoupler<List<Bloom<int>>>(group);
        expect(coupler.isActive, isFalse);
        expect(group.isActive, isFalse);

        final terminal = RawBloomTerminal(coupler.bloom, onInvalidated: () {});
        terminal.activate();

        expect(coupler.isActive, isTrue);
        expect(group.isActive, isTrue);

        final bloomData = coupler.snapshot.data.map((c) => untracked(c)).toList();
        expect(bloomData, [1, 2]);

        terminal.deactivate();
        expect(coupler.isActive, isFalse);
        expect(group.isActive, isFalse);
      });

      test('2.2 BloomCoupler<List<T>> couple, decouple, and coupleGuarded methods', () {
        final coupler = BloomCoupler<List<Bloom<String>>>.late();
        expect(coupler.isEmpty, isTrue);

        final group1 = Bloom.constant([Bloom.constant('a'), Bloom.constant('b')]);
        coupler.couple(group1);
        expect(coupler.hasData, isTrue);
        expect(coupler.data.map((c) => untracked(c)).toList(), ['a', 'b']);

        coupler.coupleGuarded(() => throw Exception('Guard Failed'));
        expect(coupler.hasError, isTrue);
        expect(coupler.error, isA<Exception>());

        final group2 = Bloom.constant([Bloom.constant('x')]);
        coupler.coupleGuarded(() => group2);
        expect(coupler.hasData, isTrue);
        expect(coupler.data.map((c) => untracked(c)).toList(), ['x']);

        coupler.setError('Manual Group Error');
        expect(coupler.hasError, isTrue);
        expect(coupler.error, 'Manual Group Error');

        coupler.decouple();
        expect(coupler.isEmpty, isTrue);
      });

      test('2.3 BloomCoupler<List<T>> type inference', () {
        final group = Bloom.constant([Bloom.constant(10), Bloom.constant(20)]);
        final coupler = BloomCoupler(group); // Inferred as BloomCoupler<List<Bloom<int>>>

        expect(coupler, isA<BloomCoupler<List<Bloom<int>>>>());
        expect(untracked(coupler.bloom).length, 2);
        expect(coupler.data.length, 2);

        final lateCoupler = BloomCoupler<List<Bloom<int>>>.late();
        expect(lateCoupler.isEmpty, isTrue);

        final errorCoupler = BloomCoupler<List<Bloom<int>>>.error('TestError');
        expect(errorCoupler.hasError, isTrue);
      });
    });

    // =========================================================================
    // 3. Coupler Isolation & Non-Interference Invariants
    // =========================================================================
    group('3. Coupler Isolation & Non-Interference Invariants', () {
      test('3.1 Multiple couplers on same source operate independently without interference', () {
        final sourceA = blooming('A_orig');
        final sourceB = blooming('B_orig');

        final coupler1 = BloomCoupler<String>(sourceA.bloom);
        final coupler2 = BloomCoupler<String>(sourceA.bloom);

        int c1Notify = 0, c2Notify = 0;
        final t1 = RawBloomTerminal(coupler1.bloom, onInvalidated: () => c1Notify++);
        final t2 = RawBloomTerminal(coupler2.bloom, onInvalidated: () => c2Notify++);
        t1.activate();
        t2.activate();

        expect(coupler1.snapshot.data, 'A_orig');
        expect(coupler2.snapshot.data, 'A_orig');

        // Couple only coupler1 to sourceB
        coupler1.couple(sourceB.bloom);
        expect(c1Notify, 1);
        expect(t1.data, 'B_orig'); // Pull resets pending state under Q1: A
        expect(c2Notify, 0);

        // Update sourceA -> only coupler2 should react
        sourceA.set('A_new');
        expect(c1Notify, 1);
        expect(c2Notify, 1);
        expect(t2.data, 'A_new');

        // Update sourceB -> only coupler1 should react
        sourceB.set('B_new');
        expect(c1Notify, 2);
        expect(c2Notify, 1);

        t1.deactivate();
        t2.deactivate();
      });

      test('3.2 Coupler couple must NOT steal or disrupt independent subscribers of the old source', () {
        final sourceA = blooming('A');
        final sourceB = blooming('B');

        int sourceANotifyCount = 0;
        int couplerNotifyCount = 0;

        final terminalA = RawBloomTerminal(sourceA.bloom, onInvalidated: () => sourceANotifyCount++);
        terminalA.activate();

        final coupler = BloomCoupler<String>(sourceA.bloom);
        final terminalCoupler = RawBloomTerminal(coupler.bloom, onInvalidated: () => couplerNotifyCount++);
        terminalCoupler.activate();

        // Couple to sourceB
        coupler.couple(sourceB.bloom);
        expect(couplerNotifyCount, 1);
        expect(terminalCoupler.data, 'B'); // Pull resets pending state under Q1: A
        expect(sourceANotifyCount, 0);

        // Update old sourceA
        sourceA.set('A_updated');
        expect(sourceANotifyCount, 1);
        expect(terminalA.data, 'A_updated');
        expect(couplerNotifyCount, 1);

        // Update new sourceB
        sourceB.set('B_updated');
        expect(sourceANotifyCount, 1);
        expect(couplerNotifyCount, 2);

        terminalA.deactivate();
        terminalCoupler.deactivate();
      });

      test('3.3 Topological lifecycle transition on couple with resources', () {
        int createA = 0, disposeA = 0;
        int createB = 0, disposeB = 0;

        final resA = managed(
          create: (_) {
            createA++;
            return 'resA';
          },
          dispose: (_) => disposeA++,
        );

        final resB = managed(
          create: (_) {
            createB++;
            return 'resB';
          },
          dispose: (_) => disposeB++,
        );

        final coupler = BloomCoupler<String>(resA);
        final terminal = RawBloomTerminal(coupler.bloom, onInvalidated: () {});
        terminal.activate();

        expect(terminal.data, 'resA');
        expect(createA, 1);
        expect(disposeA, 0);
        expect(createB, 0);

        coupler.couple(resB);

        expect(disposeA, 1);
        expect(createB, 0); // resB is pure lazy, not pulled yet!

        expect(terminal.data, 'resB');
        expect(createB, 1);
        expect(disposeB, 0);

        terminal.deactivate();
        expect(disposeB, 1);
      });

      test('3.4 setError and decouple do not notify independent source subscribers', () {
        final sharedSource = blooming('shared');
        int sourceNotifyCount = 0;
        int couplerNotifyCount = 0;

        final terminalSource = RawBloomTerminal(sharedSource.bloom, onInvalidated: () => sourceNotifyCount++);
        terminalSource.activate();

        final coupler = BloomCoupler<String>(sharedSource.bloom);
        final terminalCoupler = RawBloomTerminal(coupler.bloom, onInvalidated: () => couplerNotifyCount++);
        terminalCoupler.activate();

        coupler.setError(StateError('Coupler Error'));
        expect(couplerNotifyCount, 1);
        expect(terminalCoupler.hasError, isTrue); // Pull resets pending state under Q1: A
        expect(sourceNotifyCount, 0);

        coupler.decouple();
        expect(couplerNotifyCount, 2);
        expect(terminalCoupler.isEmpty, isTrue);
        expect(sourceNotifyCount, 0);

        terminalSource.deactivate();
        terminalCoupler.deactivate();
      });

      test('3.5 BloomCoupler<List<T>> subscriber isolation on couple', () {
        final groupA = blooming.list([Bloom.constant(1)]);
        final groupB = blooming.list([Bloom.constant(2)]);

        int groupANotify = 0;
        int couplerNotify = 0;

        final tA = RawBloomTerminal(groupA.bloom, onInvalidated: () => groupANotify++);
        tA.activate();

        final coupler = BloomCoupler<List<Bloom<int>>>(groupA.bloom);
        final tC = RawBloomTerminal(coupler.bloom, onInvalidated: () => couplerNotify++);
        tC.activate();

        coupler.couple(groupB.bloom);
        expect(couplerNotify, 1);
        expect(tC.data.length, 1); // Pull resets pending state under Q1: A
        expect(groupANotify, 0);

        groupA.set([Bloom.constant(10)]);
        expect(groupANotify, 1);
        expect(tA.data.length, 1);
        expect(couplerNotify, 1);

        groupB.set([Bloom.constant(20)]);
        expect(groupANotify, 1);
        expect(couplerNotify, 2);
        expect(tC.data.length, 1);

        tA.deactivate();
        tC.deactivate();
      });
    });

    // =========================================================================
    // 4. Daisy-Chained Couplers (3-Hop & Multi-Layer Chaining)
    // =========================================================================
    group('4. Daisy-Chained Couplers (Multi-Hop Propagation)', () {
      test('4.1 Daisy-chained 3-Hop Coupler propagates mutations cleanly', () {
        final rootController = blooming<int>(1);
        final hop1 = BloomCoupler<int>(rootController.bloom);
        final hop2 = BloomCoupler<int>(hop1.bloom);
        final hop3 = BloomCoupler<int>(hop2.bloom);

        int hop3DirtyCount = 0;
        final terminal = RawBloomTerminal(hop3.bloom, onInvalidated: () {
          hop3DirtyCount++;
        });
        terminal.activate();

        expect(hop3.data, 1);
        expect(hop3DirtyCount, 0);

        rootController.set(10);
        expect(hop3DirtyCount, 1);
        expect(hop3.data, 10);

        terminal.deactivate();
      });

      test('4.2 Daisy-chained Coupler intermediate couple and isolation', () {
        final rootA = blooming<String>('RootA');
        final rootB = blooming<String>('RootB');

        final hop1 = BloomCoupler<String>(rootA.bloom);
        final hop2 = BloomCoupler<String>(hop1.bloom);
        final hop3 = BloomCoupler<String>(hop2.bloom);

        final terminal = RawBloomTerminal(hop3.bloom, onInvalidated: () {});
        terminal.activate();

        expect(hop3.data, 'RootA');

        // Couple intermediate hop1 to rootB
        hop1.couple(rootB.bloom);
        expect(hop3.data, 'RootB');

        // Mutate rootA -> hop3 should not receive it
        rootA.set('RootA_Modified');
        expect(hop3.data, 'RootB');

        // Mutate rootB -> hop3 receives it
        rootB.set('RootB_Modified');
        expect(hop3.data, 'RootB_Modified');

        terminal.deactivate();
      });
    });
  });
}

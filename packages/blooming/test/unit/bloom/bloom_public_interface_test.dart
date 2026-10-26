// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

void main() {
  group('Dynamic Triad 1st-Class Public Interfaces & Constructors', () {
    test('1. computed functors (sync, future, stream, async) return pure Bloom<T>', () async {
      final a = blooming(10);

      // 1.1 sync
      final syncNode = computed((via) => via(a.bloom) * 2);
      expect(syncNode, isA<Bloom<int>>());
      expect(untracked(syncNode), 20);

      // 1.2 future
      final completer = Completer<String>();
      final futureNode = computed.future((via) => completer.future);
      expect(futureNode, isA<Bloom<String>>());
      expect(untracked.state(futureNode).isEmpty, isTrue);

      final term = RawBloomTerminal(futureNode, onInvalidated: () {});
      term.activate();

      // 1.3 async alias
      final completer2 = Completer<int>();
      final asyncNode = computed.async((via) => completer2.future);
      expect(asyncNode, isA<Bloom<int>>());

      // 1.4 stream
      final sc = StreamController<int>.broadcast();
      final streamNode = computed.stream((via) => sc.stream);
      expect(streamNode, isA<Bloom<int>>());

      completer.complete('done');
      await Future<void>.delayed(Duration.zero);
      expect(untracked(futureNode), 'done');

      term.deactivate();
      sc.close();
    });

    test('2. switched() functor (lazy, eager microtask scheduling & flicker-free)', () async {
      final cond = blooming(true);
      final branchA = blooming('A');
      final branchB = blooming('B');

      // 2.1 default (lazy): does NOT decouple on dirty; keeps old source until pulled!
      final lazySwitched = switched((via) => via(cond.bloom) ? branchA.bloom : branchB.bloom);
      expect(lazySwitched, isA<Bloom<String>>());
      expect(untracked(lazySwitched), 'A');

      cond.data = false;
      // Before reading data, old source is still safely intact, not decoupled to empty!
      expect(untracked.state(lazySwitched).hasData, isTrue);
      // Reads new branch on demand
      expect(untracked(lazySwitched), 'B');

      // 2.2 eager: schedules eager microtask switch upon trigger dirty!
      final eagerSwitched = switched(
        (via) => via(cond.bloom) ? branchA.bloom : branchB.bloom,
        eager: true,
      );
      expect(eagerSwitched, isA<Bloom<String>>());
      expect(untracked(eagerSwitched), 'B');

      final terminal = RawBloomTerminal(eagerSwitched, onInvalidated: () {});
      terminal.activate();

      // Trigger dirty
      cond.data = true;
      // Yield to microtask queue
      await Future<void>.delayed(Duration.zero);

      // Branch has pre-connected via microtask before downstream read!
      expect(untracked(eagerSwitched), 'A');
      terminal.deactivate();
    });

    test('3. managed() functor and lifecycle returns pure Bloom<T>', () {
      int disposed = 0;

      // 3.1 sync
      final syncManaged = managed<int>(
        create: (via) => 42,
        dispose: (_) => disposed++,
      );
      expect(syncManaged, isA<Bloom<int>>());

      final terminal = RawBloomTerminal(syncManaged, onInvalidated: () {});
      terminal.activate();
      expect(untracked(syncManaged), 42);
      terminal.deactivate();
      expect(disposed, 1);
    });

    test('4. retained extension on Bloom<T> and pure Bloom<T> interface with optional coupler', () {
      final source = blooming<int>(1);
      final pendingCoupler = BloomCoupler<bool>.late();
      final retainedNode = source.bloom.retained(pending: pendingCoupler);

      expect(retainedNode, isA<Bloom<int>>());
      expect(untracked(retainedNode), 1);
      expect(pendingCoupler.bloom, isA<Bloom<bool>>());
      expect(untracked(pendingCoupler.bloom), isFalse);

      final fromExtension = source.bloom.retained();
      expect(fromExtension, isA<Bloom<int>>());
      expect(untracked(fromExtension), 1);
    });

    test('5. SwitchedFunctor and ManagedFunctor eager option verification', () {
      final cond = blooming(true);
      final branchA = blooming('A');
      final branchB = blooming('B');

      final s1 = switched((via) => via(cond.bloom) ? branchA.bloom : branchB.bloom);
      expect(s1, isA<Bloom<String>>());
      expect(untracked(s1), 'A');

      final s2 = switched(
        (via) => via(cond.bloom) ? branchA.bloom : branchB.bloom,
        eager: true,
      );
      expect(s2, isA<Bloom<String>>());
      expect(untracked(s2), 'A');

      // Managed sync eager option
      final mEager = managed(
        create: (_) => 100,
        dispose: (_) {},
        eager: true,
      );
      expect(mEager, isA<Bloom<int>>());

      // Managed sync lazy option (default)
      final mLazy = managed(
        create: (_) => 200,
        dispose: (_) {},
        eager: false,
      );
      expect(mLazy, isA<Bloom<int>>());
    });
  });
}

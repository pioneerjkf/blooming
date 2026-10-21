// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

void main() {
  group('The Dynamic Triad Top-Level Functions (computed, switched, managed) Suite', () {
    // =========================================================================
    // 1. Top-Level managed() & resource() Alias Tests
    // =========================================================================
    group('1. Top-Level managed() Functor', () {
      test('1.1 managed() creates lifecycle-supervised node activating on terminal connection', () {
        int created = 0;
        int disposed = 0;

        final client = managed<String>(
          create: (_) {
            created++;
            return 'HttpClient';
          },
          dispose: (_) => disposed++,
        );

        expect(created, 0);
        expect(disposed, 0);

        final terminal = RawBloomTerminal(client, onInvalidated: () {});
        expect(created, 0);

        terminal.activate();
        expect(created, 0);
        expect(terminal.data, 'HttpClient');
        expect(created, 1);

        terminal.deactivate();
        expect(disposed, 1);
      });

      test('1.2 managed() with guard & reason guards allocation', () {
        final token = BloomController<String>.late();
        int created = 0;
        int disposed = 0;

        final ws = managed<String>(
          guard: (via) => via.state(token.bloom).hasData.guarded('AwaitingAuthToken'),
          create: (via) {
            created++;
            return 'WebSocket(${via(token.bloom)})';
          },
          dispose: (_) => disposed++,
        );

        final terminal = RawBloomTerminal(ws, onInvalidated: () {});
        terminal.activate();

        // Guarded: token is empty
        expect(terminal.isEmpty, isTrue);
        expect(terminal.snapshot.emptyReason, 'AwaitingAuthToken');
        expect(created, 0);

        // Token becomes ready
        token.set('token-abc');
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'WebSocket(token-abc)');
        expect(created, 1);

        // Invalidate token -> should dispose and transition to empty
        token.empty();
        expect(terminal.isEmpty, isTrue);
        expect(disposed, 1);
      });

      test('1.3 managed() factory works identically to top-level managed()', () {
        int created = 0;
        int disposed = 0;

        final res = managed<int>(
          create: (_) {
            created++;
            return 999;
          },
          dispose: (_) => disposed++,
        );

        final terminal = RawBloomTerminal(res, onInvalidated: () {});
        terminal.activate();

        expect(created, 0);
        expect(terminal.data, 999);
        expect(created, 1);

        terminal.deactivate();
        expect(disposed, 1);
      });
    });

    // =========================================================================
    // 2. Top-Level switched() Functor Tests
    // =========================================================================
    group('2. Top-Level switched() Functor', () {
      test('2.1 switched() dynamically flattens active subtree branches', () {
        final isVip = BloomController(false);
        final normalFeed = BloomController('Normal Feed');
        final vipFeed = BloomController('VIP Feed');

        final activeFeed = switched((via) => via(isVip.bloom) ? vipFeed.bloom : normalFeed.bloom);

        final terminal = RawBloomTerminal(activeFeed, onInvalidated: () {});
        terminal.activate();

        expect(terminal.data, 'Normal Feed');

        // Dynamic branch mutation
        normalFeed.data = 'Normal Feed Updated';
        expect(terminal.data, 'Normal Feed Updated');

        // Switch to VIP branch
        isVip.data = true;
        expect(terminal.data, 'VIP Feed');

        // VIP branch mutation
        vipFeed.data = 'VIP Feed Special';
        expect(terminal.data, 'VIP Feed Special');

        // Normal branch mutation does not affect active VIP subscription
        normalFeed.data = 'Normal Ignored';
        expect(terminal.data, 'VIP Feed Special');
      });

      test('2.2 switched() with guard & reason', () {
        final isAuth = BloomController(false);
        final tab = BloomController(0);
        final feed0 = BloomController('Tab 0');
        final feed1 = BloomController('Tab 1');

        final feed = switched(
          (via) => via(tab.bloom) == 0 ? feed0.bloom : feed1.bloom,
          guard: (via) => via(isAuth.bloom).guarded('AwaitingLogin'),
        );

        final terminal = RawBloomTerminal(feed, onInvalidated: () {});
        terminal.activate();

        expect(terminal.isEmpty, isTrue);
        expect(terminal.snapshot.emptyReason, 'AwaitingLogin');

        isAuth.data = true;
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'Tab 0');

        tab.data = 1;
        expect(terminal.data, 'Tab 1');
      });
    });

    // =========================================================================
    // 3. Dynamic Triad Interplay: managed -> computed -> switched
    // =========================================================================
    group('3. Dynamic Triad Interplay (computed + switched + managed)', () {
      test('3.1 Full pipeline: managed client fed into computed stats and switched channels', () {
        final isConnected = BloomController(false);
        final channelId = BloomController(1);

        // 1. Managed resource
        final socket = managed<String>(
          guard: (via) => via(isConnected.bloom).guarded('Disconnected'),
          create: (_) => 'SocketClient',
          dispose: (_) {},
        );

        // 2. Computed derivation
        final socketStatus = computed(
          (via) => '${via(socket)} is active on channel ${via(channelId.bloom)}',
          guard: (via) => via.state(socket).hasData.guarded('SocketNotReady'),
        );

        // 3. Switched subtree
        final fallbackBloom = BloomController('Offline Banner');
        final liveBloom = socketStatus;
        final display = switched(
          (via) => via(isConnected.bloom) ? liveBloom : fallbackBloom.bloom,
        );

        final terminal = RawBloomTerminal(display, onInvalidated: () {});
        terminal.activate();

        // Initially offline
        expect(terminal.data, 'Offline Banner');

        // Connect
        isConnected.data = true;
        expect(terminal.data, 'SocketClient is active on channel 1');

        // Change channel
        channelId.data = 2;
        expect(terminal.data, 'SocketClient is active on channel 2');

        // Disconnect
        isConnected.data = false;
        expect(terminal.data, 'Offline Banner');
      });

      test('3.2 managed() with upstream dependency', () {
        final upstream = BloomController(10);
        int created = 0;
        int disposed = 0;

        final derived = managed<String>(
          create: (via) {
            created++;
            return 'Derived(${via(upstream.bloom)})';
          },
          dispose: (_) => disposed++,
        );

        final terminal = RawBloomTerminal(derived, onInvalidated: () {});
        terminal.activate();

        expect(created, 0);
        expect(terminal.data, 'Derived(10)');
        expect(created, 1);

        upstream.data = 20;
        expect(terminal.data, 'Derived(20)');
        expect(created, 2);
        expect(disposed, 1);

        terminal.deactivate();
        expect(disposed, 2);
      });
    });

    // =========================================================================
    // 4. Bloom Namespaced Static Functors (Bloom.computed, Bloom.switched, Bloom.managed)
    // =========================================================================
    group('4. Bloom Namespaced Static Functors Suite', () {
      test('4.1 Bloom.computed works identically to top-level computed', () {
        final a = BloomController(5);
        final b = BloomController(15);
        final sum = Bloom.computed((via) => via(a.bloom) + via(b.bloom));

        expect(untracked(sum), 20);
        a.data = 10;
        expect(untracked(sum), 25);
      });

      test('4.2 Bloom.computed.future & Bloom.computed.stream work seamlessly', () async {
        final id = BloomController(1);
        final user = Bloom.computed.future(
          (via) async => 'User-${via(id.bloom)}',
          initialFactory: () => 'Initial',
        );

        final termFuture = RawBloomTerminal(user, onInvalidated: () {})..activate();
        expect(termFuture.data, 'Initial');
        await Future<void>.delayed(Duration.zero);
        expect(termFuture.data, 'User-1');
        termFuture.deactivate();

        final count = BloomController(0);
        final stream = Bloom.computed.stream(
          (via) => Stream.value('Count:${via(count.bloom)}'),
          initialFactory: () => 'Count:init',
        );

        final term = RawBloomTerminal(stream, onInvalidated: () {})..activate();
        expect(term.data, 'Count:init');
        await Future<void>.delayed(Duration.zero);
        expect(term.data, 'Count:0');
        term.deactivate();
      });

      test('4.3 Bloom.switched works identically to top-level switched', () {
        final flag = BloomController(true);
        final branchA = BloomController('A');
        final branchB = BloomController('B');

        final active = Bloom.switched((via) => via(flag.bloom) ? branchA.bloom : branchB.bloom);

        expect(untracked(active), 'A');
        flag.data = false;
        expect(untracked(active), 'B');
      });

      test('4.4 Bloom.managed works identically to top-level managed', () {
        int disposed = 0;
        final res = Bloom.managed<int>(
          create: (_) => 42,
          dispose: (_) => disposed++,
        );

        final term = RawBloomTerminal(res, onInvalidated: () {})..activate();
        expect(term.data, 42);
        term.deactivate();
        expect(disposed, 1);
      });
    });
  });
}

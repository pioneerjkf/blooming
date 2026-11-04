// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';
import 'package:test/test.dart';

void main() {
  group('BloomVia.exit & BloomVia.exitIfInactive Suite', () {
    // =========================================================================
    // 1. BloomVia.exit() in synchronous computed & guards
    // =========================================================================
    group('1. via.exit() in computed and guard', () {
      test('1.1 via.exit() directly inside compute short-circuits with Empty state', () {
        var reachedAfterExit = false;
        final trigger = blooming(true);

        final node = computed<int>((via) {
          if (via(trigger.bloom)) {
            via.exit(emptyReason: 'ConditionMet');
          }
          reachedAfterExit = true;
          return 42;
        });

        expect(untracked.state(node).isEmpty, isTrue);
        expect(untracked.state(node).emptyReason, 'ConditionMet');
        expect(reachedAfterExit, isFalse);

        // Turn off trigger -> normally returns 42
        trigger.data = false;
        expect(untracked.state(node).hasData, isTrue);
        expect(untracked(node), 42);
        expect(untracked.state(node).emptyReason, isNull);
        expect(reachedAfterExit, isTrue);
      });

      test('1.2 via.exit() with default null emptyReason', () {
        final node = computed<int>((via) {
          via.exit();
        });

        expect(untracked.state(node).isEmpty, isTrue);
        expect(untracked.state(node).emptyReason, isNull);
      });

      test('1.3 guard calling via.exit() aborts before compute is invoked', () {
        var computeCalled = false;
        final allowed = blooming(false);

        final node = computed<String>(
          (via) {
            computeCalled = true;
            return 'secret';
          },
          guard: (via) {
            if (!via(allowed.bloom)) {
              via.exit(emptyReason: 'Forbidden');
            }
          },
        );

        expect(untracked.state(node).isEmpty, isTrue);
        expect(untracked.state(node).emptyReason, 'Forbidden');
        expect(computeCalled, isFalse);

        allowed.data = true;
        expect(untracked.state(node).hasData, isTrue);
        expect(untracked(node), 'secret');
        expect(computeCalled, isTrue);
      });
    });

    // =========================================================================
    // 2. Resource leak prevention in managed
    // =========================================================================
    group('2. managed leak prevention with guard & via.exit', () {
      test('2.1 via.exit() in managed guard prevents create from executing', () {
        var resourceAllocated = false;
        var resourceDisposed = false;
        final isAuthorized = blooming(false);

        final client = managed<String>(
          guard: (via) {
            if (!via(isAuthorized.bloom)) {
              via.exit(emptyReason: 'Unauthorized');
            }
          },
          create: (via) {
            resourceAllocated = true;
            return 'AllocatedSocket';
          },
          dispose: (_) {
            resourceDisposed = true;
          },
        );

        final terminal = RawBloomTerminal(client, onInvalidated: () {});
        terminal.activate();

        // Guard blocked: create was NOT called
        expect(terminal.isEmpty, isTrue);
        expect(terminal.emptyReason, 'Unauthorized');
        expect(resourceAllocated, isFalse);
        expect(resourceDisposed, isFalse);

        // Authorize: create is now called
        isAuthorized.data = true;
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 'AllocatedSocket');
        expect(resourceAllocated, isTrue);

        // Deauthorize: guard exits, existing resource is disposed
        isAuthorized.data = false;
        expect(terminal.isEmpty, isTrue);
        expect(terminal.emptyReason, 'Unauthorized');
        expect(resourceDisposed, isTrue);

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 3. BloomVia.exitIfInactive in asynchronous computed.future
    // =========================================================================
    group('3. via.exitIfInactive in async computed.future', () {
      test('3.1 exitIfInactive does nothing while turn is still active', () async {
        final source = blooming(10);

        final futureBloom = computed.future<int>((via) async {
          final val = via(source.bloom);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          via.exitIfInactive(emptyReason: 'TurnSuperseded');
          return val * 2;
        });

        final terminal = RawBloomTerminal(futureBloom, onInvalidated: () {});
        terminal.activate();

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(terminal.hasData, isTrue);
        expect(terminal.data, 20);

        terminal.deactivate();
      });

      test('3.2 exitIfInactive aborts stale turn when newer turn was triggered mid-await', () async {
        final query = blooming('first');
        final completerFirst = Completer<void>();
        final executionLog = <String>[];

        final searchNode = computed.future<String>((via) async {
          final q = via(query.bloom);
          executionLog.add('start:$q');
          if (q == 'first') {
            await completerFirst.future;
          } else {
            await Future<void>.delayed(Duration.zero);
          }
          via.exitIfInactive(emptyReason: 'StaleQuery');
          executionLog.add('finish:$q');
          return 'Result for $q';
        });

        final terminal = RawBloomTerminal(searchNode, onInvalidated: () {});
        terminal.activate();

        await Future<void>.delayed(Duration.zero);
        expect(executionLog, contains('start:first'));
        expect(executionLog, isNot(contains('finish:first')));

        // Trigger new query while 'first' is still awaiting
        query.data = 'second';
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(executionLog, contains('start:second'));
        expect(executionLog, contains('finish:second'));
        expect(terminal.data, 'Result for second');

        // Now resume the stale 'first' turn
        completerFirst.complete();
        await Future<void>.delayed(Duration.zero);

        // 'finish:first' should NOT have executed because via.exitIfInactive short-circuited it
        expect(executionLog, isNot(contains('finish:first')));
        expect(terminal.data, 'Result for second');

        terminal.deactivate();
      });

      test('3.3 exitIfInactive aborts in-flight execution when node is deactivated during await', () async {
        final completer = Completer<void>();
        var postAwaitExecuted = false;

        final node = computed.future<String>((via) async {
          await completer.future;
          via.exitIfInactive(emptyReason: 'DormantTurn');
          postAwaitExecuted = true;
          return 'Result';
        });

        final terminal = RawBloomTerminal(node, onInvalidated: () {});
        terminal.activate();

        // Terminal is active and node is awaiting completer
        await Future<void>.delayed(Duration.zero);
        expect(postAwaitExecuted, isFalse);

        // Deactivate terminal -> node becomes dormant/inactive
        terminal.deactivate();

        // Now complete the future while node is dormant
        completer.complete();
        await Future<void>.delayed(Duration.zero);

        // postAwaitExecuted must be false because exitIfInactive short-circuited it
        expect(postAwaitExecuted, isFalse);
      });
    });

    // =========================================================================
    // 4. EffectVia Decoupling & Strict Type Boundary
    // =========================================================================
    group('4. EffectVia decoupling & strict type boundary', () {
      test('4.1 Effect.via action receives strictly EffectVia and not BloomVia', () async {
        final trigger = blooming(1);
        EffectVia? capturedVia;

        final effect = Effect.via((via) {
          via(trigger.bloom);
          capturedVia = via;
        });

        final terminal = RawViaTerminal((via) {
          via.tether(effect);
        }, onInvalidated: () {});
        terminal.activate();
        terminal.evaluate();

        await Future<void>.delayed(Duration.zero);

        expect(capturedVia, isNotNull);
        expect(capturedVia, isA<EffectVia>());
        expect(capturedVia is BloomVia, isFalse);
        expect(
          () => (capturedVia as dynamic) as BloomVia,
          throwsA(isA<TypeError>()),
        );

        terminal.deactivate();
      });

      test('4.2 Effect.scoped.via action receives strictly EffectVia and not BloomVia', () async {
        final trigger = blooming(1);
        EffectVia? capturedVia;

        final effect = Effect.scoped.via((via, scope) {
          via(trigger.bloom);
          capturedVia = via;
        });

        final terminal = RawViaTerminal((via) {
          via.tether(effect);
        }, onInvalidated: () {});
        terminal.activate();
        terminal.evaluate();

        await Future<void>.delayed(Duration.zero);

        expect(capturedVia, isNotNull);
        expect(capturedVia, isA<EffectVia>());
        expect(capturedVia is BloomVia, isFalse);
        expect(
          () => (capturedVia as dynamic) as BloomVia,
          throwsA(isA<TypeError>()),
        );

        terminal.deactivate();
      });

      test('4.3 Effect.via guard receives strictly EffectVia and not BloomVia', () async {
        final trigger = blooming(1);
        EffectVia? guardVia;

        final effect = Effect.via(
          (via) {},
          guard: (via) {
            via(trigger.bloom);
            guardVia = via;
            return true;
          },
        );

        final terminal = RawViaTerminal((via) {
          via.tether(effect);
        }, onInvalidated: () {});
        terminal.activate();
        terminal.evaluate();

        await Future<void>.delayed(Duration.zero);

        expect(guardVia, isNotNull);
        expect(guardVia, isA<EffectVia>());
        expect(guardVia is BloomVia, isFalse);
        expect(
          () => (guardVia as dynamic) as BloomVia,
          throwsA(isA<TypeError>()),
        );

        terminal.deactivate();
      });

      test('4.4 BloomVia does not implement EffectVia', () {
        BloomVia? capturedVia;
        final node = computed<int>((via) {
          capturedVia = via;
          return 42;
        });

        expect(untracked(node), 42);
        expect(capturedVia, isNotNull);
        expect(capturedVia, isA<BloomVia>());
        expect(capturedVia is EffectVia, isFalse);
        expect(
          () => (capturedVia as dynamic) as EffectVia,
          throwsA(isA<TypeError>()),
        );
      });
    });

    // =========================================================================
    // 5. Escaped BloomVia exit & exitIfInactive Behavior
    // =========================================================================
    group('5. Escaped BloomVia exit & exitIfInactive behavior', () {
      test('5.1 escaped via.exit() throws unhandled Error outside evaluation scope', () {
        BloomVia? escapedVia;
        final node = computed<int>((via) {
          escapedVia = via;
          return 42;
        });

        expect(untracked(node), 42);
        expect(escapedVia, isNotNull);

        // Calling exit() on escaped via cannot be no-op (returns Never) and throws Error
        expect(
          () => escapedVia!.exit(emptyReason: 'EscapedExit'),
          throwsA(isA<Error>()),
        );
      });

      test('5.2 escaped via.exitIfInactive() delegates to exit() and throws Error when inactive', () {
        BloomVia? escapedVia;
        final node = computed<int>((via) {
          escapedVia = via;
          return 100;
        });

        // Evaluate once; node is dormant/inactive
        expect(untracked(node), 100);
        expect(escapedVia, isNotNull);

        // Inactive scope causes exitIfInactive() to call exit(), throwing Error
        expect(
          () => escapedVia!.exitIfInactive(emptyReason: 'EscapedExitIfInactive'),
          throwsA(isA<Error>()),
        );
      });
    });
  });
}

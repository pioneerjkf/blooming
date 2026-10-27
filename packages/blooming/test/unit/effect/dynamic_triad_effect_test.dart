// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:blooming/effect.dart';
import 'package:blooming/blooming.dart';

void main() {
  group('The Dynamic Triad (computed, switched, managed) x EffectRunner Matrix', () {
    // =========================================================================
    // 1. Unary Primitives directly connected to EffectRunner
    // =========================================================================
    group('1. Unary Primitives x EffectRunner', () {
      test('1.1 computed -> EffectRunner: primes DAG, skips initial, responds to upstream mutation', () async {
        final count = blooming<int>(10);
        final doubled = computed((via) => via(count.bloom) * 2);

        final captured = <int>[];
        final runner = doubled.effect(() {
          captured.add(untracked(doubled));
        }).start();

        expect(runner.isActive, isTrue);
        expect(captured, isEmpty, reason: 'Must skip initial execution');

        count.data = 20;
        await Future<void>.delayed(Duration.zero);
        expect(captured, [40]);

        count.data = 30;
        await Future<void>.delayed(Duration.zero);
        expect(captured, [40, 60]);

        runner.stop();
        count.data = 40;
        await Future<void>.delayed(Duration.zero);
        expect(captured, [40, 60], reason: 'Deactivated runner must not capture mutations');
      });

      test('1.2 switched -> EffectRunner: primes active branch, tracks mutation, dynamically switches', () async {
        final useVip = blooming<bool>(false);
        final normalFeed = blooming<String>('Normal 1');
        final vipFeed = blooming<String>('VIP 1');

        final activeFeed = switched(
          (via) => via(useVip.bloom) ? vipFeed.bloom : normalFeed.bloom,
        );

        final captured = <String>[];
        final runner = activeFeed.effect(() {
          captured.add(untracked(activeFeed));
        }).start();

        expect(captured, isEmpty);

        // Mutate currently active normal branch
        normalFeed.data = 'Normal 2';
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Normal 2']);

        // Mutate inactive VIP branch (must be ignored)
        vipFeed.data = 'VIP 2';
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Normal 2']);

        // Switch branch to VIP
        useVip.data = true;
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Normal 2', 'VIP 2']);

        // Mutate now active VIP branch
        vipFeed.data = 'VIP 3';
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Normal 2', 'VIP 2', 'VIP 3']);

        // Mutate swept normal branch (must be ignored)
        normalFeed.data = 'Normal 3';
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Normal 2', 'VIP 2', 'VIP 3']);

        runner.stop();
      });

      test('1.3 managed -> EffectRunner: creates resource upon activation, disposes on deactivation', () async {
        final port = blooming<int>(8080);
        int created = 0;
        int updated = 0;
        int disposed = 0;

        final server = managed<String>(
          create: (via) {
            created++;
            return 'Server(:${via(port.bloom)})';
          },
          update: (via, current) {
            updated++;
            return 'Server(:${via(port.bloom)})';
          },
          dispose: (_) => disposed++,
        );

        expect(created, 0);
        expect(disposed, 0);

        final captured = <String>[];
        final runner = server.effect(() {
          captured.add(untracked(server));
        }).start();

        expect(created, 1, reason: 'Activation must prime managed resource');
        expect(captured, isEmpty, reason: 'Effect action must skip initial run');
        expect(disposed, 0);

        port.data = 9090;
        await Future<void>.delayed(Duration.zero);
        expect(updated, 1);
        expect(captured, ['Server(:9090)']);

        runner.stop();
        expect(disposed, 2, reason: 'Old resource disposed on update, active resource disposed on runner deactivation');
      });
    });

    // =========================================================================
    // 2. Pairwise 2-Stage Composite Pipelines
    // =========================================================================
    group('2. Pairwise 2-Stage Composite Pipelines', () {
      test('2.1 computed -> switched -> EffectRunner (computed condition drives switched selection)', () async {
        final score = blooming<int>(50);
        final passNode = blooming<String>('PASS');
        final failNode = blooming<String>('FAIL');

        final isPassed = computed((via) => via(score.bloom) >= 60);
        final status = switched((via) => via(isPassed) ? passNode.bloom : failNode.bloom);

        final captured = <String>[];
        final runner = status.effect(() {
          captured.add(untracked(status));
        }).start();

        expect(captured, isEmpty);

        // Mutate score crossing boundary
        score.data = 75;
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['PASS']);

        // Mutate active PASS node
        passNode.data = 'PASS (HONORS)';
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['PASS', 'PASS (HONORS)']);

        runner.stop();
      });

      test('2.2 switched -> computed -> EffectRunner (computed derives from dynamic branch output)', () async {
        final mode = blooming<int>(1);
        final rateA = blooming<double>(1.1);
        final rateB = blooming<double>(1.5);

        final activeRate = switched((via) => via(mode.bloom) == 1 ? rateA.bloom : rateB.bloom);
        final price = computed((via) => (100.0 * via(activeRate)).toStringAsFixed(1));

        final captured = <String>[];
        final runner = price.effect(() {
          captured.add(untracked(price));
        }).start();

        expect(captured, isEmpty);

        // Mutate active rateA
        rateA.data = 1.2;
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['120.0']);

        // Switch to mode 2 (rateB = 1.5)
        mode.data = 2;
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['120.0', '150.0']);

        runner.stop();
      });

      test('2.3 managed -> computed -> EffectRunner (computed derives from managed resource)', () async {
        final capacity = blooming<int>(5);
        int created = 0;
        int disposed = 0;

        final pool = managed<List<String>>(
          create: (via) {
            created++;
            return List.generate(via(capacity.bloom), (i) => 'Item $i');
          },
          dispose: (_) => disposed++,
        );

        final poolSummary = computed((via) => 'Pool size: ${via(pool).length}');

        final captured = <String>[];
        final runner = poolSummary.effect(() {
          captured.add(untracked(poolSummary));
        }).start();

        expect(created, 1);
        expect(captured, isEmpty);

        capacity.data = 8;
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Pool size: 8']);

        runner.stop();
        expect(disposed, 2, reason: 'Disposed once on replacement, once on runner deactivation');
      });

      test('2.4 computed -> managed -> EffectRunner (computed feeds managed lifecycle input)', () async {
        final host = blooming<String>('api.example.com');
        final isSecure = blooming<bool>(true);

        final url = computed((via) => '${via(isSecure.bloom) ? 'https' : 'http'}://${via(host.bloom)}');

        int created = 0;
        int disposed = 0;
        final client = managed<String>(
          create: (via) {
            created++;
            return 'HttpClient(${via(url)})';
          },
          dispose: (_) => disposed++,
        );

        final captured = <String>[];
        final runner = client.effect(() {
          captured.add(untracked(client));
        }).start();

        expect(created, 1);
        expect(captured, isEmpty);

        isSecure.data = false;
        await Future<void>.delayed(Duration.zero);
        expect(created, 2);
        expect(disposed, 1);
        expect(captured, ['HttpClient(http://api.example.com)']);

        runner.stop();
        expect(disposed, 2);
      });

      test('2.5 managed -> switched -> EffectRunner (switched selects between managed resources)', () async {
        final useProduction = blooming<bool>(false);
        int devCreated = 0;
        int devDisposed = 0;
        int prodCreated = 0;
        int prodDisposed = 0;

        final devDb = managed<String>(
          create: (_) {
            devCreated++;
            return 'DevDatabase';
          },
          dispose: (_) => devDisposed++,
        );

        final prodDb = managed<String>(
          create: (_) {
            prodCreated++;
            return 'ProdDatabase';
          },
          dispose: (_) => prodDisposed++,
        );

        final activeDb = switched(
          (via) => via(useProduction.bloom) ? prodDb : devDb,
        );

        final captured = <String>[];
        final runner = activeDb.effect(() {
          captured.add(untracked(activeDb));
        }).start();

        expect(devCreated, 1);
        expect(prodCreated, 0, reason: 'Inactive prod branch must stay dormant');
        expect(captured, isEmpty);

        // Switch to Prod: dev must be disposed, prod created
        useProduction.data = true;
        await Future<void>.delayed(Duration.zero);

        expect(devDisposed, 1, reason: 'Swept dev branch must be disposed');
        expect(prodCreated, 1, reason: 'Newly selected prod branch must be created');
        expect(captured, ['ProdDatabase']);

        runner.stop();
        expect(prodDisposed, 1, reason: 'Deactivating runner must dispose active prod branch');
      });

      test('2.6 switched -> managed -> EffectRunner (switched feeds managed lifecycle input)', () async {
        final tier = blooming<String>('free');
        final freeLimit = blooming<int>(10);
        final paidLimit = blooming<int>(100);

        final limit = switched(
          (via) => via(tier.bloom) == 'paid' ? paidLimit.bloom : freeLimit.bloom,
        );

        int created = 0;
        int disposed = 0;
        final limiter = managed<String>(
          create: (via) {
            created++;
            return 'Limiter(${via(limit)})';
          },
          dispose: (_) => disposed++,
        );

        final captured = <String>[];
        final runner = limiter.effect(() {
          captured.add(untracked(limiter));
        }).start();

        expect(created, 1);
        expect(captured, isEmpty);

        // Mutate active limit
        freeLimit.data = 15;
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Limiter(15)']);

        // Switch to paid
        tier.data = 'paid';
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Limiter(15)', 'Limiter(100)']);

        runner.stop();
        expect(disposed, 3);
      });
    });

    // =========================================================================
    // 3. 3-Stage Full Dynamic Triad Pipeline (Full Integration)
    // =========================================================================
    group('3. 3-Stage Full Dynamic Triad Pipeline', () {
      test('3.1 managed -> computed -> switched -> EffectRunner: full pipeline with sweeping & disposal', () async {
        final isBackup = blooming<bool>(false);
        final primaryPort = blooming<int>(5432);
        final backupPort = blooming<int>(5433);

        int primaryCreated = 0;
        int primaryDisposed = 0;
        final primaryDb = managed<String>(
          create: (via) {
            primaryCreated++;
            return 'PrimaryDb(:${via(primaryPort.bloom)})';
          },
          dispose: (_) => primaryDisposed++,
        );

        int backupCreated = 0;
        int backupDisposed = 0;
        final backupDb = managed<String>(
          create: (via) {
            backupCreated++;
            return 'BackupDb(:${via(backupPort.bloom)})';
          },
          dispose: (_) => backupDisposed++,
        );

        final primaryDerived = computed((via) => 'Active: ${via(primaryDb)}');
        final backupDerived = computed((via) => 'Active: ${via(backupDb)}');

        final currentConnection = switched(
          (via) => via(isBackup.bloom) ? backupDerived : primaryDerived,
        );

        final captured = <String>[];
        final runner = currentConnection.effect(() {
          captured.add(untracked(currentConnection));
        }).start();

        // 1. Priming: primary is active, backup is dormant
        expect(primaryCreated, 1);
        expect(backupCreated, 0);
        expect(captured, isEmpty);

        // 2. Mutate primary port
        primaryPort.data = 5434;
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Active: PrimaryDb(:5434)']);

        // 3. Failover to backup: primary disposes, backup creates
        isBackup.data = true;
        await Future<void>.delayed(Duration.zero);
        expect(primaryDisposed, 2);
        expect(backupCreated, 1);
        expect(captured, ['Active: PrimaryDb(:5434)', 'Active: BackupDb(:5433)']);

        // 4. Mutate backup port
        backupPort.data = 9999;
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Active: PrimaryDb(:5434)', 'Active: BackupDb(:5433)', 'Active: BackupDb(:9999)']);

        // 5. Cleanup
        runner.stop();
        expect(backupDisposed, 2);
      });

      test('3.2 computed -> switched -> managed -> EffectRunner: dynamic resource driven by derived switch', () async {
        final userRole = blooming<String>('guest');
        final isElevated = computed((via) => via(userRole.bloom) == 'admin' || via(userRole.bloom) == 'owner');

        final defaultQuota = blooming<int>(10);
        final elevatedQuota = blooming<int>(1000);

        final activeQuota = switched((via) => via(isElevated) ? elevatedQuota.bloom : defaultQuota.bloom);

        int allocated = 0;
        int released = 0;
        final session = managed<String>(
          create: (via) {
            allocated++;
            return 'Session(quota: ${via(activeQuota)})';
          },
          dispose: (_) => released++,
        );

        final captured = <String>[];
        final runner = session.effect(() {
          captured.add(untracked(session));
        }).start();

        expect(allocated, 1);
        expect(captured, isEmpty);

        // Promote role
        userRole.data = 'admin';
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Session(quota: 1000)']);

        // Mutate elevated quota directly
        elevatedQuota.data = 5000;
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Session(quota: 1000)', 'Session(quota: 5000)']);

        runner.stop();
        expect(released, 3);
      });
    });

    // =========================================================================
    // 4. Multi-Target (N-ary) Tuples x EffectRunner
    // =========================================================================
    group('4. Multi-Target (N-ary) Tuples x EffectRunner', () {
      test('4.1 (computed, switched).effect(...).start(): both prime and trigger independently', () async {
        final a = blooming<int>(1);
        final comp = computed((via) => via(a.bloom) * 10);

        final toggle = blooming<bool>(false);
        final opt1 = blooming<String>('Opt1');
        final opt2 = blooming<String>('Opt2');
        final sw = switched((via) => via(toggle.bloom) ? opt2.bloom : opt1.bloom);

        var runs = 0;
        final runner = (comp, sw).effect(() {
          runs++;
        }).start();

        expect(runs, 0);

        a.data = 2;
        await Future<void>.delayed(Duration.zero);
        expect(runs, 1);

        toggle.data = true;
        await Future<void>.delayed(Duration.zero);
        expect(runs, 2);

        runner.stop();
      });

      test('4.2 (computed, managed).effect(...).start(): primes computation and allocates resource atomically',
          () async {
        final numCtrl = blooming<int>(5);
        final doubled = computed((via) => via(numCtrl.bloom) * 2);

        int created = 0;
        int disposed = 0;
        final res = managed<String>(
          create: (_) {
            created++;
            return 'Resource';
          },
          dispose: (_) => disposed++,
        );

        var runs = 0;
        final runner = (doubled, res).effect(() {
          runs++;
        }).start();

        expect(created, 1);
        expect(runs, 0);

        numCtrl.data = 10;
        await Future<void>.delayed(Duration.zero);
        expect(runs, 1);

        runner.stop();
        expect(disposed, 1);
      });

      test('4.3 (computed, switched, managed).effect(...).start(): 3-tuple primes all 3 Dynamic Triad primitives',
          () async {
        final numCtrl = blooming<int>(1);
        final comp = computed((via) => via(numCtrl.bloom) + 100);

        final sel = blooming<bool>(false);
        final branchA = blooming<String>('A');
        final branchB = blooming<String>('B');
        final sw = switched((via) => via(sel.bloom) ? branchB.bloom : branchA.bloom);

        int created = 0;
        int disposed = 0;
        final res = managed<String>(
          create: (_) {
            created++;
            return 'ManagedResource';
          },
          dispose: (_) => disposed++,
        );

        var runs = 0;
        final runner = (comp, sw, res).effect(() {
          runs++;
        }).start();

        expect(created, 1);
        expect(runs, 0);

        // 1. Mutate computed source
        numCtrl.data = 2;
        await Future<void>.delayed(Duration.zero);
        expect(runs, 1);

        // 2. Mutate switched branch
        branchA.data = 'A_mutated';
        await Future<void>.delayed(Duration.zero);
        expect(runs, 2);

        // 3. Switch branch
        sel.data = true;
        await Future<void>.delayed(Duration.zero);
        expect(runs, 3);

        runner.stop();
        expect(disposed, 1);
      });
    });

    // =========================================================================
    // 5. Rate-Limited Temporal Terminals (Debounce & Throttle) with Dynamic Triad
    // =========================================================================
    group('5. Rate-Limited Temporal Terminals with Dynamic Triad', () {
      test('5.1 switched.effect.debounce primes and collapses rapid mutations', () async {
        final selector = blooming<int>(1);
        final f1 = blooming<String>('Feed 1');
        final f2 = blooming<String>('Feed 2');

        final feed = switched((via) => via(selector.bloom) == 1 ? f1.bloom : f2.bloom);

        final captured = <String>[];
        final runner = feed.effect.debounce(const Duration(milliseconds: 30), () {
          captured.add(untracked(feed));
        }).start();

        expect(captured, isEmpty);

        // Rapid mutations
        f1.data = 'Feed 1.1';
        f1.data = 'Feed 1.2';
        f1.data = 'Feed 1.3';

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(captured, isEmpty);

        await Future<void>.delayed(const Duration(milliseconds: 35));
        expect(captured, ['Feed 1.3']);

        runner.stop();
      });

      test('5.2 managed.effect.throttle primes, throttles, and maintains lifecycle', () async {
        final interval = blooming<int>(10);
        int created = 0;
        int disposed = 0;

        final timerResource = managed<String>(
          create: (via) {
            created++;
            return 'Timer(${via(interval.bloom)}ms)';
          },
          dispose: (_) => disposed++,
        );

        final captured = <String>[];
        final runner = timerResource.effect.throttle(const Duration(milliseconds: 50), () {
          captured.add(untracked(timerResource));
        }).start();

        expect(created, 1);
        expect(captured, isEmpty);

        // First mutation fires on leading edge
        interval.data = 20;
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Timer(20ms)']);

        // Rapid mutations during throttle window
        interval.data = 30;
        interval.data = 40;
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Timer(20ms)']); // Still in throttle window

        // Wait past throttle duration (trailing edge fires)
        await Future<void>.delayed(const Duration(milliseconds: 60));
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Timer(20ms)', 'Timer(40ms)']);

        runner.stop();
        expect(disposed, 3);
      });
    });

    // =========================================================================
    // 6. Early Teardown & Cascading Cleanup via `take: N` with Dynamic Triad
    // =========================================================================
    group('6. Early Teardown & Cascading Cleanup via `take: N` with Dynamic Triad', () {
      test('6.1 managed -> computed -> switched -> effect(take: 2) cascades teardown on completion', () async {
        final selector = blooming<bool>(true);
        final port = blooming<int>(8080);
        int managedCreated = 0;
        int managedDisposed = 0;

        final server = managed<String>(
          create: (via) {
            managedCreated++;
            return 'Server(:${via(port.bloom)})';
          },
          update: (via, current) {
            return 'Server(:${via(port.bloom)})';
          },
          dispose: (_) => managedDisposed++,
        );

        final serverInfo = computed((via) => 'Info: ${via(server)}');
        final fallback = blooming<String>('Fallback');

        final activeSource = switched<String>(
          (via) => via(selector.bloom) ? serverInfo : fallback.bloom,
        );

        final captured = <String>[];
        final runner = activeSource
            .effect(
              () => captured.add(untracked(activeSource)),
              take: 2,
            )
            .start();

        expect(runner.isActive, isTrue);
        expect(managedCreated, 1);
        expect(managedDisposed, 0);
        expect(captured, isEmpty);

        // Turn 1 (take ticket 1 consumed)
        port.data = 8081;
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Info: Server(:8081)']);
        expect(runner.isActive, isTrue);
        expect(managedDisposed, 1); // 1 old instance disposed on update

        // Turn 2 (take ticket 2 consumed -> automatic deactivation)
        port.data = 8082;
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['Info: Server(:8081)', 'Info: Server(:8082)']);
        expect(runner.isActive, isFalse, reason: 'Runner must automatically deactivate after take tickets exhausted');
        expect(
          managedDisposed,
          3,
          reason:
              'Teardown of runner must cascade and dispose active managed resource (old disposed on update + active disposed on teardown)',
        );

        // Turn 3 (Mutations must be ignored, managed must remain dormant/disposed)
        port.data = 8083;
        await Future<void>.delayed(Duration.zero);
        expect(captured.length, 2);
        expect(managedCreated, 1, reason: 'No new resource created while dormant');
      });
    });

    // =========================================================================
    // 7. Inactive Dormancy & Full Lifecycle Roundtrip (autoStart, deactivate, reactivate)
    // =========================================================================
    group('7. Inactive Dormancy & Full Lifecycle Roundtrip', () {
      test('7.1 dormant runner -> start -> mutate -> stop -> dormant mutation -> reactivate', () async {
        final factor = blooming<int>(2);
        int managedCreated = 0;
        int managedDisposed = 0;

        final calcResource = managed<int>(
          create: (via) {
            managedCreated++;
            return via(factor.bloom) * 10;
          },
          dispose: (_) => managedDisposed++,
        );

        final derived = computed((via) => 'Value: ${via(calcResource)}');
        final runnerCaptures = <String>[];

        final runner = derived.effect(() {
          runnerCaptures.add(untracked(derived));
        }).runner;

        expect(runner.isActive, isFalse);
        expect(managedCreated, 0, reason: 'dormant runner must maintain zero-leak inactive dormancy');

        // 1. Activate
        runner.start();
        expect(runner.isActive, isTrue);
        expect(managedCreated, 1, reason: 'Activation primes the pipeline');
        expect(runnerCaptures, isEmpty, reason: 'Initial skip');

        // 2. Mutate active (re-creates resource because update is not defined)
        factor.data = 3;
        await Future<void>.delayed(Duration.zero);
        expect(runnerCaptures, ['Value: 30']);
        expect(managedCreated, 2);
        expect(managedDisposed, 1);

        // 3. Deactivate
        runner.stop();
        expect(runner.isActive, isFalse);
        expect(managedDisposed, 2); // 1 on update + 1 on deactivation

        // 4. Mutate while dormant
        factor.data = 5;
        await Future<void>.delayed(Duration.zero);
        expect(runnerCaptures, ['Value: 30'], reason: 'Dormant runner ignores mutations');
        expect(managedCreated, 2, reason: 'No resource creation during dormancy');

        // 5. Reactivate
        runner.start();
        expect(runner.isActive, isTrue);
        expect(managedCreated, 3, reason: 'Reactivation re-primes with latest state');
        expect(runnerCaptures, ['Value: 30'],
            reason: 'Reactivation primes latest version without re-firing effect action');

        // 6. Mutate while reactivated
        factor.data = 7;
        await Future<void>.delayed(Duration.zero);
        expect(runnerCaptures, ['Value: 30', 'Value: 70']);
        expect(managedCreated, 4);

        runner.stop();
        expect(managedDisposed, 4); // 2 previous + 1 on update + 1 on final deactivation
      });
    });

    // =========================================================================
    // 8. Conditional Guards & Dynamic Triad Integration
    // =========================================================================
    group('8. Conditional Guards & Dynamic Triad Integration', () {
      test('8.1 guard preserves take tickets and filters execution across switched branches', () async {
        final selector = blooming<bool>(true);
        final numA = blooming<int>(10);
        final numB = blooming<int>(20);

        final branch = switched((via) => via(selector.bloom) ? numA.bloom : numB.bloom);
        final calc = computed((via) => via(branch));

        bool allowRuns = false;
        final captured = <int>[];

        final runner = calc
            .effect(
              () => captured.add(untracked(calc)),
              guard: () => allowRuns,
              take: 2,
            )
            .start();

        // 1. Mutate while guard == false
        numA.data = 11;
        await Future<void>.delayed(Duration.zero);
        expect(captured, isEmpty);
        expect(runner.isActive, isTrue);

        // 2. Enable guard & mutate
        allowRuns = true;
        numA.data = 12;
        await Future<void>.delayed(Duration.zero);
        expect(captured, [12]);
        expect(runner.isActive, isTrue);

        // 3. Switch branch while guard == false
        allowRuns = false;
        selector.data = false; // switches to numB (20)
        await Future<void>.delayed(Duration.zero);
        expect(captured, [12]); // blocked by guard

        // 4. Mutate numB while guard == true (should consume final take ticket)
        allowRuns = true;
        numB.data = 25;
        await Future<void>.delayed(Duration.zero);
        expect(captured, [12, 25]);
        expect(runner.isActive, isFalse, reason: 'take limit reached');

        // 5. Subsequent mutations ignored
        numB.data = 30;
        await Future<void>.delayed(Duration.zero);
        expect(captured, [12, 25]);
      });
    });

    // =========================================================================
    // 9. Diamond DAG Topology & Glitch-Free Invariants
    // =========================================================================
    group('9. Diamond DAG Topology & Glitch-Free Invariants', () {
      test('9.1 Diamond DAG: 1 upstream change triggers exactly 1 glitch-free effect execution', () async {
        final source = blooming<int>(1);

        // Left & Right branches
        final left = computed((via) => via(source.bloom) * 10);
        final right = computed((via) => via(source.bloom) + 100);

        // Join node
        final join = computed((via) => '${via(left)}:${via(right)}');

        final captured = <String>[];
        final runner = join.effect(() {
          captured.add(untracked(join));
        }).start();

        expect(captured, isEmpty);

        // Single mutation to root of diamond
        source.data = 2;
        await Future<void>.delayed(Duration.zero);

        // Must execute exactly once with fully synchronized values (left=20, right=102)
        expect(captured, ['20:102']);

        source.data = 5;
        await Future<void>.delayed(Duration.zero);
        expect(captured, ['20:102', '50:105']);

        runner.stop();
      });

      test('9.2 Diamond Topology with Switched & Managed: clean resource switching without glitches', () async {
        final selector = blooming<bool>(true);
        int managedLeftCreated = 0;
        int managedLeftDisposed = 0;
        int managedRightCreated = 0;
        int managedRightDisposed = 0;

        final left = managed<String>(
          create: (_) {
            managedLeftCreated++;
            return 'LeftResource';
          },
          dispose: (_) => managedLeftDisposed++,
        );

        final right = managed<String>(
          create: (_) {
            managedRightCreated++;
            return 'RightResource';
          },
          dispose: (_) => managedRightDisposed++,
        );

        final activeResource = switched<String>(
          (via) => via(selector.bloom) ? left : right,
        );

        final status = computed((via) => 'Active is [${via(activeResource)}]');

        final captured = <String>[];
        final runner = status.effect(() {
          captured.add(untracked(status));
        }).start();

        expect(managedLeftCreated, 1);
        expect(managedRightCreated, 0, reason: 'Inactive right branch must remain dormant');
        expect(captured, isEmpty);

        // Switch to Right
        selector.data = false;
        await Future<void>.delayed(Duration.zero);

        expect(captured, ['Active is [RightResource]']);
        expect(managedLeftDisposed, 1, reason: 'Swept left branch must be disposed');
        expect(managedRightCreated, 1, reason: 'Activated right branch must be created');

        runner.stop();
        expect(managedRightDisposed, 1, reason: 'Right resource disposed on runner teardown');
      });
    });

    // =========================================================================
    // 10. Handled Effect (onCleanup) & Managed (dispose) Dual Coordination
    // =========================================================================
    group('10. Handled Effect (onCleanup) & Managed (dispose) Dual Coordination', () {
      test('10.1 onCleanup runs before subsequent turn, and both onCleanup and dispose finish on teardown', () async {
        final config = blooming<String>('ConfigA');
        final log = <String>[];

        final resource = managed<String>(
          create: (via) {
            final val = via(config.bloom);
            log.add('managed:create:$val');
            return 'Resource($val)';
          },
          update: (via, current) {
            final val = via(config.bloom);
            log.add('managed:update:$val');
            return 'Resource($val)';
          },
          dispose: (res) {
            log.add('managed:dispose:$res');
          },
        );

        final pipeline = computed((via) => 'Wrapped(${via(resource)})');

        final runner = pipeline.effect.scoped((scope) {
          final current = untracked(pipeline);
          log.add('effect:run:$current');

          scope.onCleanup(() {
            log.add('effect:cleanup:$current');
          });
        }).start();

        expect(log, ['managed:create:ConfigA']);

        // First mutation
        config.data = 'ConfigB';
        await Future<void>.delayed(Duration.zero);

        expect(log, contains('managed:update:ConfigB'));
        expect(log, contains('managed:dispose:Resource(ConfigA)'));
        expect(log, contains('effect:run:Wrapped(Resource(ConfigB))'));

        // Second mutation
        config.data = 'ConfigC';
        await Future<void>.delayed(Duration.zero);

        final idxCleanupB = log.indexOf('effect:cleanup:Wrapped(Resource(ConfigB))');
        final idxRunC = log.indexOf('effect:run:Wrapped(Resource(ConfigC))');
        expect(idxCleanupB, isNonNegative);
        expect(idxRunC, isNonNegative);
        expect(idxCleanupB < idxRunC, isTrue, reason: 'onCleanup must execute before subsequent effect action');

        // Deactivate runner
        runner.stop();

        expect(log, contains('effect:cleanup:Wrapped(Resource(ConfigC))'));
        expect(log, contains('managed:dispose:Resource(ConfigC)'));
      });
    });
  });
}

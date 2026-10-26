// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.
import 'package:blooming/blooming.dart';
import 'package:test/test.dart';

// Test domain computation classes
final class _FullPricingComputation extends Computation<int> {
  _FullPricingComputation(this.basePrice, this.discount, this.tax);

  final Bloom<int> basePrice;
  final Bloom<int> discount;
  final Bloom<int> tax;

  int computeCallCount = 0;

  @override
  int compute(BloomVia via) {
    computeCallCount++;
    return _applyTax(_applyDiscount(via(basePrice), via(discount)), via(tax));
  }

  int _applyDiscount(int base, int disc) => base - disc;
  int _applyTax(int discounted, int t) => discounted + t;
}

final class _ConditionalBranchComputation extends Computation<String> {
  _ConditionalBranchComputation(this.usePrefix, this.prefix, this.value, this.fallback);

  final Bloom<bool> usePrefix;
  final Bloom<String> prefix;
  final Bloom<String> value;
  final Bloom<String> fallback;

  int computeCallCount = 0;

  @override
  String compute(BloomVia via) {
    computeCallCount++;
    if (via(usePrefix)) {
      return '${via(prefix)}: ${via(value)}';
    } else {
      return via(fallback);
    }
  }
}

final class _OverriddenGuardedComputation extends Computation<String> {
  _OverriddenGuardedComputation(this.auth, this.payload);

  final Bloom<bool> auth;
  final Bloom<String> payload;

  @override
  BloomGuard guard(BloomVia via) => via(auth).guarded('AuthRequired');

  @override
  String compute(BloomVia via) => 'Payload: ${via(payload)}';
}

final class _ConstructorGuardedComputation extends Computation<String> {
  _ConstructorGuardedComputation(Bloom<bool> ready, this.content)
      : super(
          guard: (via) => via(ready).guarded('AwaitingReady'),
        );

  final Bloom<String> content;

  @override
  String compute(BloomVia via) => via(content);
}

final class _LifecycleTrackedComputation extends Computation<int> with BloomLifecycleAware {
  _LifecycleTrackedComputation(this.source);

  final Bloom<int> source;
  int activateCount = 0;
  int deactivateCount = 0;

  @override
  void didActivate() {
    super.didActivate();
    activateCount++;
  }

  @override
  void didDeactivate() {
    super.didDeactivate();
    deactivateCount++;
  }

  @override
  int compute(BloomVia via) => via(source) * 2;
}

final class _FailingComputation extends Computation<int> {
  _FailingComputation(this.source, {this.failInGuard = false});

  final Bloom<int> source;
  final bool failInGuard;

  @override
  BloomGuard guard(BloomVia via) {
    if (failInGuard && via(source) < 0) {
      throw RangeError('Negative values rejected in guard');
    }
    return BloomGuard.pass;
  }

  @override
  int compute(BloomVia via) {
    if (!failInGuard && via(source) < 0) {
      throw FormatException('Negative values rejected in compute');
    }
    return via(source);
  }
}

void main() {
  group('Computation<T> Component Suite', () {
    // =========================================================================
    // 1. Auto-Dependency Tracking & Encapsulation
    // =========================================================================
    group('1. Auto-Dependency Tracking & Encapsulation', () {
      test('1.1 Computes multi-inbound derivation with helper methods without manual manifest', () {
        final base = blooming(100);
        final discount = blooming(20);
        final tax = blooming(8);

        final comp = _FullPricingComputation(base.bloom, discount.bloom, tax.bloom);

        expect(comp.computeCallCount, 0);
        expect(comp.hasData, isTrue);
        expect(comp.data, 88); // (100 - 20) + 8 = 88
        expect(comp.computeCallCount, 1);

        // Mutating base invalidates lazily
        base.data = 200;
        expect(comp.computeCallCount, 1); // Not computed yet (lazy pull)
        expect(comp.data, 188); // (200 - 20) + 8 = 188
        expect(comp.computeCallCount, 2);

        // Mutating discount
        discount.data = 50;
        expect(comp.data, 158);
        expect(comp.computeCallCount, 3);

        // Mutating tax
        tax.data = 15;
        expect(comp.data, 165);
        expect(comp.computeCallCount, 4);
      });

      test('1.2 Dynamic conditional branching prunes inactive edges', () {
        final usePrefix = blooming(true);
        final prefix = blooming('TAG');
        final value = blooming('Item1');
        final fallback = blooming('DEFAULT');

        final comp = _ConditionalBranchComputation(usePrefix.bloom, prefix.bloom, value.bloom, fallback.bloom);

        int notifyCount = 0;
        final terminal = RawBloomTerminal(comp.bloom, onInvalidated: () => notifyCount++);
        terminal.activate();

        expect(comp.data, 'TAG: Item1');
        expect(comp.computeCallCount, 1);

        // Mutating inactive fallback does NOT cause recalculation
        fallback.data = 'NEW_DEFAULT';
        expect(comp.computeCallCount, 1);
        expect(comp.data, 'TAG: Item1');

        // Mutating active prefix triggers recalculation
        prefix.data = 'CATEGORY';
        expect(comp.data, 'CATEGORY: Item1');
        expect(comp.computeCallCount, 2);

        // Flip condition to false: dynamically switches to fallback branch!
        usePrefix.data = false;
        expect(comp.data, 'NEW_DEFAULT');
        expect(comp.computeCallCount, 3);

        // Now mutating prefix does NOT cause recalculation
        prefix.data = 'UNUSED';
        expect(comp.computeCallCount, 3);

        // Mutating active fallback causes recalculation
        fallback.data = 'UPDATED_DEFAULT';
        expect(comp.data, 'UPDATED_DEFAULT');
        expect(comp.computeCallCount, 4);

        terminal.deactivate();
      });
    });

    // =========================================================================
    // 2. Reactive Guards (Preconditions & Empty Reasons)
    // =========================================================================
    group('2. Reactive Guards (BloomGuard)', () {
      test('2.1 Constructor-based guard parameters gate computation', () {
        final ready = blooming(false);
        final content = blooming('Hello World');

        final comp = _ConstructorGuardedComputation(ready.bloom, content.bloom);

        expect(comp.isEmpty, isTrue);
        expect(comp.hasData, isFalse);
        expect(comp.emptyReason, 'AwaitingReady');

        // Mutating content while blocked keeps node empty
        content.data = 'New Content';
        expect(comp.isEmpty, isTrue);
        expect(comp.emptyReason, 'AwaitingReady');

        // Make ready
        ready.data = true;
        expect(comp.hasData, isTrue);
        expect(comp.data, 'New Content');
        expect(comp.emptyReason, isNull);

        // Un-ready again: transitions back to empty
        ready.data = false;
        expect(comp.isEmpty, isTrue);
        expect(comp.emptyReason, 'AwaitingReady');
      });

      test('2.2 Overridden method guard() returns BloomGuard', () {
        final auth = blooming(false);
        final payload = blooming('Secret Data');

        final comp = _OverriddenGuardedComputation(auth.bloom, payload.bloom);

        expect(comp.isEmpty, isTrue);
        expect(comp.emptyReason, 'AuthRequired');

        auth.data = true;
        expect(comp.hasData, isTrue);
        expect(comp.data, 'Payload: Secret Data');

        auth.data = false;
        expect(comp.isEmpty, isTrue);
        expect(comp.emptyReason, 'AuthRequired');
      });
    });

    // =========================================================================
    // 3. Lifecycle Integration (BloomLifecycleAware)
    // =========================================================================
    group('3. Lifecycle Integration (BloomLifecycleAware)', () {
      test('3.1 Coordinates didActivate and didDeactivate with terminal subscriptions', () {
        final num = blooming(10);
        final comp = _LifecycleTrackedComputation(num.bloom);

        expect(comp.isActive, isFalse);
        expect(comp.activateCount, 0);
        expect(comp.deactivateCount, 0);

        final terminal1 = RawBloomTerminal(comp.bloom, onInvalidated: () {});
        terminal1.activate();

        expect(comp.isActive, isTrue);
        expect(comp.activateCount, 1);
        expect(comp.deactivateCount, 0);

        final terminal2 = RawBloomTerminal(comp.bloom, onInvalidated: () {});
        terminal2.activate();

        // 2nd subscriber does not re-fire didActivate (already active)
        expect(comp.activateCount, 1);

        terminal1.deactivate();
        // Still 1 subscriber remaining
        expect(comp.isActive, isTrue);
        expect(comp.deactivateCount, 0);

        terminal2.deactivate();
        // All subscribers gone: didDeactivate fires!
        expect(comp.isActive, isFalse);
        expect(comp.deactivateCount, 1);
      });
    });

    // =========================================================================
    // 4. Direct Convenience Getters & Operators
    // =========================================================================
    group('4. Direct Convenience Getters & Snapshot Symmetry', () {
      test('4.1 Convenience getters delegate directly to underlying bloom', () {
        final source = blooming('Active');
        final comp = _FullPricingComputation(blooming(10).bloom, blooming(2).bloom, blooming(1).bloom);

        expect(comp.data, 9);
        expect(comp.dataOrNull, 9);
        expect(comp.dataOrElse(() => 99), 9);
        expect(comp.hasData, isTrue);
        expect(comp.isEmpty, isFalse);
        expect(comp.emptyReason, isNull);
        expect(comp.hasError, isFalse);
        expect(comp.snapshot.data, 9);

        // Empty state getters
        final emptyComp = _ConstructorGuardedComputation(blooming(false).bloom, source.bloom);
        expect(emptyComp.isEmpty, isTrue);
        expect(emptyComp.hasData, isFalse);
        expect(emptyComp.emptyReason, 'AwaitingReady');
        expect(emptyComp.dataOrNull, isNull);
        expect(emptyComp.dataOrElse(() => 'Fallback'), 'Fallback');
        expect(() => emptyComp.data, throwsA(isA<BloomSnapshotExtractionException>()));
      });
    });

    // =========================================================================
    // 5. Error Containment & Fault Isolation
    // =========================================================================
    group('5. Error Containment & Fault Isolation', () {
      test('5.1 Exception in compute() transitions computation into hasError state', () {
        final source = blooming(10);
        final comp = _FailingComputation(source.bloom, failInGuard: false);

        expect(comp.hasData, isTrue);
        expect(comp.data, 10);

        source.data = -5;
        expect(comp.hasError, isTrue);
        expect(comp.hasData, isFalse);
        expect(comp.error, isA<FormatException>());
        expect(comp.stackTrace, isNotNull);
        expect(() => comp.data, throwsA(isA<BloomSnapshotExtractionException>()));

        // Recover by fixing source
        source.data = 20;
        expect(comp.hasData, isTrue);
        expect(comp.data, 20);
      });

      test('5.2 Exception in guard() transitions computation into hasError state', () {
        final source = blooming(10);
        final comp = _FailingComputation(source.bloom, failInGuard: true);

        expect(comp.hasData, isTrue);
        expect(comp.data, 10);

        source.data = -1;
        expect(comp.hasError, isTrue);
        expect(comp.error, isA<RangeError>());

        // Recover
        source.data = 5;
        expect(comp.hasData, isTrue);
        expect(comp.data, 5);
      });
    });
  });
}

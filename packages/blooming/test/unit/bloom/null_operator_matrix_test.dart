// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

void main() {
  group('Bloom Sound Null-Safety, 3-State Exclusivity & Safe Extraction Matrix', () {
    group('1. Sound Null Safety (Valid Null vs Empty vs Error)', () {
      test('1.1 Valid Bloom holding explicit null is not empty and not in error', () {
        final nullableBloom = blooming<String?>(null);

        expect(nullableBloom.hasData, isTrue);
        expect(nullableBloom.isEmpty, isFalse);
        expect(nullableBloom.hasError, isFalse);
        expect(nullableBloom.data, isNull);
        expect(nullableBloom.dataOrNull, isNull);
        expect(nullableBloom.dataOrElse(() => 'fallback'), isNull);
        expect(nullableBloom.snapshot.hasData, isTrue);
      });

      test('1.2 Bloom.late is strictly empty and fails fast on .data access', () {
        final lateBloom = blooming.late<String?>();

        expect(lateBloom.hasData, isFalse);
        expect(lateBloom.isEmpty, isTrue);
        expect(lateBloom.hasError, isFalse);
        expect(lateBloom.snapshot.isEmpty, isTrue);

        // Fail-fast on .data
        expect(
          () => lateBloom.data,
          throwsA(isA<BloomSnapshotExtractionException>()),
        );

        // Safe accessors
        expect(lateBloom.dataOrNull, isNull);
        expect(lateBloom.dataOrElse(() => 'safe-default'), 'safe-default');

        // Populate late bloom
        lateBloom.data = null;
        expect(lateBloom.hasData, isTrue);
        expect(lateBloom.isEmpty, isFalse);
        expect(lateBloom.data, isNull);
      });

      test('1.3 Bloom.error is strictly error and fails fast on .data access', () {
        final errorBloom = Bloom<int>.error(
          FormatException('Invalid payload format'),
        );

        expect(untracked.state(errorBloom).hasData, isFalse);
        expect(untracked.state(errorBloom).isEmpty, isFalse);
        expect(untracked.state(errorBloom).hasError, isTrue);
        expect(untracked.state(errorBloom).snapshot.hasError, isTrue);

        // Fail-fast on .data
        expect(
          () => untracked(errorBloom),
          throwsA(isA<BloomSnapshotExtractionException>()),
        );

        // Safe accessors
        expect(untracked.state(errorBloom).dataOrNull, isNull);
        expect(untracked.state(errorBloom).dataOrElse(() => 999), 999);
      });
    });

    group('2. Nullable Combinators & Transformations on Bloom', () {
      test('2.1 computed with nullable data flows', () {
        final source = blooming<String?>('apple');

        final uppercaseBloom = computed((via) => via(source.bloom)?.toUpperCase());
        final lengthBloom = computed((via) => via(source.bloom)?.length ?? 0);

        expect(untracked(uppercaseBloom), 'APPLE');
        expect(untracked(lengthBloom), 5);

        // Mutate to null
        source.data = null;
        expect(untracked(uppercaseBloom), isNull);
        expect(untracked(lengthBloom), 0);

        // Mutate back to non-null
        source.data = 'banana';
        expect(untracked(uppercaseBloom), 'BANANA');
        expect(untracked(lengthBloom), 6);
      });

      test('2.2 fallback recovery on nullable Bloom', () {
        final lateBloom = blooming.late<String?>();

        final fallbackToNull =
            computed<String?>((via) => via.state(lateBloom.bloom).hasData ? via(lateBloom.bloom) : null);
        expect(untracked.state(fallbackToNull).hasData, isTrue);
        expect(untracked(fallbackToNull), isNull);

        final safeFallback = computed((via) => via.state(lateBloom.bloom).dataOrElse(() => 'default-val'));
        expect(untracked(safeFallback), 'default-val');

        // Populate with null
        lateBloom.data = null;
        expect(untracked(fallbackToNull), isNull);
        expect(untracked(safeFallback), isNull); // valid payload is preserved
      });

      test('2.3 guard conditionally gates computed', () {
        final count = blooming<int>(10);
        final canProceed = blooming(true);

        final guarded = computed(
          (via) => via(count.bloom),
          guard: (via) => via(canProceed.bloom).guarded('Blocked by security guard'),
        );

        expect(untracked.state(guarded).hasData, isTrue);
        expect(untracked(guarded), 10);

        // Block
        canProceed.data = false;
        count.data = 20;

        expect(untracked.state(guarded).isEmpty, isTrue);
        expect(untracked.state(guarded).hasData, isFalse);
        expect(untracked.state(guarded).snapshot.emptyReason, 'Blocked by security guard');
        expect(
          () => untracked(guarded),
          throwsA(isA<BloomSnapshotExtractionException>()),
        );

        // Restore
        canProceed.data = true;
        count.data = 30;
        expect(untracked.state(guarded).hasData, isTrue);
        expect(untracked(guarded), 30);
      });
    });
  });
}

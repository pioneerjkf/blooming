// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

void main() {
  group('Bloom.constantNull Singleton Tests', () {
    test('holds valid null data permanently in Data state', () {
      final node = Bloom.constantNull;

      expect(untracked(node), isNull);
      expect(untracked.state(node).hasData, isTrue);
      expect(untracked.state(node).isEmpty, isFalse);
      expect(untracked.state(node).hasError, isFalse);
    });

    test('is a canonical singleton instance', () {
      expect(identical(Bloom.constantNull, Bloom.constantNull), isTrue);
    });

    test('is assignable to any Bloom<T?> without type casting', () {
      Bloom<int?> nullableInt = Bloom.constantNull;
      Bloom<String?> nullableString = Bloom.constantNull;
      Bloom<Object?> nullableObject = Bloom.constantNull;

      expect(untracked(nullableInt), isNull);
      expect(untracked(nullableString), isNull);
      expect(untracked(nullableObject), isNull);
      expect(identical(nullableInt, nullableString), isTrue);
    });

    test('works seamlessly inside computed derivations without edge churn', () {
      final derived = computed((via) {
        final val = via(Bloom.constantNull);
        return val ?? 'default_fallback';
      });

      expect(untracked(derived), equals('default_fallback'));
    });
  });
}

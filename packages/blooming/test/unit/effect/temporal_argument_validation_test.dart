// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';
import 'package:test/test.dart';

void main() {
  group('Temporal Configuration Argument Validation Tests', () {
    group('Debounce Effect leading/trailing validation', () {
      test('Effect.debounce.unary throws ArgumentError when leading: false and trailing: false', () {
        final source = blooming<int>(0);
        expect(
          () => Effect.debounce.unary(
            source.bloom,
            const Duration(milliseconds: 50),
            () {},
            leading: false,
            trailing: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('Effect.debounce (n-ary) throws ArgumentError when leading: false and trailing: false', () {
        final source = blooming<int>(0);
        expect(
          () => Effect.debounce(
            [source.bloom],
            const Duration(milliseconds: 50),
            () {},
            leading: false,
            trailing: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('source.bloom.effect.debounce throws ArgumentError when leading: false and trailing: false', () {
        final source = blooming<int>(0);
        expect(
          () => source.bloom.effect.debounce(
            const Duration(milliseconds: 50),
            () {},
            leading: false,
            trailing: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Throttle Effect leading/trailing validation', () {
      test('Effect.throttle.unary throws ArgumentError when leading: false and trailing: false', () {
        final source = blooming<int>(0);
        expect(
          () => Effect.throttle.unary(
            source.bloom,
            const Duration(milliseconds: 50),
            () {},
            leading: false,
            trailing: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('Effect.throttle (n-ary) throws ArgumentError when leading: false and trailing: false', () {
        final source = blooming<int>(0);
        expect(
          () => Effect.throttle(
            [source.bloom],
            const Duration(milliseconds: 50),
            () {},
            leading: false,
            trailing: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('source.bloom.effect.throttle throws ArgumentError when leading: false and trailing: false', () {
        final source = blooming<int>(0);
        expect(
          () => source.bloom.effect.throttle(
            const Duration(milliseconds: 50),
            () {},
            leading: false,
            trailing: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Bloom Temporal Operator leading/trailing validation', () {
      test('source.bloom.debounced throws ArgumentError when leading: false and trailing: false', () {
        final source = blooming<int>(0);
        expect(
          () => source.bloom.debounced(
            const Duration(milliseconds: 50),
            leading: false,
            trailing: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('source.bloom.throttled throws ArgumentError when leading: false and trailing: false', () {
        final source = blooming<int>(0);
        expect(
          () => source.bloom.throttled(
            const Duration(milliseconds: 50),
            leading: false,
            trailing: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}

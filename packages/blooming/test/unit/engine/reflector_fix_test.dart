// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';
import 'package:blooming/reflector.dart';
import 'package:test/test.dart';

void main() {
  group('Reflector Diagnostic Observer Effect and Effect Dependencies Tests', () {
    test('1. Effect exposes upstream sources through reflector', () {
      final a = blooming(1)..withDebugLabel('NodeA');
      final b = blooming(2)..withDebugLabel('NodeB');

      final unaryEffect = Effect.unary(a.bloom, () {})..withDebugLabel('UnaryEffect');
      final naryEffect = Effect([a.bloom, b.bloom], () {})..withDebugLabel('NaryEffect');

      final unaryReflector = unaryEffect.debugReflector;
      expect(unaryReflector, isNotNull);
      expect(unaryReflector!.kind, 'sink');
      expect(unaryReflector.sourceCount, 1);
      final unarySources = unaryReflector.sources.map((s) => s.debugLabel).toList();
      expect(unarySources, contains('NodeA'), reason: 'Unary Effect reflector must expose its source');

      final naryReflector = naryEffect.debugReflector;
      expect(naryReflector, isNotNull);
      expect(naryReflector!.kind, 'sink');
      expect(naryReflector.sourceCount, 2);
      final narySources = naryReflector.sources.map((s) => s.debugLabel).toList();
      expect(narySources, containsAll(['NodeA', 'NodeB']), reason: 'N-ary Effect reflector must expose all sources');
    });

    test('2. Inspecting BloomReflector on un-evaluated computed does not trigger computation', () {
      final counter = blooming(10);
      var computeCount = 0;
      final derived = computed((via) {
        computeCount++;
        return via(counter.bloom) * 2;
      })
        ..withDebugLabel('LazyDerived');

      final reflector = derived.debugReflector as BloomReflector;

      // Accessing reflector properties on uncomputed node must NOT trigger computation:
      expect(reflector.hasData, isFalse);
      expect(reflector.data, isNull);
      expect(reflector.isEmpty, isTrue);
      expect(reflector.emptyReason, 'pending');

      final json = reflector.toJson();
      expect(json['hasData'], isFalse);
      expect(json['data'], isNull);

      expect(computeCount, 0, reason: 'Reflector inspection must never trigger lazy computation');
      expect(reflector.version, 0, reason: 'Version must remain 0 before first evaluation');
    });

    test('3. Inspecting BloomReflector on dirty computed node does not trigger recomputation', () {
      final counter = blooming(10);
      var computeCount = 0;
      final derived = computed((via) {
        computeCount++;
        return via(counter.bloom) * 2;
      })
        ..withDebugLabel('Derived');

      final terminal = RawBloomTerminal(derived, onInvalidated: () {})..activate();
      expect(untracked(derived), 20);
      expect(computeCount, 1);

      // Mutate upstream: marks derived dirty, but derived is NOT yet pulled
      counter.data = 20;

      final reflector = derived.debugReflector as BloomReflector;

      // Inspecting reflector should NOT force recomputation:
      final json = reflector.toJson();
      expect(json['hasData'], isTrue);
      expect(computeCount, 1, reason: 'Inspection must not trigger recomputation on dirty node');

      terminal.deactivate();
    });
  });
}

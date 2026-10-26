// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:test/test.dart';
import '../../test_utils.dart';

void main() {
  group('Bloom State & Node switch (phase) Pattern Matching Tests', () {
    test('1. Valid, Late, Error BloomController branching with switch (phase)', () {
      final validBloom = blooming('Lotus');
      final lateBloom = blooming.late<String>();
      final errorBloom = Bloom<String>.error('error payload');

      final validLabel = switch (validBloom.phase) {
        BloomPhase.valid => 'Data: ${validBloom.data}',
        BloomPhase.empty => 'Empty',
        BloomPhase.error => 'Error: ${validBloom.error}',
      };
      expect(validLabel, 'Data: Lotus');

      final lateLabel = switch (lateBloom.phase) {
        BloomPhase.valid => 'Data: ${lateBloom.data}',
        BloomPhase.empty => 'Empty',
        BloomPhase.error => 'Error: ${lateBloom.error}',
      };
      expect(lateLabel, 'Empty');

      final errorState = untracked.state(errorBloom);
      final errorLabel = switch (errorState.phase) {
        BloomPhase.valid => 'Data: ${errorState.data}',
        BloomPhase.empty => 'Empty',
        BloomPhase.error => 'Error: ${errorState.error}',
      };
      expect(errorLabel, 'Error: error payload');
    });

    test('2. Fallback branching with hasData ternary', () {
      final validBloom = blooming('Lotus');
      final lateBloom = blooming.late<String>();

      final validResult = validBloom.hasData ? 'Value: ${validBloom.data}' : 'Fallback';
      expect(validResult, 'Value: Lotus');

      final lateResult = lateBloom.hasData ? 'Value: ${lateBloom.data}' : 'Fallback';
      expect(lateResult, 'Fallback');
    });

    test('3. Conditional null-coalescing extraction with hasData / hasError / dataOrNull', () {
      final validBloom = blooming('Lotus');
      final lateBloom = blooming.late<String>();
      final errorBloom = Bloom<String>.error('error payload');

      // Idiomatic ternary extraction via hasData / hasError
      final validLen = validBloom.hasData ? validBloom.data.length : null;
      expect(validLen, 5);

      final lateLen = lateBloom.hasData ? lateBloom.data.length : null;
      expect(lateLen, isNull);

      final errorState = untracked.state(errorBloom);
      final errVal = errorState.hasError ? errorState.error : null;
      expect(errVal, 'error payload');

      // Direct optional null-safe access via dataOrNull
      expect(validBloom.dataOrNull?.length, 5);
      expect(lateBloom.dataOrNull?.length, isNull);
    });

    test('4. Auto-tracking inside computed() when branching on switch (via.state.phase)', () {
      final count = blooming(10);

      final statusMessage = computed((via) {
        final state = via.state(count.bloom);
        return switch (state.phase) {
          BloomPhase.valid => 'Count is ${state.data}',
          BloomPhase.empty => 'No count',
          BloomPhase.error => 'Count error',
        };
      });

      expect(untracked(statusMessage), 'Count is 10');

      count.data = 20;
      expect(untracked(statusMessage), 'Count is 20');
    });

    test('5. Auto-tracking inside effect() when reading via.state with hasData ternary', () async {
      final text = blooming('Initial');
      final logs = <String>[];

      final dispose = effect((BloomVia via) {
        final state = via.state(text.bloom);
        logs.add(state.hasData ? 'Logged: ${state.data}' : 'Logged: None');
      });

      // Initial execution happened synchronously or microtask
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(logs, contains('Logged: Initial'));

      text.data = 'Updated';
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(logs, contains('Logged: Updated'));

      dispose();
    });

    test('6. Bloom list untracked.state branching with switch (phase)', () {
      final r1 = blooming(10);
      final r2 = blooming(20);
      final group = Bloom.constant([r1.bloom, r2.bloom]);

      final state = untracked.state(group);
      final result = switch (state.phase) {
        BloomPhase.valid => state.data.length,
        BloomPhase.empty => 0,
        BloomPhase.error => -1,
      };
      expect(result, 2);
    });
  });
}

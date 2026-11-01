// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:blooming_lints/blooming_lints.dart';
import 'package:test/test.dart';

void main() {
  group('AvoidAsyncInComputed AST detection', () {
    test('detects async closure passed to computed', () {
      final unit = parseString(content: '''
void setup() {
  final bad = computed((via) async {
    return 42;
  });
}
''').unit;

      MethodInvocation? computedCall;
      unit.visitChildren(_MethodInvocationVisitor(
          'computed', (node) => computedCall = node));

      expect(computedCall, isNotNull);
      expect(
          AvoidAsyncInComputed.isAsyncClosureInComputed(computedCall!), isTrue);
    });

    test('detects async* generator passed to computed', () {
      final unit = parseString(content: '''
void setup() {
  final bad = computed((via) async* {
    yield 42;
  });
}
''').unit;

      MethodInvocation? computedCall;
      unit.visitChildren(_MethodInvocationVisitor(
          'computed', (node) => computedCall = node));

      expect(computedCall, isNotNull);
      expect(
          AvoidAsyncInComputed.isAsyncClosureInComputed(computedCall!), isTrue);
    });

    test('detects closure when guard is placed before compute argument', () {
      final unit = parseString(content: '''
void setup() {
  final bad = computed(
    guard: (via) => BloomGuard.pass,
    (via) async => 42,
  );
}
''').unit;

      MethodInvocation? computedCall;
      unit.visitChildren(_MethodInvocationVisitor(
          'computed', (node) => computedCall = node));

      expect(computedCall, isNotNull);
      expect(
          AvoidAsyncInComputed.isAsyncClosureInComputed(computedCall!), isTrue);
    });

    test('permits synchronous closure in computed', () {
      final unit = parseString(content: '''
void setup() {
  final good = computed((via) => 42);
}
''').unit;

      MethodInvocation? computedCall;
      unit.visitChildren(_MethodInvocationVisitor(
          'computed', (node) => computedCall = node));

      expect(computedCall, isNotNull);
      expect(
          AvoidAsyncInComputed.isAsyncClosureInComputed(computedCall!), isFalse);
    });
  });
}

class _MethodInvocationVisitor extends RecursiveAstVisitor<void> {
  _MethodInvocationVisitor(this.methodName, this.onFound);
  final String methodName;
  final void Function(MethodInvocation) onFound;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == methodName) {
      onFound(node);
    }
    super.visitMethodInvocation(node);
  }
}


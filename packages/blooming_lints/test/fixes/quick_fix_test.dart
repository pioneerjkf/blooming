// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:test/test.dart';
import 'package:blooming_lints/blooming_lints.dart';

void main() {
  group('QuickFix Transformations', () {
    test('AvoidUntrackedBloomRead registers WrapWithViaFix', () {
      final rule = AvoidUntrackedBloomRead();
      final fixes = rule.getFixes();
      expect(fixes.length, equals(1));
      expect(fixes.first, isA<WrapWithViaFix>());
    });

    test('AvoidViaStateWhenValueSuffices registers ReplaceViaStateDataFix', () {
      final rule = AvoidViaStateWhenValueSuffices();
      final fixes = rule.getFixes();
      expect(fixes.length, equals(1));
      expect(fixes.first, isA<ReplaceViaStateDataFix>());
    });

    test('AvoidAsyncInComputed registers ConvertToComputedAsyncFix', () {
      final rule = AvoidAsyncInComputed();
      final fixes = rule.getFixes();
      expect(fixes.length, equals(1));
      expect(fixes.first, isA<ConvertToComputedAsyncFix>());
    });

    test('ConvertToComputedAsyncFix AST recognition for async closure', () {
      final unit = parseString(content: '''
void test() {
  final res = computed((via) async => 42);
}
''').unit;

      MethodInvocation? foundInvocation;
      unit.accept(_ComputedInvocationFinder((node) {
        foundInvocation = node;
      }));

      expect(foundInvocation, isNotNull);
      expect(foundInvocation!.methodName.name, equals('computed'));
      final computeArg = foundInvocation!.argumentList.arguments.first;
      expect(
        BloomTypeChecker.classifyAsyncComputation(computeArg),
        equals(AsyncComputationKind.future),
      );
    });

    test('ConvertToComputedAsyncFix AST recognition for async* generator', () {
      final unit = parseString(content: '''
void test() {
  final res = computed((via) async* {
    yield 42;
  });
}
''').unit;

      MethodInvocation? foundInvocation;
      unit.accept(_ComputedInvocationFinder((node) {
        foundInvocation = node;
      }));

      expect(foundInvocation, isNotNull);
      expect(foundInvocation!.methodName.name, equals('computed'));
      final computeArg = foundInvocation!.argumentList.arguments.first;
      expect(
        BloomTypeChecker.classifyAsyncComputation(computeArg),
        equals(AsyncComputationKind.stream),
      );
    });

    test('ReplaceViaStateDataFix AST recognition', () {
      final unit = parseString(content: '''
void test() {
  final res = computed((via) => via.state(price).data * 2);
}
''').unit;

      MethodInvocation? foundInvocation;
      unit.accept(_StateDataFinder((node) {
        foundInvocation = node;
      }));

      expect(foundInvocation, isNotNull);
      expect(foundInvocation!.methodName.name, equals('state'));
      expect(foundInvocation!.argumentList.arguments.first.toSource(),
          equals('price'));
    });
  });
}

class _StateDataFinder extends RecursiveAstVisitor<void> {
  final void Function(MethodInvocation) onFound;
  _StateDataFinder(this.onFound);

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'data') {
      final target = node.target;
      if (target is MethodInvocation &&
          AvoidViaStateWhenValueSuffices.isViaStateInvocation(target)) {
        onFound(target);
      }
    }
    super.visitPropertyAccess(node);
  }
}

class _ComputedInvocationFinder extends RecursiveAstVisitor<void> {
  final void Function(MethodInvocation) onFound;
  _ComputedInvocationFinder(this.onFound);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'computed') {
      onFound(node);
    }
    super.visitMethodInvocation(node);
  }
}

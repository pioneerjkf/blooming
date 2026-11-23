// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:test/test.dart';
import 'package:blooming_lints/blooming_lints.dart';

void main() {
  group('AvoidUnnecessaryViaScope AST detection', () {
    test('detects unused via parameter in computed()', () {
      final unit = parseString(
        content: '''
void setup() {
  final constant = computed((via) {
    return 10 + 20;
  });
}
''',
      ).unit;

      FunctionExpression? closure;
      unit.visitChildren(_FunctionExpressionVisitor((node) => closure = node));

      expect(closure, isNotNull);
      expect(
        AvoidUnnecessaryViaScope.isUnnecessaryViaClosure(closure!),
        isTrue,
      );
    });

    test('permits active via usage in computed()', () {
      final unit = parseString(
        content: '''
void setup() {
  final sum = computed((via) {
    return via(a) + via(b);
  });
}
''',
      ).unit;

      FunctionExpression? closure;
      unit.visitChildren(_FunctionExpressionVisitor((node) => closure = node));

      expect(closure, isNotNull);
      expect(
        AvoidUnnecessaryViaScope.isUnnecessaryViaClosure(closure!),
        isFalse,
      );
    });

    test(
      'detects unnecessary via when body only has property/named/shadowed via',
      () {
        for (final body in [
          'otherObj.via',
          'helper(via: 1)',
          'items.map((via) => via + 1).toList()',
        ]) {
          final unit = parseString(
            content:
                '''
void test() {
  final res = computed((via) => $body);
}
''',
          ).unit;

          FunctionExpression? outerClosure;
          unit.visitChildren(
            _FunctionExpressionVisitor((node) {
              if (outerClosure == null &&
                  node.parameters?.parameters.isNotEmpty == true) {
                outerClosure = node;
              }
            }),
          );

          expect(outerClosure, isNotNull);
          expect(
            AvoidUnnecessaryViaScope.isUnnecessaryViaClosure(outerClosure!),
            isTrue,
          );
        }
      },
    );
  });
}

class _FunctionExpressionVisitor extends RecursiveAstVisitor<void> {
  _FunctionExpressionVisitor(this.onFound);
  final void Function(FunctionExpression) onFound;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    onFound(node);
    super.visitFunctionExpression(node);
  }
}

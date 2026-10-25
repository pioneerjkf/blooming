// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:blooming_lints/blooming_lints.dart';
import 'package:test/test.dart';

void main() {
  group('PreferBloomWidget AST detection', () {
    test('detects 1:1 StatelessWidget returning composed via expression body',
        () {
      final unit = parseString(content: '''
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) => composed((context, via) => Text('hi'));
}
''').unit;

      ClassDeclaration? clazz;
      unit.visitChildren(_ClassVisitor((node) => clazz = node));

      expect(clazz, isNotNull);
      final buildMethod = clazz!.members.whereType<MethodDeclaration>().first;
      final returnedExpr =
          PreferBloomWidget.getSoleReturnedExpression(buildMethod);

      expect(returnedExpr, isNotNull);
      expect(PreferBloomWidget.isSoleComposedInvocation(returnedExpr!), isTrue);
    });

    test(
        'detects 1:1 StatelessWidget returning composed via single return statement block',
        () {
      final unit = parseString(content: '''
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return composed((context, via) {
      final user = via(userBloom);
      return Text(user.name);
    });
  }
}
''').unit;

      ClassDeclaration? clazz;
      unit.visitChildren(_ClassVisitor((node) => clazz = node));

      expect(clazz, isNotNull);
      final buildMethod = clazz!.members.whereType<MethodDeclaration>().first;
      final returnedExpr =
          PreferBloomWidget.getSoleReturnedExpression(buildMethod);

      expect(returnedExpr, isNotNull);
      expect(PreferBloomWidget.isSoleComposedInvocation(returnedExpr!), isTrue);
    });

    test('detects 1:1 StatelessWidget returning composed.animate', () {
      final unit = parseString(content: '''
class RadarView extends StatelessWidget {
  const RadarView({super.key, required this.controller});
  final DurableAnimationController controller;

  @override
  Widget build(BuildContext context) {
    return composed.animate(
      controller,
      (context, via, ctrl) => RotationTransition(turns: ctrl.view, child: Icon(Icons.radar)),
    );
  }
}
''').unit;

      ClassDeclaration? clazz;
      unit.visitChildren(_ClassVisitor((node) => clazz = node));

      expect(clazz, isNotNull);
      final buildMethod = clazz!.members.whereType<MethodDeclaration>().first;
      final returnedExpr =
          PreferBloomWidget.getSoleReturnedExpression(buildMethod);

      expect(returnedExpr, isNotNull);
      expect(PreferBloomWidget.isSoleComposedInvocation(returnedExpr!), isTrue);
    });

    test(
        'permits StatelessWidget that has fixed layout with local leaf composed (does NOT flag)',
        () {
      final unit = parseString(content: '''
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HeavyHeader(),
        composed((context, via) => Text('Count: \${via(countBloom)}')),
      ],
    );
  }
}
''').unit;

      ClassDeclaration? clazz;
      unit.visitChildren(_ClassVisitor((node) => clazz = node));

      expect(clazz, isNotNull);
      final buildMethod = clazz!.members.whereType<MethodDeclaration>().first;
      final returnedExpr =
          PreferBloomWidget.getSoleReturnedExpression(buildMethod);

      expect(returnedExpr, isNotNull);
      // Column is NOT a sole composed invocation!
      expect(
          PreferBloomWidget.isSoleComposedInvocation(returnedExpr!), isFalse);
    });

    test('permits StatelessWidget with multiple statements before return', () {
      final unit = parseString(content: '''
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return composed((context, via) => Text('hi'));
  }
}
''').unit;

      ClassDeclaration? clazz;
      unit.visitChildren(_ClassVisitor((node) => clazz = node));

      expect(clazz, isNotNull);
      final buildMethod = clazz!.members.whereType<MethodDeclaration>().first;
      final returnedExpr =
          PreferBloomWidget.getSoleReturnedExpression(buildMethod);

      // Has 2 statements, so getSoleReturnedExpression must return null!
      expect(returnedExpr, isNull);
    });
  });
}

class _ClassVisitor extends RecursiveAstVisitor<void> {
  final void Function(ClassDeclaration) onClass;
  _ClassVisitor(this.onClass);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    onClass(node);
    super.visitClassDeclaration(node);
  }
}

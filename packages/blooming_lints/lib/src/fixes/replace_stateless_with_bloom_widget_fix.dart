// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

// ignore_for_file: deprecated_member_use

part of '../../blooming_lints.dart';

/// A quick fix that converts a 1:1 `StatelessWidget` wrapping `composed` into a direct `BloomWidget`.
class ReplaceStatelessWithBloomWidgetFix extends ResolvedCorrectionProducer {
  ReplaceStatelessWithBloomWidgetFix({required super.context});

  static const _fixKind = FixKind(
    'blooming_lints.fix.replaceStatelessWithBloomWidget',
    DartFixKindPriority.standard,
    'Convert to {0}',
  );

  String? _replacementSuperclass;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  List<String>? get fixArguments =>
      _replacementSuperclass == null ? null : [_replacementSuperclass!];

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl == null) return;

    final extendsClause = classDecl.extendsClause;
    if (extendsClause == null) return;

    MethodDeclaration? buildMethod;
    for (final member in FlutterAstUtils.classMembers(classDecl)) {
      if (member is MethodDeclaration && member.name.lexeme == 'build') {
        buildMethod = member;
        break;
      }
    }
    if (buildMethod == null) return;

    final returnedExpr = PreferBloomWidget.getSoleReturnedExpression(
      buildMethod,
    );
    if (returnedExpr == null ||
        !PreferBloomWidget.isSoleComposedInvocation(returnedExpr)) {
      return;
    }

    final isAnimate =
        returnedExpr is MethodInvocation &&
        returnedExpr.methodName.name == 'animate';
    final isVsync =
        returnedExpr is MethodInvocation &&
        returnedExpr.methodName.name == 'vsync';

    final replacementSuperclass = isAnimate
        ? 'BloomAnimatedWidget'
        : isVsync
        ? 'BloomVsyncWidget'
        : 'BloomWidget';
    _replacementSuperclass = replacementSuperclass;

    await builder.addDartFileEdit(file, (builder) {
      // 1. Replace superclass: StatelessWidget -> BloomWidget / BloomAnimatedWidget
      builder.addSimpleReplacement(
        range.node(extendsClause.superclass),
        replacementSuperclass,
      );

      // 2. Adjust build parameters: (BuildContext context) -> (BuildContext context, BloomVia via)
      final params = buildMethod!.parameters;
      if (params != null && params.parameters.isNotEmpty) {
        final firstParam = params.parameters.first;
        final extraParam = isAnimate
            ? ', BloomVia via, ScopedAnimationController anim'
            : isVsync
            ? ', BloomVia via, TickerProvider vsync'
            : ', BloomVia via';
        builder.addInsertion(firstParam.end, (editBuilder) {
          editBuilder.write(extraParam);
        });
      }

      // 3. Unwrap composed(...)
      FunctionExpression? closure;
      if (returnedExpr is FunctionExpressionInvocation) {
        final args = returnedExpr.argumentList.arguments;
        if (args.isNotEmpty && args.first is FunctionExpression) {
          closure = args.first as FunctionExpression;
        }
      } else if (returnedExpr is MethodInvocation) {
        final args = returnedExpr.argumentList.arguments;
        for (final arg in args) {
          if (arg is FunctionExpression) {
            closure = arg;
            break;
          }
        }
      }

      if (closure != null) {
        final closureBody = closure.body;
        if (closureBody is ExpressionFunctionBody) {
          final innerExpr = closureBody.expression.toSource();
          builder.addSimpleReplacement(range.node(returnedExpr), innerExpr);
        } else if (closureBody is BlockFunctionBody) {
          final innerBlockSource = closureBody.block.toSource();
          builder.addSimpleReplacement(
            range.node(buildMethod.body),
            innerBlockSource,
          );
        }
      }
    });
  }
}

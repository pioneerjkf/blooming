// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

// ignore_for_file: deprecated_member_use

part of '../../blooming_lints.dart';

/// A quick fix that converts a 1:1 `StatelessWidget` wrapping `composed` into a direct `BloomWidget`.
class ReplaceStatelessWithBloomWidgetFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addClassDeclaration((node) {
      final extendsClause = node.extendsClause;
      if (extendsClause == null) return;
      if (!extendsClause.superclass.sourceRange
          .intersects(analysisError.sourceRange)) {
        return;
      }

      MethodDeclaration? buildMethod;
      for (final member in node.members) {
        if (member is MethodDeclaration && member.name.lexeme == 'build') {
          buildMethod = member;
          break;
        }
      }
      if (buildMethod == null) return;

      final returnedExpr =
          PreferBloomWidget.getSoleReturnedExpression(buildMethod);
      if (returnedExpr == null ||
          !PreferBloomWidget.isSoleComposedInvocation(returnedExpr)) {
        return;
      }

      final isAnimate = returnedExpr is MethodInvocation &&
          returnedExpr.methodName.name == 'animate';
      final isVsync = returnedExpr is MethodInvocation &&
          returnedExpr.methodName.name == 'vsync';

      final replacementSuperclass = isAnimate
          ? 'BloomAnimatedWidget'
          : isVsync
              ? 'BloomVsyncWidget'
              : 'BloomWidget';

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Convert to $replacementSuperclass',
        priority: 50,
      );

      changeBuilder.addDartFileEdit((builder) {
        // 1. Replace superclass: StatelessWidget -> BloomWidget / BloomAnimatedWidget
        builder.addSimpleReplacement(
          extendsClause.superclass.sourceRange,
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
            builder.addSimpleReplacement(returnedExpr.sourceRange, innerExpr);
          } else if (closureBody is BlockFunctionBody) {
            final innerBlockSource = closureBody.block.toSource();
            builder.addSimpleReplacement(
                buildMethod.body.sourceRange, innerBlockSource);
          }
        }
      });
    });
  }
}

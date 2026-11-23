// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../blooming_lints.dart';

/// A lint rule recommending extending `BloomWidget` or `BloomAnimatedWidget` directly
/// instead of wrapping the entire `build()` method of a `StatelessWidget` with a 1:1 `composed` functor.
///
/// ### Rationale:
/// When a `StatelessWidget`'s `build()` method does nothing except immediately return a `composed`
/// or `composed.animate` call, Flutter creates both a `StatelessElement` and an internal `_ComposedElement`.
/// This redundant element layer causes:
/// 1. Double element tree depth and duplicate element heap allocations.
/// 2. Redundant framework build pass indirection.
///
/// If a component's entire presentation depends on reactive state, extend `BloomWidget`
/// (or `BloomAnimatedWidget`) directly to achieve a single, optimal Element binding.
///
/// Note: Wrapping only a local sub-branch (leaf) inside a larger `StatelessWidget` layout
/// (e.g. `Row`, `Column`, `Scaffold`) is a RECOMMENDED pattern and is not flagged.
///
/// **BAD (1:1 Redundant Wrapper):**
/// ```dart
/// class MyCounterWidget extends StatelessWidget {
///   const MyCounterWidget({super.key, required this.count});
///   final Bloom<int> count;
///
///   @override
///   Widget build(BuildContext context) {
///     return composed((context, via) => Text('Count: ${via(count)}'));
///   }
/// }
/// ```
///
/// **GOOD (Direct BloomWidget):**
/// ```dart
/// class MyCounterWidget extends BloomWidget {
///   const MyCounterWidget({super.key, required this.count});
///   final Bloom<int> count;
///
///   @override
///   Widget build(BuildContext context, BloomVia via) {
///     return Text('Count: ${via(count)}');
///   }
/// }
/// ```
///
/// **GOOD (StatelessWidget with Local Leaf Rebuild - Allowed):**
/// ```dart
/// class MyDashboard extends StatelessWidget {
///   const MyDashboard({super.key, required this.count});
///   final Bloom<int> count;
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         const HeavyHeader(),
///         composed((context, via) => Text('Count: ${via(count)}')),
///       ],
///     );
///   }
/// }
/// ```
class PreferBloomWidget extends AnalysisRule {
  PreferBloomWidget()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'prefer_bloom_widget',
    'A StatelessWidget that immediately returns a composed functor creates redundant Element allocations. Extend BloomWidget directly.',
    correctionMessage:
        'Replace StatelessWidget with BloomWidget (or BloomAnimatedWidget) to eliminate double-Element overhead.',
    severity: DiagnosticSeverity.INFO,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _PreferBloomWidgetVisitor(this));
  }

  /// Returns the sole returned expression if the method body consists strictly of a single return or expression body.
  static Expression? getSoleReturnedExpression(MethodDeclaration method) {
    final body = method.body;
    if (body is ExpressionFunctionBody) {
      return body.expression.unParenthesized;
    }
    if (body is BlockFunctionBody) {
      final statements = body.block.statements;
      if (statements.length == 1) {
        final statement = statements.first;
        if (statement is ReturnStatement) {
          return statement.expression?.unParenthesized;
        }
      }
    }
    return null;
  }

  /// Returns `true` if [expr] is an immediate invocation of `composed(...)`,
  /// `composed.vsync(...)`, or `composed.animate(...)`.
  static bool isSoleComposedInvocation(Expression expr) {
    if (expr is MethodInvocation) {
      // 1. Direct top-level composed(...) -> target is null, methodName is 'composed'
      if (expr.target == null && expr.methodName.name == 'composed') {
        return true;
      }
      // 2. Chained composed.vsync(...) / composed.animate(...)
      final target = expr.target?.unParenthesized;
      if (target is SimpleIdentifier && target.name == 'composed') {
        final name = expr.methodName.name;
        return name == 'vsync' || name == 'animate';
      }
    }
    if (expr is FunctionExpressionInvocation) {
      final target = expr.function.unParenthesized;
      return target is SimpleIdentifier && target.name == 'composed';
    }
    return false;
  }
}

class _PreferBloomWidgetVisitor extends SimpleAstVisitor<void> {
  _PreferBloomWidgetVisitor(this.rule);
  final PreferBloomWidget rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause == null) return;
    if (extendsClause.superclass.name.lexeme != 'StatelessWidget') return;

    for (final member in FlutterAstUtils.classMembers(node)) {
      if (member is MethodDeclaration && member.name.lexeme == 'build') {
        final returnedExpr = PreferBloomWidget.getSoleReturnedExpression(
          member,
        );
        if (returnedExpr != null &&
            PreferBloomWidget.isSoleComposedInvocation(returnedExpr)) {
          rule.reportAtNode(extendsClause.superclass);
        }
      }
    }
  }
}

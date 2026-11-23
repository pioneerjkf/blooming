// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../blooming_lints.dart';

/// A lint rule warning when a `computed` or `switched` scope declares a `via` parameter but never uses it.
///
/// ### Rationale:
/// Reactive derivation nodes (`computed`, `switched`) exist to dynamically track upstream dependencies
/// via explicit `via(node)` observation calls.
/// Creating a reactive scope that never accesses `via` creates unnecessary DAG graph overhead, allocation pressure,
/// and re-evaluation churn for values that never change reactively.
///
/// **BAD:**
/// ```dart
/// final constantVal = computed((via) { // [Anti-Pattern] via is never used!
///   return 10 + 20;
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// // Approach 1: Static node via Bloom.constant or standard final variable
/// final staticConfig = Bloom.constant(30);
/// final constantVal = 10 + 20;
///
/// // Approach 2: Actively tracking dependencies via via(node)
/// final sum = computed((via) {
///   return via(aBloom) + via(bBloom); // [Recommended] Explicit dynamic dependencies tracked
/// });
/// ```
class AvoidUnnecessaryViaScope extends AnalysisRule {
  AvoidUnnecessaryViaScope()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'avoid_unnecessary_via_scope',
    'The reactive closure declares \'via\' but never tracks any upstream dependencies.',
    correctionMessage:
        'Call via(bloom) to track dependencies, or replace this reactive node with a standard final variable.',
    severity: DiagnosticSeverity.INFO,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _AvoidUnnecessaryViaScopeVisitor(this);
    registry.addFunctionExpressionInvocation(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }

  /// Returns `true` if [closure] accepts a `via` parameter but never calls `via(...)` or references `via`.
  static bool isUnnecessaryViaClosure(FunctionExpression closure) {
    final params = closure.parameters?.parameters;
    if (params == null || params.isEmpty) return false;

    FormalParameter? viaParam;
    for (final p in params) {
      if (BloomTypeChecker.isBloomViaParameter(p)) {
        viaParam = p;
        break;
      }
    }
    if (viaParam == null) return false;

    final viaName = viaParam.name?.lexeme ?? 'via';
    final viaElement = viaParam.declaredFragment?.element;
    var usesVia = false;

    closure.body.visitChildren(
      _IdentifierVisitor(viaName, viaElement, () {
        usesVia = true;
      }),
    );

    return !usesVia;
  }
}

class _AvoidUnnecessaryViaScopeVisitor extends SimpleAstVisitor<void> {
  _AvoidUnnecessaryViaScopeVisitor(this.rule);
  final AvoidUnnecessaryViaScope rule;

  void _checkArguments(ArgumentList argumentList) {
    final args = argumentList.arguments;
    if (args.isEmpty) return;

    final firstArg = args.first;
    if (firstArg is FunctionExpression) {
      if (AvoidUnnecessaryViaScope.isUnnecessaryViaClosure(firstArg)) {
        rule.reportAtNode(firstArg);
      }
    }
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    final name = BloomTypeChecker.resolveFunctorName(node);
    if (name == 'ComputedFunctor' ||
        name == 'SwitchedFunctor' ||
        name == 'ComputedStreamFunctor' ||
        name == 'ComputedFutureFunctor') {
      _checkArguments(node.argumentList);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = BloomTypeChecker.resolveFunctorName(node);
    if (name == 'ComputedFunctor' ||
        name == 'SwitchedFunctor' ||
        name == 'ComputedStreamFunctor' ||
        name == 'ComputedFutureFunctor') {
      _checkArguments(node.argumentList);
    }
  }
}

class _IdentifierVisitor extends RecursiveAstVisitor<void> {
  _IdentifierVisitor(this.viaName, this.viaElement, this.onFound);
  final String viaName;
  final Element? viaElement;
  final void Function() onFound;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (viaElement == null) {
      final params = node.parameters?.parameters;
      if (params != null && params.any((p) => p.name?.lexeme == viaName)) {
        return; // Shadowed in unresolved AST
      }
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (viaElement != null) {
      if (node.element == viaElement) {
        onFound();
      }
    } else if (node.name == viaName) {
      final parent = node.parent;
      final isNonReference =
          (parent is PropertyAccess && identical(parent.propertyName, node)) ||
          (parent is PrefixedIdentifier && identical(parent.identifier, node)) ||
          (parent is NamedArgument && identical(parent.name, node)) ||
          (parent is MethodInvocation &&
              parent.target != null &&
              identical(parent.methodName, node));
      if (!isNonReference) {
        onFound();
      }
    }
    super.visitSimpleIdentifier(node);
  }
}

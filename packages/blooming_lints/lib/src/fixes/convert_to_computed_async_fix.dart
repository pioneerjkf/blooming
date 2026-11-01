// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

// ignore_for_file: deprecated_member_use

part of '../../blooming_lints.dart';

/// A quick fix that converts a synchronous `computed(...)` invocation with an asynchronous
/// computation into `computed.future(...)` or `computed.stream(...)`.
class ConvertToComputedAsyncFix extends DartFix {
  /// Resolves the AST target node and its replacement string for [node], or `null` if not convertible.
  @visibleForTesting
  static ({
    AstNode targetNode,
    Expression computeArg,
    String replacement,
    String message,
  })? computeReplacement(InvocationExpression node) {
    if (BloomTypeChecker.resolveFunctorName(node) != 'ComputedFunctor') {
      return null;
    }

    final positional =
        node.argumentList.arguments.where((arg) => arg is! NamedExpression);
    if (positional.isEmpty) return null;
    final computeArg = positional.first;

    final kind = BloomTypeChecker.classifyAsyncComputation(computeArg);
    if (kind == AsyncComputationKind.none) return null;

    final isStream = kind == AsyncComputationKind.stream;
    final suffix = isStream ? '.stream' : '.future';
    final message =
        isStream ? 'Convert to computed.stream' : 'Convert to computed.future';

    AstNode? targetNode;
    String? replacement;

    if (node is MethodInvocation) {
      if (node.methodName.name == 'computed') {
        targetNode = node.methodName;
        replacement = 'computed$suffix';
      }
    } else if (node is FunctionExpressionInvocation) {
      final func = node.function;
      if (func is SimpleIdentifier && func.name == 'computed') {
        targetNode = func;
        replacement = 'computed$suffix';
      } else if (func is PrefixedIdentifier &&
          func.identifier.name == 'computed') {
        targetNode = func.identifier;
        replacement = 'computed$suffix';
      } else if (func is PropertyAccess &&
          func.propertyName.name == 'computed') {
        targetNode = func.propertyName;
        replacement = 'computed$suffix';
      }
    }

    if (targetNode == null || replacement == null) return null;

    return (
      targetNode: targetNode,
      computeArg: computeArg,
      replacement: replacement,
      message: message,
    );
  }

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    void handleInvocation(InvocationExpression node) {
      if (!node.sourceRange.intersects(analysisError.sourceRange)) return;

      final resolved = computeReplacement(node);
      if (resolved == null) return;
      if (!resolved.computeArg.sourceRange
          .intersects(analysisError.sourceRange)) {
        return;
      }

      final changeBuilder = reporter.createChangeBuilder(
        message: resolved.message,
        priority: 50,
      );
      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          resolved.targetNode.sourceRange,
          resolved.replacement,
        );
      });
    }

    context.registry.addMethodInvocation(handleInvocation);
    context.registry.addFunctionExpressionInvocation(handleInvocation);
  }
}

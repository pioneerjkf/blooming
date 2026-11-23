// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../blooming_lints.dart';

/// A lint rule prohibiting catching broad exceptions around `via()` calls inside reactive scopes.
///
/// ### Rationale:
/// Bloom uses a lightweight internal short-circuit sentinel (`_ViaShortCircuit`) to instantly
/// drop downstream derivation evaluation and propagate `Empty` or `Error` states synchronously.
///
/// Wrapping `via(...)` calls in a broad `try/catch` (`catch (_)`, `on Object`, `on Exception`,
/// `on Error`) inadvertently intercepts this sentinel, breaking Bloom's 3-state propagation and
/// silently corrupting downstream reactive semantics.
///
/// **BAD:**
/// ```dart
/// final derived = computed((via) {
///   try {
///     return via(sourceBloom) + 1; // [Anti-Pattern] Intercepts short-circuit sentinel!
///   } catch (e) {
///     return 0;
///   }
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// final derived = computed((via) {
///   final value = via(sourceBloom); // [Recommended] Short-circuit escapes unhindered
///   try {
///     return parseValue(value);
///   } on FormatException catch (e) {
///     return 0; // Catches only specific business exception
///   }
/// });
/// ```
class AvoidCatchingViaShortCircuit extends AnalysisRule {
  AvoidCatchingViaShortCircuit()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'avoid_catching_via_short_circuit',
    'Avoid catching broad exceptions around via() calls inside reactive scopes.',
    correctionMessage:
        'Move via() calls outside the try block or catch only specific domain exceptions to allow Bloom\'s short-circuit sentinel to propagate.',
    severity: DiagnosticSeverity.ERROR,
  );

  static const broadExceptionTypes = {
    'Object',
    'dynamic',
    'Exception',
    'Error',
  };

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addTryStatement(this, _AvoidCatchingViaShortCircuitVisitor(this));
  }

  /// Returns `true` if the given catch [clause] rethrows its exception.
  static bool isCatchClauseRethrowing(CatchClause clause) {
    final statements = clause.body.statements;
    if (statements.isNotEmpty) {
      final last = statements.last;
      if (last is ExpressionStatement && last.expression is RethrowExpression) {
        return true;
      }
    }
    return false;
  }
}

class _AvoidCatchingViaShortCircuitVisitor extends SimpleAstVisitor<void> {
  _AvoidCatchingViaShortCircuitVisitor(this.rule);
  final AvoidCatchingViaShortCircuit rule;

  @override
  void visitTryStatement(TryStatement node) {
    if (!BloomTypeChecker.isInsideBloomViaScope(node)) return;
    if (AvoidUntrackedBloomRead.isInsideDeferredEventOrAsyncCallback(node)) {
      return;
    }

    // Check if node.body contains any via() or via.state() invocation
    final finder = _ViaInvocationFinder();
    node.body.accept(finder);
    if (!finder.hasViaInvocation) return;

    for (final catchClause in node.catchClauses) {
      if (AvoidCatchingViaShortCircuit.isCatchClauseRethrowing(catchClause)) {
        continue;
      }

      final typeName = catchClause.exceptionType?.toSource();
      if (typeName == null ||
          AvoidCatchingViaShortCircuit.broadExceptionTypes.contains(typeName)) {
        rule.reportAtNode(catchClause);
      }
    }
  }
}

class _ViaInvocationFinder extends RecursiveAstVisitor<void> {
  bool hasViaInvocation = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (BloomTypeChecker.isBloomViaInvocation(node)) {
      hasViaInvocation = true;
      return;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (BloomTypeChecker.isBloomViaInvocation(node)) {
      hasViaInvocation = true;
      return;
    }
    super.visitFunctionExpressionInvocation(node);
  }
}

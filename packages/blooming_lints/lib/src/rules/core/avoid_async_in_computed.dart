// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../blooming_lints.dart';

/// A lint rule prohibiting asynchronous closures or Future/Stream return types in synchronous `computed(...)`.
///
/// ### Rationale:
/// `computed(...)` is strictly a synchronous LPDAG derivation node.
/// Passing an `async` or `async*` closure to `computed(...)` causes Dart to infer
/// `Bloom<Future<T>>` or `Bloom<Stream<T>>`, supervising the `Future`/`Stream` instance
/// as a data payload rather than unwrapping its value.
///
/// Furthermore, `computed(...)` does not attach completion or error handlers to returned
/// `Future`s, meaning downstream `_ViaShortCircuit` sentinels or asynchronous exceptions
/// become unhandled, leading to silent drops or application crashes.
///
/// Asynchronous derivations must use `computed.future(...)` or `computed.stream(...)`.
///
/// **BAD:**
/// ```dart
/// final userProfile = computed((via) async { // [Anti-Pattern] Async closure in computed!
///   final id = via(userIdBloom);
///   return await apiService.fetchUser(id);
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// // Approach 1: Single-shot async request (Direct return avoids async state-machine allocation)
/// final userProfile = computed.future((via) => apiService.fetchUser(via(userIdBloom)));
///
/// // Approach 2: Multi-step async pipeline with await
/// final userWithPermissions = computed.future((via) async {
///   final user = await apiService.fetchUser(via(userIdBloom));
///   return await apiService.fetchPermissions(user.id);
/// });
/// ```
class AvoidAsyncInComputed extends AnalysisRule {
  AvoidAsyncInComputed()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'avoid_async_in_computed',
    'Avoid passing asynchronous closures or Future/Stream return types to synchronous computed().',
    correctionMessage:
        'Use computed.future() for Future derivations or computed.stream() for Stream derivations.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _AvoidAsyncInComputedVisitor(this);
    registry.addFunctionExpressionInvocation(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }

  /// Returns `true` if [expr] is an asynchronous closure or returns a Future/Stream.
  static bool isAsyncComputation(Expression expr) {
    return BloomTypeChecker.classifyAsyncComputation(expr) !=
        AsyncComputationKind.none;
  }

  /// Checks if [node] is a `computed` invocation containing an async closure.
  static bool isAsyncClosureInComputed(InvocationExpression node) {
    final name = BloomTypeChecker.resolveFunctorName(node);
    if (name != 'ComputedFunctor') return false;
    final positional = node.argumentList.arguments
        .where((arg) => arg is! NamedArgument)
        .map((arg) => arg.argumentExpression);
    if (positional.isEmpty) return false;
    return isAsyncComputation(positional.first);
  }
}

class _AvoidAsyncInComputedVisitor extends SimpleAstVisitor<void> {
  _AvoidAsyncInComputedVisitor(this.rule);
  final AvoidAsyncInComputed rule;

  void _checkArgumentList(ArgumentList argumentList) {
    final positional = argumentList.arguments
        .where((arg) => arg is! NamedArgument)
        .map((arg) => arg.argumentExpression);
    if (positional.isEmpty) return;
    final computeArg = positional.first;
    if (AvoidAsyncInComputed.isAsyncComputation(computeArg)) {
      rule.reportAtNode(computeArg);
    }
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (BloomTypeChecker.resolveFunctorName(node) == 'ComputedFunctor') {
      _checkArgumentList(node.argumentList);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (BloomTypeChecker.resolveFunctorName(node) == 'ComputedFunctor') {
      _checkArgumentList(node.argumentList);
    }
  }
}

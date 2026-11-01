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
class AvoidAsyncInComputed extends DartLintRule {
  AvoidAsyncInComputed() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_async_in_computed',
    problemMessage:
        'Avoid passing asynchronous closures or Future/Stream return types to synchronous computed().',
    correctionMessage:
        'Use computed.future() for Future derivations or computed.stream() for Stream derivations.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  List<Fix> getFixes() => [ConvertToComputedAsyncFix()];

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    void checkArgumentList(ArgumentList argumentList) {
      final positional =
          argumentList.arguments.where((arg) => arg is! NamedExpression);
      if (positional.isEmpty) return;
      final computeArg = positional.first;
      if (isAsyncComputation(computeArg)) {
        reporter.atNode(computeArg, _code);
      }
    }

    context.registry.addFunctionExpressionInvocation((node) {
      if (BloomTypeChecker.resolveFunctorName(node) == 'ComputedFunctor') {
        checkArgumentList(node.argumentList);
      }
    });

    context.registry.addMethodInvocation((node) {
      if (BloomTypeChecker.resolveFunctorName(node) == 'ComputedFunctor') {
        checkArgumentList(node.argumentList);
      }
    });
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
    final positional =
        node.argumentList.arguments.where((arg) => arg is! NamedExpression);
    if (positional.isEmpty) return false;
    return isAsyncComputation(positional.first);
  }
}

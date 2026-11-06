// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../blooming_lints.dart';

/// A lint rule prohibiting asynchronous closures or Future/Stream return types in `managed(...)`.
///
/// ### Rationale:
/// `managed` strictly supervises pure synchronous external resource lifecycles (`create`, `update`, `dispose`).
/// Passing an `async` or `async*` closure to `create` or `update` causes Dart to infer `managed<Future<T>>`
/// or `managed<Stream<T>>`, supervising the asynchronous container itself instead of the underlying resource,
/// preventing timely disposal and causing catastrophic resource leaks.
///
/// Synchronous resources that implement `Stream` (such as `ReceivePort` or `Socket`) are fully permitted
/// because their allocation and disposal remain synchronous.
///
/// For `dispose`, asynchronous closures (`async`) are prohibited to prevent fire-and-forget concurrency
/// issues, but synchronous functions returning `Future<void>` (such as `(sub) => sub.cancel()`) are
/// allowed.
///
/// Asynchronous data querying must be cleanly separated into `computed.future` or `computed.stream`.
///
/// **BAD:**
/// ```dart
/// final client = managed(
///   create: (via) async { // [Anti-Pattern] Async closure in managed!
///     final c = HttpClient();
///     await c.init();
///     return c;
///   },
///   dispose: (c) => c.close(),
/// );
/// ```
///
/// **GOOD:**
/// ```dart
/// // Approach 1: Synchronous resource lifecycle in managed
/// final timer = managed<Timer>(
///   create: (via) => Timer.periodic(const Duration(seconds: 1), (t) => tick()),
///   dispose: (t) => t.cancel(),
/// );
///
/// // Approach 2: Synchronous stream resource (e.g. ReceivePort)
/// final port = managed<ReceivePort>(
///   create: (via) => ReceivePort(),
///   dispose: (p) => p.close(),
/// );
///
/// // Approach 3: Asynchronous querying in computed.future
/// final clientData = computed.future((via) async {
///   final targetUrl = via(urlBloom); // Tracked and isolated by _ViaScope.async
///   final c = HttpClient();
///   return await c.fetch(targetUrl);
/// });
/// ```
class AvoidAsyncInManaged extends DartLintRule {
  AvoidAsyncInManaged() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_async_in_managed',
    problemMessage:
        'Avoid passing asynchronous closures or Future/Stream types to managed().',
    correctionMessage:
        'Use synchronous closures for managed resource lifecycles, or use computed.future/computed.stream for async queries.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    void checkArgumentList(ArgumentList argumentList) {
      for (final expr in findAsyncClosures(argumentList)) {
        reporter.atNode(expr, _code);
      }
    }

    context.registry.addFunctionExpressionInvocation((node) {
      if (BloomTypeChecker.resolveFunctorName(node) == 'ManagedFunctor') {
        checkArgumentList(node.argumentList);
      }
    });

    context.registry.addMethodInvocation((node) {
      if (BloomTypeChecker.resolveFunctorName(node) == 'ManagedFunctor') {
        checkArgumentList(node.argumentList);
      }
    });
  }

  /// Returns all asynchronous create/update/dispose [Expression]s in the given [argumentList].
  static List<Expression> findAsyncClosures(ArgumentList argumentList) {
    final asyncClosures = <Expression>[];
    for (final arg in argumentList.arguments) {
      if (arg is NamedExpression) {
        final paramName = arg.name.label.name;
        final expr = arg.expression;

        // 1. For create and update, prohibit async closures AND functions returning Future or exact Stream.
        // Synchronous resources implementing Stream (e.g. ReceivePort, Socket) are permitted.
        if (paramName == 'create' || paramName == 'update') {
          final kind = BloomTypeChecker.classifyAsyncComputation(
            expr,
            exactStreamOnly: true,
          );
          if (kind != AsyncComputationKind.none) {
            asyncClosures.add(expr);
          }
        }
        // 2. For dispose, prohibit async closures (body.isAsynchronous) but allow synchronous
        // functions returning Future<void> (e.g. dispose: (sub) => sub.cancel())
        else if (paramName == 'dispose') {
          if (expr is FunctionExpression && expr.body.isAsynchronous) {
            asyncClosures.add(expr);
          }
        }
      }
    }
    return asyncClosures;
  }

  /// Checks if the [node] invocation is a `managed` call containing an asynchronous create/update closure.
  static bool isAsyncClosureInManaged(MethodInvocation node) {
    if (node.methodName.name != 'managed') return false;
    return findAsyncClosures(node.argumentList).isNotEmpty;
  }
}

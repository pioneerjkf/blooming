// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../blooming_lints.dart';

/// A lint rule prohibiting escaping `BloomVia` into asynchronous timers/dispatchers,
/// deferred event callbacks, or nested asynchronous helper closures across `await` gaps.
///
/// ### Rationale:
/// `BloomVia` (`via(node)`) is bound to the evaluation turn of its owning reactive scope
/// (`computed`, `computed.future`, `computed.stream`, `Effect.via`, `BloomWidget`, etc.).
/// While direct `async` / `async*` reactive closures support post-`await` and post-`yield`
/// tracking within the same turn via on-demand asynchronous tracking (`_ViaTrack.async`),
/// escaping `via(...)` into out-of-band timers (`Timer.run`, `Timer.periodic`, `scheduleMicrotask`,
/// `Future.delayed`, `future.then`), UI event callbacks (`onPressed`), or unawaited nested
/// `async` helper functions causes:
/// 1. **Dropped Dependencies**: Out-of-band callbacks execute after the evaluation epoch has closed.
/// 2. **Temporal Inconsistency & Race Conditions**: Uncoordinated out-of-band reads bypass turn isolation.
///
/// **BAD:**
/// ```dart
/// final delayedTask = computed((via) {
///   Timer.run(() {
///     print(via(counterBloom)); // [Anti-Pattern] Escaped into async timer dispatcher!
///   });
///   return via(counterBloom);
/// });
///
/// class MyWidget extends BloomWidget {
///   Widget build(BuildContext context, BloomVia via) {
///     return ElevatedButton(
///       onPressed: () => print(via(counterBloom)), // [Anti-Pattern] Escaped into event callback!
///       child: const Text('Tap'),
///     );
///   }
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // Approach 1: Track dependencies directly inside the reactive closure (including after await in async scopes)
/// final userProfile = computed.future((via) async {
///   final id = via(userIdBloom);
///   final profile = await http.get('/user/$id');
///   final token = via(authTokenBloom); // [Supported] Tracked & turn-isolated by _ViaTrack.async
///   return filter(profile, token);
/// });
///
/// // Approach 2: Use zero-overhead raw reads (untracked) inside event or timer callbacks
/// class MyWidget extends BloomWidget {
///   Widget build(BuildContext context, BloomVia via) {
///     return ElevatedButton(
///       onPressed: () => print(untracked(counterBloom)), // [Recommended] Safe raw read without tracking
///       child: const Text('Tap'),
///     );
///   }
/// }
/// ```
class AvoidEscapingVia extends DartLintRule {
  AvoidEscapingVia() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_escaping_via',
    problemMessage:
        'Avoid escaping via() into event callbacks, async timer/Future callbacks, or nested async functions across await.',
    correctionMessage:
        'Call via(node) directly within the owning reactive scope, or use untracked(node) inside deferred event/timer callbacks.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!BloomTypeChecker.isBloomViaInvocation(node)) return;

      if (isEscapingViaInvocation(node)) {
        reporter.atNode(node, _code);
      }
    });

    context.registry.addFunctionExpressionInvocation((node) {
      if (!BloomTypeChecker.isBloomViaInvocation(node)) return;

      if (isEscapingViaInvocation(node)) {
        reporter.atNode(node, _code);
      }
    });
  }

  /// Checks if [node] is called inside an async timer/dispatcher, deferred inside an event handler,
  /// or across an `await` gap inside a nested function that does not own the `via` parameter.
  static bool isEscapingViaInvocation(AstNode node) {
    AstNode? current = node.parent;

    while (current != null) {
      // 1. Check if inside event handler parameter (e.g. onPressed, onTap)
      if (current is NamedExpression) {
        final paramName = current.name.label.name;
        if (BloomTypeChecker.isEventCallbackParameter(paramName)) {
          return true;
        }
      }

      // 2. Check if inside async dispatchers or Timer constructors
      // (e.g. Timer.run, Timer.periodic, scheduleMicrotask, Future.delayed, future.then)
      if (current is MethodInvocation) {
        if (BloomTypeChecker.isAsyncOrTimerInvocation(current)) {
          return true;
        }
      }
      if (current is InstanceCreationExpression) {
        if (BloomTypeChecker.isTimerCreation(current)) {
          return true;
        }
      }

      // 3. Check if inside an asynchronous function body, after an await expression.
      // Direct reactive closures that declare `via` (e.g., `(via) async { ... }`) are tracked
      // by `_resultViaTrack` (`_ViaTrack.async`), whereas nested helper functions/closures
      // that do not declare `via` escape the synchronous turn if they suspend at `await`.
      if (current is FunctionBody) {
        final parent = current.parent;
        final isOwningViaClosure = parent is FunctionExpression &&
            (parent.parameters?.parameters
                    .any(BloomTypeChecker.isBloomViaParameter) ??
                false);

        if (current.isAsynchronous && !isOwningViaClosure) {
          if (_isPrecededByAwait(current, node)) {
            return true;
          }
        }
      }

      // Stop once we reach the owning BloomVia closure or method declaration
      if (current is FunctionExpression) {
        final params = current.parameters?.parameters;
        if (params != null &&
            params.any(BloomTypeChecker.isBloomViaParameter)) {
          break;
        }
      }
      if (current is MethodDeclaration || current is FunctionDeclaration) {
        break;
      }

      current = current.parent;
    }

    return false;
  }

  /// Checks if there is any [AwaitExpression] preceding [node] within [body].
  static bool _isPrecededByAwait(FunctionBody body, AstNode node) {
    final nodeOffset = node.offset;
    var foundPrecedingAwait = false;

    body.visitChildren(_AwaitFinder((awaitNode) {
      if (awaitNode.offset < nodeOffset) {
        foundPrecedingAwait = true;
      }
    }));

    return foundPrecedingAwait;
  }
}

class _AwaitFinder extends RecursiveAstVisitor<void> {
  _AwaitFinder(this.onFound);
  final void Function(AwaitExpression) onFound;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    onFound(node);
    super.visitAwaitExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Do not recurse into nested closures or local functions; awaits inside them
    // do not suspend the enclosing asynchronous function body.
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Do not recurse into nested local function declarations.
  }
}

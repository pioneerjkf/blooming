// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../blooming_lints.dart';

/// A lint rule prohibiting direct, untracked reactive payload extraction (`untracked(bloom)`, `untracked.state(bloom)`, `.data`, `.snapshot`, etc.)
/// inside explicit `BloomVia` scopes without establishing dependency registration via `via()`.
///
/// ### Rationale:
/// Bloom uses explicit `BloomVia` dependency manifests (`computed((via) => ...)`, `composed((context, via) => ...)`,
/// `switched((via) => ...)`, `Effect((via) => ...)`, `BloomWidget.build(context, via)`) to achieve
/// zero-overhead raw reads with zero implicit tracking scope.
///
/// Reading a reactive node's payload directly via `untracked(node)`, `untracked.state(node)`, or controller `.data` inside a `BloomVia`
/// scope without wrapping it with `via(node)` or `via.state(node)` bypasses LPDAG edge creation. Consequently, when the
/// upstream state mutates, the downstream derivation or widget **fails to invalidate and recalculate**
/// (the fatal "silent unreactivity" bug).
///
/// **BAD:**
/// ```dart
/// final doubled = computed((via) {
///   return untracked(counterBloom) * 2; // [Anti-Pattern] Unregistered dependency (silent bug: never recomputes!)
/// });
///
/// class CounterWidget extends BloomWidget {
///   Widget build(BuildContext context, BloomVia via) {
///     return Text('${untracked(counterBloom)}'); // [Anti-Pattern] Never rebuilds on count updates!
///   }
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// final doubled = computed((via) {
///   return via(counterBloom) * 2; // [Recommended] Explicit LPDAG edge registered
/// });
///
/// class CounterWidget extends BloomWidget {
///   Widget build(BuildContext context, BloomVia via) {
///     return Text('${via(counterBloom)}'); // [Recommended] Dynamic dependency tracked
///   }
/// }
/// ```
class AvoidUntrackedBloomRead extends DartLintRule {
  AvoidUntrackedBloomRead() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_untracked_bloom_read',
    problemMessage:
        'Avoid reading reactive payload directly (\'{0}\') inside BloomVia scopes without calling via().',
    correctionMessage:
        'Wrap the reactive node with via(node) or via.state(node) to establish dynamic dependency tracking.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  static const _castCode = LintCode(
    name: 'avoid_untracked_bloom_read',
    problemMessage:
        'Avoid casting Bloom node to BloomState inside BloomVia scopes to bypass reactive tracking.',
    correctionMessage:
        'Use via(node) or via.state(node) instead of manual casting to establish dynamic dependency tracking.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  static const _untrackedCode = LintCode(
    name: 'avoid_untracked_bloom_read',
    problemMessage:
        'Avoid calling untracked(...) inside BloomVia scopes without establishing dependency tracking.',
    correctionMessage:
        'Use via(node) or via.state(node) instead of untracked(...) to establish dynamic dependency tracking.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  List<Fix> getFixes() => [WrapWithViaFix()];

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // 1. PropertyAccess (e.g. this.counter.data, this.controller.snapshot)
    context.registry.addPropertyAccess((node) {
      final propName = node.propertyName.name;
      if (BloomTypeChecker.isPipelineReadProperty(propName)) {
        if (BloomTypeChecker.isTrackableBloomTarget(node.target)) {
          if (isUntrackedInBloomViaScope(node)) {
            reporter.atNode(node, _code, arguments: [propName]);
          }
        }
      }
    });

    // 2. PrefixedIdentifier (e.g. counter.data, controller.snapshot)
    context.registry.addPrefixedIdentifier((node) {
      final propName = node.identifier.name;
      if (BloomTypeChecker.isPipelineReadProperty(propName)) {
        if (BloomTypeChecker.isTrackableBloomTarget(node.prefix)) {
          if (isUntrackedInBloomViaScope(node)) {
            reporter.atNode(node, _code, arguments: [propName]);
          }
        }
      }
    });

    // 3. MethodInvocation (e.g. counter.dataOrElse(...), untracked.state(...))
    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;
      if (BloomTypeChecker.isPipelineReadMethod(methodName)) {
        if (BloomTypeChecker.isTrackableBloomTarget(node.target)) {
          if (isUntrackedInBloomViaScope(node)) {
            reporter.atNode(node, _code, arguments: [methodName]);
          }
        }
      } else if (BloomTypeChecker.isBloomUntrackedInvocation(node)) {
        if (isUntrackedInBloomViaScope(node)) {
          reporter.atNode(node, _untrackedCode);
        }
      }
    });

    // 4. FunctionExpressionInvocation (e.g. untracked(node))
    context.registry.addFunctionExpressionInvocation((node) {
      if (BloomTypeChecker.isBloomUntrackedInvocation(node)) {
        if (isUntrackedInBloomViaScope(node)) {
          reporter.atNode(node, _untrackedCode);
        }
      }
    });

    // 5. AsExpression (e.g. count as BloomState)
    context.registry.addAsExpression((node) {
      if (isUntrackedInBloomViaScope(node)) {
        final targetType = node.type.type;
        if (targetType != null &&
            BloomTypeChecker.isBloomStateClass(targetType)) {
          final exprType = node.expression.unParenthesized.staticType;
          if (exprType != null && BloomTypeChecker.isBloomClass(exprType)) {
            reporter.atNode(node, _castCode);
          }
        }
      }
    });
  }

  /// Checks if the AST [node] is inside an active `BloomVia` scope and NOT deferred inside an event handler or via() call.
  static bool isUntrackedInBloomViaScope(AstNode node) {
    if (!isInsideBloomViaScope(node)) return false;
    if (isInsideDeferredEventOrAsyncCallback(node)) return false;
    if (isAlreadyTrackedByVia(node)) return false;
    return true;
  }

  /// Checks if the [node] is deferred inside an event handler parameter (e.g. onPressed) or async timer closure.
  static bool isInsideDeferredEventOrAsyncCallback(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      // 1. If inside an event callback parameter (e.g. onPressed: () => ..., onTap: () => ...)
      if (current is NamedExpression) {
        final paramName = current.name.label.name;
        if (BloomTypeChecker.isEventCallbackParameter(paramName)) {
          return true;
        }
      }

      // 2. If inside async dispatchers (e.g. Timer.run, scheduleMicrotask)
      if (current is MethodInvocation) {
        if (BloomTypeChecker.isAsyncOrTimerInvocation(current)) {
          return true;
        }
      }

      // 3. If inside a terminal side-effect action or listener callback
      if (BloomTypeChecker.isTerminalOrEffectInvocation(current)) {
        return true;
      }

      // Stop once we reach the enclosing BloomVia scope boundary
      if (current is MethodDeclaration &&
          BloomTypeChecker.isBloomWidgetBuildMethod(current)) {
        break;
      }
      if (current is FunctionExpression) {
        final params = current.parameters?.parameters;
        if (params != null &&
            params.any(BloomTypeChecker.isBloomViaParameter)) {
          break;
        }
      }

      current = current.parent;
    }
    return false;
  }

  /// Returns `true` if the [node] is physically enclosed inside a `BloomVia` manifest scope
  /// (`BloomWidget.build`, `computed`, `composed`, `switched`, `Effect`, or closure with `via` parameter).
  static bool isInsideBloomViaScope(AstNode node) =>
      BloomTypeChecker.isInsideBloomViaScope(node);

  /// Returns `true` if the [node] is already tracked via `via(node).prop` or inside `via(...)`.
  static bool isAlreadyTrackedByVia(AstNode node) {
    // 1. If target is directly a via() invocation, via.state(), or alias thereof
    if (node is PropertyAccess) {
      if (_isExpressionTrackedByVia(node.target)) {
        return true;
      }
    }

    if (node is PrefixedIdentifier) {
      if (_isExpressionTrackedByVia(node.prefix)) {
        return true;
      }
    }

    if (node is MethodInvocation) {
      if (_isExpressionTrackedByVia(node.target)) {
        return true;
      }
    }

    // 2. If node is an argument to via(...) (e.g. via(node))
    AstNode? current = node.parent;
    while (current != null) {
      if (BloomTypeChecker.isBloomViaInvocation(current)) {
        return true;
      }
      // via(...) is an expression invocation, so searching beyond a statement
      // or declaration boundary is unnecessary and wasteful.
      if (current is Statement || current is Declaration) {
        break;
      }
      current = current.parent;
    }
    return false;
  }

  /// Maximum variable alias resolution hops permitted before aborting to prevent
  /// infinite recursion on self-referential or cyclic variable assignments.
  static const _maxAliasHops = 4;

  static bool _isExpressionTrackedByVia(Expression? expr, [int aliasHops = 0]) {
    if (expr == null) return false;
    final unwrapped = expr.unParenthesized;
    if (BloomTypeChecker.isBloomViaInvocation(unwrapped)) return true;

    // Only variable alias resolution hops consume aliasHops budget.
    if (aliasHops < _maxAliasHops &&
        _isAliasOfViaInvocation(unwrapped, aliasHops + 1)) {
      return true;
    }

    // Syntactic AST descent (target, prefix) does not cycle, so it retains current aliasHops.
    if (unwrapped is PropertyAccess) {
      return _isExpressionTrackedByVia(unwrapped.target, aliasHops);
    }
    if (unwrapped is PrefixedIdentifier) {
      return _isExpressionTrackedByVia(unwrapped.prefix, aliasHops);
    }
    if (unwrapped is MethodInvocation) {
      return _isExpressionTrackedByVia(unwrapped.target, aliasHops);
    }
    return false;
  }

  static bool _isAliasOfViaInvocation(Expression? expr, [int aliasHops = 0]) {
    if (expr is! SimpleIdentifier || aliasHops >= _maxAliasHops) return false;
    final element = expr.element;

    // Search the enclosing root FunctionBody to support local variable lookups across closures
    final body = _findEnclosingRootFunctionBody(expr);
    if (body == null) return false;

    bool isTracked = false;
    if (element != null) {
      body.accept(_VariableFinder(element, (decl) {
        if (!isTracked &&
            decl.initializer != null &&
            _isExpressionTrackedByVia(decl.initializer, aliasHops)) {
          isTracked = true;
        }
      }));
    } else {
      final targetName = expr.name;
      final exprOffset = expr.offset;
      body.accept(_UnresolvedVariableFinder(targetName, (decl) {
        // Enforce lexical order for unresolved symbols: declaration must precede usage
        if (!isTracked &&
            decl.offset < exprOffset &&
            decl.initializer != null &&
            _isExpressionTrackedByVia(decl.initializer, aliasHops)) {
          isTracked = true;
        }
      }));
    }
    return isTracked;
  }

  /// Finds the outermost enclosing [FunctionBody] within the lexical method or function scope.
  static FunctionBody? _findEnclosingRootFunctionBody(Expression expr) {
    FunctionBody? rootBody;
    AstNode? current = expr.parent;
    while (current != null) {
      if (current is FunctionBody) {
        rootBody = current;
      }
      if (current is MethodDeclaration ||
          current is FunctionDeclaration ||
          current is ConstructorDeclaration) {
        break;
      }
      current = current.parent;
    }
    return rootBody;
  }
}

class _VariableFinder extends RecursiveAstVisitor<void> {
  final Element targetElement;
  final void Function(VariableDeclaration) onFound;

  _VariableFinder(this.targetElement, this.onFound);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.declaredFragment?.element == targetElement) {
      onFound(node);
    }
    super.visitVariableDeclaration(node);
  }
}

class _UnresolvedVariableFinder extends RecursiveAstVisitor<void> {
  final String targetName;
  final void Function(VariableDeclaration) onFound;

  _UnresolvedVariableFinder(this.targetName, this.onFound);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == targetName) {
      onFound(node);
    }
    super.visitVariableDeclaration(node);
  }
}

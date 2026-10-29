// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../blooming_lints.dart';

/// Centralized type-checking and AST analysis utility for the Bloom framework ecosystem.
abstract final class BloomTypeChecker {
  // ===========================================================================
  // Package URI Prefixes
  // ===========================================================================

  /// Package URI prefixes belonging to the Bloom ecosystem.
  static const _bloomPackagePrefixes = {
    'package:blooming/',
    'package:blooming_flutter/',
    'package:blooming_extensions/',
    'package:blooming_lints/',
  };

  /// Returns `true` if the given URI belongs to a Bloom package.
  static bool isBloomPackageUri(String? uri) {
    if (uri == null) return false;
    for (final prefix in _bloomPackagePrefixes) {
      if (uri.startsWith(prefix)) return true;
    }
    return false;
  }

  /// Returns `true` if the [element] is declared inside a Bloom package.
  static bool isFromBloomPackage(Element? element) {
    if (element == null) return false;
    return isBloomPackageUri(element.library?.identifier);
  }

  /// Returns `true` if the [type] represents the given [className] from a Bloom package.
  static bool _isBloomClass(DartType? type, String className) {
    if (type == null) return false;
    final element = type.element;
    if (element == null) return false;
    if (element.name == className && isFromBloomPackage(element)) return true;
    if (type is InterfaceType) {
      for (final superType in type.allSupertypes) {
        if (superType.element.name == className &&
            isFromBloomPackage(superType.element)) {
          return true;
        }
      }
    }
    return false;
  }

  // ===========================================================================
  // ===========================================================================
  // Core Type Name Sets (100% Verified Active Codebase AST Symbols)
  // ===========================================================================

  /// Core Bloom reactive DAG, state, controller, terminal, and UI types.
  static const _bloomTypes = {
    // 1. Core State Nodes & Protocol
    'Bloom',
    'BloomState',
    'BloomSnapshot',
    'BloomStatus',
    'RefreshableBloom',

    // 2. Producers & Controllers
    'BloomController',
    'RawBloomController',
    'BloomDraftController',
    'BloomCoupler',
    'BloomSignalController',

    // 3. Dependency Manifest & Signals
    'BloomVia',
    'BloomUntracked',
    'BloomSignal',

    // 4. Terminals & Boundary Sinks
    'RawTerminal',
    'RawBloomTerminal',
    'RawViaTerminal',
    'RawComputedTerminal',

    // 5. Effect Domain
    'Effect',
    'EffectScope',
    'EffectRunner',

    // 6. Flutter UI & Widgets
    'BloomWidget',
    'BloomVsyncWidget',
    'BloomAnimatedWidget',
    'BloomListener',

    // 7. Durable Animation Controllers
    'FrozenAnimationController',
    'CatchUpAnimationController',
    'DurableAnimationController',
    'ScopedAnimationController',
  };

  /// Core animation types declared in blooming_flutter.
  static const _coreAnimationTypes = {
    'FrozenAnimationController',
    'CatchUpAnimationController',
    'DurableAnimationController',
    'ScopedAnimationController',
  };

  // ===========================================================================
  // Bloom Type & Target Checks
  // ===========================================================================

  /// Returns `true` if the [type] is a Bloom ecosystem type.
  static bool isBloomType(DartType? type) {
    if (type == null) return false;
    if (type is DynamicType || type is InvalidType) return false;

    // Check RecordType fields recursively
    if (type is RecordType) {
      return type.positionalFields.any((f) => isBloomType(f.type)) ||
          type.namedFields.any((f) => isBloomType(f.type));
    }

    final element = type.element;
    if (element == null) return false;

    final typeName = element.name ?? '';
    if (_bloomTypes.contains(typeName)) {
      return true;
    }

    // Check supertypes/interfaces (e.g. custom classes implementing Bloom / BloomState)
    if (type is InterfaceType) {
      for (final superType in type.allSupertypes) {
        final superName = superType.element.name;
        if (_bloomTypes.contains(superName)) {
          return true;
        }
      }
    }

    if (isFromBloomPackage(element)) {
      return typeName.contains('Entry') || typeName.contains('Functor');
    }

    return false;
  }

  /// Returns `true` if the [expr] represents a verified Bloom target node
  /// based on Analyzer static type analysis, with syntax fallback for unresolved ASTs.
  static bool isBloomTarget(Expression? expr) {
    if (expr == null) return false;
    final staticType = expr.staticType;
    if (staticType != null &&
        staticType is! DynamicType &&
        staticType is! InvalidType) {
      return isBloomType(staticType);
    }
    // Strict identifier naming fallback for unresolved ASTs in standalone unit tests
    if (expr is SimpleIdentifier) {
      final name = expr.name;
      return name == 'bloom' || name.endsWith('Bloom');
    }
    return false;
  }

  /// Returns `true` if the [type] is or implements `Bloom`.
  static bool isBloomClass(DartType? type) => _isBloomClass(type, 'Bloom');

  /// Returns `true` if the [type] is or implements `BloomState`.
  static bool isBloomStateClass(DartType? type) =>
      _isBloomClass(type, 'BloomState');

  /// Returns `true` if the [expr] represents a verified trackable source for `via`
  /// (e.g. `Bloom`, `BloomState`, `BloomController`, `RawBloomTerminal`, `BloomCoupler`).
  static bool isTrackableBloomTarget(Expression? expr) {
    if (expr == null) return false;
    final unwrapped = expr.unParenthesized;
    final staticType = unwrapped.staticType;
    if (staticType != null &&
        staticType is! DynamicType &&
        staticType is! InvalidType) {
      return _isBloomClass(staticType, 'Bloom') ||
          _isBloomClass(staticType, 'BloomState') ||
          _isBloomClass(staticType, 'BloomController') ||
          _isBloomClass(staticType, 'RawBloomController') ||
          _isBloomClass(staticType, 'RawBloomTerminal') ||
          _isBloomClass(staticType, 'RawTerminal') ||
          _isBloomClass(staticType, 'BloomCoupler');
    }
    // Strict identifier naming fallback for unresolved ASTs
    if (unwrapped is SimpleIdentifier) {
      final name = unwrapped.name;
      return name == 'bloom' || name.endsWith('Bloom');
    }
    if (unwrapped is PropertyAccess) {
      final name = unwrapped.propertyName.name;
      return name == 'bloom' || name.endsWith('Bloom');
    }
    if (unwrapped is PrefixedIdentifier) {
      final name = unwrapped.identifier.name;
      return name == 'bloom' || name.endsWith('Bloom');
    }
    if (unwrapped is MethodInvocation) {
      final name = unwrapped.methodName.name;
      return name == 'bloomOf' ||
          name == 'maybeBloomOf' ||
          name == 'bloom' ||
          name.endsWith('Bloom');
    }
    return false;
  }

  /// Stateful Bloom producer controller and coupler types.
  static const _coreControllerTypes = {
    'BloomController',
    'RawBloomController',
    'BloomDraftController',
    'BloomCoupler',
    'BloomSignalController',
  };

  /// Returns `true` if the [typeName] is a stateful controller or coupler type.
  static bool isControllerOrCouplerType(String? typeName) {
    if (typeName == null) return false;
    return _coreControllerTypes.contains(typeName);
  }

  /// Returns `true` if the [type] is a Bloom animation controller type.
  static bool isBloomAnimationController(DartType? type) {
    if (type == null) return false;
    final element = type.element;
    if (element == null) return false;

    final typeName = element.name ?? '';
    return _coreAnimationTypes.contains(typeName);
  }

  /// Returns `true` if the [type] represents `ScopedAnimationController`.
  static bool isScopedAnimationController(DartType? type) {
    if (type == null) return false;
    return _isBloomClass(type, 'ScopedAnimationController');
  }

  // ===========================================================================
  // Reactive Bridging & Adapter Members
  // ===========================================================================

  /// Verified factory & extension methods that create reactive bridges
  /// (e.g. `stream.toBloom()`, `listenable.toBloomBy(...)`, `bloom.toListenable()`).
  static const _reactiveBridgingMethods = {
    'toBloom',
    'toBloomBy',
    'toBloomTuple',
    'toBloomTriple',
    'toListenable',
  };

  /// Verified adapter getters (empty in modern Bloom: all bridges are explicit methods).
  static const Set<String> _reactiveBridgingProperties = {};

  /// Returns `true` if the given method [name] represents a reactive bridging factory method.
  static bool isReactiveBridgingMethod(String? name) {
    if (name == null) return false;
    return _reactiveBridgingMethods.contains(name);
  }

  /// Returns `true` if the given property [name] represents a reactive adapter getter.
  static bool isReactiveBridgingProperty(String? name) {
    if (name == null) return false;
    return _reactiveBridgingProperties.contains(name);
  }

  // ===========================================================================
  // 1. Pipeline Read (Payload Extraction) Members
  // ===========================================================================

  /// Verified member properties that read reactive node payload on `BloomState`.
  static const _pipelineReadProperties = {
    'phase',
    'data',
    'dataOrNull',
    'snapshot',
    'hasData',
    'isEmpty',
    'emptyReason',
    'hasError',
    'error',
    'stackTrace',
  };

  /// Verified member methods that evaluate and read reactive node payload on `BloomState`.
  static const _pipelineReadMethods = {
    'dataOrElse',
  };

  /// Returns `true` if the given property [name] represents a reactive payload extraction getter.
  static bool isPipelineReadProperty(String? name) {
    if (name == null) return false;
    return _pipelineReadProperties.contains(name);
  }

  /// Returns `true` if the given method [name] represents a reactive payload extraction method.
  static bool isPipelineReadMethod(String? name) {
    if (name == null) return false;
    return _pipelineReadMethods.contains(name);
  }

  // ===========================================================================
  // 2. Pipeline Write (State & Topology Mutation) Members
  // ===========================================================================

  /// Verified member methods that write state or modify reactive graph topology.
  static const _pipelineWriteMethods = {
    // 1. Controller state writes
    'set',
    'setGuarded',
    'setError',
    'empty',
    'markDirty',

    // 2. Collection controller transactional draft edits
    'edit',
    'editGuarded',

    // 3. Coupler dynamic socket coupling
    'couple',
    'coupleGuarded',
    'decouple',
    'tryDecoupling',
  };

  /// Verified member properties whose setters write state or modify topology.
  static const _pipelineWriteProperties = {
    'data',
  };

  /// Returns `true` if the given method [name] represents a state-writing or topology-modifying method.
  static bool isPipelineWriteMethod(String? name) {
    if (name == null) return false;
    return _pipelineWriteMethods.contains(name);
  }

  /// Returns `true` if the given property [name] represents a state-writing or topology-modifying setter.
  static bool isPipelineWriteProperty(String? name) {
    if (name == null) return false;
    return _pipelineWriteProperties.contains(name);
  }

  // ===========================================================================
  // 3. Pipeline Evaluation (Transformation & UI) Members
  // ===========================================================================

  /// Verified pipeline evaluation methods where synchronous writes cause reentrancy errors.
  static const _pipelineEvaluationMethods = {
    // 1. Core Bloom transformation & derivation functors
    'computed',
    'switched',
    'managed',
    'distinct',
    'effect',

    // 2. Blooming Flutter UI render & listener functors
    'build',
    'drive',
    'animate',
    'match',
    'when',
    'listen',
  };

  /// Returns `true` if the given method [name] represents a pipeline evaluation or transform method.
  static bool isPipelineEvaluationMethod(String? name) {
    if (name == null) return false;
    return _pipelineEvaluationMethods.contains(name);
  }

  /// Returns `true` if the [node] represents an active Bloom pipeline evaluation invocation
  /// (e.g. `computed(...)`, `composed(...)`, `switched(...)`, `managed(...)`, `bloom.build(...)`).
  ///
  /// **Core Safety Philosophy:**
  /// Executing state writes (`controller.set()`, `controller.data = ...`) synchronously inside
  /// any Bloom pipeline invocation triggers a reentrancy error or infinite loop.
  static bool isBloomPipelineInvocation(AstNode node) {
    if (node is FunctionExpressionInvocation) {
      final function = node.function;
      final funcName =
          function is SimpleIdentifier ? function.name : function.toSource();
      if (funcName == 'composed' ||
          funcName == 'computed' ||
          funcName == 'switched' ||
          funcName == 'managed' ||
          funcName == 'effect') {
        final element = function is SimpleIdentifier ? function.element : null;
        if (element == null) return true;
        return isFromBloomPackage(element);
      }
      return false;
    }

    if (node is! MethodInvocation) return false;

    final name = node.methodName.name;

    // 1. Top-level functors: composed(), computed(), switched(), managed(), effect()
    if ((name == 'composed' ||
            name == 'computed' ||
            name == 'switched' ||
            name == 'managed' ||
            name == 'effect') &&
        node.target == null) {
      final element = node.methodName.element;
      if (element == null) return true;
      return isFromBloomPackage(element);
    }

    // 2. Bloom pipeline transformation and UI render methods
    if (_pipelineEvaluationMethods.contains(name)) {
      final target = node.realTarget;
      if (target == null) return true;

      final targetType = target.staticType;
      if (targetType == null) return false;

      // 2.1. Record tuple functor: (bloomA, bloomB).effect(...)
      if (targetType is RecordType) return true;

      // 2.2. Bloom reactive state node methods: bloom.distinct(...), bloom.build(...)
      if (isBloomType(targetType)) return true;

      // 2.3. Bloom Animation Controller functors: composed.animate(controller, ...)
      if (isBloomAnimationController(targetType)) return true;
    }

    return false;
  }

  /// Resolves the functor name for the given invocation callee expression.
  static String? resolveFunctorName(InvocationExpression node) {
    Expression callee;
    String sourceStr;

    if (node is MethodInvocation) {
      callee = node.methodName;
      sourceStr = node.target != null
          ? '${node.target!.toSource()}.${node.methodName.name}'
          : node.methodName.name;
    } else if (node is FunctionExpressionInvocation) {
      callee = node.function;
      sourceStr = callee.toSource();
    } else {
      return null;
    }

    final type = callee.staticType;
    if (type is InterfaceType) {
      final name = type.element.name;
      if (name != null &&
          name.endsWith('Functor') &&
          isFromBloomPackage(type.element)) {
        return name;
      }
    }

    if (node is MethodInvocation && node.target != null) {
      final targetType = node.target!.staticType;
      if (targetType is InterfaceType) {
        final name = targetType.element.name;
        if (name != null &&
            name.endsWith('Functor') &&
            isFromBloomPackage(targetType.element)) {
          if (name == 'ComputedFunctor' && node.methodName.name == 'future') {
            return 'ComputedFutureFunctor';
          }
          if (name == 'ComputedFunctor' && node.methodName.name == 'stream') {
            return 'ComputedStreamFunctor';
          }
          if (name.startsWith('Composed') && node.methodName.name == 'child') {
            return 'ComposedChildFunctor';
          }
          if (name.startsWith('Composed') &&
              node.methodName.name == 'children') {
            return 'ComposedChildrenFunctor';
          }
          if (name == 'ComposedFunctor' && node.methodName.name == 'context') {
            return 'ComposedContextFunctor';
          }
          if (name == 'ComposedFunctor' && node.methodName.name == 'vsync') {
            return 'ComposedVsyncFunctor';
          }
          if (name == 'ComposedFunctor' && node.methodName.name == 'drive') {
            return 'ComposedDriveFunctor';
          }
          if (name == 'ComposedFunctor' && node.methodName.name == 'animate') {
            return 'ComposedAnimateFunctor';
          }
          return name;
        }
      }
    }

    // Unresolved fallback
    if (sourceStr == 'computed') return 'ComputedFunctor';
    if (sourceStr == 'computed.future' || sourceStr == 'computed.async') {
      return 'ComputedFutureFunctor';
    }
    if (sourceStr == 'computed.stream') return 'ComputedStreamFunctor';
    if (sourceStr == 'switched') return 'SwitchedFunctor';
    if (sourceStr == 'managed' || sourceStr == 'Bloom.managed') {
      return 'ManagedFunctor';
    }
    if (sourceStr == 'composed') return 'ComposedFunctor';
    if (sourceStr.startsWith('composed.') && sourceStr.endsWith('.child')) {
      return 'ComposedChildFunctor';
    }
    if (sourceStr.startsWith('composed.') && sourceStr.endsWith('.children')) {
      return 'ComposedChildrenFunctor';
    }
    if (sourceStr == 'composed.context') return 'ComposedContextFunctor';
    if (sourceStr == 'composed.vsync') return 'ComposedVsyncFunctor';
    if (sourceStr == 'composed.drive') return 'ComposedDriveFunctor';
    if (sourceStr == 'composed.animate') return 'ComposedAnimateFunctor';
    if (sourceStr == 'composed.child') return 'ComposedChildFunctor';
    if (sourceStr == 'composed.children') return 'ComposedChildrenFunctor';
    return null;
  }

  // ===========================================================================
  // 4. BloomVia AST Manifest Helpers
  // ===========================================================================

  /// Returns `true` if the parameter represents a `BloomVia` dependency manifest handle.
  static bool isBloomViaParameter(FormalParameter param) {
    final element = param.declaredFragment?.element;
    if (element != null) {
      final type = element.type;
      if (type is! DynamicType && type is! InvalidType) {
        return _isBloomClass(type, 'BloomVia');
      }
    }

    final name = param.name?.lexeme;
    if (name == 'via') return true;

    if (param is SimpleFormalParameter) {
      final typeStr = param.type?.toSource();
      if (typeStr == 'BloomVia' || typeStr == 'BloomVia?') return true;
    }
    return false;
  }

  /// Returns `true` if the invocation represents a call to `via(bloom)`, `via.state(bloom)`, `via.tether(effect)`, or `via.of(context)` / `via.maybeOf(context)`.
  static bool isBloomViaInvocation(AstNode? node) {
    if (node == null) return false;

    // 1. Check for `via.of(...)`, `via.maybeOf(...)`, `via.state(...)`, `via.tether(...)`
    if (node is MethodInvocation) {
      final methodName = node.methodName.name;
      if (methodName == 'of' ||
          methodName == 'maybeOf' ||
          methodName == 'state' ||
          methodName == 'tether') {
        final target = node.target;
        if (target != null) {
          final targetType = target.staticType;
          if (targetType != null &&
              targetType is! DynamicType &&
              targetType is! InvalidType) {
            if (_isBloomClass(targetType, 'BloomVia')) {
              return true;
            }
          }
          if (target is SimpleIdentifier && target.name == 'via') {
            return true;
          }
        }
      }
    }

    Expression? function;
    if (node is MethodInvocation) {
      function = node.methodName;
    } else if (node is FunctionExpressionInvocation) {
      function = node.function;
    }

    if (function != null) {
      final staticType = function.staticType;
      if (staticType != null &&
          staticType is! DynamicType &&
          staticType is! InvalidType) {
        return _isBloomClass(staticType, 'BloomVia');
      }
    }

    if (node is MethodInvocation) {
      return node.methodName.name == 'via' && node.target == null;
    }
    if (node is FunctionExpressionInvocation) {
      final func = node.function;
      if (func is SimpleIdentifier && func.name == 'via') {
        return true;
      }
    }
    return false;
  }

  /// Returns `true` if the invocation represents a call to `untracked(bloom)` or `untracked.state(bloom)`.
  static bool isBloomUntrackedInvocation(AstNode? node) {
    if (node == null) return false;

    // 1. Check for `untracked.state(...)`
    if (node is MethodInvocation) {
      final methodName = node.methodName.name;
      if (methodName == 'state') {
        final target = node.target;
        if (target != null) {
          final targetType = target.staticType;
          if (targetType != null &&
              targetType is! DynamicType &&
              targetType is! InvalidType) {
            if (_isBloomClass(targetType, 'BloomUntracked')) {
              return true;
            }
          }
          if (target is SimpleIdentifier && target.name == 'untracked') {
            return true;
          }
        }
      }
    }

    // 2. Check for `untracked(...)`
    Expression? function;
    if (node is MethodInvocation) {
      function = node.methodName;
    } else if (node is FunctionExpressionInvocation) {
      function = node.function;
    }

    if (function != null) {
      final staticType = function.staticType;
      if (staticType != null &&
          staticType is! DynamicType &&
          staticType is! InvalidType) {
        if (_isBloomClass(staticType, 'BloomUntracked')) {
          return true;
        }
      }
    }

    if (node is MethodInvocation) {
      return node.methodName.name == 'untracked' && node.target == null;
    }
    if (node is FunctionExpressionInvocation) {
      final func = node.function;
      if (func is SimpleIdentifier && func.name == 'untracked') {
        return true;
      }
    }
    return false;
  }

  /// Returns `true` if the [expr] represents a `BloomVia` target expression.
  static bool isBloomViaTarget(Expression? expr) {
    if (expr == null) return false;
    final unwrapped = expr.unParenthesized;
    final staticType = unwrapped.staticType;
    if (staticType != null &&
        staticType is! DynamicType &&
        staticType is! InvalidType) {
      if (_isBloomClass(staticType, 'BloomVia')) return true;
    }
    if (unwrapped is SimpleIdentifier && unwrapped.name == 'via') {
      return true;
    }
    return false;
  }

  /// Returns `true` if the method declaration matches `BloomWidget.build(BuildContext context, BloomVia via)`.
  static bool isBloomWidgetBuildMethod(MethodDeclaration method) {
    if (method.name.lexeme != 'build') return false;
    final params = method.parameters?.parameters;
    if (params == null || params.length < 2) return false;

    // Check if second parameter is BloomVia
    return isBloomViaParameter(params[1]);
  }

  /// Returns `true` if the [node] is physically enclosed inside a `BloomVia` manifest scope
  /// (`BloomWidget.build`, `computed`, `composed`, `switched`, `Effect`, or closure with `via` parameter).
  static bool isInsideBloomViaScope(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      // 1. BloomWidget.build(context, via)
      if (current is MethodDeclaration && isBloomWidgetBuildMethod(current)) {
        return true;
      }

      // 4. Closures with a parameter typed 'BloomVia' or named 'via'
      if (current is FunctionExpression) {
        final params = current.parameters?.parameters;
        if (params != null && params.any(isBloomViaParameter)) {
          return true;
        }
      }

      current = current.parent;
    }
    return false;
  }

  // ===========================================================================
  // Callback & Dispatcher AST Patterns
  // ===========================================================================

  /// Checks if the parameter name corresponds to an event callback (e.g. onPressed, onTap).
  static bool isEventCallbackParameter(String name) {
    return name.startsWith(
            'on') || // onPressed, onTap, onChanged, onSubmitted, etc.
        name == 'listener' ||
        name == 'callback' ||
        name == 'action';
  }

  static const _terminalCallbackMethods = {
    'effect',
    'scoped',
    'handled',
    'throttle',
    'debounce',
  };

  static const _terminalConstructors = {
    'Effect',
    'ThrottleEffect',
    'DebounceEffect',
    'EffectRunner',
    'BloomListener',
  };

  /// Returns `true` if the [node] represents an invocation or instantiation of a reactive terminal, effect, or listener.
  static bool isTerminalOrEffectInvocation(AstNode node) {
    if (node is MethodInvocation) {
      if (_terminalCallbackMethods.contains(node.methodName.name)) {
        return true;
      }
    }
    if (node is FunctionExpressionInvocation) {
      final func = node.function;
      String? name;
      if (func is SimpleIdentifier) {
        name = func.name;
      } else if (func is PrefixedIdentifier) {
        name = func.identifier.name;
      } else if (func is PropertyAccess) {
        name = func.propertyName.name;
      }
      if (name != null && _terminalCallbackMethods.contains(name)) {
        return true;
      }
    }
    if (node is InstanceCreationExpression) {
      final typeName = node.constructorName.type.name.lexeme;
      if (_terminalConstructors.contains(typeName)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if the [node] represents an asynchronous timer or dispatcher invocation
  /// (e.g., Timer.run, scheduleMicrotask, Future.microtask, future.then).
  static bool isAsyncOrTimerInvocation(MethodInvocation node) {
    final name = node.methodName.name;

    // Top-level async dispatcher in dart:async
    if (name == 'scheduleMicrotask') {
      return true;
    }

    final target = node.target;
    if (target != null) {
      final targetSource = target.toSource();
      // Only accept 'run' if called on Timer (e.g. Timer.run or async.Timer.run)
      if (name == 'run' && targetSource.endsWith('Timer')) {
        return true;
      }
      // Delayed invocations: Future.delayed or Timer.delayed
      if (name == 'delayed' &&
          (targetSource.endsWith('Future') || targetSource.endsWith('Timer'))) {
        return true;
      }
      // Microtask invocation: Future.microtask
      if (name == 'microtask' && targetSource.endsWith('Future')) {
        return true;
      }
      // Future chaining: future.then, future.catchError, future.whenComplete
      if (name == 'then' || name == 'catchError' || name == 'whenComplete') {
        final targetType = target.staticType;
        if (targetType == null ||
            targetType is DynamicType ||
            targetType is InvalidType) {
          // Fallback for unresolved ASTs or dynamic receivers
          return true;
        }
        final elementName = targetType.element?.name;
        if (elementName == 'Future' ||
            elementName == 'FutureOr' ||
            elementName == 'Completer') {
          return true;
        }
        if (targetType is InterfaceType) {
          return targetType.allSupertypes
              .any((t) => t.element.name == 'Future');
        }
        return false;
      }
    }

    return false;
  }
}

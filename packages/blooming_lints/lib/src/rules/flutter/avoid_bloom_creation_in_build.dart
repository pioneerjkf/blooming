// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../blooming_lints.dart';

/// A lint rule prohibiting instantiating Bloom controllers, signals, effects, or reactive pipelines
/// directly inside Flutter `build()` methods.
///
/// ### Rationale:
/// Flutter `build()` methods are called repeatedly during animations, parent updates, and state mutations.
/// Instantiating controllers (`BloomController`), reactive pipelines (`computed`, `managed`, `switched`),
/// or side-effect terminals (`Effect`) directly inside `build()` causes:
/// 1. State reset on every single rebuild tick (loss of previous state).
/// 2. Severe memory leaks through dangling controllers and uncollected DAG nodes.
///
/// **BAD:**
/// ```dart
/// Widget build(BuildContext context) {
///   final counter = blooming(0); // [Anti-Pattern] Recreated on every frame!
///   final doubled = computed((via) => via(counter.bloom) * 2); // [Anti-Pattern] Orphan pipeline node!
///   return Text('${untracked(doubled)}');
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// class MyWidget extends StatefulWidget {
///   const MyWidget({super.key});
///
///   @override
///   State<MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<MyWidget> {
///   late final BloomController<int> _counter;
///   late final Bloom<int> _doubled;
///
///   @override
///   void initState() {
///     super.initState();
///     _counter = blooming(0);
///     _doubled = computed((via) => via(_counter.bloom) * 2);
///   }
///
///   // Note: Pure BloomController instances are subscriber-driven and automatically
///   // collected by GC upon deactivation; manual disposal is not required.
///
///   @override
///   Widget build(BuildContext context) {
///     return composed((context, via) => Text('Count: ${via(_doubled)}'));
///   }
/// }
/// ```
class AvoidBloomCreationInBuild extends AnalysisRule {
  AvoidBloomCreationInBuild()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'avoid_bloom_creation_in_build',
    'Avoid instantiating Bloom controllers, signals, or reactive pipelines inside Flutter build() methods.',
    correctionMessage:
        'Move controller and pipeline instantiation to State.initState, top-level/static declarations, or DI scopes.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _AvoidBloomCreationInBuildVisitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
    registry.addFunctionExpressionInvocation(this, visitor);
  }

  static const _controllerAndTerminalConstructors = {
    'BloomController',
    'RawBloomController',
    'BloomDraftController',
    'BloomCollectionController',
    'BloomCoupler',
    'BloomSignal',
    'BloomSignalController',
    'Effect',
    'EffectRunner',
  };

  static const _forbiddenPipelineFunctors = {
    'blooming',
    'computed',
    'switched',
    'managed',
    'effect',
  };

  /// Returns `true` if [node] calls a forbidden pipeline functor via FunctionExpressionInvocation.
  static bool isForbiddenFunctionExpressionInvocation(
    FunctionExpressionInvocation node,
  ) {
    final function = node.function;
    final name = function is SimpleIdentifier
        ? function.name
        : function.toSource();
    return _forbiddenPipelineFunctors.contains(name) ||
        _controllerAndTerminalConstructors.contains(name) ||
        name.startsWith('blooming.') ||
        name.startsWith('computed.');
  }

  /// Returns `true` if [node] creates a forbidden controller, coupler, signal, or terminal.
  static bool isForbiddenCreation(InstanceCreationExpression node) {
    final typeName = node.constructorName.type.name.lexeme;
    return _controllerAndTerminalConstructors.contains(typeName);
  }

  /// Returns `true` if [node] calls a forbidden pipeline functor or factory constructor inside build.
  static bool isForbiddenMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (_forbiddenPipelineFunctors.contains(name) ||
        _controllerAndTerminalConstructors.contains(name)) {
      final target = node.target;
      if (target == null) return true;
      if (target is SimpleIdentifier && target.name == 'Bloom') return true;
    }
    final target = node.target;
    if (target is SimpleIdentifier && target.name == 'blooming') {
      return true;
    }
    if (target is SimpleIdentifier && target.name == 'computed') {
      if (name == 'future' || name == 'stream' || name == 'async') {
        return true;
      }
    }
    return false;
  }
}

class _AvoidBloomCreationInBuildVisitor extends SimpleAstVisitor<void> {
  _AvoidBloomCreationInBuildVisitor(this.rule);
  final AvoidBloomCreationInBuild rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!AvoidBloomCreationInBuild.isForbiddenCreation(node)) return;
    if (!FlutterAstUtils.isInsideBuildMethod(node)) return;
    if (AvoidStateWritesInPipeline.isInsideEventOrDeferredClosure(node)) {
      return;
    }

    rule.reportAtNode(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!AvoidBloomCreationInBuild.isForbiddenMethodInvocation(node)) return;
    if (!FlutterAstUtils.isInsideBuildMethod(node)) return;
    if (AvoidStateWritesInPipeline.isInsideEventOrDeferredClosure(node)) {
      return;
    }

    rule.reportAtNode(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (!AvoidBloomCreationInBuild.isForbiddenFunctionExpressionInvocation(
      node,
    )) {
      return;
    }
    if (!FlutterAstUtils.isInsideBuildMethod(node)) return;
    if (AvoidStateWritesInPipeline.isInsideEventOrDeferredClosure(node)) {
      return;
    }

    rule.reportAtNode(node);
  }
}

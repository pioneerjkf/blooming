// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../blooming_lints.dart';

/// A lint rule prohibiting synchronous state writes or topology modifications inside reactive pipelines and build passes.
///
/// ### Rationale:
/// In reactive DAG architectures, evaluation passes (`computed`, `switched`, `managed`, `composed`, Flutter `build`)
/// must remain side-effect-free.
///
/// Performing state writes (`controller.set()`, `controller.data = ...`) or topological mutations
/// synchronously inside evaluation passes causes immediate reentrancy errors or infinite render loops.
///
/// **BAD:**
/// ```dart
/// Widget build(BuildContext context) {
///   counterController.set(10); // [Anti-Pattern] Synchronous state write during build!
///   return const SizedBox();
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// Widget build(BuildContext context) {
///   return ElevatedButton(
///     onPressed: () => counterController.set(10), // [Recommended] Safe asynchronous event handler
///     child: const Text('Reset'),
///   );
/// }
/// ```
class AvoidStateWritesInPipeline extends AnalysisRule {
  AvoidStateWritesInPipeline()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'avoid_state_writes_in_pipeline',
    'Avoid writing state or modifying graph topology directly inside reactive pipeline evaluation or build scopes.',
    correctionMessage:
        'Perform state writes inside event handlers (e.g. onPressed), async dispatchers, or lifecycle hooks.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _AvoidStateWritesInPipelineVisitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addAssignmentExpression(this, visitor);
  }

  static String? _extractPropertyName(Expression leftHandSide) {
    if (leftHandSide is PropertyAccess) {
      return leftHandSide.propertyName.name;
    }
    if (leftHandSide is PrefixedIdentifier) {
      return leftHandSide.identifier.name;
    }
    return null;
  }

  /// Checks if the [node] is inside a pipeline method or a Flutter widget build method.
  static bool isInsidePipelineMethod(AstNode node) =>
      FlutterAstUtils.isInsidePipelineOrBuild(node);

  /// Checks if the [node] is deferred inside an event handler or asynchronous closure.
  static bool isInsideEventOrDeferredClosure(AstNode node) =>
      FlutterAstUtils.isInsideEventOrDeferredClosure(node);

  /// Returns `true` if the method invocation [node] targets a Bloom package element or trackable Bloom target.
  static bool isFromBloomPackageOrTarget(MethodInvocation node) {
    final element = node.methodName.element;
    if (element != null && BloomTypeChecker.isFromBloomPackage(element)) {
      return true;
    }
    final target = node.realTarget;
    if (target != null && BloomTypeChecker.isTrackableBloomTarget(target)) {
      return true;
    }
    // Unresolved fallback
    if (element == null && target?.staticType == null) {
      return true;
    }
    return false;
  }

  /// Returns `true` if the assignment [node] targets a Bloom property.
  static bool isAssignmentToBloomProperty(AssignmentExpression node) {
    final lhs = node.leftHandSide;
    Element? element;
    Expression? target;
    if (lhs is PropertyAccess) {
      element = lhs.propertyName.element;
      target = lhs.target;
    } else if (lhs is PrefixedIdentifier) {
      element = lhs.identifier.element;
      target = lhs.prefix;
    }

    if (element != null && BloomTypeChecker.isFromBloomPackage(element)) {
      return true;
    }
    if (target != null && BloomTypeChecker.isTrackableBloomTarget(target)) {
      return true;
    }
    // Unresolved fallback
    if (element == null && target?.staticType == null) {
      return true;
    }
    return false;
  }
}

class _AvoidStateWritesInPipelineVisitor extends SimpleAstVisitor<void> {
  _AvoidStateWritesInPipelineVisitor(this.rule);
  final AvoidStateWritesInPipeline rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (BloomTypeChecker.isPipelineWriteMethod(node.methodName.name)) {
      if (!AvoidStateWritesInPipeline.isFromBloomPackageOrTarget(node)) return;
      if (!AvoidStateWritesInPipeline.isInsidePipelineMethod(node)) return;
      if (AvoidStateWritesInPipeline.isInsideEventOrDeferredClosure(node)) {
        return;
      }

      rule.reportAtNode(node);
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final propName = AvoidStateWritesInPipeline._extractPropertyName(
      node.leftHandSide,
    );
    if (BloomTypeChecker.isPipelineWriteProperty(propName)) {
      if (!AvoidStateWritesInPipeline.isAssignmentToBloomProperty(node)) return;
      if (!AvoidStateWritesInPipeline.isInsidePipelineMethod(node)) return;
      if (AvoidStateWritesInPipeline.isInsideEventOrDeferredClosure(node)) {
        return;
      }

      rule.reportAtNode(node);
    }
  }
}

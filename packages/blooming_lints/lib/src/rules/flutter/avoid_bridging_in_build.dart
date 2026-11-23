// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../blooming_lints.dart';

/// A lint rule that discourages calling reactive bridging methods (`.toBloom()`, `.toBloomBy()`, etc.)
/// directly inside Flutter `build()` methods or reactive derivation scopes (`computed`, `composed`).
///
/// ### Rationale:
/// In Flutter's rendering pipeline and Bloom's reactive graph, `build()` methods and derivation
/// scopes can execute up to 120 times per second during active animations or updates.
/// Calling bridging methods like `.toBloom()` inside these scopes creates new reactive
/// pipelines on every single tick, causing GC thrashing and broken subscription caching.
///
/// **BAD:**
/// ```dart
/// Widget build(BuildContext context) {
///   final countBloom = valueNotifier.toBloom(); // [Anti-Pattern] New bridge allocation on every frame!
///   return Text('${untracked(countBloom)}');
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // Approach 1: Convert notifier/stream to Bloom once in a State class
/// class _MyWidgetState extends State<MyWidget> {
///   late final Bloom<int> _countBloom = widget.valueNotifier.toBloom();
///
///   Widget build(BuildContext context) =>
///       composed((context, via) => Text('${via(_countBloom)}'));
/// }
///
/// // Approach 2: Convert notifier/stream to Bloom once at the state/controller layer
/// class StockController {
///   late final stockBloom = stockStream.toBloom(initialData: 0.0);
/// }
/// ```
class AvoidBridgingInBuild extends AnalysisRule {
  AvoidBridgingInBuild()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'avoid_bridging_in_build',
    'Avoid calling reactive bridging methods or adapters (\'{0}\') inside build methods or reactive scopes.',
    correctionMessage:
        'Cache the bridged reactive node in a `late final` field on the Widget or outside the evaluation scope to avoid allocations.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _AvoidBridgingInBuildVisitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addPropertyAccess(this, visitor);
    registry.addPrefixedIdentifier(this, visitor);
  }

  /// Checks if the AST [node] is located within a Flutter `build()` method or a reactive derivation scope
  /// (excluding deferred event handlers or async callbacks).
  static bool isInsideBuildOrReactiveScope(AstNode node) {
    if (FlutterAstUtils.isInsideEventOrDeferredClosure(node)) return false;
    if (FlutterAstUtils.isInsideBuildMethod(node)) return true;
    if (BloomTypeChecker.isInsideBloomViaScope(node)) return true;
    return false;
  }
}

class _AvoidBridgingInBuildVisitor extends SimpleAstVisitor<void> {
  _AvoidBridgingInBuildVisitor(this.rule);
  final AvoidBridgingInBuild rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (BloomTypeChecker.isReactiveBridgingMethod(methodName)) {
      final element = node.methodName.element;
      if (element != null && !BloomTypeChecker.isFromBloomPackage(element)) {
        return;
      }
      if (AvoidBridgingInBuild.isInsideBuildOrReactiveScope(node)) {
        rule.reportAtNode(node, arguments: [methodName]);
      }
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final propName = node.propertyName.name;
    if (BloomTypeChecker.isReactiveBridgingProperty(propName)) {
      if (AvoidBridgingInBuild.isInsideBuildOrReactiveScope(node)) {
        rule.reportAtNode(node, arguments: [propName]);
      }
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    final propName = node.identifier.name;
    if (BloomTypeChecker.isReactiveBridgingProperty(propName)) {
      if (AvoidBridgingInBuild.isInsideBuildOrReactiveScope(node)) {
        rule.reportAtNode(node, arguments: [propName]);
      }
    }
  }
}

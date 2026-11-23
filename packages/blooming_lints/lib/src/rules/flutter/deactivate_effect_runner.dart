// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../blooming_lints.dart';

/// A lint rule ensuring `EffectRunner` instances held in `State` classes are explicitly stopped in `dispose()`.
///
/// ### Rationale:
/// `EffectRunner` subscriptions hold strong listener references in upstream `Effect` and `Bloom` nodes.
/// Failing to call `runner.stop()` inside `State.dispose()` retains the unmounted `State` instance
/// and its associated BuildContext in memory, causing severe memory leaks.
///
/// **BAD:**
/// ```dart
/// class _MyState extends State<MyWidget> {
///   EffectRunner? _runner; // [Anti-Pattern] Never stopped in dispose!
///
///   @override
///   void initState() {
///     super.initState();
///     _runner = counterBloom.effect(() => print(untracked(counterBloom))).start();
///   }
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// class _MyState extends State<MyWidget> {
///   EffectRunner? _runner;
///
///   @override
///   void initState() {
///     super.initState();
///     _runner = counterBloom.effect(() => print(untracked(counterBloom))).start();
///   }
///
///   @override
///   void dispose() {
///     _runner?.stop(); // [Recommended] Explicitly stopped
///     super.dispose();
///   }
/// }
/// ```
class DeactivateEffectRunner extends AnalysisRule {
  DeactivateEffectRunner()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'deactivate_effect_runner',
    'The EffectRunner \'{0}\' must be stopped in State.dispose() to prevent memory leaks.',
    correctionMessage:
        'Call \'{0}?.stop();\' inside the dispose() method of this State class.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _DeactivateEffectRunnerVisitor(this));
  }

  /// Returns a list of field variable declarations holding an `EffectRunner` that are not deactivated in `dispose()`.
  static List<({String name, VariableDeclaration node})> findUncancelledRunners(
    ClassDeclaration clazz,
  ) {
    final runnerFields = <String, VariableDeclaration>{};

    for (final member in FlutterAstUtils.classMembers(clazz)) {
      if (member is FieldDeclaration) {
        final typeStr = member.fields.type?.toSource() ?? '';
        final hasRunnerAnnotation = BloomTypeChecker.matchesTypeNameBoundary(
          typeStr,
          const {'EffectRunner'},
        );

        for (final variable in member.fields.variables) {
          final inferredType = variable.declaredFragment?.element.type;
          final isRunner =
              hasRunnerAnnotation ||
              BloomTypeChecker.isEffectRunnerType(inferredType);
          if (isRunner) {
            runnerFields[variable.name.lexeme] = variable;
          }
        }
      }
    }

    if (runnerFields.isEmpty) return const [];

    // Find dispose() method
    MethodDeclaration? disposeMethod;
    for (final member in FlutterAstUtils.classMembers(clazz)) {
      if (member is MethodDeclaration && member.name.lexeme == 'dispose') {
        disposeMethod = member;
        break;
      }
    }

    // Collect all deactivated field names in dispose
    final deactivatedFields = <String>{};
    if (disposeMethod != null) {
      disposeMethod.visitChildren(
        _DeactivateInvocationVisitor((targetName) {
          deactivatedFields.add(targetName);
        }),
      );
    }

    final uncancelled = <({String name, VariableDeclaration node})>[];
    for (final entry in runnerFields.entries) {
      if (!deactivatedFields.contains(entry.key)) {
        uncancelled.add((name: entry.key, node: entry.value));
      }
    }

    return uncancelled;
  }
}

class _DeactivateEffectRunnerVisitor extends SimpleAstVisitor<void> {
  _DeactivateEffectRunnerVisitor(this.rule);
  final DeactivateEffectRunner rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!FlutterAstUtils.isStateClass(node)) return;

    final uncancelledRunners = DeactivateEffectRunner.findUncancelledRunners(
      node,
    );
    for (final entry in uncancelledRunners) {
      rule.reportAtNode(entry.node, arguments: [entry.name]);
    }
  }
}

class _DeactivateInvocationVisitor extends RecursiveAstVisitor<void> {
  _DeactivateInvocationVisitor(this.onFound);
  final void Function(String fieldName) onFound;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'deactivate' ||
        node.methodName.name == 'stop' ||
        node.methodName.name == 'cancel') {
      final target = node.target;
      if (target is SimpleIdentifier) {
        onFound(target.name);
      } else if (target is PropertyAccess) {
        onFound(target.propertyName.name);
      }
    }
    super.visitMethodInvocation(node);
  }
}

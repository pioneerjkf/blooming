// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../blooming_lints.dart';

/// A lint rule recommending passing read-only `Bloom<T>` instead of mutable `BloomController<T>` to widgets.
///
/// ### Rationale:
/// In accordance with the Bloom Engineering Constitution (Separation of Producer and Consumer),
/// `Bloom<T>` is the read-only, observation-only reactive interface, while `BloomController<T>` is the producer/manager handle.
/// Passing mutable controllers directly into consumer widgets breaks clean encapsulation, weakens unidirectional
/// data flow, and invites accidental state mutations inside presentation widgets.
///
/// **BAD:**
/// ```dart
/// class CounterDisplay extends StatelessWidget {
///   const CounterDisplay({super.key, required this.controller});
///   final BloomController<int> controller; // [Anti-Pattern] Exposes mutation methods to presentation widget!
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// class CounterDisplay extends StatelessWidget {
///   const CounterDisplay({super.key, required this.counter});
///   final Bloom<int> counter; // [Recommended] Clean read-only reactive interface
/// }
/// ```
class PreferBloomOverController extends AnalysisRule {
  PreferBloomOverController()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'prefer_bloom_over_controller',
    'Prefer accepting read-only Bloom<T> instead of mutable BloomController<T> in widget parameters.',
    correctionMessage:
        'Pass controller.bloom or declare the widget parameter as Bloom<T> to preserve Producer/Consumer encapsulation.',
    severity: DiagnosticSeverity.INFO,
  );

  static const _targetControllerTypes = {
    'BloomController',
    'RawBloomController',
    'BloomDraftController',
    'BloomCollectionController',
    'BloomCoupler',
    'BloomSignalController',
  };

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _PreferBloomOverControllerVisitor(this));
  }

  static bool _isWidgetClass(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause == null) return false;
    final supertype = extendsClause.superclass.name.lexeme;
    return supertype == 'StatelessWidget' ||
        supertype == 'StatefulWidget' ||
        supertype == 'BloomWidget' ||
        supertype == 'BloomVsyncWidget' ||
        supertype == 'BloomAnimatedWidget';
  }

  /// Returns the static or declared type string of [param] within the given [clazz].
  static String? getParameterTypeString(
    FormalParameter param,
    ClassDeclaration clazz,
  ) {
    if (param is RegularFormalParameter) {
      return param.type?.toSource();
    }
    if (param is FieldFormalParameter) {
      final explicitType = param.type?.toSource();
      if (explicitType != null) return explicitType;

      // Look up matching field declaration in class
      final paramName = param.name.lexeme;
      for (final member in FlutterAstUtils.classMembers(clazz)) {
        if (member is FieldDeclaration) {
          for (final variable in member.fields.variables) {
            if (variable.name.lexeme == paramName) {
              return member.fields.type?.toSource();
            }
          }
        }
      }
    }
    return null;
  }
}

class _PreferBloomOverControllerVisitor extends SimpleAstVisitor<void> {
  _PreferBloomOverControllerVisitor(this.rule);
  final PreferBloomOverController rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!PreferBloomOverController._isWidgetClass(node)) return;

    for (final member in FlutterAstUtils.classMembers(node)) {
      if (member is ConstructorDeclaration) {
        for (final param in member.parameters.parameters) {
          final paramType = param.declaredFragment?.element.type;
          if (paramType != null &&
              paramType is! DynamicType &&
              paramType is! InvalidType) {
            if (BloomTypeChecker.isControllerOrCouplerDartType(paramType) ||
                BloomTypeChecker.isBloomAnimationController(paramType)) {
              rule.reportAtNode(param);
            }
            continue;
          }
          final typeStr = PreferBloomOverController.getParameterTypeString(
            param,
            node,
          );
          if (typeStr != null &&
              BloomTypeChecker.matchesTypeNameBoundary(
                typeStr,
                PreferBloomOverController._targetControllerTypes,
              )) {
            rule.reportAtNode(param);
          }
        }
      }
    }
  }
}

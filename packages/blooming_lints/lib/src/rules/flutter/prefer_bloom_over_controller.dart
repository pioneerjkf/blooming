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
class PreferBloomOverController extends DartLintRule {
  PreferBloomOverController() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_bloom_over_controller',
    problemMessage:
        'Prefer accepting read-only Bloom<T> instead of mutable BloomController<T> in widget parameters.',
    correctionMessage:
        'Pass controller.bloom or declare the widget parameter as Bloom<T> to preserve Producer/Consumer encapsulation.',
    errorSeverity: DiagnosticSeverity.INFO,
  );

  static const _targetControllerTypes = {
    'BloomController',
    'RawBloomController',
    'BloomDraftController',
    'BloomCoupler',
  };

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!_isWidgetClass(node)) return;

      for (final member in node.members) {
        if (member is ConstructorDeclaration) {
          for (final param in member.parameters.parameters) {
            final typeStr = getParameterTypeString(param, node);
            if (typeStr != null &&
                _targetControllerTypes.any((t) => typeStr.startsWith(t))) {
              reporter.atNode(param, _code);
            }
          }
        }
      }
    });
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
      FormalParameter param, ClassDeclaration clazz) {
    final actualParam =
        param is DefaultFormalParameter ? param.parameter : param;
    if (actualParam is SimpleFormalParameter) {
      return actualParam.type?.toSource();
    }
    if (actualParam is FieldFormalParameter) {
      final explicitType = actualParam.type?.toSource();
      if (explicitType != null) return explicitType;

      // Look up matching field declaration in class
      final paramName = actualParam.name.lexeme;
      for (final member in clazz.members) {
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

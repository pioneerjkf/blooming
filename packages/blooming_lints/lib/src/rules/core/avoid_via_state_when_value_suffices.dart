// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../blooming_lints.dart';

/// A lint rule recommending `via(x)` over `via.state(x).data` when only the payload value is needed.
///
/// ### Rationale:
/// `via(x)` returns `T` directly and automatically short-circuits downstream evaluation if
/// upstream is Empty or Error, ensuring 0-alloc propagation and concise syntax.
///
/// Calling `via.state(x).data` redundantly queries the live `BloomState<T>` view only to extract
/// its `.data` payload, bypassing the concise value API.
///
/// **BAD:**
/// ```dart
/// final total = computed((via) => via.state(priceBloom).data * via.state(quantityBloom).data);
/// ```
///
/// **GOOD:**
/// ```dart
/// final total = computed((via) => via(priceBloom) * via(quantityBloom));
/// ```
class AvoidViaStateWhenValueSuffices extends AnalysisRule {
  AvoidViaStateWhenValueSuffices()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  static const code = LintCode(
    'avoid_via_state_when_value_suffices',
    'Use via(x) directly instead of via.state(x).data when only the value is needed.',
    correctionMessage:
        'Replace \'via.state(x).data\' with \'via(x)\' for zero-allocation and concise derivation.',
    severity: DiagnosticSeverity.INFO,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addPropertyAccess(
      this,
      _AvoidViaStateWhenValueSufficesVisitor(this),
    );
  }

  /// Returns `true` if the method invocation [node] represents a `via.state(...)` call.
  static bool isViaStateInvocation(MethodInvocation node) {
    if (node.methodName.name != 'state') return false;
    final target = node.target;
    return target != null && BloomTypeChecker.isBloomViaTarget(target);
  }
}

class _AvoidViaStateWhenValueSufficesVisitor extends SimpleAstVisitor<void> {
  _AvoidViaStateWhenValueSufficesVisitor(this.rule);
  final AvoidViaStateWhenValueSuffices rule;

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name != 'data') return;
    final target = node.target;
    if (target is MethodInvocation &&
        AvoidViaStateWhenValueSuffices.isViaStateInvocation(target)) {
      rule.reportAtNode(node);
    }
  }
}

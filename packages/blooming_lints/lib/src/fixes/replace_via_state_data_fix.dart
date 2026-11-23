// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

// ignore_for_file: deprecated_member_use

part of '../../blooming_lints.dart';

/// A quick fix that simplifies `via.state(x).data` to `via(x)`.
class ReplaceViaStateDataFix extends ResolvedCorrectionProducer {
  ReplaceViaStateDataFix({required super.context});

  static const _fixKind = FixKind(
    'blooming_lints.fix.replaceViaStateData',
    DartFixKindPriority.standard,
    'Simplify to via({0})',
  );

  String? _argSource;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  List<String>? get fixArguments => _argSource == null ? null : [_argSource!];

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final propertyAccess = node is PropertyAccess
        ? node as PropertyAccess
        : node.thisOrAncestorOfType<PropertyAccess>();
    if (propertyAccess == null || propertyAccess.propertyName.name != 'data') {
      return;
    }

    final target = propertyAccess.target;
    if (target is! MethodInvocation || target.methodName.name != 'state') {
      return;
    }

    final args = target.argumentList.arguments;
    if (args.isEmpty) return;

    final argSource = args.first.toSource();
    _argSource = argSource;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(propertyAccess),
        'via($argSource)',
      );
    });
  }
}

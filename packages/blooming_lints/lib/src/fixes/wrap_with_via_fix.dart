// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

// ignore_for_file: deprecated_member_use

part of '../../blooming_lints.dart';

/// A quick fix that wraps direct, untracked reactive reads with `via()` or `via.state()`.
class WrapWithViaFix extends ResolvedCorrectionProducer {
  WrapWithViaFix({required super.context});

  static const _fixKind = FixKind(
    'blooming_lints.fix.wrapWithVia',
    DartFixKindPriority.standard,
    '{0}',
  );

  String? _message;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  List<String>? get fixArguments => _message == null ? null : [_message!];

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final current = node;

    if (current is PropertyAccess) {
      await _handleProperty(
        builder,
        current.target,
        current.propertyName.name,
        current,
      );
      return;
    }
    if (current is PrefixedIdentifier) {
      await _handleProperty(
        builder,
        current.prefix,
        current.identifier.name,
        current,
      );
      return;
    }
    if (current is FunctionExpressionInvocation &&
        BloomTypeChecker.isBloomUntrackedInvocation(current)) {
      final args = current.argumentList.arguments;
      if (args.isNotEmpty) {
        final targetSource = args.first.toSource();
        _message = 'Replace untracked(...) with via(...)';
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(
            range.node(current),
            'via($targetSource)',
          );
        });
      }
      return;
    }
    if (current is MethodInvocation &&
        BloomTypeChecker.isBloomUntrackedInvocation(current)) {
      final args = current.argumentList.arguments;
      if (args.isNotEmpty) {
        final targetSource = args.first.toSource();
        final isState = current.methodName.name == 'state';
        final replacement = isState
            ? 'via.state($targetSource)'
            : 'via($targetSource)';
        _message = isState
            ? 'Replace untracked.state(...) with via.state(...)'
            : 'Replace untracked(...) with via(...)';
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(range.node(current), replacement);
        });
      }
    }
  }

  Future<void> _handleProperty(
    ChangeBuilder builder,
    Expression? target,
    String propName,
    Expression fullNode,
  ) async {
    if (target == null) return;

    final targetType = target.staticType;
    final isController = BloomTypeChecker.isControllerOrCouplerType(
      targetType?.element?.name,
    );

    if (propName == 'data') {
      _message = 'Wrap with via(...)';
      await builder.addDartFileEdit(file, (builder) {
        final targetSource = target.toSource();
        final replacement = isController
            ? 'via($targetSource.bloom)'
            : 'via($targetSource)';
        builder.addSimpleReplacement(range.node(fullNode), replacement);
      });
    } else if (BloomTypeChecker.isPipelineReadProperty(propName)) {
      _message = 'Wrap target with via.state(...)';
      await builder.addDartFileEdit(file, (builder) {
        final targetSource = target.toSource();
        final viaTarget = isController
            ? 'via.state($targetSource.bloom)'
            : 'via.state($targetSource)';
        final replacement = '$viaTarget.$propName';
        builder.addSimpleReplacement(range.node(fullNode), replacement);
      });
    }
  }
}

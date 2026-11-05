// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:blooming_lints/blooming_lints.dart';
import 'package:test/test.dart';

void main() {
  group('BloomTypeChecker', () {
    test('package URI identification for Bloom ecosystem packages', () {
      expect(
          BloomTypeChecker.isBloomPackageUri('package:blooming/blooming.dart'),
          isTrue);
      expect(
          BloomTypeChecker.isBloomPackageUri(
              'package:blooming_flutter/blooming_flutter.dart'),
          isTrue);
      expect(
          BloomTypeChecker.isBloomPackageUri(
              'package:blooming_extensions/extensions.dart'),
          isTrue);
      expect(
          BloomTypeChecker.isBloomPackageUri(
              'package:blooming_lints/blooming_lints.dart'),
          isTrue);

      expect(
          BloomTypeChecker.isBloomPackageUri('package:flutter/material.dart'),
          isFalse);
      expect(
          BloomTypeChecker.isBloomPackageUri('package:riverpod/riverpod.dart'),
          isFalse);
      expect(BloomTypeChecker.isBloomPackageUri(null), isFalse);
    });

    test(
        'isControllerOrCouplerType identifies real producer controllers and couplers',
        () {
      expect(BloomTypeChecker.isControllerOrCouplerType('BloomController'),
          isTrue);
      expect(BloomTypeChecker.isControllerOrCouplerType('RawBloomController'),
          isTrue);
      expect(BloomTypeChecker.isControllerOrCouplerType('BloomDraftController'),
          isTrue);
      expect(
          BloomTypeChecker.isControllerOrCouplerType('BloomCollectionController'),
          isTrue);
      expect(
          BloomTypeChecker.isControllerOrCouplerType('BloomCoupler'), isTrue);
      expect(
          BloomTypeChecker.isControllerOrCouplerType('BloomSignalController'),
          isTrue);

      // Terminals and non-producers are exempt
      expect(BloomTypeChecker.isControllerOrCouplerType('RawBloomTerminal'),
          isFalse);
      expect(BloomTypeChecker.isControllerOrCouplerType('RawViaTerminal'),
          isFalse);
      expect(BloomTypeChecker.isControllerOrCouplerType('RawComputedTerminal'),
          isFalse);
      expect(BloomTypeChecker.isControllerOrCouplerType('Bloom'), isFalse);
      expect(
          BloomTypeChecker.isControllerOrCouplerType(
              'FrozenAnimationController'),
          isFalse);
      expect(BloomTypeChecker.isControllerOrCouplerType('Container'), isFalse);
      expect(BloomTypeChecker.isControllerOrCouplerType(null), isFalse);
    });

    test(
        'isReactiveBridgingMethod identifies valid reactive bridging factory methods',
        () {
      expect(BloomTypeChecker.isReactiveBridgingMethod('toBloom'), isTrue);
      expect(BloomTypeChecker.isReactiveBridgingMethod('toBloomBy'), isTrue);
      expect(BloomTypeChecker.isReactiveBridgingMethod('toListenable'), isTrue);

      expect(BloomTypeChecker.isReactiveBridgingMethod('map'), isFalse);
      expect(BloomTypeChecker.isReactiveBridgingMethod('set'), isFalse);
      expect(BloomTypeChecker.isReactiveBridgingMethod(null), isFalse);
    });

    test(
        'isReactiveBridgingProperty is empty in modern Bloom (all bridges are methods)',
        () {
      expect(BloomTypeChecker.isReactiveBridgingProperty('asStream'), isFalse);
      expect(
          BloomTypeChecker.isReactiveBridgingProperty('asTerminal'), isFalse);
      expect(
          BloomTypeChecker.isReactiveBridgingProperty('toListenable'), isFalse);
      expect(BloomTypeChecker.isReactiveBridgingProperty('data'), isFalse);
      expect(BloomTypeChecker.isReactiveBridgingProperty(null), isFalse);
    });

    test(
        'isPipelineReadProperty identifies valid reactive payload getters on BloomState',
        () {
      expect(BloomTypeChecker.isPipelineReadProperty('phase'), isTrue);
      expect(BloomTypeChecker.isPipelineReadProperty('data'), isTrue);
      expect(BloomTypeChecker.isPipelineReadProperty('dataOrNull'), isTrue);
      expect(BloomTypeChecker.isPipelineReadProperty('snapshot'), isTrue);
      expect(BloomTypeChecker.isPipelineReadProperty('hasData'), isTrue);
      expect(BloomTypeChecker.isPipelineReadProperty('isEmpty'), isTrue);
      expect(BloomTypeChecker.isPipelineReadProperty('emptyReason'), isTrue);
      expect(BloomTypeChecker.isPipelineReadProperty('hasError'), isTrue);
      expect(BloomTypeChecker.isPipelineReadProperty('error'), isTrue);
      expect(BloomTypeChecker.isPipelineReadProperty('stackTrace'), isTrue);

      // Obsolete/Phantom properties
      expect(BloomTypeChecker.isPipelineReadProperty('nodes'), isFalse);
      expect(BloomTypeChecker.isPipelineReadProperty('nodesOrNull'), isFalse);
      expect(BloomTypeChecker.isPipelineReadProperty('nodesOrEmpty'), isFalse);
      expect(BloomTypeChecker.isPipelineReadProperty('value'), isFalse);
      expect(BloomTypeChecker.isPipelineReadProperty(null), isFalse);
    });

    test(
        'isPipelineReadMethod identifies valid reactive payload extraction methods on BloomState',
        () {
      expect(BloomTypeChecker.isPipelineReadMethod('dataOrElse'), isTrue);

      // Obsolete / Purged legacy methods (must evaluate to false)
      expect(BloomTypeChecker.isPipelineReadMethod('match'), isFalse);
      expect(BloomTypeChecker.isPipelineReadMethod('matchOrElse'), isFalse);
      expect(BloomTypeChecker.isPipelineReadMethod('matchOrNull'), isFalse);
      expect(BloomTypeChecker.isPipelineReadMethod('map'), isFalse);
      expect(BloomTypeChecker.isPipelineReadMethod('set'), isFalse);
      expect(BloomTypeChecker.isPipelineReadMethod(null), isFalse);
    });

    test(
        'isPipelineWriteMethod identifies verified real state-writing and coupling methods',
        () {
      // 1. Controller state writes
      expect(BloomTypeChecker.isPipelineWriteMethod('set'), isTrue);
      expect(BloomTypeChecker.isPipelineWriteMethod('setGuarded'), isTrue);
      expect(BloomTypeChecker.isPipelineWriteMethod('setError'), isTrue);
      expect(BloomTypeChecker.isPipelineWriteMethod('empty'), isTrue);
      expect(BloomTypeChecker.isPipelineWriteMethod('markDirty'), isTrue);

      // 2. Collection draft edits
      expect(BloomTypeChecker.isPipelineWriteMethod('edit'), isTrue);
      expect(BloomTypeChecker.isPipelineWriteMethod('editGuarded'), isTrue);

      // 3. Coupler dynamic coupling
      expect(BloomTypeChecker.isPipelineWriteMethod('couple'), isTrue);
      expect(BloomTypeChecker.isPipelineWriteMethod('coupleGuarded'), isTrue);
      expect(BloomTypeChecker.isPipelineWriteMethod('decouple'), isTrue);
      expect(BloomTypeChecker.isPipelineWriteMethod('tryDecoupling'), isTrue);

      // Non-writing / Phantom methods
      expect(BloomTypeChecker.isPipelineWriteMethod('swapSource'), isFalse);
      expect(BloomTypeChecker.isPipelineWriteMethod('swapSources'), isFalse);
      expect(BloomTypeChecker.isPipelineWriteMethod('dataOrElse'), isFalse);
      expect(BloomTypeChecker.isPipelineWriteMethod(null), isFalse);
    });

    test(
        'isPipelineWriteProperty identifies only verified real state-writing setters',
        () {
      expect(BloomTypeChecker.isPipelineWriteProperty('data'), isTrue);

      // Phantom properties
      expect(BloomTypeChecker.isPipelineWriteProperty('nodes'), isFalse);
      expect(BloomTypeChecker.isPipelineWriteProperty('sources'), isFalse);
      expect(BloomTypeChecker.isPipelineWriteProperty('snapshot'), isFalse);
      expect(BloomTypeChecker.isPipelineWriteProperty('dataOrNull'), isFalse);
      expect(BloomTypeChecker.isPipelineWriteProperty(null), isFalse);
    });

    test(
        'isPipelineEvaluationMethod identifies verified evaluation, derivation & UI render methods',
        () {
      // Core functors
      expect(BloomTypeChecker.isPipelineEvaluationMethod('computed'), isTrue);
      expect(BloomTypeChecker.isPipelineEvaluationMethod('switched'), isTrue);
      expect(BloomTypeChecker.isPipelineEvaluationMethod('managed'), isTrue);
      expect(BloomTypeChecker.isPipelineEvaluationMethod('distinct'), isTrue);
      expect(BloomTypeChecker.isPipelineEvaluationMethod('effect'), isTrue);

      // Flutter UI functors
      expect(BloomTypeChecker.isPipelineEvaluationMethod('build'), isTrue);
      expect(BloomTypeChecker.isPipelineEvaluationMethod('drive'), isTrue);
      expect(BloomTypeChecker.isPipelineEvaluationMethod('animate'), isTrue);
      expect(BloomTypeChecker.isPipelineEvaluationMethod('match'), isTrue);
      expect(BloomTypeChecker.isPipelineEvaluationMethod('when'), isTrue);
      expect(BloomTypeChecker.isPipelineEvaluationMethod('listen'), isTrue);

      // Phantom / Obsolete methods
      expect(BloomTypeChecker.isPipelineEvaluationMethod('map'), isFalse);
      expect(BloomTypeChecker.isPipelineEvaluationMethod('select'), isFalse);
      expect(BloomTypeChecker.isPipelineEvaluationMethod('cascade'), isFalse);
      expect(BloomTypeChecker.isPipelineEvaluationMethod('resource'), isFalse);
      expect(BloomTypeChecker.isPipelineEvaluationMethod('set'), isFalse);
      expect(BloomTypeChecker.isPipelineEvaluationMethod(null), isFalse);
    });

    test('Bloom target and type checks handle null/unresolved safely', () {
      expect(BloomTypeChecker.isBloomTarget(null), isFalse);
      expect(BloomTypeChecker.isBloomType(null), isFalse);

      final unit = parseString(content: '''
void test() {
  counterBloom;
  signalBloom;
  bloom;
  bloomSignal;
  bloomScreen;
  blooming;
  showBloomDialog();
}
''').unit;

      final identifiers = <SimpleIdentifier>[];
      unit.visitChildren(_IdentifierCollector((node) => identifiers.add(node)));

      final counterBloomId =
          identifiers.firstWhere((id) => id.name == 'counterBloom');
      final signalBloomId =
          identifiers.firstWhere((id) => id.name == 'signalBloom');
      final bloomId = identifiers.firstWhere((id) => id.name == 'bloom');
      final bloomSignalId =
          identifiers.firstWhere((id) => id.name == 'bloomSignal');
      final bloomScreenId =
          identifiers.firstWhere((id) => id.name == 'bloomScreen');
      final bloomingId = identifiers.firstWhere((id) => id.name == 'blooming');

      expect(BloomTypeChecker.isBloomTarget(counterBloomId), isTrue);
      expect(BloomTypeChecker.isBloomTarget(signalBloomId), isTrue);
      expect(BloomTypeChecker.isBloomTarget(bloomId), isTrue);
      expect(BloomTypeChecker.isBloomTarget(bloomSignalId), isFalse);
      expect(BloomTypeChecker.isBloomTarget(bloomScreenId), isFalse);
      expect(BloomTypeChecker.isBloomTarget(bloomingId), isFalse);
    });

    test(
        'isAsyncOrTimerInvocation strictly requires valid targets or top-level functions',
        () {
      final unit = parseString(content: '''
void test() {
  scheduleMicrotask(() {});
  Future.microtask(() {});
  Future.delayed(Duration.zero, () {});
  Timer.run(() {});
  future.then((v) {});
  future.catchError((e) {});
  future.whenComplete(() {});

  // Invalid / Untargeted invocations that must NOT match
  then(() {});
  catchError((e) {});
  whenComplete(() {});
  microtask(() {});
  delayed(() {});
  run(() {});
  foo.run(() {});
}
''').unit;

      final invocations = <MethodInvocation>[];
      unit.visitChildren(_InvocationCollector((node) => invocations.add(node)));

      MethodInvocation find(String name, {bool hasTarget = true}) =>
          invocations.firstWhere((i) =>
              i.methodName.name == name &&
              (hasTarget ? i.target != null : i.target == null));

      expect(
          BloomTypeChecker.isAsyncOrTimerInvocation(
              find('scheduleMicrotask', hasTarget: false)),
          isTrue);
      expect(
          BloomTypeChecker.isAsyncOrTimerInvocation(
              find('microtask', hasTarget: true)),
          isTrue);
      expect(
          BloomTypeChecker.isAsyncOrTimerInvocation(
              find('delayed', hasTarget: true)),
          isTrue);
      expect(
          BloomTypeChecker.isAsyncOrTimerInvocation(
              find('run', hasTarget: true)),
          isTrue);
      expect(
          BloomTypeChecker.isAsyncOrTimerInvocation(
              find('then', hasTarget: true)),
          isTrue);
      expect(
          BloomTypeChecker.isAsyncOrTimerInvocation(
              find('catchError', hasTarget: true)),
          isTrue);
      expect(
          BloomTypeChecker.isAsyncOrTimerInvocation(
              find('whenComplete', hasTarget: true)),
          isTrue);

      expect(
          BloomTypeChecker.isAsyncOrTimerInvocation(
              find('then', hasTarget: false)),
          isFalse);
      expect(
          BloomTypeChecker.isAsyncOrTimerInvocation(
              find('catchError', hasTarget: false)),
          isFalse);
      expect(
          BloomTypeChecker.isAsyncOrTimerInvocation(
              find('whenComplete', hasTarget: false)),
          isFalse);
      expect(
          BloomTypeChecker.isAsyncOrTimerInvocation(
              find('microtask', hasTarget: false)),
          isFalse);
      expect(
          BloomTypeChecker.isAsyncOrTimerInvocation(
              find('delayed', hasTarget: false)),
          isFalse);
      expect(
          BloomTypeChecker.isAsyncOrTimerInvocation(
              find('run', hasTarget: false)),
          isFalse);

      final fooRun = invocations.firstWhere(
          (i) => i.methodName.name == 'run' && i.target?.toSource() == 'foo');
      expect(BloomTypeChecker.isAsyncOrTimerInvocation(fooRun), isFalse);
    });

    test(
        'isInsideBloomViaScope identifies reactive scopes and does NOT treat isolated via call as scope',
        () {
      final unit = parseString(content: '''
void normalFunction() {
  via(counter);
  final a = counter.data;
}

void testComputed() {
  computed((via) {
    final b = counter.data;
  });
}
''').unit;

      final identifiers = <SimpleIdentifier>[];
      unit.visitChildren(_IdentifierCollector((node) => identifiers.add(node)));

      final normalViaCounter = identifiers.firstWhere((id) =>
          id.name == 'counter' &&
          id.parent?.parent?.toSource() == 'via(counter)');
      final normalDirectCounter = identifiers.firstWhere((id) =>
          id.name == 'counter' &&
          id.parent?.toSource() == 'counter.data' &&
          id.parent?.parent?.toSource() == 'a = counter.data');
      final computedCounter = identifiers.firstWhere((id) =>
          id.name == 'counter' &&
          id.parent?.toSource() == 'counter.data' &&
          id.parent?.parent?.toSource() == 'b = counter.data');

      expect(BloomTypeChecker.isInsideBloomViaScope(normalViaCounter), isFalse);
      expect(
          BloomTypeChecker.isInsideBloomViaScope(normalDirectCounter), isFalse);
      expect(BloomTypeChecker.isInsideBloomViaScope(computedCounter), isTrue);
    });

    test(
        'isTimerCreation and isFutureCreation recognize unresolved constructors',
        () {
      final unit = parseString(content: '''
void test() {
  final t = new Timer(Duration.zero, () {});
  final f = new Future.value(1);
  final o = new Object();
}
''').unit;

      final creations = <InstanceCreationExpression>[];
      unit.visitChildren(
          _InstanceCreationCollector((node) => creations.add(node)));

      expect(BloomTypeChecker.isTimerCreation(creations[0]), isTrue);
      expect(BloomTypeChecker.isFutureCreation(creations[1]), isTrue);
      expect(BloomTypeChecker.isTimerCreation(creations[2]), isFalse);
      expect(BloomTypeChecker.isFutureCreation(creations[2]), isFalse);
    });

    test(
        'isBloomViaInvocation vs isBloomViaTrackingInvocation distinguishes tracking from control flow',
        () {
      final unit = parseString(content: '''
void testVia(BloomVia via, dynamic context) {
  via(counter);
  via.state(counter);
  via.tether(effect);
  via.of(context);
  via.maybeOf(context);
  via.exit(emptyReason: 'done');
  via.exitIfInactive(emptyReason: 'stale');
}
''').unit;

      final invocations = <AstNode>[];
      unit.visitChildren(_AstNodeCollector((node) {
        if (node is MethodInvocation || node is FunctionExpressionInvocation) {
          invocations.add(node);
        }
      }));

      // Find specific calls
      final callVia =
          invocations.firstWhere((n) => n.toSource() == 'via(counter)');
      final stateCall =
          invocations.firstWhere((n) => n.toSource() == 'via.state(counter)');
      final tetherCall =
          invocations.firstWhere((n) => n.toSource() == 'via.tether(effect)');
      final ofCall =
          invocations.firstWhere((n) => n.toSource() == 'via.of(context)');
      final maybeOfCall =
          invocations.firstWhere((n) => n.toSource() == 'via.maybeOf(context)');
      final exitCall = invocations
          .firstWhere((n) => n.toSource() == "via.exit(emptyReason: 'done')");
      final exitIfInactiveCall = invocations.firstWhere(
          (n) => n.toSource() == "via.exitIfInactive(emptyReason: 'stale')");

      // All are recognized as general BloomVia invocations
      expect(BloomTypeChecker.isBloomViaInvocation(callVia), isTrue);
      expect(BloomTypeChecker.isBloomViaInvocation(stateCall), isTrue);
      expect(BloomTypeChecker.isBloomViaInvocation(tetherCall), isTrue);
      expect(BloomTypeChecker.isBloomViaInvocation(ofCall), isTrue);
      expect(BloomTypeChecker.isBloomViaInvocation(maybeOfCall), isTrue);
      expect(BloomTypeChecker.isBloomViaInvocation(exitCall), isTrue);
      expect(BloomTypeChecker.isBloomViaInvocation(exitIfInactiveCall), isTrue);

      // Only dependency-tracking calls are recognized by isBloomViaTrackingInvocation
      expect(BloomTypeChecker.isBloomViaTrackingInvocation(callVia), isTrue);
      expect(BloomTypeChecker.isBloomViaTrackingInvocation(stateCall), isTrue);
      expect(BloomTypeChecker.isBloomViaTrackingInvocation(tetherCall), isTrue);
      expect(BloomTypeChecker.isBloomViaTrackingInvocation(ofCall), isTrue);
      expect(
          BloomTypeChecker.isBloomViaTrackingInvocation(maybeOfCall), isTrue);

      // exit and exitIfInactive are control flow and do NOT register dependencies
      expect(BloomTypeChecker.isBloomViaTrackingInvocation(exitCall), isFalse);
      expect(BloomTypeChecker.isBloomViaTrackingInvocation(exitIfInactiveCall),
          isFalse);
    });
  });
}

class _AstNodeCollector extends RecursiveAstVisitor<void> {
  final void Function(AstNode) onNode;
  _AstNodeCollector(this.onNode);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    onNode(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    onNode(node);
    super.visitFunctionExpressionInvocation(node);
  }
}

class _InstanceCreationCollector extends RecursiveAstVisitor<void> {
  final void Function(InstanceCreationExpression) onCreation;
  _InstanceCreationCollector(this.onCreation);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    onCreation(node);
    super.visitInstanceCreationExpression(node);
  }
}

class _IdentifierCollector extends RecursiveAstVisitor<void> {
  final void Function(SimpleIdentifier) onIdentifier;
  _IdentifierCollector(this.onIdentifier);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    onIdentifier(node);
    super.visitSimpleIdentifier(node);
  }
}

class _InvocationCollector extends RecursiveAstVisitor<void> {
  final void Function(MethodInvocation) onInvocation;
  _InvocationCollector(this.onInvocation);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    onInvocation(node);
    super.visitMethodInvocation(node);
  }
}

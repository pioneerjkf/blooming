// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:blooming_lints/blooming_lints.dart';
import 'package:test/test.dart';

class _BridgingInvocationFinder extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> methodCalls = [];
  final List<PropertyAccess> propertyCalls = [];
  final List<PrefixedIdentifier> prefixedCalls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (BloomTypeChecker.isReactiveBridgingMethod(node.methodName.name)) {
      methodCalls.add(node);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (BloomTypeChecker.isReactiveBridgingProperty(node.propertyName.name)) {
      propertyCalls.add(node);
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (BloomTypeChecker.isReactiveBridgingProperty(node.identifier.name)) {
      prefixedCalls.add(node);
    }
    super.visitPrefixedIdentifier(node);
  }
}

void main() {
  group('AvoidBridgingInBuild AST detection', () {
    test(
        'detects toBloom, toBloomBy, toListenable inside Flutter Widget build() method',
        () {
      final unit = parseString(content: '''
class BadWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final a = controller.toBloom();
    final b = notifier.toListenable();
    final selector = scrollController.toBloomBy((c) => c.offset);
    return Container();
  }
}
''').unit;

      final finder = _BridgingInvocationFinder();
      unit.accept(finder);

      expect(finder.methodCalls.length,
          equals(3)); // toBloom, toListenable, toBloomBy

      for (final call in finder.methodCalls) {
        expect(AvoidBridgingInBuild.isInsideBuildOrReactiveScope(call), isTrue);
      }
    });

    test('detects toBloom inside computed derivation scope', () {
      final unit = parseString(content: '''
void main() {
  final comp = computed((via) {
    final a = notifier.toBloom();
    return 10;
  });
}
''').unit;

      final finder = _BridgingInvocationFinder();
      unit.accept(finder);

      expect(finder.methodCalls.length, equals(1));
      expect(
          AvoidBridgingInBuild.isInsideBuildOrReactiveScope(
              finder.methodCalls.first),
          isTrue);
    });

    test('ignores bridging inside non-build methods or lifecycle initializers',
        () {
      final unit = parseString(content: '''
class GoodWidget extends StatelessWidget {
  late final a = controller.toBloom();
  late final b = notifier.toListenable();

  void initState() {
    final bloom = controller.toBloom();
  }

  Widget build(BuildContext context) {
    return Container();
  }
}
''').unit;

      final finder = _BridgingInvocationFinder();
      unit.accept(finder);

      expect(finder.methodCalls.length, equals(3));
      for (final call in finder.methodCalls) {
        expect(
            AvoidBridgingInBuild.isInsideBuildOrReactiveScope(call), isFalse);
      }
    });
  });
}

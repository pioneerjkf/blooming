// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:analysis_server_plugin/registry.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:test/test.dart';
import 'package:blooming_lints/blooming_lints.dart';

class _TestPluginRegistry implements PluginRegistry {
  final List<AbstractAnalysisRule> rules = [];
  final Map<DiagnosticCode, List<ProducerGenerator>> fixes = {};

  @override
  void registerWarningRule(AbstractAnalysisRule rule) => rules.add(rule);

  @override
  void registerLintRule(AbstractAnalysisRule rule) => rules.add(rule);

  @override
  void registerFixForRule(DiagnosticCode code, ProducerGenerator generator) {
    fixes.putIfAbsent(code, () => []).add(generator);
  }

  @override
  void registerAssist(ProducerGenerator generator) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('QuickFix Transformations', () {
    test('BloomingPlugin registers expected quick fixes for rules', () async {
      final registry = _TestPluginRegistry();
      await plugin.register(registry);

      expect(registry.rules.length, equals(15));
      expect(
        registry.fixes[AvoidUntrackedBloomRead.code],
        contains(WrapWithViaFix.new),
      );
      expect(
        registry.fixes[AvoidUntrackedBloomRead.untrackedCode],
        contains(WrapWithViaFix.new),
      );
      expect(
        registry.fixes[AvoidViaStateWhenValueSuffices.code],
        contains(ReplaceViaStateDataFix.new),
      );
      expect(
        registry.fixes[AvoidAsyncInComputed.code],
        contains(ConvertToComputedAsyncFix.new),
      );
      expect(
        registry.fixes[PreferBloomWidget.code],
        contains(ReplaceStatelessWithBloomWidgetFix.new),
      );
    });

    test('ConvertToComputedAsyncFix AST recognition for async closure', () {
      const source = '''
void test() {
  final res = computed((via) async => 42);
}
''';
      final unit = parseString(content: source).unit;

      MethodInvocation? foundInvocation;
      unit.accept(
        _ComputedInvocationFinder((node) {
          foundInvocation = node;
        }),
      );

      expect(foundInvocation, isNotNull);
      expect(foundInvocation!.methodName.name, equals('computed'));
      final computeArg =
          foundInvocation!.argumentList.arguments.first.argumentExpression;
      expect(
        BloomTypeChecker.classifyAsyncComputation(computeArg),
        equals(AsyncComputationKind.future),
      );

      final fix = ConvertToComputedAsyncFix.computeReplacement(
        foundInvocation!,
      );
      expect(fix, isNotNull);
      expect(fix!.message, equals('Convert to computed.future'));
      expect(fix.replacement, equals('computed.future'));

      final node = fix.targetNode;
      final transformed = source.replaceRange(
        node.offset,
        node.offset + node.length,
        fix.replacement,
      );
      expect(
        transformed,
        contains('final res = computed.future((via) async => 42);'),
      );
    });

    test('ConvertToComputedAsyncFix AST recognition for async* generator', () {
      const source = '''
void test() {
  final res = computed((via) async* {
    yield 42;
  });
}
''';
      final unit = parseString(content: source).unit;

      MethodInvocation? foundInvocation;
      unit.accept(
        _ComputedInvocationFinder((node) {
          foundInvocation = node;
        }),
      );

      expect(foundInvocation, isNotNull);
      expect(foundInvocation!.methodName.name, equals('computed'));
      final computeArg =
          foundInvocation!.argumentList.arguments.first.argumentExpression;
      expect(
        BloomTypeChecker.classifyAsyncComputation(computeArg),
        equals(AsyncComputationKind.stream),
      );

      final fix = ConvertToComputedAsyncFix.computeReplacement(
        foundInvocation!,
      );
      expect(fix, isNotNull);
      expect(fix!.message, equals('Convert to computed.stream'));
      expect(fix.replacement, equals('computed.stream'));

      final node = fix.targetNode;
      final transformed = source.replaceRange(
        node.offset,
        node.offset + node.length,
        fix.replacement,
      );
      expect(
        transformed,
        contains('final res = computed.stream((via) async* {'),
      );
    });

    test('ReplaceViaStateDataFix AST recognition', () {
      final unit = parseString(
        content: '''
void test() {
  final res = computed((via) => via.state(price).data * 2);
}
''',
      ).unit;

      MethodInvocation? foundInvocation;
      unit.accept(
        _StateDataFinder((node) {
          foundInvocation = node;
        }),
      );

      expect(foundInvocation, isNotNull);
      expect(foundInvocation!.methodName.name, equals('state'));
      expect(
        foundInvocation!.argumentList.arguments.first.toSource(),
        equals('price'),
      );
    });
  });
}

class _StateDataFinder extends RecursiveAstVisitor<void> {
  final void Function(MethodInvocation) onFound;
  _StateDataFinder(this.onFound);

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'data') {
      final target = node.target;
      if (target is MethodInvocation &&
          AvoidViaStateWhenValueSuffices.isViaStateInvocation(target)) {
        onFound(target);
      }
    }
    super.visitPropertyAccess(node);
  }
}

class _ComputedInvocationFinder extends RecursiveAstVisitor<void> {
  final void Function(MethodInvocation) onFound;
  _ComputedInvocationFinder(this.onFound);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'computed') {
      onFound(node);
    }
    super.visitMethodInvocation(node);
  }
}

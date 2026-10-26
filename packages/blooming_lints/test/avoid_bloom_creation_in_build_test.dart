// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:test/test.dart';
import 'package:blooming_lints/blooming_lints.dart';

void main() {
  group('AvoidBloomCreationInBuild AST detection', () {
    test('detects blooming() instantiation inside build()', () {
      final unit = parseString(content: '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final controller = blooming(0);
    return Container();
  }
}
''').unit;

      MethodInvocation? invocation;
      unit.accept(_MethodInvocationVisitor(
          'blooming', (node) => invocation = node));

      expect(invocation, isNotNull);
      expect(
          AvoidBloomCreationInBuild.isForbiddenMethodInvocation(invocation!),
          isTrue);
      expect(FlutterAstUtils.isInsideBuildMethod(invocation!), isTrue);
      expect(
          AvoidStateWritesInPipeline.isInsideEventOrDeferredClosure(
              invocation!),
          isFalse);
    });

    test('detects blooming.signal() instantiation inside build()', () {
      final unit = parseString(content: '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final signal = blooming.signal();
    return Container();
  }
}
''').unit;

      MethodInvocation? invocation;
      unit.accept(_MethodInvocationVisitor(
          'signal', (node) => invocation = node));

      expect(invocation, isNotNull);
      expect(AvoidBloomCreationInBuild.isForbiddenMethodInvocation(invocation!),
          isTrue);
      expect(FlutterAstUtils.isInsideBuildMethod(invocation!), isTrue);
      expect(
          AvoidStateWritesInPipeline.isInsideEventOrDeferredClosure(
              invocation!),
          isFalse);
    });

    test('detects computed() instantiation inside build()', () {
      final unit = parseString(content: '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final doubled = computed((via) => via(counter) * 2);
    return Container();
  }
}
''').unit;

      MethodInvocation? invocation;
      unit.accept(
          _MethodInvocationVisitor('computed', (node) => invocation = node));

      expect(invocation, isNotNull);
      expect(
          AvoidBloomCreationInBuild.isForbiddenMethodInvocation(invocation!),
          isTrue);
      expect(FlutterAstUtils.isInsideBuildMethod(invocation!), isTrue);
      expect(
          AvoidStateWritesInPipeline.isInsideEventOrDeferredClosure(
              invocation!),
          isFalse);
    });

    test('permits composed() inside build() (composed is a valid UI widget)',
        () {
      final unit = parseString(content: '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return composed((via) => Text('\${via(counter)}'));
  }
}
''').unit;

      MethodInvocation? invocation;
      unit.accept(
          _MethodInvocationVisitor('composed', (node) => invocation = node));

      expect(invocation, isNotNull);
      expect(AvoidBloomCreationInBuild.isForbiddenMethodInvocation(invocation!),
          isFalse);
    });

    test('permits blooming() creation inside event callbacks in build()',
        () {
      final unit = parseString(content: '''
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final ctrl = blooming(10);
      },
      child: Text('Click'),
    );
  }
}
''').unit;

      MethodInvocation? invocation;
      unit.accept(_MethodInvocationVisitor(
          'blooming', (node) => invocation = node));

      expect(invocation, isNotNull);
      expect(
          AvoidBloomCreationInBuild.isForbiddenMethodInvocation(invocation!),
          isTrue);
      expect(
          AvoidStateWritesInPipeline.isInsideEventOrDeferredClosure(
              invocation!),
          isTrue);
    });

    test('permits blooming() inside State.initState()', () {
      final unit = parseString(content: '''
class MyState extends State<MyWidget> {
  void initState() {
    super.initState();
    final ctrl = blooming(0);
  }
}
''').unit;

      MethodInvocation? invocation;
      unit.accept(_MethodInvocationVisitor(
          'blooming', (node) => invocation = node));

      expect(invocation, isNotNull);
      expect(FlutterAstUtils.isInsideBuildMethod(invocation!), isFalse);
    });
  });
}

class _MethodInvocationVisitor extends RecursiveAstVisitor<void> {
  _MethodInvocationVisitor(this.methodName, this.onFound);
  final String methodName;
  final void Function(MethodInvocation) onFound;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == methodName) {
      onFound(node);
    }
    super.visitMethodInvocation(node);
  }
}

class _FunctionInvocationVisitor extends RecursiveAstVisitor<void> {
  _FunctionInvocationVisitor(this.functionName, this.onFound);
  final String functionName;
  final void Function(FunctionExpressionInvocation) onFound;

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    final function = node.function;
    final name =
        function is SimpleIdentifier ? function.name : function.toSource();
    if (name == functionName) {
      onFound(node);
    }
    super.visitFunctionExpressionInvocation(node);
  }
}

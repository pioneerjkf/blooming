// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:test/test.dart';
import 'package:blooming_lints/blooming_lints.dart';

void main() {
  group('PreferBloomOverController AST detection', () {
    test('detects BloomController parameter in StatelessWidget constructor',
        () {
      final unit = parseString(content: '''
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.controller});
  final BloomController<int> controller;

  @override
  Widget build(BuildContext context) => Container();
}
''').unit;

      ClassDeclaration? clazz;
      unit.visitChildren(_ClassVisitor((node) => clazz = node));

      expect(clazz, isNotNull);
      final constructor =
          clazz!.members.whereType<ConstructorDeclaration>().first;
      final param = constructor.parameters.parameters.last;
      final typeStr =
          PreferBloomOverController.getParameterTypeString(param, clazz!);
      expect(typeStr, startsWith('BloomController'));
    });

    test('detects Blooming and Blooming* producer alias parameters', () {
      final unit = parseString(content: '''
class MyWidget extends StatelessWidget {
  const MyWidget({
    super.key,
    required this.counter,
    required this.raw,
    required this.list,
  });
  final Blooming<int> counter;
  final BloomingRaw<int> raw;
  final BloomingList<String> list;

  @override
  Widget build(BuildContext context) => Container();
}
''').unit;

      ClassDeclaration? clazz;
      unit.visitChildren(_ClassVisitor((node) => clazz = node));

      expect(clazz, isNotNull);
      final constructor =
          clazz!.members.whereType<ConstructorDeclaration>().first;
      final params = constructor.parameters.parameters.sublist(1);

      for (final param in params) {
        final typeStr =
            PreferBloomOverController.getParameterTypeString(param, clazz!);
        expect(typeStr, startsWith('Blooming'));
      }
    });

    test('permits read-only Bloom<T> parameter in StatelessWidget', () {
      final unit = parseString(content: '''
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.count});
  final Bloom<int> count;

  @override
  Widget build(BuildContext context) => Container();
}
''').unit;

      ClassDeclaration? clazz;
      unit.visitChildren(_ClassVisitor((node) => clazz = node));

      expect(clazz, isNotNull);
      final constructor =
          clazz!.members.whereType<ConstructorDeclaration>().first;
      final param = constructor.parameters.parameters.last;
      final typeStr =
          PreferBloomOverController.getParameterTypeString(param, clazz!);
      expect(typeStr, startsWith('Bloom<int>'));
    });
  });
}

class _ClassVisitor extends RecursiveAstVisitor<void> {
  _ClassVisitor(this.onFound);
  final void Function(ClassDeclaration) onFound;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    onFound(node);
    super.visitClassDeclaration(node);
  }
}

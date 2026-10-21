// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:blooming_lints/blooming_lints.dart';
import 'package:test/test.dart';

class _UntrackedPayloadVisitor extends RecursiveAstVisitor<void> {
  final List<AstNode> untrackedNodes = [];

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (BloomTypeChecker.isPipelineReadProperty(node.identifier.name)) {
      if (AvoidUntrackedBloomRead.isUntrackedInBloomViaScope(node)) {
        untrackedNodes.add(node);
      }
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (BloomTypeChecker.isPipelineReadProperty(node.propertyName.name)) {
      if (AvoidUntrackedBloomRead.isUntrackedInBloomViaScope(node)) {
        untrackedNodes.add(node);
      }
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (BloomTypeChecker.isPipelineReadMethod(methodName)) {
      if (AvoidUntrackedBloomRead.isUntrackedInBloomViaScope(node)) {
        untrackedNodes.add(node);
      }
    } else if (BloomTypeChecker.isBloomUntrackedInvocation(node)) {
      if (AvoidUntrackedBloomRead.isUntrackedInBloomViaScope(node)) {
        untrackedNodes.add(node);
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (BloomTypeChecker.isBloomUntrackedInvocation(node)) {
      if (AvoidUntrackedBloomRead.isUntrackedInBloomViaScope(node)) {
        untrackedNodes.add(node);
      }
    }
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitAsExpression(AsExpression node) {
    if (AvoidUntrackedBloomRead.isUntrackedInBloomViaScope(node)) {
      final typeName = node.type.toString();
      if (typeName.startsWith('BloomState')) {
        untrackedNodes.add(node);
      }
    }
    super.visitAsExpression(node);
  }
}

void main() {
  group('AvoidUntrackedBloomRead AST detection', () {
    test('detects untracked .data inside computed((via) => ...) closure', () {
      final unit = parseString(content: '''
void testComputed() {
  final doubled = computed((via) {
    final raw = counter.data; // [Anti-Pattern] Untracked direct read!
    return raw * 2;
  });
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(1));
    });

    test('permits tracked via(counter) inside computed((via) => ...)', () {
      final unit = parseString(content: '''
void testComputed() {
  final doubled = computed((via) {
    final tracked = via(counter); // [Recommended] Valid explicit manifest
    return tracked * 2;
  });
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(0));
    });

    test(
        'detects untracked .data, .snapshot, .hasData inside BloomWidget.build',
        () {
      final unit = parseString(content: '''
class MyBloomWidget extends BloomWidget {
  final Bloom<int> countBloom;
  MyBloomWidget(this.countBloom);

  @override
  Widget build(BuildContext context, BloomVia via) {
    final a = countBloom.data; // [Anti-Pattern] Untracked
    final b = countBloom.snapshot; // [Anti-Pattern] Untracked
    final c = countBloom.hasData; // [Anti-Pattern] Untracked
    return Text('\$a');
  }
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(3));
    });

    test('permits via(countBloom) inside BloomWidget.build', () {
      final unit = parseString(content: '''
class MyBloomWidget extends BloomWidget {
  final Bloom<int> countBloom;
  MyBloomWidget(this.countBloom);

  @override
  Widget build(BuildContext context, BloomVia via) {
    final a = via(countBloom); // [Recommended] Tracked
    return Text('\$a');
  }
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(0));
    });

    test(
        'detects untracked .data in composed((via) => ...) micro-rebuild functor',
        () {
      final unit = parseString(content: '''
Widget testComposed() {
  return composed((via) => Text('\${counter.data}')); // [Anti-Pattern] Untracked
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(1));
    });

    test(
        'detects untracked .data in switched((via) => ...) dynamic branch functor',
        () {
      final unit = parseString(content: '''
void testSwitched() {
  final s = switched((via) {
    return via(isDark) ? darkBloom.data : lightBloom.data; // [Anti-Pattern] 2 untracked reads
  });
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(2));
    });

    test('detects untracked .data in Effect((via) => ...)', () {
      final unit = parseString(content: '''
void testEffect() {
  Effect((via) {
    print(counter.data); // [Anti-Pattern] Untracked
  });
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(1));
    });

    test('permits .data inside event handlers within BloomWidget.build', () {
      final unit = parseString(content: '''
class SafeEventWidget extends BloomWidget {
  final Bloom<int> countBloom;
  SafeEventWidget(this.countBloom);

  @override
  Widget build(BuildContext context, BloomVia via) {
    final count = via(countBloom);
    return ElevatedButton(
      onPressed: () {
        final current = countBloom.data; // [Recommended] Safe in user event handler
        print(current);
      },
      child: Text('\$count'),
    );
  }
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(0));
    });

    test('permits via(node) inside inline builder with via parameter', () {
      final unit = parseString(content: '''
class SampleWidget extends StatelessWidget {
  final Bloom<int> count;
  SampleWidget(this.count);

  @override
  Widget build(BuildContext context) {
    return composed.context(
      (context, via) => Text('Count: \${via(count)}'),
    );
  }
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(0));
    });

    test('detects untracked context.bloomOf<T>().data inside BloomWidget.build',
        () {
      final unit = parseString(content: '''
class MyBloomWidget extends BloomWidget {
  @override
  Widget build(BuildContext context, BloomVia via) {
    final store = context.bloomOf<MyStore>().data; // [Anti-Pattern] Untracked
    return Text('\$store');
  }
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(1));
    });

    test('permits tracked via.of<T>(context).data inside BloomWidget.build',
        () {
      final unit = parseString(content: '''
class MyBloomWidget extends BloomWidget {
  @override
  Widget build(BuildContext context, BloomVia via) {
    final store = via.of<MyStore>(context).data;
    final optional = via.maybeOf<MyStore>(context).data;
    return Text('\$store \$optional');
  }
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(0));
    });
    test('detects untracked(...) and untracked.state(...) inside computed', () {
      final unit = parseString(content: '''
void testComputed() {
  final result = computed((via) {
    final a = untracked(countBloom);
    final b = untracked.state(countBloom);
    return a;
  });
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(2));
    });

    test('detects untracked .data on BloomController inside computed', () {
      final unit = parseString(content: '''
void testComputed() {
  final result = computed((via) {
    final val = countController.data;
    return val * 2;
  });
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(1));
    });

    test('detects manual cast to BloomState inside BloomVia scope', () {
      final unit = parseString(content: '''
void testComputed() {
  final result = computed((via) {
    final state = countBloom as BloomState<int>;
    return state.data;
  });
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      // Both the cast and the .data read are caught
      expect(visitor.untrackedNodes.length, greaterThanOrEqualTo(1));
    });

    test('detects untracked(...) inside computed', () {
      final unit = parseString(content: '''
void testComputed() {
  final result = computed((via) {
    final a = untracked(countBloom);
    return a * 2;
  });
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(1));
    });

    test('detects untracked.state(...) inside computed', () {
      final unit = parseString(content: '''
void testComputed() {
  final result = computed((via) {
    final state = untracked.state(countBloom);
    return state.data;
  });
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, greaterThanOrEqualTo(1));
    });

    test('permits untracked(...) inside event handlers in BloomWidget', () {
      final unit = parseString(content: '''
class MyWidget extends BloomWidget {
  final Bloom<int> countBloom;
  MyWidget(this.countBloom);

  @override
  Widget build(BuildContext context, BloomVia via) {
    return ElevatedButton(
      onPressed: () {
        final a = untracked(countBloom);
        print(a);
      },
      child: Text('Click'),
    );
  }
}
''').unit;

      final visitor = _UntrackedPayloadVisitor();
      unit.accept(visitor);

      expect(visitor.untrackedNodes.length, equals(0));
    });
  });
}

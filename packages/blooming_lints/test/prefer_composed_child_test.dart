// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:blooming_lints/blooming_lints.dart';
import 'package:test/test.dart';

void main() {
  group('PreferComposedChild', () {
    test(
        'detects heavy static subtree (2+ static widgets) inside composed closure',
        () {
      final unit = parseString(content: '''
void main() {
  composed((via) => Row(children: [
    Text('\${via(countBloom)}'),
    const Icon(Icons.star),
    const Text('Favorite'),
  ]));
}
''').unit;

      FunctionExpression? composedClosure;
      unit.visitChildren(_FunctionExpressionVisitor((func) {
        composedClosure = func;
      }));

      expect(composedClosure, isNotNull);
      expect(
          PreferComposedChild.containsHeavyStaticWidget(composedClosure!.body),
          isTrue);
    });

    test(
        'detects const list literal containing static widgets inside composed closure',
        () {
      final unit = parseString(content: '''
void main() {
  composed((via) => Row(children: const [
    Icon(Icons.star),
    Icon(Icons.star_border),
  ]));
}
''').unit;

      FunctionExpression? composedClosure;
      unit.visitChildren(_FunctionExpressionVisitor((func) {
        composedClosure = func;
      }));

      expect(composedClosure, isNotNull);
      expect(
          PreferComposedChild.containsHeavyStaticWidget(composedClosure!.body),
          isTrue);
    });

    test(
        'returns false for trivial spacers and single label (SizedBox, single Text)',
        () {
      final unit = parseString(content: '''
void main() {
  composed((via) => Row(children: [
    const Text('Switch: '),
    const SizedBox(width: 8),
    Text('\${via(countBloom)}'),
    const SizedBox(height: 12),
  ]));
}
''').unit;

      FunctionExpression? composedClosure;
      unit.visitChildren(_FunctionExpressionVisitor((func) {
        composedClosure = func;
      }));

      expect(composedClosure, isNotNull);
      expect(
          PreferComposedChild.containsHeavyStaticWidget(composedClosure!.body),
          isFalse);
    });

    test('strict mode detects single const widget in high-frequency animation',
        () {
      final unit = parseString(content: '''
void main() {
  composed((via) => Row(children: [
    Text('\${via(countBloom)}'),
    const Icon(Icons.star),
  ]));
}
''').unit;

      FunctionExpression? composedClosure;
      unit.visitChildren(_FunctionExpressionVisitor((func) {
        composedClosure = func;
      }));

      expect(composedClosure, isNotNull);
      // In standard mode, single icon is allowed
      expect(
          PreferComposedChild.containsHeavyStaticWidget(composedClosure!.body),
          isFalse);
      // In high-frequency mode, single icon triggers strict isolation
      expect(
          PreferComposedChild.containsHeavyStaticWidget(composedClosure!.body,
              isHighFrequency: true),
          isTrue);
    });

    test(
        'automatically detects observe as high-frequency source and enforces threshold 1',
        () {
      final unit = parseString(content: '''
void main() {
  composed((via) => Row(children: [
    Text('\${via(ctrl.observe())}'),
    const Icon(Icons.star),
  ]));
}
''').unit;

      FunctionExpression? composedClosure;
      unit.visitChildren(_FunctionExpressionVisitor((func) {
        composedClosure = func;
      }));

      expect(composedClosure, isNotNull);
      // Automatically detected as high-frequency source, so strict isolation is enforced (threshold 1)
      expect(
          PreferComposedChild.containsHeavyStaticWidget(composedClosure!.body),
          isTrue);
    });

    test(
        'returns false when no const widgets or static trees exist inside composed closure',
        () {
      final unit = parseString(content: '''
void main() {
  composed((via) => Text('\${via(countBloom)}'));
}
''').unit;

      FunctionExpression? composedClosure;
      unit.visitChildren(_FunctionExpressionVisitor((func) {
        composedClosure = func;
      }));

      expect(composedClosure, isNotNull);
      expect(
          PreferComposedChild.containsHeavyStaticWidget(composedClosure!.body),
          isFalse);
    });

    test(
        'returns false for non-widget const value types like EdgeInsets and TextStyle',
        () {
      final unit = parseString(content: '''
void main() {
  composed((via) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text('\${via(countBloom)}', style: const TextStyle(fontSize: 14)),
  ));
}
''').unit;

      FunctionExpression? composedClosure;
      unit.visitChildren(_FunctionExpressionVisitor((func) {
        composedClosure = func;
      }));

      expect(composedClosure, isNotNull);
      expect(
          PreferComposedChild.containsHeavyStaticWidget(composedClosure!.body),
          isFalse);
    });

    test(
        'allows mutually exclusive switch expression branches returning single const widgets (view router)',
        () {
      final unit = parseString(content: '''
void main() {
  composed((via) {
    final isMounted = via(isMountedBloom);
    if (!isMounted) {
      return const DormantPlaceholder();
    }
    final activeTab = via(tabBloom);
    return switch (activeTab) {
      0 => const StageA(),
      1 => const StageB(),
      _ => const StageC(),
    };
  });
}
''').unit;

      FunctionExpression? composedClosure;
      unit.visitChildren(_FunctionExpressionVisitor((func) {
        composedClosure = func;
      }));

      expect(composedClosure, isNotNull);
      expect(
          PreferComposedChild.containsHeavyStaticWidget(composedClosure!.body),
          isFalse);
    });

    test(
        'allows ternary conditional expression with single const widgets on each branch',
        () {
      final unit = parseString(content: '''
void main() {
  composed((via) => via(flagBloom)
      ? const StageA()
      : const StageB());
}
''').unit;

      FunctionExpression? composedClosure;
      unit.visitChildren(_FunctionExpressionVisitor((func) {
        composedClosure = func;
      }));

      expect(composedClosure, isNotNull);
      expect(
          PreferComposedChild.containsHeavyStaticWidget(composedClosure!.body),
          isFalse);
    });

    test(
        'detects heavy subtree when a branch inside switch expression contains multiple const widgets',
        () {
      final unit = parseString(content: '''
void main() {
  composed((via) => switch (via(tabBloom)) {
    0 => const StageA(),
    _ => Row(children: const [
      Icon(Icons.star),
      Icon(Icons.star_border),
    ]),
  });
}
''').unit;

      FunctionExpression? composedClosure;
      unit.visitChildren(_FunctionExpressionVisitor((func) {
        composedClosure = func;
      }));

      expect(composedClosure, isNotNull);
      expect(
          PreferComposedChild.containsHeavyStaticWidget(composedClosure!.body),
          isTrue);
    });

    test(
        'detects heavy subtree when early return branch contains multiple const widgets',
        () {
      final unit = parseString(content: '''
void main() {
  composed((via) {
    if (via(flagBloom)) {
      return Row(children: const [
        Icon(Icons.star),
        Icon(Icons.star_border),
      ]);
    }
    return const StageA();
  });
}
''').unit;

      FunctionExpression? composedClosure;
      unit.visitChildren(_FunctionExpressionVisitor((func) {
        composedClosure = func;
      }));

      expect(composedClosure, isNotNull);
      expect(
          PreferComposedChild.containsHeavyStaticWidget(composedClosure!.body),
          isTrue);
    });

    test(
        'allows dynamic interactive buttons with const icons and labels (ElevatedButton.icon, IconButton)',
        () {
      final unit = parseString(content: '''
void main() {
  composed((via) => Row(children: [
    ElevatedButton.icon(
      onPressed: via(isBusy) ? null : controller.next,
      icon: const Icon(Icons.skip_next),
      label: const Text('Next Step'),
    ),
    IconButton(
      icon: const Icon(Icons.close),
      onPressed: controller.close,
    ),
    IconButton.filledTonal(
      icon: const Icon(Icons.play_arrow),
      onPressed: controller.play,
    ),
  ]));
}
''').unit;

      FunctionExpression? composedClosure;
      unit.visitChildren(_FunctionExpressionVisitor((func) {
        composedClosure = func;
      }));

      expect(composedClosure, isNotNull);
      expect(
          PreferComposedChild.containsHeavyStaticWidget(composedClosure!.body),
          isFalse);
    });

    test('allows dynamic interactive buttons with const Text child', () {
      final unit = parseString(content: '''
void main() {
  composed((via) => Row(children: [
    ElevatedButton(
      onPressed: via(isBusy) ? null : controller.next,
      child: const Text('Next'),
    ),
    TextButton(
      onPressed: controller.close,
      child: const Text('Cancel'),
    ),
  ]));
}
''').unit;

      FunctionExpression? composedClosure;
      unit.visitChildren(_FunctionExpressionVisitor((func) {
        composedClosure = func;
      }));

      expect(composedClosure, isNotNull);
      expect(
          PreferComposedChild.containsHeavyStaticWidget(composedClosure!.body),
          isFalse);
    });
  });
}

class _FunctionExpressionVisitor extends RecursiveAstVisitor<void> {
  _FunctionExpressionVisitor(this.onFound);

  final void Function(FunctionExpression) onFound;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    onFound(node);
    super.visitFunctionExpression(node);
  }
}

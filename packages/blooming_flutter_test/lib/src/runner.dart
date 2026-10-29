// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scope.dart';

// =============================================================================
// bloomWidgetTest Declarative Widget Test Runner
// =============================================================================

final List<List<BloomOverride>> _activeOverridesStack = [];

/// Extension providing scoped widget pumping helpers on [WidgetTester].
extension BloomTesterScopeExtension on WidgetTester {
  /// Pumps [widget] wrapped inside a [BloomTestScope] with the given [overrides].
  ///
  /// If [overrides] is omitted, automatically inherits the active overrides defined
  /// on the enclosing [bloomWidgetTest] runner.
  ///
  /// * [widget]: The root widget subtree to wrap in [BloomTestScope] and pump.
  /// * [overrides]: Optional explicit list of [BloomOverride] mappings.
  /// * [duration]: Optional frame advance duration forwarded to [WidgetTester.pumpWidget].
  /// * [phase]: Target [EnginePhase] forwarded to [WidgetTester.pumpWidget].
  ///
  /// ## Examples
  /// ```dart
  /// bloomWidgetTest(
  ///   'renders offline banner on error',
  ///   overrides: [userListBloom.overrideWithError(SocketException('Offline'))],
  ///   test: (tester) async {
  ///     await tester.pumpScopedWidget(const MaterialApp(home: UserScreen()));
  ///     expect(find.text('Offline'), findsOneWidget);
  ///   },
  /// );
  /// ```
  Future<void> pumpScopedWidget(
    Widget widget, {
    List<BloomOverride>? overrides,
    Duration? duration,
    EnginePhase phase = EnginePhase.sendSemanticsUpdate,
  }) {
    final effectiveOverrides = overrides ??
        (_activeOverridesStack.isNotEmpty
            ? _activeOverridesStack.last
            : const <BloomOverride>[]);
    return pumpWidget(
      BloomTestScope(
        overrides: effectiveOverrides,
        child: widget,
      ),
      duration: duration,
      phase: phase,
    );
  }
}

/// A declarative, atomic Flutter widget test runner tailored for the Bloom reactive framework.
///
/// Wraps Flutter's native [testWidgets] runner and supports declarative [overrides]
/// that are automatically supplied when using [BloomTesterScopeExtension.pumpScopedWidget], or can be explicitly
/// wrapped via [BloomTestScope].
///
/// If [autoFlushLpdag] is `true`, automatically flushes pending LPDAG 2-Phase microtask ticks
/// and UI frames at the end of the test turn.
///
/// * [description]: The description of the widget test case.
/// * [overrides]: List of [BloomOverride] mappings automatically supplied to [BloomTesterScopeExtension.pumpScopedWidget].
/// * [test]: The widget test callback receiving the [WidgetTester].
/// * [autoFlushLpdag]: Whether to automatically pump a frame after [test] completes. Defaults to `true`.
/// * [skip]: Whether to skip this test case.
/// * [timeout]: Optional test execution [Timeout].
/// * [tags]: Optional test tags forwarded to [testWidgets].
///
/// ## Examples
/// ```dart
/// bloomWidgetTest(
///   'renders counter value',
///   overrides: [
///     counterBloom.overrideWithValue(42),
///   ],
///   test: (tester) async {
///     await tester.pumpScopedWidget(const CounterDisplay());
///     expect(find.text('42'), findsOneWidget);
///   },
/// );
/// ```
void bloomWidgetTest(
  String description, {
  List<BloomOverride> overrides = const [],
  required WidgetTesterCallback test,
  bool autoFlushLpdag = true,
  bool? skip,
  Timeout? timeout,
  dynamic tags,
}) {
  testWidgets(
    description,
    (tester) async {
      _activeOverridesStack.add(overrides);
      try {
        await test(tester);
        if (autoFlushLpdag) {
          await tester.pump();
        }
      } finally {
        _activeOverridesStack.removeLast();
      }
    },
    skip: skip,
    timeout: timeout,
    tags: tags,
  );
}

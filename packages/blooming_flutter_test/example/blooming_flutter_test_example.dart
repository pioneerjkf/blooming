// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
import 'package:blooming_flutter_test/blooming_flutter_test.dart';

// =============================================================================
// 1. Production UI Widgets
// =============================================================================

class User {
  const User({required this.name, required this.email});
  final String name;
  final String email;
}

base class UserHeaderWidget extends BloomWidget {
  const UserHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final userBloom = context.bloomOf<User>();
    final userState = via.state(userBloom);

    return switch (userState.phase) {
      BloomPhase.valid =>
        Text('Welcome, ${userState.data.name} (${userState.data.email})'),
      BloomPhase.empty => const Text('Loading user profile...'),
      BloomPhase.error => Text('Failed to load user: ${userState.error}'),
    };
  }
}

base class CounterScreen extends BloomWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final count = via.of<int>(context);
    return Scaffold(
      body: Center(
        child: Text('Current Count: $count'),
      ),
    );
  }
}

// =============================================================================
// 2. Complete Executable Widget Test Suite with blooming_flutter_test
// =============================================================================

void main() {
  group('blooming_flutter_test Real-World Widget Testing Showcase', () {
    // ---------------------------------------------------------------------------
    // Scenario 1: Mocking Tree-Level Dependencies with BloomTestScope
    // ---------------------------------------------------------------------------
    testWidgets('BloomTestScope injects mock User into descendant widgets',
        (tester) async {
      const mockUser = User(name: 'Alice', email: 'alice@example.com');

      await tester.pumpWidget(
        MaterialApp(
          home: BloomTestScope(
            overrides: [
              Bloom.constant(mockUser).asOverride(),
            ],
            child: const UserHeaderWidget(),
          ),
        ),
      );

      expect(find.text('Welcome, Alice (alice@example.com)'), findsOneWidget);
    });

    testWidgets('BloomTestScope overrides with simulated network error',
        (tester) async {
      final userBloom = BloomController<User>.late().bloom;

      await tester.pumpWidget(
        MaterialApp(
          home: BloomTestScope(
            overrides: [
              userBloom.overrideWithError('HTTP 500: Internal Server Error'),
            ],
            child: const UserHeaderWidget(),
          ),
        ),
      );

      expect(find.text('Failed to load user: HTTP 500: Internal Server Error'),
          findsOneWidget);
    });

    // ---------------------------------------------------------------------------
    // Scenario 2: Declarative bloomWidgetTest Runner + pumpScopedWidget
    // ---------------------------------------------------------------------------
    bloomWidgetTest(
      'bloomWidgetTest automatically configures overrides for pumpScopedWidget',
      overrides: [
        Bloom.constant(777).asOverride(),
      ],
      test: (tester) async {
        await tester.pumpScopedWidget(
          const MaterialApp(
            home: CounterScreen(),
          ),
        );

        expect(find.text('Current Count: 777'), findsOneWidget);
      },
    );

    // ---------------------------------------------------------------------------
    // Scenario 3: Reactive Widget Rebuilding on Upstream Mutation
    // ---------------------------------------------------------------------------
    bloomWidgetTest(
      'Widget rebuilds dynamically when BloomController mutates in test',
      test: (tester) async {
        final counter = BloomController(0);

        await tester.pumpScopedWidget(
          MaterialApp(
            home: BloomProvider<int>(
              bloom: counter.bloom,
              child: const CounterScreen(),
            ),
          ),
        );

        expect(find.text('Current Count: 0'), findsOneWidget);

        // Mutate controller state
        counter.data = 42;
        await tester.pump();

        expect(find.text('Current Count: 42'), findsOneWidget);
      },
    );
  });
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
import 'package:blooming_flutter_test/blooming_flutter_test.dart';

// Sample Models & Widgets for Testing
class UserProfile {
  const UserProfile(this.name);
  final String name;
}

base class UserProfileWidget extends BloomWidget {
  const UserProfileWidget({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final userBloom = context.bloomOf<UserProfile>();
    final userState = via.state(userBloom);

    return switch (userState.phase) {
      BloomPhase.valid => Text('User: ${userState.data.name}'),
      BloomPhase.empty => Text('No profile (${userState.emptyReason})'),
      BloomPhase.error => Text('Failed: ${userState.error}'),
    };
  }
}

base class CounterDisplay extends BloomWidget {
  const CounterDisplay({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final count = via.of<int>(context);
    return Text('Count: $count');
  }
}

void main() {
  group('blooming_flutter_test Unified Test Suite', () {
    // 1. Re-exported bloomTest from blooming_test works seamlessly
    bloomTest<BloomController<int>>(
      '1. Re-exported bloomTest executes pure unit test logic',
      build: () => BloomController(10),
      target: (ctrl) => ctrl.bloom,
      act: (ctrl) => ctrl.data = 20,
      expect: () => [10, 20],
      verify: (ctrl) {
        expect(ctrl.data, 20);
      },
    );

    // 2. BloomTestScope and BloomOverride with BloomWidget
    testWidgets('2. BloomTestScope overrides value for descendant BloomWidget',
        (tester) async {
      final mockNode = Bloom.constant(const UserProfile('Alice'));

      await tester.pumpWidget(
        MaterialApp(
          home: BloomTestScope(
            overrides: [
              mockNode.asOverride(),
            ],
            child: const UserProfileWidget(),
          ),
        ),
      );

      expect(find.text('User: Alice'), findsOneWidget);
    });

    testWidgets('3. BloomOverride with error renders error fallback UI',
        (tester) async {
      final userBloom =
          BloomController<UserProfile>(const UserProfile('Default')).bloom;

      await tester.pumpWidget(
        MaterialApp(
          home: BloomTestScope(
            overrides: [
              userBloom.overrideWithError(const SocketException('Offline')),
            ],
            child: const UserProfileWidget(),
          ),
        ),
      );

      expect(find.text('Failed: SocketException: Offline'), findsOneWidget);
    });

    testWidgets('4. BloomOverride with empty renders placeholder UI',
        (tester) async {
      final userBloom =
          BloomController<UserProfile>(const UserProfile('Default')).bloom;

      await tester.pumpWidget(
        MaterialApp(
          home: BloomTestScope(
            overrides: [
              userBloom.overrideWithEmpty('pending-sync'),
            ],
            child: const UserProfileWidget(),
          ),
        ),
      );

      expect(find.text('No profile (pending-sync)'), findsOneWidget);
    });

    // 5. bloomWidgetTest declarative runner with pumpScopedWidget
    bloomWidgetTest(
      '5. bloomWidgetTest declarative runner automatically injects active overrides',
      overrides: [
        Bloom.constant(99).asOverride(),
      ],
      test: (tester) async {
        await tester.pumpScopedWidget(
          const MaterialApp(
            home: CounterDisplay(),
          ),
        );

        expect(find.text('Count: 99'), findsOneWidget);
      },
    );

    // 6. Dynamic mutations inside test trigger UI updates through LPDAG 2-Phase
    bloomWidgetTest(
      '6. Dynamic mutations trigger reactive widget rebuilds in test',
      test: (tester) async {
        final counter = BloomController(0);

        await tester.pumpScopedWidget(
          MaterialApp(
            home: BloomProvider<int>(
              bloom: counter.bloom,
              child: const CounterDisplay(),
            ),
          ),
        );

        expect(find.text('Count: 0'), findsOneWidget);

        // Mutate state
        counter.data = 1;
        await tester.pump();

        expect(find.text('Count: 1'), findsOneWidget);
      },
    );
  });
}

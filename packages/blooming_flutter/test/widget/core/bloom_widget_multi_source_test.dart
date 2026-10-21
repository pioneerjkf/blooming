// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blooming_flutter/framework.dart';

// 1. Basic Multi-source BloomWidget
base class UserProfileBloomWidget extends BloomWidget {
  const UserProfileBloomWidget({
    super.key,
    required this.nameBloom,
    required this.ageBloom,
  });

  final Bloom<String> nameBloom;
  final Bloom<int> ageBloom;

  @override
  Widget build(BuildContext context, BloomVia via) {
    final name = via(nameBloom);
    final age = via(ageBloom);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text('$name: $age'),
    );
  }
}

// 2. Dynamic Branch Switching BloomWidget
base class DynamicBranchBloomWidget extends BloomWidget {
  const DynamicBranchBloomWidget({
    super.key,
    required this.usePrimaryBloom,
    required this.primaryBloom,
    required this.secondaryBloom,
  });

  final Bloom<bool> usePrimaryBloom;
  final Bloom<String> primaryBloom;
  final Bloom<String> secondaryBloom;

  @override
  Widget build(BuildContext context, BloomVia via) {
    final usePrimary = via(usePrimaryBloom);
    final content = usePrimary ? via(primaryBloom) : via(secondaryBloom);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(content),
    );
  }
}

void main() {
  group('BloomWidget & BloomElement Comprehensive Tests', () {
    testWidgets('Renders and dynamically updates when accessed blooms change',
        (tester) async {
      final nameController = BloomController<String>('Alice');
      final ageController = BloomController<int>(25);

      await tester.pumpWidget(
        UserProfileBloomWidget(
          nameBloom: nameController.bloom,
          ageBloom: ageController.bloom,
        ),
      );

      expect(find.text('Alice: 25'), findsOneWidget);

      // Mutate name
      nameController.set('Bob');
      await tester.pump();
      expect(find.text('Bob: 25'), findsOneWidget);

      // Mutate age
      ageController.set(30);
      await tester.pump();
      expect(find.text('Bob: 30'), findsOneWidget);
    });

    testWidgets(
        'Dynamically switches branches and prunes unobserved dependencies',
        (tester) async {
      final usePrimaryController = BloomController<bool>(true);
      final primaryController = BloomController<String>('Primary Content');
      final secondaryController = BloomController<String>('Secondary Content');

      await tester.pumpWidget(
        DynamicBranchBloomWidget(
          usePrimaryBloom: usePrimaryController.bloom,
          primaryBloom: primaryController.bloom,
          secondaryBloom: secondaryController.bloom,
        ),
      );

      // Initial: primary is watched
      expect(find.text('Primary Content'), findsOneWidget);

      // Mutating secondary should NOT trigger rebuild while branch is primary
      secondaryController.set('Updated Secondary');
      await tester.pump();
      expect(find.text('Primary Content'), findsOneWidget);

      // Switch branch to false -> watches secondary, prunes primary
      usePrimaryController.set(false);
      await tester.pump();
      expect(find.text('Updated Secondary'), findsOneWidget);

      // Mutating primary should now NOT trigger rebuild because primary was pruned!
      primaryController.set('Ignored Primary Update');
      await tester.pump();
      expect(find.text('Updated Secondary'), findsOneWidget);

      // Mutating secondary triggers rebuild
      secondaryController.set('Active Secondary');
      await tester.pump();
      expect(find.text('Active Secondary'), findsOneWidget);
    });

    testWidgets(
        'BloomWidget dynamically updates compute when widget configuration changes',
        (tester) async {
      final bloomA = BloomController<int>(10);
      final bloomB = BloomController<int>(20);

      await tester.pumpWidget(
        UserProfileBloomWidget(
          nameBloom: BloomController<String>('User').bloom,
          ageBloom: bloomA.bloom,
        ),
      );
      expect(find.text('User: 10'), findsOneWidget);

      // Update widget with new ageBloom (bloomB)
      await tester.pumpWidget(
        UserProfileBloomWidget(
          nameBloom: BloomController<String>('User').bloom,
          ageBloom: bloomB.bloom,
        ),
      );
      expect(find.text('User: 20'), findsOneWidget);

      // Mutate bloomB -> updates
      bloomB.set(99);
      await tester.pump();
      expect(find.text('User: 99'), findsOneWidget);
    });
  });
}

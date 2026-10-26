// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:blooming_flutter/framework.dart';
import '../../models/section.dart';
import '../../sections/watch_widget_section.dart';

/// Sub-store for Section 01: BloomWidget & Dynamic Discovery
class BloomWidgetStore {
  final _counter = blooming<int>(0);
  final _userStatus = blooming<String>('Online');
  final _showDetails = blooming<bool>(false);

  Bloom<int> get counter => _counter.bloom;
  Bloom<String> get userStatus => _userStatus.bloom;
  Bloom<bool> get showDetails => _showDetails.bloom;

  void increment() => _counter.set(_counter.data + 1);
  void reset() => _counter.set(0);
  void toggleDetails(bool value) => _showDetails.set(value);
  void cycleUserStatus() {
    final current = _userStatus.data;
    _userStatus.set(
      current == 'Online' ? 'Away' : (current == 'Away' ? 'Busy' : 'Online'),
    );
  }

  ShowcaseSection get section => ShowcaseSection(
        id: '01_watch_widget',
        number: '01',
        title: 'BloomWidget & Dynamic Discovery',
        subtitle: 'Explicit BloomVia manifest & 1-pass epoch sweeping',
        badge: 'Widgets',
        icon: Icons.visibility_rounded,
        codeSnippet: '''
import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

final counterController = blooming<int>(0);

base class UserCounterCard extends BloomWidget {
  UserCounterCard({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    // Explicit BloomVia dependency manifest (Zero tracking stack overhead)
    final count = via(counterController.bloom);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Current Count: \$count'),
      ),
    );
  }
}''',
        highlights: const [
          'Explicit BloomVia Manifest: Dynamically tracks only nodes accessed in executed branches.',
          '1-Pass Zero-Allocation Epoch Sweeping: Automatically detaches inactive graph edges.',
          'Extends ComponentElement directly, eliminating standard StatefulWidget boilerplate.',
        ],
        roadmapTree: '''
BloomWidget (ComponentElement integration)
 ├── BloomVia (via(bloom))    -> Explicit dependency manifest & dynamic discovery
 └── 1-Pass Epoch Sweeping       -> Automatically prunes unexecuted conditional branches
''',
        builder: () => BloomWidgetSectionDemo(),
      );
}

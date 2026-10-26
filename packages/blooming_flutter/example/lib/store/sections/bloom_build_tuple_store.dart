// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
import '../../models/section.dart';
import '../../sections/bloom_build_tuple_section.dart';

/// Sub-store for Section 03: bloom.build & Inline Cascades
class BloomBuildTupleStore {
  final _user = blooming<String>('Alice');
  final _score = blooming<int>(2500);
  final _rank = blooming<int>(1);
  final _cascadeMode =
      blooming<int>(0); // 0: direct, 1: context, 2: child, 3: children

  Bloom<String> get user => _user.bloom;
  Bloom<int> get score => _score.bloom;
  Bloom<int> get rank => _rank.bloom;
  Bloom<int> get cascadeMode => _cascadeMode.bloom;

  void nextPlayer() {
    final current = _user.data;
    _user.set(
        current == 'Alice' ? 'Bob' : (current == 'Bob' ? 'Charlie' : 'Alice'));
  }

  void addXp() => _score.set(_score.data + 250);

  void improveRank() {
    final current = _rank.data;
    _rank.set(current > 1 ? current - 1 : 5);
  }

  void selectCascadeMode(int mode) => _cascadeMode.set(mode);

  ShowcaseSection get section => ShowcaseSection(
        id: '03_bloom_build_tuple',
        number: '03',
        title: 'bloom.build & Direct Value Cascades',
        subtitle: 'Zero-cost direct value binding & multi-node composition',
        badge: 'Functors',
        icon: Icons.data_object_rounded,
        codeSnippet: '''
// 1. Direct value binding (Zero runtime allocation via extension type const):
counterBloom.build((context, count) => Text('Count: \$count'));

// 2. bloom.build with Child Caching:
scoreBloom.build.child(
  (context, score, child) => Row(children: [child, Text('XP: \$score')]),
  child: const TrophyIcon(),
);

// 3. bloom.build with Children List:
rankBloom.build.children(
  (context, rank, children) => Row(children: [...children, Text('Rank #\$rank')]),
  children: const [Icon(Icons.military_tech), Icon(Icons.star)],
);

// 4. Multi-Node Dynamic Discovery Composition:
composed(
  (context, via) => LeaderboardCard(
    user: via(userBloom),
    score: via(scoreBloom),
    rank: via(rankBloom),
  ),
);''',
        highlights: const [
          'Zero runtime allocation overhead via Dart extension types (extension type const).',
          'Always injected BuildContext matching canonical Flutter builder signatures.',
          'Direct pathways (.child, .children) for optimal static subtree caching.',
          'Surgical single-node direct value unboxing for maximum performance.',
          'Seamless multi-node dynamic discovery via composed((via) => ...).',
        ],
        roadmapTree: '''
bloom.build           ((data) => ...)
 ├── .context         ((context, data) => ...)
 │    ├── .child      ((context, data, child) => ..., child: ...)
 │    └── .children   ((context, data, children) => ..., children: ...)
 ├── .child           ((data, child) => ..., child: ...)
 │    └── .context    ((context, data, child) => ..., child: ...)
 └── .children        ((data, children) => ..., children: ...)
      └── .context    ((context, data, children) => ..., children: ...)

composed((via) => ...)    [Multi-Node Dynamic Discovery & 1-Pass Epoch Sweeping]
''',
        builder: () => BloomBuildTupleSectionDemo(),
      );
}

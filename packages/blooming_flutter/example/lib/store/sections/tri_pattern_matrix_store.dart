// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
import '../../models/section.dart';
import '../../sections/tri_pattern_matrix_section.dart';

/// Sub-store for Section 12: Tri-Pattern Animation Matrix (3 Canonical Ways Side-by-Side)
class TriPatternMatrixStore {
  TriPatternMatrixStore()
      : controller = DurableAnimationController(
          duration: const Duration(seconds: 6),
        ),
        _isMounted = blooming<bool>(true),
        _patternABuildCount = blooming<int>(0),
        _patternBBuildCount = blooming<int>(0),
        _patternCBuildCount = blooming<int>(0) {
    controller.repeat();
  }

  final DurableAnimationController controller;
  final BloomController<bool> _isMounted;
  Bloom<bool> get isMounted => _isMounted.bloom;

  final BloomController<int> _patternABuildCount;
  Bloom<int> get patternABuildCount => _patternABuildCount.bloom;

  final BloomController<int> _patternBBuildCount;
  Bloom<int> get patternBBuildCount => _patternBBuildCount.bloom;

  final BloomController<int> _patternCBuildCount;
  Bloom<int> get patternCBuildCount => _patternCBuildCount.bloom;

  void toggleMount() => _isMounted.set(!_isMounted.data);

  void toggleDirection() => controller.toggle();

  void resumeRepeat() => controller.repeat();

  void togglePingPong() => controller.repeat(reverse: true);

  ShowcaseSection get section => ShowcaseSection(
        id: '14_tri_pattern_matrix',
        number: '14',
        title: 'Tri-Pattern Animation Matrix',
        subtitle:
            '3 canonical pathways: composed.animate, composed.drive, composed.animate.child',
        badge: '3 Pathways',
        icon: Icons.account_tree_rounded,
        codeSnippet: '''
// =============================================================================
// [3 Canonical Composed Animation Pathways]
// =============================================================================

// Pattern A: Functional Inline composed.animate (Controller-driven reactive composition)
composed.animate(
  storeCtrl,
  (context, via, ctrl) => RotationTransition(turns: ctrl.view, child: const Icon(Icons.hub)),
);

// Pattern B: Autonomous Continuous composed.drive (Zero-controller frame ticker)
composed.drive(
  (elapsed) => (elapsed.inMilliseconds % 2000) / 2000.0,
  (context, via, turns) => Transform.rotate(angle: turns * 2 * pi, child: const Icon(Icons.grain)),
);

// Pattern C: Static Child Memoization composed.animate.child (Controller + GPU isolation)
composed.animate.child(
  storeCtrl,
  (context, via, ctrl, child) => RotationTransition(turns: ctrl.view, child: child),
  child: const HeavyAssetWidget(), // Repaints on GPU without widget rebuilds!
);''',
        highlights: const [
          '3 Canonical Pathways: composed.animate, composed.drive, and composed.animate.child.',
          'Pattern A & C: Bound to external DurableAnimationController timeline.',
          'Pattern B (composed.drive): Runs autonomously on raw frame ticks without requiring a controller.',
          'Zero-Rebuild GPU Repaints: Heavy widget isolation via .animate.child prevents unnecessary subtree rebuilds.',
        ],
        roadmapTree: '''
[Canonical Animation & Wake Matrix]
 ├── Pattern A: composed.animate(ctrl, ...)            [Controller-Bound]
 ├── Pattern B: composed.drive(onTick, ...)            [Autonomous Frame Ticker]
 └── Pattern C: composed.animate.child(ctrl, ..., child: ...) [Static Child Isolation]
''',
        builder: () => const TriPatternMatrixSectionDemo(),
      );
}

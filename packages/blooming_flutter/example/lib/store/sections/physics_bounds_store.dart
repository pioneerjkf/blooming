// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
import '../../models/section.dart';
import '../../sections/physics_bounds_section.dart';

/// Sub-store for Section 14: Physics Simulation Arena (Spring, Gravity, Friction & Dual Engine Comparison)
class PhysicsBoundsStore {
  PhysicsBoundsStore({DateTime Function()? clock})
      : physicsBoundedFrozenCtrl = DurableAnimationController(
          policy: DurabilityPolicy.resume,
          value: 1.0,
          duration: const Duration(seconds: 4),
        ),
        physicsBoundedCatchUpCtrl = DurableAnimationController(
          policy: DurabilityPolicy.catchUp,
          value: 1.0,
          duration: const Duration(seconds: 4),
          clock: clock ?? DateTime.now,
        ),
        _springStiffness = blooming<double>(60.0),
        _springDamping = blooming<double>(12.0),
        _frictionDrag = blooming<double>(0.08),
        _isMounted = blooming<bool>(true);

  final DurableAnimationController physicsBoundedFrozenCtrl;
  final DurableAnimationController physicsBoundedCatchUpCtrl;
  final BloomController<double> _springStiffness;
  final BloomController<double> _springDamping;
  final BloomController<double> _frictionDrag;
  final BloomController<bool> _isMounted;

  Bloom<double> get springStiffness => _springStiffness.bloom;
  Bloom<double> get springDamping => _springDamping.bloom;
  Bloom<double> get frictionDrag => _frictionDrag.bloom;
  Bloom<bool> get isMounted => _isMounted.bloom;

  /// Cached reactive bridge nodes observing controller progress (zero allocation in build).
  late final Bloom<double> frozenProgress = physicsBoundedFrozenCtrl.observe();
  late final Bloom<double> catchUpProgress =
      physicsBoundedCatchUpCtrl.observe();

  void toggleMount() => _isMounted.set(!_isMounted.data);
  void setSpringStiffness(double v) => _springStiffness.set(v);
  void setSpringDamping(double v) => _springDamping.set(v);
  void setFrictionDrag(double v) => _frictionDrag.set(v);

  void runSpringSimulation() {
    physicsBoundedFrozenCtrl.value = 0.0;
    physicsBoundedCatchUpCtrl.value = 0.0;
    final sim1 = SpringSimulation(
      SpringDescription(
        mass: 1.0,
        stiffness: untracked(springStiffness),
        damping: untracked(springDamping),
      ),
      0.0, // Apex (Air)
      1.0, // Ground (Settled position)
      2.5, // Initial velocity
      snapToEnd: true,
    );
    final sim2 = SpringSimulation(
      SpringDescription(
        mass: 1.0,
        stiffness: untracked(springStiffness),
        damping: untracked(springDamping),
      ),
      0.0,
      1.0,
      2.5,
      snapToEnd: true,
    );
    physicsBoundedFrozenCtrl.animateWith(sim1);
    physicsBoundedCatchUpCtrl.animateWith(sim2);
  }

  void runGravitySimulation() {
    physicsBoundedFrozenCtrl.value = 0.0;
    physicsBoundedCatchUpCtrl.value = 0.0;
    final sim1 = GravitySimulation(4.9, 0.0, 1.0, 0.0);
    final sim2 = GravitySimulation(4.9, 0.0, 1.0, 0.0);
    physicsBoundedFrozenCtrl.animateWith(sim1);
    physicsBoundedCatchUpCtrl.animateWith(sim2);
  }

  void runFrictionSimulation() {
    physicsBoundedFrozenCtrl.value = 0.0;
    physicsBoundedCatchUpCtrl.value = 0.0;
    final sim1 = FrictionSimulation(untracked(frictionDrag), 0.0, 1.2);
    final sim2 = FrictionSimulation(untracked(frictionDrag), 0.0, 1.2);
    physicsBoundedFrozenCtrl.animateWith(sim1);
    physicsBoundedCatchUpCtrl.animateWith(sim2);
  }

  // --- Integrated Flapping Stress Test (Merged from SimulationFlapping) ---
  final BloomController<bool> _isFlappingRunning = blooming<bool>(false);
  final BloomController<int> _flappingCycles = blooming<int>(0);

  Bloom<bool> get isFlappingRunning => _isFlappingRunning.bloom;
  Bloom<int> get flappingCycles => _flappingCycles.bloom;

  Future<void> runFlappingStress(int targetCycles) async {
    if (_isFlappingRunning.data) return;
    _isFlappingRunning.set(true);
    _flappingCycles.set(0);

    for (int i = 1; i <= targetCycles; i++) {
      if (!_isFlappingRunning.data) break;
      _isMounted.set(false);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      _isMounted.set(true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      _flappingCycles.set(i);
    }
    _isFlappingRunning.set(false);
  }

  void stopFlappingStress() {
    _isFlappingRunning.set(false);
    _isMounted.set(true);
  }

  ShowcaseSection get section => ShowcaseSection(
        id: '17_physics_bounds',
        number: '17',
        title: 'Physics Dynamics & Simulation Flapping Lab',
        subtitle:
            'Spring, Gravity, Friction simulations & rapid mounting flapping stress',
        badge: 'Physics & Stress',
        icon: Icons.sports_volleyball_rounded,
        codeSnippet: '''
// =============================================================================
// [1. Frozen vs CatchUp Physics Simulations (Spring, Gravity, Friction)]
// =============================================================================
final frozenPhysics = DurableAnimationController(policy: DurabilityPolicy.resume);
final catchUpPhysics = DurableAnimationController(policy: DurabilityPolicy.catchUp);

// Both run identical SpringSimulation:
final spring = SpringSimulation(
  const SpringDescription(mass: 1.0, stiffness: 60.0, damping: 12.0),
  0.0, 1.0, 2.5,
);
frozenPhysics.animateWith(spring);
catchUpPhysics.animateWith(spring);

// 2. High-Frequency Flapping Resilience under Active Physics:
// Subject to rapid 20ms mount/unmount churn without TickerCanceled exceptions!''',
        highlights: const [
          'Physics Simulation: Drive controllers using Spring, Gravity, and Friction simulations.',
          'Dual Engine Comparison: Compare Frozen (freeze in air) vs CatchUp (wall-clock drop) side-by-side.',
          'Dynamic Parameter Sliders: Real-time control over spring stiffness, damping, and friction coefficients.',
          'Rapid Flapping Stress: Validates 0 TickerCanceled exceptions under active physics simulations.',
        ],
        roadmapTree: '''
[Flutter Physics Simulation Hierarchy]
 ├── SpringSimulation       (Elastic mass-spring-damper oscillator)
 ├── GravitySimulation      (Gravitational acceleration drop)
 ├── FrictionSimulation     (Decelerating kinematic friction)
 └── Stress Resilience
      ├── Rapid Flapping    (Mount/unmount churning under active simulations)
      └── Wall-Clock Warp   (Compensates physics trajectory across dormancy)
''',
        builder: () => PhysicsBoundsSectionDemo(),
      );
}

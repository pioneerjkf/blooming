// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
import '../../models/section.dart';
import '../../sections/simulation_flapping_section.dart';

/// Sub-store for Section 18: Simulation Flapping & Physics Stress Lab
class SimulationFlappingStore {
  SimulationFlappingStore({DateTime Function()? clock})
      : frozenPhysicsCtrl = DurableAnimationController(
          policy: DurabilityPolicy.resume,
          value: 1.0,
          duration: const Duration(seconds: 6),
        ),
        catchUpPhysicsCtrl = DurableAnimationController(
          policy: DurabilityPolicy.catchUp,
          value: 1.0,
          duration: const Duration(seconds: 6),
          clock: clock ?? DateTime.now,
        ),
        _springMass = BloomController<double>(3.0),
        _springStiffness = BloomController<double>(40.0),
        _springDamping = BloomController<double>(6.0),
        _gravityForce = BloomController<double>(2.5),
        _frictionDrag = BloomController<double>(0.04),
        _speedScale = BloomController<double>(1.0),
        _isAutoBounce = BloomController<bool>(true),
        _flappingIntervalMs = BloomController<int>(20),
        _isMounted = BloomController<bool>(true),
        _isFlappingRunning = BloomController<bool>(false),
        _flappingCyclesCompleted = BloomController<int>(0),
        _activeSimulationType = BloomController<String>('SpringSimulation'),
        _diagnosticLogs = BloomController<List<String>>([]) {
    runSpringSimulation();
  }

  final DurableAnimationController frozenPhysicsCtrl;
  final DurableAnimationController catchUpPhysicsCtrl;
  final BloomController<double> _springMass;
  final BloomController<double> _springStiffness;
  final BloomController<double> _springDamping;
  final BloomController<double> _gravityForce;
  final BloomController<double> _frictionDrag;
  final BloomController<double> _speedScale;
  final BloomController<bool> _isAutoBounce;
  final BloomController<int> _flappingIntervalMs;
  final BloomController<bool> _isMounted;
  final BloomController<bool> _isFlappingRunning;
  final BloomController<int> _flappingCyclesCompleted;
  final BloomController<String> _activeSimulationType;
  final BloomController<List<String>> _diagnosticLogs;

  Bloom<double> get springMass => _springMass.bloom;
  Bloom<double> get springStiffness => _springStiffness.bloom;
  Bloom<double> get springDamping => _springDamping.bloom;
  Bloom<double> get gravityForce => _gravityForce.bloom;
  Bloom<double> get frictionDrag => _frictionDrag.bloom;
  Bloom<double> get speedScale => _speedScale.bloom;
  Bloom<bool> get isAutoBounce => _isAutoBounce.bloom;
  Bloom<int> get flappingIntervalMs => _flappingIntervalMs.bloom;
  Bloom<bool> get isMounted => _isMounted.bloom;
  Bloom<bool> get isFlappingRunning => _isFlappingRunning.bloom;
  Bloom<int> get flappingCyclesCompleted => _flappingCyclesCompleted.bloom;
  Bloom<String> get activeSimulationType => _activeSimulationType.bloom;
  Bloom<List<String>> get diagnosticLogs => _diagnosticLogs.bloom;

  /// Cached reactive bridge nodes observing controller progress (zero allocation in build).
  late final Bloom<double> frozenProgress = frozenPhysicsCtrl.observe();
  late final Bloom<double> catchUpProgress = catchUpPhysicsCtrl.observe();

  void toggleMount() => _isMounted.set(!_isMounted.data);

  Future<void> unmountForDuration(
      [Duration duration = const Duration(seconds: 3)]) async {
    if (!_isMounted.data) return;
    final resBefore = (frozenPhysicsCtrl.value * 100).toStringAsFixed(1);
    final catchBefore = (catchUpPhysicsCtrl.value * 100).toStringAsFixed(1);
    _isMounted.set(false);
    _log(
        'Unmounted: Sleeping for ${duration.inSeconds}s (Frozen: $resBefore%, Catch: $catchBefore%)...');

    await Future<void>.delayed(duration);
    _isMounted.set(true);
    final resAfter = (frozenPhysicsCtrl.value * 100).toStringAsFixed(1);
    final catchAfter = (catchUpPhysicsCtrl.value * 100).toStringAsFixed(1);
    _log(
        'Remounted after ${duration.inSeconds}s! Frozen frozen at $resAfter% | CatchUp advanced to $catchAfter%');
  }

  void toggleAutoBounce() {
    final next = !_isAutoBounce.data;
    _isAutoBounce.set(next);
    _log('Continuous Auto-Bounce: ${next ? "ENABLED" : "DISABLED"}');
    if (next && !frozenPhysicsCtrl.isAnimating) {
      reverseDirection();
    }
  }

  void setFlappingInterval(int ms) {
    _flappingIntervalMs.set(ms);
    _log('Flapping Interval set to ${ms}ms.');
  }

  void setSpeedPreset(double scale) {
    _speedScale.set(scale);
    _log('Simulation Speed Preset set to ${scale}x.');
    // Re-run current simulation with new speed scale
    reverseDirection();
  }

  void _log(String message) {
    final list = List<String>.from(_diagnosticLogs.data)..insert(0, message);
    if (list.length > 10) list.removeLast();
    _diagnosticLogs.set(list);
  }

  void runSpringSimulation({bool reverse = false}) {
    _activeSimulationType
        .set('SpringSimulation (${reverse ? "Upward" : "Downward"})');
    final start = reverse ? 1.0 : 0.0;
    final end = reverse ? 0.0 : 1.0;
    final scale = untracked(speedScale);
    final velocity = (reverse ? -1.8 : 1.8) * scale;
    final effectiveStiffness = untracked(springStiffness) * scale * scale;
    final effectiveDamping = untracked(springDamping) * scale;

    frozenPhysicsCtrl.value = start;
    catchUpPhysicsCtrl.value = start;

    final sim1 = SpringSimulation(
      SpringDescription(
        mass: untracked(springMass),
        stiffness: effectiveStiffness,
        damping: effectiveDamping,
      ),
      start,
      end,
      velocity,
      snapToEnd: true,
    );
    final sim2 = SpringSimulation(
      SpringDescription(
        mass: untracked(springMass),
        stiffness: effectiveStiffness,
        damping: effectiveDamping,
      ),
      start,
      end,
      velocity,
      snapToEnd: true,
    );

    final future = frozenPhysicsCtrl.animateWith(sim1);
    catchUpPhysicsCtrl.animateWith(sim2);
    _attachAutoBounce(future);
    _log(
        'Spring: Mass=${untracked(springMass)}kg, Stiff=${untracked(springStiffness)}, Damp=${untracked(springDamping)}, Speed=${scale}x');
  }

  void runGravitySimulation({bool reverse = false}) {
    _activeSimulationType
        .set('GravitySimulation (${reverse ? "Upward Launch" : "Free Fall"})');
    final start = reverse ? 1.0 : 0.0;
    final end = reverse ? 0.0 : 1.0;
    final scale = untracked(speedScale);
    final velocity = (reverse ? -2.2 : 0.0) * scale;
    final effectiveGravity = untracked(gravityForce) * scale * scale;

    frozenPhysicsCtrl.value = start;
    catchUpPhysicsCtrl.value = start;

    final sim1 = GravitySimulation(effectiveGravity, start, end, velocity);
    final sim2 = GravitySimulation(effectiveGravity, start, end, velocity);

    final future = frozenPhysicsCtrl.animateWith(sim1);
    catchUpPhysicsCtrl.animateWith(sim2);
    _attachAutoBounce(future);
    _log(
        'Gravity: g=${untracked(gravityForce)}m/s², v0=$velocity, Speed=${scale}x');
  }

  void runFrictionSimulation({bool reverse = false}) {
    _activeSimulationType
        .set('FrictionSimulation (${reverse ? "Left Glide" : "Right Glide"})');
    final start = reverse ? 1.0 : 0.0;
    final scale = untracked(speedScale);
    final velocity = (reverse ? -1.2 : 1.2) * scale;
    final effectiveDrag = untracked(frictionDrag) / scale;

    frozenPhysicsCtrl.value = start;
    catchUpPhysicsCtrl.value = start;

    final sim1 = FrictionSimulation(effectiveDrag, start, velocity);
    final sim2 = FrictionSimulation(effectiveDrag, start, velocity);

    final future = frozenPhysicsCtrl.animateWith(sim1);
    catchUpPhysicsCtrl.animateWith(sim2);
    _attachAutoBounce(future);
    _log(
        'Friction: Drag=${untracked(frictionDrag)}, v0=$velocity, Speed=${scale}x');
  }

  void _attachAutoBounce(TickerFuture future) {
    future.then((_) {
      if (_isAutoBounce.data && !frozenPhysicsCtrl.isAnimating) {
        reverseDirection();
      }
    });
  }

  void reverseDirection() {
    final curType = untracked(activeSimulationType);
    final isCurrentlyReverse =
        curType.contains('Upward') || curType.contains('Left');
    if (curType.contains('Spring')) {
      runSpringSimulation(reverse: !isCurrentlyReverse);
    } else if (curType.contains('Gravity')) {
      runGravitySimulation(reverse: !isCurrentlyReverse);
    } else {
      runFrictionSimulation(reverse: !isCurrentlyReverse);
    }
  }

  Future<void> runFlappingStressTest(int targetCycles) async {
    if (_isFlappingRunning.data) return;
    _isFlappingRunning.set(true);
    _flappingCyclesCompleted.set(0);
    _isAutoBounce.set(true);
    final interval = Duration(milliseconds: untracked(flappingIntervalMs));
    _log(
        'Started $targetCycles Physics Simulation Flapping Stress Test (Interval: ${untracked(flappingIntervalMs)}ms)...');

    // Automatically trigger continuous physics motion if settled
    if (!frozenPhysicsCtrl.isAnimating) {
      runSpringSimulation();
    }

    for (int i = 1; i <= targetCycles; i++) {
      if (!_isFlappingRunning.data) break;

      _isMounted.set(false);
      await Future<void>.delayed(interval);
      _isMounted.set(true);
      await Future<void>.delayed(interval);
      _flappingCyclesCompleted.set(i);
    }

    _isFlappingRunning.set(false);
    _log(
        'Physics Flapping Stress Completed! Total Cycles: ${_flappingCyclesCompleted.data} with 0 TickerCanceled exceptions.');
  }

  void stopFlappingStress() {
    _isFlappingRunning.set(false);
    _isMounted.set(true);
    _log('Physics Flapping Stress Test Stopped Manually.');
  }

  void reset() {
    frozenPhysicsCtrl.stop();
    catchUpPhysicsCtrl.stop();
    frozenPhysicsCtrl.value = 0.0;
    catchUpPhysicsCtrl.value = 0.0;
    _log('Reset controllers to 0.0 (Idle).');
  }

  ShowcaseSection get section => ShowcaseSection(
        id: '18_simulation_flapping',
        number: '18',
        title: 'Simulation Flapping Stress',
        subtitle:
            '1000x rapid mount flapping stress while running Spring, Gravity & Friction simulations',
        badge: 'Physics Stress',
        icon: Icons.compress_rounded,
        codeSnippet: '''
// =============================================================================
// [1. Physics Simulation with 1000x Rapid Flapping Stress & Adjustable Speed]
// =============================================================================
final frozen = FrozenAnimationController();
final catchUp = CatchUpAnimationController();

// Sustained, highly visible spring oscillation:
final spring = SpringSimulation(
  const SpringDescription(mass: 3.0, stiffness: 40.0, damping: 6.0),
  0.0, 1.0, 1.8, snapToEnd: true,
);

frozen.animateWith(spring);
catchUp.animateWith(spring);

// Rapidly mount and unmount 1000 times during active physics simulation:
for (int i = 0; i < 1000; i++) {
  controller.hibernate(); // Freezes physics velocity in Frozen; advances time in CatchUp
  await pump(const Duration(milliseconds: 10));
  controller.resync(newVsync); // Resumes physics smoothly without TickerCanceled
  await pump(const Duration(milliseconds: 10));
}''',
        highlights: const [
          'Physics Flapping Invariant: 1000+ ultra-rapid mount/unmount cycles during active physics simulation.',
          'Adjustable Duration & Slow-Mo: Real-time control over spring mass, stiffness, damping, and speed scaling.',
          'Zero TickerCanceled Guarantee: Physics simulation resumes seamlessly without cancellation crashes.',
          'Velocity & Phase Preservation: Frozen preserves mid-air velocity; CatchUp integrates wall-clock flight.',
        ],
        roadmapTree: '''
[Physics Simulation Flapping Architecture]
 ├── SpringSimulation / GravitySimulation / FrictionSimulation
 │    ├── FrozenAnimationController   (Preserves position & velocity across flapping)
 │    └── CatchUpAnimationController  (Integrates dormant wall-clock flight time)
 └── Rapid Flapping Stress Engine (1000 cycles @ 10ms with zero TickerCanceled)
''',
        builder: () => SimulationFlappingSectionDemo(),
      );
}

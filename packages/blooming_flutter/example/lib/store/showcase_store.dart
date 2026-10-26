// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
import '../models/section.dart';
import 'sections/adaptive_proxies_store.dart';
import 'sections/composed_functors_store.dart';
import 'sections/dormant_thrashing_store.dart';
import 'sections/dual_engine_battle_store.dart';
import 'sections/foundation_bridge_store.dart';
import 'sections/frame_scheduler_store.dart';
import 'sections/bloom_build_tuple_store.dart';
import 'sections/google_adversarial_store.dart';
import 'sections/physics_bounds_store.dart';
import 'sections/reactive_effects_store.dart';
import 'sections/scoped_state_di_store.dart';
import 'sections/simulation_flapping_store.dart';
import 'sections/temporal_orchestration_store.dart';
import 'sections/tri_pattern_matrix_store.dart';
import 'sections/unbounded_coordinates_store.dart';
import 'sections/watch_widget_store.dart';
import 'sections/async_swr_builder_store.dart';
import 'sections/text_editing_controller_store.dart';
import 'sections/imperative_signals_store.dart';
import 'sections/scroll_kinematics_store.dart';
import 'sections/composite_motion_store.dart';

export 'sections/adaptive_proxies_store.dart';
export 'sections/composed_functors_store.dart';
export 'sections/dormant_thrashing_store.dart';
export 'sections/dual_engine_battle_store.dart';
export 'sections/foundation_bridge_store.dart';
export 'sections/frame_scheduler_store.dart';
export 'sections/bloom_build_tuple_store.dart';
export 'sections/google_adversarial_store.dart';
export 'sections/physics_bounds_store.dart';
export 'sections/reactive_effects_store.dart';
export 'sections/scoped_state_di_store.dart';
export 'sections/simulation_flapping_store.dart';
export 'sections/temporal_orchestration_store.dart';
export 'sections/tri_pattern_matrix_store.dart';
export 'sections/unbounded_coordinates_store.dart';
export 'sections/watch_widget_store.dart';
export 'sections/async_swr_builder_store.dart';
export 'sections/text_editing_controller_store.dart';
export 'sections/imperative_signals_store.dart';
export 'sections/scroll_kinematics_store.dart';
export 'sections/composite_motion_store.dart';

/// Root Store managing showcase shell navigation and all section sub-stores.
///
/// Pure instance-based dependency injection store without any global singletons.
class ShowcaseStore {
  ShowcaseStore({
    int initialIndex = 0,
    ThemeMode initialThemeMode = ThemeMode.system,
    bool initialSidebarOpen = true,
    DateTime Function()? clock,
    Graceful? textEditingGraceful = Graceful.microtask,
  })  : _activeIndex = blooming<int>(initialIndex),
        _themeMode = blooming<ThemeMode>(initialThemeMode),
        _isSidebarOpen = blooming<bool>(initialSidebarOpen),
        sections = SectionsStore(
          clock: clock,
          textEditingGraceful: textEditingGraceful,
        );

  final BloomController<int> _activeIndex;
  final BloomController<ThemeMode> _themeMode;
  final BloomController<bool> _isSidebarOpen;
  final BloomController<int> _mobileTabIndex = blooming<int>(0);

  /// Currently selected section index.
  Bloom<int> get activeIndex => _activeIndex.bloom;

  /// Current theme mode (System/Light/Dark).
  Bloom<ThemeMode> get themeMode => _themeMode.bloom;

  /// Whether the left navigation sidebar is open/expanded.
  Bloom<bool> get isSidebarOpen => _isSidebarOpen.bloom;

  /// Active tab index for mobile view (0: Live Demo, 1: Core Code).
  Bloom<int> get mobileTabIndex => _mobileTabIndex.bloom;

  /// Sets the mobile tab index.
  void setMobileTab(int tab) => _mobileTabIndex.set(tab);

  /// Hierarchical section sub-stores container.
  final SectionsStore sections;

  /// Toggles the left navigation sidebar.
  void toggleSidebar() => _isSidebarOpen.set(!_isSidebarOpen.data);

  /// Selects a specific section by index.
  void selectSection(int index, [int? maxCount]) {
    if (index >= 0 && (maxCount == null || index < maxCount)) {
      _activeIndex.set(index);
    }
  }

  /// Navigates to the next section.
  void nextSection(int maxCount) {
    if (_activeIndex.data < maxCount - 1) {
      _activeIndex.set(_activeIndex.data + 1);
    }
  }

  /// Navigates to the previous section.
  void prevSection() {
    if (_activeIndex.data > 0) {
      _activeIndex.set(_activeIndex.data - 1);
    }
  }

  /// Cycles between System, Light, and Dark mode.
  void toggleTheme() {
    switch (_themeMode.data) {
      case ThemeMode.system:
        _themeMode.set(ThemeMode.light);
        break;
      case ThemeMode.light:
        _themeMode.set(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        _themeMode.set(ThemeMode.system);
        break;
    }
  }

  /// Sets the theme mode directly.
  void setThemeMode(ThemeMode mode) => _themeMode.set(mode);
}

/// Composite container holding individual sub-stores for each showcase section.
class SectionsStore {
  SectionsStore({
    DateTime Function()? clock,
    Graceful? textEditingGraceful = Graceful.microtask,
  })  : bloomWidget = BloomWidgetStore(),
        composedFunctors = ComposedFunctorsStore(),
        bloomBuildTuple = BloomBuildTupleStore(),
        scopedStateDi = ScopedStateDiStore(),
        dualEngineBattle = DualEngineBattleStore(clock: clock),
        dormantThrashing = DormantThrashingStore(clock: clock),
        triPatternMatrix = TriPatternMatrixStore(),
        compositeMotion = CompositeMotionStore(clock: clock),
        physicsBounds = PhysicsBoundsStore(clock: clock),
        unboundedCoordinates = UnboundedCoordinatesStore(clock: clock),
        googleAdversarial = GoogleAdversarialStore(clock: clock),
        frameScheduler = FrameSchedulerStore(),
        foundationBridge = FoundationBridgeStore(),
        adaptiveProxies = AdaptiveProxiesStore(),
        simulationFlapping = SimulationFlappingStore(clock: clock),
        reactiveEffects = ReactiveEffectsStore(),
        temporalOrchestration = TemporalOrchestrationStore(),
        asyncSwrBuilder = AsyncSwrBuilderStore(),
        textEditingController =
            TextEditingControllerStore(graceful: textEditingGraceful),
        imperativeSignals = ImperativeSignalsStore(),
        scrollKinematics = ScrollKinematicsStore();

  final BloomWidgetStore bloomWidget;
  final ComposedFunctorsStore composedFunctors;
  final BloomBuildTupleStore bloomBuildTuple;
  final ScopedStateDiStore scopedStateDi;
  final DualEngineBattleStore dualEngineBattle;
  final DormantThrashingStore dormantThrashing;
  final TriPatternMatrixStore triPatternMatrix;
  final CompositeMotionStore compositeMotion;
  final PhysicsBoundsStore physicsBounds;
  final UnboundedCoordinatesStore unboundedCoordinates;
  final GoogleAdversarialStore googleAdversarial;
  final SimulationFlappingStore simulationFlapping;
  final FrameSchedulerStore frameScheduler;
  final FoundationBridgeStore foundationBridge;
  final AdaptiveProxiesStore adaptiveProxies;
  final ReactiveEffectsStore reactiveEffects;
  final TemporalOrchestrationStore temporalOrchestration;
  final AsyncSwrBuilderStore asyncSwrBuilder;
  final TextEditingControllerStore textEditingController;
  final ImperativeSignalsStore imperativeSignals;
  final ScrollKinematicsStore scrollKinematics;

  /// Aggregated list of all 18 canonical showcase sections.
  List<ShowcaseSection> get all => [
        // Tier 1: Core State & Composition (01~04)
        bloomWidget.section,
        composedFunctors.section,
        bloomBuildTuple.section,
        scopedStateDi.section,
        // Tier 2: Real-World App Essentials (05~10)
        textEditingController.section,
        asyncSwrBuilder.section,
        imperativeSignals.section,
        scrollKinematics.section,
        reactiveEffects.section,
        temporalOrchestration.section,
        // Tier 3: Platform & Ecosystem Bridges (11~12)
        foundationBridge.section,
        adaptiveProxies.section,
        // Tier 4: Durable Animation & Frame Scheduling (13~16)
        dualEngineBattle.section,
        triPatternMatrix.section,
        compositeMotion.section,
        frameScheduler.section,
        // Tier 5: Hardcore Verification & Adversarial Lab (17~18)
        physicsBounds.section,
        googleAdversarial.section,
      ];
}

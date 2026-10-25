# Blooming Flutter Foundations Specification
> Official technical whitepapers on Bloom Framework's Flutter rendering engine integration and UI reactive architecture invariants.

This directory provides the definitive engineering specifications for the junction between the Flutter framework and the Bloom reactive engine. It covers 2-Phase LPDAG rendering pipeline integration, widget element lifecycle coordination, high-throughput functional functor cascades, durable animation systems, demand-driven Listenable bridges, and DevTools diagnostics.

---

## Foundations Whitepapers (01 ~ 14)

01. [**2-Phase LPDAG Engine Integration & Surgical Micro-Rebuilds**](01_two_phase_lpdag_and_surgical_micro_rebuilds.md)
    - Phase 1: Push-Dirty (0-computation topological flag propagation) and isolated `markNeedsBuild()` dispatch.
    - Phase 2: Lazy-Pull (on-demand evaluation synchronized with Flutter's render pass).
    - 100% suppression of parent/sibling rebuilds and glitch-free UI rendering.

02. [**Widget Tree Lifecycle Invariants & Subscriber-Driven Dormancy**](02_element_lifecycle_and_dormancy_invariants.md)
    - Lifecycle contracts across `_ReactiveTerminalElementMixin`: `mount`, `activate`, `deactivate`, `unmount`.
    - Instant topological edge detachment (dormancy) on route pops and offstage transitions.
    - 1-Pass Epoch Sweeping for conditional branch pruning and hot reload (`reassemble`) cache invalidation.

03. [**Functor Ecosystem: composed & bloom.build Zero-Alloc Cascades**](03_functor_ecosystem_and_zero_alloc_cascades.md)
    - The `composed` functor family: multi-state composition, 120fps animation isolation, persistent frame drivers, and listeners.
    - `bloom.build`: Dart `extension type const` zero-heap-allocation cascades.
    - Static subtree memoization (`child:`, `children:`) and the architectural decision tree.

04. [**Declarative Side-Effect Isolation & Zero-Rebuild Terminals**](04_declarative_side_effects_and_zero_rebuild.md)
    - Rebuild Count: 0 invariant (firewalls widget element tree from side-effect invalidations).
    - Zero-Run on Mount invariant and microtask-deferred dispatch (`scheduleMicrotask`).
    - Conditional filtering (`guard`) and time-domain rate limiting (`debounce`, `throttle`).

05. [**Scoped State Provision & Rebuild Suppression**](05_scoped_state_and_rebuild_suppression.md)
    - Scoped dependency injection container: `BloomProvider`.
    - Reference identity invariant in `updateShouldNotify` (`!identical(old.bloom, new.bloom)`).
    - Suppression of indiscriminate `InheritedWidget` subtree rebuilds and dynamic scope unwrapping via `switched`.

06. [**Durable Animations & Wall-Clock Compensation Invariants**](06_durable_animations_and_wall_clock.md)
    - Elimination of Ticker leaks upon widget unmount; configurable state preservation via `DurableAnimationController` and `DurabilityPolicy` (`resume`, `catchUp`, `reset`).
    - 8 staged motion archetypes, $C^1$ continuity restoration via `_TimeOffsetSimulation`, and internal proxy listener isolation.

07. [**Frame Ticker Scheduler & VSYNC Pipeline Engine**](07_frame_ticker_and_vsync_engine.md)
    - 120Hz ProMotion hardware VSYNC synchronization via `composed.drive`.
    - Leak-free lifecycle handles via `managed<_TickerDriver<T>>` and automatic `resync`.
    - Power-efficient high-frequency tick dropping via origin-level deduplication and distinct filtering.

08. [**Declarative UI Refresh & Stale-While-Revalidate Patterns**](08_declarative_refresh_and_swr_ui.md)
    - Declarative coupling of `RefreshIndicator` and `.retained()` SWR buffers.
    - `BloomAsyncBuilder`: 4-state isolation (`data`, `loading`, `error`, `empty`) and intelligent collection emptiness detection.
    - `BloomPendingIndicator`: Lightweight non-intrusive progress canvas driven by `composed.drive`.

09. [**Context Environment Virtualization & Scope Proxies**](09_context_environment_virtualization.md)
    - Granular reactive projections (`size`, `viewInsets`, `platformBrightness`) eliminating `MediaQuery.of` subtree rebuild cascades.
    - Material/Cupertino design token and UI scope (`form`, `focus`, `navigator`) virtualization.
    - Zero-allocation runtime proxies via Dart `extension type`.

10. [**Listenable Interoperability & Reactive Bridges**](10_listenable_interoperability_and_bridges.md)
    - Standard Flutter bridges: `ValueListenable.toBloom()` and `Listenable.toBloomBy(selector)`.
    - Demand-driven activation: listeners are maintained only while active render widgets observe the node.
    - Graceful unmount buffering preventing listener thrashing during rapid route transitions.

11. [**Flutter DevTools Inspection & Diagnostics Architecture**](11_devtools_inspection_and_diagnostics.md)
    - Native DevTools integration via `_ReactiveTerminalElementMixin.debugFillProperties`.
    - Real-time visualization of active dependencies (`bloom[i]`) and lifecycle tethers (`tether[i]`).
    - Hot reload cache invalidation via `debugForceInvalidate()` and zero-overhead release build guarantees.

12. [**Declarative Routing & Navigation Sync**](12_declarative_routing_and_navigation_sync.md)
    - Synchronizing reactive graph state with declarative routers (`GoRouter`, Navigator 2.0) via `.toListenable()`.
    - Clean lifecycle binding without memory leaks, distinct filtering preventing route rebuild thrashing, and transient route triggers via [`BloomSignal`](https://github.com/pioneerjkf/blooming/blob/main/packages/blooming/doc/foundations/17_imperative_signals_and_transient_events.md) (from `package:blooming`).

13. [**Scroll Kinematics & Reactive Pagination**](13_scroll_kinematics_and_pagination.md)
    - Zero-allocation bridging of high-frequency 60/120fps `ScrollController` offsets via `.observe()`.
    - Isolating scroll kinematics from widget tree rebuilds via `composed.child` to eliminate jank in complex sliver hierarchies.

14. [**Widget Testing & Frame Pumping Mechanics**](14_widget_testing_and_pump_mechanics.md)
    - Deterministic UI verification with `WidgetTester` across 2-Phase LPDAG and asynchronous SWR lifecycles.
    - Exact temporal pump control (`pump()` vs. `pumpAndSettle()`), fake async timers, and isolated micro-rebuild verification.

---

## Foundational Pillars Matrix

| Pillar | Core Engineering Value | Implementation Mechanism | Related Whitepaper |
| :--- | :--- | :--- | :--- |
| **Surgical Render** | Rebuild scope: whole subtree $\to$ one leaf element | 2-Phase LPDAG + Leaf Element direct wiring + 1-Pass Epoch Sweeping | 01, 02 |
| **Zero-Alloc Functor** | Syntactic elegance & execution speed | `composed` Functors + `bloom.build` `extension type const` | 03 |
| **Zero-Rebuild Effect** | Clean separation of render & effects | `BloomListener` + EffectRunner + `scheduleMicrotask` | 04 |
| **Suppressed Scope** | Blocks indiscriminate global rebuilds | `BloomProvider` + `!identical` identity suppression + `switched` | 05 |
| **Durable Motion** | Physical time & motion continuity | Wall-clock compensation (`CatchUp`) + State freezing (`Frozen`) + $C^1$ continuity | 06, 07 |
| **Zero-Flicker SWR** | Continuous user immersion | Stale cache retention + `BloomAsyncBuilder` + `BloomPendingIndicator` | 08 |
| **Context Virtualization** | Granular environment token projection | `BloomViaContextExtension` (`via.of<T>(context)`) | 09 |
| **Demand-Driven Bridge**| Full Flutter ecosystem interop | `toBloom` / `toBloomBy` + Demand-driven listener lifecycle management | 10 |
| **Native Diagnostics** | Transparent live debugging | `debugFillProperties` + DevTools Inspector + Hot reload resilience | 11 |
| **Declarative Router** | 100% route-state synchronization | `.toListenable()` + [`BloomSignal`](https://github.com/pioneerjkf/blooming/blob/main/packages/blooming/doc/foundations/17_imperative_signals_and_transient_events.md) (`blooming`) + distinct filter | 12 |
| **Kinematic Scroll** | 120fps jank-free scroll binding | `.observe()` + `composed.child` isolation | 13 |
| **Deterministic Test** | Zero-flakiness reactive testing | Frame pump control + `BloomAsyncBuilder` pump mechanics | 14 |

<p align="center">
  <img src="https://raw.githubusercontent.com/pioneerjkf/blooming/main/packages/blooming_flutter/assets/blooming_flutter_banner_neutral.svg" alt=".blooming_flutter — Fine-Grained Reactive UI Engine for Flutter" width="100%" />
</p>

<h1 align="center">Bloom Flutter</h1>

<p align="center">
  <strong>High-Performance, Fine-Grained Reactive UI Bindings, Durable Animations, and Form Controllers for Flutter</strong>
</p>

<p align="center">
  <a href="https://pub.dev/packages/blooming_flutter"><img src="https://img.shields.io/pub/v/blooming_flutter.svg?style=flat-square" alt="Pub Version" /></a>
  <a href="https://pub.dev/packages/blooming_flutter/score"><img src="https://img.shields.io/pub/points/blooming_flutter.svg?style=flat-square" alt="Pub Points" /></a>
  <a href="https://github.com/pioneerjkf/blooming/blob/main/packages/blooming_flutter/LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue.svg?style=flat-square" alt="License" /></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.27+-02569B.svg?style=flat-square&logo=flutter" alt="Flutter SDK" /></a>
</p>


> **Powered by the Bloom 2-Phase LPDAG Pure Dart Engine.** For pure Dart core specifications, architecture whitepapers, and CLI/backend reactivity, visit [`blooming`](https://pub.dev/packages/blooming).

---

## Overview

**Bloom Flutter** (`package:blooming_flutter`) is the official Flutter reactive UI binding framework for the Bloom state engine. Directly bridging Bloom's **Push-Dirty, Lazy-Pull LPDAG (Lazy Pull Directed Acyclic Graph)** into the Flutter `Widget` and `Element` hierarchy, `blooming_flutter` eliminates coarse-grained subtree rebuilds, ambient context tracking traps, CJK IME composition corruption, and unmount animation state destruction.

In traditional Flutter state management architectures, state updates trigger top-down subtree rebuilds across parent and sibling widgets. Even with selective builders, ambient tracking scopes often cause accidental dependencies, memory leaks during unmounts, and screen-flicker during asynchronous revalidations.

`blooming_flutter` embeds zero-overhead reactive boundary terminals (`RawComputedTerminal<Widget>`) directly into specialized Flutter `Element` subclasses (`BloomElement`, `composed` elements). When a reactive state node mutates, only the exact leaf widget listening to that node marks itself dirty, leaving parent layouts, sibling elements, and surrounding trees completely uninvoked.

---

## 3-Second Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

// 1. Pure reactive state nodes & managed resources (No Codegen, No Global State Traps)
final likes = BloomController(0);

// 🚀 Managed Flutter TextEditingController: auto-allocated upon mount, disposed upon unmount
final textController = managed<TextEditingController>(
  create: (via) => TextEditingController(),
  dispose: (c) => c.dispose(),
  graceful: Graceful.microtask,
);

// 🚀 Zero-Disposal Motion: pauses on unmount and resumes cleanly without boilerplate
final pulse = DurableAnimationController(
  duration: const Duration(milliseconds: 800),
);

// 2. Zero StatefulWidget: BloomWidget unifies forms, 60/120fps motion, and micro-rebuilds
base class LiveSearchBar extends BloomWidget {
  const LiveSearchBar({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    return Column(
      children: [
        // A. Standard form input (Flutter native IME & caret fidelity via managed lifecycle)
        TextField(
          controller: via(textController),
          decoration: const InputDecoration(hintText: 'Search...'),
        ),

        // B. 60/120fps inline animation (driven via composed.animate without manual TickerProvider)
        composed.animate(
          pulse,
          (context, via, ctrl) => Transform.scale(
            scale: 1.0 + (ctrl.value * 0.1),
            child: const Icon(Icons.bolt, color: Colors.amber),
          ),
          onActivate: (ctrl) => ctrl.repeat(reverse: true),
        ),

        // C. Surgical micro-rebuild (spamming likes rebuilds ONLY this single Text element)
        composed((context, via) => Text('Likes: ${via(likes.bloom)}')),

        IconButton(onPressed: () => likes.data++, icon: const Icon(Icons.favorite)),
      ],
    );
  }
}
```

---

<details>
<summary>Click to view ASCII Architecture & Taxonomy Map</summary>

```text
┌────────────────────────────────────────────────────────────────────────────┐
│                    Bloom Flutter Architecture & Taxonomy                    │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  1. Reactive UI Boundaries (Surgical Micro-Rebuilds)                       │
│     ├── Base Widgets                                                       │
│     │    ├── BloomWidget                        (build: (context, via) => ) │
│     │    └── BloomVsyncWidget                   (build: (ctx, via, vsync))  │
│     ├── Inline Functors (The composed Family)                              │
│     │    ├── composed                          ((context, via) => Widget)  │
│     │    │    └── .child / .children           (preserves static subtrees) │
│     │    └── composed.vsync                    ((ctx, via, vsync) => W)    │
│     │         └── .child / .children           (preserves static subtrees) │
│     ├── Zero-Rebuild Declarative Side-Effects                              │
│     │    ├── BloomListener                      (target, (ctx, state) => )  │
│     │    │    └── .debounce / .throttle        (time-domain rate limits)   │
│     └── Fluent 1:1 Node Builders (Zero-Alloc)                              │
│          ├── bloom.build                        ((context, data) => Widget)  │
│          │    └── .child / .children           (preserves static subtrees) │
│                                                                            │
│  2. Durable Animation & Frame Scheduling Engine                            │
│     ├── DurableAnimationController        (policy: resume, catchUp, reset) │
│     ├── controller.observe()              --> Bloom<double> (Passive)       │
│     ├── composed.animate                  (ctrl, (ctx, via, c) => Widget)  │
│     │    └── .child / .children           (preserves static subtrees)      │
│     ├── composed.drive                    ((elapsed) => ..., (ctx, via, v))│
│     │    └── .child / .children           (preserves static subtrees)      │
│     └── vsync.drive(onTick)               --> Bloom<T> (Frame ticker)       │
│                                                                            │
│  3. Form Input & Listenable Interop                                        │
│     ├── controller.toBloomBy((c) => c.text)   (Demand-Driven bridge)        │
│     └── managed<TextEditingController>       (Auto-disposed form lifecycle)│
│                                                                            │
│  4. Async SWR UI & Progress                                                │
│     ├── BloomAsyncBuilder<T>                    (bloom, pending, {data, ...})│
│     │    └── .tuple                            (tuple, {data, loading, ...})│
│     └── BloomPendingIndicator                   (pendingBloom, {height: 2.0})│
│                                                                            │
│  5. Scoped DI & Context Integrations                                       │
│     ├── Scoped State DI                                                    │
│     │    ├── BloomProvider<T>                   (bloom: targetBloom, child)   │
│     │    ├── bloom.provide / controller.provide (child: Widget)             │
│     │    └── via.of<T>(context) / maybeOf<T>() // Scoped node observation  │
│     └── Fluent Context Lookup                                              │
│          ├── via.of<T>(context)                // Scoped BloomProvider read │
│          └── context.bloomOf<T>()               // Direct node extraction   │
│                                                                            │
│  6. Graceful Lifecycle & Mooring                                           │
│     ├── Graceful.microtask                     // Microtask remount buffer │
│     ├── Graceful.period(Duration)              // Time-bounded TTL mooring │
│     └── .graceful(policy)                      // Mooring attachment DSL   │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```
</details>

---

## Architectural Comparison: Conventional Flutter Approaches vs. Bloom Flutter

In Flutter applications, balancing granular reactive state, frame-isolated animations, asynchronous queries, and text inputs involves distinct architectural trade-offs across common paradigms (such as `setState`, `ValueListenableBuilder`, or provider selectors):

| Engineering Dimension | Conventional Flutter Trade-offs & Limitations | Bloom Flutter Resolution |
| :--- | :--- | :--- |
| **Widget Tree Invalidation** | Naive `setState` cascades subtree rebuilds; `ValueListenableBuilder` or manual selectors require nested boilerplate for multiple dependencies | **Surgical Leaf Micro-Rebuild** (`composed`, parent/sibling rebuild count: 0, flat multi-dependency tracking) |
| **Reactive Tracking Scopes** | Ambient context or boilerplate wrappers with hidden leaks | **Explicit `BloomVia` Injection** (Zero-ambient, deterministic AST analysis) |
| **State Mutability Contracts** | Mixed mutable getters/setters on shared object boundaries | **Strict Separation of Concerns** (`Bloom<T>` read-only vs `BloomController<T>`) |
| **State Snapshot Integrity** | Ad-hoc flags or verbose union/sealed class hierarchies | **Deterministic 3-State FSM** (`Data`, `Empty`, `Error` + `emptyReason`) |
| **Transient Lifecycle Mooring**| Immediate unmount disposal destroying state continuity | **Native `Graceful` Engine** (Microtask coalescing & `period` TTL mooring) |
| **East Asian CJK / Form Input** | Custom wrapper controllers breaking IME buffers and causing ping-pong loops | **Native Controller + `toBloomBy`** (Native platform IME fidelity & zero listener leaks) |
| **Animation Lifecycle Coupling** | Manual `AnimationController` lifecycle tied to `TickerProviderStateMixin` (state resets or ticker errors on unmount) | **Durable Engine** (Wall-clock `CatchUp` & state `Frozen` without `StatefulWidget`) |
| **Asynchronous UI Ingestion** | Screen-flashing spinners during background revalidation | **Flicker-Free SWR** (`BloomAsyncBuilder`, stale data preserved on pending) |
| **Component Hierarchy DI** | `InheritedWidget.updateShouldNotify` triggering wide rebuilds | **Rebuild-Suppressed DI** (`BloomProvider`, pointer-check only, 0-rebuild tunneling) |
| **Dormancy & Resource Teardown** | Background timers/subscriptions running while offstage | **Subscriber-Driven Inactive Dormancy** (0 CPU/ticks on unmount) |


---

## Core Production Engineering Pillars

`blooming_flutter` addresses five critical architectural constraints and failure modes encountered when scaling Flutter applications to complex production workflows.

---

### Pillar 1: Surgical Leaf Micro-Rebuilds (`composed`)

In standard Flutter, updating a reactive value inside a large widget often leads to two extremes: broad subtree rebuilds via `setState` (re-evaluating heavy headers, graphics, and footers), or deeply nested builder pyramids (`ValueListenableBuilder` / manual selectors) when isolating rebuild boundaries for multiple values. With `blooming_flutter`, the `composed` functor eliminates both dilemmas by isolating the reactive boundary to the smallest possible leaf element while automatically tracking dependencies in a single flat scope.

#### Rebuild Frequency Architecture

```text
┌────────────────────────────────────────────────────────────────────────────┐
│      Rebuild Frequency: Conventional Approaches vs. blooming_flutter Leaf      │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  Conventional Approach (Naive setState Subtree Cascade):                   │
│    [Card Widget]                ──> Rebuilds: 100 times                    │
│      ├── [Heavy Header]         ──> Rebuilds: 100 times (WASTED)           │
│      ├── [Expensive Chart]      ──> Rebuilds: 100 times (WASTED)           │
│      └── [Live Counter Text]    ──> Rebuilds: 100 times                    │
│                                                                            │
│  blooming_flutter with composed (Surgical Leaf Micro-Rebuild):                 │
│    [Card Widget]                ──> Rebuilds: 1 time  (INITIAL ONLY)       │
│      ├── [Heavy Header]         ──> Rebuilds: 1 time  (0 ON UPDATES)       │
│      ├── [Expensive Chart]      ──> Rebuilds: 1 time  (0 ON UPDATES)       │
│      └── composed((via) => ...) ──> Rebuilds: 100 times (LEAF ONLY)        │
│                                                                            │
│  * Note: While ValueListenableBuilder can isolate rebuilds, observing N    │
│    independent values requires N levels of nested builders. composed       │
│    flattens all dependencies into a single reactive leaf.                  │
└────────────────────────────────────────────────────────────────────────────┘
```

#### The `composed` Functor Family & Cascading Pathways

`composed` provides a zero-cost cascading hierarchy supporting dynamic context injection, static subtree caching, high-frequency animations, frame drivers, and side-effects:

```text
┌────────────────────────────────────────────────────────────────────────────┐
│              The composed Functor Family & Cascading Pathways              │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  composed                         ((context, via) => Widget)               │
│   ├── .child / .children          (preserves static subtrees)              │
│   │                                                                        │
│   ├── .vsync                      ((context, via, vsync) => Widget)        │
│   │    └── .child / .children     (preserves static subtrees)              │
│   │                                                                        │
│   ├── .animate                    (controller, (ctx, via, ctrl) => Widget) │
│   │    └── .child / .children     (preserves static subtrees)              │
│   │                                                                        │
│   └── .drive                      ((elapsed) => ..., (ctx, via, val) => W) │
│        └── .child / .children     (preserves static subtrees)              │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

> [!NOTE]
> All builder variants seamlessly support static subtree preservation via `.child` and `.children` (e.g. `composed.child(...)` or `composed.animate.child(...)`).

#### Production Code Example

```dart
import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

final livePriceController = BloomController<double>(100.0);

class StockDashboardCard extends StatelessWidget {
  const StockDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Header and chart are built ONCE and NEVER rebuilt on price updates
          const HeavyHeader(title: 'High-Frequency Market Feed'),
          const ExpensiveChartWidget(),

          // Surgical Leaf Rebuild: Only this Text element executes at 60/120fps
          composed((context, via) {
            final price = via(livePriceController.bloom);
            return Text(
              '\$${price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            );
          }),

          const StaticCardFooter(disclaimer: 'Real-time data powered by Bloom'),
        ],
      ),
    );
  }
}
```

---

### Pillar 2: Form Input & Listenable Interop (`toBloomBy` & `managed`)

In Flutter applications, text inputs and forms belong fundamentally to the platform UI layer. Forcing bidirectional wrapper controllers onto Flutter's `TextField` introduces critical bugs in composition-based languages (Korean, Japanese, Chinese) and risks infinite re-entrant ping-pong notification loops.

Bloom solves form inputs through **Native Platform Ownership + Unidirectional Reactive Bridges**:
1. **Native Flutter Caret & IME Integrity**: Standard `TextEditingController` handles OS typing buffers natively—preventing syllable fragmentation and caret jumping in CJK composition while ensuring seamless ecosystem compatibility with custom formatters.
2. **Zero-Leak Listenable Bridge (`toBloomBy`)**: The input stream is bridged directly into Bloom's reactive graph on-demand with automatic Demand-Driven Dormancy (listeners are active only when observed by the UI).
3. **Automated Lifecycle (`Bloom.managed`)**: Controllers are automatically allocated upon widget mount and cleanly disposed upon unmount without requiring `StatefulWidget` boilerplate.

```text
┌────────────────────────────────────────────────────────────────────────────┐
│                   Standard Bloom Form Input Flow                            │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│   [ Keyboard Input / IME ]                                                 │
│              │                                                             │
│              ▼                                                             │
│     TextEditingController (Native Flutter UI Layer)                       │
│              │                                                             │
│              ▼ .toBloomBy((c) => c.text)                                    │
│       Bloom<String> (Reactive LPDAG Stream)                                 │
│              │                                                             │
│              ├──► computed((via) => via(textBloom).length)                  │
│              └──► computed.future((via) => api.search(via(textBloom)))      │
│                                                                            │
│   [ Demand-Driven Dormancy ]:                                              │
│   Listener is attached ONLY when active subscribers exist,                 │
│   and automatically detached when the UI unmounts.                         │
└────────────────────────────────────────────────────────────────────────────┘
```

#### Production Code Example

```dart
import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

// 1. Native Flutter TextEditingController
final searchController = TextEditingController();

// 2. Extract reactive text stream with toBloomBy
final queryBloom = searchController.toBloomBy((c) => c.text);

// 3. Debounced derived computation
final searchResults = computed.future<List<String>>((via) async {
  final query = via(queryBloom.debounce(const Duration(milliseconds: 300)));
  if (query.isEmpty) return const [];
  return api.search(query);
});

// 4. Declarative BloomWidget consumer
base class SearchForm extends BloomWidget {
  const SearchForm({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final resultsState = via.state(searchResults);

    return Column(
      children: [
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Search',
            hintText: 'Type freely with native IME fidelity...',
          ),
        ),
        if (resultsState.isPending) const LinearProgressIndicator(),
        if (resultsState.hasData)
          for (final item in resultsState.data) ListTile(title: Text(item)),
      ],
    );
  }
}
```

---

### Pillar 3: Durable Animation Engine (`CatchUp` & `Frozen`)

Standard Flutter `AnimationController` instances are bound to the host widget's `SingleTickerProviderStateMixin`. When the widget unmounts (e.g. switching tabs in `BottomNavigationBar`, popping navigation routes, or hiding bottom sheets), active tickers are detached—causing animation progress to reset upon remount or triggering assertion/leak errors if tickers remain active without proper lifecycle handling.

`blooming_flutter` provides **Durable Animation Controllers** that seamlessly bridge dormant lifecycle states:

```text
┌────────────────────────────────────────────────────────────────────────────┐
│                    Durable Animation Lifecycle State                       │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│ Active (Mounted)               Dormant (Unmounted Tab)    Remounted (Active)│
│                                                                            │
│ [Ticker Running]  ──unmount──>   [Ticker Detached]  ───>  [CatchUp / Frozen]│
│ (Frames ticking)                 (0 CPU / 0 Ticks)      • CatchUp: Jump to │
│                                                           real elapsed     │
│                                                         • Frozen: Resume   │
│                                                           from exact value │
└────────────────────────────────────────────────────────────────────────────┘
```

#### 1. `DurabilityPolicy.catchUp`: Wall-Clock Synchronization
For continuous radars, clocks, live timers, and looping spinners. When the widget unmounts, the ticker halts completely (0 CPU). Upon remounting, `catchUp` calculates the elapsed wall-clock time (`DateTime.now()`) and fast-forwards the animation value to match reality precisely.

#### 2. `DurabilityPolicy.resume`: State-Preserving Freeze (Default)
For interactive expandable cards, games, and stepper animations. When the widget unmounts mid-animation, its progress is frozen at the exact double value. Upon remounting, it resumes from the frozen point without stuttering or resetting.

#### 3. `DurabilityPolicy.reset`: Initial State Reset
Resets the animation progress back to its initial parameters upon widget unmount / dormancy.

#### 4. Inline 60/120fps UI Functors: `composed.animate`
Eliminates `AnimatedBuilder` and `StatefulWidget` boilerplate by providing direct frame-ticking composition functors via `composed.animate` on `DurableAnimationController` instances. Static subtrees passed to `child:` or `children:` are strictly memoized to avoid redundant layout passes.

#### Durable Animation Architecture & Invocation Roadmap

```text
┌────────────────────────────────────────────────────────────────────────────┐
│            Durable Animation Architecture & Invocation Roadmap             │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  1. Controller Hierarchy (Durable Lifecycle Management)                    │
│     AnimationController (Flutter standard)                                 │
│      └── DurableAnimationController (Unmount-safe lifecycle contract)      │
│           ├── policy: DurabilityPolicy.resume  (Freeze on unmount, resume) │
│           ├── policy: DurabilityPolicy.catchUp (Wall-clock elapsed sync)   │
│           ├── policy: DurabilityPolicy.reset   (Reset on unmount)          │
│           └── controller.observe()             --> Bloom<double> (Passive)  │
│                                                                            │
│  2. VSYNC Providers & Frame Tickers                                        │
│     ├── BloomVsyncWidget                        (build: (ctx, via, vsync))  │
│     ├── composed.vsync                         ((ctx, via, vsync) => W)    │
│     └── vsync.drive(onTick)                    --> Bloom<T> (Frame ticker)  │
│                                                                            │
│  3. Frame-Driven Inline UI Functors (60/120fps Dynamic Motion)             │
│     ├── composed.animate                       (ctrl, (ctx, via, c) => W)   │
│     │    └── .child / .children                (preserves static subtrees) │
│     └── composed.drive                         ((elapsed) => ..., (ctx, v))│
│          └── .child / .children                (preserves static subtrees) │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

> [!NOTE]
> All inline animation variants seamlessly support static subtree preservation via `.child` and `.children` (e.g. `composed.animate.child(...)`).

#### Production Code Example

```dart
import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

class LiveRadarScanner extends StatelessWidget {
  const LiveRadarScanner({super.key, required this.controller});
  final DurableAnimationController controller;

  @override
  Widget build(BuildContext context) {
    return composed.animate(
      controller,
      (context, via, ctrl) => RotationTransition(
        turns: ctrl.view,
        child: const Icon(Icons.radar, size: 72, color: Colors.blueAccent),
      ),
      onActivate: (ctrl) => ctrl.repeat(),
    );
  }
}
```

---

### Pillar 4: Graceful Lifecycle & Mooring (`Graceful.microtask` & `Graceful.period`)

In standard Flutter reactive architectures, unmounting a widget instantly tears down its listeners or cancels asynchronous streams. This causes severe production defects:
1. **Unmount-Remount Thrashing**: Re-parenting widgets, swapping tabs, or rapid list scrolling drops subscriber counts to 0 for a single frame, destroying expensive connections and recreating them immediately.
2. **Navigation Cache Loss**: Navigating from a master view to a detail route clears form selections, scroll offsets, or live search results unless manually hoisted into fragile global variables.

`blooming_flutter` integrates the **`Graceful`** lifecycle engine to buffer deactivations safely:

```text
┌────────────────────────────────────────────────────────────────────────────┐
│                  Graceful Deactivation & Mooring Architecture              │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  [All Subscribers Detach (Count = 0)]                                      │
│                     │                                                      │
│                     ▼                                                      │
│          Graceful Policy Configured?                                       │
│          ┌──────────┴─────────────────────────┐                            │
│     (No) │                                    │ (Yes)                      │
│          ▼                                    ▼                            │
│  [Instant Dormancy]                [Enter Grace State]                     │
│  • Sever upstream edges            • Microtask: 1-scheduler tick buffer   │
│  • 0 CPU / 0 allocations           • Period: Global Mooring anchor (TTL)   │
│                                               │                            │
│                     ┌─────────────────────────┴───────────────────────┐    │
│                     ▼                                                 ▼    │
│           [Subscriber Re-attaches]                         [Grace TTL Elapses] │
│           • Resumes active instantly                       • Deallocates cleanly│
│           • Zero-cost reconnection                         • 0 Memory leak     │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

#### 1. Microtask Buffer (`Graceful.microtask` / `Graceful()`)
Defers node deallocation to the next Dart microtask. When Flutter elements are reparented or rebuilt across adjacent frames, the microtask buffer coalesces the tear-down and remount into a single operation, eliminating frame jank and redundant data re-fetching.

#### 2. Time-Based Mooring (`Graceful.period(Duration)`)
Deploys a global Mooring anchor to keep downstream nodes and their upstream dependencies warm and active for a designated time window (e.g. 5 minutes). Retains form inputs, cursor selections, and cached queries across screen navigation without requiring permanent global singletons.

#### Production Code Example

```dart
import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

// Stream moored for 3 minutes across route navigation
final liveFeedBloom = stockStream.toBloom(
  graceful: const Graceful.period(Duration(minutes: 3)),
);

// Native TextEditingController bridged with 5-minute mooring: retains cursor and selection across tab switches
final searchController = TextEditingController();
final searchInputBloom = searchController.toBloomBy(
  (c) => c.text,
  graceful: const Graceful.period(Duration(minutes: 5)),
);
```

---

### Pillar 5: Deterministic 3-State FSM Snapshot (`Data` / `Empty` / `Error`)

Ad-hoc state management libraries treat state as either an ambient value or an untyped nullable payload. This causes silent crashes when uninitialized data is read or when errors are silently swallowed.

`blooming_flutter` models every reactive node as a **Deterministic 3-State Finite State Machine (FSM)** via `BloomSnapshot`:

```text
┌────────────────────────────────────────────────────────────────────────────┐
│                    Deterministic 3-State FSM Snapshot                      │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│                     ┌───────────────────────────┐                          │
│                     │     BloomSnapshot<T>       │                          │
│                     └─────────────┬─────────────┘                          │
│                                   │                                        │
│          ┌────────────────────────┼────────────────────────┐               │
│          ▼                        ▼                        ▼               │
│   [ hasData == true ]      [ isEmpty == true ]      [ hasError == true ]   │
│   • Valid payload: T       • Dormant/Uninitialized  • Object error         │
│   • Direct .data access    • emptyReason diagnostic • StackTrace stack     │
│   • Supports T? = null     • Fail-fast on .data     • Fail-fast on .data   │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

* **Sound Fail-Fast Extraction**: Reading `untracked(node)` while in an `Empty` or `Error` state synchronously throws `BloomSnapshotExtractionException`. Bugs are exposed immediately at the call-site rather than mutating silent UI states.
* **Exhaustive Zero-Heap Pattern Matching**: Use native Dart 3 `switch (untracked.state(node).phase)` to map states directly to UI or strings with zero closure allocations and zero graph edge creation:

```dart
final state = untracked.state(stateBloom);
final statusWidget = switch (state.phase) {
  BloomPhase.valid => Text('Active: ${state.data}'),
  BloomPhase.empty => const Text('Awaiting input...'),
  BloomPhase.error => Text('Failed: ${state.error}', style: const TextStyle(color: Colors.red)),
};
```

---

## Declarative 3-Tier Builder Patterns

`blooming_flutter` provides three ergonomic builder patterns tailored for different UI scopes:

### 1. `BloomWidget` & `BloomVsyncWidget`: Class-Based Components
Best for cohesive feature screens, structured modules, and standard reactive widgets. `BloomVsyncWidget` provides a `TickerProvider` for seamless `DurableAnimationController` integration without `StatefulWidget` boilerplate.

```dart
base class UserProfileCard extends BloomWidget {
  UserProfileCard({super.key, required this.userBloom});
  final Bloom<User> userBloom;

  @override
  Widget build(BuildContext context, BloomVia via) {
    final user = via(userBloom);
    return ListTile(
      leading: CircleAvatar(child: Text(user.initials)),
      title: Text(user.name),
      subtitle: Text(user.email),
    );
  }
}

base class AnimatedCard extends BloomVsyncWidget {
  AnimatedCard({super.key, required this.themeBloom});
  final Bloom<Brightness> themeBloom;

  @override
  Widget build(BuildContext context, BloomVia via, TickerProvider vsync) {
    // Access vsync directly for animation controllers or bloom.managed ticking
    return Text('Theme: ${via(themeBloom)}');
  }
}
```

### 2. `bloom.build((context, data) => ...)`: Direct Single-Node Builders
Lightweight inline widgets bound 1:1 to a single `Bloom<T>` node. Every builder receives `BuildContext` by default to prevent accidental outer context lexical capture, incurring zero wrapper allocation overhead via Dart `extension type const`.

```dart
// Single node direct build
counterController.bloom.build((context, count) => Text('Count: $count'));

// Static subtree caching (.child)
counterController.bloom.build.child(
  (context, count, child) => Row(children: [Text('Count: $count'), child]),
  child: const FlutterLogo(),
);
```

### 3. `composed`, `composed.child`, & `composed.vsync`: Scoped Micro-Builders
Best for arbitrary multi-state leaf compositions within larger stateless or stateful widgets.

```dart
// Context and multi-state builder
composed((context, via) {
  final count = via(counter.bloom);
  final isDark = via(themeBloom) == Brightness.dark;
  return Container(
    color: isDark ? Colors.grey[900] : Colors.white,
    child: Text('Count: $count (Theme: ${isDark ? "Dark" : "Light"})'),
  );
});

// Static child-preserving builder
composed.child(
  child: const Icon(Icons.star, size: 48),
  (context, via, child) {
    final count = via(counter.bloom);
    return Stack(
      children: [
        child,
        Text('Count: $count'),
      ],
    );
  },
);

// Vsync-injected builder (provides TickerProvider directly)
composed.vsync((context, via, vsync) {
  final count = via(counter.bloom);
  return Text('Animated Count: $count');
});
```

---

## Flicker-Free SWR Asynchronous UI (`BloomAsyncBuilder`)

Building responsive asynchronous UI requires handling four distinct states: `data`, `loading`, `error`, and `empty`. Standard Flutter `FutureBuilder` or `StreamBuilder` flashes empty or loading spinners every time data revalidates in the background.

`BloomAsyncBuilder` delivers seamless **Stale-While-Revalidate (SWR)** caching:

```dart
import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

base class StockListScreen extends BloomWidget {
  StockListScreen({super.key, required this.feedBloom, required this.isPendingBloom});
  final Bloom<List<StockItem>> feedBloom;
  final Bloom<bool> isPendingBloom;

  @override
  Widget build(BuildContext context, BloomVia via) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Stock Watchlist'),
        // Surgical 2px progress bar binding directly to Bloom<bool>
        bottom: BloomPendingIndicator(target: isPendingBloom),
      ),
      body: BloomAsyncBuilder<List<StockItem>>(
        bloom: feedBloom,
        pending: isPendingBloom,
        data: (context, stocks) => ListView.builder(
          itemCount: stocks.length,
          itemBuilder: (context, i) => ListTile(title: Text(stocks[i].symbol)),
        ),
        loading: (context) => const Center(child: CircularProgressIndicator()),
        error: (context, error, stack) => Center(child: Text('Error: $error')),
        empty: (context) => const Center(child: Text('No stocks available')),
        // SWR Invariant: Retains existing list on screen during background refresh
        preserveDataOnPending: true,
      ),
    );
  }
}
```

* **`preserveDataOnPending: true`**: When revalidating in the background, the UI continues rendering the existing valid data rather than tearing down the list to render a loading spinner.
* **`BloomPendingIndicator`**: A surgical 2px/3px indeterminate linear indicator that binds directly to a `Bloom<bool>` node to inform the user of background refresh activity without full-screen layout shifts.

---

## Flutter DevTools Inspector Live Diagnostics

`blooming_flutter` integrates deeply with the Flutter DevTools Inspector. Every Bloom element (such as `BloomElement` and `composed` elements) overrides `debugFillProperties` to expose its active dependency graph directly in the DevTools UI.

When selecting any Bloom-powered widget in the Widget Tree panel, the Diagnostic Details panel renders the active reactive subscriptions and lifecycle tethers in real time:

```text
Diagnostic Details Tree:
┌────────────────────────────────────────────────────────────────────────────┐
│ BloomElement (LiveMarketCard)                                               │
│  ├── bloom[0]: LivePriceNode: Bloom<double> (value: 142.50)                  │
│  ├── bloom[1]: AppThemeNode: Bloom<ThemeMode> (value: ThemeMode.dark)        │
│  ├── tether[0]: liveSearchDebounce (_DebounceEffect)                       │
│  └── tether[1]: themeTelemetrySync (_ThrottleEffect)                       │
└────────────────────────────────────────────────────────────────────────────┘
```

### Diagnostic Highlights
* **Zero Configuration**: DevTools inspection works out-of-the-box in debug builds with zero flags or setup.
* **Production Tree-Shaking**: All diagnostic property population is wrapped inside `assert(() { ... }())` and stripped cleanly from release builds.
* **Leak Detection**: Developers can immediately verify whether an element has detached its upstream edges upon navigation or unmount.

---

## Scoped Dependency Injection (`BloomProvider` & `bloomOf`)

`BloomProvider<T>` provides `Bloom<T>` instances down the widget tree using Flutter's native `InheritedWidget` mechanism, augmented with **rebuild suppression**:

```dart
// 1. Ancestor Provider
Widget buildApp() {
  return BloomProvider<AuthSession>(
    bloom: authController.bloom,
    child: const MainAppShell(),
  );
}

// 2. Descendant Consumer
base class UserGreeting extends BloomWidget {
  const UserGreeting({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    // One-stop lookup & reactive observation via via.of<T>(context):
    final session = via.of<AuthSession>(context);
    return Text('Hello, ${session.username}!');
  }
}
```

* **Rebuild Suppression Invariant**: `BloomProvider.updateShouldNotify` returns `false` when the underlying value of `bloom` changes, preventing the intermediate widget tree from rebuilding. Only descendants explicitly reading the node via `via(sessionBloom)` are invalidated.

---

## Installation & Setup

Add `blooming_flutter` to your Flutter project:

```bash
flutter pub add blooming_flutter
```

Import the foundational libraries:

```dart
// Primary reactive UI widgets, builders, form controllers, and durable animations
import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
```

### Package Ecosystem & Re-exported APIs

`package:blooming_flutter` acts as a complete, unified entry point by re-exporting the pure Dart core [`package:blooming`](https://pub.dev/packages/blooming) and its declarative side-effect engine (`package:blooming/effect.dart`). A single import (`package:blooming_flutter/blooming_flutter.dart`) provides immediate access to both core reactive primitives and Flutter UI bindings:

| Category | API / Primitive | Originating Package | Primary Architectural Role |
| :--- | :--- | :--- | :--- |
| **Core Reactive State** | `Bloom<T>`, `BloomController<T>`, `computed`, `switched`, `managed` | [`package:blooming`](https://pub.dev/packages/blooming) | Canonical 2-Phase LPDAG state nodes, memoized derivations, and subscriber-driven lifecycle supervision |
| **Transient Signals** | [`BloomSignal`](https://github.com/pioneerjkf/blooming/blob/main/packages/blooming/doc/foundations/17_imperative_signals_and_transient_events.md), [`BloomSignalController`](https://github.com/pioneerjkf/blooming/blob/main/packages/blooming/doc/foundations/17_imperative_signals_and_transient_events.md) | [`package:blooming`](https://pub.dev/packages/blooming) | Monotonic discrete tick pulses for transient events (dialogs, toasts, router triggers) without zombie state |
| **Safe State Inspection** | `BloomSnapshot<T>`, `untracked.state`, `.dataOrNull`, `.dataOrElse(...)` | [`package:blooming`](https://pub.dev/packages/blooming) | Fail-fast snapshot inspection and non-throwing nullable value extraction |
| **Declarative Effects** | `Effect`, `DebounceEffect`, `ThrottleEffect` | [`package:blooming/effect`](https://pub.dev/packages/blooming) | Non-rendering reactive side-effect sinks and rate-limited async execution |
| **Surgical Leaf UI** | `composed`, `BloomWidget`, `BloomListener`, `bloom.build` | `package:blooming_flutter` | Zero-overhead reactive boundary elements and surgical micro-rebuild widgets |
| **Platform & Form Bridges** | `toBloom`, `toBloomBy`, `.toListenable()` | `package:blooming_flutter` | Seamless bidirectional bridging for `TextEditingController`, `Listenable`, and Routers |
| **Durable Motion & Ticker** | `DurableAnimationController`, `composed.animate`, `composed.drive` | `package:blooming_flutter` | Wall-clock `CatchUp` and `Frozen` motion engines independent of `StatefulWidget` |

---

## Architectural Whitepaper Curation

For deep-dive architectural specifications, mathematical invariants, and internal memory layouts, consult the official Bloom Framework whitepapers:

### Flutter Integration Whitepapers
* [Whitepaper 06: Durable Animations & Wall-Clock Compensation Invariants](doc/foundations/06_durable_animations_and_wall_clock.md)
  * Specification of `DurableAnimationController` (`DurabilityPolicy`), and zero-leak Ticker lifecycle.
* [Whitepaper 08: Zero-Jump Form Binding & IME Integrity Invariants](doc/foundations/08_form_binding_and_ime_integrity.md)
  * CJK IME composition protection, cursor jump immunity, and ping-pong re-entrancy mutex shields.
* [Whitepaper 09: Declarative UI Refresh & Stale-While-Revalidate Patterns](doc/foundations/09_declarative_refresh_and_swr_ui.md)
  * Zero-flicker background revalidation with `RefreshIndicator` and `.retained()` SWR buffering.
* [Whitepaper 12: Flutter DevTools Inspection & Diagnostics Architecture](doc/foundations/12_devtools_inspection_and_diagnostics.md)
  * Native inspection of reactive dependencies via `BloomElement.debugFillProperties`.
* [**All 15 Foundations Whitepapers Index**](doc/foundations/README.md)

### Core Reactive Engine Foundations
* [Core Whitepaper 01: 2-Phase LPDAG Engine & Glitch-Freedom](https://github.com/pioneerjkf/blooming/blob/main/packages/blooming/doc/foundations/01_lpdag_two_phase_engine_and_glitch_freedom.md)
* [Core Whitepaper 03: Subscriber-Driven Inactive Dormancy & Pure Lazy Lifecycle](https://github.com/pioneerjkf/blooming/blob/main/packages/blooming/doc/foundations/03_subscriber_driven_dormancy.md)
* [Core Whitepaper 09: Graceful Lifecycle & Mooring: Zero-Thrashing Transient Retention](https://github.com/pioneerjkf/blooming/blob/main/packages/blooming/doc/foundations/09_graceful_lifecycle_and_mooring_terminal.md)
* [Core Whitepaper 15: Zero-Allocation Reactive Graph: Dart VM Optimization](https://github.com/pioneerjkf/blooming/blob/main/packages/blooming/doc/foundations/15_dart_vm_low_overhead_memory_engineering.md)
* [Core Whitepaper 17: Imperative Signals & Transient Events](https://github.com/pioneerjkf/blooming/blob/main/packages/blooming/doc/foundations/17_imperative_signals_and_transient_events.md)

---

## High-Frequency Stream Benchmark (NASDAQ 50-Level Order Book)

To validate UI thread responsiveness and event loop integrity under extreme high-frequency event ingestion, `blooming_flutter` was benchmarked against major Flutter state management frameworks using a 50-level full-depth NASDAQ Order Book simulation.

### Hardware & Software Environment

| Specification | Details |
| :--- | :--- |
| **Processor** | Apple M5 Max (18 Cores) |
| **Memory** | 36 GB Unified Memory |
| **Operating System** | macOS 26.4 (Build 25E246) |
| **Flutter SDK** | Flutter 3.47.6 (Channel stable, revision `5fc346839b`) |
| **Dart SDK** | Dart 3.13.5 |
| **Execution Engine** | Real macOS GPU Window (`flutter drive -d macos --profile`) |
| **Target Load** | 1,000,000,000 TPS (Extreme Ingestion Scenario) |
| **Test Parameters** | Duration: 30s · Warmup: 3s · 10 Shuffled Sets (60 total runs) |
| **Sampling Mechanism** | 33ms interval `Timer.run()` lag probe across full 30s window (~915 samples/run in pre-allocated `Float64List`) |

### Tested Framework Profiles

| Framework | Node Topology | Release Status | Architectural Characteristic |
| :--- | :---: | :--- | :--- |
| **Blooming** | **1 : N** | **Published on pub.dev** ([`blooming_flutter`](https://pub.dev/packages/blooming_flutter)) | 2-Phase LPDAG (Push-Dirty, Lazy-Pull) multi-subscriber graph with surgical leaf rebuilds. |
| **Coralline** | **1 : 1** | **Published on pub.dev** ([`coralline`](https://pub.dev/packages/coralline)) | Ultra-high throughput 1:1 direct chain node reactive graph. |
| **Signals** | **1 : N** | Published on pub.dev ([`signals_flutter`](https://pub.dev/packages/signals_flutter) `^7.1.0`) | Fine-grained computed reactive primitives (community open-source). |
| **Riverpod** | **1 : N** | Published on pub.dev ([`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) `^3.4.2`) | Ecosystem standard provider-based dependency graph (community open-source). |

### Main Isolate Responsiveness: Event Loop Lag (10-Set Aggregated)

> **Event Loop Lag**: Delay until a scheduled `Timer.run()` executes on Dart's main event loop ($\Delta t = T_{executed} - T_{scheduled}$). As the main event loop services both timer callbacks and UI rendering pipeline events on the main isolate, maintaining minimal event loop lag serves as a key proxy metric ensuring the UI thread remains unblocked and stutter-free during high-frequency ingestion.

| Framework | Node Topology | Lag Median | Lag Trimmed Mean | Lag Mean | P99 Lag | Max Lag | Memory (RSS) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Blooming** | 1 : N | 0.060 ms | 0.154 ms | 0.157 ms | 3.391 ms | 4.070 ms | 194.4 MB |
| **Coralline** | 1 : 1 | **0.058 ms** | **0.151 ms** | **0.150 ms** | 3.429 ms | 4.029 ms | 201.2 MB |
| **Signals** | 1 : N | 0.061 ms | 0.154 ms | 0.155 ms | 3.394 ms | **3.961 ms** | **194.2 MB** |
| **Riverpod** | 1 : N | 0.294 ms | 0.450 ms | 0.448 ms | **3.285 ms** | 4.676 ms | 201.1 MB |

*Note: Bold numbers highlight the best metric in each column. Differences under 0.01 ms among reactive graph engines (Bloom, Coralline, Signals) are within system run-to-run noise, whereas traditional provider graphs exhibit ~4–5× higher event loop latency under heavy load. Sustained TPS is intentionally omitted as the arithmetic tick accumulator does not discriminate between frameworks.*

---

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](https://github.com/pioneerjkf/blooming/blob/main/packages/blooming_flutter/LICENSE) file for details.

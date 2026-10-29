# Listenable Interoperability & Reactive Bridges Specification
## (Bidirectional Listenable Harmonization: toBloom, toBloomBy, toListenable, and Zero-Leak Dormancy)

> **"When a modern reactive framework isolates itself from the existing runtime ecosystem, it forfeits pragmatic developer utility. `blooming_flutter` integrates Flutter's foundational `Listenable` and `ChangeNotifier` primitives into the 2-Phase LPDAG via demand-driven, leak-free reactive bridges."**  
> — *Bloom Framework Core Systems Group*

---

## 1. Executive Summary & Problem Statement

Numerous native Flutter framework controllers and third-party packages are engineered around Flutter's foundation contracts (`Listenable`, `ValueListenable<T>`, `ChangeNotifier`):
- `ScrollController`: Dispatches high-frequency scroll offsets and scroll metrics updates.
- `TextEditingController`: Dispatches raw text editing, composing, and cursor selection updates.
- `AnimationController`: Dispatches normalized frame progress updates ($0.0 \to 1.0$).
- Media engines (`video_player`, `camera`): Dispatch frame metrics, playback position, and device hardware states.

Consuming these primitives cleanly in standard Flutter necessitates `StatefulWidget` boilerplate with explicit `addListener` and `removeListener` hooks. Failing to deregister listeners during element unmount produces insidious memory leaks, ghost notifications, and frame drops.

`package:blooming_flutter` eliminates this operational overhead through bidirectional demand-driven bridges:
* **Flutter $\to$ Bloom**: [`ValueListenable.toBloom()`](../../lib/src/foundation/change_notifier.dart) and [`Listenable.toBloomBy()`](../../lib/src/foundation/change_notifier.dart)
* **Bloom $\to$ Flutter**: [`Bloom.toListenable()`](../../lib/src/foundation/change_notifier.dart)

---

## 2. Demand-Driven Bridge Architecture

Bridges in `blooming_flutter` do not maintain standing listeners. They operate under the framework's **Subscriber-Driven Inactive Dormancy** invariant:

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│                     Demand-Driven Listenable Bridge Flow                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   [ Initial State: No Active Consumers (isActive == false) ]                   │
│   ValueListenable (Dormant) ──► Listenable.addListener is NOT called!           │
│                                                                                 │
│   [ Event: Terminal Subscribes via via(bridgeBloom) ]                            │
│          │                                                                      │
│          ▼                                                                      │
│   terminal.activate() ──► Bridge executes Listenable.addListener(_listen)       │
│                                  │ (Catches up to latest value on activation)   │
│                                  ▼                                              │
│   Listenable.notifyListeners() ──► Extracts value ──► Distinct Equality Check?  │
│                                                          │                      │
│                            ┌─────────────────────────────┴────────┐             │
│                            ▼ (Identical Value)                    ▼ (Changed)   │
│                         [ DROP ]                        Topological Push-Dirty  │
│                                                                                 │
│   [ Event: Terminal Unmounts / Navigates Away ]                                 │
│          │                                                                      │
│          ▼                                                                      │
│   terminal.deactivate() ──► Bridge executes Listenable.removeListener(_listen)  │
│                             (Zero dangling callbacks, zero memory leaks!)       │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Bidirectional Bridge Taxonomy

### 3.1 `ValueListenable.toBloom()`: 1:1 Value Bridge

Adapts a `ValueNotifier<T>` or `ValueListenable<T>` directly into a reactive [`Bloom<T>`](../../../blooming/lib/src/bloom/bloom.dart) node via [`_ValueListenableBloomPipe<T>`](../../lib/src/foundation/_internal/_change_notifier.dart):

```dart
// packages/blooming_flutter/lib/src/foundation/change_notifier.dart
extension ValueListenableBloomExtension<T> on ValueListenable<T> {
  Bloom<T> toBloom({
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    Graceful? graceful,
  });
}
```

* **Demand-Driven Handshake**: Listener is attached inside `_onActivate()` and removed inside `_onDeactivate()`.
* **Activation Catch-Up**: Calls `_controller.setGuarded(() => _listenable.value)` upon activation to catch any mutations that occurred while dormant.
* **Distinct Deduplication**: Suppresses downstream dirty pulses if consecutive emissions match according to `equals`.
* **Graceful Mooring Support**: Accepts optional [`Graceful`](../../../blooming/lib/src/engine/graceful.dart) policy to defer listener teardown during rapid unmount/remount intervals (e.g. tab switches).

---

### 3.2 `Listenable.toBloomBy<R>()`: Granular Selector Extraction

Transforms multi-attribute, high-frequency `Listenable` instances (such as `ScrollController`) into targeted, strongly-typed [`Bloom<R>`](../../../blooming/lib/src/bloom/bloom.dart) slices via [`_ListenableSelectorBloomPipe<N, R>`](../../lib/src/foundation/_internal/_change_notifier.dart):

```dart
// packages/blooming_flutter/lib/src/foundation/change_notifier.dart
extension ListenableBloomExtension<L extends Listenable> on L {
  Bloom<R> toBloomBy<R>(
    R Function(L target) selector, {
    bool distinct = true,
    bool Function(R previous, R next)? equals,
    Graceful? graceful,
  });
}
```

* **Targeted Slice Extraction**: Transforms complex controllers into fine-grained reactive values (e.g. projecting a `ScrollController` down to `bool isScrolled`).
* **Noise Elimination**: High-frequency controller events (e.g., velocity updates, physics bounces) are filtered out at the threshold if the extracted slice $R$ remains unchanged.
* **Fault Isolation**: If `selector(target)` throws during initialization, the bridge safely initializes the underlying controller into an Error state without crashing the widget tree.

---

### 3.3 `Bloom.toListenable()`: Reverse Interoperability Bridge

Exposes a reactive [`Bloom<T>`](../../../blooming/lib/src/bloom/bloom.dart) node back to the Flutter ecosystem as a standard `ValueListenable<T>` via [`_BloomValueListenable<T>`](../../lib/src/foundation/_internal/_change_notifier.dart):

```dart
// packages/blooming_flutter/lib/src/foundation/change_notifier.dart
extension BloomListenableExtension<T> on Bloom<T> {
  ValueListenable<T> toListenable({bool sync = true});
}
```

* **Zero-Overhead Terminal Mooring**: Internally instantiates a [`RawBloomTerminal<T>`](../../../blooming/lib/src/engine/terminal.dart) when the first listener attaches (`_head` becomes non-null), and deactivates it when the last listener detaches (`_head == null`). Traverses listeners via an intrusive doubly-linked list with zero heap allocation per notification pass.
* **Synchronous vs. Coalesced Modes**:
  - `sync: true` (default): Synchronously dispatches notifications upon state mutation, satisfying Flutter's immediate contract.
  - `sync: false`: Routes through `_bloom.coalesced()`, batching high-frequency invalidations into a single microtask turn.
* **Error Containment**: Exceptions thrown inside Flutter listener callbacks are isolated and reported cleanly via `FlutterError.reportError`.

---

## 4. Anti-Pattern Prevention Guide

> [!WARNING]
> **Anti-Pattern Warning: Recreating Bridges Inside `build()` or `computed()`**  
> Never invoke `.toBloom()` or `.toBloomBy()` inside `build()` methods or dynamic `computed` closures on every evaluation pass. Doing so creates duplicate bridge nodes and accumulates orphaned listeners. Always declare and cache bridges once in controller, ViewModel, or State object fields.

```dart
// BAD: Re-creates Bloom pipeline on every build pass
Widget build(BuildContext context, BloomVia via) {
  final offsetBloom = scrollController.toBloomBy((c) => c.offset); // Memory leak!
  return Text('${via(offsetBloom)}');
}

// GOOD: Declare and cache once in a controller or widget field
class ScrollIndicator extends BloomWidget {
  ScrollIndicator(this.controller, {super.key});
  final ScrollController controller;

  late final offsetBloom = controller.toBloomBy(
    (c) => c.hasClients ? c.offset : 0.0,
    distinct: true,
  );

  @override
  Widget build(BuildContext context, BloomVia via) => Text('Offset: ${via(offsetBloom)}');
}
```

---

## 5. Production Implementation Patterns

### Pattern 1: Collapsing Header Navigation with `ScrollController`

Projects continuous scroll metrics into a distinct boolean state, eliminating frame churn:

```dart
base class CollapsingHeaderView extends BloomWidget {
  CollapsingHeaderView({super.key});

  final scrollController = ScrollController();

  // Projects scroll offset into a distinct boolean threshold node
  late final isCollapsedBloom = scrollController.toBloomBy(
    (c) => c.hasClients && c.offset > 100.0,
    distinct: true,
  );

  @override
  Widget build(BuildContext context, BloomVia via) {
    final isCollapsed = via(isCollapsedBloom);
    return Scaffold(
      appBar: AppBar(
        title: Text(isCollapsed ? 'Compact Title' : 'Full Detailed Header'),
        backgroundColor: isCollapsed ? Colors.indigo : Colors.transparent,
      ),
      body: ListView.builder(
        controller: scrollController,
        itemCount: 100,
        itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
      ),
    );
  }
}
```

### Pattern 2: TextEditingController Debounced Form Validation

Extracts raw text, bridges to a debounced derivation, and updates UI without re-rendering the whole form:

```dart
// 1. Managed TextEditingController: auto-allocated upon mount, moored gracefully, auto-disposed
final textController = managed<TextEditingController>(
  create: (via) => TextEditingController(),
  dispose: (c) => c.dispose(),
  graceful: Graceful.microtask,
);

// 2. Bridge text changes to reactive Bloom using toBloomBy
final queryBloom =
    switched((via) => via(textController).toBloomBy((c) => c.text));

// 3. Debounced search derivation
final searchBloom = queryBloom.debounced(const Duration(milliseconds: 300));

class SearchBarWidget extends BloomWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final search = via(searchBloom);

    return Column(
      children: [
        TextField(controller: via(textController)),
        Text('Searching for: $search'),
      ],
    );
  }
}
```

### Pattern 3: Bidirectional Interop with Third-Party Widgets

Consuming a Bloom reactive state inside an external widget that demands Flutter's `ValueListenable`:

```dart
// Bridges Bloom<int> to ValueListenable<int> with zero-overhead terminal mooring
final countListenable = counterBloom.toListenable();

Widget build(BuildContext context) {
  return ValueListenableBuilder<int>(
    valueListenable: countListenable,
    builder: (context, count, _) => Text('Count: $count'),
  );
}
```

---

## 6. Core Engineering Invariants

| # | Invariant Name | Mathematical / Topological Rule | Verification Mechanism |
| :---: | :--- | :--- | :--- |
| **I** | **Subscriber-Driven Dormancy** | No consumer $\implies$ `addListener` is never called. Zero standing callbacks on idle Listenables. | Verified via mock Listenable listener count checks while dormant. |
| **II** | **Activation Catch-Up** | Transition $0 \to 1 \implies$ immediately evaluates current `listenable.value` via `setGuarded`. | Confirmed by reading `untracked(node)` immediately upon terminal activation. |
| **III** | **Deduplication Filtering** | $v_{t} = v_{t-1} \implies \text{Push-Dirty dropped}$. High-frequency duplicates emit 0 DAG pulses. | Enforced by `_DistinctEntry` shallow equality checks. |
| **IV** | **Deterministic Teardown** | All consumers detach $\implies$ `removeListener` executed synchronously in $O(1)$. | Verified by asserting `hasListeners == false` upon deactivation. |
| **V** | **Reverse Mooring Integrity** | `toListenable()` attaches `RawBloomTerminal` if and only if Flutter listener count $\ge 1$. | Validated by `_BloomValueListenable.addListener` and `removeListener` tests. |
| **VI** | **Graceful Retention Support** | Rapid unmount/remount preserves Listenable bindings during `Graceful` grace windows. | Verified by `Graceful.period()` tests across simulated tab changes. |

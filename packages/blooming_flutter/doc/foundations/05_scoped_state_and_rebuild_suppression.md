# Scoped State Provision & Rebuild Suppression Specification
## (Scoped State Provision & Rebuild Suppression: BloomProvider)

> **"Traditional `InheritedWidget`s indiscriminately rebuild all dependent subtrees whenever state mutates. `BloomProvider` leverages InheritedWidget solely for tree-based discovery while suppressing rebuild cascades, routing surgical micro-updates strictly through the LPDAG."**  
> — *Bloom Framework Core Systems Group*

---

## 1. Overview and Background: The Subtree Invalidation Problem in Flutter `InheritedWidget`

Flutter's standard dependency injection mechanism, `InheritedWidget`, passes state down widget hierarchies but introduces a major architectural bottleneck:

1. **Broad Subtree Invalidation**:
   When data within an `InheritedWidget` changes, every descendant that invoked `dependOnInheritedWidgetOfExactType` is scheduled for `markNeedsBuild()`. Mutating a single localized field forces the entire consuming view to re-execute `build()`.
2. **O(N) Search and Allocation Overhead in Deeply Nested Providers**:
   Wrapping widgets in dozens of nested provider layers inflates widget tree depth, creating redundant Element wrappers on every render pass.

`package:blooming_flutter` resolves these issues via **Rebuild-Suppressed `BloomProvider<T>`** and **`BloomViaContextExtension` (`via.of<T>(context)`)**.

---

## 2. `BloomProvider` Rebuild Suppression Architecture

`BloomProvider` does not inject mutable data directly; it injects the **immutable `Bloom<T>` reactive node reference itself**:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   BloomProvider Architecture & Flow                     │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   [ Parent Widget Tree ]                                               │
│   BloomProvider<CounterState>(bloom: counterController.bloom)             │
│        │                                                               │
│        ├─► updateShouldNotify: !identical(old.bloom, new.bloom)          │
│        │   (Node reference unchanged? ──► Rebuild Propagation: ZERO!)  │
│        │                                                               │
│        ▼ (Descendants read via bloomOf<T>() or via.of<T>(context))       │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │ Consumer 1: HeaderWidget (Reads state.title)                   │   │
│   │ Consumer 2: CounterDisplay (Reads state.count)                 │   │
│   │ Consumer 3: HeavyBackground (Does not read state)              │   │
│   └────────────────────────────────┬───────────────────────────────┘   │
│                                    │                                   │
│   [ Event: counterController.data.count++ ]                            │
│        │                                                               │
│        ▼                                                               │
│   Topological 2-Phase LPDAG Dirty Pulse                                │
│        │                                                               │
│        ├─► HeavyBackground  : Rebuild Count: 0 (No edge)               │
│        ├─► HeaderWidget     : Rebuild Count: 0 (count ignored)         │
│        └─► CounterDisplay   : Rebuild Count: 1 (Surgical Update!)      │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Foundational Architecture Invariants

### Invariant 1: Reference Identity Invariant in `updateShouldNotify`
```dart
// packages/blooming_flutter/lib/src/widgets/provider.dart
class BloomProvider<T> extends InheritedWidget {
  const BloomProvider({
    super.key,
    required this.bloom,
    required super.child,
  });

  final Bloom<T> bloom;

  @override
  bool updateShouldNotify(covariant BloomProvider<T> oldWidget) {
    return !identical(oldWidget.bloom, bloom);
  }
}
```
- Regardless of how frequently the underlying data inside `bloom` mutates, as long as the `bloom` object reference remains unchanged, `updateShouldNotify` returns `false`.
- **Invariant**: *Indiscriminate subtree rebuild cascades at the Flutter `InheritedWidget` layer are 100% suppressed.*

### Invariant 2: Scoped Dependency Observation via `BloomViaContextExtension`
When descendants call `via.of<T>(context)`, Bloom resolves the ancestor `BloomProvider<T>` via `dependOnInheritedWidgetOfExactType<BloomProvider<T>>()` and registers the `Bloom<T>` node with `BloomVia`:

```dart
// packages/blooming_flutter/lib/src/widgets/provider.dart
extension BloomViaContextExtension on BloomVia {
  @pragma('vm:prefer-inline')
  T of<T>(BuildContext context) => this(context.bloomOf<T>());

  @pragma('vm:prefer-inline')
  T? maybeOf<T>(BuildContext context) => this(context.maybeBloomOf<T>());
}
```
- If the widget tree reparents and `BloomProvider<T>` binds to a different `Bloom<T>` instance, `didChangeDependencies()` invokes `terminal.markDirty()`, allowing 1-Pass Epoch Sweeping to sever the prior edge and transition to the new node seamlessly on the next build pass.
- This prevents memory leaks and orphan references to obsolete ancestor scopes.

---

## 4. Production Code Patterns

### 1. Scoped State Provision (`provide` Extension Syntax)
```dart
class StorePage extends StatelessWidget {
  StorePage({super.key});

  final cartController = blooming(CartState());

  @override
  Widget build(BuildContext context) {
    // Declarative provisioning via bloom.provide
    return cartController.bloom.provide(
      child: Scaffold(
        appBar: AppBar(title: const Text('Store')),
        body: const ProductListView(),
        bottomNavigationBar: const CartSummaryBar(),
      ),
    );
  }
}
```

### 2. Declarative Injected Consumption in `BloomWidget` (`bloomOf<T>` & `via.of<T>`)
```dart
base class CartSummaryBar extends BloomWidget {
  const CartSummaryBar({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    // Declarative ancestor state lookup & reactive observation via via.of<T>(context)
    final cart = via.of<CartState>(context);
    // Or traditional nested: via(context.bloomOf<CartState>())
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text('Total: \$${cart.totalPrice} (${cart.itemCount} items)'),
    );
  }
}
```

### 3. Inline Consumption in Micro-Widgets (`via.of<T>(context)`)
```dart
class CartItemCounter extends StatelessWidget {
  const CartItemCounter({super.key});

  @override
  Widget build(BuildContext context) {
    return composed((context, via) {
      final cart = via.of<CartState>(context);
      return Badge(label: Text('${cart.itemCount}'));
    });
  }
}
```

---

## 5. Architectural Conclusions

`BloomProvider` retains the discovery capabilities of `InheritedWidget` while eliminating subtree rebuild cascades through 2-Phase LPDAG topological routing.

Enterprise applications achieve structured dependency injection without sacrificing surgical micro-rendering performance.

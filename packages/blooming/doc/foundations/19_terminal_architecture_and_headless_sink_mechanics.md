# Terminal Architecture & Headless Sink Mechanics Specification
## (LPDAG Sink Theory, Active Boundary Transitions, RawTerminal Taxonomy, and Headless Execution Invariants)

> **"A pure Lazy-Pull DAG is a dormant potential until a Terminal grounds it. Terminals are the physical sinks of the reactive graph—the energetic boundary where downstream pull forces convert idle potential into concrete state computations."**  
> — *Bloom Framework Core Systems Group*

---

## 1. Overview and Foundations: The Graph Theory of LPDAG Sinks

In topological reactive programming, an engine modeled as a Directed Acyclic Graph (DAG) fundamentally divides all nodes into three distinct topological classifications:

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    Tripartite Graph Topology of the LPDAG Engine                │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   1. Source Nodes (In-degree = 0, Out-degree > 0)                               │
│      [BloomController<T>]  /  [BloomSignal]                                       │
│      • Originates state mutations & Push-Dirty invalidation waves               │
│                                                                                 │
│                                      │ (Directed Invalidation / Pull Edges)     │
│                                      ▼                                          │
│                                                                                 │
│   2. Intermediate Nodes (In-degree > 0, Out-degree > 0)                         │
│      [computed<T>]  /  [managed<T>]  /  [switched<T>]  /  [Computation<T>]      │
│      • Functional state derivations, branch morphing, lifecycle supervision    │
│      • Lazily evaluates state; caches values; dormant without subscribers       │
│                                                                                 │
│                                      │ (Directed Invalidation / Pull Edges)     │
│                                      ▼                                          │
│                                                                                 │
│   3. Sink Nodes / Terminals (In-degree > 0, Out-degree = 0)                    │
│      [RawBloomTerminal<T>]  /  [RawViaTerminal<T>]  /  [RawComputedTerminal<T>]  │
│      • Grounds the reactive graph; consumes invalidation pulses                 │
│      • The Active Boundary: controls upstream activation / dormancy             │
│      • Bridges reactive state to external schedulers (Flutter UI, CLI, Tests)   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 1.1 The Necessity of the Sink

In traditional eager reactive architectures, intermediate nodes compute immediately upon upstream state changes, regardless of whether any consumer is observing them. 

The Bloom Framework adheres strictly to **Subscriber-Driven Dormancy**:
* If an intermediate node has zero active subscribers (`!_hasTargets`), its execution **completely suspends**.
* No CPU cycles are expended calculating unused derivations.
* External subscriptions (WebSockets, database streams, sensor polling) are **never established** or are immediately torn down.

Because of this invariant, a reactive DAG cannot execute in a vacuum. It requires an active **Terminal** (a Sink node) to:
1. **Anchor the Topology**: Formally attach to downstream edges, transitioning upstream nodes from dormant ($0$) to active ($1$).
2. **Sink Invalidation Pulses**: Receive synchronous Push-Dirty signals from upstream mutations and schedule external reactions.
3. **Execute Lazy-Pull Queries**: Trigger synchronous data resolution on-demand via `.data`, `.snapshot`, or explicit `evaluate()`.

In Flutter applications, widget elements (`composed`, `bloom.build`, `BloomWidget`) act as implicit terminals. In headless environments—such as server-side microservices, background command-line tools, and pure Dart unit tests—reactive graphs are driven programmatically through the **[`RawTerminal`](../../lib/src/engine/terminal.dart)** taxonomy.

---

## 2. The Active Boundary: $0 \leftrightarrow 1$ Lifecycle Transitions

### 2.1 The Dormancy Invariant

When an intermediate reactive node is instantiated, it begins its existence in a dormant, inactive state:

```dart
const externalEventStream = Stream<String>.empty();

final streamNode = computed.stream((via) => externalEventStream);
final resourceNode = managed(
  create: (via) => ApiClient(port: 8080),
  dispose: (service) => service.close(),
);
```

* `streamNode` does **not** listen to `externalEventStream`.
* `resourceNode` has **not** invoked `ApiClient(port: 8080)`.
* Internal state remains uninitialized (`_state ??= _EmptyBloomState()`).

If a system attempts to inspect these nodes without establishing an active subscriber, the nodes will remain dormant.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   Dormancy vs. Terminal Mooring                        │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   [ Dormant State (0 Consumers) ]                                      │
│   untracked(node); // One-time untracked read; node remains DORMANT!   │
│   streamNode; // Stream subscription NOT established!                  │
│                                                                        │
│   [ Active Grounding (Terminal Mooring) ]                              │
│   final terminal = RawBloomTerminal(streamNode, onInvalidated: () {});  │
│   terminal.activate(); // 0 -> 1 Handshake: Powers on upstream graph!  │
│                                                                        │
│   // Upstream external stream listener attached synchronously!         │
│   streamController.add("Event 1");                                     │
│   await Future<void>.delayed(Duration.zero); // Microtask flush        │
│   expect(terminal.data, "Event 1"); // Verified!                       │
│                                                                        │
│   terminal.deactivate(); // 1 -> 0 Teardown: Clean deactivation        │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Untracked Reads (`untracked(...)`) vs. Terminal Grounding

A fundamental distinction exists between reading a node's immediate value and establishing reactive grounding:

* **[`untracked(node)`](../../lib/src/bloom/untracked.dart) / [`untracked.state(node)`](../../lib/src/bloom/untracked.dart)**:
  - Invokes `_read()` directly via inlined internal resolver without creating dependency edges and without registering as a target.
  - Evaluates the current state on-demand without creating dependency edges and without registering as a target.
  - Leaves `_lifecycle.isActive` strictly `false`.
  - **Does not awaken dormant async stream listeners or allocate `managed` handles.**
* **[`terminal.activate()`](../../lib/src/engine/terminal.dart)**:
  - Synchronously transitions `_lifecycle.isActive` from `false` to `true`.
  - Attaches an intrusive target edge ([`_attachTargetEdgeOptimistically`](../../lib/src/engine/_internal/_node.dart)) to the upstream node.
  - Cascades activation upstream via `_activateOptimistically()`, awakening streams, futures, and managed resources.

---

## 3. The Terminal Taxonomy: Deep Mechanical Specifications

The engine provides three specialized concrete implementations under the [`RawTerminal`](../../lib/src/engine/terminal.dart) interface:

```text
                               ┌─────────────────────────┐
                               │   RawTerminal (Base)    │
                               │ - activate()            │
                               │ - deactivate()          │
                               │ - debugForceInvalidate()│
                               └────────────┬────────────┘
                                            │
         ┌──────────────────────────────────┼──────────────────────────────────┐
         ▼                                  ▼                                  ▼
┌─────────────────────────┐      ┌─────────────────────────┐      ┌─────────────────────────┐
│     RawBloomTerminal     │      │     RawViaTerminal      │      │   RawComputedTerminal   │
├─────────────────────────┤      ├─────────────────────────┤      ├─────────────────────────┤
│ • 1:1 Unary Terminal    │      │ • N-ary Dynamic Via     │      │ • N-ary Leaf Computed   │
│ • Zero-Copy SSOT        │      │ • 1-Pass Epoch Sweep    │      │ • 0-Compute on Cache Hit│
│ • Direct BloomState read │      │ • Explicit evaluate()   │      │ • Lazy Pull on .data    │
│ • Immutable 1:1 binding │      │ • Tests dynamic branches│      │ • markDirty() support   │
└─────────────────────────┘      └─────────────────────────┘      └─────────────────────────┘
```

### 3.1 Terminal Comparison Matrix

| Terminal Class | Edge Cardinality | Evaluation Protocol | State Caching | Dynamic Dependency Sweeping | Primary Headless Use Case |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **[`RawBloomTerminal<T>`](../../lib/src/engine/terminal.dart)** | 1:1 (Unary) | Direct Delegation (`_read()`) | No (Zero-Copy SSOT) | N/A (Fixed 1:1) | Observing single nodes, testing Stream/Future bridges, validating `managed` lifecycles |
| **[`RawViaTerminal<T>`](../../lib/src/engine/terminal.dart)** | N-ary (Dynamic) | Explicit `evaluate()` | No (Transient) | 1-Pass Monotonic Epoch Sweep | Testing dynamic conditional branches (`if/else`), acyclic verification |
| **[`RawComputedTerminal<T>`](../../lib/src/engine/terminal.dart)** | N-ary (Dynamic) | Lazy pull on `.data` / `.snapshot` | Yes (0-Compute) | 1-Pass Monotonic Epoch Sweep | Headless leaf computation, cache coherency validation, dirty short-circuit testing |

---

### 3.2 `RawBloomTerminal<T>`: The 1:1 Zero-Copy Passive Gateway

[`RawBloomTerminal<T>`](../../lib/src/engine/terminal.dart) is a specialized low-level terminal designed specifically for observing a single upstream [`Bloom<T>`](../../lib/src/bloom/bloom.dart) pipeline.

```dart
// packages/blooming/lib/src/engine/terminal.dart
base class RawBloomTerminal<T> extends _RawTerminal
    with _UnaryEdgeMixin<Bloom<T>>, _BloomStateMixin<T>, _BloomTerminalMixin<T>
    implements BloomState<T> {
  RawBloomTerminal(
    Bloom<T> source, {
    required super.onInvalidated,
    super.onUncaughtError,
  }) {
    _source = source;
    _pulledVersion = source._version;
  }
  ...
}
```

#### Key Engineering Invariants:
1. **Zero-Copy SSOT Delegation**:
   Unlike intermediate derivation nodes (`computed`) which cache their own derived state in a local `_state` field, `RawBloomTerminal` **never shadows or duplicates state**:
   ```dart
   // packages/blooming/lib/src/engine/_internal/_terminal.dart
   @override
   _BloomState<T> _read() {
     final state = _source._read();
     _pullVersion();
     return state;
   }
   ```
   Direct state inspection via `terminal.data`, `terminal.isEmpty`, or `terminal.hasData` directly dereferences the upstream source's internal state container with **zero heap allocation** and completely eliminates cache desynchronization. Calling `terminal.snapshot` delegates directly to the upstream state without redundant caching, lazily materializing an immutable snapshot instance on-demand.
2. **Direct State Protocol Implementation**:
   Because `RawBloomTerminal` mixes in [`_BloomStateMixin<T>`](../../lib/src/bloom/_internal/_state.dart) and implements [`BloomState<T>`](../../lib/src/bloom/state.dart), external consumers can inspect state properties directly on the terminal instance:
   ```dart
   final source = blooming(42).bloom;
   final term = RawBloomTerminal(source, onInvalidated: () {});
   if (term.hasData) print(term.data);
   ```
3. **Immutable 1:1 Topological Binding**:
   `RawBloomTerminal` is strictly bound to its single upstream source for its entire lifetime. If the upstream source changes in a consumer environment (such as a Flutter `Element.update`), the consumer simply deactivates and replaces the terminal instance, preserving clean `activate()` / `deactivate()` lifecycle handshakes without edge-swapping side effects.

---

### 3.3 `RawViaTerminal<T>`: N-ary Explicit Reactive Evaluator

[`RawViaTerminal<T>`](../../lib/src/engine/terminal.dart) is designed for multi-dependency observation where dependencies are registered dynamically via an injected [`BloomVia`](../../lib/src/engine/via.dart) handle during an explicit evaluation call.

```dart
// packages/blooming/lib/src/engine/terminal.dart
base class RawViaTerminal<T> extends _RawTerminal 
    with _NaryEdgeMixin<_Node>, _BloomViaEpochMixin, _ViaTerminalMixin<T> {
  RawViaTerminal(
    T Function(BloomVia via) evaluator, {
    required super.onInvalidated,
    super.onUncaughtError,
  }) {
    _evaluator = evaluator;
  }
}
```

#### Mechanical Flow of `evaluate()`:
```text
[terminal.evaluate()]
       │
       ├─► 1. Increment epoch counter (++_epoch)
       ├─► 2. Execute evaluator(via)
       │         │
       │         └─► via(node) registers dependency edge with current epoch
       │
       └─► 3. _endEpoch(currentEpoch, commitVersions: true)
                 └─► 1-pass: detaches unused dependencies & commits versions
```

1. **Explicit Pull Boundary**:
   `RawViaTerminal` does not cache computed state. Calling `evaluate()` executes the evaluator closure synchronously, sweeps dependencies, and returns the computed value $T$.
2. **Cycle Detection**:
   If an evaluator closure recursively invokes `evaluate()` on itself, `RawViaTerminal` detects the cyclic re-entrancy and synchronously throws an [`LpdagCycleError`](../../lib/src/engine/exception.dart).

---

### 3.4 `RawComputedTerminal<T>`: N-ary 1-Hop Leaf Computed Terminal

[`RawComputedTerminal<T>`](../../lib/src/engine/terminal.dart) represents a hybrid: it functions as a terminal sink to external callers, but internally behaves as an engineered **1-hop leaf computed node**.

```dart
// packages/blooming/lib/src/engine/terminal.dart
base class RawComputedTerminal<T> extends _RawTerminal
    with _NaryEdgeMixin<_Node>, _BloomViaEpochMixin, _BloomStateMixin<T>, 
         _PullResolver<T>, _ComputedPullMixin<T>
    implements BloomState<T> {
  RawComputedTerminal(
    T Function(BloomVia via) compute, {
    required super.onInvalidated,
    super.onUncaughtError,
    BloomGuard Function(BloomVia via)? guard,
  })  : _compute = compute,
        _guard = guard;
  ...
}
```

#### Key Engineering Invariants:
1. **0-Compute Cache Hit**:
   When reading `.data` or `.snapshot`, if upstream versions have not changed, `RawComputedTerminal` returns its cached `_state` in 0-compute time ($O(1)$).
2. **Push-Dirty Direct Invalidation**:
   When an upstream dependency mutates, `RawComputedTerminal` marks its state as `_DirtyState.check` and immediately invokes `onInvalidated` without intermediate graph hops.
3. **Imperative Invalidation (`markDirty`)**:
   Provides [`markDirty()`](../../lib/src/engine/terminal.dart) to imperatively force dirty state on the terminal without mutating upstream dependencies, guaranteeing that the subsequent pull re-executes the compute closure.
4. **Precondition Guard Support**:
   Accepts an optional `guard: (via) => ...` parameter, integrating algebraic state gating ([Foundation 18](18_precondition_guarding_and_algebraic_gating.md)) directly at the terminal boundary.

---

## 4. Invalidation Sinking and Microtask Coordination

### 4.1 Synchronous Batch Queuing in `_RawTerminal`

When a state mutation occurs at a source node, invalidation ripples downstream along directed edges during **Phase 1 (Push-Dirty)**.

Unlike intermediate nodes which simply update internal dirty flags (`_dirtyState = _DirtyState.dirty`), a terminal sink must notify external systems.

```dart
// packages/blooming/lib/src/engine/_internal/_terminal.dart
abstract base class _RawTerminal extends _Terminal {
  ...
  @override
  @pragma('vm:prefer-inline')
  void _invalidate() {
    if (!_lifecycle.isActive) return;
    _PushScope.queueTerminal(this);
  }

  void _invalidateInScope() {
    if (!_lifecycle.isActive) return;
    try {
      _onInvalidated.call();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }
}
```

1. **Intrusive Terminal Queue**:
   When invalidated, `_invalidate()` adds the terminal to the current [`_PushScope`](../../lib/src/engine/_internal/_push.dart) linked list (`_flushTerminalHead` / `_flushTerminalTail`).
2. **Single-Dispatch Coalescing**:
   If multiple upstream dependencies mutate within the same execution turn or within a [`batch(() { ... })`](../../lib/src/engine/batch.dart) transaction, the terminal is enqueued only once (`_isPushQueued = true`).
3. **Synchronous Push-Flush**:
   At the end of the push wave, `_PushScope.flush()` iterates through queued terminals and calls `_invalidateInScope()`, invoking `onInvalidated` synchronously without event loop delay.

### 4.2 Invalidation Callback Discipline (Anti-Pattern Prevention)

> [!WARNING]
> **Anti-Pattern**: Performing synchronous domain evaluation or heavy computations inside `onInvalidated`.

Because `onInvalidated` executes within the synchronous Push-Dirty flush of `_PushScope`, pulling data prematurely inside this callback forces Phase 2 (Lazy-Pull) to execute before the entire invalidation wave has settled.

```dart
void render(int val) {}
void markNeedsBuild() {}
final counter = blooming(0);

// BAD: Forces premature lazy-pull during the push-dirty wave!
final badTerm = RawBloomTerminal(counter.bloom, onInvalidated: () {
  final val = untracked(counter.bloom); // Premature pull!
  render(val);
});

// GOOD: Sinks invalidation to schedule external deferred evaluation
final term = RawBloomTerminal(counter.bloom, onInvalidated: () {
  markNeedsBuild(); // Schedules frame for deferred lazy-pull
});
```

---

## 5. Mooring Terminals vs. Evaluation Terminals vs. Effect Terminals

The framework differentiates between four classes of reactive sinks across its architectural tiers:

```text
┌──────────────────────────────────────────────────────────────────────────────────┐
│                   Topological Sink Classification Matrix                         │
├──────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│   1. Programmatic Sinks (RawTerminal) [package:blooming/blooming.dart]           │
│      • RawBloomTerminal, RawViaTerminal, RawComputedTerminal                     │
│      • Pure synchronous invalidation dispatch; explicit pull control             │
│      • Designed for headless execution, custom engine adapters, unit testing     │
│                                                                                  │
│   2. Retention Sinks (_MooringTerminal) [Internal Engine]                        │
│      • Holds intrusive _MooringEdge to prevent unmount thrashing                 │
│      • Drops all invalidation ripples (zero pull, zero evaluate)                 │
│      • Tranquil harbor preserving active upstream pipelines across route changes │
│                                                                                  │
│   3. Side-Effect Sinks (EffectRunner) [package:blooming/effect.dart]             │
│      • Microtask-coalesced scheduler integration (_ScheduledTerminalMixin)       │
│      • Automatically executes side-effect closures with RAII cleanup handles     │
│                                                                                  │
│   4. UI Sinks (composed / bloom.build / BloomWidget) [package:blooming_flutter]  │
│      • Bound to Flutter Element lifecycle (mount / unmount)                      │
│      • Translates onInvalidated to Element.markNeedsBuild()                      │
│                                                                                  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Headless Execution & Verification Patterns

In non-GUI environments (CLI utilities, backend servers, and headless unit tests), developers utilize `RawTerminal` to establish deterministic reactive lifecycles.

### Pattern 1: Testing Dormant Asynchronous Streams (`computed.stream`)

```dart
test('computed.stream awakens only upon terminal activation', () async {
  final controller = StreamController<String>.broadcast();
  final streamBloom = computed.stream((via) => controller.stream);

  // 1. Dormant: Stream listener is NOT registered
  expect(streamBloom.isActive, isFalse);
  controller.add('Ignored Event');
  await Future<void>.delayed(Duration.zero);
  expect(untracked.state(streamBloom).isEmpty, isTrue);

  // 2. Establish Active Terminal Grounding
  final terminal = RawBloomTerminal(streamBloom, onInvalidated: () {});
  terminal.activate(); // Handshake 0 -> 1: awakens stream listener
  expect(streamBloom.isActive, isTrue);

  // 3. Process stream emission
  controller.add('Active Event');
  await Future<void>.delayed(Duration.zero);
  expect(terminal.data, 'Active Event');

  // 4. Clean Teardown
  terminal.deactivate(); // Handshake 1 -> 0: detaches stream listener
  expect(streamBloom.isActive, isFalse);
  await controller.close();
});
```

---

### Pattern 2: Synchronous External Lifecycle Supervision (`managed`)

```dart
test('managed resource lifecycle transitions strictly with terminal', () {
  var allocated = false;
  var disposed = false;

  final resource = managed<ApiClient>(
    create: (via) {
      allocated = true;
      return ApiClient(port: 8080);
    },
    dispose: (client) {
      disposed = true;
      client.close();
    },
  );

  // 1. Dormant: create() has not executed
  expect(allocated, isFalse);

  // 2. Terminal activation triggers allocation
  final terminal = RawBloomTerminal(resource, onInvalidated: () {});
  terminal.activate();
  expect(allocated, isTrue);
  expect(disposed, isFalse);

  // 3. Terminal deactivation triggers synchronous disposal
  terminal.deactivate();
  expect(disposed, isTrue);
});
```

---

### Pattern 3: SWR Future Verification & State Progression (`computed.future`)

```dart
test('computed.future progresses through Empty -> Data under terminal', () async {
  final completer = Completer<int>();
  final asyncBloom = computed.future((via) => completer.future);

  final terminal = RawBloomTerminal(asyncBloom, onInvalidated: () {});
  terminal.activate();

  // Initial state: Empty pending resolution
  expect(terminal.snapshot.isEmpty, isTrue);

  // Resolve future
  completer.complete(100);
  await Future<void>.delayed(Duration.zero);

  // Resolved state
  expect(terminal.hasData, isTrue);
  expect(terminal.data, 100);

  terminal.deactivate();
});
```

---

### Pattern 4: Dynamic Branch Sweeping Inspection (`RawViaTerminal`)

```dart
test('RawViaTerminal sweeps unused dependency edges dynamically', () {
  final condition = blooming(true);
  final branchA = blooming('A');
  final branchB = blooming('B');

  final terminal = RawViaTerminal(
    (via) => via(condition.bloom) ? via(branchA.bloom) : via(branchB.bloom),
    onInvalidated: () {},
  );
  terminal.activate();

  // Initial evaluation: binds condition and branchA
  expect(terminal.evaluate(), 'A');

  // Flip branch condition
  condition.data = false;
  expect(terminal.evaluate(), 'B');

  // Mutating branchA no longer invalidates terminal (1-pass swept!)
  var invalidationCount = 0;
  final countingTerminal = RawViaTerminal(
    (via) => via(condition.bloom) ? via(branchA.bloom) : via(branchB.bloom),
    onInvalidated: () => invalidationCount++,
  );
  countingTerminal.activate();
  countingTerminal.evaluate(); // Bound to branchB

  branchA.data = 'A_mutated';
  expect(invalidationCount, 0); // Confirmed swept!

  countingTerminal.deactivate();
  terminal.deactivate();
});
```

---

### Pattern 5: Zero-Compute Cache Invalidation Simulation (`RawComputedTerminal`)

```dart
test('RawComputedTerminal caches 0-compute hits and invalidates on source delta', () {
  final source = blooming(10);
  var computeCycles = 0;

  final terminal = RawComputedTerminal(
    (via) {
      computeCycles++;
      return via(source.bloom) * 2;
    },
    onInvalidated: () {},
  );
  terminal.activate();

  // Initial pull: computeCycles = 1
  expect(terminal.data, 20);
  expect(computeCycles, 1);

  // Repeated pull without source mutation: 0-Compute hit!
  expect(terminal.data, 20);
  expect(computeCycles, 1);

  // Mutate source: Phase 1 Push-Dirty invalidation
  source.data = 15;

  // Phase 2 Lazy-Pull: recomputed on-demand
  expect(terminal.data, 30);
  expect(computeCycles, 2);

  terminal.deactivate();
});
```

---

### Pattern 6: Zero-Cost Diagnostics & Terminal Reflection (`withDebugLabel`)

In development environments, terminals can be assigned human-readable debug labels via [`RawTerminalDebugExtension`](../../lib/src/engine/debug.dart):

```dart
final userPipeline = blooming('user_1').bloom;
final terminal = RawBloomTerminal(userPipeline, onInvalidated: () {})
    .withDebugLabel('UserSessionTerminal');

terminal.activate();

// Development Hot Reload hook: recursively invalidates upstream DAG
terminal.debugForceInvalidate();
```

* **Zero-Cost Release Contract**: All debug labels and introspection maps are backed by zero-overhead VM mechanisms (`Expando`). In Profile and Release builds, these operations are completely stripped by the Dart VM AOT compiler with 0 heap bytes and 0 CPU overhead.

---

## 7. Core Engineering Invariants of Terminal Sinks

| # | Invariant Name | Mathematical / Topological Rule | Verification Mechanism |
| :---: | :--- | :--- | :--- |
| **I** | **Strict Sink Boundary** | Out-degree of any terminal is strictly 0: $d_{\text{out}}(\text{Terminal}) = 0$. Terminals cannot serve as sources for other reactive nodes. | Engine static type architecture ([`RawTerminal`](../../lib/src/engine/terminal.dart) does not implement [`Bloom`](../../lib/src/bloom/bloom.dart)). |
| **II** | **Dormancy Awakening** | Upstream dormant subtrees ($0$) transition to active ($1$) if and only if an active terminal or subscriber attaches. | Verified via `_lifecycle.isActive` assertions and stream listener attachment tests. |
| **III** | **Zero-Copy SSOT** | `RawBloomTerminal<T>` maintains zero shadow state: `_read() => _source._read()`. Direct field dereference on `.data`. | Confirmed via heap allocation tests and identical object identity checks. |
| **IV** | **1-Pass Monotonic Sweep** | `RawViaTerminal` and `RawComputedTerminal` sweep unused dependency edges in exactly 1 pass with zero intermediate heap allocations. | Verified via `_BloomViaEpochMixin` edge sweep pointer unlinking. |
| **V** | **Synchronous Invalidation Batching** | Multiple synchronous mutations within a push wave or `batch()` trigger at most 1 `onInvalidated` dispatch per terminal. | Enforced by `_isPushQueued` check in `_PushScope.queueTerminal`. |
| **VI** | **Deterministic Teardown** | `terminal.deactivate()` synchronously unlinks target edges and immediately propagates deactivation upstream if subscriber counts hit 0. | Verified via `managed` disposal hooks and unregister assertions. |

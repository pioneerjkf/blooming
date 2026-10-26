# Precondition Guarding & Algebraic State Gating: The Unified Fault-Barrier of the Dynamic Triad
## (Precondition Gating, Deterministic Auto-Disposal, and Zero-Heap Multi-Guards)

> **"A reactive computation must not evaluate on invalid prerequisites, nor should an external resource linger once its operational conditions collapse. The guard is not an imperative filter; it is an algebraic fault-barrier that enforces structural invariants across the 2-Phase LPDAG."**  
> — *Bloom Framework Core Systems Group*

---

## 1. Overview & Architectural Rationale: The Perils of Imperative Gating

In traditional reactive architectures (such as Riverpod, MobX, or Rx-based state machines), gating execution based on prerequisites is frequently treated as an imperative, ad-hoc concern. When downstream derivations or external handles depend on unready upstream states (e.g., an unauthenticated user, an empty input query, or uninitialized hardware handles), developers typically resort to one of three anti-patterns:

1. **Synthetic Dummy Payloads**: Returning placeholder or null values that violate non-null domain invariants and pollute the type system downstream with nullable checks.
2. **Imperative Exception Bailing**: Throwing exceptions inside computation bodies when prerequisites are unmet, which causes false-positive error cascades, floods diagnostic logging, and disrupts downstream UI widgets.
3. **Forgotten Imperative Teardowns**: Forgetting to manually close sockets, cancel timers, or detach listeners when an upstream authentication or connection condition turns false, leading to persistent "zombie" background processes and memory leaks.

```text
[ Imperative Approach: Fragile & Error-Prone ]
Upstream State Change (e.g., User Logs Out)
       │
       ▼
Manual Service Teardown Hook? ──No────► Memory Leaks & 401 Zombie Requests
       │
      Yes
       ▼
Imperatively calls socket.close(), timer.cancel(), tracker.stop() (Human Error Risk: High)

[ Bloom Framework: Declarative Algebraic Guard ]
Upstream State Change (e.g., User Logs Out)
       │
       ▼ (1-Bit Push-Dirty Pulse)
[ guard(via).isPass == false ]
       │
       ├──► computed:    Bypasses calculation; atomically emits Empty(decision.reason)
       ├──► managed:     Automatically invokes dispose(); releases handles; emits Empty
       ├──► switched:    Decouples active branch; keeps candidate subtree dormant
       └──► Computation: Bypasses compute(); surfaces .isEmpty & .emptyReason directly to UI
```

The Bloom Framework resolves these failure modes at the engine level through **Precondition Guarding**. In the Bloom architecture, a guard is a pure, declarative callback (`BloomGuard Function(BloomVia via)?`) that acts as an algebraic barrier. It physically gates node execution, automatically tears down active resources when prerequisites collapse, and cleanly transitions nodes into the framework's canonical `Empty` state without exceptions or type compromises.

---

## 2. Algebraic State Gating: Convergence to `Empty(emptyReason)`

The Bloom Framework models state through a strict 3-state algebraic finite state machine: **Data**, **Empty**, and **Error** (see [Algebraic State Protocol](05_algebraic_state_protocol_and_self_healing_fault_tolerance.md)). 

The `guard` mechanism maps directly to this algebraic protocol via the [`BloomGuard`](../../lib/src/bloom/guard.dart) type:

```text
                          [ Downstream Observation (Pull) ]
                                          │
                                          ▼
                               [ guard(via).isPass? ]
                              ├── No  ────► Emits Empty(decision.reason)
                              │           (Execution / Allocation Aborted;
                              │            reason stored directly in emptyReason)
                              │
                              └── Yes ────► Executes Core Logic
                                          ├── Success ────► Valid(T)
                                          └── Throws  ────► Error(error, stackTrace)
```

### 2.1 The Precondition Gating Invariant
When `guard` evaluates to `BloomGuard.block([reason])`:
- The core payload logic (`compute`, `create`, or `select`) is **completely bypassed**.
- The node transitions to or remains in `_EmptyBloomState<T>`.
- The diagnostic `decision.reason` payload is stored directly in `BloomSnapshot.emptyReason` with zero boxing overhead.

This ensures that downstream consumers never observe corrupted or half-initialized data. Downstream UI components can inspect `.isEmpty` and `.emptyReason` directly to declaratively render explanatory placeholders, disable action buttons, or guide the user, all without treating an unmet prerequisite as an application crash.

### 2.2 2-Phase LPDAG Timing
Under the 2-Phase LPDAG engine:
- **Push-Dirty Phase**: When an upstream node that participates in a `guard` mutates, only a 1-bit invalidation flag travels downstream. **Guards are never evaluated synchronously during the push phase.**
- **Lazy-Pull Phase**:
  - **Synchronous & Dormant Pipelines**: For synchronous computations (`computed`, `managed`, `switched(eager: false)`) and unobserved dormant nodes, the guard is evaluated strictly on-demand when a downstream consumer reads `.data`, `.snapshot`, or an active terminal pulls. Dormant nodes consume zero CPU cycles evaluating guards.
  - **Active Asynchronous & Eager Pipelines**: For active asynchronous bridges ([`_FutureComputedBloom`](../../lib/src/bloom/_internal/_computed.dart), [`_StreamComputedBloom`](../../lib/src/bloom/_internal/_computed.dart)) and eager dynamic cascades ([`_EagerSwitchedBloom`](../../lib/src/bloom/_internal/_switched.dart)), when dependencies mutate while active subscribers exist (`_lifecycle.isActive == true`), the guard and dynamic branch coupling are scheduled proactively on the microtask turn ([`_scheduleEager`](../../lib/src/bloom/_internal/_delta.dart#L182)) to initiate or abort I/O and stream subscriptions eagerly without waiting for a manual read.

---

## 3. The Dynamic Triad & Computation Gating Specification

Precondition guarding forms the unified operational contract across the **Dynamic Triad** ([`computed`](../../lib/src/bloom/computed.dart), [`managed`](../../lib/src/bloom/managed.dart), [`switched`](../../lib/src/bloom/switched.dart)) and class-based components ([`Computation`](../../lib/src/bloom/computed.dart)).

### 3.1 Execution Gating in `computed` (Synchronous & Asynchronous)

In synchronous computations and asynchronous bridges (`computed.future`, `computed.stream`), the guard prevents expensive calculations or premature I/O operations:

```dart
// 1. Synchronous computation with zero-heap record multi-guard:
final a = blooming<int>(10).bloom;
final b = blooming<int>(20).bloom;
final orderTotal = computed(
  (via) => via(a) + via(b),
  guard: (via) => (via.state(a), via.state(b)).guarded(),
);

// 2. Granular early-return pattern with distinct diagnostic reasons:
final checkoutGate = computed(
  (via) => 'Order total: \$${via(a)}',
  guard: (via) {
    if (via.state(a).isEmpty) return BloomGuard.block('CartIsEmpty');
    if (via.state(b).isEmpty) return BloomGuard.block('AddressRequired');
    return BloomGuard.pass;
  },
);

// 3. Asynchronous Future pipeline gated on session availability:
final authToken = blooming<String>('valid_token').bloom;
final userProfile = computed.future(
  (via) => api.fetchUserFeed(),
  guard: (via) => (via.state(authToken).hasData && via(authToken).isNotEmpty)
      .guarded('AwaitingAuthentication'),
);
```

**Engine Guarantee:**
Inside [`_ComputedPullMixin._pull()`](../../lib/src/bloom/_internal/_computed.dart), if `!decision.isPass`, the computation closure is aborted before invocation. For asynchronous pipelines ([`_FutureComputedBloom`](../../lib/src/bloom/_internal/_computed.dart) and [`_StreamComputedBloom`](../../lib/src/bloom/_internal/_computed.dart)), the asynchronous task or stream subscription is never initiated, eliminating unneeded HTTP requests, thread hops, and connection overhead.

### 3.2 Deterministic Auto-Disposal in `managed`

The most critical operational impact of `guard` occurs in [`managed`](../../lib/src/bloom/managed.dart). Beyond simply gating initial allocation, the guard enforces **Deterministic Auto-Disposal**:

```dart
final isTrackingEnabled = blooming<bool>(true).bloom;
final deviceId = blooming<String>('dev_42').bloom;

final liveTelemetry = managed<ApiClient>(
  create: (via) => ApiClient(port: 8080),
  dispose: (client) => client.close(),
  guard: (via) => (via(isTrackingEnabled) && via.state(deviceId).hasData)
      .guarded('TrackingDisabled'),
);
```

#### The State Transition Flow in `_ManagedBloom`:
```text
[ Active Subscriber Connected ]
              │
              ▼
    [ guard(via).isPass? ]
     ├── No  ──► Emits Empty(decision.reason) [create() NOT called]
     └── Yes ──► Calls create() ──► Valid(resource)
              │
              ▼
    [ Upstream Dependency Mutates ]
     ├── guard remains pass  ──► Calls update() (or dispose() + create())
     └── guard becomes block ──► Immediately calls dispose()! ──► Transitions to Empty(decision.reason)
```

**The Engine Invariant:**
As implemented in [`_ManagedBloom._pull()`](../../lib/src/bloom/_internal/_managed.dart):
```dart
// packages/blooming/lib/src/bloom/_internal/_managed.dart
final guard = _guard;
if (guard != null) {
  final decision = guard(_via);
  if (!decision.isPass) {
    final hadData = _state?.hasData ?? false;
    _disposeCurrent(); // Synchronously calls user dispose() callback!
    if (hadData) {
      _version++;
    }
    return _state = _EmptyBloomState<T>(decision.reason);
  }
}
```
If an active resource is currently held, and any dependency in `guard` changes such that the decision becomes `isBlock`, **the engine synchronously invokes `dispose` on the active instance and cleans the slot**. When the condition becomes true again in the future, `create` is invoked to re-instantiate the handle. Human-managed cleanup code is reduced to zero.

### 3.3 Subtree Gating in `switched`

In dynamic topological routing ([`switched`](../../lib/src/bloom/switched.dart)), the guard prevents the initialization and activation of entire downstream subgraphs:

```dart
final selectedTab = blooming<int>(0).bloom;
final normalFeed = blooming<String>('normal').bloom;
final adminFeed = blooming<String>('admin').bloom;
final isSessionValid = blooming<bool>(true).bloom;

final activeDashboardFeed = switched(
  (via) => via(selectedTab) == 0 ? normalFeed : adminFeed,
  guard: (via) => via(isSessionValid).guarded('SessionExpired'),
);
```

When `guard` evaluates to `isBlock`, [`_SwitchedSelectionMixin._evaluateDelta()`](../../lib/src/bloom/_internal/_switched.dart) immediately binds to the static constant node `Bloom.empty(decision.reason)`. The candidate subtrees (`normalFeed` and `adminFeed`) are completely decoupled ([`_performCouple`](../../lib/src/engine/_internal/_relay.dart)), returning them to inactive dormancy and halting all upstream background computation.

### 3.4 Encapsulated Domain Preconditions in `Computation<T>`

In class-based domain components ([`Computation<T>`](../../lib/src/bloom/computed.dart)), `guard` can be configured via constructor parameter or by overriding the `BloomGuard guard(BloomVia via)` method:

```dart
base class CheckoutComputation extends Computation<CheckoutSummary> {
  CheckoutComputation(this.cart, this.paymentMethod, this.shippingAddress);

  final Bloom<Cart> cart;
  final Bloom<String?> paymentMethod;
  final Bloom<Address?> shippingAddress;

  @override
  BloomGuard guard(BloomVia via) {
    if (via.state(cart).isEmpty || via(cart).items.isEmpty) {
      return BloomGuard.block('Your cart is empty.');
    }
    if (via.state(shippingAddress).isEmpty) {
      return BloomGuard.block('Please specify a shipping address.');
    }
    if (via.state(paymentMethod).isEmpty) {
      return BloomGuard.block('Please select a valid payment method.');
    }
    return BloomGuard.pass;
  }

  @override
  CheckoutSummary compute(BloomVia via) {
    return CheckoutSummary(
      subtotal: via(cart).items.fold(0.0, (acc, item) => acc + item.price * item.quantity),
    );
  }
}
```

* **Zero-Unwrap State Dereferencing**: Because `Computation<T>` implements `BloomState<T>`, downstream UI and imperative callers can inspect `checkout.hasData`, `checkout.isEmpty`, and `checkout.emptyReason` directly without `.bloom` unwrapping.
* **Fault Isolation**: If an exception occurs inside `guard()`, Bloom captures it safely via `_BloomState.fromCaught()`, transitioning the component into `hasError` state without crashing the host process.

---

## 4. Zero-Heap Multi-Guarding across Dart 3 Record Tuples

Real-world preconditions frequently depend on multiple upstream entities (e.g., verifying that credentials, session tokens, and network connectivity are all simultaneously valid).

In conventional Dart code, multi-entity checks often introduce heap allocation overhead:
```dart
// [Anti-Pattern] Allocates a temporary List and an Iterator on every evaluation
// guard: (via) => [via(a), via(b), via(c)].every((s) => s.hasData).guarded();
```

To eliminate allocation on hot evaluation paths, Bloom provides compile-time extensions across **Dart 3 Record tuples from arity 2 through 9** (see [`BloomStateRecord2Extension` through `BloomStateRecord9Extension`](../../lib/src/bloom/state.dart)):

```dart
final nodeA = blooming<int>(1).bloom;
final nodeB = blooming<int>(2).bloom;
final nodeC = blooming<int>(3).bloom;

final combinedQuote = computed(
  (via) => via(nodeA) + via(nodeB) + via(nodeC),
  // Zero-Heap Record Tuple Multi-Guard:
  guard: (via) => (via.state(nodeA), via.state(nodeB), via.state(nodeC)).guarded('PrerequisitesIncomplete'),
);
```

### 4.1 Tuple Capabilities across Arities 2 Through 9

Each record tuple extension (`BloomStateRecord2Extension` through `BloomStateRecord9Extension`) exposes four zero-cost primitives:

| Method | Behavior | Return Type |
| :--- | :--- | :--- |
| **`allHaveData()`** | Returns `true` if all tuple members have valid data (`hasData == true`). | `bool` |
| **`guarded([reason])`** | Returns `BloomGuard.pass` if all have data, or `BloomGuard.block(reason)` otherwise. | `BloomGuard` |
| **`hasAnyEmpty()`** | Returns `true` if at least one tuple member is in empty state (`isEmpty == true`). | `bool` |
| **`hasAnyError()`** | Returns `true` if at least one tuple member is in error state (`hasError == true`). | `bool` |

### 4.2 Dart VM Devirtualization & Zero Heap Allocation
```dart
// packages/blooming/lib/src/bloom/state.dart
extension BloomStateRecord3Extension on (BloomState, BloomState, BloomState) {
  @pragma('vm:prefer-inline')
  bool allHaveData() {
    final d1 = $1.hasData, d2 = $2.hasData, d3 = $3.hasData;
    return d1 && d2 && d3;
  }
}
```

- **Stack & Register Allocation**: Dart 3 Records containing references to `BloomState` are unboxed by Dart AOT. Field accesses (`$1`, `$2`, `$3`) map directly to machine registers or stack slots.
- **Pure Monomorphic Field Dereference**: Through `_BloomStateMixin`, reading `.hasData` is a monomorphic read of a single bitflag field.
- **Zero GC Overhead**: No temporary arrays, collections, or dynamic iterators are allocated on the heap during guard evaluations.

---

## 5. Architectural Comparison: Traditional Approaches vs. Bloom Framework

| Metric / Scenario | Traditional Frameworks (Riverpod / MobX / Bloc) | Bloom Framework (`BloomGuard` Architecture) |
| :--- | :--- | :--- |
| **Prerequisite Failure State** | Throws exceptions, returns `null`, or requires custom `AsyncLoading` hacks | Clean, first-class algebraic `Empty(emptyReason)` state via `BloomGuard.block` |
| **Resource Teardown on Invalidation** | Manual imperative calls in controller / bloc logout handlers | **Automatic, deterministic `dispose()` upon `guard.isBlock`** |
| **Tab/Route Navigation Retention** | Immediate termination or complex `keepAlive()` state leaks | Optional `graceful` mooring prevents connection thrashing |
| **Subtree Activation Gating** | Unselected streams still execute in background unless manually unsubscribed | `switched(guard: ...)` keeps unselected subtrees unconditionally dormant |
| **Multi-Entity Guard Evaluation** | Temporary `List` or iterator allocation on heap | **0-Heap Dart 3 Record Tuple Evaluation (`guarded()`)** |
| **Self-Healing Mechanics** | Requires manual re-dispatch or `ref.refresh()` | **Automatic on Push-Dirty: resumes instantaneously when guard passes** |

---

## 6. Production Patterns: BAD vs. GOOD

### Example 1: Gated External Resource Management

#### BAD: Imperative Teardown & Unchecked Creation
```dart
// [Anti-Pattern] Manually checking conditions and risking resource leaks on state changes
class BadChatManager {
  ApiClient? _client;

  void onAuthChanged(String? token) {
    if (token != null) {
      _client = ApiClient(port: 8080);
    } else {
      // If the developer forgets this branch, the client stays open forever!
      _client?.close();
      _client = null;
    }
  }
}
```

#### GOOD: Declarative Auto-Disposing Managed Handle
```dart
// [Recommended] Deterministic lifecycle guaranteed by engine invariants
final token = blooming<String>('token_123').bloom;
final isLoggedIn = blooming<bool>(true).bloom;

final chatSocket = managed<ApiClient>(
  create: (via) => ApiClient(port: 8080),
  dispose: (client) => client.close(),
  guard: (via) => (via(isLoggedIn) && via.state(token).hasData)
      .guarded('UserNotAuthenticated'),
);
```

### Example 2: Granular Domain Preconditions & UI Guidance

```dart
// In Flutter UI:
class CheckoutSubmitButton extends StatelessWidget {
  const CheckoutSubmitButton({super.key, required this.checkout});
  final CheckoutComputation checkout;

  @override
  Widget build(BuildContext context) {
    // Declarative 3-state UI gating:
    return ElevatedButton(
      onPressed: checkout.hasData ? () => submitOrder() : null,
      child: Text(
        checkout.hasData
            ? 'Place Order (\$${checkout.data.subtotal.toStringAsFixed(2)})'
            : (checkout.emptyReason?.toString() ?? 'Prerequisites Pending'),
      ),
    );
  }
}
```

---

## 7. Core Engineering Invariants

1. **Algebraic Convergence Invariant**:
   A blocked guard always deterministically transitions the node to `BloomState.isEmpty` with `decision.reason` preserved. It never throws exceptions or produces synthetic nullable payloads.
2. **Computation Bypassing Invariant**:
   When `guard(via)` returns `isBlock`, core derivation bodies (`compute`, `_computeFuture`, `_computeStream`, `create`, `select`) are strictly bypassed, consuming 0 execution cycles and initiating 0 network or stream tasks.
3. **Deterministic Auto-Disposal Invariant in `managed`**:
   In `managed`, transitioning from `guard.isPass` to `guard.isBlock` synchronously invokes `dispose(currentResource)` and clears the internal resource slot immediately.
4. **Dormancy Subtree Decoupling Invariant in `switched`**:
   In `switched`, when `guard` blocks, the active branch is decoupled and replaced with `Bloom.empty(decision.reason)`, returning candidate subtrees to inactive dormancy.
5. **Zero-Heap Record Devirtualization Invariant**:
   Multi-guard checks via Dart 3 Record tuples (`(stateA, stateB, ...).guarded()`) from arity 2 through 9 execute with exactly 0 heap allocations, compiling into inline register bitwise checks.
6. **Push-Phase Purity Invariant**:
   Guards are strictly evaluated in the Pull phase (lazy pull). The Push phase never executes user guard closures.

---

## 8. Architectural Conclusions

The `BloomGuard` mechanism in the Bloom Framework elevates precondition checking from an arbitrary procedural `if`-statement to an **algebraic fault-barrier embedded within the LPDAG topology**:

1. It guarantees that calculations and asynchronous pipelines never execute with incomplete or corrupted prerequisites.
2. It guarantees that external synchronous resources managed via `managed` are deterministically closed and released the instant their prerequisites collapse.
3. It guarantees that multi-state prerequisite evaluations across Dart 3 Record tuples operate with zero heap allocation and zero GC pressure.
4. It unifies UI state handling by replacing unexpected exceptions with descriptive, self-healing `Empty(emptyReason)` snapshots carrying native diagnostic payloads (`String`, `Enum`, `Record`).

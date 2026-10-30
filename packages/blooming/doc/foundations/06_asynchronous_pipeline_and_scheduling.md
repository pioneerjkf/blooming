# Asynchronous Pipeline and Scheduling Invariants: The Physics of Async Reactivity
## (Asymmetric Scheduling Mechanics, Subscriber-Driven Active-Eager Invariants, Microtask Coalescing, and Zero-Cost Inactive Dormancy)

> **"The physical laws governing synchronous pull and asynchronous push are fundamentally distinct: why asynchronous reactive state must operate with active-eager dispatch while preserving inactive dormancy."**  
> — *Bloom Framework Core Systems Group*

---

## 1. Overview: The Intrinsic Asymmetry Between Synchronous and Asynchronous Computation

In reactive systems, on-demand lazy evaluation is the optimal strategy for purely synchronous derivations. Synchronous nodes ([`computed`](../../lib/src/bloom/computed.dart)) eliminate redundant work by deferring execution until a downstream consumer reads [`untracked(node)`](../../lib/src/bloom/untracked.dart) or calls `via(node)` (On-Demand Lazy-Pull).

However, **attempting to apply identical on-demand lazy semantics to asynchronous queries ([`computed.future`](../../lib/src/bloom/computed.dart), [`computed.stream`](../../lib/src/bloom/computed.dart)) violates the physics of asynchronous event loops**, inducing severe pipeline stalls, transient deadlocks, and event drops.

The Bloom Framework formalizes the mechanics of asynchronous I/O and enforces the **Subscriber-Driven Active-Eager** scheduling invariant for all asynchronous reactive nodes.

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│               Synchronous Pull vs. Asynchronous Active-Eager Physics            │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   [ Synchronous Derivation: computed ]                                          │
│   Consumer Pulls (untracked / via) ──► Evaluates on Call Stack (0ms) ──► Fresh Data │
│                                                                                 │
│   [ Asynchronous Derivation: computed.future / computed.stream ]               │
│   Consumer Pulls (untracked / via) ──► Initiates I/O across Event Loop ──► ???  │
│   (Cannot return future value synchronously; requires Active-Eager pre-dispatch)│
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. The Fundamental Mismatch Between Synchronous Pull and Asynchronous I/O

Synchronous derivations achieve zero-latency pull evaluation because **results are computed within the active call stack synchronously (0ms)**:

$$\text{Consumer reads } \text{untracked}(c) \text{ / } \text{via}(c) \;\longrightarrow\; \text{Evaluate } c \text{ (0ms CPU)} \;\longrightarrow\; \text{Return fresh value } V$$

The moment a consumer pulls, the derivation yields its latest state immediately.

### 2.1 What Happens if Asynchronous Nodes Are Evaluated Lazily?

$$\text{Consumer reads } \text{untracked}(b) \text{ / } \text{via}(b) \;\longrightarrow\; \text{Dispatch } \text{Future} \text{ (I/O Initiated)} \;\longrightarrow\; \mathbf{???}$$

Because asynchronous operations resolve on future ticks of the event loop, **there is no physical mechanism to return the resolved value synchronously at the moment of the pull**:

1. **Two-Step Roundtrip Stall**:
   * *Initial Read*: The node must return an empty or stale snapshot (`isEmpty == true`).
   * *Event Completion*: Only upon completion does the node push a notification downstream to trigger a second read pass or UI rebuild.
2. **Pipeline Deadlocks and Stalls**:
   * If downstream observers ([`Effect`](../../lib/src/effect/effect.dart) or reactive listeners) passively await an asynchronous push before reading, and the upstream node waits for a pull to start I/O, **the asynchronous pipeline enters a deadlock where I/O never initiates**.

---

## 3. Asynchronous Functions (`Future<T> Function()`) vs. Reactive State (`Bloom<T>`)

In asynchronous software engineering, lazy execution applies to **actions and functions**, not **reactive state**:

* **Asynchronous Functions (`Future<T> Function()` closures)**:
  - *A specification of deferred execution invoked explicitly on demand.*
  - Lazy execution is canonical here: until a user taps a button or code executes `await fetch()`, nothing runs.
* **Reactive State ([`Bloom<T>`](../../lib/src/bloom/bloom.dart))**:
  - *A continuous, time-varying representation of point-in-time state.*
  - State must remain **continuously queryable**.
  - If upstream parameters mutate but asynchronous recomputation is deferred, the state node enters an inconsistent limbo where upstream dependencies have changed but the state node reflects stale reality.

### 3.1 Bridging Cold Asynchronous Functions into Subscriber-Driven State (`FutureFactoryBloomExtension` & `StreamFactoryBloomExtension`)

When a standalone cold asynchronous function (`Future<T> Function()` or `Stream<T> Function()`) has no upstream reactive dependencies (`via`) yet must be exposed as a subscriber-driven [`Bloom<T>`](../../lib/src/bloom/bloom.dart), [`FutureFactoryBloomExtension`](../../lib/src/bloom/async.dart) and [`StreamFactoryBloomExtension`](../../lib/src/bloom/async.dart) bridge the gap directly:

```dart
Future<String> fetchServerStatus() async => 'OK';
Stream<int> watchHeartbeat() async* {
  yield 1;
}

// 1. Cold Future factory -> Subscriber-driven Bloom (0 -> 1 invokes factory, 1 -> 0 resets bulkhead)
final (:data, :pending) = fetchServerStatus.toBloomTuple(
  graceful: Graceful.microtask,
);

// 2. Cold single-subscription Stream factory -> Reconnectable Bloom triad across 1 -> 0 -> 1 cycles
final (data: heartbeat, pending: isStarting, done: isFinished) =
    watchHeartbeat.toBloomTriple(
  initialFactory: () => 0,
);
```

* **Solving Hot `Future` Eager Execution**: Calling `fetchServerStatus().toBloom()` dispatches the HTTP request immediately at declaration time, even if no UI consumer ever mounts. Calling `fetchServerStatus.toBloom()` (or `(() => fetchServerStatus()).toBloom()`) keeps the function cold until the first subscriber activates the node (`0 -> 1`), and re-invokes it on every subsequent reactivation (`1 -> 0 -> 1`).
* **Solving Single-Subscription `Stream` `StateError` on Remount**: Calling `watchHeartbeat().toBloom()` binds to a single `async*` generator instance; once the consumer unmounts (`1 -> 0`) and cancels the subscription, remounting (`0 -> 1`) throws `Bad state: Stream has already been listened to`. Calling `watchHeartbeat.toBloom()` invokes the generator function anew on every `0 -> 1` transition.
* **Bulkhead Isolation on Deactivation (`1 -> 0`)**: Upon deactivation, the factory bridge immediately swaps its internal coupled nodes to fresh initial `Bloom` instances (`Empty` or `initialFactory`), ensuring late-settling futures from a canceled observation session never leak into future sessions. Pair with `.retained()` or `.retainedTuple()` when Stale-While-Revalidate (SWR) retention across remounts is desired.

---

## 4. Event Dropping and Zombie Leaks in Real-Time Streams

For real-time broadcast streams ([`computed.stream`](../../lib/src/bloom/computed.dart)), on-demand lazy subscription induces critical anomalies:

* **Event Dropping**:  
  If an upstream parameter (e.g., `roomId`) changes from A to B, deferring subscription until a consumer reads causes real-time broadcast packets emitted during that interval to drop permanently.
* **Zombie Subscriptions**:  
  The previous connection to room A is not canceled immediately, generating memory leaks, wasted bandwidth, and unnecessary server load.

---

## 5. The Core Invariant: Active-Eager Scheduling Coexisting with Inactive Dormancy

Does active-eager scheduling cause unconstrained background network requests when unobserved?

**No.** In the Bloom Framework, active-eager scheduling is strictly conditioned on **subscriber presence**:

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│             Subscriber-Conditioned Active-Eager vs. Dormancy Pipeline           │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│                     [No Active Subscribers: isActive == false]                  │
│                                           │                                     │
│                              (Zero-Cost Inactive Dormancy)                      │
│                              • Zero I/O requests dispatched                     │
│                              • Zero open socket connections                     │
│                                           │                                     │
│                                           ▼ Subscriber Attached (_activate)     │
│                     [Active Subscribers Present: isActive == true]              │
│                                           │                                     │
│                              (Active-Eager Microtask Scheduling)                │
│                              • Upstream mutations queue in _Scheduler._eagerSet │
│                              • Dispatches I/O concurrently during microtask     │
│                                           │                                     │
│                                           ▼ All Subscribers Detached            │
│                              (Instant Teardown or Mooring Grace)                │
│                              • Subscriptions severed; async I/O teardown runs   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 5.1 Architecture of `_EagerDeltaBloom`

All asynchronous computed nodes ([`_FutureComputedBloom`](../../lib/src/bloom/_internal/_computed.dart), [`_StreamComputedBloom`](../../lib/src/bloom/_internal/_computed.dart), [`_EagerSwitchedBloom`](../../lib/src/bloom/_internal/_switched.dart)) inherit from [`_EagerDeltaBloom<T>`](../../lib/src/bloom/_internal/_delta.dart), implementing [`_EagerSchedulable`](../../lib/src/engine/_internal/_scheduler.dart).

The node encapsulates its active-eager behavior through four concise lifecycle hooks:

```dart
// packages/blooming/lib/src/bloom/_internal/_delta.dart
void _activate() => _needsSwitch ? _performSwitchGuarded(false) : null;
void _deactivate() => _Scheduler.instance._cancelEager(this);
void _onDeltaDirty() => _lifecycle.isActive ? _Scheduler.instance._scheduleEager(this) : null;
void _performScheduledEager() => _performSwitchGuarded(true);
```

### 5.2 Four Lifecycle Transition Invariants

1. **Unsubscribed Cold Dormancy (`!_lifecycle.isActive`)**:  
   Upstream parameter mutations trigger **zero network requests**. If upstream dependencies change while dormant, `_needsSwitch = true` is recorded, but no microtask is scheduled (`_lifecycle.isActive` check short-circuits).
2. **Initial Activation Handshake (`_activate`)**:  
   The instant the first downstream subscriber attaches, `_activate()` checks `_needsSwitch || _deltaTerminal._isSourceDirty`. If dirty, it immediately executes `_performSwitchGuarded(false)` **synchronously**, establishing the fresh [`_StreamBloomBridge`](../../lib/src/bloom/_internal/_async.dart) or [`_FutureBloomBridge`](../../lib/src/bloom/_internal/_async.dart) with zero roundtrip delay.
3. **Active Mutation Microtask Queuing (`_onDeltaDirty`)**:  
   While active, any upstream dependency mutation triggers `_onDeltaDirty()`. It flags `_needsSwitch = true`, invalidates downstream dependents via `_invalidate()`, and enqueues itself into [`_Scheduler.instance._scheduleEager(this)`](../../lib/src/engine/_internal/_scheduler.dart).
4. **Deactivation & Instant Subscription Teardown (`_deactivate`)**:  
   When all subscribers detach, `_Scheduler.instance._cancelEager(this)` cancels any pending microtask in $O(1)$. Active stream subscriptions are severed synchronously via `_unsubscribe()` ([`_subscription?.cancel()`](../../lib/src/bloom/_internal/_async.dart)), immediately halting event delivery while underlying socket and resource cleanup concludes asynchronously via the returned `Future`.

---

## 6. Microtask Coalescing and Double-Buffered Execution

To prevent request flooding when multiple upstream parameters mutate in the same synchronous turn:

```dart
Future<List<String>> fetchUsers(String u, String f, int p) async => ['$u:$f:$p'];

final userId = blooming('user_0');
final filter = blooming('all');
final page = blooming(1);

final userList = computed.future((via) async {
  final u = via(userId.bloom);
  final f = via(filter.bloom);
  final p = via(page.bloom);
  return fetchUsers(u, f, p);
});

// Rapid consecutive mutations in a single synchronous turn:
userId.set('user_1');
filter.set('active');
page.set(2);
```

The Bloom asynchronous engine ([`_Scheduler`](../../lib/src/engine/_internal/_scheduler.dart) and [`_EagerDeltaBloom`](../../lib/src/bloom/_internal/_delta.dart)) coalesces intermediate pulses via **Microtask Coalescing**:

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│               Microtask Coalescing & Double-Buffered Execution                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│   [Synchronous Turn: Mutation 1] ──► _scheduleEager(this) ──► Added to _eagerSet│
│   [Synchronous Turn: Mutation 2] ──► _scheduleEager(this) ──► Deduplicated O(1) │
│   [Synchronous Turn: Mutation 3] ──► _scheduleEager(this) ──► Deduplicated O(1) │
│                                                │                                │
│                        (Synchronous call stack finishes)                        │
│                                                ▼                                │
│                   [Dart Microtask Turn: scheduleMicrotask runs]                 │
│                                                │                                │
│                   _eagerSet <── (O(1) Pointer Swap) ──> _eagerSwapSet           │
│                                                │                                │
│                                                ▼                                │
│                 Exactly 1 I/O Request Dispatched! (_performScheduledEager)      │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

* **Network Flood Elimination**:  
  Even if 1,000 parameter updates occur in one synchronous turn, `_Scheduler._scheduleEager()` performs $O(1)$ set deduplication so **exactly one asynchronous dispatch task is queued**.
* **Zero-Allocation Double-Buffered Swap**:  
  During the microtask execution pass, `_eagerSet` is swapped with `_eagerSwapSet` in $O(1)$ pointer assignment:
  ```dart
  // packages/blooming/lib/src/engine/_internal/_scheduler.dart
  final processing = _eagerSet;
  _eagerSet = _eagerSwapSet;
  _eagerSwapSet = processing;
  ```
  This guarantees that re-entrant schedule calls during processing never corrupt the active iteration loop.
* **Final State Consistency**:  
  When the microtask executes (`_performScheduledEager`), it evaluates against the final, settled values of all upstream parameters, absorbing transient intermediate states in $O(1)$ time.

---

## 7. Central Scheduler Mixin Linearization Order

The central [`_Scheduler`](../../lib/src/engine/_internal/_scheduler.dart) coordinates batch execution passes using a strict mixin linearization order to ensure topological soundness across the entire reactive graph:

```dart
// packages/blooming/lib/src/engine/_internal/_scheduler.dart
base class _Scheduler extends _SchedulerBase
    with _CoalescedSchedulerMixin, _EagerSchedulerMixin, _TerminalSchedulerMixin, _GracefulSchedulerMixin {
  _Scheduler._();
  static final _Scheduler instance = _Scheduler._();
}
```

```text
               ┌────────────────────────────────────────────────────────┐
               │              Dart Microtask Loop Tick                  │
               └──────────────────────────┬─────────────────────────────┘
                                          │
                                          ▼
   Phase 1: [_SchedulerBase]       Resets scheduling flag (_isScheduled = false)
                                          │
                                          ▼
   Phase 2: [_CoalescedScheduler]  Flushes trailing coalesced pulses in the DAG
                                          │
                                          ▼
   Phase 3: [_EagerScheduler]      Pre-emptively switches and allocates eager nodes
                                          │
                                          ▼
   Phase 4: [_TerminalScheduler]   Flushes active scheduled terminals / effects
                                          │
                                          ▼
   Phase 5: [_GracefulScheduler]   Executes deactivation cleanups LAST
```

### 7.1 Why Graceful Deactivation Runs Last

Active terminals and effects running in Phase 4 may still observe or depend on resources whose subscribers dropped to zero earlier in the same tick.

Executing deactivations last in Phase 5 ensures that:
1. All resources remain fully valid throughout effect evaluations.
2. Graceful deactivations ([`_GracefulSchedulerMixin`](../../lib/src/engine/_internal/_scheduler.dart)) only execute after all scheduled side-effects have concluded.
3. Rapid unmount-remount transitions within the same microtask tick (e.g. Flutter tab switching) are resolved seamlessly without tearing down and reconstructing underlying connections.

---

## 8. Architectural Summary & Invariants

| Characteristic | Synchronous Computation (`computed`) | Asynchronous Pipeline (`computed.future`, `computed.stream`) |
| :--- | :--- | :--- |
| **Scheduling Model** | **Lazy-Pull** (On-Demand Evaluation) | **Active-Eager** (Preemptive Microtask Dispatch) |
| **Execution Trigger**| Consumer reads `untracked(node)` or `via(node)` | Upstream parameter mutation queues microtask |
| **Batching Strategy**| Evaluates once on consumer pull | **Microtask Coalescing (`_Scheduler._scheduleEager`)** |
| **Inactive State** | Dormant (No evaluations) | **Completely Dormant (Zero I/O, Zero Sockets)** |
| **Microtask Priority**| Immediate Call Stack | **Phase 3 (Pre-empts Terminals & Effects)** |
| **Memory Reclamation**| Immediate | **Synchronous on `_deactivate()` or Graceful Window** |

### Core Engineering Invariants

| # | Invariant Name | Mathematical / Topological Rule | Verification Mechanism |
| :---: | :--- | :--- | :--- |
| **I** | **Subscriber-Conditioned Eager Scheduling** | Node $N$ schedules eager microtask $\iff N.\text{isActive} == \text{true}$. | Verified by `_lifecycle.isActive` check in `_onDeltaDirty()`. |
| **II** | **Zero-Cost Cold Dormancy** | $N.\text{isActive} == \text{false} \implies \text{IORequests}(N) = 0$. Parameter changes while dormant emit 0 network calls. | Proved by mock I/O count assertions during dormant state. |
| **III** | **Immediate Synchronous Activation** | Transition $0 \to 1$ synchronously evaluates `_performSwitchGuarded(false)`, eliminating initial frame roundtrip latency. | Verified by synchronous assertion on `untracked.state` immediately after mooring. |
| **IV** | **Microtask Deduplication** | $M$ mutations in turn $T \implies \text{dispatches} = 1$. Intermediate pulses coalesce into single settled request. | Enforced by `_eagerSet.add()` set deduplication. |
| **V** | **Zero-Allocation Double-Buffered Swap** | Iteration sets swap via $O(1)$ pointer assignment, preventing re-entrant corruption. | Proved by `_eagerSet = _eagerSwapSet` implementation. |
| **VI** | **Linearized Phase Order** | $\text{Coalesced} \prec \text{Eager} \prec \text{Terminal} \prec \text{Graceful}$. Deactivation executes strictly after all effects settle. | Enforced by Dart mixin linearization order on `_Scheduler`. |

# Two-Tier Temporal Architecture: State-Domain Smoothing vs. Effect-Domain Rate Limiting Specification
## (Temporal Dirty Gatekeeping, Microtask Coalescing, Asynchronous Silence Buffering, Upstream Priming, and Isolated Terminal Sinks)

> **"Manipulating the time domain is the most dangerous intruder into reactive synchronous consistency. Treating state stream smoothing and side-effect dispatch delays within a single unified category inevitably casts the reactive graph into topological limbo."**  
> — *Bloom Framework Core Systems Group*

---

## 1. Overview and Background: The Collision of Temporal Operators and Synchronous LPDAGs

In reactive systems, debounce, throttle, and coalesce operators are essential for managing high-frequency user and sensor inputs (search typing, slider drags, sensor streams, window resizes). However, naively porting traditional Rx or event stream approaches directly into a synchronous **LPDAG (Lazy Push-Dirty, Pull-Evaluation Directed Acyclic Graph)** induces severe topological failures.

The Bloom Framework's 2-Phase LPDAG strictly adheres to the **Push-Dirty (proportional to the affected subgraph) + Lazy-Pull (On-Demand)** model. Attempting to delay invalidation (dirty) pulses arbitrarily inside dynamic downstream terminals causes three critical anomalies:

1. **The Initial Evaluation Dilemma**: Dynamic dependency scopes (`BloomVia`) must establish tracking edges synchronously upon mounting. If a terminal delays its initial execution, edges remain unformed (0 edges), dropping upstream mutations occurring during the delay. Conversely, if the terminal runs immediately on mount, side-effects (e.g., network queries) fire with uninitialized, empty payloads.
2. **Cache Limbo & Read-Uncommitted Anomalies**: If an upstream node mutates to a fresh version while an observing terminal holds an asynchronous timer, allowing uncommitted reads leaks intermediate, transient state to sibling UI widgets, causing split-brain presentation glitches.
3. **Engine Scheduler Pollution**: Mixing asynchronous platform `Timer` callbacks arbitrarily into the synchronous microtask batch scheduler (`_Scheduler`) breaks deterministic topological evaluation order and transactional atomicity.

To resolve these defects at the architectural level, Blooming separates time-domain operations into two strictly decoupled tiers: the **State Domain** (Tier 1) and the **Effect Domain** (Tier 2).

---

## 2. The Two-Tier Temporal Architecture

```text
┌────────────────────────────────────────────────────────────────────────┐
│               Two-Tier Temporal Architecture in Bloom                   │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   [ Tier 1: State Domain ]                                             │
│   • Target: Reactive State Pipelines (Bloom<T>)                         │
│   • Primitives: bloom.debounced, bloom.throttled, bloom.coalesced         │
│   • Core Class: _GatedRelayBloom<T> (Temporal Dirty Gatekeeper)         │
│   • Mechanism: Push-Dirty pulse attenuation at relay node level        │
│   • Invariant: Read-Committed Cache SSOT, Zero intermediate leak       │
│                                                                        │
│   [ Tier 2: Effect Domain ]                                            │
│   • Target: Terminal Execution Sinks (Side-Effects)                    │
│   • Primitives: Effect.debounce, Effect.throttle, target.effect.*       │
│   • Core Class: _DebounceEffectTerminal, _ThrottleEffectTerminal       │
│   • Mechanism: Upstream Priming (0 runs on mount), Timer scheduling    │
│   • Invariant: Zero state production, Early Teardown, Clean disposal   │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Tier 1: State Domain Temporal Operators (`bloom.debounced`, `bloom.throttled`, `bloom.coalesced`)

In the State Domain, temporal damping occurs not at terminal endpoints, but **at intermediate LPDAG relay nodes**, attenuating downstream Push-Dirty pulses before they reach consumers:

| Relay Operator | Damping Mechanism | Scheduler Foundation | Canonical Use Cases |
| :--- | :--- | :--- | :--- |
| **`bloom.debounced(duration)`** | Holds dirty pulse until silence period expires | Asynchronous `Timer` | Search auto-complete, window resize |
| **`bloom.throttled(duration)`** | Emits at most one dirty pulse per duration window | Asynchronous `Timer` | Scroll offset, sensor streams |
| **`bloom.coalesced()`** | Compresses multi-mutations in a single turn | **1-Tick Microtask** | Batch cascades, frame stabilization |

```text
[Upstream Source] ──(Push-Dirty: A -> B -> C)──► [_GatedRelayBloom Relay Node]
                                                          │ (Gate Closed: Holds dirty pulse)
                                                          │ (Intermediate reads return cached 'A')
                                                          ▼ (After silence / window close)
                                                 [_emitTrailing() Unlocks Gate]
                                                          │
                                                          ▼ (Push-Dirty Pulse Released)
                                             [Downstream Terminals / Consumers]
                                             (Lazy-Pull: Pulls latest state 'C' & bumps version!)
```

### 3.1 The Temporal Dirty Gatekeeper (`_GatedRelayBloom<T>`)

All state-domain temporal and batching relays inherit from [`_GatedRelayBloom<T>`](../../lib/src/bloom/_internal/_bloom.dart):

```dart
// packages/blooming/lib/src/bloom/_internal/_bloom.dart
abstract base class _GatedRelayBloom<T> extends _StaticUnaryRelay<Bloom<T>>
    with _BloomStateMixin<T>, _PullResolver<T>, _PullRelay<T>, _PushOriginMixin
    implements Bloom<T> {
  _GatedRelayBloom(
    super.source, {
    required this.leading,
    required this.trailing,
  }) {
    if (!leading && !trailing) {
      throw ArgumentError('At least one of leading or trailing must be true.');
    }
  }

  final bool leading;
  final bool trailing;
  bool _hasTrailingPending = false;

  @override
  @pragma('vm:prefer-inline')
  _BloomState<T> _pull() {
    final next = _source._read();
    if (_source._version != _pulledVersion) {
      _version++;
    }
    return _state = next;
  }

  @pragma('vm:prefer-inline')
  void _emitTrailing() {
    _hasTrailingPending = false;
    _dirtyState = _DirtyState.dirty;
    _PushScope.queueOrigin(this);
  }
}
```

#### The 3-Phase Gatekeeping Lifecycle & Cache Invariant
1. **Upstream Invalidation & Suppression (Ticking Window)**:  
   When the upstream `_source` mutates, `_invalidate()` intercepts the event. Instead of marking itself dirty or propagating flags downstream, it starts or resets a timer (or microtask). During this window, `_dirtyState` remains `_DirtyState.clean`.
2. **Cache Integrity (Read Committed)**:  
   If any downstream node or external caller reads `untracked(node)`, `untracked.state(node)`, `via(node)`, or `via.state(node)` during this delay window, `_PullResolver._resolve` sees `_dirtyState == _DirtyState.clean`, **completely bypasses `_pull()`**, and immediately returns the previously committed cached `_state`.  
   *Guarantee*: Downstream computations (e.g. SWR, search API calls) are never contaminated by uncommitted intermediate mutations.
3. **Gate Unlocking & Push Propagation (`_emitTrailing`)**:  
   When the timer or microtask elapses, `_emitTrailing()` transitions `_dirtyState` to `_DirtyState.dirty` and enqueues this node into `_PushScope.queueOrigin(this)`. Only then are downstream observers marked dirty and notified to pull the fresh upstream state via `_pull()` (which increments `_version++` when `_source._version != _pulledVersion`).

### 3.2 Microtask Burst Coalescing (`_CoalescedBloom<T>`)

```dart
// packages/blooming/lib/src/bloom/_internal/_bloom.dart
final class _CoalescedBloom<T> extends _GatedRelayBloom<T> implements _CoalescedSchedulable {
  _CoalescedBloom(
    super.source, {
    super.leading = false,
    super.trailing = true,
  });

  bool _isCoalesceScheduled = false;
  bool _isLeadingCooldown = false;

  @override
  @pragma('vm:prefer-inline')
  void _invalidate() {
    if (!_lifecycle.isActive) return;

    if (leading && !_isLeadingCooldown) {
      _isLeadingCooldown = true;
      if (!_isCoalesceScheduled) {
        _isCoalesceScheduled = true;
        _Scheduler.instance._scheduleCoalesced(this);
      }
      super._invalidate();
      return;
    }

    if (trailing) {
      _hasTrailingPending = true;
    }

    if (!_isCoalesceScheduled) {
      _isCoalesceScheduled = true;
      _Scheduler.instance._scheduleCoalesced(this);
    }
  }

  @override
  void _performCoalesce() {
    _isCoalesceScheduled = false;
    _isLeadingCooldown = false;
    if (!_lifecycle.isActive) return;

    if (_hasTrailingPending && trailing) {
      _emitTrailing();
    }
  }
}
```
* **Zero Platform Timer Overhead**: Uses Dart's microtask queue via `_Scheduler.instance._scheduleCoalesced(this)`.
* **Burst Compression**: 100 consecutive synchronous state changes within the same event loop turn collapse into exactly 1 trailing dirty notification before the rendering frame begins.

### 3.3 Debouncing & Throttling Relays (`_DebouncedBloom<T>`, `_ThrottledBloom<T>`)

```dart
// packages/blooming/lib/src/bloom/_internal/_bloom.dart
final class _DebouncedBloom<T> extends _TemporalRelayBloom<T> {
  _DebouncedBloom(
    super.source,
    super.duration, {
    super.leading = false,
    super.trailing = true,
  });
  ...
  @override
  void _invalidate() {
    if (!_lifecycle.isActive) return;

    if (leading && !_isLeadingCooldown) {
      _isLeadingCooldown = true;
      _cancelTimer();
      _timer = Timer(duration, _onTimerExpired);
      super._invalidate();
      return;
    }

    if (trailing) _hasTrailingPending = true;
    _cancelTimer();
    _timer = Timer(duration, _onTimerExpired);
  }
}
```
* **Configurable Edges**: Supports `leading` (immediate fire on initial mutation) and `trailing` (fire after silence window).
* **Argument Validation**: Throws `ArgumentError` (`if (!leading && !trailing)`) at construction time in all build modes to prevent no-op zombie relays.
* **Inactive Dormancy & Raw Reads**: When unobserved (`!_lifecycle.isActive`), reading `untracked(node)` or `untracked.state(node)` bypasses temporal timers and synchronously resolves the latest upstream state on demand. Deactivation cancels active timers synchronously.

---

## 4. Tier 2: Effect Domain Temporal Sinks (`Effect.debounce`, `Effect.throttle`)

The Effect Domain governs **terminal execution sinks** (analytics logging, audio/haptic feedback, disk storage, network dispatches) that produce zero reactive state and consume only side-effects:

```text
[Explicit Bloom Target] ──(Invalidation Pulse)──► [Effect.debounce / Effect.throttle]
                                                          │
                                                          ├── [Leading Edge: Schedules in microtask]
                                                          ├── [Cooldown: Manages isolated Timer]
                                                          ├── [Trailing Edge: Schedules on expiry]
                                                          └── [Executes untracked action() sink]
```

### 4.1 Upstream Priming Invariant (Zero Runs on Mount)

To resolve the Initial Evaluation Dilemma, all manifest effect terminals mix in [`_UnaryEffectPrimeMixin`](../../lib/src/effect/_internal/_base.dart) or [`_NaryEffectPrimeMixin`](../../lib/src/effect/_internal/_base.dart):

```dart
// packages/blooming/lib/src/effect/_internal/_base.dart
base mixin _UnaryEffectPrimeMixin on _Terminal, _UnaryEdgeMixin<Bloom> {
  @mustCallSuper
  @override
  void _activate() {
    super._activate();
    _source._resolve();
    _pullVersion();
  }
}
```

* **Synchronous Edge Synchronization**: Upon activation (`_activate()`), the terminal resolves its target and synchronizes `_pulledVersion = _source._version`.
* **Zero Runs on Mount**: The action callback executes **0 times** upon construction or mounting. It fires strictly when *subsequent* mutations arrive from upstream targets.

### 4.2 Debounce & Throttle Terminal Engines

```dart
// packages/blooming/lib/src/effect/_internal/_base.dart
abstract base class _DebounceEffectTerminal extends _ManifestEffectTerminal {
  ...
  @override
  @pragma('vm:prefer-inline')
  void _invalidate() {
    if (!_lifecycle.isActive) return;
    if (_takeLimit != null && _remaining <= 0) return;

    if (leading && !_isLeadingCooldown) {
      _Scheduler.instance._scheduleTerminal(this);
      _isLeadingCooldown = true;
    } else if (trailing) {
      _hasTrailingPending = true;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, _onDebounceTimerExpired);
  }

  void _onDebounceTimerExpired() {
    _debounceTimer = null;
    _isLeadingCooldown = false;
    if (!_lifecycle.isActive) return;
    if (_takeLimit != null && _remaining <= 0) return;

    if (_hasTrailingPending && trailing) {
      _hasTrailingPending = false;
      _isTrailingExecution = true;
      _Scheduler.instance._scheduleTerminal(this);
    }
  }
}
```

* **Microtask Invalidation Batching**: When edges fire (leading or trailing), the terminal schedules execution via `_Scheduler.instance._scheduleTerminal(this)`, preserving microtask batch consistency.
* **Finite Execution Guard (`take`)**: Once `_remaining <= 0`, incoming pulses are discarded and the terminal executes `deactivate()` immediately (Early Teardown).
* **Guarded Execution (`guard`)**: If `guard?.call() == false`, action execution is skipped and `take` tickets are preserved.

### 4.3 Fluent Scoped DSL (`UnaryBloomEffectScope`, `BloomEffectScope`)

Using compile-time zero-cost extension types ([extensions.dart](../../lib/src/effect/extensions.dart)), developers define debounce and throttle effects directly on `Bloom` instances:

```dart
final searchInput = blooming('');

// Fluent unary debounce effect:
final searchEffect = searchInput.bloom.effect.debounce(
  const Duration(milliseconds: 300),
  () => performSearch(untracked(searchInput.bloom)),
);

// Standalone execution outside widget lifecycles:
final runner = searchEffect.start();
runner.stop(); // Cancels internal timer and detaches edge
```

---

## 5. Structural Contradictions in Dynamic Terminal Debouncing

Why introducing debounce directly inside dynamic tracking scopes (`BloomVia`) is mathematically contradictory:

```dart
// [Anti-Pattern] Structural contradiction when placing debounce inside dynamic tracking
Effect.via((via) {
  // If a 300ms debounce were applied directly to this dynamic scope:
  // Should this block run immediately to register via() edges, or wait 300ms?
});
```

1. **If Execution Is Delayed**:
   - For 300ms post-mount, the block never executes.
   - `via(...)` is uncalled; the LPDAG engine has zero knowledge of which dependency edges to establish.
   - Any upstream state mutations occurring during that 300ms window are dropped silently.
2. **If Executed Immediately, Then Delayed Thereafter**:
   - Opening a search screen immediately fires a network query with an empty string `""`.
   - Conditional branches (ternary expressions) re-evaluating on asynchronous timer ticks destabilize topological graph invariants and cause race conditions.

**Definitive Engineering Principle:**
* **"What to Observe" (Topological Edge Tracking)**: Must be determined **synchronously**.
* **"When to Notify" (Notification Timing)**: Must be damped within **intermediate state relay nodes** (`bloom.debounced`) or **explicit manifest effect sinks** (`Effect.debounce`).

---

## 6. Core Engineering Invariants

1. **State-Effect Orthogonality**:
   - State-domain nodes always cache valid algebraic state (`_BloomState<T>`) and support on-demand Lazy-Pull.
   - Effect-domain sinks never produce state, cannot be observed via `via(effect)`, and cannot serve as upstream sources in the LPDAG.
2. **Read-Committed Dirty Gatekeeping**:
   - During active debounce/throttle cooldown periods, `_GatedRelayBloom<T>` keeps `_dirtyState == _DirtyState.clean`. Reads return the previous committed snapshot without evaluating intermediate mutations.
3. **Upstream Priming & Zero Mount Runs**:
   - Manifest effect terminals prime upstream sources on mount without executing action callbacks, eliminating initial empty-state side-effect dispatches.
4. **Zero-Leak Inactive Cold Dormancy**:
   - When downstream subscribers drop to zero, `_deactivate()` synchronously cancels active `Timer`s (`_timer?.cancel()`) or pending microtasks (`_Scheduler.instance._cancelCoalesced(this)`), guaranteeing zero memory or timer leaks.
5. **Finite Execution Safety**:
   - Effects configured with `take(n)` sever upstream edges immediately upon consuming their quota, ensuring permanent inactive dormancy.

---

## 7. Production Patterns

### 7.1 Search Autocomplete Pipeline (Debounced Query + SWR Retained)

```dart
import 'package:blooming/blooming.dart';

// 1. Source producer (Raw user keystroke input)
final searchQuery = blooming<String>('');

// 2. State-domain debounce (Intermediate LPDAG relay node)
//    Suppresses Push-Dirty pulses for 300ms to eliminate redundant network queries
final debouncedQuery = searchQuery.bloom.debounced(
  const Duration(milliseconds: 300),
);

// 3. Asynchronous query pipeline with SWR retained buffering
final searchResults = computed.future((via) async {
  final query = via(debouncedQuery);
  if (query.trim().isEmpty) return <String>[];
  return performSearch(query);
}).retained();
```

### 7.2 Sensor & Scroll Offset Rate-Limiting (Throttled Stream)

```dart
const maxScrollExtent = 1000.0;
final scrollPosition = blooming<double>(0.0);

// Throttles scroll position updates to at most once every 50ms:
final throttledScroll = scrollPosition.bloom.throttled(
  const Duration(milliseconds: 50),
  leading: true,
  trailing: true,
);

final scrollProgress = computed((via) => via(throttledScroll) / maxScrollExtent);
```

### 7.3 Synchronous Burst Mutation Coalescing

```dart
final transactionLog = blooming<int>(0, distinct: false);

// Collapses 100 consecutive synchronous increments into 1 trailing notification:
final coalescedLog = transactionLog.bloom.coalesced();

final renderTerminal = RawBloomTerminal(coalescedLog, onInvalidated: () {
  print('Render frame with latest balance: ${untracked(coalescedLog)}');
})..activate();
```

### 7.4 Analytics Click Tracking (Standalone Throttle Effect)

```dart
import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';

final buttonClickCount = blooming<int>(0);

// Pure side-effect: Dispatches analytics at most once per second on leading edge
final clickTracker = buttonClickCount.bloom.effect.throttle(
  const Duration(seconds: 1),
  () => print('button_tap: ${untracked(buttonClickCount.bloom)}'),
  leading: true,
  trailing: false,
).start();

// Clean up when service or controller is disposed:
void dispose() => clickTracker.stop();
```

---

## 8. Implementation & Verification Matrix

| Architectural Guarantee | Behavioral Specification | Engine Implementation Anchor | Test Suite Verification |
| :--- | :--- | :--- | :--- |
| **Read-Committed Cache Invariant** | Relay keeps `_dirtyState == clean` during delay window; `.data` reads return cached state. | [`_GatedRelayBloom`](../../lib/src/bloom/_internal/_bloom.dart) | [`temporal_pipeline_test.dart` (1.1)](../../test/unit/engine/temporal_pipeline_test.dart) |
| **Microtask Burst Coalescing** | Compresses synchronous bursts within the same turn into 1 trailing microtask notification. | [`_CoalescedBloom`](../../lib/src/bloom/_internal/_bloom.dart), [`_Scheduler`](../../lib/src/engine/_internal/_scheduler.dart) | [`coalesced_test.dart` (test 1)](../../test/unit/bloom/coalesced_test.dart) |
| **Silence Period Debouncing** | Resets timer upon successive mutations; dispatches trailing pulse after duration silence. | [`_DebouncedBloom`](../../lib/src/bloom/_internal/_bloom.dart) | [`temporal_pipeline_test.dart` (1.1, 1.2)](../../test/unit/engine/temporal_pipeline_test.dart) |
| **Interval Rate-Limiting Throttle** | Limits downstream notifications to at most one pulse per time interval window. | [`_ThrottledBloom`](../../lib/src/bloom/_internal/_bloom.dart) | [`temporal_pipeline_test.dart` (3.1, 3.2)](../../test/unit/engine/temporal_pipeline_test.dart) |
| **Upstream Priming (0 Mount Runs)** | Manifest effects prime upstream versions on activation; 0 action callbacks on mount. | [`_UnaryEffectPrimeMixin`](../../lib/src/effect/_internal/_base.dart) | [`debounce_test.dart` (test 1)](../../test/unit/effect/debounce_test.dart) |
| **Zero-Leak Inactive Dormancy** | Deactivation cancels running `Timer`s and microtask schedules synchronously. | [`_TemporalRelayBloom._deactivate`](../../lib/src/bloom/_internal/_bloom.dart) | [`temporal_pipeline_test.dart` (4.1)](../../test/unit/engine/temporal_pipeline_test.dart) |
| **Finite Execution Early Teardown** | Effects with `take` limit sever edges immediately upon exhausting execution quota. | [`_ManifestEffectTerminal`](../../lib/src/effect/_internal/_base.dart) | [`debounce_test.dart` (test 3)](../../test/unit/effect/debounce_test.dart) |
| **Fluent Extension Zero-Cost DSL** | Monomorphic `UnaryBloomEffectScope` compiles to direct terminal dispatch without allocations. | [`UnaryBloomEffectScope`](../../lib/src/effect/extensions.dart) | [`tether_temporal_test.dart`](../../test/unit/bloom/tether_temporal_test.dart) |

---

## 9. Engineering Conclusions

The **Two-Tier Temporal Architecture** resolves the long-standing tension between asynchronous rate-limiting and synchronous reactive consistency:

1. **State Domain Immunity**: By embedding pulse attenuation into intermediate relay nodes (`_GatedRelayBloom<T>`), state pipelines preserve the single-source-of-truth cache invariant and guarantee that uncommitted mutations never contaminate downstream computations.
2. **Effect Domain Clarity**: Terminal sinks (`Effect.debounce`, `Effect.throttle`) operate strictly on explicit targets with upstream priming, completely resolving the Initial Evaluation Dilemma and isolating side-effects cleanly from the reactive data graph.
3. **Unified Performance Excellence**: Microtask coalescing (`bloom.coalesced()`) and timer damping operate with zero heap overhead and zero GC pressure, upholding the Bloom Framework's foundational LPDAG guarantees.

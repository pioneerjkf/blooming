# Imperative Signals & Transient Events Specification
## (Imperative Signals & Transient Events)

> **"State represents persistence; Events represent transition. Forcing transient, one-off events (like a Toast notification or a Navigation pop) into persistent state graphs creates zombie payloads. True reactivity must cleanly decouple the permanent from the transient."**  
> — *Bloom Framework Core Systems Group*

---

## 1. Overview and Background: The State vs. Event Dichotomy

In modern reactive architectures (such as Flutter and Dart), a prevalent anti-pattern is treating one-off imperative events as persistent domain state. For example, to display a transient error Snackbar, developers often declare a `blooming<String?>(null)` and assign `"Network Connection Lost"`.

This creates three critical architectural defects:

1. **Zombie Payloads**: The `"Network Connection Lost"` string lingers inside the reactive node's cache indefinitely unless explicitly cleared via an imperative `set(null)`.
2. **Re-triggering on Remount (The Zombie Dialog Bug)**: If a widget unmounts and remounts (e.g. during tab switching, list recycling, or route pop/push), the reactive subscriber re-evaluates upon mounting. Because the cached payload is still `"Network Connection Lost"`, the Snackbar or Dialog fires a second time unexpectedly, causing severe UX glitches.
3. **Manual Nullification Boilerplate & Race Hazards**: Developers are forced to author defensive `onDismissed` or `onComplete` callbacks purely to nullify state (`set(null)`). If a second event occurs before nullification completes, the second event can be lost or overwritten by race conditions.

The Bloom Framework resolves this fundamental dichotomy by introducing **`BloomSignal`** and **`BloomSignalController`** ([BloomSignal](../../lib/src/bloom/signal.dart), [BloomSignalController](../../lib/src/bloom/signal.dart))—specialized primitives dedicated strictly to discrete, stateless event pulses.

---

## 2. BloomSignal Architecture & Monotonic Tick Mechanics

`BloomSignal` and its producer, `BloomSignalController`, implement the identical topological LPDAG tracking as standard [`Bloom<T>`](../../lib/src/bloom/bloom.dart) nodes, but with one critical distinction: **they do not cache domain payloads**.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        Signal Routing Architecture                     │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   [ Producer Layer (Encapsulated Controller) ]                        │
│   final _refreshSignal = blooming.signal();                       │
│   BloomSignal get refreshSignal => _refreshSignal.bloom;                │
│          │                                                             │
│          ▼ emit()                                                      │
│   [ Monotonic Tick Sequence: 0 -> 1 -> 2 ... ]                         │
│          │                                                             │
│          ├──────────────────────────────────┐                          │
│          ▼ (Push-Dirty Pulse)               ▼ (Push-Dirty Pulse)       │
│   [ Manifest Listener / Side-Effect ]    [ Declarative Pipeline ]      │
│   Effect([refreshSignal], () {           computed.future((via) async { │
│     // 0-run on mount!                     via(refreshSignal);         │
│     // Runs STRICTLY on emit()             return fetchUserFeed();     │
│     showToast("Refreshed!");             });                           │
│   });                                                                  │
│                                                                        │
│   [ Remount / Re-evaluation Guarantee ]                                │
│   No lingering domain payload! Signals carry only discrete sequence    │
│   ticks, eliminating zombie dialogs and duplicate executions on remount│
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### 2.1 The Monotonic Integer Sequence Engine

Under the hood, [BloomSignal](../../lib/src/bloom/signal.dart) implements [`Bloom<int>`](../../lib/src/bloom/bloom.dart). Internally, `_SignalEntry` is a specialized root node initialized to `0`. Each invocation of `BloomSignalController.emit()` executes:

```dart
// packages/blooming/lib/src/bloom/_internal/_signal.dart
@override
void emit() {
  final entry = _target as _RawEntry<int>;
  entry.set(entry.data + 1);
}
```

This design achieves three fundamental guarantees:

1. **100% LPDAG Engine Unification**: Signals do not require a separate event bus, stream controller, or bespoke dispatch pipeline. They participate natively in Bloom's zero-allocation 2-Phase LPDAG Push-Dirty engine.
2. **Monotonic Distinct Immunity**: In reactive systems, attaching `.distinct()` filters to boolean flags (`true -> true`) drops duplicate emissions. Because `BloomSignal` monotonically increments its tick count (`0 -> 1 -> 2 ...`), consecutive signal emissions are **guaranteed never to be suppressed or dropped by `.distinct()`**.
3. **Decoupled Domain Payloads**: The signal node carries no domain data (no strings, models, or entities). Domain data is either passed directly as transient arguments to action handlers or extracted from authoritative stores at the moment of the pulse.

---

## 3. Core Engineering Invariants

1. **Monotonic Sequence & Distinct Immunity Invariant**:
   `BloomSignal` implements `Bloom<int>`, advancing by `+1` on each `emit()`. This guarantees that consecutive pulses are never suppressed by downstream `.distinct()` equality filters.
2. **Producer-Consumer Decoupling Invariant**:
   Emitters hold `BloomSignalController` which exposes `void emit()`. Consumers receive only the read-only `BloomSignal` (`signal.bloom`) which implements `Bloom<int>`, preventing consumers from imperatively firing events.
3. **Zero-Run on Mount Invariant for Manifest Listeners**:
   When observing via manifest `Effect([signal.bloom], action)` or Flutter's `BloomListener(signal.bloom, action)`, initial subscription establishes topological dependency edges with exactly 0 callback executions; `action` executes strictly upon subsequent `signal.emit()` pulses.
4. **Late-Bound Ignorance (Dormancy Safe Invariant)**:
   When `signal.emit()` is invoked while `signal.isActive == false` (no active downstream terminals or listeners attached), the pulse increments the internal sequence and is safely discarded without queuing or accumulating unhandled event backlogs in memory.
5. **Dynamic Epoch Diffing & Branch Rewiring Invariant**:
   When observed inside dynamic functors like `computed`, `switched`, or `managed` via `via(signal.bloom)`, signal dependencies participate in 1-Pass Epoch Sweeping, rewiring or pruning edges without memory leaks.

---

## 4. Production Code Patterns

### 4.1 Triggering Discrete Side-Effects in Pure Dart (`Effect`)

Manifest effects ([`Effect`](../../lib/src/effect/effect.dart)) monitor explicit target signals and execute side-effects (logging, analytics, socket transmissions) strictly upon mutation with **zero executions on mount**:

```dart
class AuthStore {
  final _loginSuccessSignal = blooming.signal();
  BloomSignal get loginSuccessSignal => _loginSuccessSignal.bloom;

  final userProfile = blooming<UserProfile?>(null);

  Future<void> login(String credentials) async {
    final profile = await api.authenticate(credentials);
    userProfile.set(profile);
    
    // Fires discrete event pulse
    _loginSuccessSignal.emit();
  }
}

// In background or service layer:
void setupAnalytics(AuthStore authStore) {
  // Manifest Effect skips initial execution (0 runs on mount)
  Effect([authStore.loginSuccessSignal], () {
    final user = untracked(authStore.userProfile.bloom);
    analytics.logEvent('user_logged_in', {'userId': user?.id});
  });
}
```

### 4.2 Flutter UI Side-Effects (`BloomListener`)

In Flutter applications, listening to signals via `BloomListener` eliminates the "Zombie Dialog" bug completely across widget rebuilds and route transitions:

```dart
class CheckoutView extends StatelessWidget {
  const CheckoutView({super.key, required this.store});
  final CheckoutStore store;

  @override
  Widget build(BuildContext context) {
    return BloomListener(
      store.paymentFailureSignal.bloom,
      (context, _) {
        // Runs STRICTLY when paymentFailureSignal.emit() is called.
        // Remounting this view or popping back to this screen NEVER re-triggers the dialog!
        showDialog(
          context: context,
          builder: (ctx) => const AlertDialog(
            title: Text('Payment Failed'),
            content: Text('Please verify your payment credentials and retry.'),
          ),
        );
      },
      child: CheckoutForm(store: store),
    );
  }
}
```

### 4.3 Declarative Invalidation & SWR Refetching (`computed.future`)

Signals serve as declarative cache-invalidation triggers inside asynchronous pipelines ([computed.future](../../lib/src/bloom/computed.dart)), initiating immediate background refetches without imperative callback spaghettis:

```dart
final refreshSignal = blooming.signal();

// Baseline snapshot loads on mount; subsequent [refreshSignal.emit()] pulses trigger fresh refetches:
final marketOverview = computed.future((via) async {
  via(refreshSignal.bloom); // Dynamically subscribes to the signal pulse
  return stockApi.fetchMarketSnapshot();
});

// User pull-to-refresh action:
void onPullToRefresh() {
  refreshSignal.emit();
}
```

### 4.4 Forcing Re-evaluation of Dynamic Branches (`switched`)

Signals can be observed inside conditional selectors ([switched](../../lib/src/bloom/switched.dart)) to force branch re-evaluation on demand, even when primary condition variables remain unchanged:

```dart
enum FeedTab { trending, personalized }

final selectedTab = blooming(FeedTab.trending);
final reloadTabSignal = blooming.signal();

final activeFeed = switched((via) {
  final tab = via(selectedTab.bloom);
  switch (tab) {
    case FeedTab.trending:
      via(reloadTabSignal.bloom); // Forces trending branch re-evaluation on emit()
      return trendingFeed.bloom;
    case FeedTab.personalized:
      return personalizedFeed.bloom;
  }
});
```

### 4.5 Resetting and Recycling Managed Resources (`managed`)

When coordinating managed lifecycle resources ([managed](../../lib/src/bloom/managed.dart)), observing a signal inside the `create` factory tears down the previous resource via `dispose` and cleanly allocates a fresh instance:

```dart
final reconnectSignal = blooming.signal();

final activeSocket = managed<WebSocketChannel>(
  create: (via) {
    via(reconnectSignal.bloom); // Re-creates socket connection on signal pulse
    return WebSocketChannel.connect(serverUri);
  },
  dispose: (channel) {
    channel.sink.close();
  },
);

// Trigger reconnect:
void reconnect() {
  reconnectSignal.emit();
}
```

### 4.6 Subscriber-Driven Lifecycle Coordination (`onActivated` / `onDeactivated`)

`BloomSignalController` supports subscriber boundary callbacks, allowing emitters to coordinate upstream data sources (e.g., hardware sensors, polling intervals, SSE listeners) based on whether any downstream UI component is actively observing the signal:

```dart
final pushEventSignal = blooming.signal(
  onActivated: () {
    // Connect to external push stream only when observed by active terminal/UI
    pushClient.subscribe();
  },
  onDeactivated: () {
    // Deterministically disconnect when all UI widgets unmount
    pushClient.unsubscribe();
  },
);
```

### 4.7 Zero-Overhead Debugging & Diagnostics

`BloomSignalController` integrates seamlessly into Bloom's zero-cost diagnostic ecosystem via [BloomSignalControllerDebugExtension](../../lib/src/engine/debug.dart):

```dart
final refreshSignal = blooming.signal().withDebugLabel('OrderRefreshSignal');

// Inspect live diagnostic state in debug mode
final snapshot = refreshSignal.bloom.debug.snapshot();
print(snapshot.name);        // "OrderRefreshSignal"
print(snapshot.version);     // 0 (Increments monotonically on each emit)
print(snapshot.isActive);    // true / false based on downstream connections

refreshSignal.emit();
print(refreshSignal.bloom.debugVersion); // 1
```

---

## 5. Architectural Conclusions

By decoupling **`BloomController<T>`** (persistent state representation) from **`BloomSignalController`** (transient event triggers) while unifying both under the core 2-Phase LPDAG engine ([`Bloom<int>`](../../lib/src/bloom/bloom.dart)), the Bloom Framework achieves:

1. **Complete Elimination of Zombie Payloads**: No stale event data is preserved across UI lifecycles or remounts.
2. **Zero-Overhead Monotonic Unification**: Reuses the core topological dependency engine with 0 extra event routing abstractions.
3. **Immunity to Distinct Filter Drops**: Monotonically advancing ticks ensure sequential event pulses are preserved with 100% fidelity.

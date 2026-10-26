// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// BloomController<T> & RawBloomController<T> Imperative Producers (Has-a)
// =============================================================================

/// Imperative producer controller managing state mutations into the Bloom reactive DAG.
///
/// Under the strict **Producer/Consumer Separation (Has-a)** architecture:
/// - [BloomController<T>] owns and encapsulates an internal physical reactive DAG entry node.
/// - It does **NOT** implement [Bloom<T>], completely preventing mutation methods from being
///   inadvertently invoked by consumers that only receive the read-only [bloom] view.
/// - Downcasting a [Bloom<T>] instance back to [BloomController<T>] will fail with a [TypeError],
///   ensuring compile-time and runtime encapsulation of state producers.
///
/// ## System Architectural Flow
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │                     Store / Service                    │
/// │                                                        │
/// │   final _count = blooming<int>(0); // Producer   │
/// │   Bloom<int> get count => _count.bloom;    // Consumer   │
/// └────────────────────────────────────────────────────────┘
///              │                                 │
///              ▼ (.data = 1 / .set(1))           ▼ (untracked / via(count))
/// ┌──────────────────────────┐     ┌──────────────────────────┐
/// │   BloomController<int>    │ ──> │        Bloom<int>         │
/// └──────────────────────────┘     └──────────────────────────┘
///   (Encapsulated Producer)           (Read-Only DAG Node View)
///                                                │
///                                                ▼ (Push-Dirty / Lazy-Pull)
///                                     [Downstream Derivations]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Has-a Producer Encapsulation**: A state container does not mix producer and consumer APIs.
///    Mutations can only be initiated by the component owning the [BloomController] handle.
/// 2. **Built-In Distinct Filtering**: By default, [BloomController] suppresses dirty notifications
///    when consecutive assignments match the previous payload, preventing downstream cascade recomputations.
/// 3. **Subscriber-Driven Inactive Dormancy**: Lifecycle hooks (`onActivated`, `onDeactivated`)
///    fire synchronously as downstream consumers connect or disconnect, enabling automated resource pause.
/// 4. **Deterministic 3-State FSM Control**: Supports full 3-state lifecycle transitions
///    ([set], [empty], [setError]) with optional causal attribution reasons (`reason`).
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT expose [BloomController] directly through public getters or widget constructor parameters.
///   Always expose the read-only [bloom] getter to preserve mutation encapsulation.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Exposing mutable controller handle directly to UI consumers
/// class CounterStore {
///   final count = blooming(0); // Callers can invoke count.set() arbitrarily!
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Encapsulate producer handle and expose read-only Bloom view
/// class CounterStore {
///   final _count = blooming(0);
///   Bloom<int> get count => _count.bloom; // Read-only consumer view
///
///   void increment() => _count.data++;
/// }
/// ```
///
/// ## Examples
/// ```dart
/// final counter = blooming<int>(0);
/// final countView = counter.bloom;
///
/// print(untracked(countView)); // 0
/// counter.set(10);
/// print(untracked(countView)); // 10
/// ```
abstract base class BloomController<T> implements BloomState<T> {
  /// Private constructor preventing direct instantiation; use [blooming] instead.
  BloomController._();

  /// The encapsulated read-only reactive node view exposed to downstream consumers.
  ///
  /// Downstream derivations and UI widgets should observe this view rather than the controller.
  Bloom<T> get bloom;

  /// Injects [data] into the pipeline via property assignment.
  ///
  /// Shorthand alias for [set]. Propagates dirty invalidation pulses downstream if [data]
  /// differs from the existing payload (or if `distinct` is false).
  ///
  /// **Ensures:**
  /// * Transitions this node to the Data state ([hasData] == true) with payload [data].
  set data(T data);

  /// Injects [data] into the pipeline, propagating dirty signals downstream.
  ///
  /// * [data]: The new payload to store and propagate.
  ///
  /// **Ensures:**
  /// * Transitions this node to the Data state ([hasData] == true).
  void set(T data);

  /// Safely executes [test] and injects the returned payload or catches thrown exceptions.
  ///
  /// If [test] executes successfully, the returned value is injected via [set].
  /// If [test] throws an exception, it is caught and transitioned to Error state via [setError].
  ///
  /// * [test]: Synchronous closure returning a new [T] payload or throwing an error.
  ///
  /// **Ensures:**
  /// * On success: Transitions to Data state with the result of [test].
  /// * On exception: Transitions to Error state with the caught error and stack trace.
  ///
  /// ## Examples
  /// ```dart
  /// controller.setGuarded(() => int.parse(rawText));
  /// ```
  void setGuarded(T Function() test);

  /// Injects an error state into the pipeline with optional [stackTrace].
  ///
  /// * [error]: The error or exception object to store.
  /// * [stackTrace]: Optional stack trace associated with the error.
  ///
  /// **Ensures:**
  /// * Transitions this node to the Error state ([hasError] == true).
  void setError(Object error, [StackTrace? stackTrace]);

  /// Injects an empty (uninitialized) state into the pipeline, clearing the current value.
  ///
  /// * [reason]: Optional reason explaining why this state is now empty.
  ///
  /// **Ensures:**
  /// * Transitions this node to the Empty state ([isEmpty] == true).
  void empty([Object? reason]);

  /// Whether this controller's target node is currently observed by downstream subscribers.
  ///
  /// Returns `true` if at least one active terminal or derivation is subscribed to [bloom].
  bool get isActive;
}

/// Raw unfiltered producer controller bypassing distinct checks and supporting manual [markDirty].
///
/// Engineered for high-throughput mutation sequences, mutable in-place data structures, or
/// performance-critical scenarios where equality checks incur non-trivial overhead.
///
/// ## System Architectural Flow
/// ```text
/// [In-Place Mutation: list.add(item)] ──> controller.markDirty() ──> [Push-Dirty Pulse]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Zero Equality Overhead**: Bypasses distinct checks entirely, propagating dirty signals unconditionally.
/// 2. **Manual Dirty Notification**: Allows explicit invalidation for in-place modifications where the
///    reference identity remains unchanged.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT use [RawBloomController] for primitive immutable values (e.g. `int`, `String`) where distinct
///   checks prevent wasteful downstream UI rebuilds. Use standard [BloomController] instead.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Using RawBloomController for immutable primitives wastes distinct suppression
/// final count = blooming.raw(0);
/// count.data = 0; // Triggers redundant downstream rebuilds even when value is unchanged!
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Use RawBloomController for in-place mutable collections with manual markDirty
/// final items = blooming.raw<List<String>>(['initial']);
/// items.data.add('new item');
/// items.markDirty(); // Explicitly notifies downstream subscribers of in-place mutation
/// ```
///
/// ## Examples
/// ```dart
/// final listController = blooming.raw<List<int>>([1, 2, 3]);
/// listController.data.add(4);
/// listController.markDirty(); // Explicitly notify downstream subscribers
/// ```
abstract base class RawBloomController<T> implements BloomController<T> {
  /// Private constructor preventing direct instantiation; use `blooming.raw` instead.
  RawBloomController._();

  /// Force-emits a dirty pulse downstream for in-place mutable collections or objects.
  ///
  /// When modifying mutable objects without creating new instance references, invoke
  /// [markDirty] to inform downstream nodes and UI widgets to re-pull fresh state.
  ///
  /// **Ensures:**
  /// * Synchronously marks the underlying node dirty and schedules downstream updates.
  void markDirty();
}

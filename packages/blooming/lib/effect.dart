// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

/// @docImport 'src/framework.dart';
/// @docImport 'blooming.dart';
///
/// Reactive side-effect pipelines and temporal rate limiters.
///
/// `package:blooming/effect.dart` provides an expressive suite of non-propagating reactive
/// terminals: declarative [Effect], time-domain rate limiters (`Effect.throttle`, `Effect.debounce`),
/// finite execution bounds with reactive guards (`guard`, `take`), and composite grouping (`Effect.group`).
///
/// ## Architectural Overview
///
/// In the Bloom DAG architecture, reactive state nodes ([Bloom]) adhere strictly
/// to the **Push-Dirty / Lazy-Pull** paradigm. Side-effects (such as analytics,
/// logging, audio/haptic feedback, or external I/O sync) MUST NOT mutate intermediate DAG
/// nodes to produce business state.
///
/// Instead, side-effects are modeled as **Terminal Sinks**:
/// - **Terminal Non-Propagation**: Effects do not propagate dirty pulses downstream; they consume
///   signals at graph terminal boundaries without creating cascading DAG cycles.
/// - **Declarative Blueprints**: [Effect] instances can be defined
///   declaratively and attached to tracking scopes via `via.tether()`.
/// - **Zero-Glitch Invariant**: Effects are flushed only after state transactions settle, guaranteeing
///   that multi-node updates are read consistently without transient tearing.
///
/// ## System Architectural Flow
///
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │               Bloom Reactive Topology                 │
/// ├───────────────────────────┬────────────────────────────┤
/// │   State Pipeline Domain   │     Side-Effect Domain     │
/// │ (package:blooming/blooming) │  (package:blooming/effect)  │
/// ├───────────────────────────┼────────────────────────────┤
/// │ • Push-Dirty / Lazy-Pull  │ • Terminal Sinks           │
/// │ • Bloom / Computed / FSM  │ • Non-propagating actions  │
/// │ • State Synchronous SSOT  │ • Debounce / Throttle      │
/// │ • 1 node = 1 allocation   │ • Scope-bound via via.tether│
/// └───────────────────────────┴────────────────────────────┘
/// ```
///
/// ## Architectural Benefits
///
/// 1. **Cycle-Free Terminal Boundaries**: Effects never act as reactive sources for upstream nodes,
///    guaranteeing that side-effect executions cannot create infinite topological update cycles.
/// 2. **Transaction-Safe Flush**: Effects fire only after state transactions settle, eliminating transient
///    tearing or intermediate state reads.
/// 3. **Declarative Lifecycle Management**: Tethering via `via.tether()` automatically aligns effect lifetimes
///    with active subscription scopes, preventing background memory and listener leaks.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT mutate upstream [BloomController] nodes inside an [Effect] without an explicit guard or exit condition;
///   uncontrolled mutations induce reentrant event loops.
/// - Do NOT instantiate new effects repeatedly inside Flutter build methods or dynamic loop passes without
///   persisting them in a field or binding them to a lifecycle scope.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Uncontrolled state mutation inside side-effect creates reentrancy loop
/// final counter = blooming(0);
/// final e = counter.bloom.effect(() {
///   counter.set(untracked(counter.bloom) + 1); // Mutates source node without guard!
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] One-way terminal sink for external interactions
/// final counter = blooming(0);
/// final e = counter.bloom.effect(() {
///   analyticsService.logCount(untracked(counter.bloom)); // Pure side-effect sink
/// });
/// ```
///
/// ## Examples
///
/// ### 1. Fluent Single-Node Debounce:
/// ```dart
/// final searchQuery = blooming('');
///
/// // Debounce searches to execute 300ms after user stops typing
/// final searchRunner = searchQuery.bloom.effect
///     .debounce(
///       const Duration(milliseconds: 300),
///       () => fetchSearchResults(untracked(searchQuery.bloom)),
///     )
///     .start();
/// ```
///
/// ### 2. Scope-Bound Lifecycle with `via.tether()`:
/// ```dart
/// final user = blooming(User(id: 'u1'));
/// final settings = blooming(Settings());
///
/// // Inside a computation scope or terminal:
/// final term = RawViaTerminal(
///   (via) {
///     via.tether((user.bloom, settings.bloom).effect(() {
///       analytics.track('User updated: ${untracked(user.bloom).id}');
///     }));
///   },
///   onInvalidated: () {},
/// );
/// ```
library;

export 'src/framework.dart'
    show
        // Core Contract & Types
        Effect,
        EffectScope,
        EffectScopedFunctor,
        EffectDebounceFunctor,
        EffectThrottleFunctor,
        Tether,
        // Standalone Execution Runner
        EffectStartExtension,
        EffectRunner,
        // Direct Bloom .effect Scopes & Extension Suite
        UnaryBloomEffectScope,
        BloomEffectExtension,
        BloomEffectScope,
        BloomIterableEffectExtension,
        BloomRecord2EffectExtension,
        BloomRecord3EffectExtension,
        BloomRecord4EffectExtension,
        BloomRecord5EffectExtension,
        // Direct .group Extension Suite for Effect
        EffectIterableExtension,
        EffectRecord2Extension,
        EffectRecord3Extension,
        EffectRecord4Extension,
        EffectRecord5Extension;

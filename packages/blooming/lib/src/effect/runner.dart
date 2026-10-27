// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// EffectRunner Public Contract
// =============================================================================

/// An active standalone execution terminal that imperatively controls the lifecycle of an [Effect].
///
/// While declarative [Effect] nodes are typically tethered to reactive tracking scopes
/// via [BloomVia.tether], an [EffectRunner] enables executing effects imperatively
/// outside reactive scopes (e.g. in domain services, ViewModels, or background workers).
///
/// ## System Architectural Flow
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │                Declarative Effect Node                 │
/// └───────────────────────────┬────────────────────────────┘
///                             │ (Active Subscription Edge)
///                             ▼
/// ┌────────────────────────────────────────────────────────┐
/// │                      EffectRunner                      │
/// ├────────────────────────────────────────────────────────┤
/// │ • start()               ──> Attaches edge, resumes runs │
/// │ • stop()                ──> Relinquishes edge (Dormancy)│
/// │ • isActive             ──> Dual-state health check     │
/// └────────────────────────────────────────────────────────┘
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Zero-Leak Inactive Dormancy**: When stopped via [stop],
///    immediately relinquishes its subscription edge, guaranteeing dormant upstream subgraphs when unobserved.
/// 2. **Imperative Standalone Lifecycle**: Controls reactive side-effect execution in services,
///    view models, or CLI tasks outside widget lifecycles.
/// 3. **Subscriber-Driven Dormancy Invariant**: If the same [Effect] instance is shared between
///    a tracking scope (`via.tether`) and an [EffectRunner], stopping the runner leaves the
///    effect active as long as the tethering scope remains active. The underlying effect enters
///    true dormancy only when **all** observing terminals and tethers have detached.
/// 4. **Dual-State Health Invariant**: [isActive] reflects both the runner's lifecycle state
///    and the underlying effect terminal's status. If the underlying effect deactivates due to
///    exhausting its `take` ticket quota (Early Teardown), [isActive] transitions to `false` automatically.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT call `.start()` repeatedly inside Flutter build methods or reactive derivations without
///   stopping; unmanaged runners stay attached to upstream effects and cause memory leaks.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Spawning effect runners inside build method causes memory leaks
/// Widget build(BuildContext context) {
///   searchEffect.start(); // New runner created on every render frame!
///   return Text('Searching...');
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Manage runner in long-lived lifecycle scope or State class
/// class SearchService {
///   late final EffectRunner _runner;
///
///   void init() {
///     _runner = searchEffect.start();
///   }
///
///   void dispose() => _runner.stop();
/// }
/// ```
///
/// ## Examples
/// ```dart
/// final query = blooming('');
/// final searchEffect = Effect.debounce(
///   [query.bloom],
///   const Duration(milliseconds: 300),
///   () => apiService.search(untracked(query.bloom)),
/// );
///
/// // Start standalone execution:
/// final runner = searchEffect.start();
///
/// // Pause observation:
/// runner.stop();
///
/// // Resume observation:
/// runner.start();
/// ```
abstract interface class EffectRunner implements LpdagStatus {
  /// Creates an inactive, dormant [EffectRunner] managing execution of [effect].
  ///
  /// * [effect]: The target declarative [Effect] to execute.
  ///
  /// **Ensures:**
  /// * Returns a dormant [EffectRunner] (`isActive == false`) governing execution of [effect].
  /// * Observation and execution begin only upon calling [start].
  ///
  /// ## Examples
  /// ```dart
  /// final runner = EffectRunner(myEffect);
  /// expect(runner.isActive, isFalse);
  ///
  /// // Start execution:
  /// runner.start();
  /// expect(runner.isActive, isTrue);
  /// ```
  factory EffectRunner(Effect effect) = _EffectRunnerImpl;

  /// Starts or resumes observation and execution of the underlying effect.
  void start();

  /// Stops or pauses observation and execution, relinquishing this runner's subscription edge.
  void stop();

  /// The underlying [Effect] executed by this runner.
  Effect get effect;

  /// Whether both this runner and its underlying effect terminal are currently active.
  ///
  /// Returns `false` if this runner has been stopped via [stop], or if
  /// the underlying effect terminal has completed early teardown (e.g. exhausted `take` tickets).
  @override
  bool get isActive;
}

// =============================================================================
// EffectStartExtension
// =============================================================================

/// Extension granting declarative [Effect] instances direct invocation of an [EffectRunner].
extension EffectStartExtension on Effect {
  /// Instantiates an [EffectRunner] and immediately starts observation and execution.
  ///
  /// **Ensures:**
  /// * Attaches an active subscription edge to this [Effect].
  /// * Returns an active [EffectRunner] (`isActive == true`).
  ///
  /// **Warning (Anti-Pattern Prevention):**
  /// - Do NOT invoke `.start()` inside Flutter build methods or reactive derivations without stopping.
  ///
  /// **BAD:**
  /// ```dart
  /// // [Anti-Pattern] Calling .start() on every frame rebuild
  /// Widget build(BuildContext context) {
  ///   loggingEffect.start(); // Re-creates and leaks runner
  ///   return Container();
  /// }
  /// ```
  ///
  /// **GOOD:**
  /// ```dart
  /// // [Recommended] Run standalone effect in service lifecycle
  /// class LoggingService {
  ///   late final EffectRunner _runner;
  ///   void init() => _runner = loggingEffect.start();
  ///   void dispose() => _runner.stop();
  /// }
  /// ```
  ///
  /// ## Examples
  /// ```dart
  /// final counter = blooming(0);
  /// final loggingEffect = counter.bloom.effect(() => log(untracked(counter.bloom)));
  /// final runner = loggingEffect.start();
  ///
  /// // Clean up when finished:
  /// runner.stop();
  /// ```
  @useResult
  @pragma('vm:prefer-inline')
  EffectRunner start() => EffectRunner(this)..start();

  /// Creates a dormant, unstarted [EffectRunner] for this effect.
  ///
  /// Call [EffectRunner.start] on the returned runner to begin observation and execution.
  @useResult
  @pragma('vm:prefer-inline')
  EffectRunner get runner => EffectRunner(this);
}

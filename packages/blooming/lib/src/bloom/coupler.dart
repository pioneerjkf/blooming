// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// Dynamic Bloom Couplers & Pipeline Coupling Sockets
// =============================================================================

/// A dynamic reactive socket controller that allows hot-coupling or cold-coupling upstream
/// [Bloom] pipelines at runtime without rebuilding downstream consumers.
///
/// Standard [Bloom] pipelines form a statically connected DAG. [BloomCoupler] introduces a
/// dynamic 1-tier relay proxy in the pipeline, allowing developers to switch the upstream source
/// node dynamically while maintaining unbroken continuity for downstream listeners.
///
/// Following the Producer-Consumer decoupling model of [BloomController], [BloomCoupler] acts
/// as the controller/producer handle and exposes a read-only [bloom] consumer view, completely
/// encapsulating mutation and coupling capabilities from downstream consumers.
///
/// ## System Architectural Flow
/// ```text
/// [Upstream Bloom A] (Detached on couple)
///        │
///        ▼ (coupler.couple(bloomB))
/// ┌─────────────────────┐
/// │   BloomCoupler<T>    │ ──► bloom (Read-Only) ──► [Downstream Transformations / Terminals]
/// └─────────────────────┘
///        ▲
///        │ (Newly Attached)
/// [Upstream Bloom B]
/// ```
///
/// **Common Use Cases:**
/// * **Environment Coupling:** Dynamically coupling a mock data source with a live API source.
/// * **Session Management:** Switching the active user stream upon authentication state changes.
/// * **Feature Toggles:** Rerouting reactive data flows based on runtime configuration.
///
/// **Warning (Anti-Pattern Prevention):**
/// - **DO NOT** perform circular coupling (e.g. coupling a downstream node that already depends on this coupler).
///   Circular coupling causes infinite dependency loops and topological corruption.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Circular coupling: coupler depends on downstream child
/// final coupler = BloomCoupler<int>.late();
/// final childBloom = computed((via) => via(coupler.bloom) + 1);
/// coupler.couple(childBloom); // Circular dependency loop!
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Hot-coupling independent upstream sources
/// final mockSource = Bloom.constant('Guest');
/// final liveSource = blooming<String>('User123');
///
/// final coupler = BloomCoupler<String>(mockSource);
/// final greetingBloom = computed((via) => 'Hello, ${via(coupler.bloom)}!');
///
/// coupler.couple(liveSource.bloom); // Safely coupled to live source
/// ```
base class BloomCoupler<T> with _BloomStateMixin<T> implements BloomState<T>, LpdagStatus {
  /// Creates a [BloomCoupler] initialized with [inbound].
  ///
  /// * [inbound]: The initial upstream [Bloom] pipeline to relay.
  ///
  /// **Ensures:**
  /// * Returns a [BloomCoupler] delegating to [inbound].
  ///
  /// ## Examples
  /// ```dart
  /// final coupler = BloomCoupler(liveSourceBloom);
  /// ```
  BloomCoupler(Bloom<T> inbound) : _proxy = _CoupledBloom<T>(inbound);

  /// Creates a [BloomCoupler] in an uninitialized (empty) state.
  ///
  /// **Ensures:**
  /// * Returns an empty [BloomCoupler] awaiting its first [couple].
  BloomCoupler.late() : _proxy = _CoupledBloom<T>.late();

  /// Creates a [BloomCoupler] initialized in an error state.
  ///
  /// * [error]: The initial failure or exception object.
  /// * [stackTrace]: Optional stack trace associated with the failure.
  ///
  /// **Ensures:**
  /// * Returns a [BloomCoupler] initialized in an error state.
  BloomCoupler.error(Object error, [StackTrace? stackTrace]) : _proxy = _CoupledBloom<T>.error(error, stackTrace);

  final _CoupledBloom<T> _proxy;

  /// Exposes the underlying read-only [Bloom] node for downstream consumers.
  @pragma('vm:prefer-inline')
  Bloom<T> get bloom => _proxy;

  /// Couples the currently attached inbound source node with [newInbound].
  ///
  /// * [newInbound]: The new upstream [Bloom] node to attach to this coupler.
  ///
  /// **Ensures:**
  /// * If this coupler is currently active, [newInbound] is automatically activated.
  /// * The previously attached node is detached cleanly.
  /// * Returns the previous inbound node, or `null` if [newInbound] is identical to the currently attached inbound node.
  @pragma('vm:prefer-inline')
  Bloom<T>? couple(Bloom<T> newInbound) => _proxy._performCouple(newInbound);

  /// Safely executes [callback] and couples the inbound node to the returned [Bloom].
  ///
  /// * [callback]: A closure returning the new upstream [Bloom] node to attach.
  ///
  /// **Ensures:**
  /// * If [callback] throws, catches the exception and transitions this coupler to an error state.
  /// * Returns the previous inbound node, or `null` if [callback] threw or the new node was identical to the current inbound.
  Bloom<T>? coupleGuarded(Bloom<T> Function() callback) {
    try {
      return couple(callback());
    } catch (error, stackTrace) {
      setError(error, stackTrace);
      return null;
    }
  }

  /// Immediately decouples and detaches the currently attached inbound node.
  ///
  /// **Ensures:**
  /// * Transitions the coupler into an empty state until a new node is coupled.
  @pragma('vm:prefer-inline')
  void decouple() => _proxy._performDecouple();

  /// Decouples the inbound node only if it matches [bloom].
  ///
  /// * [bloom]: The candidate [Bloom] node to decouple.
  ///
  /// **Ensures:**
  /// * Returns `true` if [bloom] matched the currently attached node and was decoupled.
  /// * Returns `false` otherwise without altering coupling state.
  bool tryDecoupling(Bloom<dynamic> bloom) {
    if (!identical(bloom, _proxy._source)) return false;
    decouple();
    return true;
  }

  /// Injects an error state into the coupler with optional [stackTrace].
  ///
  /// * [error]: The error or exception object to transition into.
  /// * [stackTrace]: Optional stack trace associated with [error].
  ///
  /// **Ensures:**
  /// * Transitions the coupler to an error state and propagates dirty invalidation downstream.
  /// * Returns the previously attached inbound node.
  Bloom<T> setError(Object error, [StackTrace? stackTrace]) => _proxy._setError(error, stackTrace);

  /// Whether this coupler currently has active downstream subscribers.
  @override
  bool get isActive => _proxy.isActive;

  @override
  @pragma('vm:prefer-inline')
  _BloomState<T> _read() => _proxy._read();
}

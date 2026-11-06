// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// Scoped Explicit Dependency Tracker (Effect Manifest)
// =============================================================================

/// The scoped dependency tracker injected into [Effect] and reactive sink callbacks.
///
/// Provides explicit observation calls (`via(node)` and `via.state(node)`) and lifecycle
/// tethering (`via.tether(...)`). Deliberately omits `exit` and empty state mutations
/// because side-effects are void-returning sinks without reactive states.
final class EffectVia {
  EffectVia._(this._node);

  final _EffectViaEpochMixin _node;

  /// Scoped watch function that tracks [bloom] as an upstream dependency
  /// and returns its underlying valid data payload of type [T].
  ///
  /// If [bloom] is currently in an empty or error state, short-circuits
  /// and silently halts the current effect execution turn.
  ///
  /// * [bloom]: The reactive node to observe within this evaluation epoch.
  @pragma('vm:prefer-inline')
  T call<T>(Bloom<T> bloom) {
    _node._trackDependency(this, bloom);
    final s = bloom._read();
    if (s is _ValidBloomState) {
      return s.data;
    }
    throw _ViaShortCircuit(s);
  }

  /// Registers [bloom] as an active dependency in the current evaluation epoch
  /// and returns its 3-phase [BloomState] container without short-circuiting.
  ///
  /// * [bloom]: The reactive node to observe within this evaluation epoch.
  @pragma('vm:prefer-inline')
  BloomState<T> state<T>(Bloom<T> bloom) {
    _node._trackDependency(this, bloom);
    return bloom as BloomState<T>;
  }

  /// Tethers declarative [tether] to this tracking scope's lifecycle.
  ///
  /// * [tether]: The scoped lifecycle resource or side-effect to attach.
  ///
  /// **Ensures:**
  /// * The tether is automatically activated when this scope activates, and
  ///   deactivated (dormant) when this scope deactivates or is unmounted.
  /// * Emits zero dirty invalidation pulses downstream to parent scopes.
  /// * Returns the identical [tether] instance.
  ///
  /// ## Examples
  /// ```dart
  /// final eventCount = blooming(0);
  /// final analyticsLoggerEffect = Effect([eventCount.bloom], () {
  ///   print('Logged event: ${untracked(eventCount.bloom)}');
  /// });
  ///
  /// final parentEffect = Effect.via((via) {
  ///   via.tether(analyticsLoggerEffect);
  ///   print('Observed: ${via(eventCount.bloom)}');
  /// });
  /// ```
  @pragma('vm:prefer-inline')
  T tether<T extends Tether>(T tether) {
    _node._trackDependency(this, tether);
    return tether;
  }
}

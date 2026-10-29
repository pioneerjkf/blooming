// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

// =============================================================================
// Animation -> Bloom Reactive Bridge
// =============================================================================

/// A convenience extension bridging Flutter's [Animation] status updates with the Bloom reactive pipeline.
extension AnimationStatusBloomExtension on Animation<dynamic> {
  /// Converts this [Animation]'s status updates into a demand-driven reactive [Bloom] of [AnimationStatus].
  ///
  /// Subscribes to status updates only while active, and automatically unsubscribes on deactivation
  /// to prevent listener memory leaks.
  ///
  /// * [distinct]: When `true` (default), suppresses consecutive duplicate [AnimationStatus] pulses.
  /// * [graceful]: Optional [Graceful] teardown deferral policy when all downstream subscribers detach.
  ///
  /// **Ensures:**
  /// * Returns a demand-driven [Bloom] seeded with the current [status].
  ///
  /// **Warning (Anti-Pattern Prevention):**
  /// - Do NOT invoke [toStatusBloom] directly inside a widget `build()` method; cache the bridged node in state or a controller field.
  ///
  /// ## Examples
  /// ```dart
  /// final statusBloom = animation.toStatusBloom();
  /// final badge = statusBloom.build((context, status) => Text('Status: ${status.name}'));
  /// ```
  Bloom<AnimationStatus> toStatusBloom({
    bool distinct = true,
    Graceful? graceful,
  }) =>
      _AnimationStatusBloomPipe(
        this,
        distinct: distinct,
        graceful: graceful,
      ).bloom;
}

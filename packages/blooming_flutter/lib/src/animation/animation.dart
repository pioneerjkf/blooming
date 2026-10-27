// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

// =============================================================================
// Animation -> Bloom Reactive Bridge
// =============================================================================

/// A convenience extension bridging Flutter's [Animation] status updates with the Bloom reactive pipeline.
extension AnimationStatusBloomExtension on Animation<dynamic> {
  /// Converts this [Animation]'s status updates into a demand-driven reactive [Bloom<AnimationStatus>].
  ///
  /// Subscribes to status updates only while active, and automatically unsubscribes on deactivation
  /// to prevent listener memory leaks.
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

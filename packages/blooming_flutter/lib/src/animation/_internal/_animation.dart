// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../framework.dart';

// =============================================================================
// AnimationStatus -> Bloom Demand-Driven Bridge Pipe
// =============================================================================

final class _AnimationStatusBloomPipe {
  /// Creates a demand-driven bridge pipe wrapping [animation]'s status updates.
  _AnimationStatusBloomPipe(
    Animation<dynamic> animation, {
    bool distinct = true,
    Graceful? graceful,
  }) : _animation = animation {
    _controller = blooming<AnimationStatus>(
      animation.status,
      distinct: distinct,
      graceful: graceful,
      onActivated: _onActivate,
      onDeactivated: _onDeactivate,
    );
  }

  final Animation<dynamic> _animation;
  late final BloomController<AnimationStatus> _controller;

  /// Activates the bridge, synchronizing the current status and registering the status listener.
  void _onActivate() {
    _controller.setGuarded(() => _animation.status);
    _animation.addStatusListener(_listen);
  }

  /// Deactivates the bridge, removing the status listener from the source animation.
  void _onDeactivate() {
    _animation.removeStatusListener(_listen);
  }

  /// Handles incoming status notifications from the source animation.
  void _listen(AnimationStatus status) {
    _controller.set(status);
  }

  /// The read-only [Bloom<AnimationStatus>] consumer view of this bridge.
  Bloom<AnimationStatus> get bloom => _controller.bloom;
}

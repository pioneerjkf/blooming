// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

// =============================================================================
// Internal BloomGuard Concrete Implementations
// =============================================================================

final class _PassBloomGuard extends BloomGuard {
  const _PassBloomGuard() : super._();

  @override
  bool get isPass => true;

  @override
  Object? get reason => null;

  @override
  String toString() => 'BloomGuard.pass';
}

final class _BlockBloomGuard extends BloomGuard {
  const _BlockBloomGuard([this.reason = BloomGuard.prerequisiteNotMet]) : super._();

  @override
  bool get isPass => false;

  @override
  final Object reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is _BlockBloomGuard && other.reason == reason) || other == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'BloomGuard.block($reason)';
}

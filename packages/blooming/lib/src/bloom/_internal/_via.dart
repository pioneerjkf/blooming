// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

/// Mixin for reactive computed nodes, managed resources, and terminals that binds
/// explicit dependency tracking to [BloomVia].
base mixin _BloomViaEpochMixin on _ViaEpochMixin<BloomVia> {
  @override
  BloomVia _initVia() => BloomVia._(this);

  @override
  void _refreshVia() {
    _via = BloomVia._(this);
  }
}

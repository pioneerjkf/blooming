// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

/// Mixin for [Effect] terminals that binds explicit dependency tracking to [EffectVia].
base mixin _EffectViaEpochMixin on _ViaEpochMixin<EffectVia> {
  @override
  EffectVia _initVia() => EffectVia._(this);

  @override
  void _refreshVia() {
    _via = EffectVia._(this);
  }
}

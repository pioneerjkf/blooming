// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

final class _BloomUntrackedImpl implements BloomUntracked {
  const _BloomUntrackedImpl();

  @override
  @pragma('vm:prefer-inline')
  T call<T>(Bloom<T> bloom) => bloom._read().data;

  @override
  @pragma('vm:prefer-inline')
  BloomState<T> state<T>(Bloom<T> bloom) => bloom as BloomState<T>;
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart' as b;

/// Test utility for testing reactive tracking in unit tests.
void Function() effect(Function callback) {
  final term = RawViaTerminal((via) {
    via.tether(
      b.Effect.via(
        callback is void Function(BloomVia) ? callback : (v) => (callback as dynamic)(),
      ),
    );
  }, onInvalidated: () {})
    ..activate()
    ..evaluate();
  return term.deactivate;
}

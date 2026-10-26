// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

/// Internal coordinator library binding the Engine, Bloom, Effect, and Reflector domains.
///
/// This file acts as the central part file coordinator for the `package:blooming`
/// core. It organizes source files into four decoupled architectural tiers:
///
/// 1. **Engine Domain (`src/engine/`)**:
///    The topological core containing intrusive doubly-linked list DAG edges (`_SourceEdge`,
///    `_TargetEdge`), the Push-Dirty invalidation loop (`_push.dart`), explicit dependency tracking
///    (`via.dart`), the 1-tick microtask queue coordinator (`_scheduler.dart`), and
///    terminal anchors (`terminal.dart`, `graceful.dart`).
///
/// 2. **Bloom Domain (`src/bloom/`)**:
///    The reactive state abstraction tier containing read-only reactive nodes ([Bloom]),
///    producer controllers ([BloomController], [RawBloomController]), the Dynamic Triad,
///    immutable point-in-time state containers ([BloomSnapshot]), and collection reactivity.
///
/// 3. **Effect Domain (`src/effect/`)**:
///    The non-propagating side-effect sink tier containing declarative effects ([Effect])
///    and rate limiters ([DebounceEffect], [ThrottleEffect]).
///
/// 4. **Reflector Domain (`src/reflector/`)**:
///    The DevTools and diagnostic inspection tier containing zero-overhead reflection
///    handles ([LpdagReflector], [BloomReflector]), topology walkers, and serialization.
library;

import 'dart:async';

import 'package:meta/meta.dart';

// =============================================================================
// 1. [Engine Domain] (LPDAG Topological Core, Terminals, Schedulers & Tracking)
// =============================================================================
part 'engine/batch.dart';
part 'engine/debug.dart';
part 'engine/exception.dart';
part 'engine/graceful.dart';
part 'engine/status.dart';
part 'engine/terminal.dart';
part 'engine/tether.dart';
part 'engine/uncaught.dart';
part 'engine/via.dart';
part 'engine/_internal/_batch.dart';
part 'engine/_internal/_debug.dart';
part 'engine/_internal/_dirty.dart';
part 'engine/_internal/_edge.dart';
part 'engine/_internal/_graceful.dart';
part 'engine/_internal/_lifecycle.dart';
part 'engine/_internal/_mooring.dart';
part 'engine/_internal/_node.dart';
part 'engine/_internal/_origin.dart';
part 'engine/_internal/_pull.dart';
part 'engine/_internal/_push.dart';
part 'engine/_internal/_relay.dart';
part 'engine/_internal/_scheduler.dart';
part 'engine/_internal/_terminal.dart';
part 'engine/_internal/_uncaught.dart';
part 'engine/_internal/_via.dart';

// =============================================================================
// 2. [Bloom Domain] (Reactive State, Nodes, Dynamic Triad & Controllers)
// =============================================================================
part 'bloom/async.dart';
part 'bloom/collection.dart';
part 'bloom/computed.dart';
part 'bloom/controller.dart';
part 'bloom/blooming.dart';
part 'bloom/coupler.dart';
part 'bloom/elements.dart';
part 'bloom/exception.dart';
part 'bloom/guard.dart';
part 'bloom/managed.dart';
part 'bloom/signal.dart';
part 'bloom/snapshot.dart';
part 'bloom/state.dart';
part 'bloom/switched.dart';
part 'bloom/untracked.dart';
part 'bloom/bloom.dart';
part 'bloom/_internal/_async.dart';
part 'bloom/_internal/_collection.dart';
part 'bloom/_internal/_computed.dart';
part 'bloom/_internal/_controller.dart';
part 'bloom/_internal/_coupler.dart';
part 'bloom/_internal/_delta.dart';
part 'bloom/_internal/_elements.dart';
part 'bloom/_internal/_entry.dart';
part 'bloom/_internal/_guard.dart';
part 'bloom/_internal/_managed.dart';
part 'bloom/_internal/_signal.dart';
part 'bloom/_internal/_snapshot.dart';
part 'bloom/_internal/_state.dart';
part 'bloom/_internal/_switched.dart';
part 'bloom/_internal/_untracked.dart';
part 'bloom/_internal/_bloom.dart';

// =============================================================================
// 3. [Effect Domain] (Side-Effects & Temporal Limiters)
// =============================================================================
part 'effect/effect.dart';
part 'effect/extensions.dart';
part 'effect/runner.dart';
part 'effect/_internal/_base.dart';
part 'effect/_internal/_effect.dart';
part 'effect/_internal/_runner.dart';

// =============================================================================
// 4. [Reflector Domain] (DevTools & Diagnostics Inspection)
// =============================================================================
part 'reflector/reflector.dart';
part 'reflector/_internal/_reflector.dart';

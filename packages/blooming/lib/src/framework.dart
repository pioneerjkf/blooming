// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

/// Internal coordinator library binding the Graph, Blooming, Bloom, Effect, and Reflector domains.
///
/// This file acts as the central part file coordinator for the `package:blooming`
/// core. It organizes source files into five decoupled architectural tiers:
///
/// 1. **Graph Domain (`src/graph/`)**:
///    The topological core containing intrusive doubly-linked list DAG edges (`_Edge`,
///    `_TargetEdge`), the Push-Dirty invalidation loop (`_push.dart`), DAG edge tracking mixins
///    (`_via.dart`), the 1-tick microtask queue coordinator (`_scheduler.dart`), and
///    terminal anchors (`terminal.dart`, `graceful.dart`).
///
/// 2. **Blooming Domain (`src/blooming/`)**:
///    The mutable state producer (CQRS Write/Origin) tier containing state producer handles
///    ([blooming], [BloomController], [RawBloomController], [BloomDraftController], [BloomSignalController]),
///    discrete event triggers, and encapsulated physical entry roots (`_Entry`).
///
/// 3. **Bloom Domain (`src/bloom/`)**:
///    The reactive state abstraction (CQRS Read/FSM & Relay) tier containing read-only reactive nodes ([Bloom]),
///    dynamic pipeline couplers ([BloomCoupler]), the Dynamic Triad ([computed], [switched], [managed]),
///    immutable point-in-time state containers ([BloomSnapshot], [BloomState]), collection reactivity, and raw read accessors ([untracked]).
///
/// 4. **Effect Domain (`src/effect/`)**:
///    The non-propagating side-effect sink tier containing declarative effects ([Effect])
///    and rate limiters ([EffectDebounceFunctor], [EffectThrottleFunctor]).
///
/// 5. **Reflector Domain (`src/reflector/`)**:
///    The DevTools and diagnostic inspection tier containing zero-overhead reflection
///    handles ([LpdagReflector], [BloomReflector]), topology walkers, and serialization.
library;

import 'dart:async';

import 'package:meta/meta.dart';

// =============================================================================
// 1. [Graph Domain] (LPDAG Topological Core, Terminals, Schedulers & Tracking)
// =============================================================================
part 'graph/batch.dart';
part 'graph/debug.dart';
part 'graph/exception.dart';
part 'graph/graceful.dart';
part 'graph/status.dart';
part 'graph/terminal.dart';
part 'graph/tether.dart';
part 'graph/uncaught.dart';
part 'graph/_internal/_batch.dart';
part 'graph/_internal/_debug.dart';
part 'graph/_internal/_dirty.dart';
part 'graph/_internal/_edge.dart';
part 'graph/_internal/_graceful.dart';
part 'graph/_internal/_lifecycle.dart';
part 'graph/_internal/_mooring.dart';
part 'graph/_internal/_node.dart';
part 'graph/_internal/_origin.dart';
part 'graph/_internal/_pull.dart';
part 'graph/_internal/_push.dart';
part 'graph/_internal/_relay.dart';
part 'graph/_internal/_scheduler.dart';
part 'graph/_internal/_terminal.dart';
part 'graph/_internal/_uncaught.dart';
part 'graph/_internal/_via.dart';

// =============================================================================
// 2. [Blooming Domain] (Mutable State Producers, CQRS Write Roots & Controllers)
// =============================================================================
part 'blooming/blooming.dart';
part 'blooming/controller.dart';
part 'blooming/draft.dart';
part 'blooming/signal.dart';
part 'blooming/_internal/_controller.dart';
part 'blooming/_internal/_draft.dart';
part 'blooming/_internal/_entry.dart';
part 'blooming/_internal/_signal.dart';

// =============================================================================
// 3. [Bloom Domain] (Reactive State, Dynamic Triad, FSM & Read-Only Nodes)
// =============================================================================
part 'bloom/async.dart';
part 'bloom/bloom.dart';
part 'bloom/collection.dart';
part 'bloom/computed.dart';
part 'bloom/coupler.dart';
part 'bloom/elements.dart';
part 'bloom/exception.dart';
part 'bloom/managed.dart';
part 'bloom/snapshot.dart';
part 'bloom/state.dart';
part 'bloom/switched.dart';
part 'bloom/untracked.dart';
part 'bloom/via.dart';
part 'bloom/_internal/_async.dart';
part 'bloom/_internal/_bloom.dart';
part 'bloom/_internal/_computed.dart';
part 'bloom/_internal/_coupler.dart';
part 'bloom/_internal/_delta.dart';
part 'bloom/_internal/_elements.dart';
part 'bloom/_internal/_managed.dart';
part 'bloom/_internal/_snapshot.dart';
part 'bloom/_internal/_state.dart';
part 'bloom/_internal/_switched.dart';
part 'bloom/_internal/_untracked.dart';

// =============================================================================
// 4. [Effect Domain] (Side-Effects & Temporal Limiters)
// =============================================================================
part 'effect/effect.dart';
part 'effect/extensions.dart';
part 'effect/runner.dart';
part 'effect/via.dart';
part 'effect/_internal/_base.dart';
part 'effect/_internal/_effect.dart';
part 'effect/_internal/_runner.dart';

// =============================================================================
// 5. [Reflector Domain] (DevTools & Diagnostics Inspection)
// =============================================================================
part 'reflector/reflector.dart';
part 'reflector/_internal/_reflector.dart';

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// Reactive Collection Controller (List, Set, Map)
// =============================================================================

/// Producer controller managing reactive collection states ([List], [Set], [Map]) with
/// guaranteed immutability and transactional draft edits.
///
/// Under the Bloom reactive DAG engine:
/// - Guarantees that internal collection states are permanently frozen as unmodifiable collections
///   ([List.unmodifiable], [Set.unmodifiable], [Map.unmodifiable]).
/// - Prevents in-place mutation leaks: attempting to mutate `.data` directly throws [UnsupportedError].
/// - In-place batch modifications inside [edit] execute in an isolated draft buffer and commit in
///   at most one downstream Push-Dirty pulse after equality diffing.
///
/// ## System Architectural Flow
/// ```text
/// [BloomCollectionController] ──> .edit((draft) { draft.add(item); })
///                                         │
///                                         ▼ (Compares Equality with Previous)
///                              [Modified? ── Yes ──> Freezes Unmodifiable & Push-Dirty (1 Pulse)]
///                                         └── No   ──> No-Op (Zero Downstream Recomputations)
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Unmodifiable Freezing Guarantee**: Stored data is always frozen into unmodifiable collections,
///    guaranteeing that downstream observers never suffer from out-of-band mutation glitches.
/// 2. **Atomic Draft Transactions**: Edits are applied to an isolated draft buffer and committed in a single pulse.
/// 3. **Deep/Shallow Equality Guarding**: Suppresses downstream notifications if the draft results in no net changes.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT attempt to mutate `.data` in-place directly (e.g. `controller.data.add(...)`), as `.data` returns an
///   unmodifiable collection and throws an [UnsupportedError]. Always use [edit] or assign a new collection via [set].
///
/// ## Examples
/// ```dart
/// // 1. Reactive list
/// final todos = blooming.list<String>(['Task 1', 'Task 2']);
/// todos.edit((draft) => draft.add('Task 3'));
///
/// // 2. Reactive set
/// final tags = blooming.set<String>({'flutter', 'reactive'});
/// tags.edit((draft) => draft.add('dart'));
///
/// // 3. Reactive map
/// final scores = blooming.map<String, int>({'Alice': 100});
/// scores.edit((draft) => draft['Bob'] = 95);
/// ```
abstract base class BloomCollectionController<C> implements BloomController<C> {
  /// Internal constructor for subclasses.
  BloomCollectionController._();

  /// Edits the current state in-place via a temporary draft buffer.
  ///
  /// The [recipe] callback receives a mutable copy of the current collection.
  /// Upon completion, changes are compared via equality (`equals` or collection-specific shallow equality).
  /// If modified, the new collection is frozen as an unmodifiable collection and
  /// commits at most one Push-Dirty invalidation downstream.
  ///
  /// * [recipe]: Synchronous callback mutating the temporary draft buffer in-place.
  void edit(void Function(C draft) recipe);

  /// Safely executes [recipe] on a temporary draft buffer and commits modifications,
  /// or catches any thrown exceptions and transitions this controller to an error state.
  ///
  /// * [recipe]: Synchronous callback mutating the temporary draft buffer in-place.
  void editGuarded(void Function(C draft) recipe);

  @override
  Bloom<C> get bloom;
}

/// Backward compatibility alias for [BloomCollectionController].
@Deprecated('Use BloomCollectionController instead. Will be removed in 0.4.0.')
typedef BloomDraftController<C> = BloomCollectionController<C>;

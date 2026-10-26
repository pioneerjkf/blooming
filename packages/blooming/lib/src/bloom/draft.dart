// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// Transactional Draft Controllers (List, Set, Map, Entities)
// =============================================================================

/// Producer controller managing a reactive state with transactional draft edits.
///
/// Combines zero-overhead immutable replacement ([set], [data]) with
/// transactional draft edits ([edit], [editGuarded]).
///
/// Modifying elements inside an [edit] closure guarantees that changes are
/// compared via equality, frozen into an unmodifiable collection, and
/// committed in at most one downstream Push-Dirty pulse.
///
/// ## System Architectural Flow
/// ```text
/// [BloomDraftController] ──> .edit((draft) { draft.add(item); })
///                                    │
///                                    ▼ (Compares Equality with Previous)
///                         [Modified? ── Yes ──> Freezes Unmodifiable & Push-Dirty (1 Pulse)]
///                                    └── No   ──> No-Op (Zero Downstream Recomputations)
/// ```
///
/// ## Architectural Benefits
/// 1. **Atomic Draft Transactions**: Edits are applied to an isolated draft buffer and committed in a single pulse.
/// 2. **Deep/Shallow Equality Guarding**: Suppresses downstream notifications if the draft results in no net changes.
/// 3. **Immutability Enforcement**: The underlying payload is stored as unmodifiable collections to prevent mutation leaks.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT attempt to mutate `.data` in-place directly (e.g. `controller.data.add(...)`), as `.data` returns an
///   unmodifiable collection and throws an [UnsupportedError]. Always use [edit] or assign a new collection via [set].
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Mutating unmodifiable collection directly throws UnsupportedError
/// final listCtrl = blooming.list([1, 2]);
/// listCtrl.data.add(3); // Throws UnsupportedError!
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Use transactional edit to safely mutate draft and commit
/// final listCtrl = blooming.list([1, 2]);
/// listCtrl.edit((draft) => draft.add(3)); // Commits atomically as immutable list
/// ```
///
/// ## Examples
/// ```dart
/// // Primary: construct via blooming functor
/// final numbers = blooming.list([1, 2, 3]);
/// numbers.edit((draft) {
///   draft.add(4);
///   draft.remove(1);
/// });
/// print(numbers.data); // [2, 3, 4]
///
/// final tags = blooming.set({'flutter', 'dart'});
/// tags.edit((draft) => draft.add('reactive'));
///
/// final scores = blooming.map({'Alice': 90});
/// scores.edit((draft) => draft['Bob'] = 85);
/// ```
abstract base class BloomDraftController<C> implements BloomController<C> {
  /// Private constructor preventing direct instantiation; use `blooming.list`, `blooming.set`, or `blooming.map` instead.
  BloomDraftController._();

  /// Edits the current state in-place via a temporary draft buffer.
  ///
  /// The [recipe] callback receives a mutable copy of the current collection.
  /// Upon completion, changes are compared via equality (`equals` or collection-specific equality).
  /// If modified, the new collection is frozen as an unmodifiable collection and
  /// commits at most one Push-Dirty invalidation downstream.
  void edit(void Function(C draft) recipe);

  /// Safely executes [recipe] on a temporary draft buffer and commits modifications,
  /// or catches any thrown exceptions and transitions this controller to an error state.
  void editGuarded(void Function(C draft) recipe);

  @override
  Bloom<C> get bloom;
}

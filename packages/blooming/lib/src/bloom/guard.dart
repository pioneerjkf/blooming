// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// Precondition Guarding & Algebraic State Gating
// =============================================================================

/// Represents the decision of a reactive guard evaluation in the Bloom Framework.
///
/// Precondition guards act as algebraic fault-barriers across the Dynamic Triad
/// ([computed], [managed], [switched]). Instead of throwing exceptions or returning
/// synthetic fallback types, a guard halts execution or initiates resource disposal,
/// cleanly transitioning the node into the canonical [BloomState.isEmpty] state.
///
/// ### States
/// - [BloomGuard.pass]: Preconditions are satisfied; execution or resource allocation proceeds.
/// - [BloomGuard.block]: Preconditions are unmet; execution is aborted and the node enters an empty state.
///
/// ### Causal Diagnostics ([BloomGuard.reason])
/// When a guard blocks, its associated [reason] payload (e.g. `String`, `Enum`, `Record`) is
/// stored directly into [BloomSnapshot.emptyReason] and [BloomState.emptyReason] with zero boxing overhead.
///
/// ### Examples
///
/// #### 1. Granular Early-Return Pattern:
/// ```dart
/// final checkoutSummary = computed(
///   (via) => calculateCheckout(via(cart), via(address)),
///   guard: (via) {
///     if (via.state(cart).isEmpty) return const BloomGuard.block('CartEmpty');
///     if (via.state(address).isEmpty) return const BloomGuard.block('AddressRequired');
///     return BloomGuard.pass;
///   },
/// );
/// ```
///
/// #### 2. Declarative Boolean Extension:
/// ```dart
/// final userFeed = switched(
///   (via) => via(isAdmin) ? adminFeed : regularFeed,
///   guard: (via) => via(isLoggedIn).guarded('UserNotAuthenticated'),
/// );
/// ```
///
/// #### 3. Multi-Input Record Tuple Guarding (0-Heap):
/// ```dart
/// final combined = computed(
///   (via) => process(via(a), via(b)),
///   guard: (via) => (via.state(a), via.state(b)).guarded('AwaitingInputs'),
/// );
/// ```
sealed class BloomGuard {
  const BloomGuard._();

  /// Canonical diagnostic payload indicating that prerequisites were not satisfied.
  static const String prerequisiteNotMet = 'PrerequisiteNotMet';

  /// Indicates that preconditions are satisfied and execution should proceed.
  static const pass = _PassBloomGuard();

  /// Indicates that preconditions are not satisfied, blocking execution with the specified [reason].
  ///
  /// * [reason]: The diagnostic payload explaining why preconditions were unmet.
  ///
  /// **Ensures:**
  /// * Returns a blocking [BloomGuard] containing [reason].
  const factory BloomGuard.block([Object reason]) = _BlockBloomGuard;

  /// Convenient factory converting a boolean [condition] into [BloomGuard.pass] or [BloomGuard.block].
  ///
  /// * [condition]: The boolean prerequisite expression to evaluate.
  /// * [reason]: The diagnostic payload used when [condition] evaluates to `false`.
  ///
  /// **Ensures:**
  /// * Returns [BloomGuard.pass] when [condition] is `true`, or a blocking [BloomGuard] with [reason] when `false`.
  @pragma('vm:prefer-inline')
  factory BloomGuard(bool condition, [Object reason = prerequisiteNotMet]) =>
      condition ? BloomGuard.pass : BloomGuard.block(reason);

  /// Whether this guard passed, allowing execution to proceed.
  bool get isPass;

  /// Whether this guard blocked execution, transitioning the node into an empty state.
  bool get isBlock => !isPass;

  /// The diagnostic reason or payload associated with a blocked guard, or `null` if passed.
  Object? get reason;
}

/// Zero-cost compile-time extensions converting booleans into [BloomGuard] decisions.
extension BloomBoolGuardExtension on bool {
  /// Converts this boolean to [BloomGuard.pass] if `true`, or [BloomGuard.block] with [reason] if `false`.
  ///
  /// * [reason]: The diagnostic payload used when this boolean evaluates to `false`.
  ///
  /// **Ensures:**
  /// * Returns [BloomGuard.pass] if `this` is `true`, or a blocking [BloomGuard] with [reason] if `false`.
  @pragma('vm:prefer-inline')
  BloomGuard guarded([Object reason = BloomGuard.prerequisiteNotMet]) =>
      this ? BloomGuard.pass : BloomGuard.block(reason);
}

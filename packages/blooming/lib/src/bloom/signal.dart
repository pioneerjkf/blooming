// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// Bloom Signal & Signal Controller (Discrete Event Notification)
// =============================================================================

/// A specialized reactive [Bloom] node representing a discrete event signal.
///
/// Implements [Bloom<int>] by emitting a monotonically increasing dirty version sequence (tick count).
/// Observing this node inside reactive scopes (e.g. `computed`, `effect`, or reactive widget scopes) causes
/// downstream subscribers to re-evaluate whenever the signal is emitted via [BloomSignalController.emit].
///
/// ## System Architectural Flow
/// ```text
/// [User Tap / External Event]
///              │
///              ▼ (signalController.emit())
/// ┌───────────────────────────┐
/// │   BloomSignalController    │ (Producer Handle)
/// └───────────────────────────┘
///              │
///              ▼ (.bloom)
/// ┌───────────────────────────┐
/// │        BloomSignal         │ (Consumer View, implements Bloom<int>)
/// └───────────────────────────┘
///              │
///              ▼ (Explicit Dependency Manifest via BloomVia)
/// ┌────────────────────────────────────────┐ ┌────────────────────────────────┐
/// │ computed.future((via) {                │ │ computed((via) {               │
/// │   via(refreshTrigger.bloom);            │ │   final tick = via(sig.bloom)...│
/// │   return api.fetchUserFeed();          │ │   return 'Event tick #$tick';  │
/// │ });                                    │ │ });                            │
/// └────────────────────────────────────────┘ └────────────────────────────────┘
/// ```
///
/// ## Two Idiomatic Consumption Patterns
///
/// ### Pattern A: Discrete Invalidation / Refetch Trigger (Zero-Data Pulse)
/// When a computation needs to be invalidated or re-evaluated whenever an event occurs,
/// declare the dependency via `via(refreshTrigger.bloom)`:
/// ```dart
/// final refreshTrigger = blooming.signal();
///
/// // Declaratively re-evaluates/refetches whenever `refreshTrigger.emit()` is called:
/// final userFeed = computed.future((via) {
///   via(refreshTrigger.bloom); // Subscribes to discrete event pulse
///   return api.fetchUserFeed();
/// });
/// ```
///
/// ### Pattern B: Explicit Dynamic Read via `BloomVia` (When Tick Count is Needed)
/// When the computation specifically reads or displays the tick sequence number:
/// ```dart
/// final pulseSignal = blooming.signal();
///
/// final pulseCounter = computed((via) {
///   final tick = via(pulseSignal.bloom);
///   return 'Event tick #$tick';
/// });
/// ```
///
/// ## Key Capabilities
/// 1. **Zero-Allocation Version Sequence**: Emits internal sequence ticks (`0 -> 1 -> 2 ...`),
///    guaranteeing that downstream `.distinct()` filters will **never drop** or suppress consecutive pulses.
/// 2. **Producer-Consumer Decoupling**: Emitters hold the [BloomSignalController] handle,
///    while consumers only receive read-only [BloomSignal].
/// 3. **100% LPDAG Integration**: Drop-in compatible with [BloomVia], [Effect], and all pipeline transformations.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT expose [BloomSignalController] directly to public UI layers; expose the read-only [BloomSignalController.bloom] view to prevent arbitrary signal emissions.
/// - Do NOT read signals via `untracked(...)` directly without wrapping in `via(...)`, as untracked reads will miss discrete pulses.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Exposing mutable signal controller handle directly to UI consumers
/// class RefreshService {
///   final refreshSignal = blooming.signal(); // Callers can invoke emit() uncontrollably!
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Encapsulate signal controller and expose read-only BloomSignal
/// class RefreshService {
///   final _refreshSignal = blooming.signal();
///   BloomSignal get refreshSignal => _refreshSignal.bloom;
///
///   void refresh() => _refreshSignal.emit();
/// }
/// ```
///
/// ## Examples
/// ```dart
/// final refreshSignal = blooming.signal();
///
/// final userFeed = computed.future((via) {
///   via(refreshSignal.bloom); // Dynamically tracks signal pulse
///   return fetchFeed();
/// });
///
/// // Trigger refresh
/// refreshSignal.emit();
/// ```
abstract base class BloomSignal implements Bloom<int> {}

/// Producer controller handle for emitting discrete reactive signals.
///
/// Exposes a read-only [bloom] consumer view for downstream observation,
/// completely encapsulating emission capabilities.
abstract base class BloomSignalController implements LpdagStatus {
  /// Private constructor preventing direct instantiation; use `blooming.signal` instead.
  BloomSignalController._();

  /// The encapsulated read-only [BloomSignal] view exposed to downstream consumers.
  BloomSignal get bloom;

  /// Emits a discrete signal pulse, advancing the internal dirty sequence and notifying downstream observers.
  void emit();

  /// Whether this controller's target signal node is currently observed by downstream subscribers.
  @override
  bool get isActive;
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

// =============================================================================
// BloomWidget & Reactive Core Element Hierarchy
// =============================================================================

/// A reactive widget that dynamically and explicitly tracks all [Bloom] dependencies
/// declared via [BloomVia] within [build].
///
/// Seamlessly connects Flutter widget rebuild cycles with Bloom's 2-Phase LPDAG engine
/// using 1-pass zero-allocation epoch diffing. Rather than managing manual streams, listeners,
/// or [ChangeNotifier] subscriptions, dependencies are registered dynamically and explicitly
/// via the injected [BloomVia] parameter in [build].
///
/// ## System Architectural Flow
/// ```text
/// [ Upstream Bloom<T> Mutation ]
///        │
///        │ (Phase 1: 0-Compute Push-Dirty Invalidation)
///        ▼
/// [ RawComputedTerminal<Widget>.onInvalidated: markNeedsBuild() ]
///        │
///        │ (Flutter Engine Frame Pipeline Scheduling)
///        ▼
/// [ BloomElement.rebuild() -> performRebuild() ]
///        │
///        │ (Phase 2: Lazy-Pull Evaluation via terminal.data)
///        ▼
/// ┌────────────────────────────────────────────────────────────┐
/// │ If Clean: Returns cached Widget in O(1) (0-Compute)        │
/// │ If Dirty: Evaluates BloomWidget.build(context, via)         │
/// └────────────────────────────────────────────────────────────┘
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **0-Compute Reactive Memoization**: When upstream state triggers frame invalidation but
///    dependencies resolve to clean (e.g. unchanged distinct intermediates), `terminal.data`
///    returns the cached widget in $O(1)$ without re-evaluating [build].
///    (Note: Ancestor widget rebuilds pass new widget instances through [Element.update], which re-evaluates
///    [build] to honor updated widget parameters; use `const` or `composed.child` for ancestor isolation).
/// 2. **Zero Heap Overhead in Hot Path**: Dynamic edge tracking utilizes 1-pass zero-allocation
///    epoch stamping, avoiding intermediate list allocations during rebuilds.
/// 3. **Dormancy Garbage Collection**: When the widget unmounts, all active graph subscriptions
///    detach synchronously via [RawTerminal.deactivate].
/// 4. **No Stateful Mutators**: [BloomWidget] is intentionally immutable and declarative. Never mutate
///    state synchronously inside [build].
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT read untracked values directly without wrapping in `via(...)`, as untracked reads will not
///   trigger widget rebuilds when state changes.
/// - Do NOT mutate reactive state inside [build], as this triggers reentrancy loops and violates
///   Flutter's rendering contract.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Reading untracked directly bypasses dependency registration
/// class BadCounterWidget extends BloomWidget {
///   BadCounterWidget(this.countBloom, {super.key});
///   final Bloom<int> countBloom;
///
///   @override
///   Widget build(BuildContext context, BloomVia via) {
///     return Text('Count: ${untracked(countBloom)}'); // NEVER rebuilds!
///   }
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Explicitly observe dependencies via BloomVia
/// class GoodCounterWidget extends BloomWidget {
///   GoodCounterWidget(this.countBloom, {super.key});
///   final Bloom<int> countBloom;
///
///   @override
///   Widget build(BuildContext context, BloomVia via) {
///     return Text('Count: ${via(countBloom)}'); // Dynamically tracked
///   }
/// }
/// ```
///
/// ## Examples
/// ```dart
/// // Pure reactive state node:
/// final counter = BloomController(0);
///
/// class CounterPage extends StatelessWidget {
///   const CounterPage({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return CounterView(counterBloom: counter.bloom);
///   }
/// }
///
/// class CounterView extends BloomWidget {
///   const CounterView({required this.counterBloom, super.key});
///   final Bloom<int> counterBloom;
///
///   @override
///   Widget build(BuildContext context, BloomVia via) {
///     return Text('Count: ${via(counterBloom)}');
///   }
/// }
/// ```
abstract base class BloomWidget extends Widget {
  const BloomWidget({super.key});

  @override
  BloomElement createElement() => BloomElement(this);

  /// Describes the part of the user interface represented by this widget, with explicit [BloomVia] tracking.
  ///
  /// * [context]: The active Flutter [BuildContext] representing this widget's location in the element tree.
  /// * [via]: The injected [BloomVia] tracker used to dynamically and explicitly discover reactive dependencies.
  ///
  /// **Requires:**
  /// * [build] must be a pure, declarative function without mutations or unhandled asynchronous scheduling.
  ///
  /// **Ensures:**
  /// * Returns a [Widget] representing the current reactive user interface.
  @protected
  Widget build(BuildContext context, BloomVia via);
}

// =============================================================================
// BloomElement
// =============================================================================

/// The element managing the lifecycle of the reactive [RawComputedTerminal<Widget>] for a [BloomWidget].
///
/// Mixes in `_ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>` and `_ViaTerminalElementMixin`
/// to bridge Flutter element lifecycle hooks ([mount], [activate], [deactivate], [reassemble], [unmount])
/// with the reactive LPDAG terminal sink.
base class BloomElement extends ComponentElement
    with
        _ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>,
        _ViaTerminalElementMixin {
  BloomElement(BloomWidget super.widget);

  @override
  BloomWidget get widget => super.widget as BloomWidget;

  @override
  Widget _buildVia(BloomVia via) => widget.build(this, via);
}

// =============================================================================
// BloomVsyncWidget & BloomVsyncElement
// =============================================================================

/// A reactive widget that dynamically and explicitly tracks [Bloom] dependencies
/// while providing an element-managed Flutter [TickerProvider]
/// for driving animations and tickers without boilerplate.
///
/// Seamlessly pairs [BloomWidget]'s reactive capabilities with element-level [TickerProvider] lifecycle management,
/// ensuring all tickers created via `vsync` are synchronized with [TickerMode] and safely disposed upon unmount.
///
/// ## System Architectural Flow
/// ```text
/// [ Upstream Bloom<T> Mutation ]
///        │
///        │ (Phase 1: 0-Compute Push-Dirty Invalidation)
///        ▼
/// [ RawComputedTerminal<Widget>.onInvalidated: markNeedsBuild() ]
///        │
///        │ (Flutter Engine Frame Pipeline Scheduling)
///        ▼
/// [ BloomVsyncElement.rebuild() -> performRebuild() ]
///        │
///        │ (Phase 2: Lazy-Pull Evaluation via terminal.data)
///        ▼
/// ┌────────────────────────────────────────────────────────────────────────┐
/// │ If Clean: Returns cached Widget in O(1) (0-Compute)                    │
/// │ If Dirty: Evaluates BloomVsyncWidget.build(context, via, vsync)         │
/// └────────────────────────────────────────────────────────────────────────┘
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Zero Stateful Ticker Boilerplate**: Eliminates the need for [StatefulWidget] and [SingleTickerProviderStateMixin].
/// 2. **Immutable Const Contract**: Supports `const` constructors with zero mutable state on the widget instance.
/// 3. **Element-Owned Ticker Lifecycle**: The underlying [BloomVsyncElement] provides [TickerProvider] directly,
///    preventing re-binding hazards and memory leaks across rebuilds.
/// 4. **Automatic Ticker Muting**: Integrates with Flutter's [TickerMode], pausing tickers automatically
///    when routes or tabs are hidden or inactive.
/// 5. **0-Compute Reactive Memoization**: Inherits [RawComputedTerminal] caching to skip [build] re-evaluation when dependencies resolve to clean.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT create raw [AnimationController] instances inside [build] directly, as rebuilding creates new
///   controllers and leaks resources. Use external durable controllers or initialize persistent resources in a ViewModel.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Re-allocating controller resource inside build()
/// Widget build(BuildContext context, BloomVia via, TickerProvider vsync) {
///   final ctrl = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 300)); // Leak!
///   return FadeTransition(opacity: ctrl, child: const Text('Hello'));
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Pass vsync to external components or use composed.animate
/// class TabbedHeaderWidget extends BloomVsyncWidget {
///   const TabbedHeaderWidget({required this.tabIndexBloom, super.key});
///   final Bloom<int> tabIndexBloom;
///
///   @override
///   Widget build(BuildContext context, BloomVia via, TickerProvider vsync) {
///     final tabIndex = via(tabIndexBloom);
///     return DefaultTabController(
///       length: 3,
///       initialIndex: tabIndex,
///       child: const TabBar(tabs: [Tab(text: 'A'), Tab(text: 'B'), Tab(text: 'C')]),
///     );
///   }
/// }
/// ```
///
/// ## Examples
/// ```dart
/// class CustomTickerWidget extends BloomVsyncWidget {
///   const CustomTickerWidget({required this.activeBloom, super.key});
///   final Bloom<bool> activeBloom;
///
///   @override
///   Widget build(BuildContext context, BloomVia via, TickerProvider vsync) {
///     final isActive = via(activeBloom);
///     return Text('Active: $isActive, Vsync: $vsync');
///   }
/// }
/// ```
abstract base class BloomVsyncWidget extends Widget {
  /// Initializes a [BloomVsyncWidget] with an optional [key].
  const BloomVsyncWidget({super.key});

  @override
  BloomVsyncElement createElement() => BloomVsyncElement(this);

  /// Describes the part of the user interface represented by this widget, with explicit [BloomVia] tracking
  /// and an injected [TickerProvider].
  ///
  /// * [context]: The active Flutter [BuildContext] representing this widget's location in the element tree.
  /// * [via]: The injected [BloomVia] tracker used to dynamically and explicitly discover reactive dependencies.
  /// * [vsync]: The element-bound [TickerProvider] used to drive or couple animations.
  ///
  /// **Requires:**
  /// * [build] must be a pure, declarative function without unhandled asynchronous mutations.
  ///
  /// **Ensures:**
  /// * Returns a [Widget] representing the current reactive user interface.
  @protected
  Widget build(
    BuildContext context,
    BloomVia via,
    TickerProvider vsync,
  );
}

/// The element managing both the reactive [RawComputedTerminal<Widget>] and [TickerProvider] lifecycle for a [BloomVsyncWidget].
base class BloomVsyncElement extends ComponentElement
    with
        _TickerProviderElementMixin,
        _ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>,
        _ViaTerminalElementMixin {
  /// Creates a [BloomVsyncElement] managing [widget].
  BloomVsyncElement(BloomVsyncWidget super.widget);

  @override
  BloomVsyncWidget get widget => super.widget as BloomVsyncWidget;

  @override
  Widget _buildVia(BloomVia via) => widget.build(this, via, this);
}

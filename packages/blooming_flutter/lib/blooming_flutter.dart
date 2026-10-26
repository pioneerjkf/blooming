// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
/// @docImport 'package:blooming/blooming.dart';
/// @docImport 'framework.dart';
///
/// High-performance reactive Flutter framework connecting Bloom's 2-Phase LPDAG engine with the Flutter element tree.
///
/// `blooming_flutter` embeds reactive [RawComputedTerminal] and [RawBloomTerminal] boundary sinks
/// directly into specialized lightweight [Element]s, enabling surgical micro-rebuilds,
/// declarative auto-tracked widgets, zero-boilerplate animations, and leak-free lifecycle-bound state management.
///
/// ## Architectural Overview
///
/// In standard Flutter development, state changes frequently trigger wide subtree rebuilds,
/// leading to frame drops and redundant widget evaluations. `blooming_flutter` solves this by
/// embedding reactive terminals into [Element] nodes via `_ReactiveTerminalElementMixin`.
///
/// Under the 2-Phase LPDAG architecture:
/// 1. **Phase 1: Push-Dirty (Lightweight Invalidation)**: When an upstream [Bloom] mutates, dirty notifications propagate
///    topologically to leaf terminals, triggering [Element.markNeedsBuild] without recomputing values.
/// 2. **Phase 2: Lazy-Pull (On-Demand Evaluation)**: During Flutter's render pipeline, only the exact invalidated leaf elements
///    pull and evaluate their dependencies inside [RawComputedTerminal.data], leaving the surrounding
///    widget tree completely untouched.
///
/// ## System Architectural Flow
/// ```text
/// ┌────────────────────────────────────────────────────────────────────────────┐
/// │                         Flutter Widget Tree Layer                          │
/// │                                                                            │
/// │   • BloomWidget                           : Auto-tracked Flutter widgets    │
/// │   • BloomAnimatedWidget                   : Class-based durable animations  │
/// │   • BloomProvider                         : Scoped DI with rebuild block    │
/// │   • composed((context, via) => ...)      : Surgical inline micro-rebuild   │
/// │   • bloom.build(...)                     : Direct reactive node builders   │
/// │   • composed.animate                     : 60/120fps frame-isolated motion │
/// │   • composed.drive                       : Continuous frame-ticker drivers │
/// └─────────────────────────────────────┬──────────────────────────────────────┘
///                                       │ (1-Pass Zero-Alloc Epoch Diffing / Element Binding)
///                                       ▼
/// ┌────────────────────────────────────────────────────────────────────────────┐
/// │                Flutter Element Patching Layer (Terminal Mixins)            │
/// │                                                                            │
/// │   • _ReactiveTerminalElementMixin        : Mount/Activate/Deactivate sync  │
/// │   • _ViaTerminalElementMixin             : Dynamic branch sink             │
/// │   • _BloomTerminalElementMixin            : 1:1 direct single-source sink   │
/// └─────────────────────────────────────┬──────────────────────────────────────┘
///                                       │ (Push-Dirty Invalidation / Lazy-Pull Evaluation)
///                                       ▼
/// ┌────────────────────────────────────────────────────────────────────────────┐
/// │                    Bloom Topological 2-Phase LPDAG Core                    │
/// │                                                                            │
/// │   • Bloom<T> / BloomController<T>          : Canonical state nodes           │
/// │   • computed                             : Pure memoized derived state     │
/// │   • RawComputedTerminal / RawBloomTerminal: Boundary sinks & dirty routers  │
/// └────────────────────────────────────────────────────────────────────────────┘
/// ```
///
/// ## Quick Start
///
/// ### 1. Surgical Inline Micro-Rebuilds (`composed`)
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:blooming_flutter/blooming_flutter.dart';
///
/// final counter = blooming(0);
///
/// class CounterPage extends StatelessWidget {
///   const CounterPage({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Column(
///         children: [
///           const HeavyHeaderWidget(), // NEVER rebuilds when counter changes!
///           // ONLY this Text rebuilds:
///           composed((context, via) => Text('Count: ${via(counter.bloom)}')),
///         ],
///       ),
///       floatingActionButton: FloatingActionButton(
///         onPressed: () => counter.data++,
///         child: const Icon(Icons.add),
///       ),
///     );
///   }
/// }
/// ```
///
/// ### 2. Declarative Reactive Widgets (`BloomWidget`)
/// ```dart
/// class UserProfileWidget extends BloomWidget {
///   UserProfileWidget({required this.userBloom, super.key});
///   final Bloom<User> userBloom;
///
///   @override
///   Widget build(BuildContext context, BloomVia via) {
///     final user = via(userBloom);
///     return Text('User: ${user.name}');
///   }
/// }
/// ```
///
/// **Warning (Anti-Pattern Prevention):**
/// - Do NOT execute state mutations inside a `build()` method or within an active
///   reactive evaluation pass. Mutations during build violate Flutter's single-pass
///   layout/render contract and trigger reentrancy exceptions.
/// - Do NOT access `untracked(...)` directly inside [BloomWidget.build] or `composed` without wrapping
///   in `via(...)`. Directly calling `untracked(...)` bypasses dependency registration.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Reading untracked without via() inside composed
/// Widget build(BuildContext context) {
///   return composed((context, via) => Text('${untracked(counter.bloom)}')); // Not tracked!
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Explicitly observe via(node)
/// Widget build(BuildContext context) {
///   return composed((context, via) => Text('${via(counter.bloom)}')); // Dynamically tracked
/// }
/// ```
library;

export 'package:blooming/blooming.dart';
export 'package:blooming/effect.dart';
export 'framework.dart' hide DurableAnimationTestingExtension, TestDurableVSync;

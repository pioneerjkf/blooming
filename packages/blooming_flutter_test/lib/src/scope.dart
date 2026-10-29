// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

// =============================================================================
// BloomTestScope & BloomOverride (Scoped Widget Mocking System)
// =============================================================================

/// An immutable declarative override mapping that injects a mock or replacement
/// [Bloom] into descendant widget subtrees via [BloomProvider].
final class BloomOverride<T> {
  /// Creates a [BloomOverride] supplying [replacement] to descendant widgets.
  ///
  /// * [replacement]: The mock or replacement [Bloom] node to supply into the widget subtree.
  /// * [target]: Optional original [Bloom] node being overridden.
  const BloomOverride({
    required this.replacement,
    this.target,
  });

  /// The mock or replacement [Bloom] node to supply into the widget subtree.
  final Bloom<T> replacement;

  /// The original [Bloom] node being overridden, if specified.
  final Bloom<T>? target;

  /// Wraps [child] in a [BloomProvider] providing this replacement node.
  ///
  /// * [child]: The descendant widget subtree to wrap.
  Widget wrap(Widget child) =>
      BloomProvider<T>(bloom: replacement, child: child);
}

/// Fluent extensions on [Bloom] for creating [BloomOverride] instances in widget tests.
extension BloomOverrideExtension<T> on Bloom<T> {
  /// Overrides this node's type with a static constant [value].
  ///
  /// * [value]: The static constant payload to inject.
  BloomOverride<T> overrideWithValue(T value) =>
      BloomOverride<T>(target: this, replacement: Bloom.constant(value));

  /// Overrides this node's type with another reactive [bloom] node.
  ///
  /// * [bloom]: The replacement [Bloom] node to inject.
  BloomOverride<T> overrideWithBloom(Bloom<T> bloom) =>
      BloomOverride<T>(target: this, replacement: bloom);

  /// Overrides this node's type with a permanent error state.
  ///
  /// * [error]: The error or exception object to inject.
  /// * [stackTrace]: Optional stack trace associated with [error].
  BloomOverride<T> overrideWithError(Object error, [StackTrace? stackTrace]) =>
      BloomOverride<T>(
          target: this, replacement: Bloom.error(error, stackTrace));

  /// Overrides this node's type with an empty state and optional [reason].
  ///
  /// * [reason]: Optional diagnostic reason explaining why the overridden state is empty.
  BloomOverride<T> overrideWithEmpty([Object? reason]) =>
      BloomOverride<T>(target: this, replacement: Bloom.empty(reason));

  /// Converts this [Bloom] node directly into a [BloomOverride] for [T].
  BloomOverride<T> asOverride() => BloomOverride<T>(replacement: this);
}

/// A scoped testing widget that dynamically wraps descendant widgets with a cascade
/// of [BloomProvider] nodes matching [overrides].
///
/// Any descendant [BloomWidget] reading state via `via.of<T>(context)` or
/// `context.bloomOf<T>()` will automatically receive the mock node specified in [overrides].
///
/// ## Examples
/// ```dart
/// await tester.pumpWidget(
///   BloomTestScope(
///     overrides: [
///       userListBloom.overrideWithError(SocketException('Offline')),
///     ],
///     child: const MaterialApp(home: UserScreen()),
///   ),
/// );
/// ```
class BloomTestScope extends StatelessWidget {
  /// Creates a [BloomTestScope] injecting [overrides] into [child].
  ///
  /// * [key]: Optional widget key.
  /// * [overrides]: The list of state overrides to apply to descendant widgets.
  /// * [child]: The descendant widget subtree receiving the overridden states.
  const BloomTestScope({
    super.key,
    required this.overrides,
    required this.child,
  });

  /// The list of state overrides to apply to descendant widgets.
  final List<BloomOverride> overrides;

  /// The descendant widget subtree receiving the overridden states.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget current = child;
    for (final override in overrides.reversed) {
      current = override.wrap(current);
    }
    return current;
  }
}

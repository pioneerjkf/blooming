// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

// =============================================================================
// BloomProvider<T> & Scoped State Provision System
// =============================================================================

/// An [InheritedWidget] providing a reactive [Bloom<T>] node to descendant widgets with rebuild wave suppression.
///
/// In standard Flutter development, updating inherited widget state triggers wide subtree rebuilds across
/// all dependent elements. `BloomProvider` eliminates these rebuild storms by decoupling structural element
/// scoping from reactive state propagation:
/// * [updateShouldNotify] only returns `true` if the underlying [bloom] node reference itself changes (`!identical`).
/// * Descendant widgets observe state via `via.of<T>(context)` or `via(context.bloomOf<T>())`.
/// * Mutations to the [Bloom] node's payload propagate surgically through Bloom's 2-Phase LPDAG engine directly
///   to leaf terminals, leaving intermediate and sibling widgets completely untouched.
///
/// ## System Architectural Flow
/// ```text
/// ┌────────────────────────────────────────────────────────────────────────┐
/// │                    BloomProvider Element Architecture                   │
/// ├────────────────────────────────────────────────────────────────────────┤
/// │                                                                        │
/// │   [ BloomProvider<T>(bloom: myBloom) ] ── (InheritedWidget In Element Tree)
/// │                  │                                                     │
/// │                  │ (updateShouldNotify returns !identical(old, new))   │
/// │                  ▼                                                     │
/// │   [ Intermediate Static Widgets ]  ──► Bypasses Rebuilds (0 Rebuilds!) │
/// │                  │                                                     │
/// │                  ▼                                                     │
/// │   [ Descendant BloomWidget / composed ]                                 │
/// │                  │                                                     │
/// │                  ├─► context.bloomOf<T>()    ──► Fetches Bloom<T> node   │
/// │                  └─► via.of<T>(context)     ──► Registers in 2-Phase   │
/// │                                                 LPDAG (Leaf Only Rebuild)
/// │                                                                        │
/// └────────────────────────────────────────────────────────────────────────┘
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Zero Subtree Rebuild Storms**: State mutations inside [bloom] never trigger wide `InheritedWidget` rebuild passes.
/// 2. **Surgical Leaf Rebuilds**: Only widgets explicitly observing the state via [BloomVia] are invalidated (Rebuild Scope: Leaf Only).
/// 3. **Sound Scoped Discovery**: Seamless context lookup via [BloomBuildContextProviderExtension.bloomOf]
///    and [BloomViaContextExtension.of].
/// 4. **Exact Type Resolution**: InheritedWidget resolution relies on exact reified type keys (`BloomProvider<T>`).
///    Subtypes or base classes do not match automatically. If polymorphic consumption is needed,
///    explicitly provision as the base type (e.g. `BloomProvider<FooBase>(bloom: fooBloom)`).
///
/// **Warning (Anti-Pattern Prevention):**
/// - Avoid wrapping transient subtrees with new [BloomProvider] instances repeatedly in build methods
///   with newly constructed [Bloom] nodes, which forces tree replacement.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] New controller instantiated per frame in provider
/// Widget build(BuildContext context) {
///   return BloomProvider(bloom: blooming(0).bloom, child: const ChildWidget());
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Provide stable cached state
/// class FeaturePage extends StatelessWidget {
///   FeaturePage({super.key});
///   final counter = blooming(0);
///
///   @override
///   Widget build(BuildContext context) {
///     return BloomProvider<int>(bloom: counter.bloom, child: const CounterDisplay());
///   }
/// }
/// ```
///
/// ## Examples
/// ```dart
/// // Providing state at an ancestor level
/// BloomProvider<CounterState>(
///   bloom: counterController.bloom,
///   child: const CounterDisplay(),
/// );
///
/// // Consuming in a descendant BloomWidget
/// base class CounterDisplay extends BloomWidget {
///   const CounterDisplay({super.key});
///
///   @override
///   Widget build(BuildContext context, BloomVia via) {
///     final state = via.of<CounterState>(context);
///     return Text('Count: ${state.count}');
///   }
/// }
/// ```
class BloomProvider<T> extends InheritedWidget {
  /// Creates a [BloomProvider] binding [bloom] into the widget subtree.
  ///
  /// * [bloom]: The reactive state carrier node to provide.
  /// * [child]: The descendant widget subtree that can query this state.
  /// * [key]: Optional widget key.
  ///
  /// **Requires:**
  /// * [bloom] and [child] must not be null.
  ///
  /// **Ensures:**
  /// * Provisions [bloom] to descendants with forced rebuild suppression.
  const BloomProvider({
    super.key,
    required this.bloom,
    required super.child,
  });

  /// The provided reactive state carrier node.
  final Bloom<T> bloom;

  /// Returns `true` only if the [bloom] node reference has changed.
  @override
  bool updateShouldNotify(covariant BloomProvider<T> oldWidget) {
    return !identical(oldWidget.bloom, bloom);
  }

  /// Retrieves the [Bloom<T>] state from the nearest ancestor [BloomProvider<T>].
  ///
  /// * [context]: The active [BuildContext] to search upwards from.
  ///
  /// **Exact Type Resolution:**
  /// * Lookup matches the exact reified type [T]. Subtypes or base classes do not match.
  ///
  /// **Requires:**
  /// * An ancestor [BloomProvider<T>] must exist in the [context] hierarchy.
  ///
  /// **Ensures:**
  /// * Returns the nearest ancestor [Bloom<T>] node.
  ///
  /// **Throws:**
  /// * Throws [FlutterError] in all build modes if no matching [BloomProvider<T>] is found.
  static Bloom<T> of<T>(BuildContext context) => context.bloomOf<T>();

  /// Retrieves the [Bloom<T?>] state from the nearest ancestor [BloomProvider<T>], if present.
  ///
  /// * [context]: The active [BuildContext] to search upwards from.
  ///
  /// **Exact Type Resolution:**
  /// * Lookup matches the exact reified type [T]. Subtypes or base classes do not match.
  ///
  /// **Ensures:**
  /// * Returns the ancestor provider's [Bloom<T>], or [Bloom.constantNull] if no matching ancestor provider exists.
  static Bloom<T?> maybeOf<T>(BuildContext context) =>
      context.maybeBloomOf<T>();
}

/// A convenience extension for converting a [Bloom] into a [BloomProvider].
extension BloomProvideExtension<T> on Bloom<T> {
  /// Wraps [child] in a [BloomProvider<T>] providing this reactive [Bloom] node.
  ///
  /// * [child]: The descendant widget subtree receiving this state.
  /// * [key]: Optional widget key.
  ///
  /// **Requires:**
  /// * [child] must not be null.
  ///
  /// **Ensures:**
  /// * Returns a [BloomProvider<T>] embedding this reactive [Bloom] node.
  ///
  /// ## Examples
  /// ```dart
  /// counterBloom.provide(child: const CounterDisplay());
  /// ```
  BloomProvider<T> provide({Key? key, required Widget child}) =>
      BloomProvider<T>(key: key, bloom: this, child: child);
}

/// Context-aware reactive lookup extensions on [BuildContext] for [BloomProvider].
extension BloomBuildContextProviderExtension on BuildContext {
  /// Reactively subscribes to an ancestor [BloomProvider] and returns its inner [Bloom<T>] state.
  ///
  /// **Exact Type Resolution:**
  /// Lookup matches the exact reified type [T]. Subtypes or base classes do not match
  /// (e.g., `BloomProvider<Dog>` cannot be resolved via `context.bloomOf<Animal>()`).
  /// To query by a base class or interface, explicitly provision as `BloomProvider<Animal>`.
  ///
  /// **Requires:**
  /// * An ancestor [BloomProvider] of type [T] must exist in the widget tree when evaluated.
  ///
  /// **Ensures:**
  /// * Registers this [BuildContext] as a dependent on the ancestor [BloomProvider]
  ///   and returns its inner [Bloom] reactive node.
  ///
  /// **Throws:**
  /// * Throws [FlutterError] in all build modes if no matching [BloomProvider] is found in the current hierarchy.
  ///
  /// ## Examples
  /// ```dart
  /// final counterBloom = context.bloomOf<int>();
  /// ```
  @pragma('vm:prefer-inline')
  Bloom<T> bloomOf<T>() {
    final provider = dependOnInheritedWidgetOfExactType<BloomProvider<T>>();
    if (provider == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            'No ancestor BloomProvider<$T> found in the current BuildContext hierarchy.'),
        ErrorDescription(
          'BuildContext.bloomOf<$T>() was called with a context that does not contain '
          'a BloomProvider<$T> ancestor.\n'
          'Lookup is strictly by exact runtime type ($T). InheritedWidget resolution does '
          'not match subtypes or base classes (e.g., BloomProvider<Foo> cannot be resolved as FooBase).',
        ),
        ErrorHint(
          'Ensure that a BloomProvider<$T> is mounted above this widget in the widget tree, '
          'or use context.maybeBloomOf<$T>() if the provider is optional. '
          'If providing a subclass for a base class interface, provide it explicitly as '
          'BloomProvider<$T>(bloom: instance).',
        ),
        describeElement('The context used was'),
      ]);
    }
    return provider.bloom;
  }

  /// Reactively subscribes to an optional ancestor [BloomProvider] and returns its inner [Bloom] state.
  ///
  /// **Exact Type Resolution:**
  /// Lookup matches the exact reified type [T]. Subtypes or base classes do not match.
  ///
  /// **Ensures:**
  /// * Returns the ancestor provider's [Bloom], or [Bloom.constantNull] if no matching ancestor provider exists.
  ///
  /// ## Examples
  /// ```dart
  /// final optionalTheme = context.maybeBloomOf<AppTheme>();
  /// ```
  @pragma('vm:prefer-inline')
  Bloom<T?> maybeBloomOf<T>() {
    final provider = dependOnInheritedWidgetOfExactType<BloomProvider<T>>();
    return provider?.bloom ?? Bloom.constantNull;
  }
}

/// Context-aware reactive observation extensions on [BloomVia] for [BloomProvider].
extension BloomViaContextExtension on BloomVia {
  /// Reactively discovers and observes an ancestor [BloomProvider<T>] within [context].
  ///
  /// Connects [BloomBuildContextProviderExtension.bloomOf] with this [BloomVia] tracking scope in a single,
  /// fluent call, eliminating nested `via(context.bloomOf<T>())` boilerplate.
  ///
  /// * [context]: The active [BuildContext] to locate the ancestor provider from.
  ///
  /// **Exact Type Resolution:**
  /// * Lookup matches the exact reified type [T]. Subtypes or base classes do not match.
  ///
  /// **Requires:**
  /// * An ancestor [BloomProvider<T>] must exist in the [context] widget tree.
  ///
  /// **Ensures:**
  /// * Subscribes this reactive tracking scope to the ancestor [Bloom<T>] node.
  /// * Returns the underlying value of type [T].
  ///
  /// ## Examples
  /// ```dart
  /// @override
  /// Widget build(BuildContext context, BloomVia via) {
  ///   final store = via.of<ShowcaseStore>(context);
  ///   return Text(store.title);
  /// }
  /// ```
  @pragma('vm:prefer-inline')
  T of<T>(BuildContext context) => this(context.bloomOf<T>());

  /// Reactively discovers and observes an optional ancestor [BloomProvider<T>] within [context].
  ///
  /// Connects [BloomBuildContextProviderExtension.maybeBloomOf] with this [BloomVia] tracking scope in a single,
  /// fluent call, eliminating nested `via(context.maybeBloomOf<T>())` boilerplate.
  ///
  /// * [context]: The active [BuildContext] to locate the ancestor provider from.
  ///
  /// **Exact Type Resolution:**
  /// * Lookup matches the exact reified type [T]. Subtypes or base classes do not match.
  ///
  /// **Ensures:**
  /// * Subscribes this reactive tracking scope to the ancestor [Bloom<T?>] node if found,
  ///   or [Bloom.constantNull] if no matching provider exists.
  /// * Returns the underlying value of type [T?].
  ///
  /// ## Examples
  /// ```dart
  /// @override
  /// Widget build(BuildContext context, BloomVia via) {
  ///   final theme = via.maybeOf<AppTheme>(context);
  ///   return Text(theme?.name ?? 'Default');
  /// }
  /// ```
  @pragma('vm:prefer-inline')
  T? maybeOf<T>(BuildContext context) => this(context.maybeBloomOf<T>());
}

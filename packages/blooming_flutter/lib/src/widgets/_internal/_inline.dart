// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../framework.dart';

// =============================================================================
// Internal Inline Reactive Widgets (ComponentElement Backing)
// =============================================================================

/// Internal reactive widget backing single [Bloom] `(context, data)` extensions.
final class _InlineSingleBloomWidget<T> extends Widget {
  const _InlineSingleBloomWidget({
    super.key,
    required this.bloom,
    required this.builder,
  });

  final Bloom<T> bloom;
  final Widget Function(BuildContext context, T data) builder;

  @override
  _InlineSingleBloomElement<T> createElement() =>
      _InlineSingleBloomElement<T>(this);
}

/// Element managing the 1:1 [RawBloomTerminal] for an [_InlineSingleBloomWidget].
final class _InlineSingleBloomElement<T> extends ComponentElement
    with
        _ReactiveTerminalElementMixin<RawBloomTerminal<T>>,
        _BloomTerminalElementMixin<T> {
  _InlineSingleBloomElement(_InlineSingleBloomWidget<T> super.widget);

  @override
  _InlineSingleBloomWidget<T> get widget =>
      super.widget as _InlineSingleBloomWidget<T>;

  @override
  Bloom<T> get _sourceBloom => widget.bloom;

  @override
  Widget build() => widget.builder(this, untracked(widget.bloom));
}

/// Internal reactive widget backing single [Bloom] `(context, data, child)` extensions.
final class _InlineSingleBloomWithChildWidget<T> extends Widget {
  const _InlineSingleBloomWithChildWidget({
    super.key,
    required this.bloom,
    required this.builder,
    required this.child,
  });

  final Bloom<T> bloom;
  final Widget Function(BuildContext context, T data, Widget child) builder;
  final Widget child;

  @override
  _InlineSingleBloomWithChildElement<T> createElement() =>
      _InlineSingleBloomWithChildElement<T>(this);
}

/// Element managing the 1:1 [RawBloomTerminal] with cached child fallback for an [_InlineSingleBloomWithChildWidget].
final class _InlineSingleBloomWithChildElement<T> extends ComponentElement
    with
        _ReactiveTerminalElementMixin<RawBloomTerminal<T>>,
        _BloomTerminalElementMixin<T> {
  _InlineSingleBloomWithChildElement(
      _InlineSingleBloomWithChildWidget<T> super.widget);

  @override
  _InlineSingleBloomWithChildWidget<T> get widget =>
      super.widget as _InlineSingleBloomWithChildWidget<T>;

  @override
  Bloom<T> get _sourceBloom => widget.bloom;

  @override
  Widget build() {
    if (!untracked.state(widget.bloom).hasData) {
      return widget.child;
    }
    return widget.builder(this, untracked(widget.bloom), widget.child);
  }
}

/// Internal reactive widget backing single [Bloom] `(context, data, children)` extensions.
final class _InlineSingleBloomWithChildrenWidget<T> extends Widget {
  const _InlineSingleBloomWithChildrenWidget({
    super.key,
    required this.bloom,
    required this.builder,
    required this.children,
  });

  final Bloom<T> bloom;
  final Widget Function(BuildContext context, T data, List<Widget> children)
      builder;
  final List<Widget> children;

  @override
  _InlineSingleBloomWithChildrenElement<T> createElement() =>
      _InlineSingleBloomWithChildrenElement<T>(this);
}

/// Element managing the 1:1 [RawBloomTerminal] with cached children for an [_InlineSingleBloomWithChildrenWidget].
final class _InlineSingleBloomWithChildrenElement<T> extends ComponentElement
    with
        _ReactiveTerminalElementMixin<RawBloomTerminal<T>>,
        _BloomTerminalElementMixin<T> {
  _InlineSingleBloomWithChildrenElement(
      _InlineSingleBloomWithChildrenWidget<T> super.widget);

  @override
  _InlineSingleBloomWithChildrenWidget<T> get widget =>
      super.widget as _InlineSingleBloomWithChildrenWidget<T>;

  @override
  Bloom<T> get _sourceBloom => widget.bloom;

  @override
  Widget build() {
    if (!untracked.state(widget.bloom).hasData) {
      return const SizedBox.shrink();
    }
    return widget.builder(this, untracked(widget.bloom), widget.children);
  }
}

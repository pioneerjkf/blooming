// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../framework.dart';

// =============================================================================
// Section 1: Standard Reactive Composed Widgets & Elements (RawComputedTerminal Backed)
// =============================================================================

/// Internal reactive widget backing `composed((context, via) => ...)`.
final class _ComposedWidget extends Widget {
  const _ComposedWidget(this.builder, {super.key});

  final Widget Function(BuildContext context, BloomVia via) builder;

  @override
  _ComposedElement createElement() => _ComposedElement(this);
}

/// The element managing the reactive [RawComputedTerminal<Widget>] for a [_ComposedWidget].
final class _ComposedElement extends ComponentElement
    with
        _ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>,
        _ViaTerminalElementMixin {
  _ComposedElement(_ComposedWidget super.widget);

  @override
  _ComposedWidget get widget => super.widget as _ComposedWidget;

  @override
  Widget _buildVia(BloomVia via) => widget.builder(this, via);
}

/// Internal reactive widget backing `composed.child((context, via, child) => ..., child: ...)`.
final class _ComposedWithChildWidget extends Widget {
  const _ComposedWithChildWidget({
    required this.builder,
    required this.child,
    super.key,
  });

  final Widget Function(BuildContext context, BloomVia via, Widget child)
      builder;
  final Widget child;

  @override
  _ComposedWithChildElement createElement() => _ComposedWithChildElement(this);
}

final class _ComposedWithChildElement extends ComponentElement
    with
        _ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>,
        _ViaTerminalElementMixin {
  _ComposedWithChildElement(_ComposedWithChildWidget super.widget);

  @override
  _ComposedWithChildWidget get widget =>
      super.widget as _ComposedWithChildWidget;

  @override
  Widget _buildVia(BloomVia via) => widget.builder(this, via, widget.child);
}

/// Internal reactive widget backing `composed.children((context, via, children) => ..., children: ...)`.
final class _ComposedWithChildrenWidget extends Widget {
  const _ComposedWithChildrenWidget({
    required this.builder,
    required this.children,
    super.key,
  });

  final Widget Function(
      BuildContext context, BloomVia via, List<Widget> children) builder;
  final List<Widget> children;

  @override
  _ComposedWithChildrenElement createElement() =>
      _ComposedWithChildrenElement(this);
}

final class _ComposedWithChildrenElement extends ComponentElement
    with
        _ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>,
        _ViaTerminalElementMixin {
  _ComposedWithChildrenElement(_ComposedWithChildrenWidget super.widget);

  @override
  _ComposedWithChildrenWidget get widget =>
      super.widget as _ComposedWithChildrenWidget;

  @override
  Widget _buildVia(BloomVia via) => widget.builder(this, via, widget.children);
}

// =============================================================================
// Section 2: VSYNC Provider Composed Widgets & Elements
// =============================================================================

/// Internal reactive widget backing `composed.vsync((context, via, vsync) => ...)`.
final class _ComposedVsyncWidget extends Widget {
  const _ComposedVsyncWidget(this.builder, {super.key});

  final Widget Function(
      BuildContext context, BloomVia via, TickerProvider vsync) builder;

  @override
  _ComposedVsyncElement createElement() => _ComposedVsyncElement(this);
}

final class _ComposedVsyncElement extends ComponentElement
    with
        _TickerProviderElementMixin,
        _ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>,
        _ViaTerminalElementMixin {
  _ComposedVsyncElement(_ComposedVsyncWidget super.widget);

  @override
  _ComposedVsyncWidget get widget => super.widget as _ComposedVsyncWidget;

  @override
  Widget _buildVia(BloomVia via) => widget.builder(this, via, this);
}

/// Internal reactive widget backing `composed.vsync.child(...)`.
final class _ComposedVsyncWithChildWidget extends Widget {
  const _ComposedVsyncWithChildWidget({
    required this.builder,
    required this.child,
    super.key,
  });

  final Widget Function(BuildContext context, BloomVia via,
      TickerProvider vsync, Widget child) builder;
  final Widget child;

  @override
  _ComposedVsyncWithChildElement createElement() =>
      _ComposedVsyncWithChildElement(this);
}

final class _ComposedVsyncWithChildElement extends ComponentElement
    with
        _TickerProviderElementMixin,
        _ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>,
        _ViaTerminalElementMixin {
  _ComposedVsyncWithChildElement(_ComposedVsyncWithChildWidget super.widget);

  @override
  _ComposedVsyncWithChildWidget get widget =>
      super.widget as _ComposedVsyncWithChildWidget;

  @override
  Widget _buildVia(BloomVia via) =>
      widget.builder(this, via, this, widget.child);
}

/// Internal reactive widget backing `composed.vsync.children(...)`.
final class _ComposedVsyncWithChildrenWidget extends Widget {
  const _ComposedVsyncWithChildrenWidget({
    required this.builder,
    required this.children,
    super.key,
  });

  final Widget Function(BuildContext context, BloomVia via,
      TickerProvider vsync, List<Widget> children) builder;
  final List<Widget> children;

  @override
  _ComposedVsyncWithChildrenElement createElement() =>
      _ComposedVsyncWithChildrenElement(this);
}

final class _ComposedVsyncWithChildrenElement extends ComponentElement
    with
        _TickerProviderElementMixin,
        _ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>,
        _ViaTerminalElementMixin {
  _ComposedVsyncWithChildrenElement(
      _ComposedVsyncWithChildrenWidget super.widget);

  @override
  _ComposedVsyncWithChildrenWidget get widget =>
      super.widget as _ComposedVsyncWithChildrenWidget;

  @override
  Widget _buildVia(BloomVia via) =>
      widget.builder(this, via, this, widget.children);
}

// =============================================================================
// Section 3: Controller-Driven Animate Composed Widgets & Elements
// =============================================================================

/// Internal reactive widget backing `composed.animate(...)`.
final class _ComposedAnimateWidget extends Widget {
  const _ComposedAnimateWidget({
    super.key,
    required this.controller,
    required this.builder,
  });

  final DurableAnimationController controller;
  final Widget Function(BuildContext context, BloomVia via,
      ScopedAnimationController controller) builder;

  @override
  _ComposedAnimateElement createElement() => _ComposedAnimateElement(this);
}

final class _ComposedAnimateElement extends ComponentElement
    with
        _ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>,
        _ViaTerminalElementMixin,
        _DurableVsyncSocketElementMixin {
  _ComposedAnimateElement(_ComposedAnimateWidget super.widget);

  @override
  _ComposedAnimateWidget get widget => super.widget as _ComposedAnimateWidget;

  @override
  DurableAnimationController get _controller => widget.controller;

  @override
  Widget _buildVia(BloomVia via) =>
      widget.builder(this, via, _scopedController);
}

/// Internal reactive widget backing `composed.animate.child(...)`.
final class _ComposedAnimateWithChildWidget extends Widget {
  const _ComposedAnimateWithChildWidget({
    super.key,
    required this.controller,
    required this.builder,
    required this.child,
  });

  final DurableAnimationController controller;
  final Widget Function(BuildContext context, BloomVia via,
      ScopedAnimationController controller, Widget child) builder;
  final Widget child;

  @override
  _ComposedAnimateWithChildElement createElement() =>
      _ComposedAnimateWithChildElement(this);
}

final class _ComposedAnimateWithChildElement extends ComponentElement
    with
        _ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>,
        _ViaTerminalElementMixin,
        _DurableVsyncSocketElementMixin {
  _ComposedAnimateWithChildElement(
      _ComposedAnimateWithChildWidget super.widget);

  @override
  _ComposedAnimateWithChildWidget get widget =>
      super.widget as _ComposedAnimateWithChildWidget;

  @override
  DurableAnimationController get _controller => widget.controller;

  @override
  Widget _buildVia(BloomVia via) =>
      widget.builder(this, via, _scopedController, widget.child);
}

/// Internal reactive widget backing `composed.animate.children(...)`.
final class _ComposedAnimateWithChildrenWidget extends Widget {
  const _ComposedAnimateWithChildrenWidget({
    super.key,
    required this.controller,
    required this.builder,
    required this.children,
  });

  final DurableAnimationController controller;
  final Widget Function(BuildContext context, BloomVia via,
      ScopedAnimationController controller, List<Widget> children) builder;
  final List<Widget> children;

  @override
  _ComposedAnimateWithChildrenElement createElement() =>
      _ComposedAnimateWithChildrenElement(this);
}

final class _ComposedAnimateWithChildrenElement extends ComponentElement
    with
        _ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>,
        _ViaTerminalElementMixin,
        _DurableVsyncSocketElementMixin {
  _ComposedAnimateWithChildrenElement(
      _ComposedAnimateWithChildrenWidget super.widget);

  @override
  _ComposedAnimateWithChildrenWidget get widget =>
      super.widget as _ComposedAnimateWithChildrenWidget;

  @override
  DurableAnimationController get _controller => widget.controller;

  @override
  Widget _buildVia(BloomVia via) =>
      widget.builder(this, via, _scopedController, widget.children);
}

// =============================================================================
// Section 4: Frame Ticker Drive Composed Widgets & Elements
// =============================================================================

/// Internal reactive widget backing `composed.drive(...)`.
final class _ComposedDriveWidget<T> extends Widget {
  const _ComposedDriveWidget({
    required this.onTick,
    required this.builder,
    super.key,
  });

  final T Function(Duration elapsed) onTick;
  final Widget Function(BuildContext context, BloomVia via, T value) builder;

  @override
  _ComposedDriveElement<T> createElement() => _ComposedDriveElement<T>(this);
}

final class _ComposedDriveElement<T> extends ComponentElement
    with
        _TickerProviderElementMixin,
        _ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>,
        _ViaTerminalElementMixin {
  _ComposedDriveElement(_ComposedDriveWidget<T> super.widget);

  @override
  _ComposedDriveWidget<T> get widget => super.widget as _ComposedDriveWidget<T>;

  late final _driver = _TickerDriver<T>(
    this,
    onTick: (elapsed) => widget.onTick(elapsed),
  );

  @override
  Widget _buildVia(BloomVia via) {
    final value = via(_driver.bloom);
    return widget.builder(this, via, value);
  }

  @override
  void update(covariant _ComposedDriveWidget<T> newWidget) {
    super.update(newWidget);
    rebuild(force: true);
  }

  @override
  void unmount() {
    try {
      _driver.dispose();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'blooming_flutter',
          context: ErrorDescription('while unmounting _ComposedDriveElement'),
        ),
      );
    }
    super.unmount();
  }
}

/// Internal reactive widget backing `composed.drive.child(...)`.
final class _ComposedDriveWithChildWidget<T> extends Widget {
  const _ComposedDriveWithChildWidget({
    required this.onTick,
    required this.builder,
    required this.child,
    super.key,
  });

  final T Function(Duration elapsed) onTick;
  final Widget Function(
      BuildContext context, BloomVia via, T value, Widget child) builder;
  final Widget child;

  @override
  _ComposedDriveWithChildElement<T> createElement() =>
      _ComposedDriveWithChildElement<T>(this);
}

final class _ComposedDriveWithChildElement<T> extends ComponentElement
    with
        _TickerProviderElementMixin,
        _ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>,
        _ViaTerminalElementMixin {
  _ComposedDriveWithChildElement(_ComposedDriveWithChildWidget<T> super.widget);

  @override
  _ComposedDriveWithChildWidget<T> get widget =>
      super.widget as _ComposedDriveWithChildWidget<T>;

  late final _driver = _TickerDriver<T>(
    this,
    onTick: (elapsed) => widget.onTick(elapsed),
  );

  @override
  Widget _buildVia(BloomVia via) {
    final value = via(_driver.bloom);
    return widget.builder(this, via, value, widget.child);
  }

  @override
  void update(covariant _ComposedDriveWithChildWidget<T> newWidget) {
    super.update(newWidget);
    rebuild(force: true);
  }

  @override
  void unmount() {
    try {
      _driver.dispose();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'blooming_flutter',
          context: ErrorDescription(
              'while unmounting _ComposedDriveWithChildElement'),
        ),
      );
    }
    super.unmount();
  }
}

/// Internal reactive widget backing `composed.drive.children(...)`.
final class _ComposedDriveWithChildrenWidget<T> extends Widget {
  const _ComposedDriveWithChildrenWidget({
    required this.onTick,
    required this.builder,
    required this.children,
    super.key,
  });

  final T Function(Duration elapsed) onTick;
  final Widget Function(
          BuildContext context, BloomVia via, T value, List<Widget> children)
      builder;
  final List<Widget> children;

  @override
  _ComposedDriveWithChildrenElement<T> createElement() =>
      _ComposedDriveWithChildrenElement<T>(this);
}

final class _ComposedDriveWithChildrenElement<T> extends ComponentElement
    with
        _TickerProviderElementMixin,
        _ReactiveTerminalElementMixin<RawComputedTerminal<Widget>>,
        _ViaTerminalElementMixin {
  _ComposedDriveWithChildrenElement(
      _ComposedDriveWithChildrenWidget<T> super.widget);

  @override
  _ComposedDriveWithChildrenWidget<T> get widget =>
      super.widget as _ComposedDriveWithChildrenWidget<T>;

  late final _driver = _TickerDriver<T>(
    this,
    onTick: (elapsed) => widget.onTick(elapsed),
  );

  @override
  Widget _buildVia(BloomVia via) {
    final value = via(_driver.bloom);
    return widget.builder(this, via, value, widget.children);
  }

  @override
  void update(covariant _ComposedDriveWithChildrenWidget<T> newWidget) {
    super.update(newWidget);
    rebuild(force: true);
  }

  @override
  void unmount() {
    try {
      _driver.dispose();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'blooming_flutter',
          context: ErrorDescription(
              'while unmounting _ComposedDriveWithChildrenElement'),
        ),
      );
    }
    super.unmount();
  }
}

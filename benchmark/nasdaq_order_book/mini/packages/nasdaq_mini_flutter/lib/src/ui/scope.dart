import 'package:flutter/widgets.dart';

import '../pipeline/order_book_pipeline.dart';
import 'theme.dart';

/// Root inherited scope providing [NasdaqThemeStore] and [OrderBookPipeline]
/// via $O(1)$ context lookup.
class NasdaqBenchmarkScope extends InheritedWidget {
  const NasdaqBenchmarkScope({
    super.key,
    required this.themeStore,
    required this.pipeline,
    required super.child,
  });

  final NasdaqThemeStore themeStore;
  final OrderBookPipeline pipeline;

  static NasdaqBenchmarkScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<NasdaqBenchmarkScope>();
    assert(scope != null, 'No NasdaqBenchmarkScope found in context');
    return scope!;
  }

  static OrderBookPipeline pipelineOf(BuildContext context) =>
      of(context).pipeline;
  static NasdaqThemeStore themeStoreOf(BuildContext context) =>
      of(context).themeStore;

  @override
  bool updateShouldNotify(NasdaqBenchmarkScope oldWidget) {
    return themeStore != oldWidget.themeStore || pipeline != oldWidget.pipeline;
  }
}

/// Inherited scope reacting strictly to theme changes using [InheritedNotifier].
class ThemeScope extends InheritedNotifier<NasdaqThemeStore> {
  const ThemeScope({
    super.key,
    required NasdaqThemeStore themeStore,
    required super.child,
  }) : super(notifier: themeStore);

  static NasdaqThemeData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    return scope?.notifier?.current ?? NasdaqThemeData.swissOledDark;
  }

  static NasdaqThemeStore storeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    return scope!.notifier!;
  }
}

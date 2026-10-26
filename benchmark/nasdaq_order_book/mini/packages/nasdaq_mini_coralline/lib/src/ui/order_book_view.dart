import 'dart:math';

import 'package:coralline_flutter/coralline_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../pipeline/order_book_pipeline.dart';
import 'order_book_row.dart';
import 'order_book_spread_bar.dart';
import 'theme.dart';

// =============================================================================
// SECTION 1: 50-LEVEL VERTICAL ORDER BOOK DEPTH COMPONENT
// =============================================================================

/// 50-Level Vertical Order Book Depth component (`003 ORDER BOOK`).
/// Features 5-second oscillating vertical sliding motion and isolated reactive mapping.
/// Automatically resolves [OrderBookPipeline] from Coralline context tree.
final class OrderBookView extends BuildComponent
    with
        CorallineLifecycleAware,
        CorallineTerminalIntentAware,
        CorallineBuildContextAware,
        SingleTickerProviderCorallineLifecycleAwareMixin,
        OrderBookPipelineAware {
  OrderBookView();

  late final Coral<NasdaqThemeData> themeCoral = coralOf<NasdaqThemeData>();
  late final Coral<bool> _isScrollAnimationEnabledCoral =
      isScrollAnimationEnabledCoralOf();

  late final CoralController<double> _animOffsetController =
      CoralController<double>(0.5);

  Ticker? _ticker;
  double _elapsedSeconds = 0.0;

  @override
  void didActivate() {
    super.didActivate();
    _ticker = createTicker((elapsed) {
      _elapsedSeconds = elapsed.inMicroseconds / 1000000.0;
      final normalizedProgress =
          (sin((_elapsedSeconds / 10.0) * 2 * pi - (pi / 2)) + 1.0) / 2.0;
      _animOffsetController.set(normalizedProgress);
    });
    if (_isScrollAnimationEnabledCoral.data) {
      _ticker?.start();
    } else {
      _animOffsetController.set(0.5);
    }
  }

  @override
  void didDeactivate() {
    _ticker?.stop();
    _ticker?.dispose();
    super.didDeactivate();
  }

  late final List<Widget> _orderBookWidgets = [
    // 25 Asks (Sell orders, Level 25 down to Level 1)
    ...List.generate(25, (i) => OrderBookRow(isAsk: true, index: i).toWidget()),
    // Central Spread Bar (Latest Price & Change %)
    OrderBookSpreadBar().toWidget(),
    // 25 Bids (Buy orders, Level 1 down to Level 25)
    ...List.generate(
        25, (i) => OrderBookRow(isAsk: false, index: i).toWidget()),
  ];

  late final Widget _animWidget = _animOffsetController.map((progress) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    // Total content height: 50 rows * 22px + spread (32px) = 1132px.
    // Viewport height = 362px. Max scroll extent = 1132 - 362 = 770px.
    const maxScrollExtent = 770.0;
    final offsetY = -clampedProgress * maxScrollExtent;

    return Transform.translate(
      offset: Offset(0, offsetY),
      child:
          Column(mainAxisSize: MainAxisSize.min, children: _orderBookWidgets),
    );
  }).toWidget();

  @override
  Iterable<CoralNode> manifest() => [themeCoral, _isScrollAnimationEnabledCoral];

  @override
  Widget build() {
    final theme = themeCoral.data;
    final isAnimEnabled = _isScrollAnimationEnabledCoral.data;

    if (isAnimEnabled) {
      if (_ticker?.isActive != true) {
        _ticker?.start();
      }
    } else {
      if (_ticker?.isActive == true) {
        _ticker?.stop();
      }
      _animOffsetController.set(0.5);
    }

    return Container(
      width: 330,
      height: 394,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border.all(
          color: theme.surfaceBorder,
          width: 1.0,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        children: [
          // Swiss Section Title Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: theme.background,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('003 ', style: theme.swissIndexLabel),
                    Text('ORDER BOOK', style: theme.swissHeader),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => pipelineCoralOf().data.toggleScrollAnimation(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isAnimEnabled ? theme.chipBg : theme.cardBackground,
                          border: Border.all(
                            color: isAnimEnabled ? theme.bidGreen : theme.chipBorder,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAnimEnabled ? theme.bidGreen : theme.textMuted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAnimEnabled ? 'SCROLL ON' : 'SCROLL OFF',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: isAnimEnabled ? theme.bidGreen : theme.textMuted,
                                letterSpacing: 0.6,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '50 LEVELS',
                      style: theme.volumeStyle
                          .copyWith(fontSize: 9.5, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.surfaceBorder),

          // Order Book Column Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            color: theme.cardBackground,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PRICE (USD)', style: theme.volumeStyle),
                Text('SIZE (SHARES)', style: theme.volumeStyle),
              ],
            ),
          ),
          Divider(height: 1, color: theme.gridLine),

          // 50-Level Order Book Viewport with SingleChildScrollView
          Expanded(
            child: ClipRect(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: RepaintBoundary(
                  child: _animWidget,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

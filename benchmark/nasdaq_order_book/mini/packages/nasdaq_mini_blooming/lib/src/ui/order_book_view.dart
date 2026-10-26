import 'dart:math';

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

import 'order_book_row.dart';
import 'order_book_spread_bar.dart';
import 'theme.dart';
import '../pipeline/order_book_pipeline.dart';

// =============================================================================
// SECTION 1: 50-LEVEL VERTICAL ORDER BOOK DEPTH COMPONENT (BLOOMING)
// =============================================================================

/// 50-Level Vertical Order Book Depth component (`003 ORDER BOOK`).
/// Features 5-second oscillating vertical sliding motion and isolated reactive mapping.
/// Single declarative component powered by [BloomWidget] and [compose.drive].
final class OrderBookView extends BloomWidget {
  OrderBookView({super.key});

  static final List<Widget> _orderBookWidgets = [
    // 25 Asks (Sell orders, Level 25 down to Level 1)
    ...List.generate(25, (i) => OrderBookRow(isAsk: true, index: i)),
    // Central Spread Bar (Latest Price & Change %)
    OrderBookSpreadBar(),
    // 25 Bids (Buy orders, Level 1 down to Level 25)
    ...List.generate(25, (i) => OrderBookRow(isAsk: false, index: i)),
  ];

  @override
  Widget build(BuildContext context, BloomVia via) {
    final theme = via.of<NasdaqThemeData>(context);
    final pipeline = via.of<OrderBookPipeline>(context);
    final isAnimEnabled = via(pipeline.isScrollAnimationEnabledBloom);

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
                      onTap: () => pipeline.toggleScrollAnimation(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isAnimEnabled
                              ? theme.chipBg
                              : theme.cardBackground,
                          border: Border.all(
                            color: isAnimEnabled
                                ? theme.bidGreen
                                : theme.chipBorder,
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
                                color: isAnimEnabled
                                    ? theme.bidGreen
                                    : theme.textMuted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAnimEnabled ? 'SCROLL ON' : 'SCROLL OFF',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: isAnimEnabled
                                    ? theme.bidGreen
                                    : theme.textMuted,
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
                  child: isAnimEnabled
                      ? composed.drive<double>(
                          (elapsed) {
                            final elapsedSeconds =
                                elapsed.inMicroseconds / 1000000.0;
                            return (sin((elapsedSeconds / 10.0) * 2 * pi -
                                        (pi / 2)) +
                                    1.0) /
                                2.0;
                          },
                          (context, via, progress) {
                            final clampedProgress = progress.clamp(0.0, 1.0);
                            // Total content height: 50 rows * 22px + spread (32px) = 1132px.
                            // Viewport height = 362px. Max scroll extent = 1132 - 362 = 770px.
                            const maxScrollExtent = 770.0;
                            final offsetY = -clampedProgress * maxScrollExtent;

                            return Transform.translate(
                              offset: Offset(0, offsetY),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: _orderBookWidgets,
                              ),
                            );
                          },
                        )
                      : Transform.translate(
                          offset: const Offset(0, -385.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _orderBookWidgets,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

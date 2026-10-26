import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/order_book_providers.dart';
import '../providers/theme_providers.dart';

// =============================================================================
// SECTION 1: REAL-TIME PRICE TREND SPARKLINE CHART COMPONENT
// =============================================================================

/// Real-time price trend sparkline chart component (`002 PRICE TREND`).
/// Built with Flutter Riverpod [ConsumerWidget] for high-fps GPU rendering.
class PriceTrendView extends ConsumerWidget {
  const PriceTrendView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeDataProvider);
    final history = ref.watch(priceHistoryProvider);
    final snapshot = ref.watch(snapshotProvider);
    final isPositive = snapshot.priceChange >= 0;
    final themeColor = isPositive ? theme.bidGreen : theme.askRed;

    return Container(
      width: 570,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border.all(
          color: theme.surfaceBorder,
          width: 1.0,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row inside Chart Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('002 ', style: theme.swissIndexLabel),
                  Text('PRICE TREND', style: theme.swissHeader),
                ],
              ),
              Text(
                '${snapshot.ticker} \$${snapshot.lastPrice.toStringAsFixed(2)} (${snapshot.priceChange >= 0 ? '+' : ''}${snapshot.priceChangePct.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Custom Painted High-Performance GPU Real-time Chart
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _PriceChartPainter(
                    history: history,
                    lineColor: themeColor,
                    gridLineColor: theme.gridLine,
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

// =============================================================================
// SECTION 2: CUSTOM GPU CANVAS SPARKLINE PAINTER
// =============================================================================

/// Custom GPU Canvas painter rendering real-time price trend path in Swiss Style.
class _PriceChartPainter extends CustomPainter {
  _PriceChartPainter({
    required this.history,
    required this.lineColor,
    required this.gridLineColor,
  });

  final List<double> history;
  final Color lineColor;
  final Color gridLineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridLineColor.withValues(alpha: 0.25)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines
    final midY = size.height / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), gridPaint);
    canvas.drawLine(
        Offset(0, midY / 2), Offset(size.width, midY / 2), gridPaint);
    canvas.drawLine(Offset(0, midY + midY / 2),
        Offset(size.width, midY + midY / 2), gridPaint);

    double minP = history.reduce(min);
    double maxP = history.reduce(max);
    if ((maxP - minP).abs() < 0.01) {
      maxP += 0.05;
      minP -= 0.05;
    }

    final range = maxP - minP;
    final stepX = size.width / (max(1, history.length - 1));

    final path = Path();
    for (int i = 0; i < history.length; i++) {
      final x = i * stepX;
      final normalizedY = (history[i] - minP) / range;
      final y = size.height - (normalizedY * (size.height - 4) + 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    canvas.drawPath(path, linePaint);

    // End point pulse dot
    if (history.isNotEmpty) {
      final lastX = (history.length - 1) * stepX;
      final lastNormY = (history.last - minP) / range;
      final lastY = size.height - (lastNormY * (size.height - 4) + 2);

      final dotPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(lastX, lastY), 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) {
    return oldDelegate.history != history ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridLineColor != gridLineColor;
  }
}

import 'dart:math';

import 'package:flutter/material.dart';

import 'scope.dart';

// =============================================================================
// SECTION 1: REAL-TIME PRICE TREND SPARKLINE CHART COMPONENT
// =============================================================================

/// Real-time price trend sparkline chart component (`002 PRICE TREND`).
/// Bound to priceHistoryNotifier and snapshotNotifier for high-fps GPU rendering.
class PriceTrendView extends StatelessWidget {
  const PriceTrendView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final pipeline = NasdaqBenchmarkScope.pipelineOf(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        pipeline.priceHistoryNotifier,
        pipeline.snapshotNotifier,
      ]),
      builder: (context, _) {
        final history = pipeline.priceHistoryNotifier.value;
        final snapshot = pipeline.snapshot;
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
      },
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

  Shader? _cachedShader;
  Size? _cachedShaderSize;
  Color? _cachedShaderColor;

  Shader _getShader(Size size) {
    if (_cachedShader == null ||
        _cachedShaderSize != size ||
        _cachedShaderColor != lineColor) {
      _cachedShaderSize = size;
      _cachedShaderColor = lineColor;
      _cachedShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    }
    return _cachedShader!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridLineColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Draw Subtle Horizontal Reference Grid Lines (3 lines: Top 15%, Mid 50%, Bottom 85%)
    final midY = size.height * 0.5;
    final topY = size.height * 0.15;
    final btmY = size.height * 0.85;

    canvas.drawLine(Offset(0, topY), Offset(size.width, topY), gridPaint);
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), gridPaint);
    canvas.drawLine(Offset(0, btmY), Offset(size.width, btmY), gridPaint);

    double minPrice = history.reduce(min);
    double maxPrice = history.reduce(max);
    if ((maxPrice - minPrice).abs() < 0.001) {
      maxPrice += 0.05;
      minPrice -= 0.05;
    }

    final priceRange = maxPrice - minPrice;
    final stepX = size.width / (history.length - 1).clamp(1, 100);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < history.length; i++) {
      final x = i * stepX;
      final normalizedY = (history[i] - minPrice) / priceRange;
      final y = size.height - (normalizedY * (size.height - 8)) - 4;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == history.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    // 1. Draw Gradient Fill under line with cached shader
    final fillPaint = Paint()
      ..shader = _getShader(size)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 2. Draw Anti-aliased Smooth Curve Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // 3. Draw Endpoint Current Price Pulse Dot
    if (history.isNotEmpty) {
      final lastX = (history.length - 1) * stepX;
      final lastNormalizedY = (history.last - minPrice) / priceRange;
      final lastY = size.height - (lastNormalizedY * (size.height - 8)) - 4;

      final dotBgPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(lastX, lastY), 4.5, dotBgPaint);

      final dotPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(lastX, lastY), 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) {
    return oldDelegate.history != history ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridLineColor != gridLineColor;
  }
}

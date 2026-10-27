import 'dart:math';

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

import '../pipeline/order_book_pipeline.dart';
import 'theme.dart';

// =============================================================================
// SECTION 1: EVENT LOOP RIGHT METRICS & CHARTS COLUMN PANEL (BLOOMING)
// =============================================================================

/// Swiss-style right column dashboard component visualizing Event Loop metrics in 3 vertical modular cards:
/// 1. Top (Yellow): Instantaneous Tick Delay (Rolling Bar Graph)
/// 2. Middle (Sky Blue): 1-Second Moving Average (Rolling Line Graph)
/// 3. Bottom (Pink): 5-Second Moving Average (Rolling Line Graph)
final class EventLoopRightPanel extends BloomWidget {
  EventLoopRightPanel({super.key});

  static const Color yellowAccent = Color(0xFFF59E0B);
  static const Color skyBlueAccent = Color(0xFF0EA5E9);
  static const Color pinkAccent = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context, BloomVia via) {
    final theme = via.of<NasdaqThemeData>(context);
    final pipeline = via.of<OrderBookPipeline>(context);

    final lag = via(pipeline.eventLoopLagBloom);
    final tickHistory = via(pipeline.eventLoopHistoryBloom);

    final avg1s = via(pipeline.eventLoopAvg1sBloom);
    final avg1sHistory = via(pipeline.eventLoopAvg1sHistoryBloom);

    final avg5s = via(pipeline.eventLoopAvg5sBloom);
    final avg5sHistory = via(pipeline.eventLoopAvg5sHistoryBloom);

    return SizedBox(
      width: 230,
      height: 502,
      child: Column(
        children: [
          // 1. TOP CARD (Yellow): Instantaneous Tick Data (Bar Graph)
          Expanded(
            child: _EventLoopMetricCard(
              theme: theme,
              index: '006',
              title: 'EVENT LOOP TICK',
              subtitle: 'INSTANTANEOUS',
              value: '${lag.toStringAsFixed(2)}ms',
              accentColor: yellowAccent,
              chart: CustomPaint(
                painter: _EventLoopBarChartPainter(
                  history: tickHistory,
                  theme: theme,
                  accentColor: yellowAccent,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // 2. MIDDLE CARD (Sky Blue): 1-Second Moving Average (Line Graph)
          Expanded(
            child: _EventLoopMetricCard(
              theme: theme,
              index: '007',
              title: 'EVENT LOOP 1s AVG',
              subtitle: '1.0s MOVING AVG',
              value: '${avg1s.toStringAsFixed(2)}ms',
              accentColor: skyBlueAccent,
              chart: CustomPaint(
                painter: _EventLoopLineChartPainter(
                  history: avg1sHistory,
                  theme: theme,
                  lineColor: skyBlueAccent,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // 3. BOTTOM CARD (Pink): 5-Second Moving Average (Line Graph)
          Expanded(
            child: _EventLoopMetricCard(
              theme: theme,
              index: '008',
              title: 'EVENT LOOP 5s AVG',
              subtitle: '5.0s MOVING AVG',
              value: '${avg5s.toStringAsFixed(2)}ms',
              accentColor: pinkAccent,
              chart: CustomPaint(
                painter: _EventLoopLineChartPainter(
                  history: avg5sHistory,
                  theme: theme,
                  lineColor: pinkAccent,
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
// SECTION 2: CARD CONTAINER COMPONENT
// =============================================================================

class _EventLoopMetricCard extends StatelessWidget {
  const _EventLoopMetricCard({
    required this.theme,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accentColor,
    required this.chart,
  });

  final NasdaqThemeData theme;
  final String index;
  final String title;
  final String subtitle;
  final String value;
  final Color accentColor;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border.all(
          color: theme.surfaceBorder,
          width: 1.0,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Index + Title + Color Dot + Monospace Value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    color: accentColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$index ',
                    style: theme.swissIndexLabel.copyWith(
                      fontSize: 8.5,
                      color: accentColor,
                    ),
                  ),
                  Text(
                    title,
                    style: theme.swissHeader.copyWith(
                      fontSize: 9.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                  fontFamily: 'monospace',
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              color: theme.textMuted,
              letterSpacing: 0.4,
              fontFamily: 'monospace',
            ),
          ),

          const SizedBox(height: 4),

          // Real-time Chart Canvas Viewport with RepaintBoundary
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: theme.gridLine, width: 0.5),
              ),
              child: RepaintBoundary(
                child: chart,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 3: ROLLING BAR CHART PAINTER (YELLOW)
// =============================================================================

class _EventLoopBarChartPainter extends CustomPainter {
  _EventLoopBarChartPainter({
    required this.history,
    required this.theme,
    required this.accentColor,
  });

  final List<double> history;
  final NasdaqThemeData theme;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    // Calculate dynamic ceiling (floor at 2.0ms) and peak value
    double peakVal = 0.0;
    for (final val in history) {
      if (val > peakVal) peakVal = val;
    }
    final double maxVal = max(2.0, peakVal);

    final gridPaint = Paint()
      ..color = theme.gridLine.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    // Draw horizontal reference lines (at 25%, 50%, 75%)
    canvas.drawLine(Offset(0, size.height * 0.25),
        Offset(size.width, size.height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.50),
        Offset(size.width, size.height * 0.50), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.75),
        Offset(size.width, size.height * 0.75), gridPaint);

    final count = history.length;
    final barWidth = (size.width / count) * 0.75;
    final spacing = (size.width / count) * 0.25;

    final barPaint = Paint()..color = accentColor;
    final warningPaint = Paint()..color = theme.askRed;

    for (int i = 0; i < count; i++) {
      final val = history[i];
      final normalizedHeight = ((val / maxVal).clamp(0.0, 1.0)) * size.height;
      final x = i * (barWidth + spacing) + (spacing / 2);
      final y = size.height - normalizedHeight;

      final rect = Rect.fromLTWH(x, y, barWidth, normalizedHeight);
      canvas.drawRect(rect, val > 8.33 ? warningPaint : barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EventLoopBarChartPainter oldDelegate) => true;
}

// =============================================================================
// SECTION 4: ROLLING LINE CHART PAINTER (SKY BLUE / PINK)
// =============================================================================

class _EventLoopLineChartPainter extends CustomPainter {
  _EventLoopLineChartPainter({
    required this.history,
    required this.theme,
    required this.lineColor,
  });

  final List<double> history;
  final NasdaqThemeData theme;
  final Color lineColor;

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
          lineColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    }
    return _cachedShader!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    // Calculate dynamic ceiling (floor at 2.0ms) and peak value
    double peakVal = 0.0;
    for (final val in history) {
      if (val > peakVal) peakVal = val;
    }
    final double maxVal = max(2.0, peakVal);

    final gridPaint = Paint()
      ..color = theme.gridLine.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    canvas.drawLine(Offset(0, size.height * 0.25),
        Offset(size.width, size.height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.50),
        Offset(size.width, size.height * 0.50), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.75),
        Offset(size.width, size.height * 0.75), gridPaint);

    final count = history.length;
    if (count < 2) return;

    final double stepX = size.width / (count - 1);
    final linePath = Path();
    final fillPath = Path();

    final List<Offset> points = [];
    for (int i = 0; i < count; i++) {
      final val = history[i];
      final normalized = (val / maxVal).clamp(0.0, 1.0);
      final x = i * stepX;
      final y = size.height - (normalized * (size.height - 4.0)) - 2.0;
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      linePath.moveTo(points.first.dx, points.first.dy);
      fillPath.moveTo(points.first.dx, size.height);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        final p0 = points[i - 1];
        final p1 = points[i];
        final controlX = p0.dx + (p1.dx - p0.dx) / 2;
        linePath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
        fillPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      }

      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      // Area Fill with cached shader
      final fillPaint = Paint()
        ..shader = _getShader(size)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);

      // Stroke
      final strokePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(linePath, strokePaint);

      // Head indicator dot
      final lastPoint = points.last;
      final dotBgPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastPoint, 3.5, dotBgPaint);

      final dotPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastPoint, 1.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EventLoopLineChartPainter oldDelegate) => true;
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/order_book_providers.dart';
import '../providers/theme_providers.dart';

// =============================================================================
// SECTION 1: EVENT LOOP RIGHT METRICS & CHARTS COLUMN PANEL (RIVERPOD)
// =============================================================================

/// Swiss-style right column dashboard component visualizing Event Loop metrics in 3 vertical modular cards:
/// 1. Top (Yellow): Instantaneous Tick Delay (Rolling Bar Graph)
/// 2. Middle (Sky Blue): 1-Second Moving Average (Rolling Line Graph)
/// 3. Bottom (Pink): 5-Second Moving Average (Rolling Line Graph)
class EventLoopRightPanel extends ConsumerWidget {
  const EventLoopRightPanel({super.key});

  static const Color yellowAccent = Color(0xFFF59E0B);
  static const Color skyBlueAccent = Color(0xFF0EA5E9);
  static const Color pinkAccent = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeDataProvider);

    final lag = ref.watch(eventLoopLagProvider);
    final tickHistory = ref.watch(eventLoopHistoryProvider);

    final avg1s = ref.watch(eventLoopAvg1sProvider);
    final avg1sHistory = ref.watch(eventLoopAvg1sHistoryProvider);

    final avg5s = ref.watch(eventLoopAvg5sProvider);
    final avg5sHistory = ref.watch(eventLoopAvg5sHistoryProvider);

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

          // Chart Area
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: chart,
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
  const _EventLoopBarChartPainter({
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

    // 1. Draw 1.0ms Horizontal Reference Line & Label (Right)
    final y1ms = size.height - (1.0 / maxVal).clamp(0.0, 1.0) * size.height;
    final indicatorPaint = Paint()
      ..color = theme.textMuted.withValues(alpha: 0.45)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double currentX = 0;
    final lineEndX = size.width - 24;
    while (currentX < lineEndX) {
      canvas.drawLine(
        Offset(currentX, y1ms),
        Offset(min(currentX + dashWidth, lineEndX), y1ms),
        indicatorPaint,
      );
      currentX += dashWidth + dashSpace;
    }

    final textPainter1ms = TextPainter(
      text: TextSpan(
        text: '1ms',
        style: TextStyle(
          fontSize: 7.0,
          fontWeight: FontWeight.w700,
          color: theme.textMuted.withValues(alpha: 0.75),
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter1ms.paint(
      canvas,
      Offset(size.width - textPainter1ms.width - 1,
          y1ms - (textPainter1ms.height / 2)),
    );

    // 2. Draw MAX Indicator Line & Label (Left/Top)
    final yMax = size.height -
        (peakVal / maxVal).clamp(0.0, 1.0) * (size.height - 6.0) -
        3.0;
    final maxLinePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.4)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    currentX = 0;
    while (currentX < size.width) {
      canvas.drawLine(
        Offset(currentX, yMax),
        Offset(min(currentX + 2.0, size.width), yMax),
        maxLinePaint,
      );
      currentX += 4.0;
    }

    final textPainterMax = TextPainter(
      text: TextSpan(
        text: 'MAX ${peakVal.toStringAsFixed(2)}ms',
        style: TextStyle(
          fontSize: 6.8,
          fontWeight: FontWeight.w800,
          color: accentColor.withValues(alpha: 0.9),
          fontFamily: 'monospace',
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final maxLabelY = (yMax - textPainterMax.height - 1)
        .clamp(0.0, size.height - textPainterMax.height);
    textPainterMax.paint(canvas, Offset(2, maxLabelY));

    // 3. Draw rolling bars
    final barWidth = size.width / history.length;
    final barPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < history.length; i++) {
      final val = history[i];
      final normalized = (val / maxVal).clamp(0.0, 1.0);
      final barHeight = max(1.5, normalized * size.height);

      final opacity = 0.55 + (0.45 * (i / history.length));
      barPaint.color = accentColor.withValues(alpha: opacity);

      final left = i * barWidth;
      final top = size.height - barHeight;

      canvas.drawRect(
        Rect.fromLTWH(left, top, max(1.2, barWidth - 0.8), barHeight),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EventLoopBarChartPainter oldDelegate) {
    return oldDelegate.history != history ||
        oldDelegate.theme != theme ||
        oldDelegate.accentColor != accentColor;
  }
}

// =============================================================================
// SECTION 4: ROLLING LINE CHART PAINTER (SKY BLUE / PINK)
// =============================================================================

class _EventLoopLineChartPainter extends CustomPainter {
  const _EventLoopLineChartPainter({
    required this.history,
    required this.theme,
    required this.lineColor,
  });

  final List<double> history;
  final NasdaqThemeData theme;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    // Calculate dynamic ceiling (floor at 2.0ms) and peak value
    double peakVal = 0.0;
    for (final val in history) {
      if (val > peakVal) peakVal = val;
    }
    final double maxVal = max(2.0, peakVal);

    // 1. Draw 1.0ms Horizontal Reference Line & Label (Right)
    final y1ms = size.height - (1.0 / maxVal).clamp(0.0, 1.0) * size.height;
    final indicatorPaint = Paint()
      ..color = theme.textMuted.withValues(alpha: 0.45)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double currentX = 0;
    final lineEndX = size.width - 24;
    while (currentX < lineEndX) {
      canvas.drawLine(
        Offset(currentX, y1ms),
        Offset(min(currentX + dashWidth, lineEndX), y1ms),
        indicatorPaint,
      );
      currentX += dashWidth + dashSpace;
    }

    final textPainter1ms = TextPainter(
      text: TextSpan(
        text: '1ms',
        style: TextStyle(
          fontSize: 7.0,
          fontWeight: FontWeight.w700,
          color: theme.textMuted.withValues(alpha: 0.75),
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter1ms.paint(
      canvas,
      Offset(size.width - textPainter1ms.width - 1,
          y1ms - (textPainter1ms.height / 2)),
    );

    // 2. Draw MAX Indicator Line & Label (Left/Top)
    final yMax = size.height -
        (peakVal / maxVal).clamp(0.0, 1.0) * (size.height - 6.0) -
        3.0;
    final maxLinePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.4)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    currentX = 0;
    while (currentX < size.width) {
      canvas.drawLine(
        Offset(currentX, yMax),
        Offset(min(currentX + 2.0, size.width), yMax),
        maxLinePaint,
      );
      currentX += 4.0;
    }

    final textPainterMax = TextPainter(
      text: TextSpan(
        text: 'MAX ${peakVal.toStringAsFixed(2)}ms',
        style: TextStyle(
          fontSize: 6.8,
          fontWeight: FontWeight.w800,
          color: lineColor.withValues(alpha: 0.9),
          fontFamily: 'monospace',
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final maxLabelY = (yMax - textPainterMax.height - 1)
        .clamp(0.0, size.height - textPainterMax.height);
    textPainterMax.paint(canvas, Offset(2, maxLabelY));

    // 3. Draw smooth curve line & gradient fill
    final double stepX = size.width / (history.length - 1);
    final linePath = Path();
    final fillPath = Path();

    final List<Offset> points = [];
    for (int i = 0; i < history.length; i++) {
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
        final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY1 = p0.dy;
        final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
        final controlY2 = p1.dy;

        linePath.cubicTo(
            controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
        fillPath.cubicTo(
            controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      }

      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      // Draw gradient area under line
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.25),
            lineColor.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);

      // Draw line stroke
      final strokePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(linePath, strokePaint);

      // Draw active head indicator dot
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
  bool shouldRepaint(covariant _EventLoopLineChartPainter oldDelegate) {
    return oldDelegate.history != history ||
        oldDelegate.theme != theme ||
        oldDelegate.lineColor != lineColor;
  }
}

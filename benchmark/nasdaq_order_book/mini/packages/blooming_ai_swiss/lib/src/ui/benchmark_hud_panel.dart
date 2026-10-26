import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

import '../benchmark/benchmark_export_service.dart';
import '../pipeline/order_book_pipeline.dart';
import 'theme.dart';

// =============================================================================
// SECTION 1: BENCHMARK METRICS & CONTROLS HUD COMPONENT
// =============================================================================

/// Benchmark Metrics & Controls HUD (Heads-Up Display) component.
/// Redesigned with Swiss Art Series & Dynamic Theme System.
/// Automatically resolves [OrderBookPipeline] from Blooming context tree.
final class BenchmarkHudPanel extends BloomWidget {
  BenchmarkHudPanel({super.key});

  /// Preset target TPS values ranging from 100 TPS to 100,000,000 TPS (1억건/초)
  static const List<int> tpsPresets = [
    100,
    1000,
    10000,
    50000,
    100000,
    500000,
    1000000,
    5000000,
    10000000,
    50000000,
    100000000,
  ];

  @override
  Widget build(BuildContext context, BloomVia via) {
    final effectivePipeline = via.of<OrderBookPipeline>(context);
    final theme = via.of<NasdaqThemeData>(context);

    final targetTps = via(effectivePipeline.targetTpsBloom);
    final actualTps = via(effectivePipeline.actualTpsBloom);
    final isSimulating = via(effectivePipeline.isSimulatingBloom);
    final latency = via(effectivePipeline.latencyMsBloom);
    final snapshot = via(effectivePipeline.snapshotBloom);
    final eventLoopLag = via(effectivePipeline.eventLoopLagBloom);
    final eventLoopAvg1s = via(effectivePipeline.eventLoopAvg1sBloom);
    final eventLoopAvg5s = via(effectivePipeline.eventLoopAvg5sBloom);
    final eventLoopHistory = via(effectivePipeline.eventLoopHistoryBloom);

    // Find index in tpsPresets
    int currentIndex = BenchmarkHudPanel.tpsPresets.indexOf(targetTps);
    if (currentIndex == -1) {
      int minDiffIndex = 0;
      int minDiff = (BenchmarkHudPanel.tpsPresets[0] - targetTps).abs();
      for (int i = 1; i < BenchmarkHudPanel.tpsPresets.length; i++) {
        final diff = (BenchmarkHudPanel.tpsPresets[i] - targetTps).abs();
        if (diff < minDiff) {
          minDiff = diff;
          minDiffIndex = i;
        }
      }
      currentIndex = minDiffIndex;
    }

    BenchmarkMetricsSnapshot createSnapshot() {
      return BenchmarkMetricsSnapshot(
        frameworkName: 'Blooming',
        architecture: 'Blooming 2-Phase LPDAG Reactive Graph',
        targetTps: targetTps,
        actualTps: actualTps,
        latencyMs: latency,
        totalTicksProcessed: snapshot.totalTicksProcessed,
        eventLoopLagMs: eventLoopLag,
        eventLoopAvg1s: eventLoopAvg1s,
        eventLoopAvg5s: eventLoopAvg5s,
        eventLoopHistory: eventLoopHistory,
        timestamp: DateTime.now(),
        uiBuildTimeMs: effectivePipeline.uiBuildTimeMs,
        rasterTimeMs: effectivePipeline.rasterTimeMs,
        jankRatePct: effectivePipeline.jankRatePct,
      );
    }

    return Container(
      width: 230,
      height: 172,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('005 ', style: theme.swissIndexLabel.copyWith(fontSize: 9)),
                  Text('BENCHMARK HUD',
                      style: theme.swissHeader.copyWith(fontSize: 11, letterSpacing: 1.0)),
                ],
              ),
              Text(
                'CTRL',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Real-time Metric Tiles
          _MetricTile(
            label: 'INGEST TPS',
            value: _formatNum(actualTps),
            valueColor: actualTps > 0 ? theme.bidGreen : theme.textPrimary,
            labelStyle: theme.volumeStyle.copyWith(fontSize: 9.5),
          ),
          const SizedBox(height: 1),
          _MetricTile(
            label: 'LATENCY',
            value: '${latency.toStringAsFixed(1)}ms',
            valueColor: latency < 10 ? theme.bidGreen : theme.askRed,
            labelStyle: theme.volumeStyle.copyWith(fontSize: 9.5),
          ),
          const SizedBox(height: 1),
          _MetricTile(
            label: 'TOTAL TICKS',
            value: _formatNum(snapshot.totalTicksProcessed),
            valueColor: theme.textPrimary,
            labelStyle: theme.volumeStyle.copyWith(fontSize: 9.5),
          ),

          Divider(height: 7, color: theme.gridLine),

          // Target TPS Slider Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TARGET TPS',
                style: theme.volumeStyle.copyWith(color: theme.textPrimary, fontSize: 9.5),
              ),
              Text(
                _formatNum(targetTps),
                style: TextStyle(
                  color: theme.bidGreen,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: theme.textPrimary,
              inactiveTrackColor: theme.gridLine,
              thumbColor: theme.textPrimary,
              overlayColor: theme.textPrimary.withValues(alpha: 0.1),
              trackHeight: 3.5,
              thumbShape: const SwissRectSliderThumbShape(enabledThumbRadius: 6.0),
            ),
            child: SizedBox(
              height: 22,
              child: Slider(
                value: currentIndex.toDouble(),
                min: 0,
                max: (BenchmarkHudPanel.tpsPresets.length - 1).toDouble(),
                divisions: BenchmarkHudPanel.tpsPresets.length - 1,
                label: '${_formatNum(BenchmarkHudPanel.tpsPresets[currentIndex])} TPS',
                onChanged: (val) {
                  final newTps = BenchmarkHudPanel.tpsPresets[val.round()];
                  effectivePipeline.setTargetTps(newTps);
                },
              ),
            ),
          ),

          const SizedBox(height: 3),

          // Action Buttons: [START / STOP] + [📋 EXPORT]
          Row(
            children: [
              Expanded(
                flex: 6,
                child: SizedBox(
                  height: 26,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isSimulating) {
                        effectivePipeline.stopSimulation();
                      } else {
                        effectivePipeline.startSimulation();
                      }
                    },
                    icon: Icon(
                      isSimulating ? Icons.stop : Icons.play_arrow,
                      size: 12,
                    ),
                    label: Text(
                      isSimulating ? 'STOP' : 'START SIM',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 9.0,
                        letterSpacing: 0.6,
                        fontFamily: 'monospace',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSimulating ? theme.askRed : theme.chipBg,
                      foregroundColor: isSimulating ? Colors.white : theme.chipText,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(
                          color: isSimulating ? theme.askRed : theme.chipBorder,
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 26,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final metrics = createSnapshot();
                      BenchmarkExportService.copyMediumMarkdown(
                        context,
                        metrics,
                        theme,
                      );
                    },
                    icon: const Icon(Icons.copy_all, size: 11),
                    label: const Text(
                      'EXPORT',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 9.0,
                        letterSpacing: 0.6,
                        fontFamily: 'monospace',
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.textPrimary,
                      backgroundColor: theme.cardBackground,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(
                          color: theme.chipBorder,
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNum(int num) {
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

// =============================================================================
// SECTION 2: PRIVATE METRIC TILE WIDGET
// =============================================================================

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.labelStyle,
    this.valueColor,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SECTION 3: SWISS RECTANGULAR SLIDER THUMB SHAPE & HELPERS
// =============================================================================

String formatIntervalLabel(double ms) {
  if (ms >= 1000) {
    final s = ms / 1000;
    return '${s % 1 == 0 ? s.toInt() : s.toStringAsFixed(1)}s';
  }
  return '${ms % 1 == 0 ? ms.toInt() : ms.toStringAsFixed(2)}ms';
}

/// Custom rectangular slider thumb shape matching Swiss International typography.
class SwissRectSliderThumbShape extends SliderComponentShape {
  const SwissRectSliderThumbShape({
    this.enabledThumbRadius = 4,
    this.thumbColor,
  });

  final double enabledThumbRadius;
  final Color? thumbColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.fromRadius(enabledThumbRadius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..color = thumbColor ?? sliderTheme.thumbColor ?? Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: enabledThumbRadius * 2,
        height: enabledThumbRadius * 2,
      ),
      paint,
    );
  }
}

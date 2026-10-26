import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/theme.dart';

/// Comprehensive snapshot model for Coralline benchmark metrics.
@immutable
class CorallineBenchmarkMetricsSnapshot {
  const CorallineBenchmarkMetricsSnapshot({
    required this.frameworkName,
    required this.architecture,
    required this.targetTps,
    required this.actualTps,
    required this.latencyMs,
    required this.totalTicksProcessed,
    required this.eventLoopLagMs,
    required this.eventLoopAvg1s,
    required this.eventLoopAvg5s,
    required this.eventLoopHistory,
    required this.timestamp,
    this.memoryRssMb = 0.0,
    this.uiBuildTimeMs = 0.0,
    this.rasterTimeMs = 0.0,
    this.jankRatePct = 0.0,
  });

  final String frameworkName;
  final String architecture;
  final int targetTps;
  final int actualTps;
  final double latencyMs;
  final int totalTicksProcessed;
  final double eventLoopLagMs;
  final double eventLoopAvg1s;
  final double eventLoopAvg5s;
  final List<double> eventLoopHistory;
  final DateTime timestamp;
  final double memoryRssMb;
  final double uiBuildTimeMs;
  final double rasterTimeMs;
  final double jankRatePct;

  double get achievementRate =>
      targetTps > 0 ? ((actualTps / targetTps) * 100).clamp(0.0, 100.0) : 0.0;

  double get eventLoopP95 {
    if (eventLoopHistory.isEmpty) return eventLoopLagMs;
    final sorted = List<double>.from(eventLoopHistory)..sort();
    final idx = ((sorted.length - 1) * 0.95).floor();
    return sorted[idx];
  }

  double get eventLoopP99 {
    if (eventLoopHistory.isEmpty) return eventLoopLagMs;
    final sorted = List<double>.from(eventLoopHistory)..sort();
    final idx = ((sorted.length - 1) * 0.99).floor();
    return sorted[idx];
  }

  String toMediumMarkdown() {
    final effectiveMemory = memoryRssMb > 0 ? memoryRssMb : (ProcessInfo.currentRss / (1024 * 1024));
    final buffer = StringBuffer();
    buffer.writeln('### 📊 $frameworkName Benchmark Snapshot ($architecture)');
    buffer.writeln();
    buffer.writeln('- **Generated At**: `${timestamp.toIso8601String()}`');
    buffer.writeln('- **Runtime Environment**: `${Platform.operatingSystem} ${Platform.operatingSystemVersion}`');
    buffer.writeln('- **Dart SDK**: `${Platform.version.split(' ').first}`');
    buffer.writeln();
    buffer.writeln('| Metric Category | Measurement | Value | Status / Rating |');
    buffer.writeln('| :--- | :--- | :--- | :--- |');
    buffer.writeln('| **Throughput** | Target TPS | `${_formatNum(targetTps)} TPS` | Configured Load |');
    buffer.writeln('| **Throughput** | Sustained TPS | `${_formatNum(actualTps)} TPS` | **${achievementRate.toStringAsFixed(1)}% Achieved** |');
    buffer.writeln('| **Throughput** | Total Ingested Ticks | `${_formatNum(totalTicksProcessed)} ticks` | High Frequency Stream |');
    buffer.writeln('| **UI Latency** | Tick-to-UI Latency | `${latencyMs.toStringAsFixed(2)} ms` | ${latencyMs < 16.6 ? '⚡ Zero Jank (<16.6ms)' : '⚠️ High Latency'} |');
    buffer.writeln('| **Responsiveness** | Event Loop Lag (Current) | `${eventLoopLagMs.toStringAsFixed(2)} ms` | Main Thread Smoothness |');
    buffer.writeln('| **Responsiveness** | Event Loop Lag (1s Moving Avg) | `${eventLoopAvg1s.toStringAsFixed(2)} ms` | Sustained Stability |');
    buffer.writeln('| **Responsiveness** | Event Loop P95 / P99 | `${eventLoopP95.toStringAsFixed(2)} ms / ${eventLoopP99.toStringAsFixed(2)} ms` | Worst-case Jitter |');
    buffer.writeln('| **Frame Timing** | UI Thread Build Time | `${uiBuildTimeMs.toStringAsFixed(2)} ms` | Localized Fine-Grained Rebuild |');
    buffer.writeln('| **Frame Timing** | Raster GPU Time | `${rasterTimeMs.toStringAsFixed(2)} ms` | Layer Rasterization |');
    buffer.writeln('| **Frame Timing** | Jank Frame Rate | `${jankRatePct.toStringAsFixed(1)}%` | ${jankRatePct == 0.0 ? '🏆 Zero-Jank 120Hz' : '⚠️ Frame Drops'} |');
    buffer.writeln('| **Resource** | Process RSS Memory | `${effectiveMemory.toStringAsFixed(1)} MB` | Memory Footprint & GC Stability |');
    buffer.writeln();
    buffer.writeln('> **Key Engineering Takeaway**:');
    buffer.writeln('> $frameworkName powered by $architecture achieved **${achievementRate.toStringAsFixed(1)}%** of ${_formatNum(targetTps)} TPS with an average event loop lag of **${eventLoopAvg1s.toStringAsFixed(2)} ms** and memory footprint of **${effectiveMemory.toStringAsFixed(1)} MB**.');
    buffer.writeln();
    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'framework': frameworkName,
      'architecture': architecture,
      'timestamp': timestamp.toIso8601String(),
      'environment': {
        'os': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
        'dart_version': Platform.version,
      },
      'metrics': {
        'target_tps': targetTps,
        'actual_tps': actualTps,
        'achievement_rate_percent': double.parse(achievementRate.toStringAsFixed(2)),
        'total_ticks_processed': totalTicksProcessed,
        'tick_latency_ms': double.parse(latencyMs.toStringAsFixed(2)),
        'event_loop_lag': {
          'current_ms': double.parse(eventLoopLagMs.toStringAsFixed(2)),
          'avg_1s_ms': double.parse(eventLoopAvg1s.toStringAsFixed(2)),
          'avg_5s_ms': double.parse(eventLoopAvg5s.toStringAsFixed(2)),
          'p95_ms': double.parse(eventLoopP95.toStringAsFixed(2)),
          'p99_ms': double.parse(eventLoopP99.toStringAsFixed(2)),
        },
      },
    };
  }

  static String _formatNum(int num) {
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

/// Service providing export and clipboard sharing utilities for benchmarks.
class CorallineBenchmarkExportService {
  const CorallineBenchmarkExportService._();

  static Future<void> copyMediumMarkdown(
    BuildContext context,
    CorallineBenchmarkMetricsSnapshot snapshot,
    NasdaqThemeData theme,
  ) async {
    final markdown = snapshot.toMediumMarkdown();
    await Clipboard.setData(ClipboardData(text: markdown));

    if (context.mounted) {
      _showSwissSnackBar(
        context,
        message: '📋 MEDIUM MARKDOWN COPIED TO CLIPBOARD',
        theme: theme,
      );
    }
  }

  static Future<void> copyJson(
    BuildContext context,
    CorallineBenchmarkMetricsSnapshot snapshot,
    NasdaqThemeData theme,
  ) async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(snapshot.toJson());
    await Clipboard.setData(ClipboardData(text: jsonStr));

    if (context.mounted) {
      _showSwissSnackBar(
        context,
        message: '💾 BENCHMARK JSON DATASET COPIED',
        theme: theme,
      );
    }
  }

  static void _showSwissSnackBar(
    BuildContext context, {
    required String message,
    required NasdaqThemeData theme,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: theme.chipBg,
            fontWeight: FontWeight.w900,
            fontSize: 10.5,
            letterSpacing: 0.8,
            fontFamily: 'monospace',
          ),
        ),
        backgroundColor: theme.chipText,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: theme.surfaceBorder, width: 1.0),
        ),
      ),
    );
  }
}

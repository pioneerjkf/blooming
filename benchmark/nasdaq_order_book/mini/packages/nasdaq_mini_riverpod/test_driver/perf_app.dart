import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasdaq_mini_riverpod/main.dart';
import 'package:nasdaq_mini_riverpod/src/pipeline/order_book_pipeline.dart';
import 'package:nasdaq_mini_riverpod/src/providers/theme_providers.dart';

void main() {
  late ProviderContainer container;
  late OrderBookPipeline pipeline;

  int measurementStartTicks = 0;
  int measurementStartBatches = 0;
  int measurementStartMs = 0;

  enableFlutterDriverExtension(
    handler: (message) async {
      if (message == 'get_metrics') {
        final rssMb = ProcessInfo.currentRss / (1024 * 1024);
        double refreshRate = 120.0;
        try {
          final views = WidgetsBinding.instance.platformDispatcher.views;
          if (views.isNotEmpty) {
            refreshRate = views.first.display.refreshRate;
          }
        } catch (_) {}
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final elapsedSec =
            measurementStartMs > 0 ? (nowMs - measurementStartMs) / 1000.0 : 0.0;
        final currentTicks = pipeline.totalTicksProcessed;
        final currentBatches = pipeline.totalBatchesProcessed;
        final windowTicks = measurementStartMs > 0
            ? max(0, currentTicks - measurementStartTicks)
            : currentTicks;
        final windowBatches = measurementStartMs > 0
            ? max(0, currentBatches - measurementStartBatches)
            : currentBatches;
        final sustainedTps = elapsedSec > 0
            ? (windowTicks / elapsedSec).round()
            : pipeline.actualTpsValue;
        final batchRate =
            elapsedSec > 0 ? (windowBatches / elapsedSec).round() : 0;

        return jsonEncode({
          'display_refresh_rate': refreshRate,
          'sustained_tps': sustainedTps,
          'generator_tps': sustainedTps,
          'framework_update_rate_hz': batchRate,
          'total_ticks': windowTicks,
          'total_batches': windowBatches,
          'avg_event_loop_lag_ms': pipeline.eventLoopLagValue,
          'lag_stats': pipeline.lagRecorder.stats(),
          'latency_ms': pipeline.latencyMsValue,
          'ui_build_time_ms': pipeline.uiBuildTimeMs,
          'raster_time_ms': pipeline.rasterTimeMs,
          'jank_rate_pct': pipeline.jankRatePct,
          'memory_rss_mb': rssMb,
        });
      } else if (message == 'lag_reset') {
        measurementStartTicks = pipeline.totalTicksProcessed;
        measurementStartBatches = pipeline.totalBatchesProcessed;
        measurementStartMs = DateTime.now().millisecondsSinceEpoch;
        pipeline.lagRecorder.reset();
        return 'OK';
      } else if (message?.startsWith('set_tps:') == true) {
        final tps = int.parse(message!.substring('set_tps:'.length));
        pipeline.setTargetTps(tps);
        pipeline.startSimulation();
        return 'OK';
      } else if (message?.startsWith('set_scroll_anim:') == true) {
        final enabled =
            message!.substring('set_scroll_anim:'.length).toLowerCase() ==
                'true';
        pipeline.setScrollAnimationEnabled(enabled);
        return 'OK';
      } else if (message?.startsWith('set_theme_rotation:') == true) {
        final parts =
            message!.substring('set_theme_rotation:'.length).split(':');
        final enabled = parts[0].toLowerCase() == 'true';
        if (parts.length > 1) {
          final intervalIndex = int.tryParse(parts[1]);
          if (intervalIndex != null) {
            container
                .read(themeRotationIntervalIndexProvider.notifier)
                .set(intervalIndex);
          }
        }
        container.read(themeAutoRotatingProvider.notifier).set(enabled);
        return 'OK';
      } else if (message?.startsWith('set_ticker_rotation:') == true) {
        final parts =
            message!.substring('set_ticker_rotation:'.length).split(':');
        final enabled = parts[0].toLowerCase() == 'true';
        if (parts.length > 1) {
          final intervalIndex = int.tryParse(parts[1]);
          if (intervalIndex != null) {
            pipeline.setRotationIntervalIndex(intervalIndex);
          }
        }
        if (enabled) {
          pipeline.startAutoRotation();
        } else {
          pipeline.stopAutoRotation();
        }
        return 'OK';
      } else if (message?.startsWith('set_progress:') == true) {
        final parts = message!.substring('set_progress:'.length).split(':');
        if (parts.length >= 4) {
          final curSet = int.tryParse(parts[0]) ?? 1;
          final totSets = int.tryParse(parts[1]) ?? 1;
          final curBench = int.tryParse(parts[2]) ?? 1;
          final totBenches = int.tryParse(parts[3]) ?? 1;
          final curRun = parts.length > 4 ? (int.tryParse(parts[4]) ?? 1) : 1;
          final totRuns = parts.length > 5 ? (int.tryParse(parts[5]) ?? 1) : 1;
          pipeline.setBenchmarkProgress(
            currentSet: curSet,
            totalSets: totSets,
            currentBench: curBench,
            totalBenches: totBenches,
            currentRun: curRun,
            totalRuns: totRuns,
          );
        }
        return 'OK';
      }
      return 'UNKNOWN';
    },
  );

  container = ProviderContainer();
  pipeline = OrderBookPipeline(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: NasdaqBenchmarkApp(pipeline: pipeline),
    ),
  );
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter/material.dart';
import 'package:nasdaq_mini_flutter/main.dart';
import 'package:nasdaq_mini_flutter/src/pipeline/order_book_pipeline.dart';
import 'package:nasdaq_mini_flutter/src/ui/theme.dart';

void main() {
  late NasdaqThemeStore themeStore;
  late OrderBookPipeline pipeline;

  enableFlutterDriverExtension(
    handler: (message) async {
      if (message == 'get_metrics') {
        final rssMb = ProcessInfo.currentRss / (1024 * 1024);
        return jsonEncode({
          'sustained_tps': pipeline.actualTps,
          'total_ticks': pipeline.snapshot.totalTicksProcessed,
          'avg_event_loop_lag_ms': pipeline.eventLoopLag,
          'lag_stats': pipeline.lagRecorder.stats(),
          'latency_ms': pipeline.latencyMs,
          'ui_build_time_ms': pipeline.uiBuildTimeMs,
          'raster_time_ms': pipeline.rasterTimeMs,
          'jank_rate_pct': pipeline.jankRatePct,
          'memory_rss_mb': rssMb,
        });
      } else if (message == 'lag_reset') {
        pipeline.lagRecorder.reset();
        return 'OK';
      } else if (message?.startsWith('set_tps:') == true) {
        final tps = int.parse(message!.substring('set_tps:'.length));
        pipeline.setTargetTps(tps);
        pipeline.startSimulation();
        return 'OK';
      } else if (message?.startsWith('set_scroll_anim:') == true) {
        final enabled = message!.substring('set_scroll_anim:'.length).toLowerCase() == 'true';
        pipeline.setScrollAnimationEnabled(enabled);
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

  themeStore = NasdaqThemeStore();
  pipeline = OrderBookPipeline();

  runApp(
    NasdaqBenchmarkApp(
      themeStore: themeStore,
      pipeline: pipeline,
    ),
  );
}

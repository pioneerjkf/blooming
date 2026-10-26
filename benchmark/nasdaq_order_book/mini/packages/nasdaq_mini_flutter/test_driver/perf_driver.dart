// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

void main() async {
  final targetTpsStr = Platform.environment['BENCH_TPS'] ?? '100000';
  final durationStr = Platform.environment['BENCH_DURATION'] ?? '3';
  final warmupStr = Platform.environment['BENCH_WARMUP'] ?? '1';
  final scrollAnimStr = Platform.environment['BENCH_SCROLL_ANIM'] ?? 'true';
  final themeRotStr = Platform.environment['BENCH_THEME_ROTATION'] ?? 'true';
  final themeIntervalIndexStr = Platform.environment['BENCH_THEME_INTERVAL_INDEX'] ?? '0';
  final tickerRotStr = Platform.environment['BENCH_TICKER_ROTATION'] ?? 'true';
  final tickerIntervalIndexStr = Platform.environment['BENCH_TICKER_INTERVAL_INDEX'] ?? '0';

  final targetTps = int.parse(targetTpsStr);
  final durationSec = int.parse(durationStr);
  final warmupSec = int.parse(warmupStr);
  final enableScrollAnim = scrollAnimStr.toLowerCase() == 'true';
  final enableThemeRotation = themeRotStr.toLowerCase() == 'true';
  final themeIntervalIndex = int.tryParse(themeIntervalIndexStr) ?? 0;
  final enableTickerRotation = tickerRotStr.toLowerCase() == 'true';
  final tickerIntervalIndex = int.tryParse(tickerIntervalIndexStr) ?? 0;

  final setIndex = int.tryParse(Platform.environment['BENCH_SET_INDEX'] ?? '1') ?? 1;
  final totalSets = int.tryParse(Platform.environment['BENCH_TOTAL_SETS'] ?? '1') ?? 1;
  final targetIndex = int.tryParse(Platform.environment['BENCH_TARGET_INDEX'] ?? '1') ?? 1;
  final totalTargets = int.tryParse(Platform.environment['BENCH_TOTAL_TARGETS'] ?? '1') ?? 1;
  final runIndex = int.tryParse(Platform.environment['BENCH_RUN_INDEX'] ?? '1') ?? 1;
  final totalRuns = int.tryParse(Platform.environment['BENCH_TOTAL_RUNS'] ?? '1') ?? 1;

  FlutterDriver? driver;
  try {
    driver = await FlutterDriver.connect();

    // 1. Configure Benchmark Progress, TPS load, scroll animation, and rotations
    await driver.requestData('set_progress:$setIndex:$totalSets:$targetIndex:$totalTargets:$runIndex:$totalRuns');
    await driver.requestData('set_scroll_anim:$enableScrollAnim');
    await driver.requestData('set_theme_rotation:$enableThemeRotation:$themeIntervalIndex');
    await driver.requestData('set_ticker_rotation:$enableTickerRotation:$tickerIntervalIndex');
    await driver.requestData('set_tps:$targetTps');

    // 2. Warmup stage
    await Future.delayed(Duration(seconds: warmupSec));

    // 3. Trace GPU and UI frame timeline
    // Start lag sampling exactly at the measurement window start.
    await driver.requestData('lag_reset');
    final timeline = await driver.traceAction(() async {
      await Future.delayed(Duration(seconds: durationSec));
    });

    final summary = TimelineSummary.summarize(timeline);

    // 4. Query live metrics from pipeline
    final metricsJson = await driver.requestData('get_metrics');
    final Map<String, dynamic> pipelineMetrics = jsonDecode(metricsJson);

    final frameCount = summary.countFrames();
    final missedBudget = summary.computeMissedFrameBuildBudgetCount();
    final jankRate = frameCount > 0 ? (missedBudget / frameCount) * 100.0 : 0.0;
    final fps = frameCount > 0 ? frameCount / durationSec : 60.0;

    final avgBuildMs = summary.computeAverageFrameBuildTimeMillis();
    final p90BuildMs = summary.computePercentileFrameBuildTimeMillis(90.0);
    final p99BuildMs = summary.computePercentileFrameBuildTimeMillis(99.0);
    final avgRasterMs = summary.computeAverageFrameRasterizerTimeMillis();
    final p99RasterMs = summary.computePercentileFrameRasterizerTimeMillis(99.0);

    // -------------------------------------------------------------------------
    // [Data Source A] In-App Flutter Engine Live FrameTiming Metrics (Primary)
    // -------------------------------------------------------------------------
    final appInternalBuildMs = (pipelineMetrics['ui_build_time_ms'] as num?)?.toDouble() ?? 0.0;
    final appInternalRasterMs = (pipelineMetrics['raster_time_ms'] as num?)?.toDouble() ?? 0.0;
    final appInternalJankPct = (pipelineMetrics['jank_rate_pct'] as num?)?.toDouble() ?? 0.0;

    // -------------------------------------------------------------------------
    // [Data Source B] External Flutter Driver VM Timeline Trace Analysis (Fallback)
    // -------------------------------------------------------------------------
    final driverTimelineAvgBuildMs = avgBuildMs;
    final driverTimelineAvgRasterMs = avgRasterMs;
    final driverTimelineJankPct = jankRate;

    final effectiveBuildMs = appInternalBuildMs > 0 ? appInternalBuildMs : driverTimelineAvgBuildMs;
    final effectiveRasterMs = appInternalRasterMs > 0 ? appInternalRasterMs : driverTimelineAvgRasterMs;
    final effectiveJankRate = appInternalBuildMs > 0 ? appInternalJankPct : driverTimelineJankPct;

    final lagStats = (pipelineMetrics['lag_stats'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    double? lagStat(String k) => (lagStats[k] as num?)?.toDouble();

    final result = {
      'framework': 'Flutter',
      'architecture': 'Pure Flutter (ValueNotifier & ListenableBuilder)',
      'target_tps': targetTps,
      'sustained_tps': (pipelineMetrics['sustained_tps'] as num).toInt(),
      'total_ticks': (pipelineMetrics['total_ticks'] as num).toInt(),
      'avg_event_loop_lag_ms': lagStat('mean') == null ? null : double.parse(lagStat('mean')!.toStringAsFixed(3)),
      'median_event_loop_lag_ms': lagStat('median') == null ? null : double.parse(lagStat('median')!.toStringAsFixed(3)),
      'p95_event_loop_lag_ms': lagStat('p95') == null ? null : double.parse(lagStat('p95')!.toStringAsFixed(3)),
      'p99_event_loop_lag_ms': lagStat('p99') == null ? null : double.parse(lagStat('p99')!.toStringAsFixed(3)),
      'max_event_loop_lag_ms': lagStat('max') == null ? null : double.parse(lagStat('max')!.toStringAsFixed(3)),
      'lag_sample_count': lagStats['count'] ?? 0,
      'ui_build_time_ms': double.parse(effectiveBuildMs.toStringAsFixed(2)),
      'p90_ui_build_time_ms': double.parse(p90BuildMs.toStringAsFixed(2)),
      'p99_ui_build_time_ms': double.parse(p99BuildMs.toStringAsFixed(2)),
      'raster_time_ms': double.parse(effectiveRasterMs.toStringAsFixed(2)),
      'p99_raster_time_ms': double.parse(p99RasterMs.toStringAsFixed(2)),
      'actual_fps': double.parse(fps.toStringAsFixed(1)),
      'jank_rate_pct': double.parse(effectiveJankRate.toStringAsFixed(2)),
      'memory_rss_mb': (pipelineMetrics['memory_rss_mb'] as num).toDouble(),
      'scroll_animation': enableScrollAnim,
      'theme_rotation': enableThemeRotation,
      'ticker_rotation': enableTickerRotation,
      'duration_sec': durationSec,
    };

    print('__BENCHMARK_RAW_OUTPUT__:${jsonEncode(result)}');

    final outDir = Directory('build/benchmark');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final jsonFile = File('${outDir.path}/order_book_perf.json');
    jsonFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(summary.summaryJson));
    await summary.writeTimelineToFile('order_book_timeline', destinationDirectory: outDir.path, pretty: true);
  } finally {
    await driver?.close();
  }
}

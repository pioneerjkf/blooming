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
  final themeIntervalIndexStr =
      Platform.environment['BENCH_THEME_INTERVAL_INDEX'] ?? '0';
  final tickerRotStr = Platform.environment['BENCH_TICKER_ROTATION'] ?? 'true';
  final tickerIntervalIndexStr =
      Platform.environment['BENCH_TICKER_INTERVAL_INDEX'] ?? '0';

  final targetTps = int.parse(targetTpsStr);
  final durationSec = int.parse(durationStr);
  final warmupSec = int.parse(warmupStr);
  final enableScrollAnim = scrollAnimStr.toLowerCase() == 'true';
  final enableThemeRotation = themeRotStr.toLowerCase() == 'true';
  final themeIntervalIndex = int.tryParse(themeIntervalIndexStr) ?? 0;
  final enableTickerRotation = tickerRotStr.toLowerCase() == 'true';
  final tickerIntervalIndex = int.tryParse(tickerIntervalIndexStr) ?? 0;

  final setIndex =
      int.tryParse(Platform.environment['BENCH_SET_INDEX'] ?? '1') ?? 1;
  final totalSets =
      int.tryParse(Platform.environment['BENCH_TOTAL_SETS'] ?? '1') ?? 1;
  final targetIndex =
      int.tryParse(Platform.environment['BENCH_TARGET_INDEX'] ?? '1') ?? 1;
  final totalTargets =
      int.tryParse(Platform.environment['BENCH_TOTAL_TARGETS'] ?? '1') ?? 1;
  final runIndex =
      int.tryParse(Platform.environment['BENCH_RUN_INDEX'] ?? '1') ?? 1;
  final totalRuns =
      int.tryParse(Platform.environment['BENCH_TOTAL_RUNS'] ?? '1') ?? 1;

  FlutterDriver? driver;
  try {
    driver = await FlutterDriver.connect();

    await driver.requestData(
        'set_progress:$setIndex:$totalSets:$targetIndex:$totalTargets:$runIndex:$totalRuns');
    await driver.requestData('set_scroll_anim:$enableScrollAnim');
    await driver.requestData(
        'set_theme_rotation:$enableThemeRotation:$themeIntervalIndex');
    await driver.requestData(
        'set_ticker_rotation:$enableTickerRotation:$tickerIntervalIndex');
    await driver.requestData('set_tps:$targetTps');
    await Future.delayed(Duration(seconds: warmupSec));

    // Start lag sampling exactly at the measurement window start.

    await driver.requestData('lag_reset');

    final timeline = await driver.traceAction(() async {
      await Future.delayed(Duration(seconds: durationSec));
    });

    final summary = TimelineSummary.summarize(timeline);

    final metricsJson = await driver.requestData('get_metrics');
    final Map<String, dynamic> pipelineMetrics = jsonDecode(metricsJson);

    final displayRefreshRate =
        (pipelineMetrics['display_refresh_rate'] as num?)?.toDouble() ?? 120.0;
    final frameBudgetUs = displayRefreshRate > 0
        ? (1000000.0 / displayRefreshRate).round()
        : 8333;

    final frameCount = summary.countFrames();
    double avgBuildMs = 0.0;
    double p90BuildMs = 0.0;
    double p99BuildMs = 0.0;
    double avgRasterMs = 0.0;
    double p99RasterMs = 0.0;
    double? jankRate;

    if (frameCount > 0) {
      try {
        final builds = _extractFrames(timeline, kBuildFrameEventName);
        final rasters = _extractFrames(timeline, kRasterizeFrameEventName);

        int rasterIdx = 0;
        int jankCount = 0;
        int pairedCount = 0;

        for (final b in builds) {
          while (rasterIdx < rasters.length &&
              rasters[rasterIdx].startUs < b.endUs) {
            rasterIdx++;
          }
          if (rasterIdx < rasters.length) {
            final r = rasters[rasterIdx];
            pairedCount++;
            if (b.durationUs > frameBudgetUs || r.durationUs > frameBudgetUs) {
              jankCount++;
            }
            rasterIdx++;
          }
        }

        if (pairedCount > 0) {
          jankRate = (jankCount / pairedCount) * 100.0;
        } else {
          jankRate = null;
        }

        avgBuildMs = summary.computeAverageFrameBuildTimeMillis();
        p90BuildMs = summary.computePercentileFrameBuildTimeMillis(90.0);
        p99BuildMs = summary.computePercentileFrameBuildTimeMillis(99.0);
        avgRasterMs = summary.computeAverageFrameRasterizerTimeMillis();
        p99RasterMs = summary.computePercentileFrameRasterizerTimeMillis(99.0);
      } catch (_) {
        // Fallback gracefully if TimelineSummary cannot summarize events
      }
    }

    // -------------------------------------------------------------------------
    // [Data Source A] In-App Flutter Engine Live FrameTiming Metrics (Recent 60 frames fallback)
    // -------------------------------------------------------------------------
    final appInternalBuildMs =
        (pipelineMetrics['ui_build_time_ms'] as num?)?.toDouble() ?? 0.0;
    final appInternalRasterMs =
        (pipelineMetrics['raster_time_ms'] as num?)?.toDouble() ?? 0.0;
    final appInternalJankPct =
        (pipelineMetrics['jank_rate_pct'] as num?)?.toDouble() ?? 0.0;

    // -------------------------------------------------------------------------
    // [Data Source B] External Flutter Driver VM Timeline Trace Analysis (Full Duration Primary)
    // -------------------------------------------------------------------------
    final effectiveBuildMs =
        avgBuildMs > 0 ? avgBuildMs : appInternalBuildMs;
    final effectiveRasterMs =
        avgRasterMs > 0 ? avgRasterMs : appInternalRasterMs;
    final effectiveJankRate = frameCount > 0
        ? jankRate
        : (appInternalBuildMs > 0 ? appInternalJankPct : null);

    final lagStats = (pipelineMetrics['lag_stats'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};

    double? lagStat(String k) => (lagStats[k] as num?)?.toDouble();

    final result = {
      'framework': 'Signals',
      'architecture': 'Signals Reactive Fine-Grained Architecture',
      'target_tps': targetTps,
      'sustained_tps': (pipelineMetrics['sustained_tps'] as num).toInt(),
      'generator_tps': ((pipelineMetrics['generator_tps'] ??
              pipelineMetrics['sustained_tps']) as num)
          .toInt(),
      'framework_update_rate_hz':
          (pipelineMetrics['framework_update_rate_hz'] as num?)?.toInt() ?? 0,
      'total_ticks': (pipelineMetrics['total_ticks'] as num).toInt(),
      'total_batches':
          (pipelineMetrics['total_batches'] as num?)?.toInt() ?? 0,
      'avg_event_loop_lag_ms': lagStat('mean') == null
          ? null
          : double.parse(lagStat('mean')!.toStringAsFixed(3)),
      'median_event_loop_lag_ms': lagStat('median') == null
          ? null
          : double.parse(lagStat('median')!.toStringAsFixed(3)),
      'p95_event_loop_lag_ms': lagStat('p95') == null
          ? null
          : double.parse(lagStat('p95')!.toStringAsFixed(3)),
      'p99_event_loop_lag_ms': lagStat('p99') == null
          ? null
          : double.parse(lagStat('p99')!.toStringAsFixed(3)),
      'max_event_loop_lag_ms': lagStat('max') == null
          ? null
          : double.parse(lagStat('max')!.toStringAsFixed(3)),
      'lag_sample_count': lagStats['count'] ?? 0,
      'ui_build_time_ms': effectiveBuildMs > 0
          ? double.parse(effectiveBuildMs.toStringAsFixed(2))
          : null,
      'p90_ui_build_time_ms': p90BuildMs > 0
          ? double.parse(p90BuildMs.toStringAsFixed(2))
          : null,
      'p99_ui_build_time_ms': p99BuildMs > 0
          ? double.parse(p99BuildMs.toStringAsFixed(2))
          : null,
      'raster_time_ms': effectiveRasterMs > 0
          ? double.parse(effectiveRasterMs.toStringAsFixed(2))
          : null,
      'p99_raster_time_ms': p99RasterMs > 0
          ? double.parse(p99RasterMs.toStringAsFixed(2))
          : null,
      'jank_rate_pct': effectiveJankRate != null
          ? double.parse(effectiveJankRate.toStringAsFixed(2))
          : null,
      'display_refresh_rate': displayRefreshRate,
      'frame_budget_ms':
          double.parse((frameBudgetUs / 1000.0).toStringAsFixed(2)),
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
    jsonFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(summary.summaryJson));
    await summary.writeTimelineToFile('order_book_timeline',
        destinationDirectory: outDir.path, pretty: true);
  } finally {
    await driver?.close();
  }
}

class _FrameRecord {
  const _FrameRecord({
    required this.startUs,
    required this.endUs,
    required this.durationUs,
  });
  final int startUs;
  final int endUs;
  final int durationUs;
}

List<_FrameRecord> _extractFrames(Timeline timeline, String eventName) {
  final result = <_FrameRecord>[];
  TimelineEvent? begin;
  for (final event in timeline.events ?? const <TimelineEvent>[]) {
    if (event.name != eventName) continue;
    if ((event.phase == 'X' || event.duration != null) &&
        event.timestampMicros != null &&
        event.duration != null) {
      final start = event.timestampMicros!;
      final dur = event.duration!.inMicroseconds;
      if (dur > 0) {
        result.add(_FrameRecord(
          startUs: start,
          endUs: start + dur,
          durationUs: dur,
        ));
      }
    } else if (event.phase == 'B' || event.phase == 'b') {
      begin = event;
    } else if (event.phase == 'E' || event.phase == 'e') {
      if (begin != null &&
          begin.timestampMicros != null &&
          event.timestampMicros != null) {
        final start = begin.timestampMicros!;
        final end = event.timestampMicros!;
        if (end >= start) {
          result.add(_FrameRecord(
            startUs: start,
            endUs: end,
            durationUs: end - start,
          ));
        }
        begin = null;
      }
    }
  }
  return result;
}

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasdaq_mini_coralline/src/pipeline/order_book_pipeline.dart';
import 'package:nasdaq_mini_coralline/src/ui/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Coralline Headless Benchmark Ingestion Test', () async {
    final targetTpsStr = Platform.environment['BENCH_TPS'] ?? '100000';
    final durationStr = Platform.environment['BENCH_DURATION'] ?? '2';
    final warmupStr = Platform.environment['BENCH_WARMUP'] ?? '1';
    final themeRotStr = Platform.environment['BENCH_THEME_ROTATION'] ?? 'true';
    final themeIntervalIndexStr =
        Platform.environment['BENCH_THEME_INTERVAL_INDEX'] ?? '0';
    final tickerRotStr =
        Platform.environment['BENCH_TICKER_ROTATION'] ?? 'true';
    final tickerIntervalIndexStr =
        Platform.environment['BENCH_TICKER_INTERVAL_INDEX'] ?? '0';

    final targetTps = int.parse(targetTpsStr);
    final durationSec = int.parse(durationStr);
    final warmupSec = int.parse(warmupStr);
    final enableThemeRotation = themeRotStr.toLowerCase() == 'true';
    final themeIntervalIndex = int.tryParse(themeIntervalIndexStr) ?? 0;
    final enableTickerRotation = tickerRotStr.toLowerCase() == 'true';
    final tickerIntervalIndex = int.tryParse(tickerIntervalIndexStr) ?? 0;

    final pipeline = OrderBookPipeline();
    pipeline.setTargetTps(targetTps);
    // Scroll animation requires a Flutter UI render tree and VSync ticker,
    // which does not exist in headless mode. Marked false in headless execution.
    pipeline.setScrollAnimationEnabled(false);

    if (enableTickerRotation) {
      pipeline.setRotationIntervalIndex(tickerIntervalIndex);
      pipeline.startAutoRotation();
    }

    final themeStore = NasdaqThemeStore();
    if (enableThemeRotation) {
      themeStore.setRotationIntervalIndex(themeIntervalIndex);
      themeStore.startAutoRotation();
    }

    await pipeline.startSimulation();

    // 1. Warmup stage
    await Future.delayed(Duration(seconds: warmupSec));

    // 2. Pure hardware measurement stage
    final startTicks = pipeline.snapshotValue.totalTicksProcessed;
    final startBatches = pipeline.totalBatchesProcessed;
    pipeline.lagRecorder.reset();
    final stopwatch = Stopwatch()..start();

    await Future.delayed(Duration(seconds: durationSec));
    final lagStats = pipeline.lagRecorder.stats();
    stopwatch.stop();

    final endTicks = pipeline.snapshotValue.totalTicksProcessed;
    final endBatches = pipeline.totalBatchesProcessed;
    final actualTicks = endTicks - startTicks;
    final actualBatches = endBatches - startBatches;
    final elapsedSec = stopwatch.elapsedMicroseconds / 1000000.0;
    final sustainedTps = (actualTicks / elapsedSec).round();
    final batchRate = (actualBatches / elapsedSec).round();
    final latency = pipeline.latencyMsValue;
    final memoryRssMb = ProcessInfo.currentRss / (1024 * 1024);

    if (enableTickerRotation) {
      pipeline.stopAutoRotation();
    }
    if (enableThemeRotation) {
      themeStore.stopAutoRotation();
    }
    pipeline.stopSimulation();
    pipeline.dispose();

    double? lagStat(String k) => (lagStats[k] as num?)?.toDouble();

    final result = {
      'framework': 'Coralline',
      'architecture': 'Coralline High-Performance Reactive Graph',
      'target_tps': targetTps,
      'sustained_tps': sustainedTps,
      'generator_tps': sustainedTps,
      'framework_update_rate_hz': batchRate,
      'total_ticks': actualTicks,
      'total_batches': actualBatches,
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
      'latency_ms': double.parse(latency.toStringAsFixed(2)),
      'memory_rss_mb': double.parse(memoryRssMb.toStringAsFixed(1)),
      'scroll_animation': false,
      'theme_rotation': enableThemeRotation,
      'theme_interval_index': themeIntervalIndex,
      'ticker_rotation': enableTickerRotation,
      'ticker_interval_index': tickerIntervalIndex,
      'duration_sec': durationSec,
    };

    print('__BENCHMARK_RAW_OUTPUT__:${jsonEncode(result)}');
  });
}

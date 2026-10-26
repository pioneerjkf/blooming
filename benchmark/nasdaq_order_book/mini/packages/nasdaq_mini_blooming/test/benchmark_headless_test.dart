// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasdaq_mini_blooming/src/pipeline/order_book_pipeline.dart';
import 'package:blooming/blooming.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Blooming Headless Benchmark Ingestion Test', () async {
    final targetTpsStr = Platform.environment['BENCH_TPS'] ?? '100000';
    final durationStr = Platform.environment['BENCH_DURATION'] ?? '2';
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

    final pipeline = OrderBookPipeline();
    pipeline.setTargetTps(targetTps);
    if (enableTickerRotation) {
      pipeline.setRotationIntervalIndex(tickerIntervalIndex);
      pipeline.startAutoRotation();
    }
    pipeline.startSimulation();

    // 1. Warmup stage
    await Future.delayed(Duration(seconds: warmupSec));

    // 2. Pure hardware measurement stage
    final startTicks = untracked(pipeline.snapshotBloom).totalTicksProcessed;
    final stopwatch = Stopwatch()..start();
    final List<double> lags = [];

    final timer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      lags.add(untracked(pipeline.eventLoopLagBloom));
    });

    await Future.delayed(Duration(seconds: durationSec));
    timer.cancel();
    stopwatch.stop();

    final endTicks = untracked(pipeline.snapshotBloom).totalTicksProcessed;
    final actualTicks = endTicks - startTicks;
    final elapsedSec = stopwatch.elapsedMicroseconds / 1000000.0;
    final sustainedTps = (actualTicks / elapsedSec).round();
    final latency = untracked(pipeline.latencyMsBloom);
    final memoryRssMb = ProcessInfo.currentRss / (1024 * 1024);

    if (enableTickerRotation) {
      pipeline.stopAutoRotation();
    }
    pipeline.stopSimulation();
    pipeline.dispose();

    lags.sort();
    final double? avgLag = lags.isEmpty ? null : lags.reduce((a, b) => a + b) / lags.length;
    final double? p95Lag = lags.isEmpty ? null : lags[((lags.length - 1) * 0.95).floor()];
    final double? p99Lag = lags.isEmpty ? null : lags[((lags.length - 1) * 0.99).floor()];

    final result = {
      'framework': 'Blooming',
      'architecture': 'Blooming 2-Phase LPDAG Reactive Graph',
      'target_tps': targetTps,
      'sustained_tps': sustainedTps,
      'total_ticks': actualTicks,
      'avg_event_loop_lag_ms': avgLag != null ? double.parse(avgLag.toStringAsFixed(2)) : null,
      'p95_event_loop_lag_ms': p95Lag != null ? double.parse(p95Lag.toStringAsFixed(2)) : null,
      'p99_event_loop_lag_ms': p99Lag != null ? double.parse(p99Lag.toStringAsFixed(2)) : null,
      'latency_ms': double.parse(latency.toStringAsFixed(2)),
      'memory_rss_mb': double.parse(memoryRssMb.toStringAsFixed(1)),
      'scroll_animation': enableScrollAnim,
      'theme_rotation': enableThemeRotation,
      'theme_interval_index': themeIntervalIndex,
      'ticker_rotation': enableTickerRotation,
      'ticker_interval_index': tickerIntervalIndex,
      'duration_sec': durationSec,
    };

    print('__BENCHMARK_RAW_OUTPUT__:${jsonEncode(result)}');
  });
}

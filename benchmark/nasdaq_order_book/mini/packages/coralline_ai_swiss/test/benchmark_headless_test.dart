// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasdaq_order_benchmark_coralline_ai_swiss/src/pipeline/order_book_pipeline.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Coralline Headless Benchmark Ingestion Test', () async {
    final targetTpsStr = Platform.environment['BENCH_TPS'] ?? '100000';
    final durationStr = Platform.environment['BENCH_DURATION'] ?? '2';
    final warmupStr = Platform.environment['BENCH_WARMUP'] ?? '1';
    final scrollAnimStr = Platform.environment['BENCH_SCROLL_ANIM'] ?? 'true';

    final targetTps = int.parse(targetTpsStr);
    final durationSec = int.parse(durationStr);
    final warmupSec = int.parse(warmupStr);
    final enableScrollAnim = scrollAnimStr.toLowerCase() == 'true';

    final pipeline = OrderBookPipeline();
    pipeline.setTargetTps(targetTps);
    pipeline.startSimulation();

    // 1. Warmup stage
    await Future.delayed(Duration(seconds: warmupSec));

    // 2. Pure hardware measurement stage
    final startTicks = pipeline.snapshotValue.totalTicksProcessed;
    final stopwatch = Stopwatch()..start();
    final List<double> lags = [];

    final timer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      lags.add(pipeline.eventLoopLagValue);
    });

    await Future.delayed(Duration(seconds: durationSec));
    timer.cancel();
    stopwatch.stop();

    final endTicks = pipeline.snapshotValue.totalTicksProcessed;
    final actualTicks = endTicks - startTicks;
    final elapsedSec = stopwatch.elapsedMicroseconds / 1000000.0;
    final sustainedTps = (actualTicks / elapsedSec).round();
    final latency = pipeline.latencyMsValue;
    final memoryRssMb = ProcessInfo.currentRss / (1024 * 1024);

    pipeline.stopSimulation();
    pipeline.dispose();

    lags.sort();
    final double? avgLag = lags.isEmpty ? null : lags.reduce((a, b) => a + b) / lags.length;
    final double? p95Lag = lags.isEmpty ? null : lags[((lags.length - 1) * 0.95).floor()];
    final double? p99Lag = lags.isEmpty ? null : lags[((lags.length - 1) * 0.99).floor()];

    final result = {
      'framework': 'Coralline',
      'architecture': 'Coralline High-Performance Reactive Graph',
      'target_tps': targetTps,
      'sustained_tps': sustainedTps,
      'total_ticks': actualTicks,
      'avg_event_loop_lag_ms': avgLag != null ? double.parse(avgLag.toStringAsFixed(2)) : null,
      'p95_event_loop_lag_ms': p95Lag != null ? double.parse(p95Lag.toStringAsFixed(2)) : null,
      'p99_event_loop_lag_ms': p99Lag != null ? double.parse(p99Lag.toStringAsFixed(2)) : null,
      'latency_ms': double.parse(latency.toStringAsFixed(2)),
      'memory_rss_mb': double.parse(memoryRssMb.toStringAsFixed(1)),
      'scroll_animation': enableScrollAnim,
      'duration_sec': durationSec,
    };

    print('__BENCHMARK_RAW_OUTPUT__:${jsonEncode(result)}');
  });
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:nasdaq_mini_coralline/src/pipeline/order_book_pipeline.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  int targetTps = 100000;
  int durationSec = 3;
  int warmupSec = 1;

  for (final arg in args) {
    if (arg.startsWith('--tps=')) {
      targetTps = int.parse(arg.substring('--tps='.length));
    } else if (arg.startsWith('--duration=')) {
      durationSec = int.parse(arg.substring('--duration='.length));
    } else if (arg.startsWith('--warmup=')) {
      warmupSec = int.parse(arg.substring('--warmup='.length));
    }
  }

  final pipeline = OrderBookPipeline();
  pipeline.setTargetTps(targetTps);
  pipeline.startSimulation();

  // Warmup stage
  await Future.delayed(Duration(seconds: warmupSec));

  // Real measurement stage
  final startTicks = pipeline.snapshotValue.totalTicksProcessed;
  final stopwatch = Stopwatch()..start();
  final List<double> lags = [];

  final timer = Timer.periodic(const Duration(milliseconds: 20), (_) {
    lags.add(pipeline.eventLoopLagProvider.coral.data);
  });

  await Future.delayed(Duration(seconds: durationSec));
  timer.cancel();
  stopwatch.stop();

  final endTicks = pipeline.snapshotValue.totalTicksProcessed;
  final actualTicks = endTicks - startTicks;
  final elapsedSec = stopwatch.elapsedMicroseconds / 1000000.0;
  final sustainedTps = (actualTicks / elapsedSec).round();
  final latency = pipeline.latencyMsValue;

  pipeline.stopSimulation();
  pipeline.dispose();

  lags.sort();
  final double? avgLag =
      lags.isEmpty ? null : lags.reduce((a, b) => a + b) / lags.length;
  final double? p95Lag =
      lags.isEmpty ? null : lags[((lags.length - 1) * 0.95).floor()];
  final double? p99Lag =
      lags.isEmpty ? null : lags[((lags.length - 1) * 0.99).floor()];

  final result = {
    'framework': 'Coralline',
    'architecture': 'Coralline High-Performance Reactive Graph',
    'target_tps': targetTps,
    'sustained_tps': sustainedTps,
    'total_ticks': actualTicks,
    'avg_event_loop_lag_ms':
        avgLag != null ? double.parse(avgLag.toStringAsFixed(2)) : null,
    'p95_event_loop_lag_ms':
        p95Lag != null ? double.parse(p95Lag.toStringAsFixed(2)) : null,
    'p99_event_loop_lag_ms':
        p99Lag != null ? double.parse(p99Lag.toStringAsFixed(2)) : null,
    'latency_ms': double.parse(latency.toStringAsFixed(2)),
    'duration_sec': durationSec,
  };

  stdout.writeln('__BENCHMARK_RAW_OUTPUT__:${jsonEncode(result)}');
  exit(0);
}

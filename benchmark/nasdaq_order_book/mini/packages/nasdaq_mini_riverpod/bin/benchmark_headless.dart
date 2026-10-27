import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasdaq_mini_riverpod/src/pipeline/order_book_pipeline.dart';
import 'package:nasdaq_mini_riverpod/src/providers/order_book_providers.dart';

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

  final container = ProviderContainer();
  final pipeline = OrderBookPipeline(container);
  pipeline.setTargetTps(targetTps);
  pipeline.startSimulation();

  // Warmup stage
  await Future.delayed(Duration(seconds: warmupSec));

  // Real measurement stage
  final startTicks = container.read(snapshotProvider).totalTicksProcessed;
  pipeline.lagRecorder.reset();
  final stopwatch = Stopwatch()..start();

  await Future.delayed(Duration(seconds: durationSec));
  final lagStats = pipeline.lagRecorder.stats();
  stopwatch.stop();

  final endTicks = container.read(snapshotProvider).totalTicksProcessed;
  final actualTicks = endTicks - startTicks;
  final elapsedSec = stopwatch.elapsedMicroseconds / 1000000.0;
  final sustainedTps = (actualTicks / elapsedSec).round();
  final latency = container.read(latencyMsProvider);

  pipeline.stopSimulation();
  pipeline.dispose();
  container.dispose();

  double? lagStat(String k) => (lagStats[k] as num?)?.toDouble();

  final result = {
    'framework': 'Riverpod',
    'architecture': 'Flutter Riverpod State Management',
    'target_tps': targetTps,
    'sustained_tps': sustainedTps,
    'total_ticks': actualTicks,
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
    'duration_sec': durationSec,
  };

  stdout.writeln('__BENCHMARK_RAW_OUTPUT__:${jsonEncode(result)}');
  exit(0);
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

// =============================================================================
// NASDAQ ORDER BOOK MINI - COMPREHENSIVE BENCHMARK SUITE
// SUPPORTS BOTH:
// 1. PURE FLUTTER DRIVER (Real Windows GPU/VSync Frame Timings & TPS)
// 2. HEADLESS SUBPROCESS (Fast Pure Isolate Pipeline & Event Loop Lag)
// =============================================================================

/// Target Framework Metadata
class BenchmarkTarget {
  const BenchmarkTarget({
    required this.id,
    required this.name,
    required this.architecture,
    required this.directoryName,
  });

  final String id;
  final String name;
  final String architecture;
  final String directoryName;
}

/// Target Frameworks Under Comparison
const List<BenchmarkTarget> benchmarkTargets = [
  BenchmarkTarget(
    id: 'blooming',
    name: 'Blooming',
    architecture: 'Blooming 2-Phase LPDAG Reactive Graph',
    directoryName: 'blooming_ai_swiss',
  ),
  BenchmarkTarget(
    id: 'coralline',
    name: 'Coralline',
    architecture: 'Coralline High-Performance Reactive Graph',
    directoryName: 'coralline_ai_swiss',
  ),
  BenchmarkTarget(
    id: 'signals',
    name: 'Signals',
    architecture: 'Signals Reactive Fine-Grained Architecture',
    directoryName: 'signals_ai_swiss',
  ),
  BenchmarkTarget(
    id: 'riverpod',
    name: 'Riverpod',
    architecture: 'Flutter Riverpod State Management',
    directoryName: 'riverpod_ai_swiss',
  ),
  BenchmarkTarget(
    id: 'flutter',
    name: 'Flutter',
    architecture: 'Pure Flutter (ValueNotifier & ListenableBuilder)',
    directoryName: 'flutter_ai_swiss',
  ),
];

/// Pure hardware measurement result data point
class BenchmarkRunResult {
  const BenchmarkRunResult({
    required this.target,
    required this.targetTps,
    required this.sustainedTps,
    required this.totalTicks,
    required this.avgEventLoopLagMs,
    required this.p95EventLoopLagMs,
    required this.p99EventLoopLagMs,
    required this.latencyMs,
    required this.memoryRssMb,
    required this.uiBuildTimeMs,
    required this.rasterTimeMs,
    required this.actualFps,
    required this.jankRatePct,
    required this.durationSec,
    this.scrollAnimation = true,
    this.setIndex = 1,
    this.medianEventLoopLagMs,
    this.maxEventLoopLagMs,
    this.lagSampleCount,
  });

  final BenchmarkTarget target;
  final int targetTps;
  final int sustainedTps;
  final int totalTicks;
  final double? avgEventLoopLagMs;
  final double? p95EventLoopLagMs;
  final double? p99EventLoopLagMs;
  final double latencyMs;
  final double memoryRssMb;
  final double uiBuildTimeMs;
  final double rasterTimeMs;
  final double actualFps;
  final double jankRatePct;
  final int durationSec;
  final bool scrollAnimation;
  final int setIndex;
  final double? medianEventLoopLagMs;
  final double? maxEventLoopLagMs;
  final int? lagSampleCount;

  double get achievementRate => targetTps > 0
      ? ((sustainedTps / targetTps) * 100).clamp(0.0, 100.0)
      : 0.0;

  Map<String, dynamic> toJson() => {
        'target_id': target.id,
        'framework': target.name,
        'architecture': target.architecture,
        'set_index': setIndex,
        'scroll_animation': scrollAnimation,
        'target_tps': targetTps,
        'sustained_tps': sustainedTps,
        'achievement_rate_pct':
            double.parse(achievementRate.toStringAsFixed(2)),
        'total_ticks': totalTicks,
        'avg_event_loop_lag_ms': avgEventLoopLagMs != null
            ? double.parse(avgEventLoopLagMs!.toStringAsFixed(3))
            : null,
        'median_event_loop_lag_ms': medianEventLoopLagMs != null
            ? double.parse(medianEventLoopLagMs!.toStringAsFixed(3))
            : null,
        'p95_event_loop_lag_ms': p95EventLoopLagMs != null
            ? double.parse(p95EventLoopLagMs!.toStringAsFixed(3))
            : null,
        'p99_event_loop_lag_ms': p99EventLoopLagMs != null
            ? double.parse(p99EventLoopLagMs!.toStringAsFixed(3))
            : null,
        'max_event_loop_lag_ms': maxEventLoopLagMs != null
            ? double.parse(maxEventLoopLagMs!.toStringAsFixed(3))
            : null,
        'lag_sample_count': lagSampleCount,
        'ui_build_time_ms': double.parse(uiBuildTimeMs.toStringAsFixed(2)),
        'raster_time_ms': double.parse(rasterTimeMs.toStringAsFixed(2)),
        'actual_fps': double.parse(actualFps.toStringAsFixed(1)),
        'jank_rate_pct': double.parse(jankRatePct.toStringAsFixed(2)),
        'latency_ms': double.parse(latencyMs.toStringAsFixed(2)),
        'memory_rss_mb': double.parse(memoryRssMb.toStringAsFixed(1)),
        'duration_sec': durationSec,
      };
}

void main(List<String> args) async {
  print('================================================================');
  print('⚡ NASDAQ ORDER BOOK MINI - COMPREHENSIVE BENCHMARK SUITE');
  print('================================================================');

  List<int> tpsScenarios = [1000000000];
  int durationSec = 30;
  int warmupSec = 5;
  int setsCount = 10;
  bool shuffleOrder = true;
  bool scrollAnimation = true;
  String outputDir = 'results';
  String mode =
      'drive'; // Default to Real Windows GPU Flutter Driver E2E Benchmarking
  List<BenchmarkTarget> effectiveTargets = List.from(benchmarkTargets);

  for (final arg in args) {
    if (arg.startsWith('--tps=')) {
      final val = arg.substring('--tps='.length);
      tpsScenarios = val.split(',').map((s) => int.parse(s.trim())).toList();
    } else if (arg.startsWith('--duration=')) {
      durationSec = int.parse(arg.substring('--duration='.length));
    } else if (arg.startsWith('--warmup=')) {
      warmupSec = int.parse(arg.substring('--warmup='.length));
    } else if (arg.startsWith('--output-dir=')) {
      outputDir = arg.substring('--output-dir='.length);
    } else if (arg.startsWith('--mode=')) {
      mode = arg.substring('--mode='.length);
    } else if (arg.startsWith('--sets=')) {
      setsCount = int.parse(arg.substring('--sets='.length));
    } else if (arg.startsWith('--target=') || arg.startsWith('--framework=')) {
      final filterId = (arg.startsWith('--target=')
              ? arg.substring('--target='.length)
              : arg.substring('--framework='.length))
          .toLowerCase();
      effectiveTargets = effectiveTargets
          .where((t) =>
              t.id.toLowerCase() == filterId ||
              t.name.toLowerCase() == filterId)
          .toList();
    } else if (arg == '--shuffle' || arg == '--random-order') {
      shuffleOrder = true;
    } else if (arg == '--no-shuffle') {
      shuffleOrder = false;
    } else if (arg.startsWith('--shuffle=')) {
      shuffleOrder = arg.split('=').last.toLowerCase() == 'true';
    } else if (arg == '--scroll-anim' || arg == '--scroll') {
      scrollAnimation = true;
    } else if (arg == '--no-scroll-anim' || arg == '--no-scroll') {
      scrollAnimation = false;
    } else if (arg.startsWith('--scroll-anim=') ||
        arg.startsWith('--order-book-scroll=') ||
        arg.startsWith('--scroll=')) {
      final val = arg.split('=').last.toLowerCase();
      scrollAnimation = val == 'true';
    }
  }

  print('Configuration:');
  print('  • Scenarios (TPS): $tpsScenarios');
  print('  • Duration: ${durationSec}s per scenario (Warmup: ${warmupSec}s)');
  print(
      '  • Total Sets: $setsCount set(s) (Order Shuffling: ${shuffleOrder ? "RANDOMIZED" : "SEQUENTIAL"})');
  print(
      '  • Scroll Animation: ${scrollAnimation ? "ENABLED (Oscillating VSync)" : "DISABLED (Static Center)"}');
  print(
      '  • Target Frameworks: ${effectiveTargets.map((t) => t.name).join(', ')}');
  print(
      '  • Execution Mode: ${mode.toUpperCase()} (${mode == 'drive' ? 'Flutter Driver Real Window' : 'Fast Subprocess Isolate'})');
  print('  • Output Directory: $outputDir\n');

  final List<BenchmarkRunResult> allResults = [];
  String currentDir = Directory.current.path;
  String miniDir = currentDir;
  String packagesDir = currentDir;

  if (effectiveTargets.isNotEmpty) {
    final firstTarget = effectiveTargets.first.directoryName;
    if (Directory('$currentDir/$firstTarget').existsSync()) {
      packagesDir = currentDir;
      miniDir = currentDir;
    } else if (Directory('$currentDir/packages/$firstTarget').existsSync()) {
      packagesDir = '$currentDir/packages';
      miniDir = currentDir;
    } else {
      try {
        final scriptDir = File(Platform.script.toFilePath()).parent.parent.path;
        miniDir = scriptDir;
        if (Directory('$scriptDir/$firstTarget').existsSync()) {
          packagesDir = scriptDir;
        } else if (Directory('$scriptDir/packages/$firstTarget').existsSync()) {
          packagesDir = '$scriptDir/packages';
        }
      } catch (_) {}
    }
  }
  final random = Random();

  final totalRuns = setsCount * effectiveTargets.length * tpsScenarios.length;
  int currentRunIndex = 0;

  for (int setIndex = 1; setIndex <= setsCount; setIndex++) {
    if (setsCount > 1) {
      print('================================================================');
      print('🎲 BENCHMARK SET $setIndex of $setsCount');
      print('================================================================');
    }

    final currentTargets = List<BenchmarkTarget>.from(effectiveTargets);
    if (shuffleOrder) {
      currentTargets.shuffle(random);
      print('  🔀 Randomized Execution Order for Set $setIndex:');
      print('     ${currentTargets.map((t) => t.name).join(' ➔ ')}\n');
    }

    int targetIndex = 0;
    for (final target in currentTargets) {
      targetIndex++;
      print('----------------------------------------------------------------');
      print(
          '🚀 [Set $setIndex/$setsCount] [Bench $targetIndex/${currentTargets.length}] Measuring: ${target.name} [${target.architecture}]');
      print('----------------------------------------------------------------');

      final targetDir = '$packagesDir/${target.directoryName}';

      for (final targetTps in tpsScenarios) {
        currentRunIndex++;
        final result = mode == 'drive'
            ? await _runFlutterDriverBenchmark(
                target: target,
                targetDir: targetDir,
                targetTps: targetTps,
                durationSec: durationSec,
                warmupSec: warmupSec,
                scrollAnimation: scrollAnimation,
                setIndex: setIndex,
                setsCount: setsCount,
                targetIndex: targetIndex,
                totalTargets: currentTargets.length,
                runIndex: currentRunIndex,
                totalRuns: totalRuns,
              )
            : await _runHeadlessSubprocessBenchmark(
                target: target,
                targetDir: targetDir,
                targetTps: targetTps,
                durationSec: durationSec,
                warmupSec: warmupSec,
                scrollAnimation: scrollAnimation,
                setIndex: setIndex,
                setsCount: setsCount,
                targetIndex: targetIndex,
                totalTargets: currentTargets.length,
                runIndex: currentRunIndex,
                totalRuns: totalRuns,
              );

        allResults.add(result);
        final lagPrint = result.avgEventLoopLagMs != null
            ? '${result.avgEventLoopLagMs!.toStringAsFixed(2)}ms'
            : 'N/A';
        print(
          '  → ${_formatNum(targetTps)} TPS (${durationSec}s) DONE! Sustained: ${_formatNum(result.sustainedTps)} TPS (${result.achievementRate.toStringAsFixed(1)}%) | Lag: $lagPrint | RSS: ${result.memoryRssMb.toStringAsFixed(1)}MB | UI Build: ${result.uiBuildTimeMs > 0 ? '${result.uiBuildTimeMs}ms' : 'N/A'}',
        );
      }
      print('');
    }
  }

  print('================================================================');
  print('📝 GENERATING 100% PURE HARDWARE ARTIFACTS & CHARTS');
  print('================================================================');

  final rootOutDir = Directory('$miniDir/$outputDir');
  if (!rootOutDir.existsSync()) {
    rootOutDir.createSync(recursive: true);
  }

  // Calculate timestamp + 3-digit daily sequence folder: YYYYMMDD_HHMMSS_###
  final now = DateTime.now();
  final dateStr =
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final timeStr =
      '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

  // Count existing runs for today
  int todayRunCount = 0;
  try {
    final existingDirs = rootOutDir.listSync().whereType<Directory>();
    for (final dir in existingDirs) {
      final name = dir.path.split(Platform.pathSeparator).last;
      if (name.startsWith(dateStr)) {
        todayRunCount++;
      }
    }
  } catch (_) {}

  final seqStr = (todayRunCount + 1).toString().padLeft(3, '0');
  final runFolderName = '${dateStr}_${timeStr}_$seqStr';
  final outDir = Directory('${rootOutDir.path}/$runFolderName');
  outDir.createSync(recursive: true);

  print('  📁 Destination Run Directory: ${outDir.path}');

  // 1. Generate Markdown Report
  final mdReportSub = _generateMediumMarkdownReport(
      allResults, tpsScenarios, durationSec, mode, setsCount, scrollAnimation,
      methodologyRelPath: '../../BENCHMARK_METHODOLOGY.md');
  final mdFile = File('${outDir.path}/SUMMARY_REPORT.md');
  mdFile.writeAsStringSync(mdReportSub);
  print('  ✅ Generated Medium Markdown Report: ${mdFile.path}');

  // 2. Generate JSON Matrix
  final jsonReport = _generateJsonMatrix(
      allResults, tpsScenarios, mode, setsCount, scrollAnimation);
  final jsonFile = File('${outDir.path}/benchmark_matrix.json');
  jsonFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(jsonReport));
  print('  ✅ Generated JSON Matrix Dataset:    ${jsonFile.path}');

  // 3. Generate CSV
  final csvReport = _generateCsv(allResults);
  final csvFile = File('${outDir.path}/benchmark_summary.csv');
  csvFile.writeAsStringSync(csvReport);
  print('  ✅ Generated CSV Dataset:            ${csvFile.path}');

  print('\n🎉 All 100% pure hardware benchmarks completed successfully!\n');
}

/// Renders a 1Hz low-frequency progress status line without interfering with benchmarked process
void _renderProgress({
  required int targetTps,
  required int warmupSec,
  required int durationSec,
  required int elapsedSec,
}) {
  final buffer = StringBuffer();
  buffer.write('  ⏳ [${_formatNum(targetTps)} TPS] ');

  if (elapsedSec <= warmupSec) {
    final cur = elapsedSec;
    final total = warmupSec > 0 ? warmupSec : 1;
    final pct = ((cur / total) * 100).toInt().clamp(0, 100);
    final bar = _renderProgressBar(cur, total, 10);
    buffer.write('Warmup: [$bar] ${cur}s/${warmupSec}s ($pct%)');
  } else {
    final cur = elapsedSec - warmupSec;
    final total = durationSec > 0 ? durationSec : 1;
    final pct = ((cur / total) * 100).toInt().clamp(0, 100);
    final bar = _renderProgressBar(cur, total, 10);
    buffer.write(
        'Ingestion: [$bar] ${cur.clamp(0, durationSec)}s/${durationSec}s ($pct%)');
  }

  final msg = buffer.toString();
  final padding = msg.length < 80 ? ' ' * (80 - msg.length) : '';
  stdout.write('\r$msg$padding');
}

String _renderProgressBar(int current, int total, int length) {
  if (total <= 0) return '░' * length;
  final filled = ((current / total) * length).round().clamp(0, length);
  return '█' * filled + '░' * (length - filled);
}

String _getFlutterCommand() {
  if (Platform.isWindows) return 'flutter.bat';
  final flutterInSdk = File(
      '${File(Platform.resolvedExecutable).parent.parent.parent.parent.path}/bin/flutter');
  if (flutterInSdk.existsSync()) {
    return flutterInSdk.path;
  }
  final userFlutter =
      File('${Platform.environment['HOME']}/dev/flutter/bin/flutter');
  if (userFlutter.existsSync()) {
    return userFlutter.path;
  }
  return 'flutter';
}

/// Executes the real headless test runner in each framework project directory
Future<BenchmarkRunResult> _runHeadlessSubprocessBenchmark({
  required BenchmarkTarget target,
  required String targetDir,
  required int targetTps,
  required int durationSec,
  required int warmupSec,
  bool scrollAnimation = true,
  int setIndex = 1,
  int setsCount = 1,
  int targetIndex = 1,
  int totalTargets = 1,
  int runIndex = 1,
  int totalRuns = 1,
}) async {
  final flutterCmd = _getFlutterCommand();
  final process = await Process.start(
    flutterCmd,
    [
      'test',
      'test/benchmark_headless_test.dart',
      '--no-pub',
    ],
    workingDirectory: targetDir,
    environment: {
      ...Platform.environment,
      'BENCH_TPS': targetTps.toString(),
      'BENCH_DURATION': durationSec.toString(),
      'BENCH_WARMUP': warmupSec.toString(),
      'BENCH_SCROLL_ANIM': scrollAnimation.toString(),
      'BENCH_SET_INDEX': setIndex.toString(),
      'BENCH_TOTAL_SETS': setsCount.toString(),
      'BENCH_TARGET_INDEX': targetIndex.toString(),
      'BENCH_TOTAL_TARGETS': totalTargets.toString(),
      'BENCH_RUN_INDEX': runIndex.toString(),
      'BENCH_TOTAL_RUNS': totalRuns.toString(),
    },
    runInShell: Platform.isWindows,
  );

  final stdoutBuffer = StringBuffer();
  final stderrBuffer = StringBuffer();

  process.stdout
      .transform(utf8.decoder)
      .listen((data) => stdoutBuffer.write(data));
  process.stderr
      .transform(utf8.decoder)
      .listen((data) => stderrBuffer.write(data));

  int elapsedSec = 0;
  _renderProgress(
    targetTps: targetTps,
    warmupSec: warmupSec,
    durationSec: durationSec,
    elapsedSec: 0,
  );

  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    elapsedSec++;
    _renderProgress(
      targetTps: targetTps,
      warmupSec: warmupSec,
      durationSec: durationSec,
      elapsedSec: elapsedSec,
    );
  });

  final exitCode = await process.exitCode;
  timer.cancel();
  stdout.write('\r${' ' * 80}\r');

  final stdoutText = stdoutBuffer.toString();
  final marker = '__BENCHMARK_RAW_OUTPUT__:';
  final markerIdx = stdoutText.indexOf(marker);

  if (exitCode != 0 && markerIdx == -1) {
    stderr.writeln('\n[ERROR] Failed running benchmark for ${target.name}:');
    stderr.writeln(stderrBuffer.toString());
    stderr.writeln(stdoutText);
    throw Exception('Benchmark execution failed for ${target.name}');
  }

  if (markerIdx == -1) {
    throw Exception('Could not find benchmark output marker in: $stdoutText');
  }

  final jsonEndIdx = stdoutText.indexOf('\n', markerIdx);
  final jsonString = jsonEndIdx != -1
      ? stdoutText.substring(markerIdx + marker.length, jsonEndIdx).trim()
      : stdoutText.substring(markerIdx + marker.length).trim();
  final Map<String, dynamic> data = jsonDecode(jsonString);

  return BenchmarkRunResult(
    target: target,
    targetTps: targetTps,
    sustainedTps: (data['sustained_tps'] as num).toInt(),
    totalTicks: (data['total_ticks'] as num).toInt(),
    avgEventLoopLagMs: (data['avg_event_loop_lag_ms'] as num?)?.toDouble(),
    p95EventLoopLagMs: (data['p95_event_loop_lag_ms'] as num?)?.toDouble(),
    p99EventLoopLagMs: (data['p99_event_loop_lag_ms'] as num?)?.toDouble(),
    uiBuildTimeMs: 0.0,
    rasterTimeMs: 0.0,
    actualFps: 60.0,
    jankRatePct: 0.0,
    latencyMs: (data['latency_ms'] as num).toDouble(),
    memoryRssMb: (data['memory_rss_mb'] as num).toDouble(),
    durationSec: durationSec,
    scrollAnimation: (data['scroll_animation'] as bool?) ?? scrollAnimation,
    setIndex: setIndex,
  );
}

/// Executes Flutter Driver with real Windows GPU window
Future<BenchmarkRunResult> _runFlutterDriverBenchmark({
  required BenchmarkTarget target,
  required String targetDir,
  required int targetTps,
  required int durationSec,
  required int warmupSec,
  bool scrollAnimation = true,
  int setIndex = 1,
  int setsCount = 1,
  int targetIndex = 1,
  int totalTargets = 1,
  int runIndex = 1,
  int totalRuns = 1,
}) async {
  final flutterCmd = _getFlutterCommand();
  final process = await Process.start(
    flutterCmd,
    [
      'drive',
      '-d',
      Platform.isMacOS ? 'macos' : 'windows',
      '--profile',
      '--no-pub',
      '--target=test_driver/perf_app.dart',
      '--driver=test_driver/perf_driver.dart',
    ],
    workingDirectory: targetDir,
    environment: {
      ...Platform.environment,
      'BENCH_TPS': targetTps.toString(),
      'BENCH_DURATION': durationSec.toString(),
      'BENCH_WARMUP': warmupSec.toString(),
      'BENCH_SCROLL_ANIM': scrollAnimation.toString(),
      'BENCH_SET_INDEX': setIndex.toString(),
      'BENCH_TOTAL_SETS': setsCount.toString(),
      'BENCH_TARGET_INDEX': targetIndex.toString(),
      'BENCH_TOTAL_TARGETS': totalTargets.toString(),
      'BENCH_RUN_INDEX': runIndex.toString(),
      'BENCH_TOTAL_RUNS': totalRuns.toString(),
    },
    runInShell: Platform.isWindows,
  );

  final stdoutBuffer = StringBuffer();
  final stderrBuffer = StringBuffer();

  process.stdout
      .transform(utf8.decoder)
      .listen((data) => stdoutBuffer.write(data));
  process.stderr
      .transform(utf8.decoder)
      .listen((data) => stderrBuffer.write(data));

  int elapsedSec = 0;
  _renderProgress(
    targetTps: targetTps,
    warmupSec: warmupSec,
    durationSec: durationSec,
    elapsedSec: 0,
  );

  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    elapsedSec++;
    _renderProgress(
      targetTps: targetTps,
      warmupSec: warmupSec,
      durationSec: durationSec,
      elapsedSec: elapsedSec,
    );
  });

  final exitCode = await process.exitCode;
  timer.cancel();
  stdout.write('\r${' ' * 80}\r');

  final stdoutText = stdoutBuffer.toString();
  final marker = '__BENCHMARK_RAW_OUTPUT__:';
  final markerIdx = stdoutText.indexOf(marker);

  if (exitCode != 0 && markerIdx == -1) {
    stderr
        .writeln('\n[ERROR] Failed running Flutter Driver for ${target.name}:');
    stderr.writeln(stderrBuffer.toString());
    stderr.writeln(stdoutText);
    throw Exception('Flutter Driver execution failed for ${target.name}');
  }

  if (markerIdx == -1) {
    throw Exception('Could not find benchmark output marker in: $stdoutText');
  }

  final jsonEndIdx = stdoutText.indexOf('\n', markerIdx);
  final jsonString = jsonEndIdx != -1
      ? stdoutText.substring(markerIdx + marker.length, jsonEndIdx).trim()
      : stdoutText.substring(markerIdx + marker.length).trim();
  final Map<String, dynamic> data = jsonDecode(jsonString);

  final avgLag = (data['avg_event_loop_lag_ms'] as num?)?.toDouble();
  return BenchmarkRunResult(
    target: target,
    targetTps: targetTps,
    sustainedTps: (data['sustained_tps'] as num).toInt(),
    totalTicks: (data['total_ticks'] as num).toInt(),
    avgEventLoopLagMs: avgLag,
    p95EventLoopLagMs:
        (data['p95_event_loop_lag_ms'] as num?)?.toDouble() ?? avgLag,
    p99EventLoopLagMs:
        (data['p99_event_loop_lag_ms'] as num?)?.toDouble() ?? avgLag,
    medianEventLoopLagMs:
        (data['median_event_loop_lag_ms'] as num?)?.toDouble(),
    maxEventLoopLagMs: (data['max_event_loop_lag_ms'] as num?)?.toDouble(),
    lagSampleCount: (data['lag_sample_count'] as num?)?.toInt(),
    uiBuildTimeMs: (data['ui_build_time_ms'] as num).toDouble(),
    rasterTimeMs: (data['raster_time_ms'] as num).toDouble(),
    actualFps: (data['actual_fps'] as num).toDouble(),
    jankRatePct: (data['jank_rate_pct'] as num).toDouble(),
    latencyMs: (data['latency_ms'] as num? ?? 0.0).toDouble(),
    memoryRssMb: (data['memory_rss_mb'] as num).toDouble(),
    durationSec: durationSec,
    scrollAnimation: (data['scroll_animation'] as bool?) ?? scrollAnimation,
    setIndex: setIndex,
  );
}

/// Plain arithmetic mean (null for empty input).
double? _computeMean(List<double> values) =>
    values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;

/// Median (null for empty input).
double? _computeMedian(List<double> values) {
  if (values.isEmpty) return null;
  final s = List<double>.from(values)..sort();
  final mid = s.length ~/ 2;
  return s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) / 2;
}

String _fmtLag(double? v) => v == null ? 'N/A' : '${v.toStringAsFixed(3)} ms';

/// Computes robust trimmed mean by removing the minimum and maximum outlier if >= 4 samples
double? _computeTrimmedMean(List<double> values) {
  if (values.isEmpty) return null;
  if (values.length <= 3) {
    return values.reduce((a, b) => a + b) / values.length;
  }
  final sorted = List<double>.from(values)..sort();
  // Drop 1 minimum and 1 maximum outlier (Olympic scoring / Trimmed mean)
  final trimmed = sorted.sublist(1, sorted.length - 1);
  return trimmed.reduce((a, b) => a + b) / trimmed.length;
}

/// Generates Medium & GitHub ready Markdown report
String _generateMediumMarkdownReport(
  List<BenchmarkRunResult> results,
  List<int> tpsScenarios,
  int durationSec,
  String mode,
  int setsCount,
  bool scrollAnimation, {
  String methodologyRelPath = '../BENCHMARK_METHODOLOGY.md',
}) {
  final buffer = StringBuffer();
  buffer.writeln(
      '# NASDAQ Order Book Mini — Multi-Framework Performance Whitepaper');
  buffer.writeln();
  buffer.writeln(
      '> High-throughput reactive benchmark comparing state management & reactive graph architectures in Flutter/Dart under extreme stream ingest loads (10K to 100K+ TPS).');
  buffer.writeln();
  buffer.writeln(
      '## Benchmark Execution Environment (100% Real Hardware Ingestion)');
  buffer.writeln(
      '- **Operating System**: `${Platform.operatingSystem} ${Platform.operatingSystemVersion}`');
  buffer.writeln('- **Dart SDK**: `${Platform.version.split(' ').first}`');
  buffer.writeln(
      '- **Scenario Duration**: `${durationSec}s` per test scenario ($setsCount randomized set(s))');
  buffer.writeln(
      '- **Order Book Scroll Animation**: `${scrollAnimation ? "Enabled (Continuous VSync Oscillation)" : "Disabled (Static Center Viewport)"}`');
  buffer.writeln(
      '- **Execution Engine**: ${mode == 'drive' ? 'Flutter Driver Real Window, `--profile` build (GPU & VSync Timelines)' : 'Dedicated Background Isolate Ingestion & OS RSS Memory Sampling'}');
  buffer.writeln(
      '- **Event Loop Lag sampling**: every 33ms over the full ${durationSec}s window of each set (about ${(durationSec / 0.033).round()} samples per set), stored in a pre-allocated fixed buffer.');
  buffer.writeln(
      '- **Scope**: see *Limitations* at the end of this report before drawing conclusions.');
  buffer.writeln();

  for (final tps in tpsScenarios) {
    buffer.writeln('---');
    buffer.writeln(
        '### Scenario: Target ${_formatNum(tps)} TPS — $setsCount set(s)${setsCount > 1 ? ', shuffled order' : ''}');
    buffer.writeln();
    buffer.writeln(
        'Per-set lag statistics are aggregated across sets. **Mean, Median and Trimmed Mean are all shown** (Trimmed Mean drops the single lowest and highest set when sets >= 4); no value is hidden. Rows are sorted by Median (lower is better).');
    buffer.writeln();

    if (mode == 'drive') {
      buffer.writeln(
          '| Framework | Lag Mean | Lag Median | Lag Trimmed Mean | P99 Lag (median of sets) | Max Lag (worst sample) | UI Build | GPU Raster | RSS |');
      buffer.writeln(
          '| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |');
    } else {
      buffer.writeln(
          '| Framework | Lag Mean | Lag Median | Lag Trimmed Mean | P99 Lag (median of sets) | Max Lag (worst sample) | RSS |');
      buffer.writeln('| :--- | :--- | :--- | :--- | :--- | :--- | :--- |');
    }

    final targetMap = <String, List<BenchmarkRunResult>>{};
    for (final r in results.where((r) => r.targetTps == tps)) {
      targetMap.putIfAbsent(r.target.id, () => []).add(r);
    }

    final aggregatedList = <Map<String, dynamic>>[];
    targetMap.forEach((targetId, runList) {
      final setMeans =
          runList.map((r) => r.avgEventLoopLagMs).whereType<double>().toList();
      final setP99s =
          runList.map((r) => r.p99EventLoopLagMs).whereType<double>().toList();
      final setMaxes = runList
          .map((r) => r.maxEventLoopLagMs ?? r.p99EventLoopLagMs)
          .whereType<double>()
          .toList();
      final setMedians = runList
          .map((r) => r.medianEventLoopLagMs ?? r.avgEventLoopLagMs)
          .whereType<double>()
          .toList();

      aggregatedList.add({
        'target': runList.first.target,
        'mean': _computeMean(setMeans),
        'median': _computeMedian(setMedians),
        'trimmed': _computeTrimmedMean(setMeans),
        'p99': _computeMedian(setP99s),
        'max':
            setMaxes.isEmpty ? null : setMaxes.reduce((a, b) => a > b ? a : b),
        'build': runList.map((r) => r.uiBuildTimeMs).reduce((a, b) => a + b) /
            runList.length,
        'raster': runList.map((r) => r.rasterTimeMs).reduce((a, b) => a + b) /
            runList.length,
        'rss': runList.map((r) => r.memoryRssMb).reduce((a, b) => a + b) /
            runList.length,
      });
    });

    aggregatedList.sort((a, b) {
      final x = a['median'] as double?;
      final y = b['median'] as double?;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    });

    for (final agg in aggregatedList) {
      final target = agg['target'] as BenchmarkTarget;
      final lagCells =
          '${_fmtLag(agg['mean'] as double?)} | ${_fmtLag(agg['median'] as double?)} | ${_fmtLag(agg['trimmed'] as double?)} | ${_fmtLag(agg['p99'] as double?)} | ${_fmtLag(agg['max'] as double?)}';
      final memStr = '${(agg['rss'] as double).toStringAsFixed(1)} MB';
      if (mode == 'drive') {
        buffer.writeln(
            '| ${target.name} | $lagCells | ${(agg['build'] as double).toStringAsFixed(2)} ms | ${(agg['raster'] as double).toStringAsFixed(2)} ms | $memStr |');
      } else {
        buffer.writeln('| ${target.name} | $lagCells | $memStr |');
      }
    }
    buffer.writeln();

    if (setsCount > 1) {
      buffer.writeln('#### Individual Set Breakdown (raw, unfiltered)');
      buffer.writeln();
      buffer.writeln(
          '| Set # | Framework | Lag Mean | Lag Median | Lag P99 | Lag Max | Samples | UI Build | GPU Raster | RSS |');
      buffer.writeln(
          '| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |');
      for (final res in results.where((r) => r.targetTps == tps)) {
        buffer.writeln(
            '| Set ${res.setIndex} | ${res.target.name} | ${_fmtLag(res.avgEventLoopLagMs)} | ${_fmtLag(res.medianEventLoopLagMs)} | ${_fmtLag(res.p99EventLoopLagMs)} | ${_fmtLag(res.maxEventLoopLagMs)} | ${res.lagSampleCount ?? 'n/a'} | ${res.uiBuildTimeMs.toStringAsFixed(2)} ms | ${res.rasterTimeMs.toStringAsFixed(2)} ms | ${res.memoryRssMb.toStringAsFixed(1)} MB |');
      }
      buffer.writeln();
    }
  }

  buffer.writeln('---');
  buffer.writeln('## Limitations');
  buffer.writeln();
  buffer.writeln(
      '- **Throughput is intentionally not reported.** The tick generator simulates at most 200 steps per 1 ms batch and adds the remainder to the tick counter arithmetically, so Sustained TPS / Achievement Rate track the target for every framework and cannot discriminate between them. Raw values remain in `benchmark_matrix.json` and `benchmark_summary.csv`.');
  buffer.writeln(
      '- **Rendering metrics have low resolution.** The UI only repaints a handful of frames per run, so UI Build / GPU Raster are nearly identical across frameworks and should not be used to rank them.');
  buffer.writeln(
      '- **Event loop lag is a main-isolate responsiveness metric**, not a throughput or correctness metric. Differences of a few hundredths of a millisecond are within run-to-run noise; compare Median and Max together with the raw per-set table.');
  buffer.writeln(
      '- **Authorship Disclosure.** Signals and Riverpod are community open-source libraries. Flutter represents pure vanilla Flutter primitives (ValueNotifier & ListenableBuilder) without external dependencies. Blooming and Coralline are experimental frameworks designed by the benchmark author. See [`BENCHMARK_METHODOLOGY.md`]($methodologyRelPath) for detailed architecture profiles.');
  buffer.writeln(
      '- **Single machine, single OS, profile build.** Results are not portable to other hardware, OS versions or release/AOT builds without re-running.');
  buffer.writeln(
      '- **No causal claims.** This report measures; it does not explain why a framework is faster or slower.');
  buffer.writeln();
  buffer.writeln('---');
  buffer.writeln('## 📊 Metric Definitions & Statistical Methodology');
  buffer.writeln();
  buffer.writeln(
      '- **Event Loop Lag**: Measured by injecting `Timer.run()` every 33ms into Dart’s event queue. Measures delay until CPU execution (\\Delta t = T_{executed} - T_{scheduled}).');
  buffer.writeln(
      '- **Mean / Median / Trimmed Mean**: all three are reported side by side. Trimmed Mean drops the single lowest and highest set when sets >= 4; Median is the robust reference. The statistics are fixed in advance and never applied selectively.');
  buffer.writeln(
      '- **Raw Data Transparency**: All individual set records, P95/P99 latencies, and engine timings are fully preserved in `benchmark_matrix.json` and `benchmark_summary.csv`.');
  buffer.writeln(
      '- **Full Whitepaper**: See [`BENCHMARK_METHODOLOGY.md`]($methodologyRelPath) for full mathematical definitions and source code snippets.');
  buffer.writeln();
  buffer.writeln('---');
  buffer.writeln(
      '*Report generated automatically via pure hardware headless measurement.*');

  return buffer.toString();
}

/// Generates JSON matrix dataset
Map<String, dynamic> _generateJsonMatrix(
  List<BenchmarkRunResult> results,
  List<int> tpsScenarios,
  String mode,
  int setsCount,
  bool scrollAnimation,
) {
  return {
    'suite': 'NASDAQ Order Book Mini Benchmark (100% Pure Hardware Execution)',
    'mode': mode,
    'sets_count': setsCount,
    'scroll_animation': scrollAnimation,
    'timestamp': DateTime.now().toIso8601String(),
    'environment': {
      'os': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'dart_version': Platform.version,
    },
    'scenarios_tps': tpsScenarios,
    'results': results.map((r) => r.toJson()).toList(),
  };
}

/// Generates CSV data
String _generateCsv(List<BenchmarkRunResult> results) {
  final buffer = StringBuffer();
  buffer.writeln(
      'Framework,Architecture,Target_TPS,Sustained_TPS,Achievement_Rate_Pct,Total_Ticks,Avg_Event_Loop_Lag_Ms,P95_Lag_Ms,P99_Lag_Ms,UI_Build_Time_Ms,Raster_Time_Ms,Actual_FPS,Jank_Rate_Pct,Memory_RSS_MB,Latency_Ms,Scroll_Animation');
  for (final r in results) {
    final lagStr = r.avgEventLoopLagMs != null
        ? r.avgEventLoopLagMs!.toStringAsFixed(2)
        : 'N/A';
    final p95Str = r.p95EventLoopLagMs != null
        ? r.p95EventLoopLagMs!.toStringAsFixed(2)
        : 'N/A';
    final p99Str = r.p99EventLoopLagMs != null
        ? r.p99EventLoopLagMs!.toStringAsFixed(2)
        : 'N/A';
    buffer.writeln(
        '"${r.target.name}","${r.target.architecture}",${r.targetTps},${r.sustainedTps},${r.achievementRate.toStringAsFixed(2)},${r.totalTicks},$lagStr,$p95Str,$p99Str,${r.uiBuildTimeMs.toStringAsFixed(2)},${r.rasterTimeMs.toStringAsFixed(2)},${r.actualFps.toStringAsFixed(1)},${r.jankRatePct.toStringAsFixed(2)},${r.memoryRssMb.toStringAsFixed(1)},${r.latencyMs.toStringAsFixed(2)},${r.scrollAnimation}');
  }
  return buffer.toString();
}

String _formatNum(int num) {
  return num.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

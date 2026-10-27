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
    directoryName: 'nasdaq_mini_blooming',
  ),
  BenchmarkTarget(
    id: 'coralline',
    name: 'Coralline',
    architecture: 'Coralline High-Performance Reactive Graph',
    directoryName: 'nasdaq_mini_coralline',
  ),
  BenchmarkTarget(
    id: 'signals',
    name: 'Signals',
    architecture: 'Signals Reactive Fine-Grained Architecture',
    directoryName: 'nasdaq_mini_signals',
  ),
  BenchmarkTarget(
    id: 'riverpod',
    name: 'Riverpod',
    architecture: 'Flutter Riverpod State Management',
    directoryName: 'nasdaq_mini_riverpod',
  ),
  BenchmarkTarget(
    id: 'flutter',
    name: 'Flutter',
    architecture: 'Pure Flutter (ValueNotifier & ListenableBuilder)',
    directoryName: 'nasdaq_mini_flutter',
  ),
];

/// Preset interval options in milliseconds matching all benchmark packages
const List<double> rotationIntervalPresetsMs = [
  8.33,
  16.67,
  50,
  100,
  250,
  500,
  1000,
  2000,
  3000,
  5000,
  10000,
];

String _formatInterval(double ms) {
  if (ms >= 1000) {
    final s = ms / 1000;
    return '${s % 1 == 0 ? s.toInt() : s.toStringAsFixed(1)}s';
  }
  return '${ms % 1 == 0 ? ms.toInt() : ms.toStringAsFixed(2)}ms';
}

int _resolveIntervalIndex(String input, List<double> presets) {
  var clean = input.trim().toLowerCase();
  double ms = 0;
  if (clean.endsWith('ms')) {
    ms = double.tryParse(clean.substring(0, clean.length - 2)) ?? presets.first;
  } else if (clean.endsWith('s')) {
    final s = double.tryParse(clean.substring(0, clean.length - 1));
    ms = s != null ? s * 1000 : presets.first;
  } else {
    // Unitless numeric inputs are strictly interpreted as milliseconds (ms).
    // Note: direct preset index specification is exclusively handled via --*-interval-index
    final d = double.tryParse(clean);
    ms = d ?? presets.first;
  }

  int bestIdx = 0;
  double minDiff = (presets[0] - ms).abs();
  for (int i = 1; i < presets.length; i++) {
    final diff = (presets[i] - ms).abs();
    if (diff < minDiff) {
      minDiff = diff;
      bestIdx = i;
    }
  }
  return bestIdx;
}

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
    this.uiBuildTimeMs,
    this.rasterTimeMs,
    this.actualFps,
    this.jankRatePct,
    this.displayRefreshRate,
    this.frameBudgetMs,
    required this.durationSec,
    this.scrollAnimation = true,
    this.themeRotation = true,
    this.tickerRotation = true,
    this.themeIntervalIndex = 0,
    this.tickerIntervalIndex = 0,
    this.setIndex = 1,
    this.medianEventLoopLagMs,
    this.maxEventLoopLagMs,
    this.lagSampleCount,
    this.retryCount = 0,
    this.failureReason,
    this.frameworkUpdateRateHz,
    this.totalBatches,
  });

  final BenchmarkTarget target;
  final int targetTps;
  final int sustainedTps;
  final int totalTicks;
  final int? frameworkUpdateRateHz;
  final int? totalBatches;
  final double? avgEventLoopLagMs;
  final double? p95EventLoopLagMs;
  final double? p99EventLoopLagMs;
  final double latencyMs;
  final double memoryRssMb;
  final double? uiBuildTimeMs;
  final double? rasterTimeMs;
  final double? actualFps;
  final double? jankRatePct;
  final double? displayRefreshRate;
  final double? frameBudgetMs;
  final int durationSec;
  final bool scrollAnimation;
  final bool themeRotation;
  final bool tickerRotation;
  final int themeIntervalIndex;
  final int tickerIntervalIndex;
  final int setIndex;
  final double? medianEventLoopLagMs;
  final double? maxEventLoopLagMs;
  final int? lagSampleCount;
  final int retryCount;
  final String? failureReason;

  BenchmarkRunResult copyWith({
    BenchmarkTarget? target,
    int? targetTps,
    int? sustainedTps,
    int? totalTicks,
    int? frameworkUpdateRateHz,
    int? totalBatches,
    double? avgEventLoopLagMs,
    double? p95EventLoopLagMs,
    double? p99EventLoopLagMs,
    double? latencyMs,
    double? memoryRssMb,
    double? uiBuildTimeMs,
    double? rasterTimeMs,
    double? actualFps,
    double? jankRatePct,
    double? displayRefreshRate,
    double? frameBudgetMs,
    int? durationSec,
    bool? scrollAnimation,
    bool? themeRotation,
    bool? tickerRotation,
    int? themeIntervalIndex,
    int? tickerIntervalIndex,
    int? setIndex,
    double? medianEventLoopLagMs,
    double? maxEventLoopLagMs,
    int? lagSampleCount,
    int? retryCount,
    String? failureReason,
  }) =>
      BenchmarkRunResult(
        target: target ?? this.target,
        targetTps: targetTps ?? this.targetTps,
        sustainedTps: sustainedTps ?? this.sustainedTps,
        totalTicks: totalTicks ?? this.totalTicks,
        frameworkUpdateRateHz:
            frameworkUpdateRateHz ?? this.frameworkUpdateRateHz,
        totalBatches: totalBatches ?? this.totalBatches,
        avgEventLoopLagMs: avgEventLoopLagMs ?? this.avgEventLoopLagMs,
        p95EventLoopLagMs: p95EventLoopLagMs ?? this.p95EventLoopLagMs,
        p99EventLoopLagMs: p99EventLoopLagMs ?? this.p99EventLoopLagMs,
        latencyMs: latencyMs ?? this.latencyMs,
        memoryRssMb: memoryRssMb ?? this.memoryRssMb,
        uiBuildTimeMs: uiBuildTimeMs ?? this.uiBuildTimeMs,
        rasterTimeMs: rasterTimeMs ?? this.rasterTimeMs,
        actualFps: actualFps ?? this.actualFps,
        jankRatePct: jankRatePct ?? this.jankRatePct,
        displayRefreshRate: displayRefreshRate ?? this.displayRefreshRate,
        frameBudgetMs: frameBudgetMs ?? this.frameBudgetMs,
        durationSec: durationSec ?? this.durationSec,
        scrollAnimation: scrollAnimation ?? this.scrollAnimation,
        themeRotation: themeRotation ?? this.themeRotation,
        tickerRotation: tickerRotation ?? this.tickerRotation,
        themeIntervalIndex: themeIntervalIndex ?? this.themeIntervalIndex,
        tickerIntervalIndex: tickerIntervalIndex ?? this.tickerIntervalIndex,
        setIndex: setIndex ?? this.setIndex,
        medianEventLoopLagMs: medianEventLoopLagMs ?? this.medianEventLoopLagMs,
        maxEventLoopLagMs: maxEventLoopLagMs ?? this.maxEventLoopLagMs,
        lagSampleCount: lagSampleCount ?? this.lagSampleCount,
        retryCount: retryCount ?? this.retryCount,
        failureReason: failureReason ?? this.failureReason,
      );

  double get achievementRate => targetTps > 0
      ? ((sustainedTps / targetTps) * 100).clamp(0.0, 100.0)
      : 0.0;

  Map<String, dynamic> toJson() => {
        'target_id': target.id,
        'framework': target.name,
        'architecture': target.architecture,
        'set_index': setIndex,
        'retry_count': retryCount,
        'failure_reason': failureReason,
        'scroll_animation': scrollAnimation,
        'theme_rotation': themeRotation,
        'theme_interval_ms': rotationIntervalPresetsMs[themeIntervalIndex],
        'ticker_rotation': tickerRotation,
        'ticker_interval_ms': rotationIntervalPresetsMs[tickerIntervalIndex],
        'target_tps': targetTps,
        'sustained_tps': sustainedTps,
        'generator_tps': sustainedTps,
        'framework_update_rate_hz': frameworkUpdateRateHz,
        'achievement_rate_pct':
            double.parse(achievementRate.toStringAsFixed(2)),
        'total_ticks': totalTicks,
        'total_batches': totalBatches,
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
        'ui_build_time_ms': uiBuildTimeMs != null
            ? double.parse(uiBuildTimeMs!.toStringAsFixed(2))
            : null,
        'raster_time_ms': rasterTimeMs != null
            ? double.parse(rasterTimeMs!.toStringAsFixed(2))
            : null,
        'actual_fps': actualFps != null
            ? double.parse(actualFps!.toStringAsFixed(1))
            : null,
        'jank_rate_pct': jankRatePct != null
            ? double.parse(jankRatePct!.toStringAsFixed(2))
            : null,
        'display_refresh_rate': displayRefreshRate != null
            ? double.parse(displayRefreshRate!.toStringAsFixed(1))
            : null,
        'frame_budget_ms': frameBudgetMs != null
            ? double.parse(frameBudgetMs!.toStringAsFixed(2))
            : null,
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
  bool themeRotation = true;
  int themeIntervalIndex = 0; // 8.33ms (120Hz minimum)
  bool tickerRotation = true;
  int tickerIntervalIndex = 0; // 8.33ms (120Hz minimum)
  String outputDir = 'results';
  String mode =
      'drive'; // Default to Real Windows GPU Flutter Driver E2E Benchmarking
  List<BenchmarkTarget> effectiveTargets = List.from(benchmarkTargets);
  final List<String> requestedTargetFilters = [];

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
      final rawMode = arg.substring('--mode='.length).toLowerCase().trim();
      if (rawMode == 'drive' || rawMode == 'flutter-driver') {
        mode = 'drive';
      } else if (rawMode == 'subprocess' || rawMode == 'headless') {
        mode = 'subprocess';
      } else {
        stderr.writeln(
            '❌ Invalid --mode="$rawMode". Supported modes are: "drive" (Flutter Driver real desktop window) or "subprocess" (headless isolate).');
        exit(1);
      }
    } else if (arg.startsWith('--sets=')) {
      setsCount = int.parse(arg.substring('--sets='.length));
    } else if (arg.startsWith('--target=') || arg.startsWith('--framework=')) {
      final filterVal = (arg.startsWith('--target=')
              ? arg.substring('--target='.length)
              : arg.substring('--framework='.length))
          .trim();
      if (filterVal.isEmpty) {
        stderr.writeln(
            '❌ Missing value for target filter. Supported targets: ${benchmarkTargets.map((t) => t.id).join(', ')}');
        exit(1);
      }
      for (final part in filterVal.split(',')) {
        final trimmed = part.trim().toLowerCase();
        if (trimmed.isNotEmpty) {
          requestedTargetFilters.add(trimmed);
        }
      }
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
    } else if (arg == '--theme-rotation' || arg == '--theme-rot') {
      themeRotation = true;
    } else if (arg == '--no-theme-rotation' || arg == '--no-theme-rot') {
      themeRotation = false;
    } else if (arg.startsWith('--theme-rotation=') ||
        arg.startsWith('--theme-rot=')) {
      final val = arg.split('=').last.toLowerCase();
      themeRotation = val == 'true';
    } else if (arg.startsWith('--theme-interval=') ||
        arg.startsWith('--theme-interval-ms=')) {
      final val = arg.split('=').last;
      themeIntervalIndex =
          _resolveIntervalIndex(val, rotationIntervalPresetsMs);
    } else if (arg.startsWith('--theme-interval-index=')) {
      themeIntervalIndex = int.parse(arg.split('=').last)
          .clamp(0, rotationIntervalPresetsMs.length - 1);
    } else if (arg == '--ticker-rotation' ||
        arg == '--ticker-rot' ||
        arg == '--watchlist-rotation' ||
        arg == '--stock-rotation') {
      tickerRotation = true;
    } else if (arg == '--no-ticker-rotation' ||
        arg == '--no-ticker-rot' ||
        arg == '--no-watchlist-rotation' ||
        arg == '--no-stock-rotation') {
      tickerRotation = false;
    } else if (arg.startsWith('--ticker-rotation=') ||
        arg.startsWith('--ticker-rot=') ||
        arg.startsWith('--watchlist-rotation=') ||
        arg.startsWith('--stock-rotation=')) {
      final val = arg.split('=').last.toLowerCase();
      tickerRotation = val == 'true';
    } else if (arg.startsWith('--ticker-interval=') ||
        arg.startsWith('--ticker-interval-ms=') ||
        arg.startsWith('--watchlist-interval=') ||
        arg.startsWith('--stock-interval=')) {
      final val = arg.split('=').last;
      tickerIntervalIndex =
          _resolveIntervalIndex(val, rotationIntervalPresetsMs);
    } else if (arg.startsWith('--ticker-interval-index=') ||
        arg.startsWith('--watchlist-interval-index=') ||
        arg.startsWith('--stock-interval-index=')) {
      tickerIntervalIndex = int.parse(arg.split('=').last)
          .clamp(0, rotationIntervalPresetsMs.length - 1);
    }
  }

  if (requestedTargetFilters.isNotEmpty) {
    final validTargetNames =
        benchmarkTargets.map((t) => t.id.toLowerCase()).toList();
    final unknownTargets = <String>[];
    final selectedTargets = <BenchmarkTarget>[];

    for (final filter in requestedTargetFilters) {
      final match = benchmarkTargets.where((t) =>
          t.id.toLowerCase() == filter || t.name.toLowerCase() == filter);
      if (match.isEmpty) {
        unknownTargets.add(filter);
      } else {
        for (final target in match) {
          if (!selectedTargets.contains(target)) {
            selectedTargets.add(target);
          }
        }
      }
    }

    if (unknownTargets.isNotEmpty) {
      stderr.writeln(
          '❌ Unknown target framework(s): "${unknownTargets.join(', ')}". Supported targets: ${validTargetNames.join(', ')}');
      exit(1);
    }

    effectiveTargets = selectedTargets;
  }

  if (effectiveTargets.isEmpty) {
    stderr.writeln(
        '❌ No valid benchmark targets specified. Supported targets: ${benchmarkTargets.map((t) => t.id).join(', ')}');
    exit(1);
  }

  print('Configuration:');
  print('  • Scenarios (TPS): $tpsScenarios');
  print('  • Duration: ${durationSec}s per scenario (Warmup: ${warmupSec}s)');
  print(
      '  • Total Sets: $setsCount set(s) (Order Shuffling: ${shuffleOrder ? "RANDOMIZED" : "SEQUENTIAL"})');
  print(
      '  • Scroll Animation: ${scrollAnimation ? "ENABLED (Oscillating VSync)" : "DISABLED (Static Center)"}');
  print(
      '  • Theme Rotation: ${themeRotation ? "ENABLED (${_formatInterval(rotationIntervalPresetsMs[themeIntervalIndex])})" : "DISABLED"}');
  print(
      '  • Watchlist Ticker Rotation: ${tickerRotation ? "ENABLED (${_formatInterval(rotationIntervalPresetsMs[tickerIntervalIndex])})" : "DISABLED"}');
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
                themeRotation: themeRotation,
                themeIntervalIndex: themeIntervalIndex,
                tickerRotation: tickerRotation,
                tickerIntervalIndex: tickerIntervalIndex,
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
                themeRotation: themeRotation,
                themeIntervalIndex: themeIntervalIndex,
                tickerRotation: tickerRotation,
                tickerIntervalIndex: tickerIntervalIndex,
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
          '  → ${_formatNum(targetTps)} TPS (${durationSec}s) DONE! Sustained: ${_formatNum(result.sustainedTps)} TPS (${result.achievementRate.toStringAsFixed(1)}%) | Lag: $lagPrint | RSS: ${result.memoryRssMb.toStringAsFixed(1)}MB | UI Build: ${result.uiBuildTimeMs != null && result.uiBuildTimeMs! > 0 ? '${result.uiBuildTimeMs}ms' : 'N/A'}',
        );
      }
      print('');
      await Future.delayed(const Duration(milliseconds: 1000));
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
      shuffleOrder: shuffleOrder,
      themeRotation: themeRotation,
      themeIntervalIndex: themeIntervalIndex,
      tickerRotation: tickerRotation,
      tickerIntervalIndex: tickerIntervalIndex,
      methodologyRelPath: '../../BENCHMARK_METHODOLOGY.md');
  final mdFile = File('${outDir.path}/SUMMARY_REPORT.md');
  mdFile.writeAsStringSync(mdReportSub);
  print('  ✅ Generated Medium Markdown Report: ${mdFile.path}');

  // 2. Generate JSON Matrix
  final jsonReport = _generateJsonMatrix(
      allResults, tpsScenarios, mode, setsCount, scrollAnimation,
      shuffleOrder: shuffleOrder,
      themeRotation: themeRotation,
      themeIntervalIndex: themeIntervalIndex,
      tickerRotation: tickerRotation,
      tickerIntervalIndex: tickerIntervalIndex);
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
  bool themeRotation = true,
  int themeIntervalIndex = 0,
  bool tickerRotation = true,
  int tickerIntervalIndex = 0,
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
      'BENCH_THEME_ROTATION': themeRotation.toString(),
      'BENCH_THEME_INTERVAL_INDEX': themeIntervalIndex.toString(),
      'BENCH_TICKER_ROTATION': tickerRotation.toString(),
      'BENCH_TICKER_INTERVAL_INDEX': tickerIntervalIndex.toString(),
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

  final stdoutDone = process.stdout
      .transform(utf8.decoder)
      .forEach((data) => stdoutBuffer.write(data));
  final stderrDone = process.stderr
      .transform(utf8.decoder)
      .forEach((data) => stderrBuffer.write(data));

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
  await Future.wait([stdoutDone, stderrDone])
      .timeout(const Duration(seconds: 3), onTimeout: () => []);

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

  final avgLag = (data['avg_event_loop_lag_ms'] as num?)?.toDouble();
  return BenchmarkRunResult(
    target: target,
    targetTps: targetTps,
    sustainedTps: (data['sustained_tps'] as num).toInt(),
    totalTicks: (data['total_ticks'] as num).toInt(),
    frameworkUpdateRateHz: (data['framework_update_rate_hz'] as num?)?.toInt(),
    totalBatches: (data['total_batches'] as num?)?.toInt(),
    avgEventLoopLagMs: avgLag,
    p95EventLoopLagMs: (data['p95_event_loop_lag_ms'] as num?)?.toDouble(),
    p99EventLoopLagMs: (data['p99_event_loop_lag_ms'] as num?)?.toDouble(),
    medianEventLoopLagMs:
        (data['median_event_loop_lag_ms'] as num?)?.toDouble(),
    maxEventLoopLagMs: (data['max_event_loop_lag_ms'] as num?)?.toDouble(),
    lagSampleCount: (data['lag_sample_count'] as num?)?.toInt(),
    uiBuildTimeMs: null,
    rasterTimeMs: null,
    actualFps: null,
    jankRatePct: null,
    latencyMs: (data['latency_ms'] as num).toDouble(),
    memoryRssMb: (data['memory_rss_mb'] as num).toDouble(),
    durationSec: durationSec,
    scrollAnimation: (data['scroll_animation'] as bool?) ?? false,
    themeRotation: (data['theme_rotation'] as bool?) ?? themeRotation,
    themeIntervalIndex:
        (data['theme_interval_index'] as num?)?.toInt() ?? themeIntervalIndex,
    tickerRotation: (data['ticker_rotation'] as bool?) ?? tickerRotation,
    tickerIntervalIndex:
        (data['ticker_interval_index'] as num?)?.toInt() ?? tickerIntervalIndex,
    setIndex: setIndex,
  );
}

/// Executes Flutter Driver with real desktop GPU window with automatic single retry on transient OS/driver failure
Future<BenchmarkRunResult> _runFlutterDriverBenchmark({
  required BenchmarkTarget target,
  required String targetDir,
  required int targetTps,
  required int durationSec,
  required int warmupSec,
  bool scrollAnimation = true,
  bool themeRotation = true,
  int themeIntervalIndex = 0,
  bool tickerRotation = true,
  int tickerIntervalIndex = 0,
  int setIndex = 1,
  int setsCount = 1,
  int targetIndex = 1,
  int totalTargets = 1,
  int runIndex = 1,
  int totalRuns = 1,
}) async {
  try {
    return await _runFlutterDriverBenchmarkAttempt(
      target: target,
      targetDir: targetDir,
      targetTps: targetTps,
      durationSec: durationSec,
      warmupSec: warmupSec,
      scrollAnimation: scrollAnimation,
      themeRotation: themeRotation,
      themeIntervalIndex: themeIntervalIndex,
      tickerRotation: tickerRotation,
      tickerIntervalIndex: tickerIntervalIndex,
      setIndex: setIndex,
      setsCount: setsCount,
      targetIndex: targetIndex,
      totalTargets: totalTargets,
      runIndex: runIndex,
      totalRuns: totalRuns,
    );
  } catch (e) {
    stdout.writeln('\n⚠️ Transient Flutter Driver error on ${target.name}: $e');
    stdout.writeln(
        '🔄 Retrying benchmark run for ${target.name} once after 3s cooldown...');
    await Future.delayed(const Duration(seconds: 3));
    final retriedResult = await _runFlutterDriverBenchmarkAttempt(
      target: target,
      targetDir: targetDir,
      targetTps: targetTps,
      durationSec: durationSec,
      warmupSec: warmupSec,
      scrollAnimation: scrollAnimation,
      themeRotation: themeRotation,
      themeIntervalIndex: themeIntervalIndex,
      tickerRotation: tickerRotation,
      tickerIntervalIndex: tickerIntervalIndex,
      setIndex: setIndex,
      setsCount: setsCount,
      targetIndex: targetIndex,
      totalTargets: totalTargets,
      runIndex: runIndex,
      totalRuns: totalRuns,
    );
    return retriedResult.copyWith(
      retryCount: 1,
      failureReason: e.toString(),
    );
  }
}

Future<BenchmarkRunResult> _runFlutterDriverBenchmarkAttempt({
  required BenchmarkTarget target,
  required String targetDir,
  required int targetTps,
  required int durationSec,
  required int warmupSec,
  bool scrollAnimation = true,
  bool themeRotation = true,
  int themeIntervalIndex = 0,
  bool tickerRotation = true,
  int tickerIntervalIndex = 0,
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
      'BENCH_THEME_ROTATION': themeRotation.toString(),
      'BENCH_THEME_INTERVAL_INDEX': themeIntervalIndex.toString(),
      'BENCH_TICKER_ROTATION': tickerRotation.toString(),
      'BENCH_TICKER_INTERVAL_INDEX': tickerIntervalIndex.toString(),
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

  final stdoutDone = process.stdout
      .transform(utf8.decoder)
      .forEach((data) => stdoutBuffer.write(data));
  final stderrDone = process.stderr
      .transform(utf8.decoder)
      .forEach((data) => stderrBuffer.write(data));

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
  await Future.wait([stdoutDone, stderrDone])
      .timeout(const Duration(seconds: 3), onTimeout: () => []);

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
    frameworkUpdateRateHz: (data['framework_update_rate_hz'] as num?)?.toInt(),
    totalBatches: (data['total_batches'] as num?)?.toInt(),
    avgEventLoopLagMs: avgLag,
    p95EventLoopLagMs: (data['p95_event_loop_lag_ms'] as num?)?.toDouble(),
    p99EventLoopLagMs: (data['p99_event_loop_lag_ms'] as num?)?.toDouble(),
    medianEventLoopLagMs:
        (data['median_event_loop_lag_ms'] as num?)?.toDouble(),
    maxEventLoopLagMs: (data['max_event_loop_lag_ms'] as num?)?.toDouble(),
    lagSampleCount: (data['lag_sample_count'] as num?)?.toInt(),
    uiBuildTimeMs: (data['ui_build_time_ms'] as num?)?.toDouble(),
    rasterTimeMs: (data['raster_time_ms'] as num?)?.toDouble(),
    actualFps: (data['actual_fps'] as num?)?.toDouble(),
    jankRatePct: (data['jank_rate_pct'] as num?)?.toDouble(),
    displayRefreshRate: (data['display_refresh_rate'] as num?)?.toDouble(),
    frameBudgetMs: (data['frame_budget_ms'] as num?)?.toDouble(),
    latencyMs: (data['latency_ms'] as num? ?? 0.0).toDouble(),
    memoryRssMb: (data['memory_rss_mb'] as num).toDouble(),
    durationSec: durationSec,
    scrollAnimation: (data['scroll_animation'] as bool?) ?? scrollAnimation,
    themeRotation: (data['theme_rotation'] as bool?) ?? themeRotation,
    themeIntervalIndex:
        (data['theme_interval_index'] as num?)?.toInt() ?? themeIntervalIndex,
    tickerRotation: (data['ticker_rotation'] as bool?) ?? tickerRotation,
    tickerIntervalIndex:
        (data['ticker_interval_index'] as num?)?.toInt() ?? tickerIntervalIndex,
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
  bool shuffleOrder = true,
  bool themeRotation = true,
  int themeIntervalIndex = 0,
  bool tickerRotation = true,
  int tickerIntervalIndex = 0,
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
  final setDesc = setsCount > 1
      ? '$setsCount ${shuffleOrder ? "randomized" : "sequential"} set(s)'
      : '1 set';
  buffer.writeln(
      '- **Scenario Duration**: `${durationSec}s` per test scenario ($setDesc)');
  buffer.writeln(
      '- **Order Book Scroll Animation**: ${mode == 'drive' && scrollAnimation ? "Enabled (Continuous VSync Oscillation)" : mode == 'drive' ? "Disabled (Static Center Viewport)" : "Disabled (Unsupported in Headless Mode)"}');
  buffer.writeln(
      '- **Theme Auto-Rotation**: `${themeRotation ? "Enabled (${_formatInterval(rotationIntervalPresetsMs[themeIntervalIndex])})" : "Disabled"}`');
  buffer.writeln(
      '- **Watchlist Ticker Auto-Rotation**: `${tickerRotation ? "Enabled (${_formatInterval(rotationIntervalPresetsMs[tickerIntervalIndex])})" : "Disabled"}`');
  buffer.writeln(
      '- **Execution Engine**: ${mode == 'drive' ? 'Flutter Driver Real Window, `--profile` build (GPU & VSync Timelines)' : 'Dedicated Background Isolate Ingestion & OS RSS Memory Sampling'}');
  if (mode == 'drive') {
    final sampleRefreshRate = results
        .map((r) => r.displayRefreshRate)
        .firstWhere((hz) => hz != null && hz > 0, orElse: () => null);
    final sampleBudget = results
        .map((r) => r.frameBudgetMs)
        .firstWhere((b) => b != null && b > 0, orElse: () => null);
    if (sampleRefreshRate != null) {
      buffer.writeln(
          '- **Display Refresh Rate & Frame Budget**: `${sampleRefreshRate.toStringAsFixed(1)}Hz` (${sampleBudget?.toStringAsFixed(2) ?? (1000.0 / sampleRefreshRate).toStringAsFixed(2)}ms deadline for Jank evaluation)');
    }
  }
  buffer.writeln(
      '- **Event Loop Lag sampling**: every 33ms over the full ${durationSec}s window of each set (about ${(durationSec / 0.033).round()} samples per set), stored in a pre-allocated fixed buffer.');
  buffer.writeln(
      '- **Scope**: see *Limitations* at the end of this report before drawing conclusions.');
  buffer.writeln();

  for (final tps in tpsScenarios) {
    buffer.writeln('---');
    final orderSuffix = setsCount > 1
        ? (shuffleOrder ? ', shuffled order' : ', sequential order')
        : '';
    buffer.writeln(
        '### Scenario: Target ${_formatNum(tps)} TPS — $setsCount set(s)$orderSuffix');
    buffer.writeln();
    buffer.writeln(
        'Per-set lag statistics are aggregated across sets. **Mean, Median and Trimmed Mean are all shown** (Trimmed Mean drops the single lowest and highest set when sets >= 4); no value is hidden. Rows are sorted by Median (lower is better).');
    buffer.writeln();

    if (mode == 'drive') {
      buffer.writeln(
          '| Framework | Generator Ingest TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag Trimmed Mean | P99 Lag (median of sets) | Max Lag (worst sample) | UI Build | GPU Raster | RSS |');
      buffer.writeln(
          '| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |');
    } else {
      buffer.writeln(
          '| Framework | Generator Ingest TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag Trimmed Mean | P99 Lag (median of sets) | Max Lag (worst sample) | RSS |');
      buffer.writeln(
          '| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |');
    }

    final targetMap = <String, List<BenchmarkRunResult>>{};
    for (final r in results.where((r) => r.targetTps == tps)) {
      targetMap.putIfAbsent(r.target.id, () => []).add(r);
    }

    final aggregatedList = <Map<String, dynamic>>[];
    targetMap.forEach((targetId, runList) {
      final setSustainedTps = runList.map((r) => r.sustainedTps).toList();
      final setBatchRates = runList
          .map((r) => r.frameworkUpdateRateHz)
          .whereType<int>()
          .toList();
      final setMeans =
          runList.map((r) => r.avgEventLoopLagMs).whereType<double>().toList();
      final setP99s =
          runList.map((r) => r.p99EventLoopLagMs).whereType<double>().toList();
      final setMaxes = runList
          .map((r) => r.maxEventLoopLagMs)
          .whereType<double>()
          .toList();
      final setMedians = runList
          .map((r) => r.medianEventLoopLagMs)
          .whereType<double>()
          .toList();
      final setBuilds = runList
          .map((r) => r.uiBuildTimeMs)
          .whereType<double>()
          .toList();
      final setRasters = runList
          .map((r) => r.rasterTimeMs)
          .whereType<double>()
          .toList();

      aggregatedList.add({
        'target': runList.first.target,
        'generator_tps': (setSustainedTps.reduce((a, b) => a + b) /
                setSustainedTps.length)
            .round(),
        'framework_update_hz': setBatchRates.isEmpty
            ? null
            : (setBatchRates.reduce((a, b) => a + b) / setBatchRates.length)
                .round(),
        'mean': _computeMean(setMeans),
        'median': _computeMedian(setMedians),
        'trimmed': _computeTrimmedMean(setMeans),
        'p99': _computeMedian(setP99s),
        'max':
            setMaxes.isEmpty ? null : setMaxes.reduce((a, b) => a > b ? a : b),
        'build': setBuilds.isEmpty
            ? null
            : setBuilds.reduce((a, b) => a + b) / setBuilds.length,
        'raster': setRasters.isEmpty
            ? null
            : setRasters.reduce((a, b) => a + b) / setRasters.length,
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
      final genTpsStr = '${_formatNum(agg['generator_tps'] as int)}/s';
      final fwUpdateStr = agg['framework_update_hz'] != null
          ? '${_formatNum(agg['framework_update_hz'] as int)} Hz'
          : 'n/a';
      final lagCells =
          '${_fmtLag(agg['mean'] as double?)} | ${_fmtLag(agg['median'] as double?)} | ${_fmtLag(agg['trimmed'] as double?)} | ${_fmtLag(agg['p99'] as double?)} | ${_fmtLag(agg['max'] as double?)}';
      final memStr = '${(agg['rss'] as double).toStringAsFixed(1)} MB';
      if (mode == 'drive') {
        final buildStr = agg['build'] != null
            ? '${(agg['build'] as double).toStringAsFixed(2)} ms'
            : 'n/a';
        final rasterStr = agg['raster'] != null
            ? '${(agg['raster'] as double).toStringAsFixed(2)} ms'
            : 'n/a';
        buffer.writeln(
            '| ${target.name} | $genTpsStr | $fwUpdateStr | $lagCells | $buildStr | $rasterStr | $memStr |');
      } else {
        buffer.writeln(
            '| ${target.name} | $genTpsStr | $fwUpdateStr | $lagCells | $memStr |');
      }
    }
    buffer.writeln();

    if (setsCount > 1) {
      buffer.writeln('#### Individual Set Breakdown (raw, unfiltered)');
      buffer.writeln();
      buffer.writeln(
          '| Set # | Framework | Generator TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag P99 | Lag Max | Samples | UI Build | GPU Raster | RSS |');
      buffer.writeln(
          '| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |');
      for (final res in results.where((r) => r.targetTps == tps)) {
        final setLabel = res.retryCount > 0
            ? 'Set ${res.setIndex} (retry ${res.retryCount})'
            : 'Set ${res.setIndex}';
        final genTps = '${_formatNum(res.sustainedTps)}/s';
        final fwRate = res.frameworkUpdateRateHz != null
            ? '${_formatNum(res.frameworkUpdateRateHz!)} Hz'
            : 'n/a';
        final buildStr = res.uiBuildTimeMs != null
            ? '${res.uiBuildTimeMs!.toStringAsFixed(2)} ms'
            : 'n/a';
        final rasterStr = res.rasterTimeMs != null
            ? '${res.rasterTimeMs!.toStringAsFixed(2)} ms'
            : 'n/a';
        buffer.writeln(
            '| $setLabel | ${res.target.name} | $genTps | $fwRate | ${_fmtLag(res.avgEventLoopLagMs)} | ${_fmtLag(res.medianEventLoopLagMs)} | ${_fmtLag(res.p99EventLoopLagMs)} | ${_fmtLag(res.maxEventLoopLagMs)} | ${res.lagSampleCount ?? 'n/a'} | $buildStr | $rasterStr | ${res.memoryRssMb.toStringAsFixed(1)} MB |');
      }
      buffer.writeln();

      final retried = results.where((r) => r.targetTps == tps && r.retryCount > 0).toList();
      if (retried.isNotEmpty) {
        buffer.writeln('> ⚠️ **Retried Runs Notice**:');
        for (final r in retried) {
          buffer.writeln(
              '> - **${r.target.name} (Set ${r.setIndex})**: initial attempt failed and was successfully retried once. Error details: `${r.failureReason ?? 'unspecified'}`');
        }
        buffer.writeln();
      }
    }
  }

  buffer.writeln('---');
  buffer.writeln('## Limitations');
  buffer.writeln();
  final hasExtremeTps = tpsScenarios.any((t) => t >= 10000000);
  if (hasExtremeTps) {
    buffer.writeln(
        '- **Real Hardware Simulation & Physical Saturation.** All tick batches are executed 100% in real hardware by the background isolate without artificial step capping or arithmetic tick padding. When target TPS is set to extreme values such as 1B TPS (10억 틱), the isolate naturally saturates the host single-core capacity (~14.5M TPS on Apple Silicon), reflecting genuine maximum physical throughput. Event Loop Lag on the main isolate remains the primary differentiator for UI responsiveness under heavy background streaming.');
  } else {
    buffer.writeln(
        '- **Real Hardware Simulation.** All tick batches are executed 100% in real hardware by the background isolate without artificial step capping or arithmetic tick padding at the configured target rates. Event Loop Lag on the main isolate remains the primary differentiator for UI responsiveness under streaming load.');
  }
  buffer.writeln(
      '- **Generator Ingestion Throughput vs. Framework State Update Frequency**:');
  buffer.writeln(
      '  - **Generator Ingest TPS (`generator_tps` / `sustained_tps`)**: Measures raw order-book ticks computed per second inside the dedicated background isolate (up to ~14.5M TPS on Apple Silicon under hardware saturation).');
  buffer.writeln(
      '  - **Framework Update Rate (`framework_update_rate_hz`)**: The background isolate groups ticks into 1ms batches (`TickBatchPayload`), transmitting ~1,000 batches per second across the isolate port to the main UI thread. Each incoming batch triggers reactive listeners and pipeline updates once. **`sustained_tps` must NOT be interpreted as 14.5 million individual UI widget rebuilds or distinct framework state-tree invalidations per second.**');
  if (mode == 'drive') {
    buffer.writeln(
        '- **Rendering Metrics.** Measured in profile mode with Flutter Driver on a real desktop GPU window over the full test duration. UI Build Time and GPU Raster Time reflect actual widget rebuild tree overhead and compositing performance under concurrent background isolate load.');
  } else {
    buffer.writeln(
        '- **Headless Execution Environment.** In headless mode, tests run within an isolated test VM process without desktop window rendering or GPU rasterization. Render metrics (UI Build, GPU Raster, FPS, Jank Rate) and Order Book Scroll Animation are omitted/disabled as not applicable to headless mode; evaluation focuses purely on background isolate ingestion throughput, event loop lag under reactive ticker and theme rotation stress, and memory RSS footprint.');
  }
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
      '- **Generator TPS vs. Framework Update Rate (Hz)**: Clear distinction is maintained between isolate tick production volume (`generator_tps`) and main-isolate reactive dispatch frequency (`framework_update_rate_hz`, batch dispatches/sec).');
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
  final modeDesc =
      mode == 'drive' ? 'Flutter Driver real GPU window' : 'headless';
  buffer.writeln(
      '*Report generated automatically via pure hardware $modeDesc measurement.*');

  return buffer.toString();
}

/// Generates JSON matrix dataset
Map<String, dynamic> _generateJsonMatrix(
  List<BenchmarkRunResult> results,
  List<int> tpsScenarios,
  String mode,
  int setsCount,
  bool scrollAnimation, {
  bool shuffleOrder = true,
  bool themeRotation = true,
  int themeIntervalIndex = 0,
  bool tickerRotation = true,
  int tickerIntervalIndex = 0,
}) {
  return {
    'suite': 'NASDAQ Order Book Mini Benchmark (100% Pure Hardware Execution)',
    'mode': mode,
    'sets_count': setsCount,
    'shuffle_order': shuffleOrder,
    'scroll_animation': scrollAnimation,
    'theme_rotation': themeRotation,
    'theme_interval_ms': rotationIntervalPresetsMs[themeIntervalIndex],
    'ticker_rotation': tickerRotation,
    'ticker_interval_ms': rotationIntervalPresetsMs[tickerIntervalIndex],
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
      'Framework,Architecture,Set_Index,Retry_Count,Target_TPS,Generator_TPS,Framework_Update_Rate_Hz,Achievement_Rate_Pct,Total_Ticks,Total_Batches,Avg_Event_Loop_Lag_Ms,Median_Lag_Ms,P95_Lag_Ms,P99_Lag_Ms,Max_Lag_Ms,Lag_Sample_Count,UI_Build_Time_Ms,Raster_Time_Ms,Actual_FPS,Jank_Rate_Pct,Display_Refresh_Rate_Hz,Frame_Budget_Ms,Memory_RSS_MB,Latency_Ms,Scroll_Animation,Theme_Rotation,Theme_Interval_Ms,Ticker_Rotation,Ticker_Interval_Ms');
  for (final r in results) {
    final lagStr = r.avgEventLoopLagMs != null
        ? r.avgEventLoopLagMs!.toStringAsFixed(3)
        : 'N/A';
    final medianStr = r.medianEventLoopLagMs != null
        ? r.medianEventLoopLagMs!.toStringAsFixed(3)
        : 'N/A';
    final p95Str = r.p95EventLoopLagMs != null
        ? r.p95EventLoopLagMs!.toStringAsFixed(3)
        : 'N/A';
    final p99Str = r.p99EventLoopLagMs != null
        ? r.p99EventLoopLagMs!.toStringAsFixed(3)
        : 'N/A';
    final maxStr = r.maxEventLoopLagMs != null
        ? r.maxEventLoopLagMs!.toStringAsFixed(3)
        : 'N/A';
    final themeIntervalMs = rotationIntervalPresetsMs[r.themeIntervalIndex];
    final tickerIntervalMs = rotationIntervalPresetsMs[r.tickerIntervalIndex];
    final buildStr =
        r.uiBuildTimeMs != null ? r.uiBuildTimeMs!.toStringAsFixed(2) : 'N/A';
    final rasterStr =
        r.rasterTimeMs != null ? r.rasterTimeMs!.toStringAsFixed(2) : 'N/A';
    final fpsStr =
        r.actualFps != null ? r.actualFps!.toStringAsFixed(1) : 'N/A';
    final jankStr =
        r.jankRatePct != null ? r.jankRatePct!.toStringAsFixed(2) : 'N/A';
    final refreshStr = r.displayRefreshRate != null
        ? r.displayRefreshRate!.toStringAsFixed(1)
        : 'N/A';
    final budgetStr = r.frameBudgetMs != null
        ? r.frameBudgetMs!.toStringAsFixed(2)
        : 'N/A';
    final batchRateStr =
        r.frameworkUpdateRateHz != null ? '${r.frameworkUpdateRateHz}' : 'N/A';
    final batchesStr = r.totalBatches != null ? '${r.totalBatches}' : 'N/A';

    buffer.writeln(
        '"${r.target.name}","${r.target.architecture}",${r.setIndex},${r.retryCount},${r.targetTps},${r.sustainedTps},$batchRateStr,${r.achievementRate.toStringAsFixed(2)},${r.totalTicks},$batchesStr,$lagStr,$medianStr,$p95Str,$p99Str,$maxStr,${r.lagSampleCount ?? 'N/A'},$buildStr,$rasterStr,$fpsStr,$jankStr,$refreshStr,$budgetStr,${r.memoryRssMb.toStringAsFixed(1)},${r.latencyMs.toStringAsFixed(2)},${r.scrollAnimation},${r.themeRotation},$themeIntervalMs,${r.tickerRotation},$tickerIntervalMs');
  }
  return buffer.toString();
}

String _formatNum(int num) {
  return num.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

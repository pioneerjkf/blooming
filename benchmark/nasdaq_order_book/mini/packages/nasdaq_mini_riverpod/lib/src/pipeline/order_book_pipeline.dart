import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'lag_recorder.dart';
import '../engine/order_book_models.dart';
import '../engine/tick_isolate.dart';
import '../providers/order_book_providers.dart';

/// Riverpod-based Data Pipeline managing a fine-grained reactive state graph
/// for a 50-level real-time NASDAQ order book benchmark application.
class OrderBookPipeline {
  /// Records every event loop lag sample during the measurement window.
  final LagRecorder lagRecorder = LagRecorder();

  OrderBookPipeline(this.ref) {
    _initWatchlistState();
    _isolateEngine = TickIsolateEngine();
    _startEventLoopMonitor();
    try {
      WidgetsBinding.instance.addTimingsCallback(_onFrameTimings);
    } catch (_) {}
  }

  // ===========================================================================
  // REAL-TIME ENGINE FRAME TIMINGS TRACKING
  // ===========================================================================

  double _lastUiBuildTimeMs = 0.0;
  double _lastRasterTimeMs = 0.0;
  double _lastJankRatePct = 0.0;
  final List<FrameTiming> _recentTimings = [];

  double get uiBuildTimeMs => _lastUiBuildTimeMs;
  double get rasterTimeMs => _lastRasterTimeMs;
  double get jankRatePct => _lastJankRatePct;

  void _onFrameTimings(List<FrameTiming> timings) {
    _recentTimings.addAll(timings);
    if (_recentTimings.length > 60) {
      _recentTimings.removeRange(0, _recentTimings.length - 60);
    }
    if (_recentTimings.isNotEmpty) {
      double totalBuild = 0.0;
      double totalRaster = 0.0;
      int jankCount = 0;
      for (final t in _recentTimings) {
        final buildMs = t.buildDuration.inMicroseconds / 1000.0;
        final rasterMs = t.rasterDuration.inMicroseconds / 1000.0;
        totalBuild += buildMs;
        totalRaster += rasterMs;
        if (t.totalSpan.inMicroseconds > 16666) {
          jankCount++;
        }
      }
      _lastUiBuildTimeMs =
          double.parse((totalBuild / _recentTimings.length).toStringAsFixed(2));
      _lastRasterTimeMs = double.parse(
          (totalRaster / _recentTimings.length).toStringAsFixed(2));
      _lastJankRatePct = double.parse(
          ((jankCount / _recentTimings.length) * 100.0).toStringAsFixed(1));
    }
  }

  int get actualTpsValue => (ref.read(actualTpsProvider) as int?) ?? 0;
  OrderBookSnapshot get snapshotValue =>
      (ref.read(snapshotProvider) as OrderBookSnapshot);
  double get eventLoopLagValue =>
      (ref.read(eventLoopLagProvider) as double?) ?? 0.0;
  double get latencyMsValue => (ref.read(latencyMsProvider) as double?) ?? 0.0;
  bool get isScrollAnimationEnabled =>
      (ref.read(scrollAnimationEnabledProvider) as bool?) ?? true;
  void setScrollAnimationEnabled(bool enabled) =>
      ref.read(scrollAnimationEnabledProvider.notifier).set(enabled);
  void toggleScrollAnimation() =>
      ref.read(scrollAnimationEnabledProvider.notifier).toggle();

  BenchmarkProgress get benchmarkProgress =>
      (ref.read(benchmarkProgressProvider) as BenchmarkProgress?) ??
      const BenchmarkProgress();
  void setBenchmarkProgress({
    required int currentSet,
    required int totalSets,
    required int currentBench,
    required int totalBenches,
    int currentRun = 1,
    int totalRuns = 1,
  }) {
    ref.read(benchmarkProgressProvider.notifier).set(
          BenchmarkProgress(
            currentSet: currentSet,
            totalSets: totalSets,
            currentBench: currentBench,
            totalBenches: totalBenches,
            currentRun: currentRun,
            totalRuns: totalRuns,
          ),
        );
  }

  final dynamic ref;

  /// Preset interval options in milliseconds for stock auto-rotation.
  static const List<double> rotationIntervalPresetsMs = [
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

  /// List of supported NASDAQ stock items.
  final List<NasdaqStockItem> stocks = NasdaqStockItem.defaultStocks;

  final Random _random = Random();
  late final TickIsolateEngine _isolateEngine;
  late List<double> _priceHistory;
  final List<TradeTick> _tradeTicks = [];
  final Map<String, double> _latestStockPrices = {};
  final Map<String, double> _latestStockChanges = {};

  Timer? _rotationTimer;
  int _totalTicksSinceMeasurement = 0;
  int _lastMeasurementTimestamp = DateTime.now().millisecondsSinceEpoch;

  final Stopwatch _eventLoopStopwatch = Stopwatch()..start();
  Timer? _eventLoopTimer;
  final List<double> _eventLoopHistory = List.generate(40, (_) => 0.0);
  final List<double> _eventLoop1sWindow = [];
  double _eventLoop1sSum = 0.0;
  final List<double> _eventLoopAvg1sHistory = List.generate(40, (_) => 0.0);
  final List<double> _eventLoop5sWindow = [];
  double _eventLoop5sSum = 0.0;
  final List<double> _eventLoopAvg5sHistory = List.generate(40, (_) => 0.0);

  void _initWatchlistState() {
    final initialSnap = ref.read(snapshotProvider);
    _priceHistory =
        List.generate(40, (i) => initialSnap.lastPrice - ((39 - i) * 0.04));

    for (final stock in stocks) {
      _latestStockPrices[stock.symbol] = stock.basePrice;
      _latestStockChanges[stock.symbol] = stock.priceChangePct;
    }
    _latestStockPrices[initialSnap.ticker] = initialSnap.lastPrice;
    _latestStockChanges[initialSnap.ticker] = initialSnap.priceChangePct;
  }

  // ===========================================================================
  // WATCHLIST & STOCK NAVIGATION INTENTS
  // ===========================================================================

  /// Selects a specific stock from the NASDAQ stock list by index.
  void selectStock(int index) {
    if (index < 0 || index >= stocks.length) return;
    ref.read(selectedStockIndexProvider.notifier).set(index);
    final stock = stocks[index];

    final newSnapshot = OrderBookSnapshot.initial(
      ticker: stock.symbol,
      basePrice: stock.basePrice,
    );
    ref.read(snapshotProvider.notifier).set(newSnapshot);

    _priceHistory =
        List.generate(40, (i) => stock.basePrice - ((39 - i) * 0.04));
    ref
        .read(priceHistoryProvider.notifier)
        .set(UnmodifiableListView(_priceHistory));

    for (int i = 0; i < 25; i++) {
      ref.read(askRowProvider(i).notifier).set(newSnapshot.asks[i]);
      ref.read(bidRowProvider(i).notifier).set(newSnapshot.bids[i]);
    }

    _tradeTicks.clear();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _tradeTicks.addAll(List.generate(10, (i) {
      return TradeTick(
        price: double.parse(
            (stock.basePrice + ((i % 3 - 1) * 0.05)).toStringAsFixed(2)),
        volume: (10 + (i * 3)) * 100,
        isBuy: i % 2 == 0,
        timestampMs: nowMs - (i * 800),
      );
    }));
    ref
        .read(tradeTicksProvider.notifier)
        .set(UnmodifiableListView(_tradeTicks));

    _isolateEngine.setStockPrice(stock.basePrice);
  }

  /// Selects the next stock in circular order.
  void selectNextStock() {
    final selectedIndex = ref.read(selectedStockIndexProvider);
    final nextIndex = (selectedIndex + 1) % stocks.length;
    selectStock(nextIndex);
  }

  /// Starts auto-rotating through the stock list.
  void startAutoRotation() {
    ref.read(stockAutoRotatingProvider.notifier).set(true);
    _restartRotationTimer();
  }

  /// Stops auto-rotating through the stock list.
  void stopAutoRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
    ref.read(stockAutoRotatingProvider.notifier).set(false);
  }

  /// Toggles auto-rotation on and off.
  void toggleAutoRotation() {
    final isAutoRotating = ref.read(stockAutoRotatingProvider);
    if (isAutoRotating) {
      stopAutoRotation();
    } else {
      startAutoRotation();
    }
  }

  /// Updates rotation interval preset index (0 to 9).
  void setRotationIntervalIndex(int index) {
    final clamped = index.clamp(0, rotationIntervalPresetsMs.length - 1);
    ref.read(stockRotationIntervalIndexProvider.notifier).set(clamped);
    if (ref.read(stockAutoRotatingProvider)) {
      _restartRotationTimer();
    }
  }

  // ===========================================================================
  // ISOLATE SIMULATION ENGINE CONTROLS & BATCH INGESTION
  // ===========================================================================

  /// Starts the Isolate simulation engine.
  Future<void> startSimulation() async {
    if (ref.read(isSimulatingProvider)) return;

    ref.read(isSimulatingProvider.notifier).set(true);
    _lastMeasurementTimestamp = DateTime.now().millisecondsSinceEpoch;
    _totalTicksSinceMeasurement = 0;

    await _isolateEngine.start(
      targetTps: ref.read(targetTpsProvider),
      onBatchReceived: updateBatch,
    );
  }

  /// Stops the Isolate simulation engine.
  Future<void> stopSimulation() async {
    await _isolateEngine.stop();
    ref.read(isSimulatingProvider.notifier).set(false);
    ref.read(actualTpsProvider.notifier).set(0);
  }

  /// Updates target TPS dynamically.
  void setTargetTps(int tps) {
    ref.read(targetTpsProvider.notifier).set(tps);
    if (ref.read(isSimulatingProvider)) {
      _isolateEngine.updateTps(tps);
    }
  }

  /// Direct Batch Injection entrypoint called from Isolate background thread.
  void updateBatch(TickBatchPayload payload) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    _totalTicksSinceMeasurement += payload.batchSize;
    final elapsed = nowMs - _lastMeasurementTimestamp;

    if (elapsed >= 500) {
      final currentTps =
          ((_totalTicksSinceMeasurement * 1000) / elapsed).round();
      ref.read(actualTpsProvider.notifier).set(currentTps);

      final latency = (nowMs - payload.timestampMs).toDouble();
      ref.read(latencyMsProvider.notifier).set(latency.clamp(0.0, 999.0));

      _totalTicksSinceMeasurement = 0;
      _lastMeasurementTimestamp = nowMs;
    }

    // 1. Update rolling price history for real-time mini chart
    _priceHistory.add(payload.latestPrice);
    if (_priceHistory.length > 50) {
      _priceHistory.removeAt(0);
    }
    ref
        .read(priceHistoryProvider.notifier)
        .set(UnmodifiableListView(_priceHistory));

    // 1b. Update trade ticks list
    if (payload.recentTrades.isNotEmpty) {
      _tradeTicks.insertAll(0, payload.recentTrades);
      if (_tradeTicks.length > 40) {
        _tradeTicks.removeRange(40, _tradeTicks.length);
      }
      ref
          .read(tradeTicksProvider.notifier)
          .set(UnmodifiableListView(_tradeTicks));
    }

    // 2. Update 25 Asks fine-grained row providers
    for (int i = 0; i < 25; i++) {
      ref.read(askRowProvider(i).notifier).set(payload.updatedAsks[i]);
    }

    // 3. Update 25 Bids fine-grained row providers
    for (int i = 0; i < 25; i++) {
      ref.read(bidRowProvider(i).notifier).set(payload.updatedBids[i]);
    }

    // 4. Update overall snapshot & multi-asset watchlist live price ticks
    final currentSnap = ref.read(snapshotProvider);
    final activeTicker = currentSnap.ticker;
    _updateStockPriceState(
        activeTicker, payload.latestPrice, payload.priceChangePct);

    for (final stock in stocks) {
      if (stock.symbol == activeTicker) continue;
      if (_random.nextDouble() < 0.20) {
        final currentP = _latestStockPrices[stock.symbol] ?? stock.basePrice;
        final delta = (_random.nextDouble() - 0.49) * 0.12;
        final newP = double.parse((currentP + delta).toStringAsFixed(2));
        final newChgPct = double.parse(
          (((newP - stock.basePrice) / stock.basePrice) * 100)
              .toStringAsFixed(2),
        );
        _updateStockPriceState(stock.symbol, newP, newChgPct);
      }
    }

    ref.read(snapshotProvider.notifier).set(OrderBookSnapshot(
          ticker: currentSnap.ticker,
          lastPrice: payload.latestPrice,
          priceChange: payload.priceChange,
          priceChangePct: payload.priceChangePct,
          asks: payload.updatedAsks,
          bids: payload.updatedBids,
          maxVolume: currentSnap.maxVolume,
          totalVolume: currentSnap.totalVolume + payload.batchSize * 100,
          totalTicksProcessed: payload.totalTicksProcessed,
          timestampMs: payload.timestampMs,
        ));
  }

  void _updateStockPriceState(String symbol, double price, double changePct) {
    if (_latestStockPrices[symbol] != price) {
      _latestStockPrices[symbol] = price;
      ref.read(stockPriceProvider(symbol).notifier).set(price);
    }
    if (_latestStockChanges[symbol] != changePct) {
      _latestStockChanges[symbol] = changePct;
      ref.read(stockChangeProvider(symbol).notifier).set(changePct);
    }
  }

  void _startEventLoopMonitor() {
    _eventLoopTimer?.cancel();
    _eventLoopTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      final scheduledMicros = _eventLoopStopwatch.elapsedMicroseconds;
      Timer.run(() {
        final elapsedMicros =
            _eventLoopStopwatch.elapsedMicroseconds - scheduledMicros;
        final lagMs = elapsedMicros / 1000.0;
        lagRecorder.add(lagMs);

        // 1. Tick Instantaneous Delay (Yellow Bar Chart)
        ref.read(eventLoopLagProvider.notifier).set(lagMs);

        _eventLoopHistory.add(lagMs);
        if (_eventLoopHistory.length > 40) {
          _eventLoopHistory.removeAt(0);
        }
        ref
            .read(eventLoopHistoryProvider.notifier)
            .set(UnmodifiableListView(_eventLoopHistory));

        // 2. 1-Second Moving Average (Cyan Line Chart)
        _eventLoop1sWindow.add(lagMs);
        _eventLoop1sSum += lagMs;
        if (_eventLoop1sWindow.length > 30) {
          _eventLoop1sSum -= _eventLoop1sWindow.removeAt(0);
        }
        final avg1s = _eventLoop1sWindow.isNotEmpty
            ? _eventLoop1sSum / _eventLoop1sWindow.length
            : lagMs;
        ref.read(eventLoopAvg1sProvider.notifier).set(avg1s);

        _eventLoopAvg1sHistory.add(avg1s);
        if (_eventLoopAvg1sHistory.length > 40) {
          _eventLoopAvg1sHistory.removeAt(0);
        }
        ref
            .read(eventLoopAvg1sHistoryProvider.notifier)
            .set(UnmodifiableListView(_eventLoopAvg1sHistory));

        // 3. 5-Second Moving Average (Pink Line Chart)
        _eventLoop5sWindow.add(lagMs);
        _eventLoop5sSum += lagMs;
        if (_eventLoop5sWindow.length > 150) {
          _eventLoop5sSum -= _eventLoop5sWindow.removeAt(0);
        }
        final avg5s = _eventLoop5sWindow.isNotEmpty
            ? _eventLoop5sSum / _eventLoop5sWindow.length
            : lagMs;
        ref.read(eventLoopAvg5sProvider.notifier).set(avg5s);

        _eventLoopAvg5sHistory.add(avg5s);
        if (_eventLoopAvg5sHistory.length > 40) {
          _eventLoopAvg5sHistory.removeAt(0);
        }
        ref
            .read(eventLoopAvg5sHistoryProvider.notifier)
            .set(UnmodifiableListView(_eventLoopAvg5sHistory));
      });
    });
  }

  void _restartRotationTimer() {
    _rotationTimer?.cancel();
    final intervalIndex = ref.read(stockRotationIntervalIndexProvider);
    final intervalMs = rotationIntervalPresetsMs[intervalIndex];
    _rotationTimer = Timer.periodic(
      Duration(microseconds: (intervalMs * 1000).round()),
      (_) {
        selectNextStock();
      },
    );
  }

  /// Disposes background timers and isolates.
  void dispose() {
    try {
      WidgetsBinding.instance.removeTimingsCallback(_onFrameTimings);
    } catch (_) {}
    _eventLoopTimer?.cancel();
    stopAutoRotation();
    stopSimulation();
  }
}

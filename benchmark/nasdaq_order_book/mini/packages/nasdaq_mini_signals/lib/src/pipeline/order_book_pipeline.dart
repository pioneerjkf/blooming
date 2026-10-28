import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'lag_recorder.dart';
import '../engine/order_book_models.dart';
import '../engine/tick_isolate.dart';

/// Signals-based Data Pipeline managing fine-grained reactive state graph
/// for a 50-level real-time NASDAQ order book benchmark application (Swiss Theme).
class OrderBookPipeline {
  /// Records every event loop lag sample during the measurement window.
  final LagRecorder lagRecorder = LagRecorder();

  // ===========================================================================
  // 1. CONSTANTS & PUBLIC CONFIGURATION
  // ===========================================================================

  /// Preset interval options in milliseconds for theme/stock auto-rotation.
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

  // ===========================================================================
  // 2. SIGNALS STATE NODES (ENCAPSULATED)
  // ===========================================================================

  // 2a. Order Book Signals
  late final Signal<OrderBookSnapshot> _snapshotSignal;
  late final Signal<List<double>> _priceHistorySignal;
  late final List<Signal<OrderBookRowData>> _askSignals;
  late final List<Signal<OrderBookRowData>> _bidSignals;
  late final Signal<List<TradeTick>> _tradeTicksSignal;

  // 2b. Benchmark Engine & Metrics Signals
  late final Signal<int> _targetTpsSignal;
  late final Signal<bool> _isSimulatingSignal;
  late final Signal<bool> _isScrollAnimationEnabledSignal;
  late final Signal<int> _actualTpsSignal;
  late final Signal<double> _latencyMsSignal;
  late final Signal<double> _eventLoopLagSignal;
  late final Signal<List<double>> _eventLoopHistorySignal;
  late final Signal<double> _eventLoopAvg1sSignal;
  late final Signal<List<double>> _eventLoopAvg1sHistorySignal;
  late final Signal<double> _eventLoopAvg5sSignal;
  late final Signal<List<double>> _eventLoopAvg5sHistorySignal;
  late final Signal<BenchmarkProgress> _benchmarkProgressSignal;

  // 2c. Watchlist & Selection Signals
  late final Signal<int> _selectedStockIndexSignal;
  late final Signal<bool> _isAutoRotatingSignal;
  late final Signal<int> _rotationIntervalIndexSignal;
  final Map<String, Signal<double>> _stockPriceSignals = {};
  final Map<String, Signal<double>> _stockChangeSignals = {};

  // Public ReadonlySignal Views
  ReadonlySignal<OrderBookSnapshot> get snapshotSignal => _snapshotSignal;
  ReadonlySignal<List<double>> get priceHistorySignal => _priceHistorySignal;
  List<ReadonlySignal<OrderBookRowData>> get askSignals => _askSignals;
  List<ReadonlySignal<OrderBookRowData>> get bidSignals => _bidSignals;
  ReadonlySignal<List<TradeTick>> get tradeTicksSignal => _tradeTicksSignal;

  ReadonlySignal<int> get targetTpsSignal => _targetTpsSignal;
  ReadonlySignal<bool> get isSimulatingSignal => _isSimulatingSignal;
  ReadonlySignal<bool> get isScrollAnimationEnabledSignal =>
      _isScrollAnimationEnabledSignal;
  bool get isScrollAnimationEnabled => _isScrollAnimationEnabledSignal.value;
  void setScrollAnimationEnabled(bool enabled) =>
      _isScrollAnimationEnabledSignal.value = enabled;
  void toggleScrollAnimation() =>
      setScrollAnimationEnabled(!isScrollAnimationEnabled);

  ReadonlySignal<BenchmarkProgress> get benchmarkProgressSignal =>
      _benchmarkProgressSignal;
  BenchmarkProgress get benchmarkProgress => _benchmarkProgressSignal.value;
  void setBenchmarkProgress({
    required int currentSet,
    required int totalSets,
    required int currentBench,
    required int totalBenches,
    int currentRun = 1,
    int totalRuns = 1,
  }) {
    _benchmarkProgressSignal.value = BenchmarkProgress(
      currentSet: currentSet,
      totalSets: totalSets,
      currentBench: currentBench,
      totalBenches: totalBenches,
      currentRun: currentRun,
      totalRuns: totalRuns,
    );
  }

  ReadonlySignal<int> get actualTpsSignal => _actualTpsSignal;
  ReadonlySignal<double> get latencyMsSignal => _latencyMsSignal;
  ReadonlySignal<double> get eventLoopLagSignal => _eventLoopLagSignal;
  ReadonlySignal<List<double>> get eventLoopHistorySignal =>
      _eventLoopHistorySignal;
  ReadonlySignal<double> get eventLoopAvg1sSignal => _eventLoopAvg1sSignal;
  ReadonlySignal<List<double>> get eventLoopAvg1sHistorySignal =>
      _eventLoopAvg1sHistorySignal;
  ReadonlySignal<double> get eventLoopAvg5sSignal => _eventLoopAvg5sSignal;
  ReadonlySignal<List<double>> get eventLoopAvg5sHistorySignal =>
      _eventLoopAvg5sHistorySignal;

  ReadonlySignal<int> get selectedStockIndexSignal => _selectedStockIndexSignal;
  ReadonlySignal<bool> get isAutoRotatingSignal => _isAutoRotatingSignal;
  ReadonlySignal<int> get rotationIntervalIndexSignal =>
      _rotationIntervalIndexSignal;
  Map<String, ReadonlySignal<double>> get stockPriceSignals =>
      _stockPriceSignals;
  Map<String, ReadonlySignal<double>> get stockChangeSignals =>
      _stockChangeSignals;

  // ===========================================================================
  // 3. INTERNAL PRIVATE FIELDS & ENGINE DRIVERS
  // ===========================================================================

  final Random _random = Random();
  late final TickIsolateEngine _isolateEngine;
  late List<double> _priceHistory;
  final List<TradeTick> _tradeTicks = [];
  final Map<String, double> _latestStockPrices = {};
  final Map<String, double> _latestStockChanges = {};
  final Map<String, OrderBookSnapshot> _stockSnapshots = {};
  final Map<String, List<double>> _stockPriceHistories = {};
  final Map<String, List<TradeTick>> _stockTradeTicks = {};

  Timer? _rotationTimer;
  int _totalTicksSinceMeasurement = 0;
  int _totalBatchesProcessed = 0;
  int get totalBatchesProcessed => _totalBatchesProcessed;
  int _totalTicksProcessed = 0;
  int get totalTicksProcessed => _totalTicksProcessed;
  int _lastMeasurementTimestamp = DateTime.now().millisecondsSinceEpoch;
  int _lastChartUpdateMs = 0;

  final Stopwatch _eventLoopStopwatch = Stopwatch()..start();
  Timer? _eventLoopTimer;
  final List<double> _eventLoopHistory = List.generate(40, (_) => 0.0);
  final List<double> _eventLoop1sWindow = [];
  double _eventLoop1sSum = 0.0;
  final List<double> _eventLoopAvg1sHistory = List.generate(40, (_) => 0.0);
  final List<double> _eventLoop5sWindow = [];
  double _eventLoop5sSum = 0.0;
  final List<double> _eventLoopAvg5sHistory = List.generate(40, (_) => 0.0);

  // ===========================================================================
  // 4. CONSTRUCTOR & INITIALIZATION
  // ===========================================================================

  OrderBookPipeline() {
    final initialSnapshot = OrderBookSnapshot.initial();
    _stockSnapshots[initialSnapshot.ticker] = initialSnapshot;

    _snapshotSignal = signal<OrderBookSnapshot>(initialSnapshot);

    // Initialize Rolling Price History (40 slots)
    _priceHistory = List.generate(40, (i) {
      return initialSnapshot.lastPrice - ((39 - i) * 0.04);
    });
    _stockPriceHistories[initialSnapshot.ticker] = List.from(_priceHistory);
    _priceHistorySignal =
        signal<List<double>>(UnmodifiableListView(_priceHistory));

    // Initialize 25 Ask & 25 Bid Fine-Grained Reactive Row Signals
    _askSignals = List.generate(25, (i) {
      return signal<OrderBookRowData>(initialSnapshot.asks[i]);
    });
    _bidSignals = List.generate(25, (i) {
      return signal<OrderBookRowData>(initialSnapshot.bids[i]);
    });

    // Control and metric signals
    _targetTpsSignal = signal<int>(100);
    _isSimulatingSignal = signal<bool>(false);
    _isScrollAnimationEnabledSignal =
        signal<bool>(Platform.environment['BENCH_SCROLL_ANIM'] != 'false');
    _actualTpsSignal = signal<int>(0);
    _latencyMsSignal = signal<double>(0.0);
    _eventLoopLagSignal = signal<double>(0.0);
    _eventLoopHistorySignal = signal<List<double>>(
      UnmodifiableListView(_eventLoopHistory),
    );
    _eventLoopAvg1sSignal = signal<double>(0.0);
    _eventLoopAvg1sHistorySignal = signal<List<double>>(
      UnmodifiableListView(_eventLoopAvg1sHistory),
    );
    _eventLoopAvg5sSignal = signal<double>(0.0);
    _eventLoopAvg5sHistorySignal = signal<List<double>>(
      UnmodifiableListView(_eventLoopAvg5sHistory),
    );

    final envSet =
        int.tryParse(Platform.environment['BENCH_SET_INDEX'] ?? '') ?? 1;
    final envTotalSets =
        int.tryParse(Platform.environment['BENCH_TOTAL_SETS'] ?? '') ?? 1;
    final envBench =
        int.tryParse(Platform.environment['BENCH_TARGET_INDEX'] ?? '') ?? 1;
    final envTotalBenches =
        int.tryParse(Platform.environment['BENCH_TOTAL_TARGETS'] ?? '') ?? 1;
    final envRun =
        int.tryParse(Platform.environment['BENCH_RUN_INDEX'] ?? '') ?? 1;
    final envTotalRuns =
        int.tryParse(Platform.environment['BENCH_TOTAL_RUNS'] ?? '') ?? 1;
    _benchmarkProgressSignal = signal<BenchmarkProgress>(
      BenchmarkProgress(
        currentSet: envSet,
        totalSets: envTotalSets,
        currentBench: envBench,
        totalBenches: envTotalBenches,
        currentRun: envRun,
        totalRuns: envTotalRuns,
      ),
    );

    // Watchlist selection signals
    _selectedStockIndexSignal = signal<int>(0);
    _isAutoRotatingSignal = signal<bool>(false);
    _rotationIntervalIndexSignal = signal<int>(6); // Default 1000ms

    // Initial Trade Ticks Sample
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _tradeTicks.addAll(List.generate(10, (i) {
      return TradeTick(
        price: double.parse(
          (initialSnapshot.lastPrice + ((i % 3 - 1) * 0.05)).toStringAsFixed(2),
        ),
        volume: (10 + (i * 3)) * 100,
        isBuy: i % 2 == 0,
        timestampMs: nowMs - (i * 800),
      );
    }));
    _tradeTicksSignal =
        signal<List<TradeTick>>(UnmodifiableListView(_tradeTicks));

    // Initialize Multi-Asset Watchlist Price Signals
    for (final stock in stocks) {
      _latestStockPrices[stock.symbol] = stock.basePrice;
      _latestStockChanges[stock.symbol] = stock.priceChangePct;
      _stockPriceSignals[stock.symbol] = signal<double>(stock.basePrice);
      _stockChangeSignals[stock.symbol] = signal<double>(stock.priceChangePct);
    }
    _latestStockPrices[initialSnapshot.ticker] = initialSnapshot.lastPrice;
    _latestStockChanges[initialSnapshot.ticker] =
        initialSnapshot.priceChangePct;
    _stockPriceSignals[initialSnapshot.ticker]?.value =
        initialSnapshot.lastPrice;
    _stockChangeSignals[initialSnapshot.ticker]?.value =
        initialSnapshot.priceChangePct;

    _isolateEngine = TickIsolateEngine();

    // Start Event Loop Queue Delay Monitoring (50ms heartbeat)
    _startEventLoopMonitor();

    // Register real-time Flutter Engine FrameTiming callback
    try {
      WidgetsBinding.instance.addTimingsCallback(_onFrameTimings);
    } catch (_) {}
  }

  // ===========================================================================
  // 4b. REAL-TIME ENGINE FRAME TIMINGS TRACKING
  // ===========================================================================

  double _lastUiBuildTimeMs = 0.0;
  double _lastRasterTimeMs = 0.0;
  double _lastJankRatePct = 0.0;
  final List<FrameTiming> _recentTimings = [];

  double get uiBuildTimeMs => _lastUiBuildTimeMs;
  double get rasterTimeMs => _lastRasterTimeMs;
  double get jankRatePct => _lastJankRatePct;

  int _getFrameBudgetUs() {
    try {
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isNotEmpty) {
        final rate = views.first.display.refreshRate;
        if (rate > 0) return (1000000.0 / rate).round();
      }
    } catch (_) {}
    return 8333;
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    _recentTimings.addAll(timings);
    if (_recentTimings.length > 60) {
      _recentTimings.removeRange(0, _recentTimings.length - 60);
    }
    if (_recentTimings.isNotEmpty) {
      double totalBuild = 0.0;
      double totalRaster = 0.0;
      int jankCount = 0;
      final budgetUs = _getFrameBudgetUs();
      for (final t in _recentTimings) {
        final buildMs = t.buildDuration.inMicroseconds / 1000.0;
        final rasterMs = t.rasterDuration.inMicroseconds / 1000.0;
        totalBuild += buildMs;
        totalRaster += rasterMs;
        if (t.buildDuration.inMicroseconds > budgetUs ||
            t.rasterDuration.inMicroseconds > budgetUs) {
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

  // ===========================================================================
  // 5. PUBLIC ACCESSORS & HELPER GETTERS
  // ===========================================================================

  int get selectedStockIndex => _selectedStockIndexSignal.value;
  NasdaqStockItem get selectedStock => stocks[selectedStockIndex];
  bool get isAutoRotating => _isAutoRotatingSignal.value;
  int get rotationIntervalIndex => _rotationIntervalIndexSignal.value;
  double get currentRotationIntervalMs =>
      rotationIntervalPresetsMs[rotationIntervalIndex];

  double getLatestPrice(String symbol, double fallbackBasePrice) =>
      _latestStockPrices[symbol] ?? fallbackBasePrice;

  double getLatestChangePct(String symbol, double fallbackChangePct) =>
      _latestStockChanges[symbol] ?? fallbackChangePct;

  // ===========================================================================
  // 6. WATCHLIST & STOCK NAVIGATION INTENTS
  // ===========================================================================

  /// Selects a specific stock from the NASDAQ stock list by index.
  void selectStock(int index) {
    if (index < 0 || index >= stocks.length) return;
    final stock = stocks[index];

    // 1. Cache current active stock state
    final currentSnap = _snapshotSignal.value;
    _stockSnapshots[currentSnap.ticker] = currentSnap;
    _stockPriceHistories[currentSnap.ticker] = List.from(_priceHistory);
    _stockTradeTicks[currentSnap.ticker] = List.from(_tradeTicks);

    // 2. Retrieve or initialize the selected stock's state
    final cachedSnap = _stockSnapshots[stock.symbol];
    final OrderBookSnapshot newSnapshot;
    if (cachedSnap != null) {
      newSnapshot =
          cachedSnap.copyWith(totalTicksProcessed: _totalTicksProcessed);
    } else {
      newSnapshot = OrderBookSnapshot.initial(
        ticker: stock.symbol,
        basePrice: stock.basePrice,
        totalTicksProcessed: _totalTicksProcessed,
      );
      _stockSnapshots[stock.symbol] = newSnapshot;
    }

    final cachedHistory = _stockPriceHistories[stock.symbol];
    if (cachedHistory != null && cachedHistory.isNotEmpty) {
      _priceHistory = List.from(cachedHistory);
    } else {
      _priceHistory =
          List.generate(40, (i) => stock.basePrice - ((39 - i) * 0.04));
      _stockPriceHistories[stock.symbol] = List.from(_priceHistory);
    }

    _tradeTicks.clear();
    final cachedTrades = _stockTradeTicks[stock.symbol];
    if (cachedTrades != null && cachedTrades.isNotEmpty) {
      _tradeTicks.addAll(cachedTrades);
    } else {
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
      _stockTradeTicks[stock.symbol] = List.from(_tradeTicks);
    }

    batch(() {
      _selectedStockIndexSignal.value = index;
      _snapshotSignal.value = newSnapshot;
      _priceHistorySignal.value = UnmodifiableListView(_priceHistory);

      for (int i = 0; i < 25; i++) {
        _askSignals[i].value = newSnapshot.asks[i];
        _bidSignals[i].value = newSnapshot.bids[i];
      }

      _tradeTicksSignal.value = UnmodifiableListView(_tradeTicks);
    });

    _isolateEngine.setStock(stock.symbol, stock.basePrice);
  }

  /// Selects the next stock in circular order.
  void selectNextStock() {
    final nextIndex = (selectedStockIndex + 1) % stocks.length;
    selectStock(nextIndex);
  }

  /// Starts auto-rotating through the stock list.
  void startAutoRotation() {
    _isAutoRotatingSignal.value = true;
    _restartRotationTimer();
  }

  /// Stops auto-rotating through the stock list.
  void stopAutoRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
    _isAutoRotatingSignal.value = false;
  }

  /// Toggles auto-rotation on and off.
  void toggleAutoRotation() {
    if (isAutoRotating) {
      stopAutoRotation();
    } else {
      startAutoRotation();
    }
  }

  /// Updates rotation interval preset index (0 to 9).
  void setRotationIntervalIndex(int index) {
    final clamped = index.clamp(0, rotationIntervalPresetsMs.length - 1);
    _rotationIntervalIndexSignal.value = clamped;
    if (isAutoRotating) {
      _restartRotationTimer();
    }
  }

  // ===========================================================================
  // 7. ISOLATE SIMULATION ENGINE CONTROLS & BATCH INGESTION
  // ===========================================================================

  /// Starts the Isolate simulation engine.
  Future<void> startSimulation() async {
    if (_isSimulatingSignal.value) return;

    _isSimulatingSignal.value = true;
    _lastMeasurementTimestamp = DateTime.now().millisecondsSinceEpoch;
    _totalTicksSinceMeasurement = 0;

    await _isolateEngine.start(
      targetTps: _targetTpsSignal.value,
      onBatchReceived: updateBatch,
    );
  }

  /// Stops the Isolate simulation engine.
  Future<void> stopSimulation() async {
    await _isolateEngine.stop();
    batch(() {
      _isSimulatingSignal.value = false;
      _actualTpsSignal.value = 0;
    });
  }

  /// Updates target TPS dynamically.
  void setTargetTps(int tps) {
    _targetTpsSignal.value = tps;
    if (_isSimulatingSignal.value) {
      _isolateEngine.updateTps(tps);
    }
  }

  /// Direct Batch Injection entrypoint called from Isolate background thread.
  void updateBatch(TickBatchPayload payload) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    _totalTicksSinceMeasurement += payload.batchSize;
    _totalBatchesProcessed++;
    _totalTicksProcessed = payload.totalTicksProcessed;
    final elapsed = nowMs - _lastMeasurementTimestamp;

    batch(() {
      if (elapsed >= 500) {
        final currentTps =
            ((_totalTicksSinceMeasurement * 1000) / elapsed).round();
        _actualTpsSignal.value = currentTps;

        final latency = (nowMs - payload.timestampMs).toDouble();
        _latencyMsSignal.value = latency.clamp(0.0, 999.0);

        _totalTicksSinceMeasurement = 0;
        _lastMeasurementTimestamp = nowMs;
      }

      final activeTicker = _snapshotSignal.value.ticker;
      if (payload.ticker.isNotEmpty && payload.ticker != activeTicker) {
        _updateCachedStockState(payload);
        return;
      }

      // 1. Update rolling price history for real-time mini chart
      if (!kIsWeb || (nowMs - _lastChartUpdateMs >= 16)) {
        _lastChartUpdateMs = nowMs;
        _priceHistory.add(payload.latestPrice);
        if (_priceHistory.length > 50) {
          _priceHistory.removeAt(0);
        }
        _priceHistorySignal.value = UnmodifiableListView(_priceHistory);
      }

      // 1b. Update trade ticks list
      if (payload.recentTrades.isNotEmpty) {
        _tradeTicks.insertAll(0, payload.recentTrades);
        if (_tradeTicks.length > 40) {
          _tradeTicks.removeRange(40, _tradeTicks.length);
        }
        _tradeTicksSignal.value = UnmodifiableListView(_tradeTicks);
      }

      // 2. Update 25 Asks fine-grained signals
      for (int i = 0; i < 25; i++) {
        _askSignals[i].value = payload.updatedAsks[i];
      }

      // 3. Update 25 Bids fine-grained signals
      for (int i = 0; i < 25; i++) {
        _bidSignals[i].value = payload.updatedBids[i];
      }

      // 4. Update overall snapshot signal & multi-asset watchlist live price ticks
      final currentSnap = _snapshotSignal.value;
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

      final updatedSnap = OrderBookSnapshot(
        ticker: activeTicker,
        lastPrice: payload.latestPrice,
        priceChange: payload.priceChange,
        priceChangePct: payload.priceChangePct,
        asks: payload.updatedAsks,
        bids: payload.updatedBids,
        maxVolume: currentSnap.maxVolume,
        totalVolume: currentSnap.totalVolume + payload.batchSize * 100,
        totalTicksProcessed: payload.totalTicksProcessed,
        timestampMs: payload.timestampMs,
      );
      _snapshotSignal.value = updatedSnap;
      _stockSnapshots[activeTicker] = updatedSnap;
    });
  }

  void _updateCachedStockState(TickBatchPayload payload) {
    _totalTicksProcessed = payload.totalTicksProcessed;
    final sym = payload.ticker;
    _updateStockPriceState(sym, payload.latestPrice, payload.priceChangePct);
    final cachedSnap = _stockSnapshots[sym];
    if (cachedSnap != null) {
      _stockSnapshots[sym] = OrderBookSnapshot(
        ticker: sym,
        lastPrice: payload.latestPrice,
        priceChange: payload.priceChange,
        priceChangePct: payload.priceChangePct,
        asks: payload.updatedAsks,
        bids: payload.updatedBids,
        maxVolume: cachedSnap.maxVolume,
        totalVolume: cachedSnap.totalVolume + payload.batchSize * 100,
        totalTicksProcessed: payload.totalTicksProcessed,
        timestampMs: payload.timestampMs,
      );
    }
  }

  // ===========================================================================
  // 8. PRIVATE HELPERS & RESOURCE DISPOSAL
  // ===========================================================================

  void _updateStockPriceState(String symbol, double price, double changePct) {
    if (_latestStockPrices[symbol] != price) {
      _latestStockPrices[symbol] = price;
      _stockPriceSignals[symbol]?.value = price;
    }
    if (_latestStockChanges[symbol] != changePct) {
      _latestStockChanges[symbol] = changePct;
      _stockChangeSignals[symbol]?.value = changePct;
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

        batch(() {
          // 1. Tick Instantaneous Delay (Yellow Bar Chart)
          _eventLoopLagSignal.value = lagMs;

          _eventLoopHistory.add(lagMs);
          if (_eventLoopHistory.length > 40) {
            _eventLoopHistory.removeAt(0);
          }
          _eventLoopHistorySignal.value =
              UnmodifiableListView(_eventLoopHistory);

          // 2. 1-Second Moving Average (Cyan Line Chart)
          _eventLoop1sWindow.add(lagMs);
          _eventLoop1sSum += lagMs;
          if (_eventLoop1sWindow.length > 30) {
            _eventLoop1sSum -= _eventLoop1sWindow.removeAt(0);
          }
          final avg1s = _eventLoop1sWindow.isNotEmpty
              ? _eventLoop1sSum / _eventLoop1sWindow.length
              : lagMs;
          _eventLoopAvg1sSignal.value = avg1s;

          _eventLoopAvg1sHistory.add(avg1s);
          if (_eventLoopAvg1sHistory.length > 40) {
            _eventLoopAvg1sHistory.removeAt(0);
          }
          _eventLoopAvg1sHistorySignal.value =
              UnmodifiableListView(_eventLoopAvg1sHistory);

          // 3. 5-Second Moving Average (Pink Line Chart)
          _eventLoop5sWindow.add(lagMs);
          _eventLoop5sSum += lagMs;
          if (_eventLoop5sWindow.length > 150) {
            _eventLoop5sSum -= _eventLoop5sWindow.removeAt(0);
          }
          final avg5s = _eventLoop5sWindow.isNotEmpty
              ? _eventLoop5sSum / _eventLoop5sWindow.length
              : lagMs;
          _eventLoopAvg5sSignal.value = avg5s;

          _eventLoopAvg5sHistory.add(avg5s);
          if (_eventLoopAvg5sHistory.length > 40) {
            _eventLoopAvg5sHistory.removeAt(0);
          }
          _eventLoopAvg5sHistorySignal.value =
              UnmodifiableListView(_eventLoopAvg5sHistory);
        });
      });
    });
  }

  void _restartRotationTimer() {
    _rotationTimer?.cancel();
    final intervalMs = currentRotationIntervalMs;
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

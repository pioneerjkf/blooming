import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:coralline_flutter/coralline_flutter.dart';

import 'lag_recorder.dart';
import '../engine/order_book_models.dart';
import '../engine/tick_isolate.dart';

/// Coralline-based Data Pipeline managing a fine-grained reactive state graph
/// for a 50-level real-time NASDAQ order book benchmark application.
///
/// Designed with zero-overhead reactive graph principles for maximum TPS and
/// 60/120fps UI rendering performance.
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
  // 2. PRIVATE STATE CONTROLLERS (CORAL REACTIVE NODES)
  // ===========================================================================

  // 2a. Pipeline & Order Book Controllers
  late final CoralController<OrderBookSnapshot> _snapshotController;
  late final CoralController<List<double>> _priceHistoryController;
  late final List<CoralController<OrderBookRowData>> _askControllers;
  late final List<CoralController<OrderBookRowData>> _bidControllers;
  late final CoralController<List<TradeTick>> _tradeTicksController;

  // 2b. Benchmark Engine & Metrics Controllers
  late final CoralController<int> _targetTpsController;
  late final CoralController<bool> _isSimulatingController;
  late final CoralController<int> _actualTpsController;
  late final CoralController<double> _latencyMsController;
  late final CoralController<double> _eventLoopLagController;
  late final CoralController<List<double>> _eventLoopHistoryController;
  late final CoralController<double> _eventLoopAvg1sController;
  late final CoralController<List<double>> _eventLoopAvg1sHistoryController;
  late final CoralController<double> _eventLoopAvg5sController;
  late final CoralController<List<double>> _eventLoopAvg5sHistoryController;
  late final CoralController<bool> _isScrollAnimationEnabledController;
  late final CoralController<BenchmarkProgress> _benchmarkProgressController;

  // 2c. Watchlist & Selection Controllers
  late final CoralController<int> _selectedStockIndexController;
  late final CoralController<bool> _isAutoRotatingController;
  late final CoralController<int> _rotationIntervalIndexController;
  final Map<String, CoralController<double>> _stockPriceControllers = {};
  final Map<String, CoralController<double>> _stockChangeControllers = {};

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

    // Initialize Order Book Snapshot Controller
    _snapshotController = CoralController<OrderBookSnapshot>(
      initialSnapshot,
      broadcast: true,
    );

    // Initialize Rolling Price History (40 slots)
    _priceHistory = List.generate(40, (i) {
      return initialSnapshot.lastPrice - ((39 - i) * 0.04);
    });
    _stockPriceHistories[initialSnapshot.ticker] = List.from(_priceHistory);
    _priceHistoryController = CoralController<List<double>>(
      _priceHistory,
      broadcast: true,
      distinct: false,
    );

    // Initialize 25 Ask & 25 Bid Fine-Grained Reactive Row Controllers
    _askControllers = List.generate(25, (i) {
      return CoralController<OrderBookRowData>(
        initialSnapshot.asks[i],
        broadcast: true,
      );
    });
    _bidControllers = List.generate(25, (i) {
      return CoralController<OrderBookRowData>(
        initialSnapshot.bids[i],
        broadcast: true,
      );
    });

    // Initialize Benchmark Engine Control & Metrics Controllers
    _targetTpsController = CoralController<int>(100, broadcast: true);
    _isSimulatingController = CoralController<bool>(false, broadcast: true);
    _actualTpsController = CoralController<int>(0, broadcast: true);
    _latencyMsController = CoralController<double>(0.0, broadcast: true);
    _eventLoopLagController = CoralController<double>(0.0, broadcast: true);
    _eventLoopHistoryController = CoralController<List<double>>(
      _eventLoopHistory,
      broadcast: true,
      distinct: false,
    );
    _eventLoopAvg1sController = CoralController<double>(0.0, broadcast: true);
    _eventLoopAvg1sHistoryController = CoralController<List<double>>(
      _eventLoopAvg1sHistory,
      broadcast: true,
      distinct: false,
    );
    _eventLoopAvg5sController = CoralController<double>(0.0, broadcast: true);
    _eventLoopAvg5sHistoryController = CoralController<List<double>>(
      _eventLoopAvg5sHistory,
      broadcast: true,
      distinct: false,
    );
    final initialScrollAnim =
        Platform.environment['BENCH_SCROLL_ANIM'] != 'false';
    _isScrollAnimationEnabledController =
        CoralController<bool>(initialScrollAnim, broadcast: true);

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
    _benchmarkProgressController = CoralController<BenchmarkProgress>(
      BenchmarkProgress(
        currentSet: envSet,
        totalSets: envTotalSets,
        currentBench: envBench,
        totalBenches: envTotalBenches,
        currentRun: envRun,
        totalRuns: envTotalRuns,
      ),
      broadcast: true,
    );

    // Initialize Stock Selection & Auto-Rotation Controllers
    _selectedStockIndexController = CoralController<int>(0, broadcast: true);
    _isAutoRotatingController = CoralController<bool>(false, broadcast: true);
    _rotationIntervalIndexController =
        CoralController<int>(6, broadcast: true); // Default 1000ms

    // Initialize Initial Trade Ticks Sample
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
    _tradeTicksController = CoralController<List<TradeTick>>(
      _tradeTicks,
      broadcast: true,
      distinct: false,
    );

    // Initialize Multi-Asset Watchlist Price Controllers
    for (final stock in stocks) {
      _latestStockPrices[stock.symbol] = stock.basePrice;
      _latestStockChanges[stock.symbol] = stock.priceChangePct;
      _stockPriceControllers[stock.symbol] = CoralController<double>(
        stock.basePrice,
        broadcast: true,
      );
      _stockChangeControllers[stock.symbol] = CoralController<double>(
        stock.priceChangePct,
        broadcast: true,
      );
    }
    _latestStockPrices[initialSnapshot.ticker] = initialSnapshot.lastPrice;
    _latestStockChanges[initialSnapshot.ticker] =
        initialSnapshot.priceChangePct;
    _stockPriceControllers[initialSnapshot.ticker]
        ?.set(initialSnapshot.lastPrice);
    _stockChangeControllers[initialSnapshot.ticker]
        ?.set(initialSnapshot.priceChangePct);

    // Initialize Background Isolate Tick Generation Engine
    _isolateEngine = TickIsolateEngine();

    // Start Event Loop Queue Delay Monitoring (33ms heartbeat)
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
  // 5. PUBLIC REACTIVE ACCESSORS (CORALS / GETTERS)
  // ===========================================================================

  // 5a. Order Book CoralProviders
  CoralProvider<OrderBookSnapshot> get snapshotProvider =>
      _snapshotController.provider;
  CoralProvider<List<double>> get priceHistoryProvider =>
      _priceHistoryController.provider;
  List<CoralProvider<OrderBookRowData>> get askProviders =>
      _askControllers.map((c) => c.provider).toList();
  List<CoralProvider<OrderBookRowData>> get bidProviders =>
      _bidControllers.map((c) => c.provider).toList();
  CoralProvider<List<TradeTick>> get tradeTicksProvider =>
      _tradeTicksController.provider;

  // 5b. Benchmark Metrics CoralProviders
  CoralProvider<int> get targetTpsProvider => _targetTpsController.provider;
  CoralProvider<bool> get isSimulatingProvider =>
      _isSimulatingController.provider;
  CoralProvider<bool> get isScrollAnimationEnabledProvider =>
      _isScrollAnimationEnabledController.provider;
  bool get isScrollAnimationEnabled => _isScrollAnimationEnabledController.data;
  void setScrollAnimationEnabled(bool enabled) =>
      _isScrollAnimationEnabledController.set(enabled);
  void toggleScrollAnimation() =>
      setScrollAnimationEnabled(!isScrollAnimationEnabled);
  CoralProvider<BenchmarkProgress> get benchmarkProgressProvider =>
      _benchmarkProgressController.provider;
  BenchmarkProgress get benchmarkProgress => _benchmarkProgressController.data;
  void setBenchmarkProgress({
    required int currentSet,
    required int totalSets,
    required int currentBench,
    required int totalBenches,
    int currentRun = 1,
    int totalRuns = 1,
  }) {
    _benchmarkProgressController.set(BenchmarkProgress(
      currentSet: currentSet,
      totalSets: totalSets,
      currentBench: currentBench,
      totalBenches: totalBenches,
      currentRun: currentRun,
      totalRuns: totalRuns,
    ));
  }

  CoralProvider<int> get actualTpsProvider => _actualTpsController.provider;
  CoralProvider<double> get latencyMsProvider => _latencyMsController.provider;
  CoralProvider<double> get eventLoopLagProvider =>
      _eventLoopLagController.provider;
  CoralProvider<List<double>> get eventLoopHistoryProvider =>
      _eventLoopHistoryController.provider;
  CoralProvider<double> get eventLoopAvg1sProvider =>
      _eventLoopAvg1sController.provider;
  CoralProvider<List<double>> get eventLoopAvg1sHistoryProvider =>
      _eventLoopAvg1sHistoryController.provider;
  CoralProvider<double> get eventLoopAvg5sProvider =>
      _eventLoopAvg5sController.provider;
  CoralProvider<List<double>> get eventLoopAvg5sHistoryProvider =>
      _eventLoopAvg5sHistoryController.provider;

  // 5c. Watchlist & Selection CoralProviders
  CoralProvider<int> get selectedStockIndexProvider =>
      _selectedStockIndexController.provider;
  CoralProvider<bool> get isAutoRotatingProvider =>
      _isAutoRotatingController.provider;
  CoralProvider<int> get rotationIntervalIndexProvider =>
      _rotationIntervalIndexController.provider;

  CoralProvider<double> stockPriceProvider(String symbol) =>
      _stockPriceControllers[symbol]!.provider;

  CoralProvider<double> stockChangeProvider(String symbol) =>
      _stockChangeControllers[symbol]!.provider;

  // 5d. Synchronous Data Value Getters
  OrderBookSnapshot get snapshotValue => _snapshotController.data;
  List<double> get priceHistoryValue => _priceHistoryController.data;

  int get targetTpsValue => _targetTpsController.data;
  bool get isSimulatingValue => _isSimulatingController.data;
  int get actualTpsValue => _actualTpsController.data;
  double get latencyMsValue => _latencyMsController.data;
  double get eventLoopLagValue => _eventLoopLagController.data;

  int get selectedStockIndex => _selectedStockIndexController.data;
  NasdaqStockItem get selectedStock => stocks[selectedStockIndex];
  bool get isAutoRotating => _isAutoRotatingController.data;
  int get rotationIntervalIndex => _rotationIntervalIndexController.data;
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
    _selectedStockIndexController.set(index);
    final stock = stocks[index];

    // 1. Cache current active stock state
    final currentSnap = _snapshotController.data;
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
    _snapshotController.set(newSnapshot);

    final cachedHistory = _stockPriceHistories[stock.symbol];
    if (cachedHistory != null && cachedHistory.isNotEmpty) {
      _priceHistory = List.from(cachedHistory);
    } else {
      _priceHistory =
          List.generate(40, (i) => stock.basePrice - ((39 - i) * 0.04));
      _stockPriceHistories[stock.symbol] = List.from(_priceHistory);
    }
    _priceHistoryController.set(List.unmodifiable(_priceHistory));

    for (int i = 0; i < 25; i++) {
      _askControllers[i].set(newSnapshot.asks[i]);
      _bidControllers[i].set(newSnapshot.bids[i]);
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
    _tradeTicksController.set(List.unmodifiable(_tradeTicks));

    _isolateEngine.setStock(stock.symbol, stock.basePrice);
  }

  /// Selects the next stock in circular order.
  void selectNextStock() {
    final nextIndex = (selectedStockIndex + 1) % stocks.length;
    selectStock(nextIndex);
  }

  /// Starts auto-rotating through the stock list.
  void startAutoRotation() {
    _isAutoRotatingController.set(true);
    _restartRotationTimer();
  }

  /// Stops auto-rotating through the stock list.
  void stopAutoRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
    _isAutoRotatingController.set(false);
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
    _rotationIntervalIndexController.set(clamped);
    if (isAutoRotating) {
      _restartRotationTimer();
    }
  }

  // ===========================================================================
  // 7. ISOLATE SIMULATION ENGINE CONTROLS & BATCH INGESTION
  // ===========================================================================

  /// Starts the Isolate simulation engine.
  Future<void> startSimulation() async {
    if (_isSimulatingController.data) return;

    _isSimulatingController.set(true);
    _lastMeasurementTimestamp = DateTime.now().millisecondsSinceEpoch;
    _totalTicksSinceMeasurement = 0;

    await _isolateEngine.start(
      targetTps: _targetTpsController.data,
      onBatchReceived: updateBatch,
    );
  }

  /// Stops the Isolate simulation engine.
  Future<void> stopSimulation() async {
    await _isolateEngine.stop();
    _isSimulatingController.set(false);
    _actualTpsController.set(0);
  }

  /// Updates target TPS dynamically.
  void setTargetTps(int tps) {
    _targetTpsController.set(tps);
    if (_isSimulatingController.data) {
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

    if (elapsed >= 500) {
      final currentTps =
          ((_totalTicksSinceMeasurement * 1000) / elapsed).round();
      _actualTpsController.set(currentTps);

      final latency = (nowMs - payload.timestampMs).toDouble();
      _latencyMsController.set(latency.clamp(0.0, 999.0));

      _totalTicksSinceMeasurement = 0;
      _lastMeasurementTimestamp = nowMs;
    }

    final activeTicker = _snapshotController.data.ticker;
    if (payload.ticker.isNotEmpty && payload.ticker != activeTicker) {
      // In-flight batch for a previously active stock during rotation:
      // Update background cache for that stock without clobbering active UI
      _updateCachedStockState(payload);
      return;
    }

    // 1. Update rolling price history for real-time mini chart
    _priceHistory.add(payload.latestPrice);
    if (_priceHistory.length > 50) {
      _priceHistory.removeAt(0);
    }
    _priceHistoryController.set(_priceHistory);

    // 1b. Update trade ticks list
    if (payload.recentTrades.isNotEmpty) {
      _tradeTicks.insertAll(0, payload.recentTrades);
      if (_tradeTicks.length > 40) {
        _tradeTicks.removeRange(40, _tradeTicks.length);
      }
      _tradeTicksController.set(_tradeTicks);
    }

    // 2. Update 25 Asks fine-grained corals
    for (int i = 0; i < 25; i++) {
      _askControllers[i].set(payload.updatedAsks[i]);
    }

    // 3. Update 25 Bids fine-grained corals
    for (int i = 0; i < 25; i++) {
      _bidControllers[i].set(payload.updatedBids[i]);
    }

    // 4. Update overall snapshot coral & multi-asset watchlist live price ticks
    final currentSnap = _snapshotController.data;
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
    _snapshotController.set(updatedSnap);
    _stockSnapshots[activeTicker] = updatedSnap;
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
      _stockPriceControllers[symbol]?.set(price);
    }
    if (_latestStockChanges[symbol] != changePct) {
      _latestStockChanges[symbol] = changePct;
      _stockChangeControllers[symbol]?.set(changePct);
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
        _eventLoopLagController.set(lagMs);

        _eventLoopHistory.add(lagMs);
        if (_eventLoopHistory.length > 40) {
          _eventLoopHistory.removeAt(0);
        }
        _eventLoopHistoryController.set(_eventLoopHistory);

        // 2. 1-Second Moving Average (Cyan Line Chart)
        _eventLoop1sWindow.add(lagMs);
        _eventLoop1sSum += lagMs;
        if (_eventLoop1sWindow.length > 30) {
          _eventLoop1sSum -= _eventLoop1sWindow.removeAt(0);
        }
        final avg1s = _eventLoop1sWindow.isNotEmpty
            ? _eventLoop1sSum / _eventLoop1sWindow.length
            : lagMs;
        _eventLoopAvg1sController.set(avg1s);

        _eventLoopAvg1sHistory.add(avg1s);
        if (_eventLoopAvg1sHistory.length > 40) {
          _eventLoopAvg1sHistory.removeAt(0);
        }
        _eventLoopAvg1sHistoryController.set(_eventLoopAvg1sHistory);

        // 3. 5-Second Moving Average (Pink Line Chart)
        _eventLoop5sWindow.add(lagMs);
        _eventLoop5sSum += lagMs;
        if (_eventLoop5sWindow.length > 150) {
          _eventLoop5sSum -= _eventLoop5sWindow.removeAt(0);
        }
        final avg5s = _eventLoop5sWindow.isNotEmpty
            ? _eventLoop5sSum / _eventLoop5sWindow.length
            : lagMs;
        _eventLoopAvg5sController.set(avg5s);

        _eventLoopAvg5sHistory.add(avg5s);
        if (_eventLoopAvg5sHistory.length > 40) {
          _eventLoopAvg5sHistory.removeAt(0);
        }
        _eventLoopAvg5sHistoryController.set(_eventLoopAvg5sHistory);
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

// =============================================================================
// SECTION 7: REACTIVE PIPELINE CONTEXT MIXIN
// =============================================================================

/// Mixin providing zero-boilerplate, lazy-evaluated reactive access to
/// [OrderBookPipeline] streams from ancestor [InheritedCoralProviderWidget].
base mixin OrderBookPipelineAware on CorallineBuildContextAware {
  late final pipelineProvider = coralOf<OrderBookPipeline>().toBroadcaster();

  /// The root pipeline Coral node.
  Coral<OrderBookPipeline> pipelineCoralOf() => pipelineProvider.coral;

  /// Reactive snapshot of the active order book.
  Coral<OrderBookSnapshot> snapshotCoralOf() =>
      pipelineProvider.cascade((p) => p.snapshotProvider.coral);

  /// Reactive price history for sparkline rendering.
  Coral<List<double>> priceHistoryCoralOf() =>
      pipelineProvider.cascade((p) => p.priceHistoryProvider.coral);

  /// Reactive trade tick stream.
  Coral<List<TradeTick>> tradeTicksCoralOf() =>
      pipelineProvider.cascade((p) => p.tradeTicksProvider.coral);

  // Benchmark Metrics
  Coral<int> targetTpsCoralOf() =>
      pipelineProvider.cascade((p) => p.targetTpsProvider.coral);

  Coral<int> actualTpsCoralOf() =>
      pipelineProvider.cascade((p) => p.actualTpsProvider.coral);

  Coral<bool> isSimulatingCoralOf() =>
      pipelineProvider.cascade((p) => p.isSimulatingProvider.coral);

  Coral<bool> isScrollAnimationEnabledCoralOf() =>
      pipelineProvider.cascade((p) => p.isScrollAnimationEnabledProvider.coral);

  Coral<BenchmarkProgress> benchmarkProgressCoralOf() =>
      pipelineProvider.cascade((p) => p.benchmarkProgressProvider.coral);

  Coral<double> latencyMsCoralOf() =>
      pipelineProvider.cascade((p) => p.latencyMsProvider.coral);

  Coral<double> eventLoopLagCoralOf() =>
      pipelineProvider.cascade((p) => p.eventLoopLagProvider.coral);

  Coral<List<double>> eventLoopHistoryCoralOf() =>
      pipelineProvider.cascade((p) => p.eventLoopHistoryProvider.coral);

  Coral<double> eventLoopAvg1sCoralOf() =>
      pipelineProvider.cascade((p) => p.eventLoopAvg1sProvider.coral);

  Coral<List<double>> eventLoopAvg1sHistoryCoralOf() =>
      pipelineProvider.cascade((p) => p.eventLoopAvg1sHistoryProvider.coral);

  Coral<double> eventLoopAvg5sCoralOf() =>
      pipelineProvider.cascade((p) => p.eventLoopAvg5sProvider.coral);

  Coral<List<double>> eventLoopAvg5sHistoryCoralOf() =>
      pipelineProvider.cascade((p) => p.eventLoopAvg5sHistoryProvider.coral);

  // Watchlist & Selection
  Coral<int> selectedStockIndexCoralOf() =>
      pipelineProvider.cascade((p) => p.selectedStockIndexProvider.coral);

  Coral<bool> isAutoRotatingCoralOf() =>
      pipelineProvider.cascade((p) => p.isAutoRotatingProvider.coral);

  Coral<int> rotationIntervalIndexCoralOf() =>
      pipelineProvider.cascade((p) => p.rotationIntervalIndexProvider.coral);

  /// Dynamic stock price Coral by stock symbol.
  Coral<double> stockPriceCoralOf(String symbol) =>
      pipelineProvider.cascade((p) => p.stockPriceProvider(symbol).coral);

  /// Dynamic stock price change % Coral by stock symbol.
  Coral<double> stockChangeCoralOf(String symbol) =>
      pipelineProvider.cascade((p) => p.stockChangeProvider(symbol).coral);

  /// Order book row Coral at index for Ask levels.
  Coral<OrderBookRowData> askRowCoralOf(int index) =>
      pipelineProvider.cascade((p) => p.askProviders[index].coral);

  /// Order book row Coral at index for Bid levels.
  Coral<OrderBookRowData> bidRowCoralOf(int index) =>
      pipelineProvider.cascade((p) => p.bidProviders[index].coral);
}

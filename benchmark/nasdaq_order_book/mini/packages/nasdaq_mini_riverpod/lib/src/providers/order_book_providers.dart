import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/order_book_models.dart';

/// Target TPS Notifier
class TargetTpsNotifier extends Notifier<int> {
  @override
  int build() => 100;

  void set(int value) => state = value;
}

final targetTpsProvider =
    NotifierProvider<TargetTpsNotifier, int>(TargetTpsNotifier.new);

/// Benchmark Progress Notifier
class BenchmarkProgressNotifier extends Notifier<BenchmarkProgress> {
  @override
  BenchmarkProgress build() {
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
    return BenchmarkProgress(
      currentSet: envSet,
      totalSets: envTotalSets,
      currentBench: envBench,
      totalBenches: envTotalBenches,
      currentRun: envRun,
      totalRuns: envTotalRuns,
    );
  }

  void set(BenchmarkProgress value) => state = value;
}

final benchmarkProgressProvider =
    NotifierProvider<BenchmarkProgressNotifier, BenchmarkProgress>(
        BenchmarkProgressNotifier.new);

/// Simulation Active Notifier
class IsSimulatingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final isSimulatingProvider =
    NotifierProvider<IsSimulatingNotifier, bool>(IsSimulatingNotifier.new);

/// Measured Ingest TPS Notifier
class ActualTpsNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;
}

final actualTpsProvider =
    NotifierProvider<ActualTpsNotifier, int>(ActualTpsNotifier.new);

/// Latency Notifier (ms)
class LatencyMsNotifier extends Notifier<double> {
  @override
  double build() => 0.0;

  void set(double value) => state = value;
}

final latencyMsProvider =
    NotifierProvider<LatencyMsNotifier, double>(LatencyMsNotifier.new);

/// Event Loop Lag Notifier (ms)
class EventLoopLagNotifier extends Notifier<double> {
  @override
  double build() => 0.0;

  void set(double value) => state = value;
}

final eventLoopLagProvider =
    NotifierProvider<EventLoopLagNotifier, double>(EventLoopLagNotifier.new);

/// Event Loop History Notifier (40 samples for sparkline)
class EventLoopHistoryNotifier extends Notifier<List<double>> {
  @override
  List<double> build() => List.generate(40, (_) => 0.0);

  void set(List<double> value) => state = value;
}

final eventLoopHistoryProvider =
    NotifierProvider<EventLoopHistoryNotifier, List<double>>(
        EventLoopHistoryNotifier.new);

/// Event Loop 1s Moving Average Notifier (ms)
class EventLoopAvg1sNotifier extends Notifier<double> {
  @override
  double build() => 0.0;

  void set(double value) => state = value;
}

final eventLoopAvg1sProvider = NotifierProvider<EventLoopAvg1sNotifier, double>(
    EventLoopAvg1sNotifier.new);

/// Event Loop 1s Average History Notifier (40 samples)
class EventLoopAvg1sHistoryNotifier extends Notifier<List<double>> {
  @override
  List<double> build() => List.generate(40, (_) => 0.0);

  void set(List<double> value) => state = value;
}

final eventLoopAvg1sHistoryProvider =
    NotifierProvider<EventLoopAvg1sHistoryNotifier, List<double>>(
        EventLoopAvg1sHistoryNotifier.new);

/// Event Loop 5s Moving Average Notifier (ms)
class EventLoopAvg5sNotifier extends Notifier<double> {
  @override
  double build() => 0.0;

  void set(double value) => state = value;
}

final eventLoopAvg5sProvider = NotifierProvider<EventLoopAvg5sNotifier, double>(
    EventLoopAvg5sNotifier.new);

/// Event Loop 5s Average History Notifier (40 samples)
class EventLoopAvg5sHistoryNotifier extends Notifier<List<double>> {
  @override
  List<double> build() => List.generate(40, (_) => 0.0);

  void set(List<double> value) => state = value;
}

final eventLoopAvg5sHistoryProvider =
    NotifierProvider<EventLoopAvg5sHistoryNotifier, List<double>>(
        EventLoopAvg5sHistoryNotifier.new);

/// Selected Stock Index Notifier (0..499)
class SelectedStockIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;
}

final selectedStockIndexProvider =
    NotifierProvider<SelectedStockIndexNotifier, int>(
        SelectedStockIndexNotifier.new);

/// Stock Auto Rotation Interval Index Notifier (0..9)
class StockRotationIntervalIndexNotifier extends Notifier<int> {
  @override
  int build() => 6; // Default 1000ms

  void set(int value) => state = value;
}

final stockRotationIntervalIndexProvider =
    NotifierProvider<StockRotationIntervalIndexNotifier, int>(
        StockRotationIntervalIndexNotifier.new);

/// Stock Auto Rotation State Notifier
class StockAutoRotatingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final stockAutoRotatingProvider =
    NotifierProvider<StockAutoRotatingNotifier, bool>(
        StockAutoRotatingNotifier.new);

/// Rolling Price History Notifier (Sparkline Chart)
class PriceHistoryNotifier extends Notifier<List<double>> {
  @override
  List<double> build() {
    final initialPrice = 135.50;
    return List.generate(40, (i) => initialPrice - ((39 - i) * 0.04));
  }

  void set(List<double> value) => state = value;
}

final priceHistoryProvider =
    NotifierProvider<PriceHistoryNotifier, List<double>>(
        PriceHistoryNotifier.new);

/// Executed Recent Trade Ticks Notifier
class TradeTicksNotifier extends Notifier<List<TradeTick>> {
  @override
  List<TradeTick> build() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return List.generate(10, (i) {
      return TradeTick(
        price: double.parse((135.50 + ((i % 3 - 1) * 0.05)).toStringAsFixed(2)),
        volume: (10 + (i * 3)) * 100,
        isBuy: i % 2 == 0,
        timestampMs: nowMs - (i * 800),
      );
    });
  }

  void set(List<TradeTick> value) => state = value;
}

final tradeTicksProvider =
    NotifierProvider<TradeTicksNotifier, List<TradeTick>>(
        TradeTicksNotifier.new);

/// Full Order Book Snapshot Notifier
class SnapshotNotifier extends Notifier<OrderBookSnapshot> {
  @override
  OrderBookSnapshot build() => OrderBookSnapshot.initial();

  void set(OrderBookSnapshot value) => state = value;
}

final snapshotProvider =
    NotifierProvider<SnapshotNotifier, OrderBookSnapshot>(SnapshotNotifier.new);

/// Fine-Grained Ask Row Notifier (0..24)
class AskRowNotifier extends Notifier<OrderBookRowData> {
  final int index;
  AskRowNotifier(this.index);

  @override
  OrderBookRowData build() {
    final snap = ref.read(snapshotProvider);
    return snap.asks[index];
  }

  void set(OrderBookRowData value) => state = value;
}

final askRowProvider =
    NotifierProvider.family<AskRowNotifier, OrderBookRowData, int>(
        AskRowNotifier.new);

/// Fine-Grained Bid Row Notifier (0..24)
class BidRowNotifier extends Notifier<OrderBookRowData> {
  final int index;
  BidRowNotifier(this.index);

  @override
  OrderBookRowData build() {
    final snap = ref.read(snapshotProvider);
    return snap.bids[index];
  }

  void set(OrderBookRowData value) => state = value;
}

final bidRowProvider =
    NotifierProvider.family<BidRowNotifier, OrderBookRowData, int>(
        BidRowNotifier.new);

/// Stock Price Notifier by Symbol (Family)
class StockPriceNotifier extends Notifier<double> {
  final String symbol;
  StockPriceNotifier(this.symbol);

  @override
  double build() {
    final stock = NasdaqStockItem.defaultStocks.firstWhere(
      (s) => s.symbol == symbol,
      orElse: () => const NasdaqStockItem(
        symbol: 'NVDA',
        name: 'NVIDIA Corp',
        basePrice: 135.50,
        priceChange: 2.45,
        priceChangePct: 1.84,
      ),
    );
    return stock.basePrice;
  }

  void set(double value) => state = value;
}

final stockPriceProvider =
    NotifierProvider.family<StockPriceNotifier, double, String>(
        StockPriceNotifier.new);

/// Stock Price Change % Notifier by Symbol (Family)
class StockChangeNotifier extends Notifier<double> {
  final String symbol;
  StockChangeNotifier(this.symbol);

  @override
  double build() {
    final stock = NasdaqStockItem.defaultStocks.firstWhere(
      (s) => s.symbol == symbol,
      orElse: () => const NasdaqStockItem(
        symbol: 'NVDA',
        name: 'NVIDIA Corp',
        basePrice: 135.50,
        priceChange: 2.45,
        priceChangePct: 1.84,
      ),
    );
    return stock.priceChangePct;
  }

  void set(double value) => state = value;
}

final stockChangeProvider =
    NotifierProvider.family<StockChangeNotifier, double, String>(
        StockChangeNotifier.new);

/// Animation Offset Progress Notifier (0.0 .. 1.0)
class AnimOffsetNotifier extends Notifier<double> {
  @override
  double build() => 0.5;

  void set(double value) => state = value;
}

final animOffsetProvider =
    NotifierProvider<AnimOffsetNotifier, double>(AnimOffsetNotifier.new);

/// Scroll Animation Enabled Notifier
class ScrollAnimationEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    return Platform.environment['BENCH_SCROLL_ANIM'] != 'false';
  }

  void set(bool value) => state = value;
  void toggle() => state = !state;
}

final scrollAnimationEnabledProvider =
    NotifierProvider<ScrollAnimationEnabledNotifier, bool>(
        ScrollAnimationEnabledNotifier.new);

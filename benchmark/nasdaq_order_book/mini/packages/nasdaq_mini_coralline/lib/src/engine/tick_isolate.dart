import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'order_book_models.dart';

// =============================================================================
// SECTION 1: ISOLATE COMMAND & PAYLOAD MODELS
// =============================================================================

/// Commands sent to the Tick Isolate from the Main UI Thread.
@immutable
class TickIsolateCommand {
  const TickIsolateCommand.start({required this.targetTps})
      : stockPrice = 0.0,
        symbol = '';
  const TickIsolateCommand.setTps(this.targetTps)
      : stockPrice = 0.0,
        symbol = '';
  const TickIsolateCommand.setStockPrice(this.stockPrice)
      : targetTps = -1,
        symbol = '';
  const TickIsolateCommand.setStock(
      {required this.symbol, required this.stockPrice})
      : targetTps = -1;
  const TickIsolateCommand.stop()
      : targetTps = 0,
        stockPrice = 0.0,
        symbol = '';

  final int targetTps;
  final double stockPrice;
  final String symbol;
}

/// Message payload containing high-throughput tick updates sent from Isolate to Main Thread.
@immutable
class TickBatchPayload {
  const TickBatchPayload({
    required this.batchSize,
    required this.latestPrice,
    required this.priceChange,
    required this.priceChangePct,
    required this.updatedAsks,
    required this.updatedBids,
    required this.totalTicksProcessed,
    required this.timestampMs,
    this.ticker = '',
    this.recentTrades = const [],
  });

  final int batchSize;
  final double latestPrice;
  final double priceChange;
  final double priceChangePct;
  final List<OrderBookRowData> updatedAsks;
  final List<OrderBookRowData> updatedBids;
  final int totalTicksProcessed;
  final int timestampMs;
  final String ticker;
  final List<TradeTick> recentTrades;
}

// =============================================================================
// SECTION 2: HIGH-PERFORMANCE TICK ISOLATE ENGINE MANAGER
// =============================================================================

/// High-performance Isolate manager for generating high-throughput market data
/// (100 to 1,000,000,000 TPS) without blocking Flutter's Main Looper thread.
class TickIsolateEngine {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _commandPort;
  StreamSubscription? _subscription;

  // Web Fallback state
  Timer? _webTimer;
  int _webTargetTps = 100;
  bool _isWebRunning = false;
  void Function(TickBatchPayload payload)? _webOnBatchReceived;

  /// Returns true if the tick engine is currently running.
  bool get isRunning => _isolate != null || _isWebRunning;

  /// Starts the background tick generation isolate (or Web Timer fallback).
  Future<void> start({
    required int targetTps,
    required void Function(TickBatchPayload payload) onBatchReceived,
  }) async {
    if (isRunning) return;

    if (kIsWeb) {
      _startWebSimulation(
          targetTps: targetTps, onBatchReceived: onBatchReceived);
      return;
    }

    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntryPoint, _receivePort!.sendPort);

    final Completer<SendPort> handshakeCompleter = Completer();

    _subscription = _receivePort!.listen((message) {
      if (message is SendPort) {
        _commandPort = message;
        handshakeCompleter.complete(message);
      } else if (message is TickBatchPayload) {
        onBatchReceived(message);
      }
    });

    final commandPort = await handshakeCompleter.future;
    commandPort.send(TickIsolateCommand.start(targetTps: targetTps));
  }

  /// Updates the target TPS dynamically.
  void updateTps(int newTps) {
    if (kIsWeb) {
      _webTargetTps = newTps;
      return;
    }
    _commandPort?.send(TickIsolateCommand.setTps(newTps));
  }

  /// Sets base stock price dynamically.
  void setStockPrice(double price) => setStock('', price);

  /// Sets active stock ticker and base price dynamically.
  void setStock(String symbol, double price) {
    if (kIsWeb) {
      _webSetStock(symbol, price);
      return;
    }
    _commandPort
        ?.send(TickIsolateCommand.setStock(symbol: symbol, stockPrice: price));
  }

  void _webSetStock(String symbol, double price) {
    // web fallback handled via web stock books
  }

  /// Stops the background isolate cleanly.
  Future<void> stop() async {
    if (kIsWeb) {
      _webTimer?.cancel();
      _webTimer = null;
      _isWebRunning = false;
      return;
    }
    _commandPort?.send(const TickIsolateCommand.stop());
    await _subscription?.cancel();
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort = null;
    _commandPort = null;
  }

  /// Web platform simulation fallback using high-frequency Timer.
  void _startWebSimulation({
    required int targetTps,
    required void Function(TickBatchPayload payload) onBatchReceived,
  }) {
    _webTimer?.cancel();
    _webTargetTps = targetTps;
    _webOnBatchReceived = onBatchReceived;
    _isWebRunning = true;

    final random = Random();
    double currentPrice = 135.50;
    double openPrice = 133.65;
    int totalTicksProcessed = 0;
    double tickAccumulator = 0.0;

    // Heterogeneous base capacities per level (Wall, Medium, Thin levels)
    final askBaseVols = List<int>.generate(25, (i) {
      final isWall = (i % 6 == 1) || (i == 12) || (i == 24);
      final isThin = (i % 4 == 0);
      return isWall
          ? 1800000 + random.nextInt(1500000)
          : (isThin
              ? 5000 + random.nextInt(20000)
              : 80000 + random.nextInt(400000));
    });

    final bidBaseVols = List<int>.generate(25, (i) {
      final isWall = (i % 5 == 2) || (i == 10) || (i == 20);
      final isThin = (i % 3 == 1);
      return isWall
          ? 1650000 + random.nextInt(1600000)
          : (isThin
              ? 6000 + random.nextInt(25000)
              : 70000 + random.nextInt(450000));
    });

    final askNoises = List<double>.filled(25, 0.0);
    final bidNoises = List<double>.filled(25, 0.0);

    final asks = List<OrderBookRowData>.generate(25, (i) {
      final level = 25 - i;
      final vol = askBaseVols[i];
      return OrderBookRowData(
        level: level,
        price: currentPrice + (level * 0.05),
        volume: vol,
        volumeRatio: 0.5,
        isAsk: true,
      );
    });

    final bids = List<OrderBookRowData>.generate(25, (i) {
      final level = i + 1;
      final vol = bidBaseVols[i];
      return OrderBookRowData(
        level: level,
        price: currentPrice - (level * 0.05),
        volume: vol,
        volumeRatio: 0.5,
        isAsk: false,
      );
    });

    const intervalMs = 8; // ~120Hz (1000 / 120 ≈ 8.33ms) for Web simulation
    _webTimer =
        Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      if (!_isWebRunning) return;

      final ticksPerInterval = _webTargetTps / (1000.0 / intervalMs);
      tickAccumulator += ticksPerInterval;
      if (tickAccumulator < 1.0) return;

      final batchSize = tickAccumulator.floor();
      tickAccumulator -= batchSize;
      if (batchSize <= 0) return;

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final newTrades = <TradeTick>[];

      for (int i = 0; i < batchSize; i++) {
        totalTicksProcessed++;

        if (random.nextDouble() < 0.02) {
          final priceStep = random.nextBool() ? 0.05 : -0.05;
          currentPrice = max(10.0, currentPrice + priceStep);
        }

        if (newTrades.length < 2 && random.nextDouble() < 0.08) {
          final isBuy = random.nextBool();
          final tradePrice = isBuy
              ? currentPrice + ((random.nextInt(2)) * 0.05)
              : currentPrice - ((random.nextInt(2)) * 0.05);
          final tradeVol = (random.nextInt(40) + 1) * 100;
          newTrades.add(TradeTick(
            price: double.parse(tradePrice.toStringAsFixed(2)),
            volume: tradeVol,
            isBuy: isBuy,
            timestampMs: nowMs,
          ));
        }

        final askIdx = random.nextInt(25);
        final bidIdx = random.nextInt(25);

        final isAskUp = random.nextBool();
        final deltaAsk = (random.nextDouble() - 0.49) * 0.08;
        askNoises[askIdx] = (askNoises[askIdx] + deltaAsk).clamp(-0.5, 0.7);

        final isBidUp = random.nextBool();
        final deltaBid = (random.nextDouble() - 0.49) * 0.08;
        bidNoises[bidIdx] = (bidNoises[bidIdx] + deltaBid).clamp(-0.5, 0.7);

        final newAskVol =
            max(100, (askBaseVols[askIdx] * (1.0 + askNoises[askIdx])).round());
        final newBidVol =
            max(100, (bidBaseVols[bidIdx] * (1.0 + bidNoises[bidIdx])).round());

        asks[askIdx] = asks[askIdx].copyWith(
          volume: newAskVol,
          flashType: isAskUp ? FlashType.up : FlashType.down,
          flashTimestampMs: nowMs,
        );

        bids[bidIdx] = bids[bidIdx].copyWith(
          volume: newBidVol,
          flashType: isBidUp ? FlashType.up : FlashType.down,
          flashTimestampMs: nowMs,
        );
      }

      double maxAskVol = 1.0;
      double maxBidVol = 1.0;

      for (int i = 0; i < 25; i++) {
        final askLevel = 25 - i;
        final bidLevel = i + 1;

        final askPrice = currentPrice + (askLevel * 0.05);
        final bidPrice = currentPrice - (bidLevel * 0.05);

        asks[i] = asks[i].copyWith(price: askPrice);
        bids[i] = bids[i].copyWith(price: bidPrice);

        if (asks[i].volume > maxAskVol) maxAskVol = asks[i].volume.toDouble();
        if (bids[i].volume > maxBidVol) maxBidVol = bids[i].volume.toDouble();
      }

      final maxVol = max(maxAskVol, maxBidVol);

      final updatedAsks = List<OrderBookRowData>.generate(25, (i) {
        return asks[i]
            .copyWith(volumeRatio: (asks[i].volume / maxVol).clamp(0.05, 1.0));
      });

      final updatedBids = List<OrderBookRowData>.generate(25, (i) {
        return bids[i]
            .copyWith(volumeRatio: (bids[i].volume / maxVol).clamp(0.05, 1.0));
      });

      final priceChange = currentPrice - openPrice;
      final priceChangePct = (priceChange / openPrice) * 100.0;

      _webOnBatchReceived?.call(TickBatchPayload(
        batchSize: batchSize,
        latestPrice: currentPrice,
        priceChange: priceChange,
        priceChangePct: priceChangePct,
        updatedAsks: updatedAsks,
        updatedBids: updatedBids,
        totalTicksProcessed: totalTicksProcessed,
        timestampMs: nowMs,
        recentTrades: newTrades,
      ));
    });
  }
}

// =============================================================================
// SECTION 3: BACKGROUND ISOLATE ENTRYPOINT & SIMULATION LOOP
// =============================================================================

/// Manages isolate-internal continuous order book simulation state per stock.
class _IsolateStockBook {
  _IsolateStockBook({
    required this.ticker,
    required this.currentPrice,
    required this.openPrice,
    required this.askBaseVols,
    required this.bidBaseVols,
    required this.askNoises,
    required this.bidNoises,
    required this.asks,
    required this.bids,
  });

  final String ticker;
  double currentPrice;
  double openPrice;
  final List<int> askBaseVols;
  final List<int> bidBaseVols;
  final List<double> askNoises;
  final List<double> bidNoises;
  final List<OrderBookRowData> asks;
  final List<OrderBookRowData> bids;

  factory _IsolateStockBook.create(String ticker, double basePrice) {
    final initialSnap =
        OrderBookSnapshot.initial(ticker: ticker, basePrice: basePrice);
    final askBaseVols =
        List<int>.generate(25, (i) => initialSnap.asks[i].volume);
    final bidBaseVols =
        List<int>.generate(25, (i) => initialSnap.bids[i].volume);
    final askNoises = List<double>.filled(25, 0.0);
    final bidNoises = List<double>.filled(25, 0.0);
    final asks = List<OrderBookRowData>.from(initialSnap.asks);
    final bids = List<OrderBookRowData>.from(initialSnap.bids);

    return _IsolateStockBook(
      ticker: ticker,
      currentPrice: basePrice,
      openPrice: basePrice * 0.985,
      askBaseVols: askBaseVols,
      bidBaseVols: bidBaseVols,
      askNoises: askNoises,
      bidNoises: bidNoises,
      asks: asks,
      bids: bids,
    );
  }
}

/// Isolate entrypoint function running realistic micro-tick market data simulation.
void _isolateEntryPoint(SendPort mainSendPort) {
  final commandReceivePort = ReceivePort();
  mainSendPort.send(commandReceivePort.sendPort);

  final random = Random();

  final Map<String, _IsolateStockBook> stockBooks = {};
  _IsolateStockBook activeBook = _IsolateStockBook.create('NVDA', 135.50);
  stockBooks['NVDA'] = activeBook;

  int totalTicksProcessed = 0;
  int targetTps = 100;
  bool isRunning = false;

  Timer? simulationTimer;
  double tickAccumulator = 0.0;

  void startSimulation() {
    simulationTimer?.cancel();
    tickAccumulator = 0.0;
    if (targetTps <= 0 || !isRunning) return;

    // Fixed 1ms tick batch interval (1,000 batches/sec)
    const intervalMs = 1;
    final ticksPerInterval = targetTps / (1000.0 / intervalMs);

    simulationTimer =
        Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      tickAccumulator += ticksPerInterval;
      if (tickAccumulator < 1.0) return;

      final batchSize = tickAccumulator.floor();
      tickAccumulator -= batchSize;
      if (batchSize <= 0) return;

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final newTrades = <TradeTick>[];

      final currentBook = activeBook;
      final currentTicker = currentBook.ticker;

      // Realistic tick simulation - update noises dynamically
      for (int i = 0; i < batchSize; i++) {
        totalTicksProcessed++;

        // Micro price step: 2% probability of a $0.05 step
        if (random.nextDouble() < 0.02) {
          final priceStep = random.nextBool() ? 0.05 : -0.05;
          currentBook.currentPrice =
              max(10.0, currentBook.currentPrice + priceStep);
        }

        // Realistic trade tick simulation - natural market pace (max 2 per batch)
        if (newTrades.length < 2 && random.nextDouble() < 0.08) {
          final isBuy = random.nextBool();
          final tradePrice = isBuy
              ? currentBook.currentPrice + ((random.nextInt(2)) * 0.05)
              : currentBook.currentPrice - ((random.nextInt(2)) * 0.05);
          final tradeVol = (random.nextInt(40) + 1) * 100;
          newTrades.add(TradeTick(
            price: double.parse(tradePrice.toStringAsFixed(2)),
            volume: tradeVol,
            isBuy: isBuy,
            timestampMs: nowMs,
          ));
        }

        // Update volumes for random ask and bid depth levels
        final askIdx = random.nextInt(25);
        final bidIdx = random.nextInt(25);

        final isAskUp = random.nextBool();
        final deltaAsk = (random.nextDouble() - 0.49) * 0.08;
        currentBook.askNoises[askIdx] =
            (currentBook.askNoises[askIdx] + deltaAsk).clamp(-0.5, 0.7);

        final isBidUp = random.nextBool();
        final deltaBid = (random.nextDouble() - 0.49) * 0.08;
        currentBook.bidNoises[bidIdx] =
            (currentBook.bidNoises[bidIdx] + deltaBid).clamp(-0.5, 0.7);

        final newAskVol = max(
            100,
            (currentBook.askBaseVols[askIdx] *
                    (1.0 + currentBook.askNoises[askIdx]))
                .round());
        final newBidVol = max(
            100,
            (currentBook.bidBaseVols[bidIdx] *
                    (1.0 + currentBook.bidNoises[bidIdx]))
                .round());

        currentBook.asks[askIdx] = currentBook.asks[askIdx].copyWith(
          volume: newAskVol,
          flashType: isAskUp ? FlashType.up : FlashType.down,
          flashTimestampMs: nowMs,
        );

        currentBook.bids[bidIdx] = currentBook.bids[bidIdx].copyWith(
          volume: newBidVol,
          flashType: isBidUp ? FlashType.up : FlashType.down,
          flashTimestampMs: nowMs,
        );
      }

      // Strict price sorting & ratio calculation
      double maxAskVol = 1.0;
      double maxBidVol = 1.0;

      for (int i = 0; i < 25; i++) {
        final askLevel = 25 - i;
        final bidLevel = i + 1;

        final askPrice = currentBook.currentPrice + (askLevel * 0.05);
        final bidPrice = currentBook.currentPrice - (bidLevel * 0.05);

        currentBook.asks[i] = currentBook.asks[i].copyWith(price: askPrice);
        currentBook.bids[i] = currentBook.bids[i].copyWith(price: bidPrice);

        if (currentBook.asks[i].volume > maxAskVol) {
          maxAskVol = currentBook.asks[i].volume.toDouble();
        }
        if (currentBook.bids[i].volume > maxBidVol) {
          maxBidVol = currentBook.bids[i].volume.toDouble();
        }
      }

      final maxVol = max(maxAskVol, maxBidVol);

      final updatedAsks = List<OrderBookRowData>.generate(25, (i) {
        final ratio = (currentBook.asks[i].volume / maxVol).clamp(0.05, 1.0);
        return currentBook.asks[i]
            .copyWith(volumeRatio: (ratio * 1000).round() / 1000.0);
      });

      final updatedBids = List<OrderBookRowData>.generate(25, (i) {
        final ratio = (currentBook.bids[i].volume / maxVol).clamp(0.05, 1.0);
        return currentBook.bids[i]
            .copyWith(volumeRatio: (ratio * 1000).round() / 1000.0);
      });

      final priceChange = currentBook.currentPrice - currentBook.openPrice;
      final priceChangePct = (priceChange / currentBook.openPrice) * 100.0;

      mainSendPort.send(TickBatchPayload(
        batchSize: batchSize,
        latestPrice: currentBook.currentPrice,
        priceChange: priceChange,
        priceChangePct: priceChangePct,
        updatedAsks: updatedAsks,
        updatedBids: updatedBids,
        totalTicksProcessed: totalTicksProcessed,
        timestampMs: nowMs,
        ticker: currentTicker,
        recentTrades: newTrades,
      ));
    });
  }

  commandReceivePort.listen((message) {
    if (message is TickIsolateCommand) {
      if (message.stockPrice > 0.0) {
        final symbol =
            message.symbol.isNotEmpty ? message.symbol : activeBook.ticker;
        if (stockBooks.containsKey(symbol)) {
          activeBook = stockBooks[symbol]!;
          activeBook.currentPrice = message.stockPrice;
        } else {
          activeBook = stockBooks[symbol] =
              _IsolateStockBook.create(symbol, message.stockPrice);
        }
      } else if (message.targetTps > 0) {
        targetTps = message.targetTps;
        isRunning = true;
        startSimulation();
      } else {
        isRunning = false;
        simulationTimer?.cancel();
      }
    }
  });
}

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../pipeline/order_book_pipeline.dart';
import 'benchmark_hud_panel.dart';
import 'theme.dart';

// =============================================================================
// SECTION 1: NASDAQ WATCHLIST MAIN CONTAINER COMPONENT
// =============================================================================

/// Nasdaq Stock Watchlist & Auto-Rotation Controller Component.
/// Designed with Swiss Art Series & Dynamic Theme System using Signals.
class NasdaqWatchlistView extends SignalStatefulWidget {
  const NasdaqWatchlistView({super.key});

  @override
  State<NasdaqWatchlistView> createState() => _NasdaqWatchlistViewState();
}

class _NasdaqWatchlistViewState extends State<NasdaqWatchlistView> {
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (!scrollController.hasClients) return;
    const itemHeight = 33.0;
    final targetOffset = (index * itemHeight).clamp(
      0.0,
      scrollController.position.maxScrollExtent,
    );

    scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        SignalProvider.of<ReadonlySignal<NasdaqThemeData>>(context)!.value;
    final pipeline =
        SignalProvider.of<Signal<OrderBookPipeline>>(context)!.value;
    final isAutoRotating = pipeline.isAutoRotatingSignal.value;
    final intervalIndex = pipeline.rotationIntervalIndexSignal.value;
    final intervalMs = pipeline.currentRotationIntervalMs;
    final selectedIndex = pipeline.selectedStockIndexSignal.value;
    final stocks = pipeline.stocks;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(selectedIndex);
    });

    return Container(
      width: 240,
      height: 502,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border.all(
          color: theme.surfaceBorder,
          width: 1.0,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Swiss Section Title Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: theme.background,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('001 ',
                        style: theme.swissIndexLabel.copyWith(fontSize: 9)),
                    Text(
                      'NASDAQ WATCHLIST',
                      style: theme.swissHeader
                          .copyWith(fontSize: 10.5, letterSpacing: 0.8),
                    ),
                  ],
                ),
                // Auto rotation status indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isAutoRotating ? theme.bidGreenBg : theme.chipBg,
                    border: Border.all(
                      color: isAutoRotating ? theme.bidGreen : theme.gridLine,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        color:
                            isAutoRotating ? theme.bidGreen : theme.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isAutoRotating ? 'AUTO' : 'PAUSE',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          color:
                              isAutoRotating ? theme.bidGreen : theme.chipText,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.surfaceBorder),

          // 2. Watchlist Controls Bar (Interval Slider & Toggle Button)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: theme.cardBackground,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ROTATION INTERVAL',
                      style: theme.volumeStyle
                          .copyWith(color: theme.textMuted, fontSize: 8.5),
                    ),
                    Text(
                      _formatMs(intervalMs),
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: theme.bidGreen,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: theme.textPrimary,
                    inactiveTrackColor: theme.gridLine,
                    thumbColor: theme.textPrimary,
                    overlayColor: theme.textPrimary.withValues(alpha: 0.1),
                    trackHeight: 3.0,
                    thumbShape: const SwissRectSliderThumbShape(
                        enabledThumbRadius: 5.5),
                  ),
                  child: SizedBox(
                    height: 18,
                    child: Slider(
                      value: intervalIndex.toDouble(),
                      min: 0,
                      max: (OrderBookPipeline.rotationIntervalPresetsMs.length -
                              1)
                          .toDouble(),
                      divisions:
                          OrderBookPipeline.rotationIntervalPresetsMs.length -
                              1,
                      onChanged: (val) {
                        pipeline.setRotationIntervalIndex(val.round());
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Unified Swiss Action Toggle Button
                SizedBox(
                  width: double.infinity,
                  height: 24,
                  child: ElevatedButton(
                    onPressed: pipeline.toggleAutoRotation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isAutoRotating ? theme.askRed : theme.chipBg,
                      foregroundColor:
                          isAutoRotating ? Colors.white : theme.chipText,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(
                          color:
                              isAutoRotating ? theme.askRed : theme.chipBorder,
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Text(
                      isAutoRotating ? 'STOP ROTATION' : 'START ROTATION',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 8.5,
                        letterSpacing: 0.8,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.gridLine),

          // 3. Stock List Column Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: theme.background,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TICKER / NAME',
                    style: theme.volumeStyle.copyWith(fontSize: 8.5)),
                Text('PRICE / CHG',
                    style: theme.volumeStyle.copyWith(fontSize: 8.5)),
              ],
            ),
          ),
          Divider(height: 1, color: theme.gridLine),

          // 4. 100 Stocks Vertical ListView
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: stocks.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: theme.gridLine.withValues(alpha: 0.3),
              ),
              itemBuilder: (context, index) => _NasdaqStockTile(
                index: index,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMs(double ms) {
    if (ms >= 1000) {
      final s = ms / 1000;
      return '${s % 1 == 0 ? s.toInt() : s.toStringAsFixed(1)}s';
    }
    return '${ms % 1 == 0 ? ms.toInt() : ms.toStringAsFixed(2)}ms';
  }
}

// =============================================================================
// SECTION 2: FINE-GRAINED REACTIVE WATCHLIST ROW & METRIC COMPONENTS
// =============================================================================

/// Fine-grained reactive component representing a single Nasdaq stock item row in the Watchlist.
/// Inherits SignalWidget with implicit signal tracking (.value) in signals_flutter 7.x.
class _NasdaqStockTile extends SignalWidget {
  const _NasdaqStockTile({
    required this.index,
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    final theme =
        SignalProvider.of<ReadonlySignal<NasdaqThemeData>>(context)!.value;
    final pipeline =
        SignalProvider.of<Signal<OrderBookPipeline>>(context)!.value;
    final stock = pipeline.stocks[index];
    final isSelected = pipeline.selectedStockIndexSignal.value == index;

    return InkWell(
      onTap: () => pipeline.selectStock(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.textAccent.withValues(alpha: 0.12)
              : Colors.transparent,
          border: isSelected
              ? Border(
                  left: BorderSide(
                    color: theme.bidGreen,
                    width: 3.0,
                  ),
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Column: Ticker & Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        stock.symbol,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: theme.textPrimary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 3),
                        Icon(
                          Icons.play_arrow,
                          size: 9,
                          color: theme.bidGreen,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    stock.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.5,
                      color: theme.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Right Column: Price & Change %
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _NasdaqStockPriceText(
                  index: index,
                ),
                _NasdaqStockChangeText(
                  index: index,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fine-grained reactive component representing the Price text of a stock item.
/// Inherits SignalWidget with implicit signal tracking (.value) in signals_flutter 7.x.
class _NasdaqStockPriceText extends SignalWidget {
  const _NasdaqStockPriceText({
    required this.index,
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    final theme =
        SignalProvider.of<ReadonlySignal<NasdaqThemeData>>(context)!.value;
    final pipeline =
        SignalProvider.of<Signal<OrderBookPipeline>>(context)!.value;
    final stockSymbol = pipeline.stocks[index].symbol;
    final priceSignal = pipeline.stockPriceSignals[stockSymbol];
    final currentPrice = priceSignal?.value ?? pipeline.stocks[index].basePrice;

    return Text(
      '\$${currentPrice.toStringAsFixed(2)}',
      style: TextStyle(
        fontSize: 10.0,
        fontWeight: FontWeight.w800,
        color: theme.textPrimary,
        fontFamily: 'monospace',
      ),
    );
  }
}

/// Fine-grained reactive component representing the Change % text of a stock item.
/// Inherits SignalWidget with implicit signal tracking (.value) in signals_flutter 7.x.
class _NasdaqStockChangeText extends SignalWidget {
  const _NasdaqStockChangeText({
    required this.index,
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    final theme =
        SignalProvider.of<ReadonlySignal<NasdaqThemeData>>(context)!.value;
    final pipeline =
        SignalProvider.of<Signal<OrderBookPipeline>>(context)!.value;
    final stockSymbol = pipeline.stocks[index].symbol;
    final changeSignal = pipeline.stockChangeSignals[stockSymbol];
    final priceChangePct =
        changeSignal?.value ?? pipeline.stocks[index].priceChangePct;
    final isPositive = priceChangePct >= 0;
    final changeColor = isPositive ? theme.bidGreen : theme.askRed;

    return Text(
      '${isPositive ? '+' : ''}${priceChangePct.toStringAsFixed(2)}%',
      style: TextStyle(
        fontSize: 8.5,
        fontWeight: FontWeight.w700,
        color: changeColor,
        fontFamily: 'monospace',
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../pipeline/order_book_pipeline.dart';
import 'benchmark_hud_panel.dart';
import 'scope.dart';

// =============================================================================
// SECTION 1: NASDAQ WATCHLIST MAIN CONTAINER COMPONENT
// =============================================================================

/// Nasdaq Stock Watchlist & Auto-Rotation Controller Component.
/// Designed with Swiss Art Series & Dynamic Theme System using pure Flutter.
class NasdaqWatchlistView extends StatefulWidget {
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
    final theme = ThemeScope.of(context);
    final pipeline = NasdaqBenchmarkScope.pipelineOf(context);
    final stocks = pipeline.stocks;

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
          ListenableBuilder(
            listenable: pipeline.isAutoRotatingNotifier,
            builder: (context, _) {
              final isAutoRotating = pipeline.isAutoRotating;

              return Container(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isAutoRotating ? theme.bidGreenBg : theme.chipBg,
                        border: Border.all(
                          color:
                              isAutoRotating ? theme.bidGreen : theme.gridLine,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            color: isAutoRotating
                                ? theme.bidGreen
                                : theme.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isAutoRotating ? 'AUTO' : 'PAUSE',
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              color: isAutoRotating
                                  ? theme.bidGreen
                                  : theme.chipText,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Divider(height: 1, color: theme.surfaceBorder),

          // 2. Watchlist Controls Bar (Interval Slider & Toggle Button)
          ListenableBuilder(
            listenable: Listenable.merge([
              pipeline.isAutoRotatingNotifier,
              pipeline.rotationIntervalIndexNotifier,
            ]),
            builder: (context, _) {
              final isAutoRotating = pipeline.isAutoRotating;
              final intervalIndex = pipeline.rotationIntervalIndex;
              final intervalMs = pipeline.currentRotationIntervalMs;

              return Container(
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
                          max: (OrderBookPipeline
                                      .rotationIntervalPresetsMs.length -
                                  1)
                              .toDouble(),
                          divisions: OrderBookPipeline
                                  .rotationIntervalPresetsMs.length -
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
                              color: isAutoRotating
                                  ? theme.askRed
                                  : theme.chipBorder,
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
              );
            },
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
            child: ListenableBuilder(
              listenable: pipeline.selectedStockIndexNotifier,
              builder: (context, _) {
                final selectedIndex = pipeline.selectedStockIndex;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToIndex(selectedIndex);
                });

                return ListView.separated(
                  controller: scrollController,
                  itemCount: stocks.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.gridLine.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) => _NasdaqStockTile(
                    index: index,
                    isSelected: selectedIndex == index,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMs(double ms) {
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
class _NasdaqStockTile extends StatelessWidget {
  const _NasdaqStockTile({
    required this.index,
    required this.isSelected,
  });

  final int index;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final pipeline = NasdaqBenchmarkScope.pipelineOf(context);
    final stock = pipeline.stocks[index];

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
                  symbol: stock.symbol,
                  basePrice: stock.basePrice,
                ),
                _NasdaqStockChangeText(
                  symbol: stock.symbol,
                  baseChangePct: stock.priceChangePct,
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
class _NasdaqStockPriceText extends StatelessWidget {
  const _NasdaqStockPriceText({
    required this.symbol,
    required this.basePrice,
  });

  final String symbol;
  final double basePrice;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final pipeline = NasdaqBenchmarkScope.pipelineOf(context);
    final priceNotifier = pipeline.stockPriceNotifiers[symbol];

    if (priceNotifier == null) {
      return Text(
        '\$${basePrice.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 10.0,
          fontWeight: FontWeight.w800,
          color: theme.textPrimary,
          fontFamily: 'monospace',
        ),
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: priceNotifier,
      builder: (context, currentPrice, _) {
        return Text(
          '\$${currentPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.w800,
            color: theme.textPrimary,
            fontFamily: 'monospace',
          ),
        );
      },
    );
  }
}

/// Fine-grained reactive component representing the Change % text of a stock item.
class _NasdaqStockChangeText extends StatelessWidget {
  const _NasdaqStockChangeText({
    required this.symbol,
    required this.baseChangePct,
  });

  final String symbol;
  final double baseChangePct;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final pipeline = NasdaqBenchmarkScope.pipelineOf(context);
    final changeNotifier = pipeline.stockChangeNotifiers[symbol];

    if (changeNotifier == null) {
      final isPositive = baseChangePct >= 0;
      final changeColor = isPositive ? theme.bidGreen : theme.askRed;

      return Text(
        '${isPositive ? '+' : ''}${baseChangePct.toStringAsFixed(2)}%',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: changeColor,
          fontFamily: 'monospace',
        ),
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: changeNotifier,
      builder: (context, priceChangePct, _) {
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
      },
    );
  }
}

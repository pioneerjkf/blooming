import 'package:coralline_flutter/coralline_flutter.dart';
import 'package:flutter/material.dart';

import '../engine/order_book_models.dart';
import '../pipeline/order_book_pipeline.dart';
import 'theme.dart';

// =============================================================================
// SECTION 1: SELECTED STOCK HERO TICKER & LIVE METRICS BAR COMPONENT
// =============================================================================

/// 1-Line Selected Stock Ticker & Live Metrics Bar Component.
/// Prominently displays active ticker symbol, company name, live price, price change ($ and %), and volume.
/// Automatically resolves [OrderBookPipeline] from Coralline context tree via [InheritedCoralProviderWidget].
final class SelectedStockHeaderBar extends BuildComponent
    with
        CorallineTerminalIntentAware,
        CorallineBuildContextAware,
        OrderBookPipelineAware {
  SelectedStockHeaderBar();

  late final Coral<OrderBookPipeline> pipelineCoral =
      coralOf<OrderBookPipeline>();
  late final Coral<NasdaqThemeData> themeCoral = coralOf<NasdaqThemeData>();

  late final Coral<int> _selectedStockIndexCoral = selectedStockIndexCoralOf();
  late final Coral<OrderBookSnapshot> _snapshotCoral = snapshotCoralOf();

  @override
  Iterable<CoralNode> manifest() => [
        _selectedStockIndexCoral,
        _snapshotCoral,
        pipelineCoral,
        themeCoral,
      ];

  @override
  Widget build() {
    final pipeline = pipelineCoral.data;
    final theme = themeCoral.data;
    final stock = pipeline.stocks[_selectedStockIndexCoral.data];
    final snapshot = _snapshotCoral.data;
    final isPositive = snapshot.priceChange >= 0;
    final changeColor = isPositive ? theme.bidGreen : theme.askRed;
    final signStr = isPositive ? '+' : '';

    return Container(
      width: 570,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border.all(
          color: theme.surfaceBorder,
          width: 1.0,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Stock Symbol & Full Company Name
          Row(
            children: [
              Text(
                stock.symbol,
                style: TextStyle(
                  color: theme.textAccent,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 14,
                color: theme.gridLine,
              ),
              const SizedBox(width: 8),
              Text(
                stock.name,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),

          // Right: Live Price, Change ($ and %), Volume
          Row(
            children: [
              Text(
                '\$${snapshot.lastPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$signStr${snapshot.priceChange.toStringAsFixed(2)} ($signStr${snapshot.priceChangePct.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color: changeColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'VOL: ${_formatVol(snapshot.totalVolume)}',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatVol(int vol) {
    if (vol >= 1000000) {
      return '${(vol / 1000000).toStringAsFixed(1)}M';
    } else if (vol >= 1000) {
      return '${(vol / 1000).toStringAsFixed(1)}K';
    }
    return vol.toString();
  }
}

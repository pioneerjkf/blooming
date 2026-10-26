import 'package:coralline_flutter/coralline_flutter.dart';
import 'package:flutter/material.dart';

import '../engine/order_book_models.dart';
import '../pipeline/order_book_pipeline.dart';
import 'theme.dart';

// =============================================================================
// SECTION 1: CENTRAL ORDER BOOK SPREAD & LATEST PRICE BAR COMPONENT
// =============================================================================

/// Central Spread / Latest Price bar widget bound to snapshotCoral and themeCoral.
/// Positioned between 25 Asks and 25 Bids in the 50-level order book.
/// Automatically resolves [OrderBookPipeline] from Coralline context tree if snapshotCoral is omitted.
final class OrderBookSpreadBar extends BuildComponent
    with
        CorallineTerminalIntentAware,
        CorallineBuildContextAware,
        OrderBookPipelineAware {
  OrderBookSpreadBar();

  late final Coral<NasdaqThemeData> themeCoral = coralOf<NasdaqThemeData>();

  late final Coral<OrderBookSnapshot> _effectiveSnapshotCoral =
      snapshotCoralOf();

  @override
  Iterable<CoralNode> manifest() => [
        _effectiveSnapshotCoral,
        themeCoral,
      ];

  @override
  Widget build() {
    final theme = themeCoral.data;
    final snapshot = _effectiveSnapshotCoral.data;
    final isPositive = snapshot.priceChange >= 0;
    final changeColor = isPositive ? theme.bidGreen : theme.askRed;
    final changePrefix = isPositive ? '+' : '';

    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: changeColor,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '${snapshot.ticker} ',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '\$${snapshot.lastPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: changeColor,
                size: 18,
              ),
              Text(
                '$changePrefix${snapshot.priceChange.toStringAsFixed(2)} ($changePrefix${snapshot.priceChangePct.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color: changeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

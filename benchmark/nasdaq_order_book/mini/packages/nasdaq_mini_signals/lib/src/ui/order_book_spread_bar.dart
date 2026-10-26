import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../pipeline/order_book_pipeline.dart';
import 'theme.dart';

// =============================================================================
// SECTION 1: CENTRAL ORDER BOOK SPREAD & LATEST PRICE BAR COMPONENT
// =============================================================================

/// Central Spread / Latest Price bar widget bound to snapshotSignal and themeStore using SignalWidget (v7.x).
/// Positioned between 25 Asks and 25 Bids in the 50-level order book.
class OrderBookSpreadBar extends SignalWidget {
  const OrderBookSpreadBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme =
        SignalProvider.of<ReadonlySignal<NasdaqThemeData>>(context)!.value;
    final pipeline =
        SignalProvider.of<Signal<OrderBookPipeline>>(context)!.value;
    final snapshot = pipeline.snapshotSignal.value;
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

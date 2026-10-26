import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/order_book_providers.dart';
import '../providers/theme_providers.dart';

// =============================================================================
// SECTION 1: CENTRAL ORDER BOOK SPREAD & LATEST PRICE BAR COMPONENT
// =============================================================================

/// Central Spread / Latest Price bar widget bound to snapshotProvider and themeDataProvider.
/// Positioned between 25 Asks and 25 Bids in the 50-level order book.
/// Built with Flutter Riverpod [ConsumerWidget].
class OrderBookSpreadBar extends ConsumerWidget {
  const OrderBookSpreadBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeDataProvider);
    final snapshot = ref.watch(snapshotProvider);
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

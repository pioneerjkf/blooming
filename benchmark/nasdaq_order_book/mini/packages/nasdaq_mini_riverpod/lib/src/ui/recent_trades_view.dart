import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/order_book_providers.dart';
import '../providers/theme_providers.dart';

// =============================================================================
// SECTION 1: REAL-TIME EXECUTED RECENT TRADES COMPONENT
// =============================================================================

/// Vertical view displaying real-time executed market trade ticks (`004 RECENT TRADES`).
/// Built with Flutter Riverpod [ConsumerWidget] and Swiss Art design aesthetics.
class RecentTradesView extends ConsumerWidget {
  const RecentTradesView({super.key});

  static final List<Widget> _rowWidgets = List.generate(
    40,
    (i) => _TradeTickTile(index: i),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeDataProvider);
    final trades = ref.watch(tradeTicksProvider);

    return Container(
      width: 230,
      height: 218,
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
          // Swiss Section Title Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: theme.background,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('004 ', style: theme.swissIndexLabel.copyWith(fontSize: 9)),
                    Text(
                      'RECENT TRADES',
                      style: theme.swissHeader.copyWith(fontSize: 11, letterSpacing: 1.0),
                    ),
                  ],
                ),
                Text(
                  'TICKS',
                  style: theme.volumeStyle.copyWith(fontSize: 8.5, letterSpacing: 0.6),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.surfaceBorder),

          // Column Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: theme.cardBackground,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Text('TIME', style: theme.volumeStyle.copyWith(fontSize: 8.5)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'PRICE',
                    textAlign: TextAlign.right,
                    style: theme.volumeStyle.copyWith(fontSize: 8.5),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'SIZE',
                    textAlign: TextAlign.right,
                    style: theme.volumeStyle.copyWith(fontSize: 8.5),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.gridLine),

          // Trade Ticks Vertical Scroll List Viewport
          Expanded(
            child: trades.isEmpty
                ? Center(
                    child: Text(
                      'WAITING FOR TICKS...',
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 8.5,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    itemCount: 40,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: theme.gridLine.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) => _rowWidgets[index],
                  ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION 2: FINE-GRAINED REACTIVE TRADE TICK ROW COMPONENT
// =============================================================================

/// Fine-grained reactive component representing a single trade tick row.
class _TradeTickTile extends ConsumerWidget {
  const _TradeTickTile({
    required this.index,
  });

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeDataProvider);
    final trades = ref.watch(tradeTicksProvider);
    final tick = index < trades.length ? trades[index] : null;

    if (tick == null) {
      return const SizedBox(height: 18);
    }

    final priceColor = tick.isBuy ? theme.askRed : theme.bidGreen;
    final dt = DateTime.fromMillisecondsSinceEpoch(tick.timestampMs);
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 8.5,
                color: theme.textMuted,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              tick.price.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 9.0,
                fontWeight: FontWeight.w800,
                color: priceColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _formatNum(tick.volume),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 8.5,
                color: theme.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNum(int num) {
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

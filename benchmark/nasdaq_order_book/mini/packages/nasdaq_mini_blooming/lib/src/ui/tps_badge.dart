import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

import '../pipeline/order_book_pipeline.dart';
import 'theme.dart';

// =============================================================================
// SECTION 1: HEADER TPS STAMP BADGE COMPONENT (BLOOMING)
// =============================================================================

/// Reactive component displaying real-time processed Ticks Per Second (TPS).
/// Redesigned with Swiss Editorial Light & Dynamic Theme Systems using [BloomWidget].
final class TpsHeaderBadge extends BloomWidget {
  TpsHeaderBadge({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final theme = via.of<NasdaqThemeData>(context);
    final pipeline = via.of<OrderBookPipeline>(context);

    final measuredTps = via(pipeline.actualTpsBloom);
    final displayTps =
        measuredTps > 0 ? measuredTps : via(pipeline.targetTpsBloom);
    final formattedTps = _formatNum(displayTps);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border.all(
          color: theme.textPrimary,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            color: theme.bidGreen,
          ),
          const SizedBox(width: 6),
          Text(
            '$formattedTps TPS LIVE',
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 10.5,
              fontFamily: 'monospace',
              letterSpacing: 0.8,
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

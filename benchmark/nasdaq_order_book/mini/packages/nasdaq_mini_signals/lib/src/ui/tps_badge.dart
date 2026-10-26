import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../pipeline/order_book_pipeline.dart';
import 'theme.dart';

// =============================================================================
// SECTION 1: HEADER TPS STAMP BADGE COMPONENT
// =============================================================================

/// Reactive component displaying real-time processed Ticks Per Second (TPS).
/// Inherits SignalWidget with implicit signal tracking (.value) in signals_flutter 7.x.
class TpsHeaderBadge extends SignalWidget {
  const TpsHeaderBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme =
        SignalProvider.of<ReadonlySignal<NasdaqThemeData>>(context)!.value;
    final pipeline =
        SignalProvider.of<Signal<OrderBookPipeline>>(context)!.value;
    final measuredTps = pipeline.actualTpsSignal.value;
    final targetTps = pipeline.targetTpsSignal.value;
    final displayTps = measuredTps > 0 ? measuredTps : targetTps;
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

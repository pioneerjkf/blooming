import 'package:coralline_flutter/coralline_flutter.dart';
import 'package:flutter/material.dart';

import '../pipeline/order_book_pipeline.dart';
import 'theme.dart';

// =============================================================================
// SECTION 1: HEADER TPS STAMP BADGE COMPONENT
// =============================================================================

/// Reactive component displaying real-time processed Ticks Per Second (TPS).
/// Redesigned with Swiss Editorial Light & Dynamic Theme Systems.
final class TpsHeaderBadge extends BuildComponent
    with
        CorallineTerminalIntentAware,
        CorallineBuildContextAware,
        OrderBookPipelineAware {
  TpsHeaderBadge();

  late final Coral<NasdaqThemeData> themeCoral = coralOf<NasdaqThemeData>();

  late final Coral<int> _effectiveTpsCoral = actualTpsCoralOf();
  late final Coral<int> _effectiveTargetTpsCoral = targetTpsCoralOf();

  @override
  Iterable<CoralNode> manifest() => [
        _effectiveTpsCoral,
        _effectiveTargetTpsCoral,
        themeCoral,
      ];

  @override
  Widget build() {
    final theme = themeCoral.data;
    final measuredTps = _effectiveTpsCoral.data;
    final displayTps =
        measuredTps > 0 ? measuredTps : _effectiveTargetTpsCoral.data;
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

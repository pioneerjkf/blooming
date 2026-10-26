import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/order_book_providers.dart';
import '../providers/theme_providers.dart';

// =============================================================================
// SECTION 1: HEADER TPS STAMP BADGE COMPONENT
// =============================================================================

/// Reactive component displaying real-time processed Ticks Per Second (TPS).
/// Built with Flutter Riverpod [ConsumerWidget] and Swiss Editorial Light & Dynamic Theme Systems.
class TpsHeaderBadge extends ConsumerWidget {
  const TpsHeaderBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeDataProvider);
    final measuredTps = ref.watch(actualTpsProvider);
    final targetTps = ref.watch(targetTpsProvider);
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

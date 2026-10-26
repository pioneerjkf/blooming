import 'package:flutter/material.dart';

import 'scope.dart';

// =============================================================================
// SECTION 1: HEADER TPS STAMP BADGE COMPONENT
// =============================================================================

/// Reactive component displaying real-time processed Ticks Per Second (TPS).
/// Built with pure Flutter [ListenableBuilder] and [ValueNotifier].
class TpsHeaderBadge extends StatelessWidget {
  const TpsHeaderBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final pipeline = NasdaqBenchmarkScope.pipelineOf(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        pipeline.actualTpsNotifier,
        pipeline.targetTpsNotifier,
      ]),
      builder: (context, _) {
        final measuredTps = pipeline.actualTps;
        final targetTps = pipeline.targetTps;
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
      },
    );
  }

  static String _formatNum(int num) {
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

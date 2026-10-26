import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/order_book_providers.dart';
import '../providers/theme_providers.dart';

// =============================================================================
// SECTION 1: HEADER BENCHMARK PROGRESS STAMP BADGE COMPONENT (RIVERPOD)
// =============================================================================

/// Reactive component displaying benchmark execution progress (e.g. SET 3/10 • BENCH 2/5).
/// Built with Flutter Riverpod [ConsumerWidget] and Swiss Editorial Light & Dynamic Theme Systems.
class BenchmarkProgressBadge extends ConsumerWidget {
  const BenchmarkProgressBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeDataProvider);
    final progress = ref.watch(benchmarkProgressProvider);

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
            color: theme.textAccent,
          ),
          const SizedBox(width: 6),
          Text(
            progress.displayText,
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
}

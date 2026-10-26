import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';

import '../pipeline/order_book_pipeline.dart';
import 'theme.dart';

// =============================================================================
// SECTION 1: HEADER BENCHMARK PROGRESS STAMP BADGE COMPONENT (BLOOMING)
// =============================================================================

/// Reactive component displaying benchmark execution progress (e.g. SET 3/10 • BENCH 2/5).
/// Designed with Swiss Editorial Light & Dynamic Theme Systems using [BloomWidget].
final class BenchmarkProgressBadge extends BloomWidget {
  BenchmarkProgressBadge({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final theme = via.of<NasdaqThemeData>(context);
    final pipeline = via.of<OrderBookPipeline>(context);
    final progress = via(pipeline.benchmarkProgressBloom);

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

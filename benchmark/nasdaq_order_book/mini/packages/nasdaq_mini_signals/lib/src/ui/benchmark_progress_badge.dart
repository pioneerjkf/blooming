import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../pipeline/order_book_pipeline.dart';
import 'theme.dart';

// =============================================================================
// SECTION 1: HEADER BENCHMARK PROGRESS STAMP BADGE COMPONENT (SIGNALS)
// =============================================================================

/// Reactive component displaying benchmark execution progress (e.g. SET 3/10 • BENCH 2/5).
/// Inherits SignalWidget with implicit signal tracking (.value) in signals_flutter 7.x.
class BenchmarkProgressBadge extends SignalWidget {
  const BenchmarkProgressBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme =
        SignalProvider.of<ReadonlySignal<NasdaqThemeData>>(context)!.value;
    final pipeline =
        SignalProvider.of<Signal<OrderBookPipeline>>(context)!.value;
    final progress = pipeline.benchmarkProgressSignal.value;

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

import 'package:coralline_flutter/coralline_flutter.dart';
import 'package:flutter/material.dart';

import '../engine/order_book_models.dart';
import '../pipeline/order_book_pipeline.dart';
import 'theme.dart';

// =============================================================================
// SECTION 1: HEADER BENCHMARK PROGRESS STAMP BADGE COMPONENT (CORALLINE)
// =============================================================================

/// Reactive component displaying benchmark execution progress (e.g. SET 3/10 • BENCH 2/5).
/// Redesigned with Swiss Editorial Light & Dynamic Theme Systems.
final class BenchmarkProgressBadge extends BuildComponent
    with
        CorallineTerminalIntentAware,
        CorallineBuildContextAware,
        OrderBookPipelineAware {
  BenchmarkProgressBadge();

  late final Coral<NasdaqThemeData> themeCoral = coralOf<NasdaqThemeData>();
  late final Coral<BenchmarkProgress> _progressCoral = benchmarkProgressCoralOf();

  @override
  Iterable<CoralNode> manifest() => [
        _progressCoral,
        themeCoral,
      ];

  @override
  Widget build() {
    final theme = themeCoral.data;
    final progress = _progressCoral.data;

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

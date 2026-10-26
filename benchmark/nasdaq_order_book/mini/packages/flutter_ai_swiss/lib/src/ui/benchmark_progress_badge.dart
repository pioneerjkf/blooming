import 'package:flutter/material.dart';

import 'scope.dart';

// =============================================================================
// SECTION 1: HEADER BENCHMARK PROGRESS STAMP BADGE COMPONENT (FLUTTER)
// =============================================================================

/// Reactive component displaying benchmark execution progress (e.g. SET 3/10 • BENCH 2/5).
/// Built with pure Flutter [ListenableBuilder] and [ValueNotifier].
class BenchmarkProgressBadge extends StatelessWidget {
  const BenchmarkProgressBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final pipeline = NasdaqBenchmarkScope.pipelineOf(context);

    return ListenableBuilder(
      listenable: pipeline.benchmarkProgressNotifier,
      builder: (context, _) {
        final progress = pipeline.benchmarkProgress;

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
      },
    );
  }
}

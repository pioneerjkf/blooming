import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_providers.dart';
import 'benchmark_hud_panel.dart';

// =============================================================================
// SECTION 1: SWISS INTEGRATED INSTRUMENT CONTROL PANEL COMPONENT
// =============================================================================

/// Top Navigation Bar Component incorporating the Theme Auto Rotation Controller & Theme Switcher.
/// Built with Flutter Riverpod [ConsumerWidget] and Swiss Art Series aesthetics (24px height).
class ThemeRotationBar extends ConsumerWidget {
  const ThemeRotationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeDataProvider);
    final isAutoRotating = ref.watch(themeAutoRotatingProvider);
    final intervalIndex = ref.watch(themeRotationIntervalIndexProvider);
    final intervalMs =
        NasdaqThemeStore.rotationIntervalPresetsMs[intervalIndex];

    return Container(
      width: 1060,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.textPrimary, width: 1.2),
          bottom: BorderSide(color: theme.surfaceBorder, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Editorial Title
          Text(
            'THEME ROTATION // SWISS ART SERIES',
            style: TextStyle(
              fontSize: 9.0,
              fontWeight: FontWeight.w800,
              color: theme.textSecondary,
              letterSpacing: 1.0,
              fontFamily: 'monospace',
            ),
          ),

          // Unified Swiss Integrated Instrument Panel (Height 24px)
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: theme.cardBackground,
              border: Border.all(
                color: theme.surfaceBorder,
                width: 1.0,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Current Theme Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  color: Colors.transparent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'THEME:',
                        style: TextStyle(
                          fontSize: 8.0,
                          fontWeight: FontWeight.w800,
                          color: theme.textMuted,
                          fontFamily: 'monospace',
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        theme.mode.label,
                        style: TextStyle(
                          fontSize: 9.0,
                          fontWeight: FontWeight.w900,
                          color: theme.textPrimary,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Hairline Divider
                Container(width: 1.0, color: theme.surfaceBorder),

                // 2. Previous Theme Arrow Button
                InkWell(
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).togglePrevious(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    alignment: Alignment.center,
                    color: theme.chipBg,
                    child: Icon(
                      Icons.chevron_left,
                      size: 14,
                      color: theme.chipText,
                    ),
                  ),
                ),

                // Hairline Divider
                Container(width: 1.0, color: theme.surfaceBorder),

                // 3. Next Theme Arrow Button
                InkWell(
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).toggleNext(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    alignment: Alignment.center,
                    color: theme.chipBg,
                    child: Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: theme.chipText,
                    ),
                  ),
                ),

                // Hairline Divider
                Container(width: 1.0, color: theme.surfaceBorder),

                // 4. Auto Rotation Interval Slider Controls
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Text(
                        _formatMs(intervalMs),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: theme.bidGreen,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 6),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: theme.textPrimary,
                          inactiveTrackColor: theme.gridLine,
                          thumbColor: theme.textPrimary,
                          overlayColor:
                              theme.textPrimary.withValues(alpha: 0.1),
                          trackHeight: 3.0,
                          thumbShape: const SwissRectSliderThumbShape(
                              enabledThumbRadius: 5.5),
                        ),
                        child: SizedBox(
                          width: 120,
                          height: 22,
                          child: Slider(
                            value: intervalIndex.toDouble(),
                            min: 0,
                            max: (NasdaqThemeStore
                                        .rotationIntervalPresetsMs.length -
                                    1)
                                .toDouble(),
                            divisions: NasdaqThemeStore
                                    .rotationIntervalPresetsMs.length -
                                1,
                            onChanged: (val) {
                              ref
                                  .read(themeRotationIntervalIndexProvider
                                      .notifier)
                                  .set(val.round());
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Hairline Divider
                Container(width: 1.0, color: theme.surfaceBorder),

                // 5. Rotation Toggle Action Button
                InkWell(
                  onTap: () =>
                      ref.read(themeAutoRotatingProvider.notifier).toggle(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    color: isAutoRotating ? theme.askRed : theme.chipBg,
                    child: Text(
                      isAutoRotating ? 'STOP ROTATION' : 'START ROTATION',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: isAutoRotating ? Colors.white : theme.chipText,
                        fontFamily: 'monospace',
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMs(double ms) {
    if (ms >= 1000) {
      final s = ms / 1000;
      return '${s % 1 == 0 ? s.toInt() : s.toStringAsFixed(1)}s';
    }
    return '${ms % 1 == 0 ? ms.toInt() : ms.toStringAsFixed(2)}ms';
  }
}

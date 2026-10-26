import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/theme.dart';

export '../ui/theme.dart';

/// Theme Mode Notifier
class ThemeModeNotifier extends Notifier<NasdaqThemeMode> {
  @override
  NasdaqThemeMode build() => NasdaqThemeMode.swissLight;

  void set(NasdaqThemeMode mode) => state = mode;

  void toggleNext() {
    final nextIndex = (state.index + 1) % NasdaqThemeMode.values.length;
    state = NasdaqThemeMode.values[nextIndex];
  }

  void togglePrevious() {
    final prevIndex = (state.index - 1 + NasdaqThemeMode.values.length) %
        NasdaqThemeMode.values.length;
    state = NasdaqThemeMode.values[prevIndex];
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, NasdaqThemeMode>(ThemeModeNotifier.new);

/// Theme Data Provider (Derived from Theme Mode)
final themeDataProvider = Provider<NasdaqThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  return NasdaqThemeData.of(mode);
});

/// Theme Rotation Interval Index Notifier (0..9)
class ThemeRotationIntervalIndexNotifier extends Notifier<int> {
  @override
  int build() => 6; // Default 1000ms (preset index 6)

  void set(int index) {
    final clamped =
        index.clamp(0, NasdaqThemeStore.rotationIntervalPresetsMs.length - 1);
    state = clamped;
    ref.read(themeAutoRotatingProvider.notifier).restartTimerIfActive();
  }
}

final themeRotationIntervalIndexProvider =
    NotifierProvider<ThemeRotationIntervalIndexNotifier, int>(
        ThemeRotationIntervalIndexNotifier.new);

/// Theme Auto-Rotation Notifier
class ThemeAutoRotatingNotifier extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return false;
  }

  void set(bool value) {
    state = value;
    if (value) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void toggle() => set(!state);

  void restartTimerIfActive() {
    if (state) {
      _startTimer();
    }
  }

  void _startTimer() {
    _stopTimer();
    final intervalIndex = ref.read(themeRotationIntervalIndexProvider);
    final intervalMs =
        NasdaqThemeStore.rotationIntervalPresetsMs[intervalIndex];
    _timer = Timer.periodic(
      Duration(microseconds: (intervalMs * 1000).round()),
      (_) {
        ref.read(themeModeProvider.notifier).toggleNext();
      },
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

final themeAutoRotatingProvider =
    NotifierProvider<ThemeAutoRotatingNotifier, bool>(
        ThemeAutoRotatingNotifier.new);

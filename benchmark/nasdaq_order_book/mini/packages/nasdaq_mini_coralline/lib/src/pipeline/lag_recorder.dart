import 'dart:typed_data';

/// Fixed-capacity recorder for event loop lag samples (ms).
///
/// The buffer is allocated once up-front (64K samples = 512KB, ~36 minutes at
/// the 33ms monitor period), so [add] performs no allocation and has no
/// measurable effect on the benchmark. Statistics are computed only on demand
/// by [stats], i.e. after the measurement window has ended.
class LagRecorder {
  static const int capacity = 1 << 16;

  final Float64List _samples = Float64List(capacity);
  int _count = 0;
  int _dropped = 0;
  bool _recording = false;

  /// Clears previous samples and starts recording (call at measurement start).
  void reset() {
    _count = 0;
    _dropped = 0;
    _recording = true;
  }

  /// Stops recording (call at measurement end).
  void stop() => _recording = false;

  /// Records one lag sample. O(1), allocation free.
  void add(double lagMs) {
    if (!_recording) return;
    if (_count >= capacity) {
      _dropped++;
      return;
    }
    _samples[_count++] = lagMs;
  }

  /// Computes summary statistics over the recorded window and stops recording.
  Map<String, Object?> stats() {
    stop();
    if (_count == 0) {
      return {'count': 0, 'dropped': _dropped};
    }
    final sorted = Float64List.sublistView(_samples, 0, _count).toList()..sort();
    double sum = 0;
    for (final v in sorted) {
      sum += v;
    }
    double pct(double p) => sorted[((sorted.length - 1) * p).floor()];
    return {
      'count': _count,
      'dropped': _dropped,
      'mean': sum / _count,
      'median': pct(0.50),
      'p95': pct(0.95),
      'p99': pct(0.99),
      'max': sorted.last,
    };
  }
}

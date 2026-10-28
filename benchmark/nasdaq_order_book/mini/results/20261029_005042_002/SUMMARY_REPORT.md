# NASDAQ Order Book Mini — Multi-Framework Performance Whitepaper

> High-throughput reactive benchmark comparing state management & reactive graph architectures in Flutter/Dart under extreme stream ingest loads (10K to 100K+ TPS).

## Benchmark Execution Environment (100% Real Hardware Ingestion)
- **Operating System**: `macos Version 27.0.1 (Build 26A434)`
- **Dart SDK**: `3.13.5`
- **Scenario Duration**: `30s` per test scenario (10 randomized set(s))
- **Order Book Scroll Animation**: Enabled (Continuous VSync Oscillation)
- **Theme Auto-Rotation**: `Disabled`
- **Watchlist Ticker Auto-Rotation**: `Disabled`
- **Execution Engine**: Flutter Driver Real Window, `--profile` build (GPU & VSync Timelines)
- **Display Refresh Rate & Frame Budget**: `120.0Hz` (8.33ms deadline for Jank evaluation)
- **Event Loop Lag sampling**: every 33ms over the full 30s window of each set (about 909 samples per set), stored in a pre-allocated fixed buffer.
- **Scope**: see *Limitations* at the end of this report before drawing conclusions.

---
### Scenario: Target 1,000 TPS — 10 set(s), shuffled order

Per-set lag statistics are aggregated across sets. **Mean, Median and Trimmed Mean are all shown** (Trimmed Mean drops the single lowest and highest set when sets >= 4); no value is hidden. Rows are sorted by Median (lower is better).

| Framework | Generator Ingest TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag Trimmed Mean | P99 Lag (median of sets) | Max Lag (worst sample) | UI Build | GPU Raster | RSS |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Flutter | 1,000/s | 1,000 Hz | 0.098 ms | 0.046 ms | 0.099 ms | 1.889 ms | 3.862 ms | 2.08 ms | 0.73 ms | 197.4 MB |
| Signals | 1,000/s | 1,000 Hz | 0.104 ms | 0.054 ms | 0.105 ms | 2.159 ms | 3.885 ms | 2.09 ms | 0.70 ms | 198.9 MB |
| Coralline | 1,000/s | 1,000 Hz | 0.110 ms | 0.054 ms | 0.111 ms | 2.224 ms | 3.960 ms | 2.05 ms | 0.83 ms | 203.6 MB |
| Blooming | 1,000/s | 1,000 Hz | 0.104 ms | 0.054 ms | 0.104 ms | 1.898 ms | 3.918 ms | 2.09 ms | 0.68 ms | 196.0 MB |
| Riverpod | 1,000/s | 1,000 Hz | 0.328 ms | 0.265 ms | 0.327 ms | 2.172 ms | 4.098 ms | 1.98 ms | 0.74 ms | 205.9 MB |

#### Individual Set Breakdown (raw, unfiltered)

| Set # | Framework | Generator TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag P99 | Lag Max | Samples | UI Build | GPU Raster | RSS |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Set 1 | Riverpod | 1,000/s | 1,000 Hz | 0.313 ms | 0.071 ms | 2.061 ms | 3.244 ms | 914 | 1.83 ms | 0.71 ms | 210.1 MB |
| Set 1 | Signals | 1,000/s | 1,000 Hz | 0.081 ms | 0.043 ms | 1.295 ms | 2.430 ms | 914 | 1.95 ms | 0.73 ms | 198.8 MB |
| Set 1 | Coralline | 1,000/s | 1,000 Hz | 0.099 ms | 0.037 ms | 1.660 ms | 3.434 ms | 915 | 2.03 ms | 0.80 ms | 202.2 MB |
| Set 1 | Flutter | 1,000/s | 1,000 Hz | 0.102 ms | 0.040 ms | 2.148 ms | 2.898 ms | 915 | 2.11 ms | 0.73 ms | 197.0 MB |
| Set 1 | Blooming | 1,000/s | 1,000 Hz | 0.115 ms | 0.041 ms | 2.202 ms | 3.544 ms | 914 | 2.22 ms | 0.66 ms | 196.1 MB |
| Set 2 | Flutter | 1,000/s | 1,000 Hz | 0.079 ms | 0.037 ms | 1.359 ms | 2.753 ms | 915 | 2.00 ms | 0.71 ms | 194.6 MB |
| Set 2 | Coralline | 1,000/s | 1,000 Hz | 0.121 ms | 0.051 ms | 2.207 ms | 3.570 ms | 915 | 1.84 ms | 0.73 ms | 203.3 MB |
| Set 2 | Riverpod | 1,000/s | 1,000 Hz | 0.320 ms | 0.262 ms | 2.124 ms | 3.497 ms | 914 | 2.16 ms | 0.74 ms | 206.3 MB |
| Set 2 | Blooming | 1,000/s | 1,000 Hz | 0.125 ms | 0.052 ms | 2.261 ms | 3.771 ms | 915 | 2.08 ms | 0.70 ms | 194.6 MB |
| Set 2 | Signals | 1,000/s | 1,000 Hz | 0.110 ms | 0.058 ms | 2.456 ms | 3.885 ms | 915 | 2.05 ms | 0.70 ms | 206.2 MB |
| Set 3 | Coralline | 1,000/s | 1,000 Hz | 0.102 ms | 0.049 ms | 2.174 ms | 3.557 ms | 915 | 2.04 ms | 0.83 ms | 199.3 MB |
| Set 3 | Flutter | 1,000/s | 1,000 Hz | 0.089 ms | 0.037 ms | 1.448 ms | 3.733 ms | 915 | 1.98 ms | 0.62 ms | 201.0 MB |
| Set 3 | Signals | 1,000/s | 1,000 Hz | 0.087 ms | 0.035 ms | 1.436 ms | 3.710 ms | 914 | 2.03 ms | 0.68 ms | 200.7 MB |
| Set 3 | Blooming | 1,000/s | 1,000 Hz | 0.082 ms | 0.035 ms | 1.336 ms | 2.993 ms | 915 | 2.23 ms | 0.69 ms | 196.0 MB |
| Set 3 | Riverpod | 1,000/s | 1,000 Hz | 0.319 ms | 0.251 ms | 2.233 ms | 3.143 ms | 915 | 2.16 ms | 0.74 ms | 211.9 MB |
| Set 4 | Flutter | 1,000/s | 1,000 Hz | 0.098 ms | 0.035 ms | 2.204 ms | 3.625 ms | 915 | 1.92 ms | 0.72 ms | 197.9 MB |
| Set 4 | Coralline | 1,000/s | 1,000 Hz | 0.082 ms | 0.036 ms | 1.507 ms | 2.604 ms | 915 | 2.00 ms | 0.81 ms | 205.5 MB |
| Set 4 | Blooming | 1,000/s | 1,000 Hz | 0.084 ms | 0.041 ms | 1.526 ms | 2.741 ms | 915 | 2.07 ms | 0.70 ms | 197.5 MB |
| Set 4 | Signals | 1,000/s | 1,000 Hz | 0.093 ms | 0.057 ms | 1.572 ms | 2.632 ms | 914 | 1.95 ms | 0.68 ms | 199.2 MB |
| Set 4 | Riverpod | 1,000/s | 1,000 Hz | 0.337 ms | 0.267 ms | 2.198 ms | 3.577 ms | 914 | 1.85 ms | 0.72 ms | 207.9 MB |
| Set 5 | Flutter | 1,000/s | 1,000 Hz | 0.106 ms | 0.049 ms | 2.039 ms | 2.765 ms | 915 | 2.25 ms | 0.75 ms | 198.5 MB |
| Set 5 | Riverpod | 1,000/s | 1,000 Hz | 0.321 ms | 0.266 ms | 2.014 ms | 2.886 ms | 915 | 1.88 ms | 0.74 ms | 202.2 MB |
| Set 5 | Coralline | 1,000/s | 1,000 Hz | 0.118 ms | 0.060 ms | 2.300 ms | 3.960 ms | 914 | 2.09 ms | 0.88 ms | 207.8 MB |
| Set 5 | Signals | 1,000/s | 1,000 Hz | 0.112 ms | 0.052 ms | 2.102 ms | 3.661 ms | 915 | 2.02 ms | 0.71 ms | 198.9 MB |
| Set 5 | Blooming | 1,000/s | 1,000 Hz | 0.104 ms | 0.060 ms | 1.969 ms | 3.848 ms | 914 | 2.19 ms | 0.73 ms | 196.9 MB |
| Set 6 | Coralline | 1,000/s | 1,000 Hz | 0.115 ms | 0.054 ms | 2.232 ms | 3.790 ms | 915 | 2.07 ms | 0.82 ms | 203.3 MB |
| Set 6 | Riverpod | 1,000/s | 1,000 Hz | 0.338 ms | 0.262 ms | 2.265 ms | 3.868 ms | 915 | 2.13 ms | 0.75 ms | 203.3 MB |
| Set 6 | Signals | 1,000/s | 1,000 Hz | 0.115 ms | 0.050 ms | 2.311 ms | 2.969 ms | 915 | 2.17 ms | 0.66 ms | 195.0 MB |
| Set 6 | Blooming | 1,000/s | 1,000 Hz | 0.112 ms | 0.059 ms | 2.110 ms | 3.732 ms | 915 | 2.08 ms | 0.69 ms | 195.6 MB |
| Set 6 | Flutter | 1,000/s | 1,000 Hz | 0.092 ms | 0.052 ms | 1.467 ms | 2.800 ms | 915 | 2.07 ms | 0.77 ms | 196.4 MB |
| Set 7 | Flutter | 1,000/s | 1,000 Hz | 0.104 ms | 0.052 ms | 2.262 ms | 3.862 ms | 915 | 2.23 ms | 0.68 ms | 198.9 MB |
| Set 7 | Signals | 1,000/s | 1,000 Hz | 0.103 ms | 0.054 ms | 2.216 ms | 3.676 ms | 915 | 2.18 ms | 0.73 ms | 198.8 MB |
| Set 7 | Riverpod | 1,000/s | 1,000 Hz | 0.324 ms | 0.266 ms | 1.974 ms | 3.315 ms | 914 | 1.81 ms | 0.75 ms | 201.0 MB |
| Set 7 | Blooming | 1,000/s | 1,000 Hz | 0.099 ms | 0.054 ms | 1.827 ms | 3.710 ms | 914 | 1.70 ms | 0.57 ms | 193.9 MB |
| Set 7 | Coralline | 1,000/s | 1,000 Hz | 0.116 ms | 0.055 ms | 2.376 ms | 3.564 ms | 915 | 2.07 ms | 0.83 ms | 202.3 MB |
| Set 8 | Riverpod | 1,000/s | 1,000 Hz | 0.350 ms | 0.267 ms | 2.367 ms | 4.098 ms | 914 | 1.95 ms | 0.74 ms | 203.4 MB |
| Set 8 | Coralline | 1,000/s | 1,000 Hz | 0.110 ms | 0.055 ms | 2.217 ms | 3.491 ms | 915 | 2.08 ms | 0.90 ms | 208.5 MB |
| Set 8 | Blooming | 1,000/s | 1,000 Hz | 0.092 ms | 0.059 ms | 1.452 ms | 3.525 ms | 914 | 2.27 ms | 0.66 ms | 197.8 MB |
| Set 8 | Signals | 1,000/s | 1,000 Hz | 0.117 ms | 0.054 ms | 2.247 ms | 3.609 ms | 915 | 1.97 ms | 0.71 ms | 200.3 MB |
| Set 8 | Flutter | 1,000/s | 1,000 Hz | 0.101 ms | 0.044 ms | 2.087 ms | 3.855 ms | 915 | 2.12 ms | 0.78 ms | 197.2 MB |
| Set 9 | Signals | 1,000/s | 1,000 Hz | 0.117 ms | 0.059 ms | 2.321 ms | 3.699 ms | 914 | 2.28 ms | 0.69 ms | 196.3 MB |
| Set 9 | Coralline | 1,000/s | 1,000 Hz | 0.130 ms | 0.057 ms | 2.258 ms | 3.850 ms | 915 | 2.15 ms | 0.82 ms | 199.9 MB |
| Set 9 | Riverpod | 1,000/s | 1,000 Hz | 0.334 ms | 0.268 ms | 2.147 ms | 3.436 ms | 914 | 1.90 ms | 0.74 ms | 205.8 MB |
| Set 9 | Blooming | 1,000/s | 1,000 Hz | 0.127 ms | 0.056 ms | 2.444 ms | 3.918 ms | 914 | 1.94 ms | 0.61 ms | 196.7 MB |
| Set 9 | Flutter | 1,000/s | 1,000 Hz | 0.112 ms | 0.056 ms | 1.738 ms | 3.489 ms | 914 | 2.22 ms | 0.81 ms | 197.6 MB |
| Set 10 | Riverpod | 1,000/s | 1,000 Hz | 0.323 ms | 0.263 ms | 2.199 ms | 3.709 ms | 914 | 2.10 ms | 0.79 ms | 207.2 MB |
| Set 10 | Coralline | 1,000/s | 1,000 Hz | 0.110 ms | 0.057 ms | 2.238 ms | 3.583 ms | 914 | 2.14 ms | 0.84 ms | 204.2 MB |
| Set 10 | Flutter | 1,000/s | 1,000 Hz | 0.100 ms | 0.051 ms | 1.648 ms | 3.427 ms | 915 | 1.94 ms | 0.72 ms | 195.3 MB |
| Set 10 | Blooming | 1,000/s | 1,000 Hz | 0.100 ms | 0.055 ms | 1.738 ms | 2.977 ms | 915 | 2.08 ms | 0.74 ms | 195.1 MB |
| Set 10 | Signals | 1,000/s | 1,000 Hz | 0.103 ms | 0.058 ms | 1.655 ms | 3.490 ms | 915 | 2.30 ms | 0.72 ms | 194.5 MB |

---
## Limitations

- **Real Hardware Simulation.** All tick batches are executed 100% in real hardware by the background isolate without artificial step capping or arithmetic tick padding at the configured target rates. Event Loop Lag on the main isolate remains the primary differentiator for UI responsiveness under streaming load.
- **Generator Ingestion Throughput vs. Framework State Update Frequency**:
  - **Generator Ingest TPS (`generator_tps` / `sustained_tps`)**: Measures raw order-book ticks computed per second inside the dedicated background isolate (up to ~14.5M TPS on Apple Silicon under hardware saturation).
  - **Framework Update Rate (`framework_update_rate_hz`)**: The background isolate groups ticks into 1ms batches (`TickBatchPayload`), transmitting ~1,000 batches per second across the isolate port to the main UI thread. Each incoming batch triggers reactive listeners and pipeline updates once. **`sustained_tps` must NOT be interpreted as 14.5 million individual UI widget rebuilds or distinct framework state-tree invalidations per second.**
- **Rendering Metrics.** Measured in profile mode with Flutter Driver on a real desktop GPU window over the full test duration. UI Build Time and GPU Raster Time reflect actual widget rebuild tree overhead and compositing performance under concurrent background isolate load.
- **Event loop lag is a main-isolate responsiveness metric**, not a throughput or correctness metric. Differences of a few hundredths of a millisecond are within run-to-run noise; compare Median and Max together with the raw per-set table.
- **Authorship Disclosure.** Signals and Riverpod are community open-source libraries. Flutter represents pure vanilla Flutter primitives (ValueNotifier & ListenableBuilder) without external dependencies. Blooming and Coralline are experimental frameworks designed by the benchmark author. See [`BENCHMARK_METHODOLOGY.md`](../../BENCHMARK_METHODOLOGY.md) for detailed architecture profiles.
- **Single machine, single OS, profile build.** Results are not portable to other hardware, OS versions or release/AOT builds without re-running.
- **No causal claims.** This report measures; it does not explain why a framework is faster or slower.

---
## 📊 Metric Definitions & Statistical Methodology

- **Generator TPS vs. Framework Update Rate (Hz)**: Clear distinction is maintained between isolate tick production volume (`generator_tps`) and main-isolate reactive dispatch frequency (`framework_update_rate_hz`, batch dispatches/sec).
- **Event Loop Lag**: Measured by injecting `Timer.run()` every 33ms into Dart’s event queue. Measures delay until CPU execution (\Delta t = T_{executed} - T_{scheduled}).
- **Mean / Median / Trimmed Mean**: all three are reported side by side. Trimmed Mean drops the single lowest and highest set when sets >= 4; Median is the robust reference. The statistics are fixed in advance and never applied selectively.
- **Raw Data Transparency**: All individual set records, P95/P99 latencies, and engine timings are fully preserved in `benchmark_matrix.json` and `benchmark_summary.csv`.
- **Full Whitepaper**: See [`BENCHMARK_METHODOLOGY.md`](../../BENCHMARK_METHODOLOGY.md) for full mathematical definitions and source code snippets.

---
*Report generated automatically via pure hardware Flutter Driver real GPU window measurement.*

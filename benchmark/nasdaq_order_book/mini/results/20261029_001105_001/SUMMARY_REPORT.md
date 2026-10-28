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
### Scenario: Target 10,000 TPS — 10 set(s), shuffled order

Per-set lag statistics are aggregated across sets. **Mean, Median and Trimmed Mean are all shown** (Trimmed Mean drops the single lowest and highest set when sets >= 4); no value is hidden. Rows are sorted by Median (lower is better).

| Framework | Generator Ingest TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag Trimmed Mean | P99 Lag (median of sets) | Max Lag (worst sample) | UI Build | GPU Raster | RSS |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Flutter | 10,000/s | 1,000 Hz | 0.142 ms | 0.055 ms | 0.145 ms | 3.337 ms | 4.215 ms | 3.10 ms | 0.63 ms | 199.4 MB |
| Coralline | 10,000/s | 1,000 Hz | 0.163 ms | 0.057 ms | 0.166 ms | 3.454 ms | 4.122 ms | 3.19 ms | 0.71 ms | 207.8 MB |
| Blooming | 10,000/s | 1,000 Hz | 0.156 ms | 0.058 ms | 0.154 ms | 3.382 ms | 4.176 ms | 3.15 ms | 0.62 ms | 199.2 MB |
| Signals | 10,000/s | 1,000 Hz | 0.148 ms | 0.059 ms | 0.149 ms | 3.380 ms | 4.136 ms | 3.15 ms | 0.61 ms | 198.7 MB |
| Riverpod | 10,000/s | 1,000 Hz | 0.417 ms | 0.277 ms | 0.419 ms | 3.228 ms | 4.308 ms | 2.98 ms | 0.68 ms | 211.4 MB |

#### Individual Set Breakdown (raw, unfiltered)

| Set # | Framework | Generator TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag P99 | Lag Max | Samples | UI Build | GPU Raster | RSS |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Set 1 | Flutter | 10,000/s | 1,000 Hz | 0.090 ms | 0.051 ms | 0.306 ms | 3.660 ms | 914 | 2.79 ms | 0.71 ms | 206.2 MB |
| Set 1 | Blooming | 10,000/s | 1,000 Hz | 0.137 ms | 0.053 ms | 3.233 ms | 4.176 ms | 914 | 3.13 ms | 0.58 ms | 203.0 MB |
| Set 1 | Coralline | 10,000/s | 1,000 Hz | 0.093 ms | 0.055 ms | 0.258 ms | 3.688 ms | 914 | 3.29 ms | 0.71 ms | 211.2 MB |
| Set 1 | Riverpod | 10,000/s | 1,000 Hz | 0.379 ms | 0.260 ms | 3.198 ms | 3.999 ms | 914 | 2.87 ms | 0.66 ms | 210.6 MB |
| Set 1 | Signals | 10,000/s | 1,000 Hz | 0.151 ms | 0.056 ms | 3.309 ms | 3.482 ms | 914 | 3.24 ms | 0.56 ms | 201.5 MB |
| Set 2 | Riverpod | 10,000/s | 1,000 Hz | 0.391 ms | 0.268 ms | 2.980 ms | 4.254 ms | 914 | 2.71 ms | 0.66 ms | 211.6 MB |
| Set 2 | Flutter | 10,000/s | 1,000 Hz | 0.132 ms | 0.054 ms | 3.305 ms | 3.511 ms | 914 | 3.16 ms | 0.59 ms | 197.2 MB |
| Set 2 | Blooming | 10,000/s | 1,000 Hz | 0.152 ms | 0.057 ms | 3.373 ms | 3.649 ms | 914 | 3.43 ms | 0.71 ms | 199.6 MB |
| Set 2 | Signals | 10,000/s | 1,000 Hz | 0.143 ms | 0.058 ms | 3.368 ms | 4.050 ms | 914 | 3.32 ms | 0.58 ms | 201.0 MB |
| Set 2 | Coralline | 10,000/s | 1,000 Hz | 0.179 ms | 0.058 ms | 3.471 ms | 3.818 ms | 914 | 2.98 ms | 0.69 ms | 209.5 MB |
| Set 3 | Coralline | 10,001/s | 1,000 Hz | 0.161 ms | 0.058 ms | 3.439 ms | 3.693 ms | 915 | 3.18 ms | 0.71 ms | 208.2 MB |
| Set 3 | Signals | 10,000/s | 1,000 Hz | 0.147 ms | 0.059 ms | 3.392 ms | 3.541 ms | 914 | 3.16 ms | 0.59 ms | 198.4 MB |
| Set 3 | Blooming | 10,000/s | 1,000 Hz | 0.152 ms | 0.058 ms | 3.390 ms | 3.608 ms | 914 | 3.02 ms | 0.59 ms | 201.3 MB |
| Set 3 | Riverpod | 10,000/s | 1,000 Hz | 0.399 ms | 0.275 ms | 3.152 ms | 4.282 ms | 914 | 3.10 ms | 0.73 ms | 206.5 MB |
| Set 3 | Flutter | 10,000/s | 1,000 Hz | 0.175 ms | 0.056 ms | 3.407 ms | 3.757 ms | 914 | 2.97 ms | 0.58 ms | 208.9 MB |
| Set 4 | Coralline | 9,999/s | 1,000 Hz | 0.157 ms | 0.057 ms | 3.483 ms | 4.122 ms | 914 | 3.14 ms | 0.71 ms | 207.7 MB |
| Set 4 | Riverpod | 9,999/s | 1,000 Hz | 0.417 ms | 0.282 ms | 3.159 ms | 3.994 ms | 914 | 2.92 ms | 0.66 ms | 211.0 MB |
| Set 4 | Blooming | 10,001/s | 1,000 Hz | 0.141 ms | 0.058 ms | 3.286 ms | 3.586 ms | 915 | 3.15 ms | 0.64 ms | 197.5 MB |
| Set 4 | Signals | 10,000/s | 1,000 Hz | 0.155 ms | 0.059 ms | 3.490 ms | 3.624 ms | 914 | 3.02 ms | 0.64 ms | 199.9 MB |
| Set 4 | Flutter | 10,000/s | 1,000 Hz | 0.144 ms | 0.053 ms | 3.351 ms | 3.538 ms | 915 | 3.06 ms | 0.61 ms | 197.9 MB |
| Set 5 | Signals | 10,000/s | 1,000 Hz | 0.136 ms | 0.060 ms | 3.341 ms | 3.593 ms | 914 | 3.20 ms | 0.64 ms | 197.4 MB |
| Set 5 | Blooming | 10,000/s | 1,000 Hz | 0.156 ms | 0.055 ms | 3.381 ms | 3.976 ms | 914 | 3.20 ms | 0.60 ms | 196.9 MB |
| Set 5 | Flutter | 10,000/s | 1,000 Hz | 0.126 ms | 0.053 ms | 3.134 ms | 3.601 ms | 914 | 3.36 ms | 0.69 ms | 198.8 MB |
| Set 5 | Riverpod | 10,000/s | 1,000 Hz | 0.414 ms | 0.275 ms | 3.234 ms | 3.960 ms | 914 | 2.93 ms | 0.70 ms | 208.8 MB |
| Set 5 | Coralline | 10,000/s | 1,000 Hz | 0.157 ms | 0.056 ms | 3.451 ms | 3.842 ms | 914 | 3.10 ms | 0.70 ms | 203.2 MB |
| Set 6 | Flutter | 9,999/s | 1,000 Hz | 0.152 ms | 0.056 ms | 3.322 ms | 4.215 ms | 914 | 3.24 ms | 0.61 ms | 199.3 MB |
| Set 6 | Riverpod | 9,999/s | 1,000 Hz | 0.434 ms | 0.276 ms | 3.424 ms | 4.308 ms | 914 | 2.90 ms | 0.68 ms | 217.3 MB |
| Set 6 | Signals | 10,000/s | 1,000 Hz | 0.161 ms | 0.059 ms | 3.459 ms | 3.915 ms | 914 | 2.99 ms | 0.58 ms | 195.9 MB |
| Set 6 | Blooming | 10,000/s | 1,000 Hz | 0.158 ms | 0.058 ms | 3.384 ms | 3.880 ms | 914 | 3.17 ms | 0.69 ms | 200.0 MB |
| Set 6 | Coralline | 10,000/s | 1,000 Hz | 0.169 ms | 0.058 ms | 3.456 ms | 3.859 ms | 914 | 3.28 ms | 0.69 ms | 208.5 MB |
| Set 7 | Riverpod | 10,000/s | 1,000 Hz | 0.439 ms | 0.281 ms | 3.227 ms | 3.964 ms | 914 | 3.18 ms | 0.67 ms | 212.4 MB |
| Set 7 | Blooming | 9,999/s | 1,000 Hz | 0.154 ms | 0.057 ms | 3.349 ms | 3.622 ms | 914 | 3.30 ms | 0.58 ms | 194.9 MB |
| Set 7 | Coralline | 10,000/s | 1,000 Hz | 0.170 ms | 0.058 ms | 3.476 ms | 3.756 ms | 914 | 3.35 ms | 0.67 ms | 208.0 MB |
| Set 7 | Signals | 10,000/s | 1,000 Hz | 0.128 ms | 0.060 ms | 2.568 ms | 3.714 ms | 914 | 3.07 ms | 0.59 ms | 199.4 MB |
| Set 7 | Flutter | 10,000/s | 1,000 Hz | 0.121 ms | 0.055 ms | 2.622 ms | 3.584 ms | 915 | 3.10 ms | 0.58 ms | 198.0 MB |
| Set 8 | Flutter | 10,000/s | 1,000 Hz | 0.169 ms | 0.055 ms | 3.392 ms | 3.600 ms | 914 | 3.03 ms | 0.71 ms | 197.5 MB |
| Set 8 | Blooming | 10,001/s | 1,000 Hz | 0.190 ms | 0.059 ms | 3.519 ms | 3.655 ms | 914 | 3.06 ms | 0.59 ms | 199.4 MB |
| Set 8 | Signals | 10,000/s | 1,000 Hz | 0.154 ms | 0.058 ms | 3.372 ms | 4.136 ms | 914 | 2.86 ms | 0.63 ms | 195.7 MB |
| Set 8 | Riverpod | 9,999/s | 1,000 Hz | 0.445 ms | 0.278 ms | 3.316 ms | 4.023 ms | 914 | 3.14 ms | 0.67 ms | 214.1 MB |
| Set 8 | Coralline | 10,000/s | 1,000 Hz | 0.178 ms | 0.057 ms | 3.429 ms | 4.078 ms | 914 | 3.16 ms | 0.69 ms | 209.0 MB |
| Set 9 | Blooming | 10,000/s | 1,000 Hz | 0.162 ms | 0.058 ms | 3.395 ms | 3.629 ms | 914 | 2.97 ms | 0.58 ms | 200.1 MB |
| Set 9 | Flutter | 10,000/s | 1,000 Hz | 0.167 ms | 0.056 ms | 3.418 ms | 3.798 ms | 914 | 3.14 ms | 0.57 ms | 195.3 MB |
| Set 9 | Riverpod | 9,999/s | 1,000 Hz | 0.431 ms | 0.283 ms | 3.229 ms | 3.982 ms | 914 | 3.13 ms | 0.67 ms | 214.1 MB |
| Set 9 | Coralline | 10,000/s | 1,000 Hz | 0.213 ms | 0.057 ms | 3.532 ms | 3.841 ms | 914 | 3.16 ms | 0.84 ms | 204.8 MB |
| Set 9 | Signals | 10,000/s | 1,000 Hz | 0.165 ms | 0.060 ms | 3.488 ms | 3.855 ms | 914 | 3.48 ms | 0.66 ms | 196.1 MB |
| Set 10 | Signals | 10,000/s | 1,000 Hz | 0.145 ms | 0.060 ms | 3.387 ms | 3.780 ms | 914 | 3.18 ms | 0.61 ms | 201.6 MB |
| Set 10 | Coralline | 10,000/s | 1,000 Hz | 0.154 ms | 0.057 ms | 3.364 ms | 3.616 ms | 914 | 3.26 ms | 0.74 ms | 208.4 MB |
| Set 10 | Blooming | 10,000/s | 1,000 Hz | 0.157 ms | 0.060 ms | 3.400 ms | 3.674 ms | 914 | 3.02 ms | 0.61 ms | 198.8 MB |
| Set 10 | Flutter | 10,000/s | 1,000 Hz | 0.145 ms | 0.055 ms | 3.364 ms | 3.528 ms | 914 | 3.12 ms | 0.61 ms | 195.0 MB |
| Set 10 | Riverpod | 10,000/s | 1,000 Hz | 0.426 ms | 0.278 ms | 3.279 ms | 3.806 ms | 914 | 2.93 ms | 0.68 ms | 207.3 MB |

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

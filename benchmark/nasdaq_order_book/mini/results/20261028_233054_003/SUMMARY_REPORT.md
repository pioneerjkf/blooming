# NASDAQ Order Book Mini — Multi-Framework Performance Whitepaper

> High-throughput reactive benchmark comparing state management & reactive graph architectures in Flutter/Dart under extreme stream ingest loads (10K to 100K+ TPS).

## Benchmark Execution Environment (100% Real Hardware Ingestion)
- **Operating System**: `macos Version 27.0.1 (Build 26A434)`
- **Dart SDK**: `3.13.5`
- **Scenario Duration**: `30s` per test scenario (10 randomized set(s))
- **Order Book Scroll Animation**: Enabled (Continuous VSync Oscillation)
- **Theme Auto-Rotation**: `Enabled (8.33ms)`
- **Watchlist Ticker Auto-Rotation**: `Enabled (8.33ms)`
- **Execution Engine**: Flutter Driver Real Window, `--profile` build (GPU & VSync Timelines)
- **Display Refresh Rate & Frame Budget**: `120.0Hz` (8.33ms deadline for Jank evaluation)
- **Event Loop Lag sampling**: every 33ms over the full 30s window of each set (about 909 samples per set), stored in a pre-allocated fixed buffer.
- **Scope**: see *Limitations* at the end of this report before drawing conclusions.

---
### Scenario: Target 100,000 TPS — 10 set(s), shuffled order

Per-set lag statistics are aggregated across sets. **Mean, Median and Trimmed Mean are all shown** (Trimmed Mean drops the single lowest and highest set when sets >= 4); no value is hidden. Rows are sorted by Median (lower is better).

| Framework | Generator Ingest TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag Trimmed Mean | P99 Lag (median of sets) | Max Lag (worst sample) | UI Build | GPU Raster | RSS |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Blooming | 99,998/s | 1,000 Hz | 0.162 ms | 0.038 ms | 0.162 ms | 4.922 ms | 6.035 ms | 4.94 ms | 0.62 ms | 217.9 MB |
| Flutter | 99,998/s | 1,000 Hz | 0.174 ms | 0.041 ms | 0.174 ms | 4.909 ms | 6.202 ms | 4.72 ms | 0.57 ms | 215.1 MB |
| Coralline | 100,000/s | 1,000 Hz | 0.168 ms | 0.051 ms | 0.169 ms | 4.902 ms | 6.054 ms | 4.81 ms | 0.69 ms | 222.5 MB |
| Signals | 100,000/s | 1,000 Hz | 0.176 ms | 0.052 ms | 0.176 ms | 4.938 ms | 6.042 ms | 4.88 ms | 0.58 ms | 218.1 MB |
| Riverpod | 99,950/s | 1,000 Hz | 0.351 ms | 0.129 ms | 0.350 ms | 5.277 ms | 7.030 ms | 5.25 ms | 0.75 ms | 224.0 MB |

#### Individual Set Breakdown (raw, unfiltered)

| Set # | Framework | Generator TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag P99 | Lag Max | Samples | UI Build | GPU Raster | RSS |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Set 1 | Signals | 100,003/s | 1,000 Hz | 0.159 ms | 0.053 ms | 4.916 ms | 5.366 ms | 914 | 4.76 ms | 0.58 ms | 219.3 MB |
| Set 1 | Riverpod | 99,977/s | 1,000 Hz | 0.293 ms | 0.131 ms | 5.133 ms | 6.093 ms | 914 | 5.19 ms | 0.76 ms | 230.8 MB |
| Set 1 | Blooming | 99,993/s | 1,000 Hz | 0.166 ms | 0.038 ms | 4.806 ms | 5.105 ms | 914 | 4.70 ms | 0.57 ms | 212.8 MB |
| Set 1 | Coralline | 100,000/s | 1,000 Hz | 0.126 ms | 0.053 ms | 1.104 ms | 5.269 ms | 914 | 4.97 ms | 0.69 ms | 224.1 MB |
| Set 1 | Flutter | 99,997/s | 1,000 Hz | 0.170 ms | 0.044 ms | 4.828 ms | 5.428 ms | 914 | 4.71 ms | 0.57 ms | 217.4 MB |
| Set 2 | Flutter | 99,997/s | 1,000 Hz | 0.175 ms | 0.042 ms | 4.839 ms | 5.823 ms | 914 | 4.65 ms | 0.57 ms | 215.5 MB |
| Set 2 | Riverpod | 99,960/s | 1,000 Hz | 0.337 ms | 0.134 ms | 5.419 ms | 6.269 ms | 914 | 5.72 ms | 0.75 ms | 229.6 MB |
| Set 2 | Signals | 99,997/s | 1,000 Hz | 0.196 ms | 0.053 ms | 4.989 ms | 5.498 ms | 914 | 4.75 ms | 0.58 ms | 219.4 MB |
| Set 2 | Blooming | 100,003/s | 1,000 Hz | 0.148 ms | 0.041 ms | 5.095 ms | 5.986 ms | 914 | 5.36 ms | 0.59 ms | 223.4 MB |
| Set 2 | Coralline | 100,000/s | 1,000 Hz | 0.188 ms | 0.049 ms | 4.914 ms | 5.021 ms | 914 | 4.85 ms | 0.68 ms | 223.4 MB |
| Set 3 | Signals | 100,000/s | 1,000 Hz | 0.161 ms | 0.050 ms | 4.905 ms | 5.807 ms | 914 | 4.75 ms | 0.55 ms | 219.4 MB |
| Set 3 | Flutter | 100,000/s | 1,000 Hz | 0.172 ms | 0.041 ms | 4.956 ms | 5.944 ms | 914 | 4.75 ms | 0.56 ms | 213.6 MB |
| Set 3 | Blooming | 99,997/s | 1,000 Hz | 0.172 ms | 0.038 ms | 4.931 ms | 5.216 ms | 914 | 4.78 ms | 0.82 ms | 213.9 MB |
| Set 3 | Coralline | 99,997/s | 1,000 Hz | 0.183 ms | 0.051 ms | 4.965 ms | 5.135 ms | 914 | 4.78 ms | 0.70 ms | 222.9 MB |
| Set 3 | Riverpod | 99,980/s | 1,000 Hz | 0.349 ms | 0.122 ms | 5.149 ms | 6.067 ms | 914 | 4.90 ms | 0.72 ms | 220.2 MB |
| Set 4 | Coralline | 100,003/s | 1,000 Hz | 0.176 ms | 0.051 ms | 4.889 ms | 5.525 ms | 914 | 4.96 ms | 0.69 ms | 223.4 MB |
| Set 4 | Flutter | 99,993/s | 1,000 Hz | 0.153 ms | 0.041 ms | 5.108 ms | 6.202 ms | 914 | 4.98 ms | 0.57 ms | 218.6 MB |
| Set 4 | Riverpod | 99,927/s | 999 Hz | 0.354 ms | 0.136 ms | 5.402 ms | 7.030 ms | 914 | 5.47 ms | 0.97 ms | 219.9 MB |
| Set 4 | Blooming | 99,997/s | 1,000 Hz | 0.159 ms | 0.037 ms | 4.798 ms | 5.002 ms | 914 | 4.76 ms | 0.57 ms | 221.7 MB |
| Set 4 | Signals | 99,997/s | 1,000 Hz | 0.209 ms | 0.059 ms | 5.302 ms | 5.921 ms | 914 | 5.03 ms | 0.60 ms | 214.5 MB |
| Set 5 | Coralline | 100,000/s | 1,000 Hz | 0.202 ms | 0.052 ms | 4.962 ms | 6.054 ms | 914 | 4.69 ms | 0.67 ms | 222.7 MB |
| Set 5 | Flutter | 100,000/s | 1,000 Hz | 0.202 ms | 0.042 ms | 4.987 ms | 5.656 ms | 914 | 4.72 ms | 0.56 ms | 213.2 MB |
| Set 5 | Blooming | 99,997/s | 1,000 Hz | 0.136 ms | 0.042 ms | 5.059 ms | 5.640 ms | 914 | 5.07 ms | 0.61 ms | 223.7 MB |
| Set 5 | Signals | 100,003/s | 1,000 Hz | 0.145 ms | 0.051 ms | 4.898 ms | 5.478 ms | 914 | 4.89 ms | 0.59 ms | 218.8 MB |
| Set 5 | Riverpod | 99,960/s | 1,000 Hz | 0.366 ms | 0.127 ms | 5.290 ms | 6.115 ms | 914 | 5.07 ms | 0.69 ms | 225.0 MB |
| Set 6 | Riverpod | 99,980/s | 1,000 Hz | 0.354 ms | 0.126 ms | 5.225 ms | 5.701 ms | 914 | 5.01 ms | 0.73 ms | 221.1 MB |
| Set 6 | Signals | 100,007/s | 1,000 Hz | 0.178 ms | 0.058 ms | 5.098 ms | 6.042 ms | 914 | 5.19 ms | 0.60 ms | 217.6 MB |
| Set 6 | Flutter | 99,997/s | 1,000 Hz | 0.201 ms | 0.042 ms | 4.915 ms | 5.807 ms | 914 | 4.73 ms | 0.58 ms | 220.1 MB |
| Set 6 | Blooming | 99,993/s | 1,000 Hz | 0.150 ms | 0.040 ms | 4.991 ms | 5.826 ms | 914 | 4.90 ms | 0.60 ms | 221.3 MB |
| Set 6 | Coralline | 100,000/s | 1,000 Hz | 0.170 ms | 0.050 ms | 4.874 ms | 5.915 ms | 914 | 4.98 ms | 0.70 ms | 226.2 MB |
| Set 7 | Blooming | 100,000/s | 1,000 Hz | 0.172 ms | 0.041 ms | 5.026 ms | 6.035 ms | 914 | 5.10 ms | 0.60 ms | 221.8 MB |
| Set 7 | Coralline | 100,000/s | 1,000 Hz | 0.141 ms | 0.049 ms | 4.889 ms | 5.831 ms | 914 | 4.69 ms | 0.69 ms | 220.5 MB |
| Set 7 | Riverpod | 99,957/s | 1,000 Hz | 0.413 ms | 0.127 ms | 5.263 ms | 5.855 ms | 914 | 4.98 ms | 0.73 ms | 216.9 MB |
| Set 7 | Signals | 100,003/s | 1,000 Hz | 0.167 ms | 0.052 ms | 4.946 ms | 5.911 ms | 914 | 5.11 ms | 0.63 ms | 214.2 MB |
| Set 7 | Flutter | 100,000/s | 1,000 Hz | 0.193 ms | 0.039 ms | 4.859 ms | 5.210 ms | 914 | 4.66 ms | 0.58 ms | 214.4 MB |
| Set 8 | Signals | 99,997/s | 1,000 Hz | 0.188 ms | 0.052 ms | 4.957 ms | 5.548 ms | 914 | 4.66 ms | 0.56 ms | 219.4 MB |
| Set 8 | Riverpod | 99,917/s | 999 Hz | 0.348 ms | 0.130 ms | 5.432 ms | 6.375 ms | 914 | 5.75 ms | 0.72 ms | 236.3 MB |
| Set 8 | Flutter | 100,003/s | 1,000 Hz | 0.151 ms | 0.040 ms | 4.906 ms | 5.687 ms | 914 | 4.70 ms | 0.58 ms | 216.3 MB |
| Set 8 | Blooming | 100,000/s | 1,000 Hz | 0.176 ms | 0.038 ms | 4.893 ms | 5.821 ms | 914 | 4.77 ms | 0.57 ms | 219.5 MB |
| Set 8 | Coralline | 99,997/s | 1,000 Hz | 0.147 ms | 0.051 ms | 4.820 ms | 5.154 ms | 914 | 4.71 ms | 0.67 ms | 220.4 MB |
| Set 9 | Coralline | 100,000/s | 1,000 Hz | 0.187 ms | 0.049 ms | 4.949 ms | 5.339 ms | 914 | 4.71 ms | 0.68 ms | 223.3 MB |
| Set 9 | Flutter | 99,990/s | 1,000 Hz | 0.167 ms | 0.041 ms | 4.911 ms | 5.337 ms | 914 | 4.73 ms | 0.56 ms | 211.2 MB |
| Set 9 | Signals | 100,000/s | 1,000 Hz | 0.186 ms | 0.051 ms | 4.931 ms | 5.721 ms | 914 | 4.79 ms | 0.57 ms | 219.6 MB |
| Set 9 | Riverpod | 99,861/s | 999 Hz | 0.331 ms | 0.129 ms | 5.385 ms | 6.284 ms | 914 | 5.33 ms | 0.75 ms | 222.3 MB |
| Set 9 | Blooming | 99,997/s | 1,000 Hz | 0.190 ms | 0.039 ms | 4.914 ms | 5.195 ms | 914 | 5.17 ms | 0.66 ms | 210.4 MB |
| Set 10 | Blooming | 100,000/s | 1,000 Hz | 0.151 ms | 0.036 ms | 4.900 ms | 6.009 ms | 914 | 4.83 ms | 0.57 ms | 210.3 MB |
| Set 10 | Riverpod | 99,980/s | 1,000 Hz | 0.364 ms | 0.128 ms | 5.129 ms | 5.834 ms | 914 | 5.04 ms | 0.72 ms | 217.8 MB |
| Set 10 | Flutter | 100,000/s | 1,000 Hz | 0.157 ms | 0.040 ms | 4.884 ms | 5.493 ms | 914 | 4.53 ms | 0.56 ms | 210.9 MB |
| Set 10 | Signals | 99,997/s | 1,000 Hz | 0.172 ms | 0.050 ms | 4.928 ms | 5.881 ms | 914 | 4.83 ms | 0.56 ms | 218.6 MB |
| Set 10 | Coralline | 100,000/s | 1,000 Hz | 0.156 ms | 0.050 ms | 4.950 ms | 5.616 ms | 914 | 4.78 ms | 0.70 ms | 218.1 MB |

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

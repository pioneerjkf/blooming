# NASDAQ Order Book Mini — Multi-Framework Performance Whitepaper

> High-throughput reactive benchmark comparing state management & reactive graph architectures in Flutter/Dart under extreme stream ingest loads (10K to 100K+ TPS).

## Benchmark Execution Environment (100% Real Hardware Ingestion)
- **Operating System**: `macos Version 27.0.1 (Build 26A434)`
- **Dart SDK**: `3.13.5`
- **Scenario Duration**: `30s` per test scenario (10 randomized set(s))
- **Order Book Scroll Animation**: Enabled (Continuous VSync Oscillation)
- **Theme Auto-Rotation**: `Disabled`
- **Watchlist Ticker Auto-Rotation**: `Enabled (8.33ms)`
- **Execution Engine**: Flutter Driver Real Window, `--profile` build (GPU & VSync Timelines)
- **Display Refresh Rate & Frame Budget**: `120.0Hz` (8.33ms deadline for Jank evaluation)
- **Event Loop Lag sampling**: every 33ms over the full 30s window of each set (about 909 samples per set), stored in a pre-allocated fixed buffer.
- **Scope**: see *Limitations* at the end of this report before drawing conclusions.

---
### Scenario: Target 1,000,000,000 TPS — 10 set(s), shuffled order

Per-set lag statistics are aggregated across sets. **Mean, Median and Trimmed Mean are all shown** (Trimmed Mean drops the single lowest and highest set when sets >= 4); no value is hidden. Rows are sorted by Median (lower is better).

| Framework | Generator Ingest TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag Trimmed Mean | P99 Lag (median of sets) | Max Lag (worst sample) | UI Build | GPU Raster | RSS |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Signals | 17,165,119/s | 17 Hz | 0.107 ms | 0.019 ms | 0.104 ms | 3.202 ms | 5.210 ms | 3.07 ms | 0.64 ms | 215.9 MB |
| Blooming | 17,468,491/s | 17 Hz | 0.104 ms | 0.019 ms | 0.105 ms | 3.038 ms | 5.470 ms | 2.94 ms | 0.64 ms | 219.6 MB |
| Coralline | 16,454,863/s | 17 Hz | 0.124 ms | 0.019 ms | 0.126 ms | 3.381 ms | 5.388 ms | 3.57 ms | 0.80 ms | 231.4 MB |
| Flutter | 17,509,860/s | 18 Hz | 0.098 ms | 0.019 ms | 0.099 ms | 3.014 ms | 4.608 ms | 2.90 ms | 0.63 ms | 221.4 MB |
| Riverpod | 17,077,905/s | 17 Hz | 0.124 ms | 0.022 ms | 0.126 ms | 3.329 ms | 5.388 ms | 3.32 ms | 0.77 ms | 220.9 MB |

#### Individual Set Breakdown (raw, unfiltered)

| Set # | Framework | Generator TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag P99 | Lag Max | Samples | UI Build | GPU Raster | RSS |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Set 1 | Signals | 17,525,261/s | 18 Hz | 0.071 ms | 0.019 ms | 2.783 ms | 4.461 ms | 914 | 3.11 ms | 0.67 ms | 213.0 MB |
| Set 1 | Blooming | 17,590,936/s | 18 Hz | 0.087 ms | 0.018 ms | 3.026 ms | 4.625 ms | 915 | 3.18 ms | 0.68 ms | 227.8 MB |
| Set 1 | Coralline | 16,666,667/s | 17 Hz | 0.086 ms | 0.019 ms | 3.138 ms | 5.388 ms | 914 | 3.54 ms | 0.79 ms | 233.1 MB |
| Set 1 | Flutter | 17,593,268/s | 18 Hz | 0.063 ms | 0.018 ms | 2.746 ms | 3.291 ms | 914 | 2.99 ms | 0.63 ms | 219.8 MB |
| Set 1 | Riverpod | 16,765,515/s | 17 Hz | 0.088 ms | 0.020 ms | 2.934 ms | 3.732 ms | 914 | 3.54 ms | 0.80 ms | 214.1 MB |
| Set 2 | Blooming | 17,388,712/s | 17 Hz | 0.106 ms | 0.018 ms | 3.055 ms | 3.969 ms | 915 | 2.96 ms | 0.64 ms | 212.8 MB |
| Set 2 | Coralline | 16,361,950/s | 16 Hz | 0.137 ms | 0.019 ms | 3.477 ms | 4.986 ms | 915 | 3.49 ms | 0.78 ms | 229.0 MB |
| Set 2 | Flutter | 17,524,680/s | 18 Hz | 0.115 ms | 0.019 ms | 3.087 ms | 4.608 ms | 914 | 2.98 ms | 0.63 ms | 226.3 MB |
| Set 2 | Signals | 17,229,383/s | 17 Hz | 0.137 ms | 0.020 ms | 3.328 ms | 4.922 ms | 914 | 2.99 ms | 0.65 ms | 213.2 MB |
| Set 2 | Riverpod | 17,393,897/s | 17 Hz | 0.125 ms | 0.022 ms | 3.290 ms | 4.698 ms | 914 | 3.17 ms | 0.75 ms | 225.0 MB |
| Set 3 | Riverpod | 17,162,547/s | 17 Hz | 0.134 ms | 0.021 ms | 3.458 ms | 5.388 ms | 914 | 3.44 ms | 0.75 ms | 220.3 MB |
| Set 3 | Flutter | 17,661,288/s | 18 Hz | 0.085 ms | 0.019 ms | 3.017 ms | 4.037 ms | 914 | 2.90 ms | 0.62 ms | 226.6 MB |
| Set 3 | Coralline | 16,532,485/s | 17 Hz | 0.149 ms | 0.019 ms | 3.464 ms | 4.752 ms | 914 | 3.72 ms | 0.79 ms | 227.1 MB |
| Set 3 | Blooming | 17,661,288/s | 18 Hz | 0.121 ms | 0.019 ms | 3.135 ms | 4.963 ms | 914 | 3.02 ms | 0.62 ms | 225.2 MB |
| Set 3 | Signals | 17,064,281/s | 17 Hz | 0.072 ms | 0.019 ms | 2.906 ms | 3.744 ms | 914 | 3.23 ms | 0.61 ms | 210.3 MB |
| Set 4 | Blooming | 17,661,288/s | 18 Hz | 0.106 ms | 0.019 ms | 3.068 ms | 4.409 ms | 914 | 2.89 ms | 0.60 ms | 225.9 MB |
| Set 4 | Coralline | 16,561,227/s | 17 Hz | 0.131 ms | 0.019 ms | 3.410 ms | 5.258 ms | 915 | 3.66 ms | 0.78 ms | 231.0 MB |
| Set 4 | Riverpod | 16,996,886/s | 17 Hz | 0.108 ms | 0.022 ms | 3.078 ms | 4.836 ms | 914 | 3.33 ms | 0.76 ms | 226.9 MB |
| Set 4 | Signals | 17,226,529/s | 17 Hz | 0.107 ms | 0.019 ms | 3.273 ms | 3.674 ms | 915 | 3.12 ms | 0.68 ms | 219.1 MB |
| Set 4 | Flutter | 17,493,871/s | 17 Hz | 0.101 ms | 0.019 ms | 3.116 ms | 3.434 ms | 914 | 2.96 ms | 0.67 ms | 222.8 MB |
| Set 5 | Signals | 17,095,716/s | 17 Hz | 0.101 ms | 0.019 ms | 3.145 ms | 4.624 ms | 914 | 3.10 ms | 0.65 ms | 216.3 MB |
| Set 5 | Flutter | 17,427,028/s | 17 Hz | 0.100 ms | 0.019 ms | 3.012 ms | 3.948 ms | 914 | 2.77 ms | 0.63 ms | 218.8 MB |
| Set 5 | Coralline | 16,036,048/s | 16 Hz | 0.129 ms | 0.021 ms | 3.351 ms | 4.960 ms | 915 | 3.38 ms | 0.86 ms | 231.5 MB |
| Set 5 | Blooming | 17,160,273/s | 17 Hz | 0.115 ms | 0.019 ms | 3.051 ms | 3.241 ms | 915 | 3.04 ms | 0.64 ms | 218.8 MB |
| Set 5 | Riverpod | 16,963,191/s | 17 Hz | 0.141 ms | 0.022 ms | 3.363 ms | 5.281 ms | 914 | 3.21 ms | 0.77 ms | 223.4 MB |
| Set 6 | Blooming | 17,558,972/s | 18 Hz | 0.093 ms | 0.019 ms | 2.965 ms | 4.316 ms | 914 | 2.88 ms | 0.65 ms | 209.6 MB |
| Set 6 | Coralline | 16,565,068/s | 17 Hz | 0.142 ms | 0.019 ms | 3.505 ms | 4.962 ms | 914 | 3.21 ms | 0.77 ms | 231.7 MB |
| Set 6 | Flutter | 17,490,394/s | 17 Hz | 0.126 ms | 0.019 ms | 3.096 ms | 3.894 ms | 915 | 2.85 ms | 0.63 ms | 226.4 MB |
| Set 6 | Signals | 16,996,322/s | 17 Hz | 0.083 ms | 0.019 ms | 2.988 ms | 4.050 ms | 914 | 3.06 ms | 0.64 ms | 219.6 MB |
| Set 6 | Riverpod | 17,090,620/s | 17 Hz | 0.116 ms | 0.023 ms | 3.295 ms | 3.751 ms | 915 | 3.31 ms | 0.78 ms | 223.8 MB |
| Set 7 | Blooming | 17,460,738/s | 17 Hz | 0.120 ms | 0.019 ms | 3.097 ms | 3.672 ms | 914 | 2.81 ms | 0.64 ms | 227.0 MB |
| Set 7 | Flutter | 17,593,850/s | 18 Hz | 0.107 ms | 0.019 ms | 2.996 ms | 4.037 ms | 914 | 2.87 ms | 0.63 ms | 212.7 MB |
| Set 7 | Coralline | 16,627,472/s | 17 Hz | 0.108 ms | 0.020 ms | 3.270 ms | 5.233 ms | 915 | 3.73 ms | 0.79 ms | 235.3 MB |
| Set 7 | Riverpod | 17,094,583/s | 17 Hz | 0.121 ms | 0.022 ms | 3.155 ms | 4.502 ms | 914 | 3.51 ms | 0.79 ms | 217.6 MB |
| Set 7 | Signals | 17,195,110/s | 17 Hz | 0.123 ms | 0.019 ms | 3.230 ms | 5.210 ms | 914 | 3.15 ms | 0.62 ms | 216.7 MB |
| Set 8 | Coralline | 16,465,677/s | 16 Hz | 0.114 ms | 0.019 ms | 3.342 ms | 4.865 ms | 914 | 3.64 ms | 0.77 ms | 230.6 MB |
| Set 8 | Blooming | 17,359,616/s | 17 Hz | 0.096 ms | 0.019 ms | 2.905 ms | 5.470 ms | 914 | 2.97 ms | 0.63 ms | 215.0 MB |
| Set 8 | Flutter | 17,560,717/s | 18 Hz | 0.118 ms | 0.019 ms | 3.019 ms | 3.183 ms | 914 | 2.94 ms | 0.62 ms | 217.9 MB |
| Set 8 | Signals | 16,995,759/s | 17 Hz | 0.100 ms | 0.019 ms | 3.268 ms | 3.958 ms | 914 | 3.04 ms | 0.64 ms | 213.2 MB |
| Set 8 | Riverpod | 17,162,547/s | 17 Hz | 0.136 ms | 0.023 ms | 3.384 ms | 4.966 ms | 914 | 3.27 ms | 0.75 ms | 220.9 MB |
| Set 9 | Riverpod | 17,159,136/s | 17 Hz | 0.145 ms | 0.022 ms | 3.503 ms | 4.930 ms | 914 | 3.07 ms | 0.76 ms | 221.3 MB |
| Set 9 | Signals | 17,228,812/s | 17 Hz | 0.162 ms | 0.019 ms | 3.271 ms | 4.386 ms | 914 | 3.00 ms | 0.64 ms | 210.9 MB |
| Set 9 | Blooming | 17,388,712/s | 17 Hz | 0.097 ms | 0.019 ms | 3.004 ms | 3.964 ms | 915 | 2.87 ms | 0.66 ms | 219.5 MB |
| Set 9 | Flutter | 17,459,003/s | 17 Hz | 0.080 ms | 0.019 ms | 2.959 ms | 3.152 ms | 914 | 2.88 ms | 0.64 ms | 225.8 MB |
| Set 9 | Coralline | 16,465,677/s | 16 Hz | 0.135 ms | 0.020 ms | 3.438 ms | 5.157 ms | 914 | 3.61 ms | 0.76 ms | 234.5 MB |
| Set 10 | Riverpod | 16,990,130/s | 17 Hz | 0.130 ms | 0.021 ms | 3.406 ms | 4.746 ms | 915 | 3.37 ms | 0.77 ms | 215.7 MB |
| Set 10 | Flutter | 17,294,504/s | 17 Hz | 0.086 ms | 0.019 ms | 2.907 ms | 4.118 ms | 914 | 2.90 ms | 0.64 ms | 216.3 MB |
| Set 10 | Blooming | 17,454,377/s | 17 Hz | 0.104 ms | 0.019 ms | 2.965 ms | 3.853 ms | 915 | 2.78 ms | 0.62 ms | 214.7 MB |
| Set 10 | Coralline | 16,266,357/s | 16 Hz | 0.112 ms | 0.020 ms | 3.260 ms | 5.319 ms | 915 | 3.74 ms | 0.88 ms | 230.6 MB |
| Set 10 | Signals | 17,094,017/s | 17 Hz | 0.111 ms | 0.019 ms | 3.173 ms | 4.271 ms | 914 | 2.93 ms | 0.63 ms | 226.9 MB |

---
## Limitations

- **Real Hardware Simulation & Physical Saturation.** All tick batches are executed 100% in real hardware by the background isolate without artificial step capping or arithmetic tick padding. When target TPS is set to extreme values such as 1B TPS (10억 틱), the isolate naturally saturates the host single-core capacity (~14.5M TPS on Apple Silicon), reflecting genuine maximum physical throughput. Event Loop Lag on the main isolate remains the primary differentiator for UI responsiveness under heavy background streaming.
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

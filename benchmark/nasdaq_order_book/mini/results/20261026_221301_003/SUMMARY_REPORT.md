# NASDAQ Order Book Mini — Multi-Framework Performance Whitepaper

> High-throughput reactive benchmark comparing state management & reactive graph architectures in Flutter/Dart under extreme stream ingest loads (10K to 100K+ TPS).

## Benchmark Execution Environment (100% Real Hardware Ingestion)
- **Operating System**: `macos Version 27.0.1 (Build 26A434)`
- **Dart SDK**: `3.13.5`
- **Scenario Duration**: `30s` per test scenario (10 randomized set(s))
- **Order Book Scroll Animation**: `Disabled (Static Center Viewport)`
- **Execution Engine**: Flutter Driver Real Window, `--profile` build (GPU & VSync Timelines)
- **Event Loop Lag sampling**: every 33ms over the full 30s window of each set (about 909 samples per set), stored in a pre-allocated fixed buffer.
- **Scope**: see *Limitations* at the end of this report before drawing conclusions.

---
### Scenario: Target 1,000,000,000 TPS — 10 set(s), shuffled order

Per-set lag statistics are aggregated across sets. **Mean, Median and Trimmed Mean are all shown** (Trimmed Mean drops the single lowest and highest set when sets >= 4); no value is hidden. Rows are sorted by Median (lower is better).

| Framework | Lag Mean | Lag Median | Lag Trimmed Mean | P99 Lag (median of sets) | Max Lag (worst sample) | UI Build | GPU Raster | RSS |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Blooming | 0.137 ms | 0.038 ms | 0.133 ms | 0.842 ms | 4.675 ms | 4.11 ms | 0.69 ms | 192.9 MB |
| Flutter | 0.125 ms | 0.040 ms | 0.122 ms | 0.787 ms | 4.739 ms | 4.08 ms | 0.69 ms | 196.0 MB |
| Signals | 0.118 ms | 0.042 ms | 0.111 ms | 0.342 ms | 4.864 ms | 4.11 ms | 0.69 ms | 195.8 MB |
| Coralline | 0.146 ms | 0.043 ms | 0.145 ms | 2.429 ms | 5.429 ms | 4.21 ms | 0.83 ms | 204.3 MB |
| Riverpod | 0.472 ms | 0.246 ms | 0.471 ms | 3.373 ms | 4.488 ms | 3.88 ms | 0.77 ms | 203.7 MB |

#### Individual Set Breakdown (raw, unfiltered)

| Set # | Framework | Lag Mean | Lag Median | Lag P99 | Lag Max | Samples | UI Build | GPU Raster | RSS |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Set 1 | Flutter | 0.097 ms | 0.037 ms | 0.711 ms | 4.138 ms | 914 | 4.07 ms | 0.72 ms | 196.2 MB |
| Set 1 | Riverpod | 0.452 ms | 0.052 ms | 2.994 ms | 4.203 ms | 914 | 3.86 ms | 0.80 ms | 196.3 MB |
| Set 1 | Signals | 0.098 ms | 0.044 ms | 0.314 ms | 4.459 ms | 914 | 4.02 ms | 0.68 ms | 202.0 MB |
| Set 1 | Blooming | 0.128 ms | 0.039 ms | 0.824 ms | 4.660 ms | 914 | 4.08 ms | 0.68 ms | 190.5 MB |
| Set 1 | Coralline | 0.150 ms | 0.041 ms | 4.052 ms | 4.593 ms | 914 | 4.30 ms | 0.82 ms | 203.8 MB |
| Set 2 | Coralline | 0.175 ms | 0.043 ms | 4.283 ms | 4.732 ms | 914 | 4.20 ms | 0.86 ms | 202.8 MB |
| Set 2 | Riverpod | 0.447 ms | 0.245 ms | 1.840 ms | 4.488 ms | 914 | 3.95 ms | 0.74 ms | 203.4 MB |
| Set 2 | Flutter | 0.115 ms | 0.033 ms | 0.804 ms | 4.378 ms | 914 | 4.08 ms | 0.65 ms | 198.6 MB |
| Set 2 | Signals | 0.092 ms | 0.036 ms | 0.328 ms | 4.357 ms | 914 | 4.16 ms | 0.65 ms | 188.3 MB |
| Set 2 | Blooming | 0.129 ms | 0.035 ms | 0.839 ms | 4.575 ms | 914 | 4.07 ms | 0.70 ms | 189.7 MB |
| Set 3 | Riverpod | 0.487 ms | 0.247 ms | 4.016 ms | 4.311 ms | 914 | 3.94 ms | 0.75 ms | 202.1 MB |
| Set 3 | Blooming | 0.183 ms | 0.038 ms | 4.140 ms | 4.634 ms | 914 | 4.09 ms | 0.65 ms | 190.8 MB |
| Set 3 | Flutter | 0.113 ms | 0.041 ms | 0.601 ms | 4.644 ms | 914 | 4.11 ms | 0.71 ms | 191.8 MB |
| Set 3 | Coralline | 0.112 ms | 0.047 ms | 0.849 ms | 4.497 ms | 914 | 4.19 ms | 0.83 ms | 202.7 MB |
| Set 3 | Signals | 0.117 ms | 0.040 ms | 0.362 ms | 4.630 ms | 914 | 4.08 ms | 0.70 ms | 198.3 MB |
| Set 4 | Flutter | 0.175 ms | 0.042 ms | 4.130 ms | 4.492 ms | 914 | 4.11 ms | 0.70 ms | 191.6 MB |
| Set 4 | Riverpod | 0.506 ms | 0.267 ms | 3.865 ms | 4.258 ms | 914 | 3.93 ms | 0.81 ms | 206.8 MB |
| Set 4 | Signals | 0.197 ms | 0.047 ms | 4.307 ms | 4.711 ms | 914 | 4.04 ms | 0.69 ms | 192.9 MB |
| Set 4 | Coralline | 0.124 ms | 0.042 ms | 0.831 ms | 4.911 ms | 914 | 4.17 ms | 0.79 ms | 208.1 MB |
| Set 4 | Blooming | 0.127 ms | 0.037 ms | 0.701 ms | 4.454 ms | 914 | 4.10 ms | 0.68 ms | 195.2 MB |
| Set 5 | Coralline | 0.134 ms | 0.043 ms | 0.890 ms | 4.411 ms | 914 | 4.05 ms | 0.83 ms | 207.5 MB |
| Set 5 | Blooming | 0.137 ms | 0.038 ms | 3.876 ms | 4.675 ms | 914 | 4.09 ms | 0.71 ms | 194.7 MB |
| Set 5 | Riverpod | 0.489 ms | 0.231 ms | 3.843 ms | 4.203 ms | 914 | 3.79 ms | 0.75 ms | 199.2 MB |
| Set 5 | Signals | 0.104 ms | 0.042 ms | 0.319 ms | 4.306 ms | 914 | 4.06 ms | 0.74 ms | 202.0 MB |
| Set 5 | Flutter | 0.114 ms | 0.040 ms | 0.770 ms | 4.330 ms | 914 | 4.07 ms | 0.70 ms | 195.0 MB |
| Set 6 | Flutter | 0.101 ms | 0.040 ms | 0.575 ms | 4.739 ms | 914 | 4.01 ms | 0.68 ms | 200.0 MB |
| Set 6 | Coralline | 0.140 ms | 0.044 ms | 3.950 ms | 4.663 ms | 914 | 4.17 ms | 0.81 ms | 206.8 MB |
| Set 6 | Signals | 0.116 ms | 0.043 ms | 0.352 ms | 4.290 ms | 914 | 4.09 ms | 0.68 ms | 199.7 MB |
| Set 6 | Riverpod | 0.478 ms | 0.074 ms | 3.751 ms | 4.342 ms | 914 | 3.86 ms | 0.77 ms | 212.4 MB |
| Set 6 | Blooming | 0.126 ms | 0.037 ms | 0.881 ms | 4.300 ms | 914 | 4.12 ms | 0.69 ms | 193.1 MB |
| Set 7 | Riverpod | 0.455 ms | 0.064 ms | 1.916 ms | 4.176 ms | 914 | 3.84 ms | 0.78 ms | 199.4 MB |
| Set 7 | Coralline | 0.138 ms | 0.040 ms | 0.908 ms | 4.492 ms | 914 | 4.13 ms | 0.86 ms | 205.8 MB |
| Set 7 | Signals | 0.090 ms | 0.042 ms | 0.329 ms | 4.494 ms | 914 | 4.18 ms | 0.66 ms | 198.3 MB |
| Set 7 | Blooming | 0.125 ms | 0.037 ms | 0.845 ms | 4.598 ms | 914 | 4.04 ms | 0.71 ms | 193.6 MB |
| Set 7 | Flutter | 0.149 ms | 0.037 ms | 3.939 ms | 4.435 ms | 914 | 4.12 ms | 0.64 ms | 198.5 MB |
| Set 8 | Coralline | 0.175 ms | 0.039 ms | 4.136 ms | 4.418 ms | 914 | 4.14 ms | 0.80 ms | 199.1 MB |
| Set 8 | Flutter | 0.121 ms | 0.045 ms | 0.808 ms | 4.332 ms | 914 | 4.09 ms | 0.69 ms | 191.7 MB |
| Set 8 | Riverpod | 0.468 ms | 0.257 ms | 1.893 ms | 4.305 ms | 914 | 3.89 ms | 0.76 ms | 211.3 MB |
| Set 8 | Signals | 0.099 ms | 0.042 ms | 0.345 ms | 4.864 ms | 914 | 4.11 ms | 0.66 ms | 192.4 MB |
| Set 8 | Blooming | 0.137 ms | 0.043 ms | 1.122 ms | 4.280 ms | 914 | 4.13 ms | 0.68 ms | 193.5 MB |
| Set 9 | Riverpod | 0.493 ms | 0.255 ms | 3.925 ms | 4.326 ms | 914 | 3.87 ms | 0.76 ms | 200.3 MB |
| Set 9 | Coralline | 0.123 ms | 0.045 ms | 0.723 ms | 4.853 ms | 915 | 4.32 ms | 0.85 ms | 199.3 MB |
| Set 9 | Signals | 0.108 ms | 0.044 ms | 0.339 ms | 4.567 ms | 914 | 4.19 ms | 0.70 ms | 191.7 MB |
| Set 9 | Blooming | 0.132 ms | 0.040 ms | 0.696 ms | 4.351 ms | 914 | 4.15 ms | 0.73 ms | 194.1 MB |
| Set 9 | Flutter | 0.128 ms | 0.043 ms | 0.747 ms | 4.624 ms | 914 | 4.11 ms | 0.68 ms | 194.9 MB |
| Set 10 | Signals | 0.156 ms | 0.045 ms | 4.100 ms | 4.649 ms | 914 | 4.14 ms | 0.74 ms | 192.3 MB |
| Set 10 | Coralline | 0.185 ms | 0.045 ms | 4.303 ms | 5.429 ms | 914 | 4.40 ms | 0.86 ms | 207.2 MB |
| Set 10 | Riverpod | 0.449 ms | 0.257 ms | 1.730 ms | 4.202 ms | 914 | 3.86 ms | 0.78 ms | 205.3 MB |
| Set 10 | Blooming | 0.144 ms | 0.045 ms | 0.708 ms | 4.548 ms | 914 | 4.24 ms | 0.69 ms | 194.0 MB |
| Set 10 | Flutter | 0.133 ms | 0.036 ms | 0.895 ms | 4.406 ms | 914 | 4.00 ms | 0.71 ms | 201.6 MB |

---
## Limitations

- **Throughput is intentionally not reported.** The tick generator simulates at most 200 steps per 1 ms batch and adds the remainder to the tick counter arithmetically, so Sustained TPS / Achievement Rate track the target for every framework and cannot discriminate between them. Raw values remain in `benchmark_matrix.json` and `benchmark_summary.csv`.
- **Rendering metrics have low resolution.** The UI only repaints a handful of frames per run, so UI Build / GPU Raster are nearly identical across frameworks and should not be used to rank them.
- **Event loop lag is a main-isolate responsiveness metric**, not a throughput or correctness metric. Differences of a few hundredths of a millisecond are within run-to-run noise; compare Median and Max together with the raw per-set table.
- **Authorship Disclosure.** Signals and Riverpod are community open-source libraries. Flutter represents pure vanilla Flutter primitives (ValueNotifier & ListenableBuilder) without external dependencies. Blooming and Coralline are experimental frameworks designed by the benchmark author. See [`BENCHMARK_METHODOLOGY.md`](../../BENCHMARK_METHODOLOGY.md) for detailed architecture profiles.
- **Single machine, single OS, profile build.** Results are not portable to other hardware, OS versions or release/AOT builds without re-running.
- **No causal claims.** This report measures; it does not explain why a framework is faster or slower.

---
## 📊 Metric Definitions & Statistical Methodology

- **Event Loop Lag**: Measured by injecting `Timer.run()` every 33ms into Dart’s event queue. Measures delay until CPU execution (\Delta t = T_{executed} - T_{scheduled}).
- **Mean / Median / Trimmed Mean**: all three are reported side by side. Trimmed Mean drops the single lowest and highest set when sets >= 4; Median is the robust reference. The statistics are fixed in advance and never applied selectively.
- **Raw Data Transparency**: All individual set records, P95/P99 latencies, and engine timings are fully preserved in `benchmark_matrix.json` and `benchmark_summary.csv`.
- **Full Whitepaper**: See [`BENCHMARK_METHODOLOGY.md`](../../BENCHMARK_METHODOLOGY.md) for full mathematical definitions and source code snippets.

---
*Report generated automatically via pure hardware headless measurement.*

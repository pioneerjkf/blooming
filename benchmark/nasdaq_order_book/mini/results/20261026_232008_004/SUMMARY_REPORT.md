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
| Blooming | 0.155 ms | 0.042 ms | 0.153 ms | 4.069 ms | 4.852 ms | 4.10 ms | 0.69 ms | 194.2 MB |
| Flutter | 0.120 ms | 0.042 ms | 0.116 ms | 0.661 ms | 4.967 ms | 4.18 ms | 0.71 ms | 194.9 MB |
| Signals | 0.124 ms | 0.043 ms | 0.124 ms | 2.662 ms | 4.651 ms | 4.07 ms | 0.69 ms | 194.6 MB |
| Coralline | 0.153 ms | 0.044 ms | 0.147 ms | 1.004 ms | 4.800 ms | 4.17 ms | 0.83 ms | 206.6 MB |
| Riverpod | 0.477 ms | 0.247 ms | 0.478 ms | 3.791 ms | 4.351 ms | 3.86 ms | 0.77 ms | 208.5 MB |

#### Individual Set Breakdown (raw, unfiltered)

| Set # | Framework | Lag Mean | Lag Median | Lag P99 | Lag Max | Samples | UI Build | GPU Raster | RSS |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Set 1 | Riverpod | 0.469 ms | 0.054 ms | 3.799 ms | 4.191 ms | 914 | 3.87 ms | 0.75 ms | 213.7 MB |
| Set 1 | Coralline | 0.159 ms | 0.039 ms | 4.202 ms | 4.727 ms | 914 | 4.19 ms | 0.82 ms | 207.7 MB |
| Set 1 | Flutter | 0.141 ms | 0.042 ms | 4.111 ms | 4.498 ms | 914 | 4.21 ms | 0.70 ms | 192.7 MB |
| Set 1 | Blooming | 0.133 ms | 0.038 ms | 3.699 ms | 4.489 ms | 914 | 4.08 ms | 0.66 ms | 194.8 MB |
| Set 1 | Signals | 0.155 ms | 0.044 ms | 4.176 ms | 4.447 ms | 914 | 4.09 ms | 0.68 ms | 198.9 MB |
| Set 2 | Blooming | 0.137 ms | 0.038 ms | 4.073 ms | 4.852 ms | 914 | 4.11 ms | 0.69 ms | 195.3 MB |
| Set 2 | Signals | 0.110 ms | 0.041 ms | 0.324 ms | 4.286 ms | 914 | 4.06 ms | 0.67 ms | 193.9 MB |
| Set 2 | Coralline | 0.120 ms | 0.043 ms | 0.665 ms | 4.651 ms | 914 | 4.27 ms | 0.84 ms | 202.8 MB |
| Set 2 | Flutter | 0.089 ms | 0.037 ms | 0.608 ms | 4.431 ms | 914 | 4.15 ms | 0.69 ms | 199.4 MB |
| Set 2 | Riverpod | 0.475 ms | 0.232 ms | 1.931 ms | 4.130 ms | 914 | 3.84 ms | 0.79 ms | 212.4 MB |
| Set 3 | Riverpod | 0.493 ms | 0.237 ms | 3.810 ms | 4.265 ms | 914 | 3.86 ms | 0.75 ms | 208.5 MB |
| Set 3 | Blooming | 0.126 ms | 0.037 ms | 0.700 ms | 4.393 ms | 914 | 4.09 ms | 0.67 ms | 195.5 MB |
| Set 3 | Flutter | 0.117 ms | 0.038 ms | 0.657 ms | 4.567 ms | 914 | 4.11 ms | 0.70 ms | 196.0 MB |
| Set 3 | Coralline | 0.140 ms | 0.041 ms | 3.251 ms | 4.350 ms | 914 | 4.19 ms | 0.81 ms | 207.6 MB |
| Set 3 | Signals | 0.110 ms | 0.044 ms | 0.332 ms | 4.332 ms | 914 | 4.12 ms | 0.67 ms | 193.1 MB |
| Set 4 | Blooming | 0.143 ms | 0.036 ms | 4.052 ms | 4.496 ms | 914 | 4.04 ms | 0.70 ms | 194.6 MB |
| Set 4 | Signals | 0.123 ms | 0.043 ms | 3.960 ms | 4.296 ms | 914 | 4.04 ms | 0.69 ms | 193.6 MB |
| Set 4 | Coralline | 0.209 ms | 0.044 ms | 4.290 ms | 4.412 ms | 914 | 4.09 ms | 0.81 ms | 206.4 MB |
| Set 4 | Riverpod | 0.494 ms | 0.262 ms | 3.837 ms | 4.318 ms | 914 | 3.88 ms | 0.76 ms | 213.4 MB |
| Set 4 | Flutter | 0.136 ms | 0.043 ms | 3.159 ms | 4.263 ms | 914 | 4.22 ms | 0.72 ms | 191.4 MB |
| Set 5 | Flutter | 0.108 ms | 0.042 ms | 0.639 ms | 4.473 ms | 914 | 4.14 ms | 0.70 ms | 194.5 MB |
| Set 5 | Riverpod | 0.487 ms | 0.261 ms | 3.301 ms | 4.286 ms | 914 | 3.96 ms | 0.76 ms | 201.2 MB |
| Set 5 | Blooming | 0.125 ms | 0.041 ms | 0.858 ms | 4.274 ms | 914 | 4.12 ms | 0.68 ms | 193.3 MB |
| Set 5 | Coralline | 0.146 ms | 0.046 ms | 1.088 ms | 4.800 ms | 914 | 4.12 ms | 0.82 ms | 206.7 MB |
| Set 5 | Signals | 0.123 ms | 0.046 ms | 1.363 ms | 4.468 ms | 914 | 4.08 ms | 0.73 ms | 198.3 MB |
| Set 6 | Riverpod | 0.505 ms | 0.254 ms | 3.967 ms | 4.351 ms | 914 | 3.84 ms | 0.78 ms | 199.0 MB |
| Set 6 | Blooming | 0.181 ms | 0.045 ms | 4.124 ms | 4.709 ms | 914 | 4.12 ms | 0.70 ms | 193.9 MB |
| Set 6 | Coralline | 0.128 ms | 0.046 ms | 0.885 ms | 4.612 ms | 914 | 4.28 ms | 0.86 ms | 206.4 MB |
| Set 6 | Signals | 0.104 ms | 0.043 ms | 0.345 ms | 4.458 ms | 914 | 4.05 ms | 0.69 ms | 198.0 MB |
| Set 6 | Flutter | 0.100 ms | 0.042 ms | 0.596 ms | 4.652 ms | 914 | 4.27 ms | 0.76 ms | 194.3 MB |
| Set 7 | Riverpod | 0.454 ms | 0.243 ms | 1.816 ms | 4.159 ms | 914 | 3.85 ms | 0.79 ms | 211.7 MB |
| Set 7 | Signals | 0.136 ms | 0.043 ms | 4.047 ms | 4.535 ms | 914 | 4.15 ms | 0.74 ms | 192.6 MB |
| Set 7 | Blooming | 0.203 ms | 0.042 ms | 4.243 ms | 4.719 ms | 914 | 4.10 ms | 0.73 ms | 193.8 MB |
| Set 7 | Coralline | 0.242 ms | 0.044 ms | 4.306 ms | 4.594 ms | 914 | 4.09 ms | 0.81 ms | 206.2 MB |
| Set 7 | Flutter | 0.129 ms | 0.040 ms | 3.139 ms | 4.626 ms | 914 | 4.19 ms | 0.70 ms | 199.1 MB |
| Set 8 | Flutter | 0.111 ms | 0.046 ms | 0.664 ms | 4.539 ms | 914 | 4.22 ms | 0.70 ms | 192.4 MB |
| Set 8 | Signals | 0.095 ms | 0.043 ms | 0.333 ms | 4.310 ms | 914 | 4.01 ms | 0.67 ms | 192.5 MB |
| Set 8 | Coralline | 0.129 ms | 0.044 ms | 0.919 ms | 4.559 ms | 914 | 4.12 ms | 0.83 ms | 206.7 MB |
| Set 8 | Riverpod | 0.475 ms | 0.260 ms | 3.783 ms | 4.262 ms | 914 | 3.86 ms | 0.75 ms | 213.1 MB |
| Set 8 | Blooming | 0.155 ms | 0.042 ms | 4.065 ms | 4.234 ms | 914 | 3.98 ms | 0.70 ms | 193.3 MB |
| Set 9 | Blooming | 0.191 ms | 0.045 ms | 4.140 ms | 4.636 ms | 914 | 4.13 ms | 0.68 ms | 194.0 MB |
| Set 9 | Flutter | 0.177 ms | 0.044 ms | 4.156 ms | 4.967 ms | 915 | 4.12 ms | 0.71 ms | 192.5 MB |
| Set 9 | Signals | 0.143 ms | 0.044 ms | 4.141 ms | 4.651 ms | 914 | 4.03 ms | 0.71 ms | 192.7 MB |
| Set 9 | Riverpod | 0.442 ms | 0.247 ms | 1.816 ms | 3.932 ms | 914 | 3.81 ms | 0.79 ms | 206.8 MB |
| Set 9 | Coralline | 0.130 ms | 0.042 ms | 0.897 ms | 4.639 ms | 914 | 4.17 ms | 0.83 ms | 205.9 MB |
| Set 10 | Blooming | 0.154 ms | 0.045 ms | 4.149 ms | 4.652 ms | 914 | 4.20 ms | 0.70 ms | 193.6 MB |
| Set 10 | Coralline | 0.131 ms | 0.044 ms | 0.875 ms | 4.366 ms | 914 | 4.23 ms | 0.83 ms | 209.2 MB |
| Set 10 | Signals | 0.142 ms | 0.046 ms | 4.184 ms | 4.503 ms | 914 | 4.02 ms | 0.68 ms | 192.8 MB |
| Set 10 | Riverpod | 0.477 ms | 0.247 ms | 3.920 ms | 4.272 ms | 914 | 3.87 ms | 0.76 ms | 205.4 MB |
| Set 10 | Flutter | 0.088 ms | 0.042 ms | 0.603 ms | 4.430 ms | 914 | 4.17 ms | 0.74 ms | 196.9 MB |

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

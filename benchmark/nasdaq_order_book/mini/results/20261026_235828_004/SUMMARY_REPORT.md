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
| Blooming | 0.139 ms | 0.041 ms | 0.138 ms | 0.806 ms | 5.086 ms | 4.11 ms | 0.70 ms | 194.6 MB |
| Flutter | 0.154 ms | 0.042 ms | 0.156 ms | 4.035 ms | 4.921 ms | 4.12 ms | 0.70 ms | 195.9 MB |
| Coralline | 0.145 ms | 0.043 ms | 0.141 ms | 2.418 ms | 4.819 ms | 4.23 ms | 0.83 ms | 205.3 MB |
| Signals | 0.139 ms | 0.044 ms | 0.141 ms | 4.071 ms | 4.809 ms | 4.07 ms | 0.69 ms | 193.9 MB |
| Riverpod | 0.469 ms | 0.251 ms | 0.469 ms | 3.475 ms | 4.463 ms | 3.85 ms | 0.78 ms | 203.2 MB |

#### Individual Set Breakdown (raw, unfiltered)

| Set # | Framework | Lag Mean | Lag Median | Lag P99 | Lag Max | Samples | UI Build | GPU Raster | RSS |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Set 1 | Blooming | 0.108 ms | 0.037 ms | 0.779 ms | 4.212 ms | 914 | 4.12 ms | 0.69 ms | 194.7 MB |
| Set 1 | Riverpod | 0.501 ms | 0.204 ms | 3.956 ms | 4.262 ms | 914 | 3.78 ms | 0.80 ms | 202.9 MB |
| Set 1 | Flutter | 0.142 ms | 0.038 ms | 3.975 ms | 4.547 ms | 914 | 3.99 ms | 0.69 ms | 199.7 MB |
| Set 1 | Coralline | 0.147 ms | 0.044 ms | 4.141 ms | 4.692 ms | 914 | 4.37 ms | 0.88 ms | 203.6 MB |
| Set 1 | Signals | 0.090 ms | 0.045 ms | 0.301 ms | 4.210 ms | 914 | 4.10 ms | 0.69 ms | 193.9 MB |
| Set 2 | Riverpod | 0.455 ms | 0.057 ms | 3.822 ms | 4.116 ms | 914 | 3.84 ms | 0.77 ms | 200.6 MB |
| Set 2 | Flutter | 0.145 ms | 0.042 ms | 4.017 ms | 4.364 ms | 914 | 4.17 ms | 0.71 ms | 192.4 MB |
| Set 2 | Signals | 0.134 ms | 0.046 ms | 4.048 ms | 4.759 ms | 914 | 4.08 ms | 0.69 ms | 192.8 MB |
| Set 2 | Blooming | 0.178 ms | 0.046 ms | 4.099 ms | 4.575 ms | 914 | 4.02 ms | 0.69 ms | 194.3 MB |
| Set 2 | Coralline | 0.175 ms | 0.041 ms | 4.238 ms | 4.498 ms | 915 | 4.22 ms | 0.82 ms | 202.3 MB |
| Set 3 | Coralline | 0.111 ms | 0.044 ms | 0.835 ms | 4.452 ms | 914 | 4.22 ms | 0.81 ms | 206.2 MB |
| Set 3 | Signals | 0.116 ms | 0.044 ms | 0.360 ms | 4.406 ms | 914 | 3.94 ms | 0.68 ms | 197.4 MB |
| Set 3 | Riverpod | 0.464 ms | 0.261 ms | 1.989 ms | 4.198 ms | 914 | 3.80 ms | 0.75 ms | 198.6 MB |
| Set 3 | Blooming | 0.152 ms | 0.041 ms | 4.102 ms | 4.511 ms | 914 | 4.20 ms | 0.70 ms | 193.5 MB |
| Set 3 | Flutter | 0.176 ms | 0.045 ms | 4.091 ms | 4.478 ms | 914 | 4.10 ms | 0.69 ms | 194.6 MB |
| Set 4 | Signals | 0.171 ms | 0.045 ms | 4.143 ms | 4.380 ms | 914 | 4.15 ms | 0.68 ms | 192.5 MB |
| Set 4 | Coralline | 0.113 ms | 0.043 ms | 0.880 ms | 4.313 ms | 914 | 4.10 ms | 0.82 ms | 208.7 MB |
| Set 4 | Riverpod | 0.461 ms | 0.246 ms | 3.055 ms | 4.349 ms | 914 | 3.88 ms | 0.78 ms | 213.5 MB |
| Set 4 | Flutter | 0.167 ms | 0.044 ms | 4.043 ms | 4.803 ms | 915 | 4.11 ms | 0.68 ms | 199.3 MB |
| Set 4 | Blooming | 0.171 ms | 0.041 ms | 4.121 ms | 5.086 ms | 914 | 4.19 ms | 0.74 ms | 193.8 MB |
| Set 5 | Signals | 0.155 ms | 0.041 ms | 4.186 ms | 4.547 ms | 914 | 4.16 ms | 0.69 ms | 192.3 MB |
| Set 5 | Flutter | 0.177 ms | 0.043 ms | 4.230 ms | 4.486 ms | 914 | 4.09 ms | 0.68 ms | 196.5 MB |
| Set 5 | Blooming | 0.117 ms | 0.044 ms | 0.678 ms | 4.091 ms | 914 | 4.19 ms | 0.69 ms | 195.9 MB |
| Set 5 | Coralline | 0.130 ms | 0.043 ms | 0.857 ms | 4.398 ms | 914 | 4.23 ms | 0.83 ms | 201.2 MB |
| Set 5 | Riverpod | 0.476 ms | 0.246 ms | 3.228 ms | 4.362 ms | 914 | 3.88 ms | 0.79 ms | 198.7 MB |
| Set 6 | Coralline | 0.150 ms | 0.045 ms | 3.957 ms | 4.712 ms | 914 | 4.23 ms | 0.82 ms | 205.7 MB |
| Set 6 | Flutter | 0.181 ms | 0.044 ms | 4.163 ms | 4.921 ms | 914 | 4.14 ms | 0.74 ms | 193.5 MB |
| Set 6 | Riverpod | 0.471 ms | 0.255 ms | 2.291 ms | 4.463 ms | 914 | 3.86 ms | 0.76 ms | 211.0 MB |
| Set 6 | Blooming | 0.125 ms | 0.044 ms | 0.674 ms | 4.458 ms | 914 | 4.08 ms | 0.74 ms | 194.2 MB |
| Set 6 | Signals | 0.130 ms | 0.045 ms | 4.093 ms | 4.520 ms | 914 | 4.14 ms | 0.69 ms | 200.1 MB |
| Set 7 | Flutter | 0.118 ms | 0.041 ms | 0.796 ms | 4.575 ms | 914 | 4.13 ms | 0.69 ms | 201.8 MB |
| Set 7 | Signals | 0.166 ms | 0.041 ms | 4.177 ms | 4.809 ms | 914 | 4.01 ms | 0.68 ms | 192.4 MB |
| Set 7 | Coralline | 0.172 ms | 0.043 ms | 4.195 ms | 4.597 ms | 914 | 4.31 ms | 0.86 ms | 204.2 MB |
| Set 7 | Riverpod | 0.436 ms | 0.249 ms | 1.804 ms | 3.925 ms | 914 | 3.83 ms | 0.75 ms | 207.2 MB |
| Set 7 | Blooming | 0.129 ms | 0.041 ms | 0.720 ms | 4.448 ms | 914 | 4.03 ms | 0.69 ms | 196.2 MB |
| Set 8 | Riverpod | 0.473 ms | 0.256 ms | 3.843 ms | 4.345 ms | 914 | 3.94 ms | 0.84 ms | 201.9 MB |
| Set 8 | Flutter | 0.144 ms | 0.042 ms | 4.028 ms | 4.577 ms | 914 | 4.17 ms | 0.70 ms | 196.7 MB |
| Set 8 | Signals | 0.159 ms | 0.043 ms | 4.195 ms | 4.587 ms | 914 | 4.17 ms | 0.70 ms | 192.4 MB |
| Set 8 | Blooming | 0.126 ms | 0.042 ms | 0.690 ms | 4.227 ms | 914 | 3.99 ms | 0.70 ms | 193.4 MB |
| Set 8 | Coralline | 0.130 ms | 0.045 ms | 0.872 ms | 4.557 ms | 914 | 4.14 ms | 0.82 ms | 206.4 MB |
| Set 9 | Blooming | 0.156 ms | 0.040 ms | 4.068 ms | 4.650 ms | 914 | 4.13 ms | 0.69 ms | 196.1 MB |
| Set 9 | Signals | 0.140 ms | 0.044 ms | 4.019 ms | 4.308 ms | 915 | 3.98 ms | 0.68 ms | 192.8 MB |
| Set 9 | Riverpod | 0.484 ms | 0.262 ms | 3.866 ms | 4.244 ms | 914 | 3.84 ms | 0.77 ms | 199.5 MB |
| Set 9 | Coralline | 0.206 ms | 0.041 ms | 4.291 ms | 4.819 ms | 914 | 4.22 ms | 0.83 ms | 208.6 MB |
| Set 9 | Flutter | 0.101 ms | 0.042 ms | 0.640 ms | 4.773 ms | 914 | 4.06 ms | 0.69 ms | 192.9 MB |
| Set 10 | Blooming | 0.125 ms | 0.041 ms | 0.833 ms | 4.241 ms | 914 | 4.14 ms | 0.68 ms | 193.8 MB |
| Set 10 | Riverpod | 0.471 ms | 0.252 ms | 3.722 ms | 4.392 ms | 914 | 3.84 ms | 0.76 ms | 197.8 MB |
| Set 10 | Signals | 0.125 ms | 0.046 ms | 3.166 ms | 4.445 ms | 914 | 4.01 ms | 0.68 ms | 192.7 MB |
| Set 10 | Flutter | 0.190 ms | 0.043 ms | 4.150 ms | 4.427 ms | 914 | 4.22 ms | 0.69 ms | 191.9 MB |
| Set 10 | Coralline | 0.113 ms | 0.045 ms | 0.851 ms | 4.514 ms | 914 | 4.22 ms | 0.84 ms | 205.7 MB |

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

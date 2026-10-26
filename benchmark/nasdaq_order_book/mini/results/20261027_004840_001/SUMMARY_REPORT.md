# NASDAQ Order Book Mini — Multi-Framework Performance Whitepaper

> High-throughput reactive benchmark comparing state management & reactive graph architectures in Flutter/Dart under extreme stream ingest loads (10K to 100K+ TPS).

## Benchmark Execution Environment (100% Real Hardware Ingestion)
- **Operating System**: `macos Version 27.0.1 (Build 26A434)`
- **Dart SDK**: `3.13.5`
- **Scenario Duration**: `30s` per test scenario (10 randomized set(s))
- **Order Book Scroll Animation**: `Enabled (Continuous VSync Oscillation)`
- **Execution Engine**: Flutter Driver Real Window, `--profile` build (GPU & VSync Timelines)
- **Event Loop Lag sampling**: every 33ms over the full 30s window of each set (about 909 samples per set), stored in a pre-allocated fixed buffer.
- **Scope**: see *Limitations* at the end of this report before drawing conclusions.

---
### Scenario: Target 1,000,000,000 TPS — 10 set(s), shuffled order

Per-set lag statistics are aggregated across sets. **Mean, Median and Trimmed Mean are all shown** (Trimmed Mean drops the single lowest and highest set when sets >= 4); no value is hidden. Rows are sorted by Median (lower is better).

| Framework | Lag Mean | Lag Median | Lag Trimmed Mean | P99 Lag (median of sets) | Max Lag (worst sample) | UI Build | GPU Raster | RSS |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Flutter | 0.142 ms | 0.056 ms | 0.139 ms | 3.364 ms | 4.281 ms | 3.37 ms | 0.60 ms | 200.3 MB |
| Coralline | 0.139 ms | 0.057 ms | 0.138 ms | 3.455 ms | 3.921 ms | 3.51 ms | 0.71 ms | 207.8 MB |
| Blooming | 0.158 ms | 0.059 ms | 0.162 ms | 3.398 ms | 3.909 ms | 3.39 ms | 0.61 ms | 199.5 MB |
| Signals | 0.163 ms | 0.061 ms | 0.164 ms | 3.418 ms | 4.022 ms | 3.43 ms | 0.60 ms | 201.8 MB |
| Riverpod | 0.463 ms | 0.303 ms | 0.463 ms | 3.320 ms | 4.397 ms | 3.37 ms | 0.72 ms | 213.0 MB |

#### Individual Set Breakdown (raw, unfiltered)

| Set # | Framework | Lag Mean | Lag Median | Lag P99 | Lag Max | Samples | UI Build | GPU Raster | RSS |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Set 1 | Flutter | 0.137 ms | 0.052 ms | 3.266 ms | 3.754 ms | 914 | 3.36 ms | 0.60 ms | 203.2 MB |
| Set 1 | Riverpod | 0.457 ms | 0.304 ms | 3.336 ms | 3.708 ms | 914 | 3.44 ms | 0.71 ms | 212.0 MB |
| Set 1 | Coralline | 0.111 ms | 0.053 ms | 3.262 ms | 3.857 ms | 914 | 3.44 ms | 0.69 ms | 205.1 MB |
| Set 1 | Blooming | 0.170 ms | 0.055 ms | 3.388 ms | 3.646 ms | 914 | 3.36 ms | 0.61 ms | 201.6 MB |
| Set 1 | Signals | 0.140 ms | 0.055 ms | 3.334 ms | 3.760 ms | 914 | 3.44 ms | 0.59 ms | 207.6 MB |
| Set 2 | Blooming | 0.168 ms | 0.058 ms | 3.456 ms | 3.644 ms | 914 | 3.40 ms | 0.61 ms | 201.8 MB |
| Set 2 | Flutter | 0.133 ms | 0.056 ms | 3.338 ms | 3.864 ms | 914 | 3.53 ms | 0.63 ms | 200.2 MB |
| Set 2 | Signals | 0.159 ms | 0.059 ms | 3.443 ms | 3.854 ms | 914 | 3.45 ms | 0.59 ms | 199.5 MB |
| Set 2 | Coralline | 0.127 ms | 0.056 ms | 3.396 ms | 3.921 ms | 915 | 3.49 ms | 0.70 ms | 210.0 MB |
| Set 2 | Riverpod | 0.466 ms | 0.304 ms | 3.304 ms | 3.967 ms | 914 | 3.42 ms | 0.71 ms | 216.1 MB |
| Set 3 | Blooming | 0.166 ms | 0.060 ms | 3.409 ms | 3.641 ms | 914 | 3.32 ms | 0.59 ms | 199.7 MB |
| Set 3 | Signals | 0.154 ms | 0.061 ms | 3.389 ms | 3.541 ms | 914 | 3.33 ms | 0.57 ms | 205.1 MB |
| Set 3 | Flutter | 0.127 ms | 0.055 ms | 3.319 ms | 3.983 ms | 914 | 3.34 ms | 0.58 ms | 202.7 MB |
| Set 3 | Riverpod | 0.468 ms | 0.303 ms | 3.357 ms | 4.397 ms | 914 | 3.31 ms | 0.71 ms | 213.5 MB |
| Set 3 | Coralline | 0.170 ms | 0.058 ms | 3.504 ms | 3.581 ms | 914 | 3.54 ms | 0.72 ms | 203.5 MB |
| Set 4 | Flutter | 0.187 ms | 0.057 ms | 3.438 ms | 3.709 ms | 914 | 3.34 ms | 0.61 ms | 202.4 MB |
| Set 4 | Riverpod | 0.467 ms | 0.294 ms | 3.443 ms | 4.135 ms | 914 | 3.29 ms | 0.72 ms | 212.7 MB |
| Set 4 | Signals | 0.166 ms | 0.060 ms | 3.393 ms | 4.022 ms | 914 | 3.58 ms | 0.64 ms | 201.6 MB |
| Set 4 | Blooming | 0.149 ms | 0.059 ms | 3.341 ms | 3.909 ms | 914 | 3.37 ms | 0.58 ms | 196.5 MB |
| Set 4 | Coralline | 0.140 ms | 0.057 ms | 3.457 ms | 3.812 ms | 914 | 3.49 ms | 0.73 ms | 208.9 MB |
| Set 5 | Riverpod | 0.459 ms | 0.301 ms | 3.298 ms | 3.671 ms | 914 | 3.26 ms | 0.72 ms | 215.1 MB |
| Set 5 | Signals | 0.179 ms | 0.061 ms | 3.450 ms | 3.970 ms | 914 | 3.44 ms | 0.59 ms | 200.0 MB |
| Set 5 | Blooming | 0.166 ms | 0.059 ms | 3.424 ms | 3.672 ms | 914 | 3.44 ms | 0.61 ms | 199.3 MB |
| Set 5 | Coralline | 0.164 ms | 0.060 ms | 3.457 ms | 3.808 ms | 914 | 3.34 ms | 0.71 ms | 215.6 MB |
| Set 5 | Flutter | 0.118 ms | 0.055 ms | 3.296 ms | 3.705 ms | 914 | 3.40 ms | 0.60 ms | 197.1 MB |
| Set 6 | Flutter | 0.117 ms | 0.056 ms | 3.353 ms | 4.281 ms | 914 | 3.38 ms | 0.59 ms | 196.6 MB |
| Set 6 | Signals | 0.166 ms | 0.062 ms | 3.419 ms | 3.616 ms | 914 | 3.37 ms | 0.62 ms | 206.0 MB |
| Set 6 | Riverpod | 0.464 ms | 0.313 ms | 3.402 ms | 4.164 ms | 914 | 3.48 ms | 0.74 ms | 208.6 MB |
| Set 6 | Blooming | 0.146 ms | 0.058 ms | 3.378 ms | 3.891 ms | 914 | 3.36 ms | 0.60 ms | 207.0 MB |
| Set 6 | Coralline | 0.134 ms | 0.057 ms | 3.453 ms | 3.709 ms | 914 | 3.61 ms | 0.73 ms | 209.8 MB |
| Set 7 | Coralline | 0.124 ms | 0.056 ms | 3.418 ms | 3.882 ms | 914 | 3.56 ms | 0.72 ms | 206.8 MB |
| Set 7 | Riverpod | 0.437 ms | 0.297 ms | 3.294 ms | 3.634 ms | 914 | 3.38 ms | 0.71 ms | 213.9 MB |
| Set 7 | Blooming | 0.167 ms | 0.060 ms | 3.442 ms | 3.668 ms | 914 | 3.46 ms | 0.65 ms | 199.4 MB |
| Set 7 | Signals | 0.172 ms | 0.062 ms | 3.471 ms | 3.828 ms | 914 | 3.38 ms | 0.60 ms | 197.1 MB |
| Set 7 | Flutter | 0.168 ms | 0.057 ms | 3.388 ms | 3.807 ms | 914 | 3.30 ms | 0.59 ms | 198.3 MB |
| Set 8 | Coralline | 0.130 ms | 0.056 ms | 3.421 ms | 3.774 ms | 914 | 3.56 ms | 0.71 ms | 204.4 MB |
| Set 8 | Riverpod | 0.462 ms | 0.308 ms | 3.289 ms | 3.745 ms | 914 | 3.51 ms | 0.76 ms | 214.4 MB |
| Set 8 | Signals | 0.171 ms | 0.060 ms | 3.446 ms | 3.708 ms | 914 | 3.40 ms | 0.59 ms | 199.3 MB |
| Set 8 | Flutter | 0.130 ms | 0.056 ms | 3.375 ms | 3.968 ms | 914 | 3.34 ms | 0.58 ms | 198.4 MB |
| Set 8 | Blooming | 0.160 ms | 0.061 ms | 3.352 ms | 3.494 ms | 914 | 3.32 ms | 0.61 ms | 196.1 MB |
| Set 9 | Flutter | 0.151 ms | 0.055 ms | 3.402 ms | 3.848 ms | 914 | 3.34 ms | 0.60 ms | 201.7 MB |
| Set 9 | Signals | 0.150 ms | 0.063 ms | 3.417 ms | 3.966 ms | 914 | 3.46 ms | 0.64 ms | 204.8 MB |
| Set 9 | Riverpod | 0.484 ms | 0.313 ms | 3.337 ms | 4.137 ms | 914 | 3.24 ms | 0.70 ms | 214.9 MB |
| Set 9 | Coralline | 0.155 ms | 0.057 ms | 3.458 ms | 3.670 ms | 914 | 3.49 ms | 0.70 ms | 203.9 MB |
| Set 9 | Blooming | 0.119 ms | 0.059 ms | 2.884 ms | 3.573 ms | 914 | 3.41 ms | 0.64 ms | 196.2 MB |
| Set 10 | Flutter | 0.148 ms | 0.057 ms | 3.452 ms | 3.807 ms | 914 | 3.33 ms | 0.62 ms | 202.9 MB |
| Set 10 | Coralline | 0.131 ms | 0.056 ms | 3.535 ms | 3.776 ms | 914 | 3.56 ms | 0.71 ms | 210.3 MB |
| Set 10 | Riverpod | 0.461 ms | 0.294 ms | 3.225 ms | 3.997 ms | 914 | 3.40 ms | 0.73 ms | 209.1 MB |
| Set 10 | Blooming | 0.172 ms | 0.056 ms | 3.464 ms | 3.655 ms | 914 | 3.46 ms | 0.62 ms | 197.6 MB |
| Set 10 | Signals | 0.170 ms | 0.061 ms | 3.404 ms | 3.988 ms | 914 | 3.41 ms | 0.57 ms | 197.4 MB |

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

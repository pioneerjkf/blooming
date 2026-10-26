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
| Flutter | 0.180 ms | 0.058 ms | 0.181 ms | 3.376 ms | 3.919 ms | 3.37 ms | 0.60 ms | 200.1 MB |
| Signals | 0.155 ms | 0.061 ms | 0.157 ms | 3.418 ms | 4.138 ms | 3.40 ms | 0.60 ms | 203.1 MB |
| Coralline | 0.175 ms | 0.062 ms | 0.174 ms | 3.458 ms | 4.440 ms | 3.48 ms | 0.72 ms | 208.5 MB |
| Blooming | 0.188 ms | 0.063 ms | 0.189 ms | 3.393 ms | 4.099 ms | 3.35 ms | 0.59 ms | 200.2 MB |
| Riverpod | 0.500 ms | 0.316 ms | 0.500 ms | 3.336 ms | 4.274 ms | 3.41 ms | 0.72 ms | 206.4 MB |

#### Individual Set Breakdown (raw, unfiltered)

| Set # | Framework | Lag Mean | Lag Median | Lag P99 | Lag Max | Samples | UI Build | GPU Raster | RSS |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Set 1 | Signals | 0.118 ms | 0.055 ms | 3.226 ms | 4.138 ms | 914 | 3.40 ms | 0.60 ms | 203.5 MB |
| Set 1 | Riverpod | 0.475 ms | 0.302 ms | 3.283 ms | 3.845 ms | 914 | 3.46 ms | 0.73 ms | 204.1 MB |
| Set 1 | Blooming | 0.175 ms | 0.057 ms | 3.330 ms | 3.903 ms | 914 | 3.32 ms | 0.61 ms | 197.1 MB |
| Set 1 | Coralline | 0.180 ms | 0.057 ms | 3.468 ms | 3.792 ms | 914 | 3.50 ms | 0.73 ms | 204.5 MB |
| Set 1 | Flutter | 0.132 ms | 0.051 ms | 3.259 ms | 3.487 ms | 914 | 3.36 ms | 0.59 ms | 199.9 MB |
| Set 2 | Signals | 0.173 ms | 0.057 ms | 3.423 ms | 3.703 ms | 914 | 3.36 ms | 0.61 ms | 206.3 MB |
| Set 2 | Riverpod | 0.505 ms | 0.319 ms | 3.277 ms | 3.651 ms | 914 | 3.44 ms | 0.70 ms | 199.8 MB |
| Set 2 | Flutter | 0.195 ms | 0.056 ms | 3.427 ms | 3.775 ms | 914 | 3.38 ms | 0.59 ms | 200.1 MB |
| Set 2 | Coralline | 0.199 ms | 0.063 ms | 3.549 ms | 4.440 ms | 914 | 3.52 ms | 0.68 ms | 204.6 MB |
| Set 2 | Blooming | 0.186 ms | 0.061 ms | 3.392 ms | 3.622 ms | 914 | 3.43 ms | 0.58 ms | 199.7 MB |
| Set 3 | Signals | 0.174 ms | 0.061 ms | 3.506 ms | 3.743 ms | 914 | 3.46 ms | 0.59 ms | 197.5 MB |
| Set 3 | Blooming | 0.201 ms | 0.063 ms | 3.411 ms | 3.546 ms | 914 | 3.41 ms | 0.61 ms | 198.5 MB |
| Set 3 | Flutter | 0.217 ms | 0.056 ms | 3.456 ms | 3.649 ms | 914 | 3.42 ms | 0.57 ms | 200.4 MB |
| Set 3 | Riverpod | 0.502 ms | 0.309 ms | 3.375 ms | 3.949 ms | 914 | 3.39 ms | 0.70 ms | 203.0 MB |
| Set 3 | Coralline | 0.155 ms | 0.061 ms | 3.412 ms | 3.582 ms | 914 | 3.59 ms | 0.76 ms | 209.8 MB |
| Set 4 | Blooming | 0.187 ms | 0.063 ms | 3.385 ms | 3.571 ms | 914 | 3.40 ms | 0.59 ms | 201.5 MB |
| Set 4 | Flutter | 0.183 ms | 0.060 ms | 3.388 ms | 3.727 ms | 914 | 3.32 ms | 0.58 ms | 200.5 MB |
| Set 4 | Coralline | 0.171 ms | 0.062 ms | 3.465 ms | 4.201 ms | 914 | 3.44 ms | 0.70 ms | 204.2 MB |
| Set 4 | Signals | 0.149 ms | 0.061 ms | 3.391 ms | 4.060 ms | 914 | 3.35 ms | 0.61 ms | 204.8 MB |
| Set 4 | Riverpod | 0.490 ms | 0.308 ms | 3.338 ms | 3.833 ms | 914 | 3.38 ms | 0.70 ms | 212.9 MB |
| Set 5 | Signals | 0.139 ms | 0.061 ms | 3.302 ms | 3.752 ms | 914 | 3.40 ms | 0.59 ms | 205.1 MB |
| Set 5 | Flutter | 0.191 ms | 0.058 ms | 3.412 ms | 3.758 ms | 914 | 3.32 ms | 0.62 ms | 196.2 MB |
| Set 5 | Blooming | 0.197 ms | 0.062 ms | 3.386 ms | 3.806 ms | 914 | 3.34 ms | 0.59 ms | 196.7 MB |
| Set 5 | Riverpod | 0.518 ms | 0.322 ms | 3.366 ms | 3.781 ms | 914 | 3.45 ms | 0.73 ms | 206.3 MB |
| Set 5 | Coralline | 0.158 ms | 0.063 ms | 3.452 ms | 3.671 ms | 914 | 3.54 ms | 0.77 ms | 214.8 MB |
| Set 6 | Flutter | 0.176 ms | 0.059 ms | 3.386 ms | 3.919 ms | 914 | 3.46 ms | 0.60 ms | 202.3 MB |
| Set 6 | Blooming | 0.192 ms | 0.063 ms | 3.394 ms | 3.768 ms | 914 | 3.28 ms | 0.59 ms | 207.2 MB |
| Set 6 | Signals | 0.128 ms | 0.062 ms | 3.335 ms | 3.556 ms | 914 | 3.47 ms | 0.62 ms | 200.9 MB |
| Set 6 | Riverpod | 0.491 ms | 0.315 ms | 3.319 ms | 3.818 ms | 914 | 3.40 ms | 0.75 ms | 208.5 MB |
| Set 6 | Coralline | 0.179 ms | 0.061 ms | 3.420 ms | 3.781 ms | 914 | 3.41 ms | 0.71 ms | 217.0 MB |
| Set 7 | Flutter | 0.180 ms | 0.059 ms | 3.351 ms | 3.575 ms | 914 | 3.29 ms | 0.59 ms | 200.2 MB |
| Set 7 | Riverpod | 0.519 ms | 0.319 ms | 3.425 ms | 4.274 ms | 914 | 3.35 ms | 0.70 ms | 211.4 MB |
| Set 7 | Coralline | 0.174 ms | 0.063 ms | 3.485 ms | 3.980 ms | 915 | 3.48 ms | 0.73 ms | 204.4 MB |
| Set 7 | Signals | 0.174 ms | 0.061 ms | 3.451 ms | 3.834 ms | 914 | 3.42 ms | 0.61 ms | 205.6 MB |
| Set 7 | Blooming | 0.204 ms | 0.063 ms | 3.417 ms | 3.719 ms | 914 | 3.35 ms | 0.59 ms | 199.9 MB |
| Set 8 | Riverpod | 0.487 ms | 0.306 ms | 3.325 ms | 4.078 ms | 914 | 3.48 ms | 0.73 ms | 205.1 MB |
| Set 8 | Flutter | 0.183 ms | 0.059 ms | 3.365 ms | 3.689 ms | 914 | 3.41 ms | 0.64 ms | 200.8 MB |
| Set 8 | Blooming | 0.170 ms | 0.064 ms | 3.418 ms | 4.099 ms | 914 | 3.34 ms | 0.59 ms | 199.9 MB |
| Set 8 | Coralline | 0.218 ms | 0.061 ms | 3.618 ms | 4.239 ms | 914 | 3.47 ms | 0.74 ms | 206.2 MB |
| Set 8 | Signals | 0.158 ms | 0.063 ms | 3.461 ms | 4.016 ms | 914 | 3.34 ms | 0.58 ms | 207.9 MB |
| Set 9 | Blooming | 0.203 ms | 0.065 ms | 3.378 ms | 3.703 ms | 914 | 3.28 ms | 0.58 ms | 199.7 MB |
| Set 9 | Signals | 0.176 ms | 0.062 ms | 3.445 ms | 3.957 ms | 914 | 3.41 ms | 0.61 ms | 202.8 MB |
| Set 9 | Coralline | 0.175 ms | 0.062 ms | 3.413 ms | 3.726 ms | 914 | 3.46 ms | 0.72 ms | 214.8 MB |
| Set 9 | Riverpod | 0.511 ms | 0.333 ms | 3.340 ms | 3.820 ms | 914 | 3.37 ms | 0.72 ms | 204.7 MB |
| Set 9 | Flutter | 0.162 ms | 0.058 ms | 3.351 ms | 3.890 ms | 914 | 3.41 ms | 0.60 ms | 197.8 MB |
| Set 10 | Coralline | 0.142 ms | 0.062 ms | 3.357 ms | 4.002 ms | 914 | 3.43 ms | 0.69 ms | 204.8 MB |
| Set 10 | Signals | 0.159 ms | 0.062 ms | 3.414 ms | 3.969 ms | 914 | 3.41 ms | 0.60 ms | 197.0 MB |
| Set 10 | Blooming | 0.161 ms | 0.063 ms | 3.459 ms | 4.084 ms | 914 | 3.39 ms | 0.60 ms | 202.0 MB |
| Set 10 | Riverpod | 0.499 ms | 0.317 ms | 3.333 ms | 3.744 ms | 914 | 3.42 ms | 0.74 ms | 208.2 MB |
| Set 10 | Flutter | 0.177 ms | 0.061 ms | 3.349 ms | 3.728 ms | 914 | 3.37 ms | 0.60 ms | 202.5 MB |

---
## Limitations

- **Throughput is intentionally not reported.** The tick generator simulates at most 200 steps per 1 ms batch and adds the remainder to the tick counter arithmetically, so Sustained TPS / Achievement Rate track the target for every framework and cannot discriminate between them. Raw values remain in `benchmark_matrix.json` and `benchmark_summary.csv`.
- **Rendering metrics have low resolution.** The UI only repaints a handful of frames per run, so UI Build / GPU Raster are nearly identical across frameworks and should not be used to rank them.
- **Event loop lag is a main-isolate responsiveness metric**, not a throughput or correctness metric. Differences of a few hundredths of a millisecond are within run-to-run noise; compare Median and Max together with the raw per-set table.
- **Authorship Disclosure.** Signals and Riverpod are community open-source libraries. Flutter represents pure vanilla Flutter primitives (ValueNotifier & ListenableBuilder) without external dependencies. Blooming and Coralline are experimental frameworks designed by the benchmark author. See [`BENCHMARK_METHODOLOGY.md`](../BENCHMARK_METHODOLOGY.md) for detailed architecture profiles.
- **Single machine, single OS, profile build.** Results are not portable to other hardware, OS versions or release/AOT builds without re-running.
- **No causal claims.** This report measures; it does not explain why a framework is faster or slower.

---
## 📊 Metric Definitions & Statistical Methodology

- **Event Loop Lag**: Measured by injecting `Timer.run()` every 33ms into Dart’s event queue. Measures delay until CPU execution (\Delta t = T_{executed} - T_{scheduled}).
- **Mean / Median / Trimmed Mean**: all three are reported side by side. Trimmed Mean drops the single lowest and highest set when sets >= 4; Median is the robust reference. The statistics are fixed in advance and never applied selectively.
- **Raw Data Transparency**: All individual set records, P95/P99 latencies, and engine timings are fully preserved in `benchmark_matrix.json` and `benchmark_summary.csv`.
- **Full Whitepaper**: See [`BENCHMARK_METHODOLOGY.md`](../BENCHMARK_METHODOLOGY.md) for full mathematical definitions and source code snippets.

---
*Report generated automatically via pure hardware headless measurement.*

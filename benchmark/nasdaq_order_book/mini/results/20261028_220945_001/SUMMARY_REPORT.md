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
### Scenario: Target 1,000,000,000 TPS — 10 set(s), shuffled order

Per-set lag statistics are aggregated across sets. **Mean, Median and Trimmed Mean are all shown** (Trimmed Mean drops the single lowest and highest set when sets >= 4); no value is hidden. Rows are sorted by Median (lower is better).

| Framework | Generator Ingest TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag Trimmed Mean | P99 Lag (median of sets) | Max Lag (worst sample) | UI Build | GPU Raster | RSS |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Flutter | 16,455,583/s | 16 Hz | 0.153 ms | 0.024 ms | 0.156 ms | 5.594 ms | 8.659 ms | 5.82 ms | 0.70 ms | 225.4 MB |
| Blooming | 16,421,681/s | 16 Hz | 0.174 ms | 0.029 ms | 0.175 ms | 5.817 ms | 7.998 ms | 5.75 ms | 0.70 ms | 225.1 MB |
| Coralline | 15,831,870/s | 16 Hz | 0.170 ms | 0.041 ms | 0.169 ms | 5.539 ms | 9.286 ms | 6.01 ms | 0.82 ms | 238.0 MB |
| Signals | 16,392,734/s | 16 Hz | 0.165 ms | 0.042 ms | 0.168 ms | 5.583 ms | 8.427 ms | 5.83 ms | 0.70 ms | 226.9 MB |
| Riverpod | 15,888,421/s | 16 Hz | 0.186 ms | 0.080 ms | 0.190 ms | 5.540 ms | 8.524 ms | 5.99 ms | 0.82 ms | 232.4 MB |

#### Individual Set Breakdown (raw, unfiltered)

| Set # | Framework | Generator TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag P99 | Lag Max | Samples | UI Build | GPU Raster | RSS |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Set 1 | Flutter | 16,498,261/s | 16 Hz | 0.099 ms | 0.029 ms | 0.318 ms | 7.601 ms | 915 | 5.56 ms | 0.69 ms | 231.0 MB |
| Set 1 | Coralline | 16,798,648/s | 17 Hz | 0.097 ms | 0.033 ms | 0.652 ms | 7.255 ms | 915 | 5.23 ms | 0.86 ms | 231.7 MB |
| Set 1 | Riverpod | 15,804,645/s | 16 Hz | 0.146 ms | 0.083 ms | 0.595 ms | 7.965 ms | 914 | 6.65 ms | 0.83 ms | 229.5 MB |
| Set 1 | Blooming | 16,432,547/s | 16 Hz | 0.149 ms | 0.029 ms | 5.706 ms | 7.893 ms | 914 | 5.95 ms | 0.70 ms | 220.1 MB |
| Set 1 | Signals | 17,062,020/s | 17 Hz | 0.096 ms | 0.035 ms | 0.259 ms | 6.963 ms | 915 | 5.48 ms | 0.69 ms | 227.3 MB |
| Set 2 | Riverpod | 15,931,373/s | 16 Hz | 0.121 ms | 0.077 ms | 0.395 ms | 8.524 ms | 915 | 5.88 ms | 0.82 ms | 235.2 MB |
| Set 2 | Blooming | 16,366,287/s | 16 Hz | 0.120 ms | 0.027 ms | 5.290 ms | 7.268 ms | 914 | 6.27 ms | 0.76 ms | 221.5 MB |
| Set 2 | Coralline | 15,902,465/s | 16 Hz | 0.133 ms | 0.040 ms | 5.291 ms | 8.057 ms | 914 | 5.67 ms | 0.80 ms | 236.1 MB |
| Set 2 | Signals | 16,267,974/s | 16 Hz | 0.144 ms | 0.044 ms | 5.417 ms | 7.287 ms | 915 | 6.20 ms | 0.83 ms | 229.8 MB |
| Set 2 | Flutter | 17,460,738/s | 17 Hz | 0.159 ms | 0.024 ms | 5.380 ms | 6.902 ms | 914 | 5.49 ms | 0.67 ms | 213.9 MB |
| Set 3 | Riverpod | 16,134,376/s | 16 Hz | 0.193 ms | 0.081 ms | 5.540 ms | 7.991 ms | 914 | 5.64 ms | 0.77 ms | 221.6 MB |
| Set 3 | Coralline | 15,737,336/s | 16 Hz | 0.164 ms | 0.043 ms | 5.347 ms | 8.739 ms | 914 | 6.44 ms | 0.79 ms | 230.2 MB |
| Set 3 | Blooming | 16,368,456/s | 16 Hz | 0.214 ms | 0.030 ms | 6.696 ms | 7.998 ms | 914 | 5.53 ms | 0.69 ms | 223.1 MB |
| Set 3 | Flutter | 16,300,027/s | 16 Hz | 0.159 ms | 0.024 ms | 5.615 ms | 7.922 ms | 914 | 5.61 ms | 0.69 ms | 231.0 MB |
| Set 3 | Signals | 16,267,435/s | 16 Hz | 0.178 ms | 0.043 ms | 5.766 ms | 7.603 ms | 914 | 5.19 ms | 0.67 ms | 227.3 MB |
| Set 4 | Flutter | 16,399,960/s | 16 Hz | 0.166 ms | 0.025 ms | 5.572 ms | 7.608 ms | 914 | 5.80 ms | 0.71 ms | 222.1 MB |
| Set 4 | Blooming | 16,428,193/s | 16 Hz | 0.169 ms | 0.029 ms | 5.773 ms | 7.938 ms | 915 | 5.23 ms | 0.69 ms | 235.7 MB |
| Set 4 | Riverpod | 16,064,922/s | 16 Hz | 0.201 ms | 0.079 ms | 5.724 ms | 7.795 ms | 914 | 6.21 ms | 0.82 ms | 235.5 MB |
| Set 4 | Signals | 16,233,766/s | 16 Hz | 0.137 ms | 0.043 ms | 5.395 ms | 7.546 ms | 914 | 6.21 ms | 0.69 ms | 217.9 MB |
| Set 4 | Coralline | 15,736,293/s | 16 Hz | 0.143 ms | 0.040 ms | 5.370 ms | 8.757 ms | 914 | 6.06 ms | 0.83 ms | 245.4 MB |
| Set 5 | Coralline | 15,671,073/s | 16 Hz | 0.162 ms | 0.041 ms | 5.475 ms | 8.759 ms | 915 | 6.27 ms | 0.82 ms | 239.2 MB |
| Set 5 | Flutter | 16,334,239/s | 16 Hz | 0.181 ms | 0.023 ms | 6.501 ms | 8.659 ms | 914 | 5.73 ms | 0.70 ms | 222.0 MB |
| Set 5 | Blooming | 16,528,104/s | 17 Hz | 0.167 ms | 0.030 ms | 6.713 ms | 7.839 ms | 915 | 5.70 ms | 0.68 ms | 226.4 MB |
| Set 5 | Riverpod | 15,870,912/s | 16 Hz | 0.175 ms | 0.079 ms | 5.399 ms | 8.294 ms | 914 | 6.21 ms | 0.80 ms | 233.4 MB |
| Set 5 | Signals | 16,102,313/s | 16 Hz | 0.182 ms | 0.042 ms | 5.633 ms | 7.683 ms | 914 | 6.06 ms | 0.71 ms | 226.0 MB |
| Set 6 | Flutter | 16,333,157/s | 16 Hz | 0.138 ms | 0.024 ms | 5.484 ms | 6.817 ms | 914 | 6.15 ms | 0.69 ms | 218.2 MB |
| Set 6 | Riverpod | 15,937,179/s | 16 Hz | 0.197 ms | 0.082 ms | 5.539 ms | 8.395 ms | 915 | 5.52 ms | 0.82 ms | 233.7 MB |
| Set 6 | Signals | 17,193,971/s | 17 Hz | 0.211 ms | 0.032 ms | 6.500 ms | 7.213 ms | 914 | 5.41 ms | 0.66 ms | 218.6 MB |
| Set 6 | Coralline | 15,931,900/s | 16 Hz | 0.190 ms | 0.040 ms | 5.992 ms | 8.254 ms | 915 | 6.54 ms | 0.80 ms | 244.8 MB |
| Set 6 | Blooming | 16,393,986/s | 16 Hz | 0.144 ms | 0.028 ms | 5.458 ms | 7.384 ms | 915 | 5.18 ms | 0.67 ms | 232.2 MB |
| Set 7 | Blooming | 16,399,960/s | 16 Hz | 0.185 ms | 0.027 ms | 5.639 ms | 7.613 ms | 914 | 5.99 ms | 0.69 ms | 225.5 MB |
| Set 7 | Coralline | 15,533,916/s | 16 Hz | 0.210 ms | 0.041 ms | 6.018 ms | 8.906 ms | 914 | 5.98 ms | 0.82 ms | 244.5 MB |
| Set 7 | Flutter | 16,233,766/s | 16 Hz | 0.183 ms | 0.024 ms | 6.849 ms | 8.017 ms | 915 | 6.00 ms | 0.70 ms | 224.0 MB |
| Set 7 | Riverpod | 15,798,364/s | 16 Hz | 0.213 ms | 0.082 ms | 5.758 ms | 8.045 ms | 915 | 6.06 ms | 0.82 ms | 236.3 MB |
| Set 7 | Signals | 16,231,078/s | 16 Hz | 0.187 ms | 0.044 ms | 5.598 ms | 7.912 ms | 914 | 6.08 ms | 0.73 ms | 223.9 MB |
| Set 8 | Signals | 16,101,246/s | 16 Hz | 0.177 ms | 0.042 ms | 5.571 ms | 8.199 ms | 914 | 5.60 ms | 0.67 ms | 234.5 MB |
| Set 8 | Flutter | 16,334,239/s | 16 Hz | 0.159 ms | 0.025 ms | 5.662 ms | 7.457 ms | 914 | 5.74 ms | 0.70 ms | 225.5 MB |
| Set 8 | Coralline | 15,433,530/s | 15 Hz | 0.247 ms | 0.042 ms | 7.835 ms | 9.286 ms | 915 | 5.19 ms | 0.82 ms | 229.6 MB |
| Set 8 | Blooming | 16,400,504/s | 16 Hz | 0.192 ms | 0.030 ms | 6.403 ms | 7.706 ms | 914 | 5.65 ms | 0.68 ms | 222.1 MB |
| Set 8 | Riverpod | 15,703,684/s | 16 Hz | 0.225 ms | 0.080 ms | 7.021 ms | 7.688 ms | 914 | 5.76 ms | 0.83 ms | 236.4 MB |
| Set 9 | Flutter | 16,328,829/s | 16 Hz | 0.143 ms | 0.024 ms | 5.560 ms | 7.524 ms | 914 | 6.25 ms | 0.71 ms | 235.3 MB |
| Set 9 | Signals | 16,300,027/s | 16 Hz | 0.164 ms | 0.044 ms | 5.566 ms | 8.427 ms | 914 | 5.88 ms | 0.71 ms | 230.5 MB |
| Set 9 | Blooming | 16,432,547/s | 16 Hz | 0.207 ms | 0.028 ms | 5.913 ms | 7.185 ms | 914 | 5.98 ms | 0.69 ms | 223.8 MB |
| Set 9 | Coralline | 15,836,729/s | 16 Hz | 0.181 ms | 0.041 ms | 6.026 ms | 9.126 ms | 914 | 6.78 ms | 0.81 ms | 232.5 MB |
| Set 9 | Riverpod | 15,836,729/s | 16 Hz | 0.170 ms | 0.079 ms | 5.415 ms | 7.698 ms | 914 | 6.19 ms | 0.81 ms | 227.6 MB |
| Set 10 | Coralline | 15,736,814/s | 16 Hz | 0.169 ms | 0.042 ms | 5.603 ms | 8.589 ms | 915 | 5.96 ms | 0.86 ms | 245.8 MB |
| Set 10 | Flutter | 16,332,616/s | 16 Hz | 0.144 ms | 0.024 ms | 5.894 ms | 8.036 ms | 914 | 5.84 ms | 0.72 ms | 231.5 MB |
| Set 10 | Signals | 16,167,506/s | 16 Hz | 0.174 ms | 0.042 ms | 5.596 ms | 7.359 ms | 915 | 6.15 ms | 0.68 ms | 233.0 MB |
| Set 10 | Riverpod | 15,802,027/s | 16 Hz | 0.223 ms | 0.078 ms | 6.937 ms | 8.046 ms | 914 | 5.81 ms | 0.84 ms | 234.7 MB |
| Set 10 | Blooming | 16,466,223/s | 16 Hz | 0.189 ms | 0.029 ms | 5.861 ms | 7.752 ms | 914 | 6.06 ms | 0.71 ms | 220.6 MB |

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

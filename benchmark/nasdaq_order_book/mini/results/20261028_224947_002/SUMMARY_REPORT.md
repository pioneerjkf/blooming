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
### Scenario: Target 10,000,000 TPS — 10 set(s), shuffled order

Per-set lag statistics are aggregated across sets. **Mean, Median and Trimmed Mean are all shown** (Trimmed Mean drops the single lowest and highest set when sets >= 4); no value is hidden. Rows are sorted by Median (lower is better).

| Framework | Generator Ingest TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag Trimmed Mean | P99 Lag (median of sets) | Max Lag (worst sample) | UI Build | GPU Raster | RSS |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Blooming | 9,791,729/s | 979 Hz | 0.198 ms | 0.035 ms | 0.197 ms | 5.912 ms | 9.103 ms | 6.01 ms | 0.65 ms | 221.2 MB |
| Flutter | 9,805,184/s | 981 Hz | 0.213 ms | 0.036 ms | 0.217 ms | 5.979 ms | 8.245 ms | 6.03 ms | 0.66 ms | 226.0 MB |
| Coralline | 9,723,191/s | 973 Hz | 0.215 ms | 0.043 ms | 0.217 ms | 5.933 ms | 9.289 ms | 6.03 ms | 0.78 ms | 231.7 MB |
| Signals | 9,796,346/s | 980 Hz | 0.222 ms | 0.047 ms | 0.223 ms | 5.919 ms | 9.646 ms | 5.92 ms | 0.69 ms | 226.4 MB |
| Riverpod | 9,468,995/s | 947 Hz | 0.256 ms | 0.125 ms | 0.258 ms | 5.093 ms | 9.241 ms | 6.25 ms | 0.80 ms | 237.3 MB |

#### Individual Set Breakdown (raw, unfiltered)

| Set # | Framework | Generator TPS | Framework Update (Hz) | Lag Mean | Lag Median | Lag P99 | Lag Max | Samples | UI Build | GPU Raster | RSS |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Set 1 | Riverpod | 9,428,193/s | 943 Hz | 0.266 ms | 0.124 ms | 5.433 ms | 8.701 ms | 914 | 6.56 ms | 0.78 ms | 239.9 MB |
| Set 1 | Signals | 9,781,341/s | 978 Hz | 0.137 ms | 0.044 ms | 5.228 ms | 5.942 ms | 914 | 5.91 ms | 0.89 ms | 217.5 MB |
| Set 1 | Coralline | 9,727,312/s | 973 Hz | 0.131 ms | 0.040 ms | 5.588 ms | 6.050 ms | 914 | 5.89 ms | 0.80 ms | 226.5 MB |
| Set 1 | Flutter | 9,809,827/s | 981 Hz | 0.153 ms | 0.037 ms | 5.895 ms | 6.502 ms | 914 | 6.11 ms | 0.66 ms | 227.6 MB |
| Set 1 | Blooming | 9,766,047/s | 977 Hz | 0.120 ms | 0.034 ms | 0.849 ms | 7.976 ms | 914 | 5.83 ms | 0.63 ms | 217.7 MB |
| Set 2 | Signals | 9,783,977/s | 978 Hz | 0.133 ms | 0.043 ms | 4.836 ms | 7.716 ms | 914 | 5.68 ms | 0.65 ms | 228.2 MB |
| Set 2 | Flutter | 9,786,917/s | 979 Hz | 0.239 ms | 0.036 ms | 5.737 ms | 7.705 ms | 914 | 6.19 ms | 0.68 ms | 220.7 MB |
| Set 2 | Coralline | 9,737,269/s | 974 Hz | 0.193 ms | 0.044 ms | 5.928 ms | 6.346 ms | 914 | 6.21 ms | 0.77 ms | 236.3 MB |
| Set 2 | Riverpod | 9,452,377/s | 945 Hz | 0.283 ms | 0.126 ms | 5.192 ms | 8.252 ms | 914 | 5.83 ms | 0.78 ms | 236.5 MB |
| Set 2 | Blooming | 9,775,039/s | 978 Hz | 0.185 ms | 0.034 ms | 5.797 ms | 7.449 ms | 914 | 6.14 ms | 0.65 ms | 219.0 MB |
| Set 3 | Flutter | 9,809,833/s | 981 Hz | 0.194 ms | 0.036 ms | 6.021 ms | 6.900 ms | 914 | 6.07 ms | 0.64 ms | 234.5 MB |
| Set 3 | Blooming | 9,818,778/s | 982 Hz | 0.279 ms | 0.036 ms | 6.080 ms | 7.710 ms | 914 | 6.12 ms | 0.68 ms | 227.3 MB |
| Set 3 | Signals | 9,790,245/s | 979 Hz | 0.238 ms | 0.044 ms | 5.838 ms | 6.271 ms | 914 | 6.08 ms | 0.66 ms | 234.0 MB |
| Set 3 | Riverpod | 9,496,737/s | 950 Hz | 0.255 ms | 0.125 ms | 4.418 ms | 6.121 ms | 914 | 6.29 ms | 0.79 ms | 240.8 MB |
| Set 3 | Coralline | 9,725,673/s | 973 Hz | 0.265 ms | 0.042 ms | 5.890 ms | 6.653 ms | 914 | 5.88 ms | 0.78 ms | 230.2 MB |
| Set 4 | Coralline | 9,737,609/s | 974 Hz | 0.197 ms | 0.043 ms | 5.939 ms | 6.494 ms | 914 | 6.33 ms | 0.77 ms | 230.1 MB |
| Set 4 | Riverpod | 9,494,816/s | 949 Hz | 0.206 ms | 0.127 ms | 2.036 ms | 6.075 ms | 914 | 5.88 ms | 0.79 ms | 237.4 MB |
| Set 4 | Blooming | 9,820,103/s | 982 Hz | 0.181 ms | 0.035 ms | 5.938 ms | 7.509 ms | 914 | 6.17 ms | 0.65 ms | 225.5 MB |
| Set 4 | Flutter | 9,809,827/s | 981 Hz | 0.240 ms | 0.036 ms | 6.059 ms | 6.412 ms | 914 | 5.90 ms | 0.64 ms | 228.3 MB |
| Set 4 | Signals | 9,796,567/s | 980 Hz | 0.306 ms | 0.044 ms | 5.904 ms | 7.119 ms | 914 | 5.84 ms | 0.67 ms | 220.6 MB |
| Set 5 | Blooming | 9,812,140/s | 981 Hz | 0.200 ms | 0.037 ms | 6.143 ms | 8.561 ms | 914 | 6.33 ms | 0.69 ms | 227.9 MB |
| Set 5 | Flutter | 9,816,459/s | 982 Hz | 0.212 ms | 0.037 ms | 5.940 ms | 7.909 ms | 914 | 6.41 ms | 0.66 ms | 220.2 MB |
| Set 5 | Coralline | 9,687,935/s | 969 Hz | 0.183 ms | 0.043 ms | 5.845 ms | 8.057 ms | 914 | 6.08 ms | 0.79 ms | 237.4 MB |
| Set 5 | Riverpod | 9,463,363/s | 946 Hz | 0.251 ms | 0.128 ms | 5.255 ms | 6.436 ms | 914 | 6.39 ms | 0.81 ms | 241.1 MB |
| Set 5 | Signals | 9,808,177/s | 981 Hz | 0.268 ms | 0.057 ms | 6.062 ms | 8.438 ms | 914 | 6.07 ms | 0.67 ms | 221.3 MB |
| Set 6 | Coralline | 9,727,661/s | 973 Hz | 0.169 ms | 0.043 ms | 5.885 ms | 6.666 ms | 914 | 5.94 ms | 0.76 ms | 231.4 MB |
| Set 6 | Flutter | 9,802,538/s | 980 Hz | 0.205 ms | 0.036 ms | 5.984 ms | 6.961 ms | 914 | 6.28 ms | 0.68 ms | 222.5 MB |
| Set 6 | Blooming | 9,827,055/s | 983 Hz | 0.199 ms | 0.038 ms | 6.004 ms | 6.966 ms | 914 | 6.05 ms | 0.63 ms | 229.5 MB |
| Set 6 | Riverpod | 9,501,408/s | 950 Hz | 0.253 ms | 0.122 ms | 4.673 ms | 7.952 ms | 914 | 5.97 ms | 0.74 ms | 225.4 MB |
| Set 6 | Signals | 9,789,672/s | 979 Hz | 0.216 ms | 0.060 ms | 6.085 ms | 8.129 ms | 914 | 6.07 ms | 0.68 ms | 232.8 MB |
| Set 7 | Riverpod | 9,486,186/s | 949 Hz | 0.242 ms | 0.119 ms | 4.993 ms | 8.617 ms | 914 | 6.29 ms | 0.79 ms | 241.9 MB |
| Set 7 | Flutter | 9,781,658/s | 978 Hz | 0.186 ms | 0.033 ms | 5.809 ms | 6.155 ms | 914 | 5.64 ms | 0.63 ms | 222.0 MB |
| Set 7 | Blooming | 9,776,372/s | 978 Hz | 0.203 ms | 0.033 ms | 5.785 ms | 6.464 ms | 914 | 5.75 ms | 0.64 ms | 216.6 MB |
| Set 7 | Coralline | 9,726,658/s | 973 Hz | 0.242 ms | 0.041 ms | 5.937 ms | 8.229 ms | 914 | 5.77 ms | 0.77 ms | 226.7 MB |
| Set 7 | Signals | 9,797,899/s | 980 Hz | 0.216 ms | 0.041 ms | 5.721 ms | 8.122 ms | 914 | 5.87 ms | 0.70 ms | 218.3 MB |
| Set 8 | Riverpod | 9,435,131/s | 944 Hz | 0.273 ms | 0.125 ms | 5.418 ms | 9.241 ms | 914 | 6.21 ms | 0.80 ms | 238.1 MB |
| Set 8 | Signals | 9,809,502/s | 981 Hz | 0.232 ms | 0.059 ms | 6.108 ms | 9.646 ms | 914 | 5.84 ms | 0.65 ms | 228.8 MB |
| Set 8 | Flutter | 9,807,183/s | 981 Hz | 0.241 ms | 0.036 ms | 6.043 ms | 7.301 ms | 914 | 5.91 ms | 0.66 ms | 228.5 MB |
| Set 8 | Coralline | 9,721,044/s | 972 Hz | 0.288 ms | 0.048 ms | 6.152 ms | 8.823 ms | 914 | 5.90 ms | 0.73 ms | 234.0 MB |
| Set 8 | Blooming | 9,773,661/s | 977 Hz | 0.210 ms | 0.033 ms | 5.956 ms | 7.553 ms | 914 | 5.87 ms | 0.66 ms | 216.3 MB |
| Set 9 | Flutter | 9,812,809/s | 981 Hz | 0.218 ms | 0.036 ms | 6.052 ms | 6.286 ms | 914 | 5.87 ms | 0.67 ms | 226.4 MB |
| Set 9 | Coralline | 9,721,026/s | 972 Hz | 0.284 ms | 0.041 ms | 5.994 ms | 8.683 ms | 914 | 5.95 ms | 0.79 ms | 226.7 MB |
| Set 9 | Blooming | 9,776,695/s | 978 Hz | 0.193 ms | 0.033 ms | 5.854 ms | 9.103 ms | 914 | 5.89 ms | 0.63 ms | 215.5 MB |
| Set 9 | Signals | 9,803,863/s | 980 Hz | 0.254 ms | 0.050 ms | 5.935 ms | 8.365 ms | 914 | 5.82 ms | 0.66 ms | 229.8 MB |
| Set 9 | Riverpod | 9,427,180/s | 943 Hz | 0.289 ms | 0.123 ms | 6.009 ms | 8.077 ms | 914 | 6.40 ms | 0.92 ms | 230.1 MB |
| Set 10 | Signals | 9,802,220/s | 980 Hz | 0.221 ms | 0.058 ms | 6.168 ms | 8.225 ms | 914 | 6.04 ms | 0.68 ms | 232.7 MB |
| Set 10 | Blooming | 9,771,402/s | 977 Hz | 0.206 ms | 0.035 ms | 5.887 ms | 7.517 ms | 914 | 5.94 ms | 0.67 ms | 216.9 MB |
| Set 10 | Coralline | 9,719,719/s | 972 Hz | 0.201 ms | 0.050 ms | 6.171 ms | 9.289 ms | 914 | 6.31 ms | 0.80 ms | 237.8 MB |
| Set 10 | Flutter | 9,814,790/s | 981 Hz | 0.244 ms | 0.036 ms | 5.973 ms | 8.245 ms | 914 | 5.91 ms | 0.67 ms | 229.3 MB |
| Set 10 | Riverpod | 9,504,554/s | 950 Hz | 0.239 ms | 0.126 ms | 2.217 ms | 8.690 ms | 915 | 6.67 ms | 0.83 ms | 242.2 MB |

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

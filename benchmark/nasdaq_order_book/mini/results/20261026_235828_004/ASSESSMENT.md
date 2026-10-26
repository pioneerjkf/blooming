# NASDAQ Order Book Benchmark: Results and Assessment

## Executive summary

The October 26, 2026 run compares main-isolate event-loop responsiveness while five Flutter implementations receive batched order-book updates. It does **not** measure sustained processing of one billion events per second. The configured target is one billion TPS, but the generator simulates at most 200 ticks per 1 ms batch and adds the remaining count arithmetically. Treat these results as a responsiveness observation under this capped workload, not as a throughput ranking.

This run was conducted at 60 Hz with other processes closed. Signals' median lag is 0.044 ms and mean lag is 0.139 ms, but its median of per-set P99 values is 4.071 ms; eight of ten sets have P99 above 3 ms. Its typical lag remains low while its upper tail is elevated in most sets in this run. This is notably different from the adjacent 23:20 run, where five of ten Signals sets exceeded 3 ms and the median-of-set-P99 was 2.662 ms. The run supports recurring but variable Signals tail latency, not a fixed P99 level.

Blooming has the lowest median lag (0.041 ms) and a median-of-set-P99 below 1 ms, while Flutter's P99 rises sharply relative to the adjacent run. Riverpod again has a higher mean and median than the other implementations. These shifts across two runs prevent a stable overall ranking or a causal conclusion.

## Run configuration

- Run: `20261026_235828_004` (`2026-10-26 23:58:28`, Asia/Seoul)
- Machine: MacBook Pro (`Mac17,7`), Apple M5 Max, 18 CPU cores, 36 GB memory
- Display refresh rate: 60 Hz
- Other processes: closed during the benchmark run
- OS: macOS 27.0.1 (Build 26A434), ARM64
- Toolchain: Flutter 3.47.6 stable (`5fc346839b5d0eef006ed8404392afb4dfae428d`), Dart 3.13.5, Xcode 27.1
- Execution: Flutter Driver, profile build; scroll animation disabled, static center viewport
- Scenario: configured target 1,000,000,000 TPS (not verified throughput); 30 seconds per run, 10 shuffled sets per framework
- Event-loop probe: a `Timer.periodic` callback every 33 ms schedules `Timer.run`; the elapsed time from the periodic callback to the queued callback is recorded
- Samples: 914 lag samples per framework per set

The benchmark JSON records the run timestamp, macOS/Dart environment, mode, set count, scenario, and animation setting. Display refresh rate, host details, toolchain details, and the process-closure condition are part of the run context recorded here.

## Archived artifacts

This run's [raw matrix](benchmark_matrix.json), [CSV](benchmark_summary.csv), and [generated report](SUMMARY_REPORT.md) are archived alongside this assessment. Compare with the adjacent [23:20 run assessment](../20261026_232008_004/ASSESSMENT.md), the earlier [60 Hz repeat assessment](../20261026_221301_003/ASSESSMENT.md), and the [benchmark overview](../../README.md).

## Aggregated results

The table reports the arithmetic mean of per-run means, the median of per-run medians, the trimmed mean of per-run means (dropping the lowest and highest set means), the median of per-run P99 values, the worst individual lag sample, and mean RSS. Lower is better for lag; these are not throughput metrics.

| Framework | Lag mean | Lag median | Lag trimmed mean | P99 lag (median of sets) | Max lag | UI build | GPU raster | RSS |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Blooming | 0.139 ms | **0.041 ms** | 0.138 ms | 0.806 ms | 5.086 ms | 4.11 ms | 0.70 ms | 194.6 MB |
| Flutter | 0.154 ms | 0.042 ms | 0.156 ms | 4.035 ms | 4.921 ms | 4.12 ms | 0.70 ms | 195.9 MB |
| Coralline | 0.145 ms | 0.043 ms | 0.141 ms | 2.418 ms | 4.819 ms | 4.23 ms | 0.83 ms | 205.3 MB |
| Signals | 0.139 ms | 0.044 ms | 0.141 ms | 4.071 ms | 4.809 ms | 4.07 ms | 0.69 ms | **193.9 MB** |
| Riverpod | 0.469 ms | 0.251 ms | 0.469 ms | 3.475 ms | **4.463 ms** | **3.85 ms** | 0.78 ms | 203.2 MB |

Bold values mark the lowest value in a column. UI build and GPU raster were collected from only a few frames and are not suitable for ranking in this run.

## Interpretation

### Event-loop responsiveness and tail latency

- Median lag is close for Blooming, Flutter, Coralline, and Signals (0.041–0.044 ms). This small spread does not establish a meaningful real-world lead.
- Signals has a median-of-set-P99 of 4.071 ms; eight of ten set P99 values exceed 3 ms. The two exceptions are 0.301 ms and 0.360 ms, while the remaining eight range from 3.166 to 4.195 ms. This is a high-tail result in most sets, despite the low median lag.
- Flutter also has a high median-of-set-P99 (4.035 ms), with eight of ten sets above 3 ms. Blooming's median-of-set-P99 is 0.806 ms, though four sets exceed 3 ms. Thus the aggregate statistic does not describe every set.
- Coralline's median-of-set-P99 is 2.418 ms, with five sets above 3 ms. Riverpod's median-of-set-P99 is 3.475 ms, with seven sets above 3 ms; it also has the highest mean and median lag in this run.
- Signals' worst individual sample is 4.809 ms, close to 4.651 ms in the adjacent run. A high P99 distribution and a similar maximum across runs indicate recurring long-delay observations, but do not identify their cause.
- Event-loop lag is a responsiveness signal, not a direct measurement of click-to-handler latency, successful input delivery, or data correctness.

### Comparison with the adjacent run

| Framework | Lag median, 23:20 → 23:58 | P99 lag (median of sets), 23:20 → 23:58 | Sets with P99 > 3 ms, 23:20 → 23:58 |
| --- | ---: | ---: | ---: |
| Flutter | 0.042 → 0.042 ms | 0.661 → 4.035 ms | 4 → 8 |
| Blooming | 0.042 → 0.041 ms | 4.069 → 0.806 ms | 8 → 4 |
| Signals | 0.043 → 0.044 ms | 2.662 → 4.071 ms | 5 → 8 |
| Coralline | 0.044 → 0.043 ms | 1.004 → 2.418 ms | 4 → 5 |
| Riverpod | 0.247 → 0.251 ms | 3.791 → 3.475 ms | 7 → 7 |

Both runs used the same stated 60 Hz environment with other processes closed, but P99 changed substantially for Flutter, Blooming, and Signals. The median lag values remained nearly unchanged for those frameworks. Signals' high-tail behavior recurred in this run and affected more sets, but the previous and current P99 summaries differ enough that the magnitude is not stable. Because the same general P99 volatility appears in other frameworks too, these two runs alone cannot establish whether the swings are framework-specific or reflect shared run-to-run factors.

Across the four 60 Hz runs available for Signals, the median-of-set-P99 values were 3.693 ms (6/10 sets above 3 ms), 0.342 ms (2/10), 2.662 ms (5/10), and 4.071 ms (8/10). The high tail is recurrent but variable: it is not a single isolated result, and it is not consistently present in most sets. Signals' mean and median lag remain in a much narrower range across these runs, reinforcing that the variability is concentrated in the upper tail.

### The one-billion-TPS target is not achieved throughput

The generator runs a 1 ms timer and computes a target batch size. It simulates at most 200 ticks in that batch; the remaining count is added arithmetically. At a configured target of one billion TPS, a nominal batch is about one million ticks, so at most 200 are simulated and the rest are not processed as individual events. The same generator logic is used by all five framework variants, so this is a common limitation rather than a framework-specific shortcut.

Consequently, `Sustained_TPS`, total tick counts, and achievement percentages from the raw CSV/JSON must not be described as actual framework throughput. They are based on the configured batch count, including ticks that were not individually processed.

### Probe, rendering, and workload limitations

- The probe timestamps execution inside the `Timer.periodic` callback, then measures the delay until its `Timer.run` callback executes. If the periodic callback itself wakes late because the event loop was blocked, that preceding delay is not directly included. This probe can therefore understate some forms of event-loop stall.
- The test does not directly measure click-to-handler latency, input responsiveness, missed frame deadlines, or whether the displayed order book is stale.
- Scroll animation is disabled and the viewport is static. The recorded FPS (0.4) and 0% jank rate do not establish rendering performance at 60 Hz or prove stutter-free behavior; the run captured only a few frames.
- The test uses batched updates. Blooming and Signals wrap portions of their state changes in batching APIs; other implementations use their own notification paths without the same explicit wrapper. This can be a valid comparison of idiomatic framework implementations, but it is not a comparison with identical notification policy. Report the policy, and consider separate uniform-policy and best-practice modes.
- The current workload does not validate event loss, duplication, ordering, queue growth, recovery after overload, or final-state equivalence.
- Results are from one OS/runtime configuration and one machine. They are not generalizable to other devices, operating systems, or release/AOT builds.

## What this run supports

This run supports a narrow observation: under its capped, batched workload, Signals' median lag remains low, while its per-set P99 is above 3 ms in eight of ten sets. The adjacent run also showed Signals tail spikes, but fewer sets were affected. Flutter's P99 also rises sharply between the two runs, while Blooming's falls, and median lags stay similar. These results support the conclusion that tail-lag outcomes vary substantially between runs; they do not establish a stable framework ranking, a cause, or direct user-input failure.

## Recommended next benchmark

1. Repeat each run under the same 60 Hz and other-processes-closed condition, recording the exact display hosting the benchmark window and the command line.
2. Preserve every per-set P99 and report its range and the number of sets above predeclared thresholds, alongside the median across sets.
3. Replay the same deterministic event trace through each pipeline and count only events whose state updates have completed.
4. Verify event count, order, and final order-book checksum; record queue depth, backlog growth, and recovery after overload.
5. Measure input-to-handler latency and frame deadlines while the stream is active; retain event-loop lag as a complementary signal, but measure timer lateness against an expected deadline.
6. Run both a uniform notification-policy scenario and a best-practice-per-framework scenario. Document batching and subscription topology for each.

## Benchmarking and assessment process

When I asked ChatGPT to evaluate the results of a benchmark conducted with Gemini 3.x's assistance, I found its assessment unusually cold and unsparing. That impression led me to assign the work to separate roles: Gemini 3.x supported running the benchmark, while ChatGPT (GPT-6) took the lead in analyzing the results and writing the overall assessment.

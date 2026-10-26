# NASDAQ Order Book Benchmark: Results and Assessment

## Executive summary

The October 26, 2026 run compares main-isolate event-loop responsiveness while five Flutter implementations receive batched order-book updates. It does **not** measure sustained processing of one billion events per second. The configured target is one billion TPS, but the generator simulates at most 200 ticks per 1 ms batch and adds the remaining count arithmetically. Treat these results as a responsiveness observation under this capped workload, not as a throughput ranking.

This run was conducted at 60 Hz with other processes closed. Signals' median lag is low (0.043 ms), and its mean lag is 0.124 ms. Its median of per-set P99 values is 2.662 ms; five of ten sets have P99 above 3 ms. The result therefore shows low typical lag alongside intermittent high-tail sets. Blooming and Riverpod also have elevated P99 values in this run. The measurements do not establish a single overall winner or explain the outliers.

## Run configuration

- Run: `20261026_232008_004` (`2026-10-26 23:20:08`, Asia/Seoul)
- Machine: MacBook Pro (`Mac17,7`), Apple M5 Max, 18 CPU cores, 36 GB memory
- Display refresh rate: 60 Hz
- Other processes: closed during the benchmark run
- OS: macOS 27.0.1 (Build 26A434), ARM64
- Toolchain: Flutter 3.47.6 stable (`5fc346839b5d0eef006ed8404392afb4dfae428d`), Dart 3.13.5, Xcode 27.1
- Execution: Flutter Driver, profile build; scroll animation disabled, static center viewport
- Scenario: configured target 1,000,000,000 TPS (not verified throughput); 30 seconds per run, 10 shuffled sets per framework
- Event-loop probe: a `Timer.periodic` callback every 33 ms schedules `Timer.run`; the elapsed time from the periodic callback to the queued callback is recorded
- Samples: about 914 lag samples per framework per set; one Coralline set contains 915 samples

The benchmark JSON records the run timestamp, macOS/Dart environment, mode, set count, scenario, and animation setting. Display refresh rate, host details, toolchain details, and the process-closure condition are part of the run context recorded here.

## Archived artifacts

This run's [raw matrix](benchmark_matrix.json), [CSV](benchmark_summary.csv), and [generated report](SUMMARY_REPORT.md) are archived alongside this assessment. Compare with the adjacent [23:58 run assessment](../20261026_235828_004/ASSESSMENT.md), the earlier [60 Hz repeat assessment](../20261026_221301_003/ASSESSMENT.md), and the [benchmark overview](../../README.md).

## Aggregated results

The table reports the arithmetic mean of per-run means, the median of per-run medians, the trimmed mean of per-run means (dropping the lowest and highest set means), the median of per-run P99 values, the worst individual lag sample, and mean RSS. Lower is better for lag; these are not throughput metrics.

| Framework | Lag mean | Lag median | Lag trimmed mean | P99 lag (median of sets) | Max lag | UI build | GPU raster | RSS |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Blooming | 0.155 ms | 0.042 ms | 0.153 ms | 4.069 ms | 4.852 ms | 4.10 ms | 0.69 ms | 194.2 MB |
| Flutter | 0.120 ms | 0.042 ms | 0.116 ms | 0.661 ms | 4.967 ms | 4.18 ms | 0.71 ms | 194.9 MB |
| Signals | 0.124 ms | 0.043 ms | 0.124 ms | 2.662 ms | 4.651 ms | 4.07 ms | 0.69 ms | 194.6 MB |
| Coralline | 0.153 ms | 0.044 ms | 0.147 ms | 1.004 ms | 4.800 ms | 4.17 ms | 0.83 ms | 206.6 MB |
| Riverpod | 0.477 ms | 0.247 ms | 0.478 ms | 3.791 ms | 4.351 ms | 3.86 ms | 0.77 ms | 208.5 MB |

UI build and GPU raster were collected from only a few frames and are not suitable for ranking in this run.

## Interpretation

### Event-loop responsiveness and tail latency

- Flutter, Blooming, and Signals have close median lag values (0.042–0.043 ms); Coralline is also close at 0.044 ms. These small differences do not establish a meaningful real-world lead.
- Signals' per-set P99 values range from 0.324 to 4.184 ms. Five of ten sets exceed 3 ms. Its aggregate median-of-set-P99 (2.662 ms) summarizes a mixed distribution and should be read with the per-set values.
- Blooming has a median-of-set-P99 of 4.069 ms, with eight of ten set P99 values above 3 ms. Flutter's aggregate P99 is 0.661 ms, but four sets exceed 3 ms. This shows why a median across sets alone can conceal a subset of high-tail runs.
- Coralline's median-of-set-P99 is 1.004 ms, while four sets exceed 3 ms. Riverpod has both higher average/median lag and a median-of-set-P99 of 3.791 ms; seven sets exceed 3 ms.
- The worst individual sample ranges from 4.351 to 4.967 ms across frameworks. A low median or aggregate P99 does not mean that no long delay occurred.
- Event-loop lag is a responsiveness signal, not a direct measurement of click-to-handler latency, successful input delivery, or data correctness.

### Comparison with the adjacent run

| Framework | P99 lag, 23:20 run | P99 lag, 23:58 run |
| --- | ---: | ---: |
| Flutter | 0.661 ms | 4.035 ms |
| Blooming | 4.069 ms | 0.806 ms |
| Signals | 2.662 ms | 4.071 ms |
| Coralline | 1.004 ms | 2.418 ms |
| Riverpod | 3.791 ms | 3.475 ms |

Both runs used the same stated 60 Hz environment with other processes closed, yet the per-framework P99 ordering changes substantially. Signals rises from 2.662 to 4.071 ms; Blooming falls from 4.069 to 0.806 ms; Flutter moves in the opposite direction. Their median lag values remain close across the two runs. This pattern indicates considerable run-to-run variation in the tails, but does not identify whether it comes from workload timing, framework scheduling, the runtime, or other system activity.

Across the four 60 Hz runs available for Signals, the median-of-set-P99 values were 3.693 ms (6/10 sets above 3 ms), 0.342 ms (2/10), 2.662 ms (5/10), and 4.071 ms (8/10). The high tail is therefore recurrent but variable: it is not a single isolated result, and it is not consistently present in most sets. Signals' mean and median lag remain in a much narrower range across these runs, reinforcing that the variability is concentrated in the upper tail.

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

This run supports a narrow observation: under its capped, batched workload, typical median event-loop lag is similar for Flutter, Blooming, Signals, and Coralline, while Riverpod's average and median are higher. Several frameworks have sets with elevated P99 values, and their aggregate P99 ranking changes in the adjacent run despite the stated same 60 Hz, other-processes-closed condition. These results motivate more repeated runs and direct input/frame measurements; they do not establish a stable P99 ranking or identify the cause of tail variation.

## Recommended next benchmark

1. Repeat each run under the same 60 Hz and other-processes-closed condition, and record the exact window/display and command line.
2. Preserve every per-set P99 and report its range and the number of sets above predeclared thresholds, alongside the median across sets.
3. Replay the same deterministic event trace through each pipeline and count only events whose state updates have completed.
4. Verify event count, order, and final order-book checksum; record queue depth, backlog growth, and recovery after overload.
5. Measure input-to-handler latency and frame deadlines while the stream is active; retain event-loop lag as a complementary signal, but measure timer lateness against an expected deadline.
6. Run both a uniform notification-policy scenario and a best-practice-per-framework scenario. Document batching and subscription topology for each.

## Benchmarking and assessment process

When I asked ChatGPT to evaluate the results of a benchmark conducted with Gemini 3.x's assistance, I found its assessment unusually cold and unsparing. That impression led me to assign the work to separate roles: Gemini 3.x supported running the benchmark, while ChatGPT (GPT-6) took the lead in analyzing the results and writing the overall assessment.

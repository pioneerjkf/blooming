# NASDAQ Order Book Benchmark: Results and Assessment

## Executive summary

The October 26, 2026 run compares main-isolate event-loop responsiveness while five Flutter implementations receive batched order-book updates. It does **not** measure sustained processing of one billion events per second. The configured target is one billion TPS, but the generator simulates at most 200 ticks per 1 ms batch and adds the remaining count arithmetically. Treat these results as a responsiveness observation under this capped workload, not as a throughput ranking.

This is a repeat of the earlier 60 Hz run, prompted by concern that Signals had shown unusually high set-level P99 lag. That result did **not** reproduce at the same scale: Signals' median of set-level P99 values fell from 3.693 ms to 0.342 ms, while its mean lag remained 0.118 ms and its median lag changed from 0.044 ms to 0.042 ms. In the new run, 8 of 10 Signals sets had P99 below 0.4 ms, while two sets had P99 above 4 ms. The earlier result therefore should not be treated as a stable Signals characteristic; this run also does not show that occasional tail delays have disappeared.

Across this run, Flutter, Blooming, Signals, and Coralline have similar median lag (0.038–0.043 ms). Riverpod again has a higher mean and median lag. Coralline's set-level P99 remains relatively high, while Signals' P99 is low in most sets but has two pronounced outliers. No overall winner or causal explanation is established.

## Run configuration

- Run: `20261026_221301_003` (`2026-10-26 22:13:01`, Asia/Seoul)
- Machine: MacBook Pro (`Mac17,7`), Apple M5 Max, 18 CPU cores, 36 GB memory
- Display environment: 60 Hz
- OS: macOS 27.0.1 (Build 26A434), ARM64
- Toolchain: Flutter 3.47.6 stable (`5fc346839b5d0eef006ed8404392afb4dfae428d`), Dart 3.13.5, Xcode 27.1
- Execution: Flutter Driver, profile build; scroll animation disabled, static center viewport
- Scenario: configured target 1,000,000,000 TPS (not verified throughput); 30 seconds per run, 10 shuffled sets per framework
- Event-loop probe: a `Timer.periodic` callback every 33 ms schedules `Timer.run`; the elapsed time from the periodic callback to the queued callback is recorded
- Samples: 914 lag samples per framework per set, with one set containing 915 Coralline samples

The result JSON records the timestamp, macOS/Dart environment, execution mode, set count, scenario, and animation setting. It does not record the display refresh rate, machine model, Flutter/Xcode versions, or exact command line; the 60 Hz and host/toolchain details above describe the environment used for this run.

## Archived artifacts

This run's [raw matrix](benchmark_matrix.json), [CSV](benchmark_summary.csv), and [generated report](SUMMARY_REPORT.md) are archived alongside this assessment. Compare with the earlier [60 Hz run assessment](../20261026_164352_002/ASSESSMENT.md), the later [120 Hz run assessment](../20261026_201905_001/ASSESSMENT.md), and the [benchmark overview](../../README.md).

## Aggregated results

The table reports the arithmetic mean of per-run means, the median of per-run medians, the trimmed mean of per-run means (dropping the lowest and highest set means), the median of per-run P99 values, the worst individual lag sample, and mean RSS. Lower is better for lag; these are not throughput metrics.

| Framework | Lag mean | Lag median | Lag trimmed mean | P99 lag (median of sets) | Max lag | UI build | GPU raster | RSS |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Blooming | 0.137 ms | **0.038 ms** | 0.133 ms | 0.842 ms | 4.675 ms | 4.11 ms | 0.69 ms | **192.9 MB** |
| Flutter | 0.125 ms | 0.040 ms | 0.122 ms | 0.787 ms | 4.739 ms | 4.08 ms | 0.69 ms | 196.0 MB |
| Signals | **0.118 ms** | 0.042 ms | **0.111 ms** | **0.342 ms** | 4.864 ms | 4.11 ms | 0.69 ms | 195.8 MB |
| Coralline | 0.146 ms | 0.043 ms | 0.145 ms | 2.429 ms | 5.429 ms | 4.21 ms | 0.83 ms | 204.3 MB |
| Riverpod | 0.472 ms | 0.246 ms | 0.471 ms | 3.373 ms | **4.488 ms** | **3.88 ms** | 0.77 ms | 203.7 MB |

Bold values identify the lowest value in the column. UI build and GPU raster were collected from only a few frames and are not suitable for ranking in this run.

## Interpretation

### Signals and the repeated 60 Hz result

| Signals metric | Earlier 60 Hz run | This 60 Hz run |
| --- | ---: | ---: |
| Mean lag | 0.118 ms | 0.118 ms |
| Median lag | 0.044 ms | 0.042 ms |
| Median of set-level P99 | 3.693 ms | 0.342 ms |
| Sets with P99 above 3 ms | 6 of 10 | 2 of 10 |
| Worst individual sample | 4.963 ms | 4.864 ms |

The aggregate mean and median are very similar across the two runs, but the distribution of set-level P99 values is not. In the earlier run, six Signals sets had P99 values above 3 ms; in this run only sets 4 and 10 did (4.307 ms and 4.100 ms). The other eight sets ranged from 0.314 to 0.362 ms. This is strong evidence that the earlier high aggregate P99 was not consistently reproduced. It is not evidence that the two outlier sets are harmless or that the framework never has tail delays.

The worst individual Signals sample remained near 4.9 ms in both runs. A low median-of-set-P99 can coexist with occasional high-lag sets, so the aggregate should be read together with the raw per-set values and maximum. These measurements do not identify why the two runs differed.

### Cross-framework responsiveness

- Blooming has the lowest median lag (0.038 ms); Flutter (0.040 ms), Signals (0.042 ms), and Coralline (0.043 ms) are close. These small gaps do not establish a meaningful real-world lead.
- Signals has the lowest mean lag (0.118 ms) and the lowest median-of-set-P99 (0.342 ms), but two of its ten sets have P99 above 4 ms. Both the typical sets and the outlier sets matter to the interpretation.
- Coralline's median-of-set-P99 is 2.429 ms, and five of its ten sets have P99 above 3 ms. Its tail values are elevated in both 60 Hz runs (2.124 ms previously, 2.429 ms now), making this pattern more repeatable than the earlier Signals result, though still limited to two runs.
- Riverpod's mean lag is 0.472 ms and median lag is 0.246 ms, higher than the other implementations in this run. Its result is consistent with reduced main-isolate responsiveness under this particular update workload, but does not establish the cause or generalize to every application.
- Flutter and Blooming have median-of-set-P99 values below 1 ms in this run. Their worst individual samples are still around 4.7 ms, so the aggregate P99 does not imply that no long delays occurred.
- Event-loop lag is a responsiveness signal, not a guarantee that input is handled promptly or that data is processed correctly. Low lag alone does not prove that events were applied, ordered, or rendered correctly.

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

This run supports a narrow observation: under its capped, batched update workload, Signals' average and median event-loop lag are similar to its earlier 60 Hz run, but the earlier high median-of-set-P99 result does not reproduce. Two of ten Signals sets still show P99 above 4 ms, and the worst individual sample remains close to 4.9 ms. Coralline's elevated set-level P99 and Riverpod's higher mean and median recur in this run. These observations motivate more repeated runs and direct input/frame measurements; they do not prove which framework best handles a real high-rate socket pipeline or guarantees responsive input.

## Recommended next benchmark

1. Repeat the 60 Hz run several more times with the same deterministic event trace, retaining each set's raw lag samples and execution order.
2. Report the distribution of per-set P99 values (including ranges and counts above a predeclared threshold), not only their median.
3. Replay the same deterministic event trace through each state pipeline and count only events whose state updates have completed.
4. Verify event count, order, and final order-book checksum for every implementation; record queue depth, backlog growth, and recovery after overload.
5. Measure input-to-handler latency and frame deadlines while the stream is active; retain event-loop lag as a complementary signal, but measure timer lateness against an expected deadline.
6. Run both a uniform notification-policy scenario and a best-practice-per-framework scenario. Document batching and subscription topology for each.
7. Record the exact display hosting the benchmark window, command line, machine, OS, SDKs, build mode, and power/thermal conditions.

## Benchmarking and assessment process

When I asked ChatGPT to evaluate the results of a benchmark conducted with Gemini 3.x's assistance, I found its assessment unusually cold and unsparing. That impression led me to assign the work to separate roles: Gemini 3.x supported running the benchmark, while ChatGPT (GPT-6) took the lead in analyzing the results and writing the overall assessment.

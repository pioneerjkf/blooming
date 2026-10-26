# NASDAQ Order Book Benchmark: Results and Assessment

## Executive summary

The October 26, 2026 run compares main-isolate event-loop responsiveness while five Flutter implementations receive batched order-book updates. It does **not** measure sustained processing of one billion events per second. The configured target is one billion TPS, but the generator simulates at most 200 ticks per 1 ms batch and adds the remaining count arithmetically. Treat these results as a responsiveness observation under this capped workload, not as a throughput ranking.

Flutter, Blooming, Coralline, and Signals have similar aggregate median lag in this run, between 0.058 and 0.063 ms. Riverpod's median and mean are higher under this workload. The set-level P99 values are close across all five implementations, between 3.336 and 3.459 ms. These results do not establish a decisive overall winner or explain the differences.

This run was performed with the MacBook Pro built-in display at 120 Hz, with the external 60 Hz display also connected. It is useful as a record of event-loop behavior in that environment, but scroll animation was disabled. The run therefore does not test 120 Hz rendering, input-to-handler latency, or missed frame deadlines.

## Run configuration

- Run: `20261026_201905_001` (`2026-10-26 20:19:05`, Asia/Seoul)
- Machine: MacBook Pro (`Mac17,7`), Apple M5 Max, 18 CPU cores, 36 GB memory
- Displays: built-in MacBook Pro display at 120 Hz; external 60 Hz display connected
- OS: macOS 27.0.1 (Build 26A434), ARM64
- Toolchain: Flutter 3.47.6 stable (`5fc346839b5d0eef006ed8404392afb4dfae428d`), Dart 3.13.5, Xcode 27.1
- Execution: Flutter Driver, profile build; scroll animation disabled, static center viewport
- Scenario: configured target 1,000,000,000 TPS (not verified throughput); 30 seconds per run, 10 shuffled sets per framework
- Event-loop probe: a `Timer.periodic` callback every 33 ms schedules `Timer.run`; the elapsed time from the periodic callback to the queued callback is recorded
- Samples: 914 lag samples per framework per set

The benchmark result JSON records macOS, Dart, run mode, set count, scenario, and animation setting. Machine, display, Flutter, and Xcode details are recorded in [RUN_METADATA.md](RUN_METADATA.md) based on the benchmark environment.

## Archived artifacts

This run's [raw matrix](benchmark_matrix.json), [CSV](benchmark_summary.csv), and [generated report](SUMMARY_REPORT.md) are archived alongside this assessment. The [run metadata](RUN_METADATA.md) records the host and display setup. For comparison, see the earlier [60 Hz run assessment](../20261026_164352_002/ASSESSMENT.md) and the [benchmark overview](../../README.md).

## Aggregated results

The table reports the arithmetic mean of per-run means, the median of per-run medians, the trimmed mean of per-run means (dropping the lowest and highest set means), the median of per-run P99 values, the worst individual lag sample, and mean RSS. Lower lag is better; these are not throughput metrics.

| Framework | Lag mean | Lag median | Lag trimmed mean | P99 lag (median of sets) | Max lag | UI build | GPU raster | RSS mean |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Flutter | 0.180 ms | **0.058 ms** | 0.181 ms | 3.376 ms | **3.919 ms** | 3.37 ms | 0.60 ms | **200.1 MB** |
| Signals | **0.155 ms** | 0.061 ms | **0.157 ms** | 3.418 ms | 4.138 ms | 3.40 ms | 0.60 ms | 203.1 MB |
| Coralline | 0.175 ms | 0.062 ms | 0.174 ms | 3.459 ms | 4.440 ms | 3.48 ms | 0.72 ms | 208.5 MB |
| Blooming | 0.188 ms | 0.063 ms | 0.189 ms | 3.393 ms | 4.099 ms | **3.35 ms** | **0.59 ms** | 200.2 MB |
| Riverpod | 0.500 ms | 0.316 ms | 0.500 ms | **3.336 ms** | 4.274 ms | 3.41 ms | 0.72 ms | 206.4 MB |

Bold values identify the lowest value in the column. UI build and GPU raster were collected from only a few frames and are not suitable for ranking in this run. Values follow the benchmark's three-decimal display rounding.

## Interpretation

### Responsiveness and tail latency

- Flutter, Signals, Coralline, and Blooming have close median lag values, from 0.059 to 0.063 ms. This small spread does not establish a meaningful real-world lead.
- Signals has the lowest aggregate mean lag (0.155 ms) and a median-of-set-P99 of 3.419 ms. Its P99 values range from 3.226 to 3.506 ms across the ten sets. The relatively narrow range in this run is an observation about these samples, not evidence about other workloads.
- Riverpod's aggregate mean and median lag are higher than those of the other implementations in this run. The result is consistent with reduced main-isolate responsiveness under this particular update workload, but does not establish the cause or generalize to every application.
- The median-of-set-P99 values are close across frameworks (3.336–3.459 ms). They do not show a large tail-latency separation in this run.
- Event-loop lag is a responsiveness signal, not a guarantee that input is handled promptly or that data is processed correctly. Low lag alone does not prove that events were applied, ordered, or rendered correctly.

### Comparison with the earlier 60 Hz run

| Framework | Lag median, 60 Hz → 120 Hz | P99 lag (median of sets), 60 Hz → 120 Hz |
| --- | ---: | ---: |
| Flutter | 0.038 → 0.059 ms | 0.800 → 3.376 ms |
| Blooming | 0.038 → 0.063 ms | 0.803 → 3.393 ms |
| Coralline | 0.042 → 0.062 ms | 2.124 → 3.459 ms |
| Signals | 0.044 → 0.061 ms | 3.693 → 3.419 ms |
| Riverpod | 0.166 → 0.316 ms | 3.796 → 3.336 ms |

All five median values are higher in this 120 Hz run than in the earlier run, while the P99 ordering changes. Since these are two separate runs, this difference cannot be attributed to refresh rate. Run-to-run variation and other conditions were not isolated. Also, the 120 Hz run disabled scroll animation, so it does not show how a continuously animated workload behaves at either refresh rate.

### The one-billion-TPS target is not achieved throughput

The generator runs a 1 ms timer and computes a target batch size. It simulates at most 200 ticks in that batch; the remaining count is added arithmetically. At a configured target of one billion TPS, a nominal batch is about one million ticks, so at most 200 are simulated and the rest are not processed as individual events. The same generator logic is used by all five framework variants, so this is a common limitation rather than a framework-specific shortcut.

Consequently, `Sustained_TPS`, total tick counts, and achievement percentages from the raw CSV/JSON must not be described as actual framework throughput. They are based on the configured batch count, including ticks that were not individually processed.

### Probe, rendering, and workload limitations

- The probe timestamps execution inside the `Timer.periodic` callback, then measures the delay until its `Timer.run` callback executes. If the periodic callback itself wakes late because the event loop was blocked, that preceding delay is not directly included. This probe can therefore understate some forms of event-loop stall.
- The test does not directly measure click-to-handler latency, input responsiveness, missed frame deadlines, or whether the displayed order book is stale.
- Scroll animation is disabled and the viewport is static. The recorded FPS (0.4–0.5) and 0% jank rate do not establish rendering performance at 120 Hz or prove stutter-free behavior; the run captured only a few frames.
- The test uses batched updates. Blooming and Signals wrap portions of their state changes in batching APIs; other implementations use their own notification paths without the same explicit wrapper. This can be a valid comparison of idiomatic framework implementations, but it is not a comparison with identical notification policy. Report the policy, and consider separate uniform-policy and best-practice modes.
- The current workload does not validate event loss, duplication, ordering, queue growth, recovery after overload, or final-state equivalence.
- Results are from one OS/runtime configuration and one machine. They are not generalizable to other devices, operating systems, or release/AOT builds.

## What this run supports

This run supports a narrow observation: under its capped, batched update workload, Flutter, Signals, Coralline, and Blooming report similar sub-millisecond median event-loop lag, while Riverpod reports a higher median and mean. The set-level P99 values are similar in this run. These findings motivate further testing but do not prove which framework best handles a real high-rate socket pipeline, how a framework behaves during continuous rendering at 120 Hz, or whether user input remains responsive.

## Recommended next benchmark

1. Replay the same deterministic event trace through each state pipeline and count only events whose state updates have completed.
2. Verify event count, order, and final order-book checksum for every implementation.
3. Record queue depth and backlog growth, plus recovery time after overload.
4. Measure input-to-handler latency and frame deadlines while the stream is active; retain event-loop lag as a complementary signal, but measure timer lateness against an expected deadline.
5. Run both a uniform notification-policy scenario and a best-practice-per-framework scenario. Document batching and subscription topology for each.
6. Repeat runs at 60 Hz and 120 Hz with the same animated workload, and record which display is hosting the benchmark window.
7. Record the exact machine model, OS, SDKs, build mode, and raw per-run samples.

## Benchmarking and assessment process

When I asked ChatGPT to evaluate the results of a benchmark conducted with Gemini 3.x's assistance, I found its assessment unusually cold and unsparing. That impression led me to assign the work to separate roles: Gemini 3.x supported running the benchmark, while ChatGPT (GPT-6) took the lead in analyzing the results and writing the overall assessment.

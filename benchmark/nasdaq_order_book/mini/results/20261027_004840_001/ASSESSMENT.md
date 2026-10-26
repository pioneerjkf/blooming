# NASDAQ Order Book Benchmark: Results and Assessment

## Executive summary

The October 27, 2026 run compares main-isolate event-loop responsiveness while five Flutter implementations receive batched order-book updates. Unlike the earlier static 120 Hz run, this run enabled continuous order-book scroll animation. It does **not** measure sustained processing of one billion events per second: the configured target is one billion TPS, but the generator simulates at most 200 ticks per 1 ms batch and adds the remaining count arithmetically. Treat the results as a responsiveness observation under this capped workload, not as a throughput ranking.

Median event-loop lag ranges from 0.056 to 0.061 ms for Flutter, Coralline, Blooming, and Signals. Riverpod is higher at 0.303 ms. The median-of-set-P99 values are tightly clustered across all five implementations (3.320–3.455 ms), and closely match the earlier static 120 Hz run. This run therefore does not show a clear event-loop P99 difference attributable to enabling the animation.

Although the scroll animation was enabled, the exported FPS values are only 0.4–0.5 and the jank rate is 0%. Those values are not valid evidence of 120 Hz rendering quality: the FPS field is based on Flutter Driver's counted timeline frames, while the in-app jank calculation uses a 16.67 ms threshold, which is a 60 Hz frame budget. Direct input latency and reliable 120 Hz frame-deadline measurements are still needed.

## Run configuration

- Run: `20261027_004840_001` (`2026-10-27 00:48:40`, Asia/Seoul)
- Machine: MacBook Pro (`Mac17,7`), Apple M5 Max, 18 CPU cores, 36 GB memory
- Display: MacBook Pro built-in display at 120 Hz
- OS: macOS 27.0.1 (Build 26A434), ARM64
- Toolchain: Flutter 3.47.6 stable (`5fc346839b5d0eef006ed8404392afb4dfae428d`), Dart 3.13.5, Xcode 27.1
- Execution: Flutter Driver, profile build; scroll animation enabled (continuous VSync oscillation)
- Scenario: configured target 1,000,000,000 TPS (not verified throughput); 30 seconds per run, 10 shuffled sets per framework
- Event-loop probe: a `Timer.periodic` callback every 33 ms schedules `Timer.run`; the elapsed time from the periodic callback to the queued callback is recorded
- Samples: 914 lag samples per framework per set, with one Coralline set containing 915 samples
- Background process condition: not recorded for this run

The benchmark JSON records the timestamp, macOS/Dart environment, execution mode, set count, scenario, and animation setting. The display and host/toolchain details above describe the environment used for this run. The exact command line and background process condition were not captured in the result files.

## Archived artifacts

This run's [raw matrix](benchmark_matrix.json), [CSV](benchmark_summary.csv), and [generated report](SUMMARY_REPORT.md) are archived alongside this assessment. Compare with the earlier [static 120 Hz run assessment](../20261026_201905_001/ASSESSMENT.md), the latest [60 Hz run assessments](../20261026_232008_004/ASSESSMENT.md) and [adjacent 60 Hz run](../20261026_235828_004/ASSESSMENT.md), and the [benchmark overview](../../README.md).

## Aggregated results

The table reports the arithmetic mean of per-run means, the median of per-run medians, the trimmed mean of per-run means (dropping the lowest and highest set means), the median of per-run P99 values, the worst individual lag sample, and mean RSS. Lower is better for lag; these are not throughput metrics.

| Framework | Lag mean | Lag median | Lag trimmed mean | P99 lag (median of sets) | Max lag | UI build | GPU raster | RSS |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Flutter | 0.142 ms | 0.056 ms | 0.139 ms | 3.364 ms | 4.281 ms | 3.37 ms | 0.60 ms | 200.3 MB |
| Coralline | 0.139 ms | 0.057 ms | 0.138 ms | 3.455 ms | 3.921 ms | 3.51 ms | 0.71 ms | 207.8 MB |
| Blooming | 0.158 ms | 0.059 ms | 0.162 ms | 3.398 ms | 3.909 ms | 3.39 ms | 0.61 ms | 199.5 MB |
| Signals | 0.163 ms | 0.061 ms | 0.164 ms | 3.418 ms | 4.022 ms | 3.43 ms | 0.60 ms | 201.8 MB |
| Riverpod | 0.463 ms | 0.303 ms | 0.463 ms | 3.320 ms | 4.397 ms | 3.37 ms | 0.72 ms | 213.0 MB |

UI build and GPU raster values are based on the reported frame-timing collection and should not be used as a ranking until the FPS/jank instrumentation is validated for this 120 Hz run.

## Interpretation

### Responsiveness and tail latency

- Flutter, Coralline, Blooming, and Signals have close median lag values (0.056–0.061 ms). These differences are small and do not establish a meaningful real-world lead.
- Riverpod's median lag is 0.303 ms and mean is 0.463 ms, higher than the other four implementations in this run. This is consistent with reduced main-isolate responsiveness under this particular workload, but does not establish the cause or generalize to every application.
- The median-of-set-P99 values are tightly grouped (3.320–3.455 ms). Per-set P99 ranges are also comparatively narrow: Flutter 3.266–3.452 ms, Coralline 3.262–3.535 ms, Blooming 2.884–3.464 ms, Signals 3.334–3.471 ms, and Riverpod 3.225–3.443 ms. The common clustering suggests this probe/workload contributes substantially to the observed tail values; it does not identify the mechanism.
- Signals' P99 does not show the same set-to-set spikes seen in some earlier 60 Hz runs: all ten set P99 values in this run fall between 3.334 and 3.471 ms. That still does not mean that input events are guaranteed to be handled promptly.
- Event-loop lag is a responsiveness signal, not a direct measurement of click-to-handler latency, successful input delivery, or data correctness.

### Comparison with the earlier static 120 Hz run

| Framework | Median lag, static → animation on | P99 lag (median of sets), static → animation on | Mean lag, static → animation on |
| --- | ---: | ---: | ---: |
| Flutter | 0.058 → 0.056 ms | 3.376 → 3.364 ms | 0.180 → 0.142 ms |
| Blooming | 0.063 → 0.059 ms | 3.393 → 3.398 ms | 0.188 → 0.158 ms |
| Coralline | 0.062 → 0.057 ms | 3.459 → 3.455 ms | 0.175 → 0.139 ms |
| Signals | 0.061 → 0.061 ms | 3.418 → 3.418 ms | 0.155 → 0.163 ms |
| Riverpod | 0.316 → 0.303 ms | 3.336 → 3.320 ms | 0.500 → 0.463 ms |

The P99 values are nearly identical between the static and animated 120 Hz runs for every framework. Median lag is also close; mean lag is lower in this run for four frameworks and slightly higher for Signals. Since these are single runs rather than repeated paired trials, the differences cannot be attributed to the animation. At most, this run shows that enabling the order-book animation did not produce an obvious change in the measured event-loop lag summaries.

### Frame-rate and jank fields need correction before interpretation

- `actual_fps` is 0.4–0.5 for all implementations even though the order-book ticker is enabled to animate continuously with VSync. In the benchmark driver, this field is calculated as `TimelineSummary.countFrames() / durationSec`. The reported value is therefore inconsistent with a continuously animated 120 Hz view and indicates that the frame count being used is not capturing the rendered frame rate reliably.
- The in-app jank calculation marks a frame as jank only when `FrameTiming.totalSpan` exceeds 16.666 ms. That threshold is a 60 Hz budget. At 120 Hz, the nominal frame interval is about 8.33 ms, so frames that miss a 120 Hz deadline but finish under 16.67 ms are not counted as jank. The reported 0% jank rate cannot establish smooth 120 Hz rendering.
- UI build and raster summaries are based on a rolling window of recent frame timings, not a complete, verified presentation timeline for the entire run. They are useful diagnostic clues, but should not be used to rank implementations until the frame instrumentation and 120 Hz budget are corrected.
- The 33 ms event-loop probe samples about once every four 120 Hz display intervals. It can miss short stalls between samples and is not a substitute for measuring input-to-handler delay or frame presentation deadlines.

### The one-billion-TPS target is not achieved throughput

The generator runs a 1 ms timer and computes a target batch size. It simulates at most 200 ticks in that batch; the remaining count is added arithmetically. At a configured target of one billion TPS, a nominal batch is about one million ticks, so at most 200 are simulated and the rest are not processed as individual events. The same generator logic is used by all five framework variants, so this is a common limitation rather than a framework-specific shortcut.

Consequently, `Sustained_TPS`, total tick counts, and achievement percentages from the raw CSV/JSON must not be described as actual framework throughput. They are based on the configured batch count, including ticks that were not individually processed.

### Other workload limitations

- The probe timestamps execution inside the `Timer.periodic` callback, then measures the delay until its `Timer.run` callback executes. If the periodic callback itself wakes late because the event loop was blocked, that preceding delay is not directly included. This probe can therefore understate some forms of event-loop stall.
- The test does not directly measure click-to-handler latency, input responsiveness, missed frame deadlines, or whether the displayed order book is stale.
- The test uses batched updates. Blooming and Signals wrap portions of their state changes in batching APIs; other implementations use their own notification paths without the same explicit wrapper. This can be a valid comparison of idiomatic framework implementations, but it is not a comparison with identical notification policy. Report the policy, and consider separate uniform-policy and best-practice modes.
- The current workload does not validate event loss, duplication, ordering, queue growth, recovery after overload, or final-state equivalence.
- Results are from one OS/runtime configuration and one machine. They are not generalizable to other devices, operating systems, or release/AOT builds.

## What this run supports

This run supports a narrow observation: with continuous order-book animation enabled at 120 Hz, measured median event-loop lag remains close to the earlier static 120 Hz run, and the set-level P99 values remain tightly clustered around 3.3–3.5 ms. Riverpod again has higher mean and median lag than the other implementations. The exported FPS and jank fields are not valid evidence of smooth 120 Hz rendering, and the event-loop probe does not measure input-to-handler latency. This run therefore adds a useful animation-on responsiveness observation, but does not yet answer whether the frameworks sustain 120 Hz rendering or keep pointer input responsive under load.

## Recommended next benchmark

1. Fix frame counting so FPS reflects presented frames over the measured interval, and record the number of valid frame samples per run.
2. Calculate jank against the active display's frame interval (about 8.33 ms at 120 Hz), and report missed-frame counts and frame-time percentiles.
3. Run paired animation-off and animation-on trials at the same 120 Hz display, with shuffled framework order and repeated sets.
4. Measure input-to-handler latency while the update stream and animation are both active; retain event-loop lag as a complementary signal.
5. Replay the same deterministic event trace through each pipeline and verify event count, order, final-state checksum, queue depth, and overload recovery.
6. Run both a uniform notification-policy scenario and a best-practice-per-framework scenario. Document batching and subscription topology for each.
7. Record the exact display hosting the benchmark window, command line, background process condition, machine, OS, SDKs, build mode, and power/thermal state.

## Benchmarking and assessment process

When I asked ChatGPT to evaluate the results of a benchmark conducted with Gemini 3.x's assistance, I found its assessment unusually cold and unsparing. That impression led me to assign the work to separate roles: Gemini 3.x supported running the benchmark, while ChatGPT (GPT-6) took the lead in analyzing the results and writing the overall assessment.

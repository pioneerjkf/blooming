# NASDAQ Order Book Benchmark: Results and Assessment

## Executive summary

The October 26, 2026 run compares main-isolate event-loop responsiveness while each implementation receives batched order-book updates. It does **not** measure sustained processing of one billion events per second. The configured target is one billion TPS, but the generator simulates at most 200 ticks per 1 ms batch and adds the remainder to a counter. Treat the results as a responsiveness observation under this capped workload, not as a throughput ranking.

No implementation is a clear overall winner from this run. Flutter and Blooming have the lowest aggregate median lag (0.038 ms); Signals has the lowest mean lag (0.118 ms) but a high set-level P99; Riverpod has higher mean and median lag in this workload. Differences among low median values are small and should not be presented as a decisive advantage.

## Run configuration

- Run: `20261026_164352_002` (`2026-10-26 16:43:52`)
- Machine: MacBook Pro (`Mac17,7`), Apple M5 Max, 18 CPU cores, 36 GB memory
- OS: macOS 27.0.1 (Build 26A434), ARM64
- Toolchain: Flutter 3.47.6 stable (`5fc346839b5d0eef006ed8404392afb4dfae428d`), Dart 3.13.5, Xcode 27.1
- Display: 60 Hz
- Execution: Flutter Driver, profile build; scroll animation disabled, static center viewport
- Scenario: configured target 1,000,000,000 TPS (not verified throughput); 30 seconds per run, 10 shuffled sets per framework
- Event-loop probe: a `Timer.periodic` callback every 33 ms schedules `Timer.run`; the elapsed time from the periodic callback to the queued callback is recorded.

The original result files record macOS and Dart, but not the machine, display, Flutter, or Xcode details. Those additional environment details are included here based on the user's confirmation that the inspected host and display match the benchmark environment. The exact command line and power/thermal state were not captured.

## Archived artifacts

The original output for this run is archived alongside this assessment: [raw matrix](benchmark_matrix.json), [CSV](benchmark_summary.csv), and [generated report](SUMMARY_REPORT.md). Run details and missing reproducibility metadata are listed in [RUN_METADATA.md](RUN_METADATA.md). The [methodology document](../../BENCHMARK_METHODOLOGY.md) used by the benchmark is archived at the benchmark level.

## Aggregated results

The table reports the arithmetic mean of per-run means, the median of per-run medians, the trimmed mean of per-run means, the median of per-run P99 values, and the worst individual lag sample across all runs. Lower is better for lag; these are not throughput metrics.

| Framework | Lag mean | Lag median | Lag trimmed mean | P99 lag (median of sets) | Max lag | UI build | GPU raster | RSS |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Flutter | 0.127 ms | **0.038 ms** | 0.125 ms | **0.800 ms** | 4.722 ms | 4.05 ms | 0.69 ms | 196.4 MB |
| Blooming | 0.131 ms | **0.038 ms** | 0.127 ms | **0.803 ms** | 4.613 ms | 4.03 ms | 0.69 ms | **194.9 MB** |
| Coralline | 0.142 ms | 0.042 ms | 0.140 ms | 2.124 ms | 5.147 ms | 4.08 ms | 0.81 ms | 206.3 MB |
| Signals | **0.118 ms** | 0.044 ms | **0.118 ms** | 3.693 ms | 4.963 ms | 4.12 ms | 0.69 ms | 196.1 MB |
| Riverpod | 0.468 ms | 0.166 ms | 0.468 ms | 3.796 ms | **4.411 ms** | **3.82 ms** | 0.77 ms | 204.8 MB |

Bold values identify the lowest value in that column. UI build and GPU raster were collected from only a few frames and are not suitable for ranking in this run.

## Interpretation

### Responsiveness and tail latency

- Flutter and Blooming tie for the lowest aggregate median lag at 0.038 ms. This is a small difference and does not establish a meaningful performance lead.
- Signals has the lowest aggregate mean lag (0.118 ms), while its median-of-set-P99 is 3.693 ms. Six of its ten runs have P99 values around 3.6–4.2 ms, while the other four are below 1 ms. This indicates run-to-run tail variability in this measurement; this benchmark does not identify its cause.
- Riverpod's aggregate mean and median lag are higher than the other implementations in this run. The result is consistent with reduced main-isolate responsiveness under this particular update workload, but it does not establish the cause or generalize to every application.
- A lag value is a responsiveness signal, not a guarantee of reliable data processing. Low lag alone does not prove that events were applied, ordered, or rendered correctly.

### The one-billion-TPS target is not achieved throughput

The generator runs a 1 ms timer and computes a target batch size. It simulates at most 200 ticks in that batch; the remaining count is added arithmetically. At a configured target of one billion TPS, a nominal batch is about one million ticks, so at most 200 are simulated and the rest are not processed as individual events. The same generator logic is used by all five framework variants, so this is a common limitation rather than a framework-specific shortcut.

Consequently, `Sustained_TPS`, total tick counts, and achievement percentages from the raw CSV/JSON must not be described as actual framework throughput. They are based on the configured batch count, including ticks that were not individually processed.

### Probe and workload limitations

- The probe timestamps execution inside the `Timer.periodic` callback, then measures the delay until its `Timer.run` callback executes. If the periodic callback itself wakes late because the event loop was blocked, that preceding delay is not directly included. This probe can therefore understate some forms of event-loop stall.
- The test does not directly measure click-to-handler latency, input responsiveness, missed frame deadlines, or whether the displayed order book is stale. Scroll animation is disabled, and rendering metrics have very few samples.
- The reported 0% jank rate should not be read as evidence that the app is free of visible stutter: this run used a static viewport, disabled scroll animation, and captured only a few frames. Jank requires frame-deadline measurements under an active rendering workload.
- I added responsiveness measurements after observing an interactive 120 Hz test where FPS stayed near target while mouse input became unresponsive under heavy updates. This static, animation-disabled run does not reproduce or verify that case; my motivation and interpretation are described in the [benchmark overview](../../README.md).
- The test uses batched updates. Blooming and Signals wrap portions of their state changes in batching APIs; other implementations use their own notification paths without the same explicit wrapper. This can be a valid comparison of idiomatic framework implementations, but it is not a comparison with identical notification policy. Report the policy, and consider separate uniform-policy and best-practice modes.
- The current workload does not validate event loss, duplication, ordering, queue growth, recovery after overload, or final-state equivalence.
- Results are from one OS/runtime configuration and one machine. The exact model and active display are absent from the original run records; see the archival metadata for host details collected afterward.

## What this run supports

This run supports a narrow observation: under its capped, batched update workload, the measured event-loop probe usually reports sub-millisecond median lag for Flutter, Blooming, Coralline, and Signals, while Riverpod reports a higher median and mean. Signals shows notable variation in set-level P99. These findings motivate further testing but do not prove which framework best handles a real high-rate socket pipeline or guarantees responsive input.

## Recommended next benchmark

1. Replay the same deterministic event trace through each state pipeline and count only events whose state updates have completed.
2. Verify event count, order, and final order-book checksum for every implementation.
3. Record queue depth and backlog growth, plus recovery time after overload.
4. Measure input-to-handler latency and frame deadlines while the stream is active; retain event-loop lag as a complementary signal, but measure timer lateness against an expected deadline.
5. Run both a uniform notification-policy scenario and a best-practice-per-framework scenario. Document batching and subscription topology for each.
6. Record the exact machine model, OS, SDKs, build mode, and raw per-run samples.

## Benchmarking and assessment process

When I asked ChatGPT to evaluate the results of a benchmark conducted with Gemini 3.x's assistance, I found its assessment unusually cold and unsparing. That impression led me to assign the work to separate roles: Gemini 3.x supported running the benchmark, while ChatGPT (GPT-6) took the lead in analyzing the results and writing the overall assessment.


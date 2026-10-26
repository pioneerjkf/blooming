# NASDAQ Order Book Benchmark: State Pipeline Responsiveness

This benchmark compares five Flutter state-management implementations while they receive batched updates for a 50-level order book. Its current run is a **responsiveness study under a capped synthetic workload**, not a verified event-throughput benchmark.

## Why measure responsiveness as well as FPS?

I began this benchmark by focusing on throughput and FPS. Then, during an interactive test on a 120 Hz display under heavy data updates, I saw the frame rate stay close to 120 while mouse input became unresponsive. That experience changed the question I wanted the benchmark to answer: a high FPS can coexist with a system that no longer feels usable, so frame rate alone is not enough to judge the state pipeline under load.

In Flutter, **jank** means visible stutter when a frame misses its display deadline: about 16.7 ms at 60 Hz and 8.3 ms at 120 Hz. Jank describes rendering; delayed mouse or touch handling describes input responsiveness. I observed the latter even when FPS looked healthy, so I now track event-loop lag alongside FPS and configured throughput. See [Flutter performance profiling](https://docs.flutter.dev/perf/ui-performance).

My initial explanation was that frame/render work might be getting scheduled ahead of input. I have not established that scheduling order as the cause. Event-loop lag is useful because it indicates how promptly the main execution path can run queued work under pipeline load, but it is not a direct measurement of click-to-handler latency, successful event delivery, or data correctness. I need direct input-to-handler measurements, together with frame-deadline and event-loop data, to test the cause and quantify the user-visible effect. Flutter's [scheduler phases](https://api.flutter.dev/flutter/scheduler/SchedulerPhase.html) and [UI/raster thread model](https://docs.flutter.dev/perf/ui-performance) provide relevant context.

## Frameworks compared

| Framework | Version | Paradigm | Notes |
| :--- | :--- | :--- | :--- |
| **Flutter (Pure)** | Flutter SDK 3.47.6 | `ValueNotifier` / `ListenableBuilder` | Native SDK baseline |
| **Signals** | `signals_flutter` 7.1.0 | Auto-tracked reactive signals | Community package |
| **Riverpod** | `flutter_riverpod` 3.4.3 | Scoped provider graph | Community package |
| **Blooming** | `blooming_flutter` 0.1.4 | 2-phase Lazy-Pull DAG (LPDAG) | Experimental; benchmark-author project |
| **Coralline** | `coralline_flutter` 0.1.5 | Push-Dirty, Pull-Data (CORAL) | Experimental; benchmark-author project |

Blooming and Coralline are experimental reactive engines authored by the benchmark author. The implementations use framework-specific update APIs; see the batching caveat below.

## Latest archived run: `20261026_164352_002`

- **Environment:** MacBook Pro (`Mac17,7`), Apple M5 Max, 18 CPU cores, 36 GB memory; macOS 27.0.1; Flutter 3.47.6 stable; Dart 3.13.5; Xcode 27.1; 60 Hz display.
- **Execution:** Flutter Driver, profile build; 30 seconds per run, 10 shuffled sets per framework.
- **Scenario:** batched order-book updates; static center viewport; scroll animation disabled.
- **Configured target:** 1,000,000,000 TPS. This is not verified throughput; see the limitations below.

| Framework | Lag median | Lag mean | Trimmed mean | P99 lag (median of sets) | Max lag | RSS |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Flutter** | **0.038 ms** | 0.127 ms | 0.125 ms | **0.800 ms** | 4.722 ms | 196.4 MB |
| **Blooming** | **0.038 ms** | 0.131 ms | 0.127 ms | **0.803 ms** | 4.613 ms | **194.9 MB** |
| **Coralline** | 0.042 ms | 0.142 ms | 0.140 ms | 2.124 ms | 5.147 ms | 206.3 MB |
| **Signals** | 0.044 ms | **0.118 ms** | **0.118 ms** | 3.693 ms | 4.963 ms | 196.1 MB |
| **Riverpod** | 0.166 ms | 0.468 ms | 0.468 ms | 3.796 ms | **4.411 ms** | 204.8 MB |

The mean is the arithmetic mean of per-run means; the median is the median of per-run medians; the trimmed mean drops the lowest and highest per-run means; P99 is the median of per-run P99 values. Lower lag is better. The low median differences between Flutter, Blooming, and Coralline do not establish a decisive real-world lead. Signals combines the lowest aggregate mean with substantial set-to-set P99 variation. Riverpod has higher mean and median lag in this workload. No overall winner is established by this run.

Read the detailed [run assessment](results/20261026_164352_002/ASSESSMENT.md), [raw matrix](results/20261026_164352_002/benchmark_matrix.json), [CSV](results/20261026_164352_002/benchmark_summary.csv), [generated report](results/20261026_164352_002/SUMMARY_REPORT.md), and [run metadata](results/20261026_164352_002/RUN_METADATA.md).

## Additional run: 120 Hz display, `20261026_201905_001`

I repeated the benchmark on the MacBook Pro's built-in 120 Hz display, with the external 60 Hz display also connected. This run used the same 30-second, 10-set workload with scroll animation disabled. The archived run metadata records the display setup.

| Framework | Lag median | Lag mean | Trimmed mean | P99 lag (median of sets) | Max lag | RSS mean |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Flutter** | **0.058 ms** | 0.180 ms | 0.181 ms | 3.376 ms | **3.919 ms** | 200.1 MB |
| **Signals** | 0.061 ms | **0.155 ms** | **0.157 ms** | 3.419 ms | 4.138 ms | 203.1 MB |
| **Coralline** | 0.062 ms | 0.175 ms | 0.174 ms | 3.459 ms | 4.440 ms | 208.5 MB |
| **Blooming** | 0.063 ms | 0.188 ms | 0.189 ms | 3.393 ms | 4.099 ms | **200.2 MB** |
| **Riverpod** | 0.316 ms | 0.500 ms | 0.500 ms | **3.336 ms** | 4.274 ms | 206.4 MB |

These values describe this run only; they should not be merged with the 60 Hz results as if they were one controlled sample. Lag medians were higher than in the earlier 60 Hz run across all five implementations, while the P99 order changed. Two runs are not enough to attribute these differences to refresh rate or another cause. Under this animation-disabled workload, the recorded FPS (0.4–0.5) does not represent a meaningful test of 120 Hz rendering, and input-to-handler latency and missed frame deadlines were not measured. I treat this as a 120 Hz environment responsiveness observation, not evidence that 120 Hz itself changed framework performance.

The configured 1,000,000,000 TPS remains a generator target, not verified event throughput; see the limitation above. Review the [raw matrix](results/20261026_201905_001/benchmark_matrix.json), [CSV](results/20261026_201905_001/benchmark_summary.csv), [generated report](results/20261026_201905_001/SUMMARY_REPORT.md), and [run metadata](results/20261026_201905_001/RUN_METADATA.md) for this run.

## Limitations and interpretation

1. **The 1-billion-TPS target is not achieved throughput.** The generator simulates at most 200 ticks per 1 ms batch and adds the remaining count arithmetically. The same generator logic is used across all five implementations. TPS, total ticks, and achievement rate in the raw data must not be presented as actual processed-event throughput.
2. **The lag probe can miss some stalls.** It timestamps execution inside a 33 ms `Timer.periodic` callback, then measures until a queued `Timer.run` executes. A delay before the periodic callback itself wakes is not directly included. Treat lag as a responsiveness signal, not a guarantee that input is responsive.
3. **This run does not measure input latency or jank adequately.** It does not record click-to-handler delay or missed frame deadlines. The viewport is static, animation is disabled, and only a few frames were collected; therefore the reported 0% jank rate does not establish stutter-free rendering.
4. **Batching policies differ.** Blooming and Signals wrap portions of their state changes in batching APIs; the other implementations use their own notification paths without the same explicit wrapper. This can represent idiomatic framework usage, but it is not an identical notification policy. Future comparisons should separate a uniform-policy mode from a best-practice-per-framework mode.
5. **Correctness and overload recovery are not tested.** The run does not verify event loss, duplication, ordering, final-state equivalence, queue growth, or recovery after overload.
6. **Rendering metrics are not rankable here.** UI build and GPU raster values came from very few frames and should not be used to rank frameworks.
7. **One environment only.** Results describe this macOS profile run and are not generalizable to other devices, operating systems, or release/AOT builds.

## Reproducing a comparable run

The exact command line for the archived run was not recorded. The following is a suggested equivalent configuration, not a bit-for-bit reproduction:

```bash
cd benchmark/nasdaq_order_book/mini
dart run tool/run_all_benchmarks.dart --tps=1000000000 --duration=30 --sets=10 --shuffle
```

Results are written under `results/<run-id>/`. See [BENCHMARK_METHODOLOGY.md](BENCHMARK_METHODOLOGY.md) for measurement definitions and methodology details.

## Review the implementations

Frameworks have different design goals and idiomatic APIs. If an implementation in `packages/` does not reflect a framework's best practices (for example, subscription scopes, batching APIs, or selectors), feedback and pull requests are welcome.

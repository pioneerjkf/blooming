# NASDAQ Order Book Benchmark: State Pipeline Responsiveness

This benchmark compares five Flutter state-management implementations while they receive batched updates for a 50-level order book. It provides a **responsiveness study under heavy streaming workloads**, evaluating main event-loop lag and system resource utilization under load.

## Why measure responsiveness instead of raw FPS?

I began this benchmark by focusing on throughput and FPS. Then, during an interactive test on a 120 Hz display under heavy data updates, I saw the frame rate stay close to 120 while mouse input became unresponsive. That experience demonstrated that raw FPS is misleading: a high frame rate can coexist with a system that no longer feels usable, so frame rate alone cannot evaluate state pipeline responsiveness under load.

Furthermore, in Flutter's demand-driven rendering model and high-throughput background isolate streaming, raw frame counts are prone to buffer sampling artifacts and do not differentiate reactive state libraries. Consequently, raw FPS is deliberately omitted from ranking metrics, and the benchmark focuses on **Event-Loop Lag (responsiveness probe)** alongside frame deadline adherence (**Jank Rate**). See [Flutter performance profiling](https://docs.flutter.dev/perf/ui-performance).

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

## Benchmark Results

All prior benchmark run results and artifacts have been cleared.

To run a new benchmark session and generate fresh artifacts, follow the execution instructions in [Reproducing a comparable run](#reproducing-a-comparable-run). Outputs will be saved under `results/<run-id>/` containing:
- `SUMMARY_REPORT.md` (statistical summary report)
- `benchmark_matrix.json` (complete raw dataset)
- `benchmark_summary.csv` (tabular metrics for spreadsheet analysis)
- `ASSESSMENT.md` (qualitative run assessment)

## Limitations and interpretation

1. **Generator Throughput vs. Framework Update Rate.** All tick batches are executed 100% in real hardware by the background isolate without artificial step capping or arithmetic tick padding. At 1,000,000,000 TPS (10억 틱), the isolate saturates the host single-core capacity (~14.5M TPS on Apple Silicon). Because the isolate groups ticks into 1ms batches, the main isolate framework receives updates and invalidates state at ~1,000 Hz. `sustained_tps` reflects isolate generation throughput, not 14.5 million individual UI widget rebuilds or separate framework state tree invalidations per second.
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

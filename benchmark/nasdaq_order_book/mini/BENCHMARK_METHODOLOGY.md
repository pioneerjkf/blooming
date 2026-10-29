# NASDAQ Order Book Mini — Benchmark Methodology

This document outlines **what and how the benchmark measures, and what it deliberately does not measure**. Before interpreting any results, please read the [Limitations](#7-limitations) section.

---

## 1. Test Architecture & Environment

- Five state management variants (**Pure Flutter**, **Signals**, **Riverpod**, **Blooming**, and **Coralline**) implement an identical application architecture:
  `Tick Generation Isolate -> State Pipeline -> Widget Tree`
- Each framework is executed on a native desktop window via `flutter drive --profile` (measurements reflect `--profile` mode and may differ from Release/AOT runtime characteristics).
- A benchmark "set" executes each of the 5 implementations once. With the `--shuffle` flag enabled, the execution order is randomized for each set to mitigate order bias caused by OS caching and thermal throttling.
- Each run discards a `warmup` window and records metrics strictly within the active `duration` window.
- **Dynamic UI Stress Factors (Configurable & Enabled by Default)**:
  - **Order Book Scroll Animation** (`--scroll-anim` / `--no-scroll-anim`): Continuous VSync sinusoidal oscillation of the 50-level order book viewport.
  - **Theme Auto-Rotation** (`--theme-rotation` / `--no-theme-rotation`, `--theme-interval=<val>`): Automated high-frequency theme switching (default 8.33ms / 120Hz display refresh cycle) evaluating full-tree style cache invalidation and redraw overhead.
  - **Watchlist Ticker Auto-Rotation** (`--ticker-rotation` / `--no-ticker-rotation`, `--ticker-interval=<val>`): Automated high-frequency stock selection rotation (default 8.33ms / 120Hz) evaluating pipeline re-subscription and order book state swapping overhead.

---

## 2. Frameworks & Authorship Disclosure

This benchmark compares two widely adopted community state managers and Flutter's built-in primitive against two experimental engines designed by the benchmark author. To maintain transparency and enable objective evaluation, the origins and architectural paradigms of each framework are disclosed below.

### Established Community & Standard Flutter Frameworks
* **Flutter (Pure ValueNotifier)** (`flutter` SDK)
  - Built strictly using Flutter SDK primitives (`ValueNotifier<T>`, `ListenableBuilder`, `InheritedWidget`) without external dependencies.
  - Serves as the zero-dependency vanilla baseline for fine-grained per-level order book rebuilds.
* **Signals** (`signals_flutter` 7.1.0, `signals_core` 7.0.0)
  - A popular Dart port of Preact / SolidJS-style fine-grained reactive primitives.
  - Dynamically tracks and propagates updates across an auto-wired dependency graph.
* **Riverpod** (`flutter_riverpod` 3.4.3, `riverpod` 3.4.3)
  - The most widely adopted compile-safe provider architecture in the Flutter ecosystem.
  - Decouples global state and ensures testability and lifecycle safety.

### Author-Designed Experimental Frameworks (Authorship Disclosure)
* **Blooming** (`blooming` 0.1.4, `blooming_flutter` 0.1.4)
  - **Architecture**: Blooming 2-Phase LPDAG (Lazy Pull Directed Acyclic Graph)
  - **Design Philosophy**: Propagates $O(1)$ dirty flags on upstream updates, deferring actual calculation until evaluation (Pull, e.g. at VSync) to prevent redundant intermediate computations and diamond dependency glitches.
* **Coralline** (`coralline` 0.1.3, `coralline_flutter` 0.1.5)
  - **Architecture**: CORAL (Chain of Reactivity And Lazy-computation)
  - **Design Philosophy**: Adopts Flutter's `RenderObject` paradigm (**Push-Dirty, Pull-Data**) for application state management to minimize boilerplate in reactive pipelines.

---

## 3. Reported Metrics

### Event Loop Lag (Primary Metric)

Event-loop lag measures how promptly Dart's main isolate event loop processes queued tasks under update stress. It serves as a **responsiveness indicator**.

**Measurement Mechanism**

1. Inside the state pipeline, a `Timer.periodic` callback fires every 33 ms, timestamps the event, and enqueues an empty closure via `Timer.run()`:

   ```dart
   _eventLoopTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
     final scheduledMicros = _eventLoopStopwatch.elapsedMicroseconds;
     Timer.run(() {
       final lagMs = (_eventLoopStopwatch.elapsedMicroseconds - scheduledMicros) / 1000.0;
       lagRecorder.add(lagMs); // Recorded only during the measurement duration
     });
   });
   ```
2. The elapsed time between callback scheduling and closure invocation constitutes **one lag sample**.
3. The test driver signals `lag_reset` at the start of the measurement window and fetches aggregated samples via `get_metrics` when the duration ends.
4. The number of samples per set is approximately `duration / 0.033` (~600 samples for a 20s run). The exact count is preserved as `lag_sample_count` in the result JSON.

**Per-Set Statistics**: Mean, Median, P95, P99, and Max.

**Measurement Overhead**: Samples are pre-allocated once in a contiguous `Float64List` buffer (64K samples, 512 KB). Sample recording is $O(1)$ with zero runtime allocations. Sorting and statistical reductions occur only once after the measurement period concludes.

### UI Build / GPU Raster / Jank / RSS

| Metric | Source |
| :--- | :--- |
| **UI Build**, **GPU Raster** | Flutter frame timings captured via `WidgetsBinding.instance.addTimingsCallback` (or driver timeline) |
| **Jank Rate (`jank_rate_pct`)** | Percentage of frames where either UI Build or GPU Raster exceeded the frame budget ($T_{\text{frame}}$, e.g. 8.33ms for 120Hz). Aligned with official Flutter DevTools pipelined deadline specification (`buildDuration > budget || rasterDuration > budget`). |
| **RSS** | `ProcessInfo.currentRss` (resident physical memory usage at time of measurement) |

**Pipelined Frame Deadline vs. End-to-End Latency**:
Flutter's rendering engine executes UI build (Dart/layout/paint) and GPU rasterization on two distinct parallel threads (UI Thread and Raster Thread). Because the UI thread builds frame $N+1$ concurrently while the Raster thread rasterizes frame $N$, a frame misses its presentation deadline (drops/janks) if and only if **either** the UI build or the Raster stage exceeds the frame budget deadline. End-to-end latency (`totalSpan`, which includes multi-stage pipeline queuing) spans across VSync boundaries naturally and is not an indicator of frame drops. Both in-app metrics and driver timeline summaries evaluate jank against this concurrent deadline model.

*Note: In static runs where animations are disabled and screen refreshes are sparse, UI Build and Raster metrics show negligible differences. **Do not use them to rank frameworks.***

---

## 4. Real Hardware Throughput vs. Physical Saturation

The tick generator executes 100% of requested simulation steps within the background isolate without artificial batch step caps or arithmetic counter padding. Every tick invokes genuine domain state transitions (order matching, price level updates, best bid/ask calculations).

### Generator Ingestion Throughput vs. Framework State Update Frequency

To prevent misinterpreting high tick volumes as individual UI/state invalidations, the benchmark distinguishes two complementary metrics:

1. **Generator Ingest Throughput (`generator_tps` / `sustained_tps`)**:
   - Measures the raw volume of simulated financial order-book ticks generated and processed per second inside the dedicated background isolate.
   - **Linear Scaling Region (up to ~10M TPS)**: Targets within host hardware single-core capacity achieve ~100% sustained throughput.
   - **Physical Hardware Saturation Region (10M to 1,000,000,000+ TPS)**: When configured beyond physical CPU capacity (such as the default 1,000,000,000 TPS stress target), the generator isolate runs at 100% single-core saturation, yielding the physical maximum throughput sustained by the host CPU (~15.8–16.5M TPS on Apple Silicon).

2. **Framework State Update Frequency (`framework_update_rate_hz` / `batch_dispatches_per_sec`)**:
   - The background isolate bundles simulated ticks into 1ms payloads (`TickBatchPayload(batchSize: N, ...)`), sending approximately ~1,000 payloads per second across the isolate port to the main UI isolate under non-saturated loads (dropping to ~16 Hz under 1B TPS target saturation).
   - The main isolate pipeline unpacks each payload in `updateBatch()` and notifies framework reactive state listeners (`ValueNotifier`, `Bloom`, `Signal`, `StateNotifier`, `Coral`) **once per batch**.
   - **Crucial Distinction**: `sustained_tps` (e.g. 15.8–16.5M TPS) reflects the background isolate's tick generation capacity, **NOT** 16 million distinct UI widget rebuilds or separate framework state tree invalidations per second. The actual frequency of framework state invalidations corresponds to the batch dispatch rate.

- **Metric Focus**: Sustained TPS and Achievement Rate represent the background isolate's physical compute ceiling. Meanwhile, **Event Loop Lag** on the main isolate serves as the primary differentiator of framework UI responsiveness under continuous upstream streaming pressure.

---

## 5. Aggregation and Statistical Processing

To avoid cherry-picking favorable runs, multi-set benchmarks report all of the following metrics side-by-side:

| Column | Definition |
| :--- | :--- |
| **Lag Mean** | Arithmetic mean of per-set mean lag values |
| **Lag Median** | Median of per-set median lag values (outlier-resilient; primary sort key) |
| **Lag Trimmed Mean** | Mean of per-set means excluding the lowest and highest values (applied when sets $\ge 4$) |
| **P99 Lag** | Median of per-set P99 values |
| **Max Lag** | Highest individual sample observed across all runs and sets |

- **Trimmed Mean** is a complementary statistic intended to soften isolated spikes caused by OS scheduling preemptions or background GC passes. The trimming rule (excluding 1 min and 1 max) is fixed a priori and applied symmetrically across all frameworks.
- The benchmark **cannot identify the root cause** of tail latency spikes (whether attributable to Dart GC, OS interrupts, or framework internals). Any attribution is hypothetical.
- Unfiltered per-set breakdowns (Mean, Median, P99, Max, and sample counts) are fully detailed in `SUMMARY_REPORT.md` and the accompanying JSON/CSV artifacts.

---

## 6. How to Reproduce

Run the driver suite from the mini application root:

```bash
cd benchmark/nasdaq_order_book/mini
dart run tool/run_all_benchmarks.dart --tps=1000000000 --duration=30 --warmup=5 --sets=10 --shuffle --scroll-anim --theme-rotation --theme-interval=8.33ms --ticker-rotation --ticker-interval=8.33ms --mode=drive
```

Results will be generated in `results/<YYYYMMDD_HHMMSS_SEQ>/`:
- `SUMMARY_REPORT.md` (Markdown summary)
- `benchmark_matrix.json` (Complete raw sample & statistical output)
- `benchmark_summary.csv` (Tabular metrics for spreadsheet analysis)

---

## 7. Limitations

1. **Lag is an event-loop responsiveness signal, not throughput or correctness.** Sub-millisecond variations may reside within runtime noise. Always evaluate medians alongside P99, Max, and individual set distributions.
2. **Platform Specificity**: Conducted on a single host machine running macOS in `--profile` mode. Results may vary on different architectures, mobile OS environments, or Release/AOT compilation.
3. **Sampling Resolution**: The 33 ms sampling interval may not capture micro-stalls occurring between intervals.
4. **No Statistical Significance Testing**: Small sample sizes (e.g., 3–10 sets) may exhibit set-to-set rank fluctuations.
5. **No Causal Claims**: This benchmark records observed timings without asserting definitive causal explanations for differences between framework internals.

# Benchmark Assessment — 2026-11-02

## Executive Summary

This was one benchmark execution consisting of 10 shuffled sets, with five implementations measured once per set (50 framework runs total). The target was 1,000,000,000 ticks per second (TPS), with a 30-second measurement window after warmup. The run is useful as a high-load saturation comparison on this host. It does not demonstrate sustained 1B TPS: observed generator throughput was approximately 16.45–17.51M TPS, or 1.64–1.75% of target.

The main-isolate event-loop lag medians were effectively tied at 0.019 ms for Flutter, Signals, Blooming, and Coralline; Riverpod was 0.022 ms. Those median differences are very small and should not be treated as a definitive framework ranking. Flutter had the lowest aggregated mean lag (0.098 ms), while Blooming and Flutter had the lowest UI build and raster figures in the summary. Riverpod and Coralline had higher mean lag and rendering costs in this run, but this single execution cannot establish a general performance difference or its cause.

## Results

| Framework | Generator TPS | Update rate | Mean lag | Median lag | P99 lag | Worst lag | UI build | GPU raster | RSS |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Flutter | 17.51M/s | 18 Hz | 0.098 ms | 0.019 ms | 3.014 ms | 4.608 ms | 2.90 ms | 0.63 ms | 221.4 MB |
| Blooming | 17.47M/s | 17 Hz | 0.104 ms | 0.019 ms | 3.038 ms | 5.470 ms | 2.94 ms | 0.64 ms | 219.6 MB |
| Signals | 17.17M/s | 17 Hz | 0.107 ms | 0.019 ms | 3.202 ms | 5.210 ms | 3.07 ms | 0.64 ms | 215.9 MB |
| Coralline | 16.45M/s | 17 Hz | 0.124 ms | 0.019 ms | 3.381 ms | 5.388 ms | 3.57 ms | 0.80 ms | 231.4 MB |
| Riverpod | 17.08M/s | 17 Hz | 0.124 ms | 0.022 ms | 3.329 ms | 5.388 ms | 3.32 ms | 0.77 ms | 220.9 MB |

Values above are the per-framework aggregates in `SUMMARY_REPORT.md`. P99 is the median of per-set P99 values; worst lag is the highest individual sample across the run. The 33 ms periodic probe captured about 914–915 samples per set.

## Interpretation

- **Throughput:** The 1B TPS target drove the background generator into physical saturation. Generator TPS measures work in the background isolate; the roughly 16–18 Hz update figure is the frequency of batch dispatches to the framework on the main isolate. These are distinct measurements.
- **Responsiveness:** Median lag clustered at 0.019 ms for four implementations and 0.022 ms for Riverpod. The run-wide P99 values were around 3.0–3.4 ms and maximum samples were 3.15–5.47 ms. These lag samples are below the 8.33 ms frame budget, but a periodic lag probe does not directly count dropped frames or measure input-to-handler latency.
- **Rendering:** Reported jank rate was 0.00% for all implementations. Flutter had the lowest mean UI build/raster values (2.90/0.63 ms); Blooming was close (2.94/0.64 ms). These are observations from this profile-mode run, not a general ranking.
- **Memory:** RSS ranged from 215.9 MB (Signals) to 231.4 MB (Coralline). One sample window per framework per set is insufficient to establish stable memory differences.

## Conditions and Limitations

- macOS 27.0.1, Dart 3.13.5, Flutter Driver native window, profile build, 120 Hz display.
- Scroll animation and ticker auto-rotation were enabled; theme auto-rotation was disabled. Ticker rotation ran at 8.33 ms.
- This is one execution on one machine. The shuffled 10-set design reduces order bias but is not a substitute for independent repeated executions, confidence intervals, or significance testing.
- The event-loop probe samples every 33 ms, so brief stalls may be missed. Event-loop lag is a responsiveness signal, not direct input latency, correctness, or frame-drop measurement.
- These results do not isolate framework cost from all runtime, operating-system, thermal, and rendering variation. No causal explanation can be drawn from the observed differences.

## Assessment and Next Step

The run completed and produced a useful saturation profile. At this load, all five implementations kept sampled median event-loop lag low; Flutter and Blooming showed the lowest rendering timings in this run. The differences are preliminary and do not support declaring an overall winner. Repeat the same configuration across independent executions, then add lower target TPS runs under matching animation settings to compare behavior before saturation. For saturation-focused follow-up, record batch delivery/drop counts, queue growth, state parity, and recovery after the burst.

For the full measurement definitions and caveats, see [BENCHMARK_METHODOLOGY.md](../../BENCHMARK_METHODOLOGY.md). Raw records are in [benchmark_summary.csv](benchmark_summary.csv) and [benchmark_matrix.json](benchmark_matrix.json).

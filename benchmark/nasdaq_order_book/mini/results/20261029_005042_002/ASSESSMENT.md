# Run Assessment — 20261029_005042_002

- **Target Workload**: 1,000 TPS
- **Conditions**: Scroll animation enabled, theme and ticker rotation disabled; 30s × 10 randomized sets, profile mode
- **Raw Datasets**: [SUMMARY_REPORT.md](SUMMARY_REPORT.md), [benchmark_matrix.json](benchmark_matrix.json), [benchmark_summary.csv](benchmark_summary.csv)

## Key Observations

Flutter observed the lowest median lag (0.046 ms), while Signals, Blooming, and Coralline all recorded 0.054 ms. Riverpod observed a median of 0.265 ms and a relatively higher mean of 0.328 ms.

All implementations sustained the full target throughput and 1,000 Hz framework update rate. Median P99 lag spanned 1.889–2.224 ms, and worst-case lag remained between 3.862–4.098 ms. Under this baseline workload, differences between Flutter and the other reactive implementations are marginal and well within frame deadlines.

## Limitations

Event-loop lag serves as a probe of main-isolate responsiveness; it does not measure raw throughput, click-to-handler latency, data correctness, or dropped frames directly. Measurements reflect 10 sets on a single macOS machine in profile mode, without formal statistical significance testing or causal verification. UI Build and Raster timings are reported for diagnostic transparency and are not used as ranking criteria.

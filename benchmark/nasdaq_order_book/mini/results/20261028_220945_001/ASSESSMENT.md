# Run Assessment — 20261028_220945_001

- **Target Workload**: 1,000,000,000 TPS
- **Conditions**: Scroll animation, theme rotation, and ticker rotation enabled; 30s × 10 randomized sets, profile mode
- **Raw Datasets**: [SUMMARY_REPORT.md](SUMMARY_REPORT.md), [benchmark_matrix.json](benchmark_matrix.json), [benchmark_summary.csv](benchmark_summary.csv)

## Key Observations

Flutter (median 0.024 ms) and Blooming (0.029 ms) exhibited lower medians, with the median across all implementations spanning 0.024–0.080 ms. P99 lag ranged from 5.54–5.82 ms, while worst-case lag reached 7.998–9.286 ms, including samples exceeding the 8.33 ms frame budget (120 Hz).

Effective generator throughput saturated at 15.83–16.46M TPS, yielding a framework update frequency of approximately 16 Hz. This run should be interpreted not as sustained 1B TPS, but as a hardware saturation stress test. While median lag remained low, tail and worst-case latency must be considered in tandem.

## Limitations

Event-loop lag serves as a probe of main-isolate responsiveness; it does not measure raw throughput, click-to-handler latency, data correctness, or dropped frames directly. Measurements reflect 10 sets on a single macOS machine in profile mode, without formal statistical significance testing or causal verification. UI Build and Raster timings are reported for diagnostic transparency and are not used as ranking criteria.

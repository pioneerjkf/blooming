# Run Assessment — 20261028_233054_003

- **Target Workload**: 100,000 TPS
- **Conditions**: Scroll animation, theme rotation, and ticker rotation enabled; 30s × 10 randomized sets, profile mode
- **Raw Datasets**: [SUMMARY_REPORT.md](SUMMARY_REPORT.md), [benchmark_matrix.json](benchmark_matrix.json), [benchmark_summary.csv](benchmark_summary.csv)

## Key Observations

Blooming (median 0.038 ms) and Flutter (0.041 ms) recorded lower medians, while Coralline and Signals registered 0.051 ms and 0.052 ms respectively, and Riverpod observed 0.129 ms. Mean lag was also higher for Riverpod (0.351 ms) compared to the other implementations (0.162–0.176 ms).

All implementations sustained the full target throughput alongside 1,000 Hz framework update rates. Across sets, median P99 lag spanned 4.90–5.28 ms, and worst-case lag remained between 6.04–7.03 ms. While Blooming and Flutter showed favorable probe lag, this does not directly measure input dispatch latency or dropped frames.

## Limitations

Event-loop lag serves as a probe of main-isolate responsiveness; it does not measure raw throughput, click-to-handler latency, data correctness, or dropped frames directly. Measurements reflect 10 sets on a single macOS machine in profile mode, without formal statistical significance testing or causal verification. UI Build and Raster timings are reported for diagnostic transparency and are not used as ranking criteria.

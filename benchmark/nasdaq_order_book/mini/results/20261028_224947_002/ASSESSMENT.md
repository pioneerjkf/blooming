# Run Assessment — 20261028_224947_002

- **Target Workload**: 10,000,000 TPS
- **Conditions**: Scroll animation, theme rotation, and ticker rotation enabled; 30s × 10 randomized sets, profile mode
- **Raw Datasets**: [SUMMARY_REPORT.md](SUMMARY_REPORT.md), [benchmark_matrix.json](benchmark_matrix.json), [benchmark_summary.csv](benchmark_summary.csv)

## Key Observations

Blooming (median 0.035 ms) and Flutter (0.036 ms) recorded lower medians. Coralline observed 0.043 ms, Signals 0.047 ms, and Riverpod 0.125 ms. P99 lag ranged from 5.09–5.98 ms, while worst-case lag spanned 8.245–9.646 ms, including samples exceeding the 120 Hz frame budget (8.33 ms).

Effective generator throughput reached 9.47–9.81M TPS, accompanied by framework update rates of 947–982 Hz. This workload operates near the saturation boundary of the host hardware. While Riverpod's lag was comparatively higher, all values represent empirical observations within this specific environment without isolated causal attribution.

## Limitations

Event-loop lag serves as a probe of main-isolate responsiveness; it does not measure raw throughput, click-to-handler latency, data correctness, or dropped frames directly. Measurements reflect 10 sets on a single macOS machine in profile mode, without formal statistical significance testing or causal verification. UI Build and Raster timings are reported for diagnostic transparency and are not used as ranking criteria.

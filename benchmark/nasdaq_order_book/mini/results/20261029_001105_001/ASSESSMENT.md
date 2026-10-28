# Run Assessment — 20261029_001105_001

- **Target Workload**: 10,000 TPS
- **Conditions**: Scroll animation enabled, theme and ticker rotation disabled; 30s × 10 randomized sets, profile mode
- **Raw Datasets**: [SUMMARY_REPORT.md](SUMMARY_REPORT.md), [benchmark_matrix.json](benchmark_matrix.json), [benchmark_summary.csv](benchmark_summary.csv)

## Key Observations

Flutter (0.055 ms), Coralline (0.057 ms), Blooming (0.058 ms), and Signals (0.059 ms) clustered tightly together within a 4-microsecond window. Riverpod observed a median of 0.277 ms. However, Riverpod's median P99 lag was lowest at 3.228 ms, demonstrating that median lag alone cannot determine tail ranking.

All implementations sustained the full 10K TPS target and 1,000 Hz framework update rate. P99 lag spanned 3.228–3.454 ms, and worst-case lag ranged between 3.994–4.308 ms. At this lower workload, differences of a few microseconds among the four closest implementations fall within runtime noise and do not substantiate user-perceptible distinctions.

## Limitations

Event-loop lag serves as a probe of main-isolate responsiveness; it does not measure raw throughput, click-to-handler latency, data correctness, or dropped frames directly. Measurements reflect 10 sets on a single macOS machine in profile mode, without formal statistical significance testing or causal verification. UI Build and Raster timings are reported for diagnostic transparency and are not used as ranking criteria.

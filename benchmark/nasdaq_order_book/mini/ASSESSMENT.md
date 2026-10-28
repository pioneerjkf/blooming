# NASDAQ Order Book Benchmark — Cross-Run Synthesis

A synthesized assessment across five distinct benchmark sessions (each comprising 10 randomized-order sets). Detailed run assessments and raw report links are provided below.

| Run Assessment | Target Workload | Key Observations |
|---|---:|---|
| [20261028_220945_001](results/20261028_220945_001/ASSESSMENT.md) | 1,000,000,000 TPS | Flutter (median 0.024 ms) and Blooming (0.029 ms) exhibited lower medians; across all implementations, medians spanned 0.024–0.080 ms. |
| [20261028_224947_002](results/20261028_224947_002/ASSESSMENT.md) | 10,000,000 TPS | Blooming (median 0.035 ms) and Flutter (0.036 ms) were lowest; Coralline recorded 0.043 ms, Signals 0.047 ms, and Riverpod 0.125 ms. |
| [20261028_233054_003](results/20261028_233054_003/ASSESSMENT.md) | 100,000 TPS | Blooming (median 0.038 ms) and Flutter (0.041 ms) were lowest; Coralline/Signals observed 0.051/0.052 ms, and Riverpod 0.129 ms. |
| [20261029_001105_001](results/20261029_001105_001/ASSESSMENT.md) | 10,000 TPS | Flutter (0.055 ms), Coralline (0.057 ms), Blooming (0.058 ms), and Signals (0.059 ms) clustered tightly together; Riverpod recorded 0.277 ms. |
| [20261029_005042_002](results/20261029_005042_002/ASSESSMENT.md) | 1,000 TPS | Flutter observed the lowest median (0.046 ms), while Signals/Blooming/Coralline all recorded 0.054 ms; Riverpod recorded 0.265 ms (mean 0.328 ms). |

## Cross-Run Interpretation

- Across all five benchmark runs, Riverpod exhibited higher event-loop lag median and mean values compared to the other implementations. While this is a consistent pattern across these sessions, these 10-set evaluations without formal hypothesis testing cannot determine general underperformance or establish root causes.
- Flutter and Blooming frequently recorded the lowest medians, but no single framework emerged as a definitive winner across all metrics. At lighter workloads (1K / 10K TPS), Flutter, Signals, Blooming, and Coralline clustered within a narrow window of tens of microseconds.
- As workload intensifies, the distinction between target TPS and physical throughput becomes crucial. Under 10M target TPS, effective generator throughput was 9.47–9.81M TPS with framework dispatch rates of 947–982 Hz. Under the 1B target TPS workload, physical throughput saturated at 15.83–16.46M TPS, dropping dispatch frequency to ~16 Hz due to background thread saturation. The 1B run should be interpreted as a hardware saturation stress test, not as successful sustained 1B throughput.
- Tail latency must be analyzed separately from median latency. Under 10M and 1B workloads, worst-case samples exceeded the 8.33 ms frame deadline (120 Hz). Note that these were captured by a 33 ms periodic sampling probe; lag samples alone do not necessarily indicate dropped frames.
- Lighter runs (1K / 10K TPS) ran with dynamic UI rotation disabled, whereas high-load runs had them enabled. Because test conditions varied, the effects of tick throughput cannot be isolated from the overhead of continuous theme/ticker swapping.

## Conclusion

Under the tested profile build on macOS and current implementations, pre-saturation event-loop lag medians were generally lower for Flutter and Blooming, while Riverpod was consistently higher. These observations serve as valuable hypotheses for further verification rather than an authoritative framework ranking. Generator TPS reflects background isolate tick throughput and is distinct from main-isolate framework update frequency. This benchmark suite did not directly measure click-to-handler input latency, data correctness, overload recovery, or Release/AOT behavior.

## Recommendations for Follow-Up Verification

1. Standardize UI animation and rotation configurations across all target TPS tiers, or explicitly split evaluations into isolated on/off comparison suites.
2. In saturation regimes, measure batch delivery counts, queue accumulation/drop rates, end-state data parity, and recovery latency following bursts.
3. Directly record input-to-handler dispatch latencies and missed frame deadlines, accompanied by repeated runs with formal confidence intervals and significance tests.
4. Document architectural batching policies and separately compare common unified dispatch policies against framework-idiomatic patterns.

For detailed methodology, refer to [BENCHMARK_METHODOLOGY.md](BENCHMARK_METHODOLOGY.md). Raw datasets can be accessed in the respective run directories via `SUMMARY_REPORT.md`, `benchmark_matrix.json`, and `benchmark_summary.csv`.

# NASDAQ Order Book Benchmark — Overall Assessment

This assessment synthesizes six benchmark executions on one macOS machine using Flutter profile builds. Each execution measured five implementations across 10 shuffled sets (50 framework runs per execution). The primary comparison is the median of per-set event-loop lag medians; lower is better. Results are descriptive observations, not statistically established rankings.

## Run Summary

| Run | Target TPS | Blooming median | Flutter median | Riverpod median | UI stress configuration |
|---|---:|---:|---:|---:|---|
| [20261028_220945_001](mini/results/20261028_220945_001/ASSESSMENT.md) | 1B | 0.029 ms | 0.024 ms | 0.080 ms | Scroll, theme, ticker on |
| [20261028_224947_002](mini/results/20261028_224947_002/ASSESSMENT.md) | 10M | 0.035 ms | 0.036 ms | 0.125 ms | Scroll, theme, ticker on |
| [20261028_233054_003](mini/results/20261028_233054_003/ASSESSMENT.md) | 100K | 0.038 ms | 0.041 ms | 0.129 ms | Scroll, theme, ticker on |
| [20261029_001105_001](mini/results/20261029_001105_001/ASSESSMENT.md) | 10K | 0.058 ms | 0.055 ms | 0.277 ms | Scroll on; theme/ticker off |
| [20261029_005042_002](mini/results/20261029_005042_002/ASSESSMENT.md) | 1K | 0.054 ms | 0.046 ms | 0.265 ms | Scroll on; theme/ticker off |
| [20261102_085725_001](mini/results/20261102_085725_001/ASSESSMENT.md) | 1B | 0.019 ms | 0.019 ms | 0.022 ms | Scroll/ticker on; theme off |

The 2026-11-02 run is a second 1B-target saturation observation under a different UI configuration from the 2026-10-28 1B run. The two 1B results should not be treated as a controlled before/after comparison.

## Overall Findings

- **Flutter and Blooming were usually among the lower-median-lag implementations.** Flutter had the lowest median at 1K and 10K; Blooming had the lowest at 100K and 10M. In the first 1B run, Flutter was lowest (0.024 ms) and Blooming next (0.029 ms). In the second 1B run, the medians were effectively tied at 0.019 ms for Flutter, Blooming, Signals, and Coralline; Riverpod recorded 0.022 ms.
- **Riverpod recorded higher median lag in these runs**, especially in the 1K–100K scenarios. This pattern is consistent across this dataset, but the benchmark does not establish general underperformance or explain its cause. The second 1B run showed a much narrower median spread than the first.
- **The two 1B targets were hardware-saturation tests, not 1B TPS throughput tests.** In the first run, observed generator throughput was about 15.83–16.46M TPS. In the second, it was about 16.45–17.51M TPS. Framework batch dispatch fell to roughly 16–18 Hz. Generator TPS measures background-isolate simulation work; it is distinct from main-isolate framework update frequency.
- **Lower lag at the 1B target may be related to the lower batch dispatch rate, but this mechanism has not been demonstrated.** The implementation uses a 1 ms periodic timer to generate batches; under saturation, expensive batch computation can reduce how often batches reach the main isolate. Fewer main-isolate updates could reduce event-loop work and help explain the low sampled medians. However, the benchmark does not record queue depth, batch handling time, or time spent idle, so it cannot establish that this caused the observed lag differences. In particular, the measurements do not support describing the main event loop as “98% idle.”
- **Tail behavior needs separate attention.** In the 10M run and the first 1B run, some worst-case lag samples exceeded the 8.33 ms frame budget associated with 120 Hz. The second 1B run's reported maximum lag was 3.15–5.47 ms. Event-loop lag is sampled every 33 ms and does not directly identify dropped frames; these are not equivalent measurements.
- **Test conditions varied by load tier.** The 1K and 10K runs disabled theme and ticker rotation; the 100K and 10M runs enabled both; the first 1B run enabled both, while the second 1B run disabled theme rotation and kept ticker rotation enabled. Throughput effects therefore cannot be isolated from UI-stress effects across tiers.

## Conclusion

Across these six executions, Flutter and Blooming frequently recorded low event-loop lag medians, while the other frameworks were close in several scenarios. The updated 1B result confirms low sampled median lag at saturation in that particular configuration, but its medians are tied at the reported precision for four implementations. These observations support further controlled testing; they do not support declaring a universal framework winner.

The suite measures main-isolate responsiveness under simulated order-book updates on one macOS host in profile mode. It does not directly establish click-to-handler latency, data correctness, event loss, overload recovery, or Release/AOT behavior. Single-machine results and 10 sets per execution do not replace independent repeated executions, confidence intervals, or formal significance testing.

The relatively high Riverpod medians in some runs are also observations, not proof that provider propagation or immutable-state handling caused them. That attribution would require profiling or targeted measurements of per-batch processing cost.

## Recommended Follow-Up

1. Repeat each target workload across independent executions and report uncertainty intervals.
2. Standardize scroll, theme, and ticker rotation across TPS tiers, or run paired UI-stress-on/off scenarios.
3. For saturation tests, measure batch delivery counts and inter-arrival times, per-batch handling time, queue growth or drops, end-state data parity, and recovery after bursts.
4. Measure input-to-handler latency and frame deadlines directly when evaluating user-perceived responsiveness.

For metric definitions and reproduction details, see [BENCHMARK_METHODOLOGY.md](mini/BENCHMARK_METHODOLOGY.md). Each linked run assessment includes its raw report and result artifacts.

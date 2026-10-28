# NASDAQ Order Book Benchmark — Overall Assessment

Five 30-second scenarios were run on one macOS machine in Flutter profile mode. Each scenario tested five state-management implementations in 10 randomized sets. The primary comparison below is event-loop-lag median; lower is better, but small differences are not evidence of statistical significance.

| Target TPS | Blooming median | Flutter baseline | Riverpod | Setup |
|---:|---:|---:|---:|---|
| 1K | 0.054 ms | 0.046 ms | 0.265 ms | Scroll on; theme/ticker rotation off |
| 10K | 0.058 ms | 0.055 ms | 0.277 ms | Scroll on; theme/ticker rotation off |
| 100K | 0.038 ms | 0.041 ms | 0.129 ms | Scroll, theme and ticker rotation on |
| 10M | 0.035 ms | 0.036 ms | 0.125 ms | Scroll, theme and ticker rotation on |
| 1B target | 0.029 ms | 0.024 ms | 0.080 ms | Scroll, theme and ticker rotation on; saturated |

## Assessment

Blooming and the Flutter baseline recorded close, generally low medians in the 10K–10M scenarios. Blooming was marginally lower at 100K and 10M; Flutter was lower at 10K. Riverpod's median and mean lag were higher in all five scenarios. These are results for these particular implementations and this host, not a universal framework ranking. No significance testing was performed.

The 1B TPS run did not reach its requested target: the generator saturated at approximately 15.8–16.5M ticks per second, and framework update frequency was about 16 Hz. Interpret this as a hardware-saturation stress scenario. At 10M and 1B targets, some worst-case lag samples exceeded the 8.33 ms budget associated with 120 Hz. The 33 ms event-loop probe is not a direct measurement of input latency or frame drops.

The lower-load runs disabled theme and ticker rotation while the higher-load runs enabled both, so these scenarios do not isolate the effect of TPS from the effect of dynamic UI work. The benchmark also does not establish data correctness, event loss behavior, overload recovery, or Release/AOT performance.

## Individual run assessments

- [1K TPS — 20261029_005042_002](mini/results/20261029_005042_002/ASSESSMENT.md)
- [10K TPS — 20261029_001105_001](mini/results/20261029_001105_001/ASSESSMENT.md)
- [100K TPS — 20261028_233054_003](mini/results/20261028_233054_003/ASSESSMENT.md)
- [10M TPS — 20261028_224947_002](mini/results/20261028_224947_002/ASSESSMENT.md)
- [1B TPS target — 20261028_220945_001](mini/results/20261028_220945_001/ASSESSMENT.md)

See [benchmark methodology](mini/BENCHMARK_METHODOLOGY.md) for metric definitions and further limitations.

# NASDAQ Order Book Benchmark: Assessments and Runs

This directory contains the NASDAQ Order Book high-frequency stream benchmark suite, methodology documentation, and historical run assessments.

## Active Benchmark Suites

* **[NASDAQ Order Book Mini Suite](mini/README.md)**: 50-level full-depth NASDAQ order book comparing 5 Flutter state-management architectures (`Blooming`, `Coralline`, `Signals`, `Flutter Vanilla`, and `Riverpod`).
* **[Methodology & Statistical Rigor](mini/BENCHMARK_METHODOLOGY.md)**: Measurement definitions, sampling mechanism (33ms event loop lag probes), multi-set trimmed mean, and limitations.

## Run Assessments

1. **[October 26, 2026 — 120 Hz Run (`20261026_201905_001`)](mini/results/20261026_201905_001/ASSESSMENT.md)**
   * **Hardware & Setup**: Apple M5 Max (18 cores), 36 GB RAM, macOS 27.0.1, 120 Hz ProMotion display (with external 60 Hz display attached).
   * **Workload**: 1,000,000,000 target TPS (synthetic capped workload), 30s measurement, 5s warmup, 10 randomized sets, static viewport (`--no-scroll-anim`).
   * **Artifacts**: [Assessment](mini/results/20261026_201905_001/ASSESSMENT.md) · [Summary Report](mini/results/20261026_201905_001/SUMMARY_REPORT.md) · [Matrix JSON](mini/results/20261026_201905_001/benchmark_matrix.json) · [Summary CSV](mini/results/20261026_201905_001/benchmark_summary.csv) · [Run Metadata](mini/results/20261026_201905_001/RUN_METADATA.md)

2. **[October 26, 2026 — 60 Hz Run (`20261026_164352_002`)](mini/results/20261026_164352_002/ASSESSMENT.md)**
   * **Hardware & Setup**: Apple M5 Max (18 cores), 36 GB RAM, macOS 27.0.1, 60 Hz display.
   * **Workload**: 1,000,000,000 target TPS (synthetic capped workload), 30s measurement, 10 randomized sets, static viewport (`--no-scroll-anim`).
   * **Artifacts**: [Assessment](mini/results/20261026_164352_002/ASSESSMENT.md) · [Summary Report](mini/results/20261026_164352_002/SUMMARY_REPORT.md) · [Matrix JSON](mini/results/20261026_164352_002/benchmark_matrix.json) · [Summary CSV](mini/results/20261026_164352_002/benchmark_summary.csv) · [Run Metadata](mini/results/20261026_164352_002/RUN_METADATA.md)

3. **[October 26, 2026 — 60 Hz Signals P99 Replication Run (`20261026_221301_003`)](mini/results/20261026_221301_003/ASSESSMENT.md)**
   * **Hardware & Setup**: Apple M5 Max (18 cores), 36 GB RAM, macOS 27.0.1, 60 Hz display.
   * **Workload**: 1,000,000,000 target TPS, 30s measurement, 10 randomized sets, static viewport (`--no-scroll-anim`). Investigating Signals tail latency repeatability.
   * **Artifacts**: [Assessment](mini/results/20261026_221301_003/ASSESSMENT.md) · [Summary Report](mini/results/20261026_221301_003/SUMMARY_REPORT.md) · [Matrix JSON](mini/results/20261026_221301_003/benchmark_matrix.json) · [Summary CSV](mini/results/20261026_221301_003/benchmark_summary.csv)

4. **[October 26, 2026 — 60 Hz Isolated Set A (`20261026_232008_004`)](mini/results/20261026_232008_004/ASSESSMENT.md)**
   * **Hardware & Setup**: Apple M5 Max (18 cores), 36 GB RAM, macOS 27.0.1, 60 Hz display, background processes closed.
   * **Workload**: 1,000,000,000 target TPS, 30s measurement, 10 randomized sets, static viewport (`--no-scroll-anim`).
   * **Artifacts**: [Assessment](mini/results/20261026_232008_004/ASSESSMENT.md) · [Summary Report](mini/results/20261026_232008_004/SUMMARY_REPORT.md) · [Matrix JSON](mini/results/20261026_232008_004/benchmark_matrix.json) · [Summary CSV](mini/results/20261026_232008_004/benchmark_summary.csv)

5. **[October 26, 2026 — 60 Hz Isolated Set B (`20261026_235828_004`)](mini/results/20261026_235828_004/ASSESSMENT.md)**
   * **Hardware & Setup**: Apple M5 Max (18 cores), 36 GB RAM, macOS 27.0.1, 60 Hz display, adjacent run examining tail latency variance.
   * **Workload**: 1,000,000,000 target TPS, 30s measurement, 10 randomized sets, static viewport (`--no-scroll-anim`).
   * **Artifacts**: [Assessment](mini/results/20261026_235828_004/ASSESSMENT.md) · [Summary Report](mini/results/20261026_235828_004/SUMMARY_REPORT.md) · [Matrix JSON](mini/results/20261026_235828_004/benchmark_matrix.json) · [Summary CSV](mini/results/20261026_235828_004/benchmark_summary.csv)

6. **[October 27, 2026 — 120 Hz Scroll Animation Active Run (`20261027_004840_001`)](mini/results/20261027_004840_001/ASSESSMENT.md)**
   * **Hardware & Setup**: Apple M5 Max (18 cores), 36 GB RAM, macOS 27.0.1, 120 Hz ProMotion display.
   * **Workload**: 1,000,000,000 target TPS, 30s measurement, 10 randomized sets, continuous scroll animation ON (`--scroll-anim`), driver retries enabled.
   * **Artifacts**: [Assessment](mini/results/20261027_004840_001/ASSESSMENT.md) · [Summary Report](mini/results/20261027_004840_001/SUMMARY_REPORT.md) · [Matrix JSON](mini/results/20261027_004840_001/benchmark_matrix.json) · [Summary CSV](mini/results/20261027_004840_001/benchmark_summary.csv)

# NASDAQ Order Book Benchmark: Assessments and Runs

This directory contains the NASDAQ Order Book high-frequency stream benchmark suite, methodology documentation, and historical run assessments.

## Active Benchmark Suites

* **[NASDAQ Order Book Mini Suite](mini/README.md)**: 50-level full-depth NASDAQ order book comparing 5 Flutter state-management architectures (`Blooming`, `Coralline`, `Signals`, `Flutter Vanilla`, and `Riverpod`).
* **[Methodology & Statistical Rigor](mini/BENCHMARK_METHODOLOGY.md)**: Measurement definitions, sampling mechanism (33ms event loop lag probes), multi-set trimmed mean, and limitations.

## Run Assessments

All previous benchmark results and run assessments have been cleared.

When new benchmark runs are completed, their assessments, setup metadata, and generated artifact references (`ASSESSMENT.md`, `SUMMARY_REPORT.md`, `benchmark_matrix.json`, `benchmark_summary.csv`) will be documented here.

To execute a benchmark session, see [NASDAQ Order Book Mini Suite](mini/README.md#reproducing-a-comparable-run) and [Methodology & Statistical Rigor](mini/BENCHMARK_METHODOLOGY.md).

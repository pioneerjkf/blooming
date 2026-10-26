# Run archive metadata

- Run ID: `20261026_164352_002`
- Run timestamp: `2026-10-26T16:43:52.337098`
- Original output: `/Users/jkf/dev/blooming_pub/blooming_dev/benchmark/nasdaq_order_book/mini/benchmark_results/20261026_164352_002`
- Original benchmark source checkout: `/Users/jkf/dev/blooming_pub/blooming_dev`
- Source checkout HEAD observed during archival: `a6c76565d0e7f425681082b224723037a0449f90`
- Runtime recorded in the original result: macOS 27.0.1 (Build 26A434), Dart 3.13.5 stable, `macos_arm64`
- Host hardware confirmed by the user as the benchmark machine: MacBook Pro (`Mac17,7`), Apple M5 Max, 18 CPU cores, 36 GB memory
- Toolchain confirmed as matching the benchmark environment: Flutter 3.47.6 stable (`5fc346839b5d0eef006ed8404392afb4dfae428d`), Dart 3.13.5, Xcode 27.1
- Mode: Flutter Driver, profile build; 30 seconds per scenario, 10 shuffled sets, scroll animation disabled
- Display refresh: 60 Hz, confirmed by the user as the benchmark display
- Configured target: 1,000,000,000 TPS. This is not measured event throughput; see `BENCHMARK_METHODOLOGY.md` and the repository assessment.

## Archive contents

- `ASSESSMENT.md`: historical interpretation of this exact run
- `benchmark_matrix.json`: raw per-run result records
- `benchmark_summary.csv`: flat per-run records
- `SUMMARY_REPORT.md`: generated benchmark report

## Reproducibility notes

The original result files recorded OS and Dart version; the user confirmed the machine, display, Flutter, and Xcode details above match the benchmark environment. The exact command line, power/thermal state, and background system load were not captured. At archival time, the benchmark source tree appeared as untracked (`?? benchmark/`) in the source checkout, so the recorded HEAD alone does not identify the exact source files used. The methodology document is copied alongside the repository assessment for context; it does not make the run fully reproducible.

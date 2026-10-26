# Run archive metadata

- Run ID: `20261026_201905_001`
- Run timestamp: `2026-10-26 20:19:05` (Asia/Seoul; recorded as `2026-10-26T20:19:05.626554`)
- Display setup: MacBook Pro built-in display at 120 Hz; external 60 Hz display connected
- Machine: same benchmark machine recorded for the 60 Hz run: MacBook Pro (`Mac17,7`), Apple M5 Max, 18 CPU cores, 36 GB memory
- OS: macOS 27.0.1 (Build 26A434), ARM64
- Toolchain: Flutter 3.47.6 stable (`5fc346839b5d0eef006ed8404392afb4dfae428d`), Dart 3.13.5, Xcode 27.1; carried forward from the confirmed shared benchmark environment, not included in this run's JSON
- Execution: Flutter Driver, profile build (`mode: drive`); 30 seconds per run, 10 sets, shuffled order
- Scenario: configured target 1,000,000,000 TPS; scroll animation disabled, static viewport
- Event-loop probe: every 33 ms; 914 samples per framework run
- Output artifacts: `benchmark_matrix.json`, `benchmark_summary.csv`, and generated `SUMMARY_REPORT.md`

## Interpretation notes

- This run was performed with the MacBook Pro built-in display at 120 Hz and an external 60 Hz display connected.
- This run does not exercise animated rendering: scroll animation is disabled and recorded FPS is only 0.4–0.5. It does not establish rendering performance at 120 Hz.
- It does not measure input-to-handler latency or frame deadline misses.
- The 1,000,000,000 TPS value is the configured target, not verified event throughput. The generator simulates only a capped portion of each batch and adds the remaining count arithmetically.
- Exact command line, power/thermal state, and background system load were not recorded.

## Archive contents

- `benchmark_matrix.json`: raw per-run measurements and environment fields emitted by the benchmark
- `benchmark_summary.csv`: flat per-run records
- `SUMMARY_REPORT.md`: generated report
- `RUN_METADATA.md`: refresh-rate and archive context, including which environment details were confirmed after the run

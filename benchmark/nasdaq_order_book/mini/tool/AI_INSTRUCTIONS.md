# AI Assistant Benchmark Execution Protocol

This document defines the **mandatory confirmation and execution protocol** that any AI assistant must follow when instructed to **"run benchmark"**, **"execute benchmark suite"**, or similar directives.

---

## ⚠️ [Mandatory] Pre-Execution Confirmation Protocol

When a user requests a benchmark run, **do NOT execute immediately with arbitrary default parameters.**
First, present the configuration parameters (or the recommended presets) below, confirm the desired settings with the user, and only then start the run.

### Configuration Parameters to Clarify

1. **Warmup Duration (`--warmup=<seconds>`)**:
   - Recommended Default: `10` seconds (essential for JIT/AOT memory pool warmup and GC stabilization)
   - Fast Smoke Test: `1` second
2. **Measurement Duration (`--duration=<seconds>`)**:
   - Recommended Default: `30` seconds (allows convergence to steady-state and reveals backlog/leak behaviors)
   - Fast Smoke Test: `3` seconds
3. **Number of Multi-Set Iterations (`--sets=<count>`)**:
   - Recommended Default: `3` or `10` sets (reduces single-run variance; required for Trimmed Mean)
   - Single Run: `1` set
4. **Randomized Execution Order (`--shuffle`)**:
   - Recommended Default: `true` (randomizes framework execution order per set to prevent thermal throttling and OS caching bias)
5. **Target Workload TPS (`--tps=<number>`)**:
   - Standard Test: `100000` (100K TPS)
   - Saturated Stress Test: `10000000` (10M TPS) or `1000000000` (1B TPS)
6. **Order Book Scroll Animation (`--scroll-anim` / `--no-scroll-anim`)**:
   - Recommended Default: `false` (`--no-scroll-anim`, static viewport focusing on pure stream/state processing)
   - Dynamic VSync Animation: `true` (`--scroll-anim`, oscillating sinusoidal viewport scroll)

---

## Standard CLI Execution Commands

Once the parameters are confirmed with the user, launch the runner:

### 1. Recommended Official Multi-Set Benchmark (Randomized Order)
```bash
cd benchmark/nasdaq_order_book/mini
dart run tool/run_all_benchmarks.dart --tps=100000 --duration=30 --warmup=10 --sets=3 --shuffle
```

### 2. High-Frequency Stress Test (Saturated Workload)
```bash
cd benchmark/nasdaq_order_book/mini
dart run tool/run_all_benchmarks.dart --tps=10000000 --duration=30 --warmup=10 --sets=3 --shuffle
```

### 3. Fast Smoke Test (CI / Quick Sanity Check)
```bash
cd benchmark/nasdaq_order_book/mini
dart run tool/run_all_benchmarks.dart --tps=100000 --duration=3 --warmup=1 --sets=1
```

---

## Result Reporting Standard

Upon benchmark completion, synthesize and report the findings adhering strictly to the following standards:

1. **Randomized Execution Order**: Report the sequence of execution for each set (e.g., `Set 1: Blooming -> Coralline -> Signals -> Riverpod -> Flutter`).
2. **Aggregated Statistics Table**: Report Event Loop Lag (Mean, Median, Trimmed Mean, P99, Max) and RSS Memory side-by-side. **Do not report Sustained TPS or Achievement Rate** as primary metrics since the synthetic tick generator caps execution and arithmetically increments the rest (see `BENCHMARK_METHODOLOGY.md`).
3. **Set Breakdown**: Provide the unfiltered per-set measurements.
4. **Artifact Links**: Link to the generated files (`SUMMARY_REPORT.md`, `benchmark_summary.csv`, `benchmark_matrix.json`).
5. **Neutral Framing & Limitations**:
   - Highlight that sub-millisecond differences may fall within runtime noise and do not prove a decisive advantage.
   - Clarify that lag measures event-loop availability, not end-to-end user input latency or data correctness.
   - Refrain from asserting speculative causal claims regarding internal framework mechanics.

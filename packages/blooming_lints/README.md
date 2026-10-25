<h1 align="center">Blooming Lints</h1>

<p align="center">
  <strong>Official High-Performance Static Analysis &amp; Self-Healing Lint Rules for Bloom and Blooming Flutter</strong>
</p>

<p align="center">
  <a href="https://pub.dev/packages/blooming_lints"><img src="https://img.shields.io/pub/v/blooming_lints.svg?style=flat-square" alt="Pub Version" /></a>
  <a href="https://pub.dev/packages/blooming_lints/score"><img src="https://img.shields.io/pub/points/blooming_lints.svg?style=flat-square" alt="Pub Points" /></a>
  <a href="https://github.com/pioneerjkf/blooming/blob/main/packages/blooming_lints/LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue.svg?style=flat-square" alt="License" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.6+-0175C2.svg?style=flat-square&logo=dart" alt="Dart SDK" /></a>
</p>

---


## Features & Rules

`blooming_lints` provides strict, real-time diagnostic checks and self-healing guidance for both human developers and AI coding agents (Antigravity, Cursor, Claude Code, Copilot).

Rules are logically categorized into **Core Reactive Invariants** (pure Dart, framework-agnostic) and **Flutter Integration Guards** (`blooming_flutter` UI & lifecycle):

### 1. Core Reactive Invariants (Pure Dart)

Rules governing the core reactive LPDAG, transactional state boundaries, and `BloomVia` dependency manifests. Fully effective in pure Dart (CLI, backend, web, package) as well as Flutter:

| Lint Rule | Severity | Description |
| :--- | :---: | :--- |
| **`avoid_escaping_via`** | Error | Prohibits calling `via()` across asynchronous gaps (`await`), inside async timers, or deferred inside event callbacks to prevent temporal inconsistency and broken epochs. |
| **`avoid_catching_via_short_circuit`** | Error | Prohibits catching broad exceptions around `via()` calls inside reactive scopes to prevent intercepting Bloom's internal short-circuit sentinel. |
| **`avoid_async_in_managed`** | Error | Prohibits passing asynchronous closures or Future/Stream return types to `managed()` to maintain pure synchronous resource lifecycle supervision. |
| **`avoid_state_writes_in_pipeline`** | Error | Prohibits writing state or mutating topology directly inside reactive pipeline evaluation or build passes. |
| **`avoid_untracked_bloom_read`** | Error | Prohibits reading `untracked(...)`, `untracked.state(...)`, or controller `.data` directly inside `BloomVia` scopes (`computed`, `composed`, `switched`, `BloomWidget`) without calling `via()` to prevent silent lost-reactivity bugs. |
| **`avoid_via_state_when_value_suffices`** | Info | Recommends calling `via(x)` directly instead of `via.state(x).data` when only the payload value is needed to ensure 0-alloc derivation. |
| **`avoid_unnecessary_via_scope`** | Info | Warns when a `computed` or `switched` scope declares a `via` parameter but never accesses it to track upstream dependencies. |

### 2. Flutter Integration Guards (`blooming_flutter`)

Rules safeguarding Flutter widget trees, element lifecycles, and rebuild optimization:

| Lint Rule | Severity | Description |
| :--- | :---: | :--- |
| **`avoid_bloom_creation_in_build`** | Error | Prohibits instantiating Bloom controllers (`BloomController`), reactive pipelines (`computed`, `managed`), signals, or effects inside Flutter `build()` methods to prevent orphan state resets and memory leaks. |
| **`avoid_escaping_scoped_controller`** | Error | Prohibits escaping `ScopedAnimationController` or its `.view` outside the widget builder scope (e.g. storing in fields, outer variables, or outer collections) to prevent stale listeners and zombie lifecycle leaks. |
| **`avoid_bridging_in_build`** | Warning | Prevents calling reactive bridging methods (`.toBloom()`, `.toBloomBy()`, `.toListenable()`) inside `build()` or reactive derivation scopes to eliminate per-frame allocations. |
| **`deactivate_effect_runner`** | Warning | Requires deactivating `EffectRunner` instances held in `State` classes inside `dispose()` to prevent memory leaks. |
| **`prefer_composed_child`** | Info | Calculates AST subtree complexity to enforce strict isolation of heavy static widget subtrees and high-frequency (e.g. `observe`) animation sources from `composed` closures via `composed.child` caching or const extraction. |
| **`prefer_bloom_over_controller`** | Info | Recommends accepting read-only `Bloom<T>` instead of mutable `BloomController<T>` in widget constructor parameters to preserve Producer/Consumer separation. |
| **`prefer_bloom_widget`** | Info | Recommends extending `BloomWidget` or `BloomAnimatedWidget` directly instead of wrapping the entire `build()` method of a `StatelessWidget` with a 1:1 `composed` functor, eliminating double-Element overhead. |

---

## Installation

Add `blooming_lints` and `custom_lint` to your `pubspec.yaml`:

```yaml
dev_dependencies:
  custom_lint: ^0.7.0
  blooming_lints: ^0.1.0
```

Enable the plugin in your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
```

---

## License

Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

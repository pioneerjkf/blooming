## 0.4.5

- **Ecosystem**: Synchronized release with Blooming ecosystem v0.4.5.

## 0.4.4

- **Ecosystem**: Synchronized release with Blooming ecosystem v0.4.4.

## 0.4.3

- **Dependencies**: Raised lower bounds of `analysis_server_plugin` (`^0.3.17`), `analyzer` (`>=13.2.0 <15.0.0`), and `analyzer_plugin` (`>=0.14.11 <0.15.0`) so `package:analysis_server_plugin/edit/range_factory.dart` is available on `dart pub downgrade`.

## 0.4.2

- **Ecosystem**: Synchronized release with Blooming ecosystem v0.4.2.

## 0.4.1

- **Lint Rules & Quick Fixes**:
  - Fixed closure boundary, package checks, and quick fix generation.
  - Avoided over-counting single-leaf const subtrees in `prefer_composed_child`.
  - Unified type/scope checks and eliminated remaining resolved-type fallthroughs and deferred boundary edge cases.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.4.1.

## 0.4.0

- **Native Analyzer Plugin Migration (`analysis_server_plugin`)**:
  - Migrated all 15 lint rules and 4 quick fixes from `custom_lint_builder` to Dart's native `analysis_server_plugin` (`^0.3.15`) and `analyzer` (`>=13.0.0 <15.0.0`), eliminating background `custom_lint` daemon overhead.
  - Raised minimum Dart SDK constraint to `^3.10.0`.
  - Updated `example/` and `test/harness/` to run directly against the native `AnalysisContextCollection` & `LinterVisitor` pipeline.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.4.0.

## 0.3.3

- **Ecosystem**: Synchronized release with Blooming ecosystem v0.3.3.

## 0.3.2

- **Control Flow Lint Alignment**:
  - Updated `avoid_escaping_via` and `avoid_untracked_bloom_read` rules to support `via.exitIfStale` alongside deprecated `via.exitIfInactive`.
  - Aligned AST type checking with `_ViaScope.async` and `via.exitIfStale`.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.3.2.

## 0.3.1

- **Type Checker**:
  - Updated `BloomTypeChecker.isControllerOrCouplerType` and AST visitors to recognize `BloomCollectionController` in `avoid_bloom_creation_in_build` and `prefer_bloom_over_controller`.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.3.1.

## 0.3.0

- **Lint Rules**:
  - Refined `avoid_untracked_bloom_read` to recognize `BloomVia` and `EffectVia` scopes and distinguish between dependency-tracking reads and early-exit arguments.
  - Eliminated false negatives when reading untracked Bloom data inside `emptyReason` parameters of `via.exit()` and `via.exitIfInactive()`.
- **Type Checker**:
  - Updated `BloomTypeChecker` to disambiguate dependency-tracking `via(...)` calls from control-flow `via.exit(...)` calls via `isBloomViaTrackingInvocation`.
  - Added full AST detection and symbol validation for `EffectVia` and `via.exit` / `via.exitIfInactive`.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.3.0.

## 0.2.5

- **Lint Rules**: Added `avoid_async_in_computed` prohibiting passing asynchronous closures (`async`/`async*`) or `Future`/`Stream` return types to synchronous `computed()`, directing users to `computed.future()` and `computed.stream()`.
- **Quick Fixes**: Added `ConvertToComputedAsyncFix` for `avoid_async_in_computed` to automatically convert synchronous `computed(...)` into `computed.future(...)` or `computed.stream(...)`.
- **Lint Rules**: Refined `avoid_async_in_managed` to prohibit `Future`/`Stream` return types in `create`/`update` while preserving synchronous resources implementing `Stream` (such as `ReceivePort` and `Socket`), and permitting synchronous teardown callbacks returning `Future<void>` in `dispose`.
- **Lint Rules**: Aligned `avoid_escaping_via` with on-demand asynchronous `BloomVia` tracking (`_ViaTrack.async`), permitting post-`await` `via()` calls directly inside owning reactive closures while continuing to flag out-of-band `Timer`, `Future.then`, event callbacks, and nested async helper functions.
- **Type Checker**: Strengthened `BloomTypeChecker` with strict `dart:async` library origin validation for `Future`, `FutureOr`, and `Timer` symbols, preventing false-positive diagnostics on user-defined symbols.
- **Dependencies**: Added `meta` (^1.18.0) dependency for explicit testing annotations.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.5.

## 0.2.4

- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.4.

## 0.2.3

- **Documentation**: Audited and aligned lint rule documentation, quick-fix descriptions, and API doc comments with the Truth Verification Protocol (TVP).
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.3.

## 0.2.2

- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.2.

## 0.2.1

- **Lint Rules**: Updated `deactivate_effect_runner` lint rule and AST type checker to recognize canonical `Effect.*` entrypoint and sub-factories.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.1.

## 0.2.0

- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.0.

## 0.1.5

- **Analysis**: Optimized analysis options to prevent custom_lint background daemon leak.
- **Type Checker**: Aligned `BloomTypeChecker` resolution for tuple and async primitives.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.1.5.

## 0.1.4

- **Rules**: Differentiated `prefer_composed_child` diagnostics with dedicated messages for high-frequency frame animation closures (`composed.animate`, `composed.drive`) and static layout containers (`Column`, `Row`, `Stack`, `Flex`, `Wrap`, `ListView`).
- **Rules**: Allowed atomic leaf widgets (e.g., `const Icon`, `const Text`) in interactive buttons (`ElevatedButton`, `FilledButton`, `TextButton`, `IconButton`) without false-positive warnings.
- **Documentation**: Added comprehensive architectural documentation for `composed.animate.child` static subtree caching across 60/120fps frame ticks and anti-pattern warnings against over-engineering with unnecessary `StatelessWidget` wrappers.

## 0.1.3

- **Rules**: Introduced `prefer_bloom_widget` lint rule detecting redundant `StatelessWidget` wrappers directly returning `composed` or `composed.animate`.
- **Fixes**: Added `ReplaceStatelessWithBloomWidgetFix` quick fix converting eligible `StatelessWidget` declarations to `BloomWidget` or `BloomAnimatedWidget`.
- **Documentation**: Updated `prefer_composed_child` docs clarifying boundary vs leaf criteria and architectural guidance.

## 0.1.2

- **Bug Fix**: Prevented stack overflow crashes on cyclic variable aliases in `avoid_untracked_bloom_read`.
- **Rules**: Extended `avoid_escaping_scoped_controller` and `prefer_bloom_over_controller` to recognize `BloomAnimatedWidget`.

## 0.1.1

- **Ecosystem**: Synchronized release with Blooming core ecosystem v0.1.1.
- **Documentation**: Updated package metadata and ecosystem repository alignment.

## 0.1.0

- Initial release of `blooming_lints` on pub.dev.

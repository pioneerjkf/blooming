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

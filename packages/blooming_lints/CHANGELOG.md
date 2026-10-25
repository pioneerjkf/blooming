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

## 0.1.2

- **Components**: Introduced `BloomAnimatedWidget` and `BloomAnimatedElement` for zero-boilerplate class-based durable animations with element-scoped `ScopedAnimationController` proxies.
- **Animation**: Liquidated imperative `onActivate` and `onDeactivate` lifecycle callbacks in `composed.animate` in favor of declarative Staged Motion.
- **Scoped DI**: Liquidated redundant `BloomControllerProvideExtension` to preserve clean Producer/Consumer boundaries (`bloom.provide` is the canonical entry point).
- **Listenable Bridges**: Aligned documentation and examples to emphasize demand-driven `toBloomBy` Listenable bridges, liquidating legacy form controller specifications.
- **Branding Assets**: Divided banner assets into `compact` and `extended` variants across neutral, dark, and light themes; designated `blooming_flutter_banner_extended_neutral.svg` as the primary README banner.

## 0.1.1

- **Assets & Branding**: Updated official high-resolution pub.dev package logo and screenshot assets.
- **Assets**: Standardized vector logo naming conventions across asset bundles.
- **Dependencies**: Bumped `blooming`, `blooming_extensions`, and `blooming_test` dependencies to `^0.1.1`.

## 0.1.0

- Initial release of `blooming_flutter` on pub.dev.

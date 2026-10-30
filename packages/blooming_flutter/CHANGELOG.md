## 0.2.4

- **Dependencies**: Bumped `blooming`, `blooming_extensions`, and `blooming_test` dependencies to `^0.2.4`.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.4.

## 0.2.3

- **Documentation**: Audited and aligned architectural foundations, README, and widget/animation API doc comments with the Truth Verification Protocol (TVP).
- **Dependencies**: Bumped `blooming`, `blooming_extensions`, and `blooming_test` dependencies to `^0.2.3`.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.3.

## 0.2.2

- **Documentation & Benchmarks**: Added empirical high-frequency NASDAQ 50-level order-book benchmark results, detailed methodology, and performance assessment references.
- **Dependencies**: Bumped `blooming`, `blooming_extensions`, and `blooming_test` dependencies to `^0.2.2`.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.2.

## 0.2.1

- **Durable Animation Status Observation**: Introduced `DurableAnimationController.observeStatus()` demand-driven reactive Bloom pipe to observe `AnimationStatus` without manual listener lifecycle management or leaks.
- **CatchUp Animation Fixes**: Resolved dormancy completion synchronization in `CatchUpAnimationController` by safely dispatching microtask completions and injecting `initialStatus` on completed reactivation.
- **Effect API Alignment**: Migrated internal widget bindings, stores, and showcases to canonical `Effect.*` sub-factories.
- **Dependencies**: Bumped `blooming`, `blooming_extensions`, and `blooming_test` dependencies to `^0.2.1`.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.1.

## 0.2.0

- **Dependencies**: Bumped `blooming`, `blooming_extensions`, and `blooming_test` dependencies to `^0.2.0`.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.0.

## 0.1.5

- **Async UI**: Introduced `BloomAsyncBuilder.tuple` constructor supporting direct declarative binding of paired `(data, pending)` or `(data, status)` tuples.
- **Branding**: Standardized documentation and naming to "Blooming Flutter".
- **Examples**: Updated showcase `AsyncSwrBuilderSection` with tuple-based stream patterns and SWR builders.
- **Dependencies**: Bumped `blooming`, `blooming_extensions`, and `blooming_test` dependencies to `^0.1.5`.

## 0.1.4

- **Assets & Branding**: Adjusted bottom padding on extended vector banner assets.
- **Examples**: Updated showcase sections (`CompositeMotionSection`, `DualEngineBattleSection`) demonstrating `composed.animate.child` static subtree caching and surgical leaf rebuild patterns.
- **Dependencies**: Bumped `blooming`, `blooming_extensions`, and `blooming_test` dependencies to `^0.1.4`.

## 0.1.3

- **Widgets**: Relaxed class modifiers on `BloomWidget`, `BloomVsyncWidget`, and `BloomAnimatedWidget` from `abstract base class` to `abstract class` to allow unconstrained subclassing across library boundaries.
- **Documentation**: Added comprehensive architectural decision matrix and situational Good/Bad cases for Widget API selection in README and `DurableAnimationController`.
- **Dependencies**: Bumped `blooming`, `blooming_extensions`, and `blooming_test` dependencies to `^0.1.3`.

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

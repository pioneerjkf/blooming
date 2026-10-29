## 0.2.2

- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.2.

## 0.2.1

- **Effect Architecture**: Promoted `sealed class Effect` to the canonical entrypoint with standardized sub-factories (`Effect(...)`, `Effect.scoped(...)`, `Effect.debounce(...)`, `Effect.throttle(...)`). Liquidated legacy top-level `effect` functor in favor of the unified `Effect` contract.
- **Lifecycle & Temporal Pipeline**: Standardized effect lifecycle naming (`EffectScope`, `onCleanup`), hardened same-turn trailing cancellation, and strengthened dual-edge validation.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.1.

## 0.2.0

### Breaking Changes & Migration Guide

- **State Producer Instantiation Unification**: Concrete constructors for state controllers (`BloomController`, `RawBloomController`, `BloomSignalController`, `BloomDraftController`) are now encapsulated and private (`._()`). All state creation must use the unified hierarchical **`blooming`** functor family.
  - **Migration Guide**:
    - `BloomController(init)` → `blooming(init)`
    - `BloomController.late()` → `blooming.late<T>()`
    - `BloomController.error(e)` → `blooming.error<T>(e)`
    - `RawBloomController(init)` → `blooming.raw(init)`
    - `RawBloomController.late()` → `blooming.raw.late<T>()`
    - `BloomSignalController()` → `blooming.signal()`
    - `BloomDraftController.list(init)` / `BloomListController(init)` → `blooming.list(init)`
    - `BloomDraftController.map(init)` / `BloomMapController(init)` → `blooming.map(init)`
    - `BloomDraftController.set(init)` / `BloomSetController(init)` → `blooming.set(init)`
- **Coupler Independence**: `BloomCoupler` explicitly retains its standalone public constructor (`BloomCoupler(...)`) as an explicit pipeline coupler and adapter rather than a state producer.
- **Collection Functor Privatization**: Collection functor implementation classes for `blooming.list`, `blooming.map`, and `blooming.set` are strictly internal and inaccessible from public API exports.

### Improvements & Hardening

- **Exception Stringification**: Hardened `BloomSnapshotExtractionException` formatting against double faults and cascading toString evaluation failures during diagnostic extraction.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.0.

## 0.1.5

- **Async Primitives**: Introduced tuple async primitives (`Bloom.tuple`, `Bloom.tupleAsync`, `BloomAsyncTuple2`, `toBloomTuple()`, `toBloomTriple()`) for ergonomic multi-signal coordination.
- **Stream Lifecycle**: Isolated Stream bridge subscription activation strictly to data demand, and made `subscribe()` fully idempotent to eliminate redundant subscriptions.
- **Exceptions**: Separated `BloomEmptyExtractionException` and `BloomErrorExtractionException` under `BloomSnapshotExtractionException` with actionable causal diagnostics and guidance.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.1.5.

## 0.1.4

- **Ecosystem**: Synchronized release with Blooming ecosystem v0.1.4.

## 0.1.3

- **Ecosystem**: Synchronized release with Blooming ecosystem v0.1.3.

## 0.1.2

- **Ecosystem**: Synchronized release with Blooming ecosystem v0.1.2.
- **Assets & Branding**: Aligned vector banner typography and grid guidelines.

## 0.1.1

- **Assets & Branding**: Updated official high-resolution pub.dev package logo and screenshot assets.
- **Documentation**: Added official vector branding assets and standardized logo representations.

## 0.1.0

- Initial release of `blooming` on pub.dev.

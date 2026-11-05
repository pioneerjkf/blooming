## 0.3.1

- **Unified Collection Controllers (`BloomCollectionController`)**:
  - Introduced `BloomCollectionController<E, C>` base class unifying `BloomListController<E>`, `BloomSetController<E>`, and `BloomMapController<K, V>`.
  - Added dual-track transactional mutation APIs: `controller.batch((c) => ...)`, `update()`, and atomic bulk operations.
  - Formalized collection proxy and draft contracts under `src/blooming/collection.dart`.
- **Signal Enhancements**:
  - Added `reset()` to `BloomSignal` and `SignalController` to reset tick count to zero.
- **LPDAG Core Engine Refinement**:
  - Renamed internal contract `_DirtySyncable` to `_DirtyResolver` in graph engine (`_UnaryEdgeMixin`, `_NaryEdgeMixin`, `_Relay`, `_PullResolver`, effect terminals) for precise semantic reflection of upstream dirty querying, resolution, and version synchronization.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.3.1.

## 0.3.0

- **Algebraic Early-Exit Control Flow (`via.exit`)**:
  - Replaced legacy `BloomGuard` with algebraic early-exit control flow via `via.exit({Object? emptyReason})` and `via.exitIfInactive({Object? emptyReason})`.
  - Migrated derived computations (`computed`, `switched`, `managed`, `Computation`) and record tuple extensions (`.allHaveData()` + `via.exit()`) to the algebraic early-exit protocol.
  - Hardened turn-isolation and exception propagation so that `via.exit()` thrown out-of-band or escaped outside evaluation closures immediately bubbles up as an unhandled `_ViaShortCircuit`.
- **Domain Separation (`BloomVia` & `EffectVia`)**:
  - Decoupled reactive data evaluation from side-effect pipelines: `BloomVia` is used exclusively for state evaluation (`computed`, `switched`, `managed`), while `EffectVia` is used for side-effect dispatch (`Effect.via`, `Effect.scoped.via`).
- **Tether Binding Alignment**:
  - Standardized `.tether()` contract across both `BloomVia.tether` and `EffectVia.tether` to link child effect lifetimes to their parent reactive scope.
- **Architectural 5-Tier Domain Structure**:
  - Restructured internal architecture into Graph (`src/graph/`), Blooming (`src/blooming/`), Bloom (`src/bloom/`), Effect (`src/effect/`), and Reflector (`src/reflector/`).
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.3.0.

## 0.2.5

- **On-Demand Asynchronous Tracking & Turn Isolation**:
  - Enabled post-`await` and post-`yield` dependency tracking via `BloomVia` (for `computed.future`, `computed.stream`) and `EffectVia` (for `Effect.via`, `Effect.scoped.via`) through `_ViaTrack` (`closed`, `sync`, `async`) and `_resultViaTrack`.
  - Enforced strict turn isolation by rotating tracker instances (`BloomVia` / `EffectVia`) on demand when a new epoch begins or the node deactivates while an asynchronous turn is in flight, preventing stale turns from mutating the active dependency graph.
  - Propagated post-`await` / post-`yield` `_ViaShortCircuit` exceptions in `_DeLorean`, `_PragueVltava`, `_ViaEffectTerminal`, and `_HandledViaEffectTerminal`.
  - Unified `BloomVia` into a single concrete `final class` and merged dependency-tracking dispatch to eliminate polymorphic call overhead on the synchronous hot path.
- **Native `FutureOr<T>` Support in `computed.future`**:
  - Accepted `FutureOr<T> Function(BloomVia via) compute` in `computed.future`, enabling 0ms synchronous instant resolution (Fast-Path) when returning synchronous values (e.g. cache hits) without microtask latency.
  - Refined `Future` instance validation and dynamic subtype unwrapping, ensuring untyped or dynamic futures resolve safely through `_FutureBloomBridge`.
- **API Refinement**: Liquidated redundant `computed.async` alias in favor of explicit `computed.future` and `computed.stream` primitives.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.5.

## 0.2.4
- **Lazy Factory Bridges**: Introduced `FutureFactoryBloomExtension` and `StreamFactoryBloomExtension` providing `.toBloom()`, `.toBloomTuple()`, and `.toBloomTriple()`.
  - Defers execution of `Future<T> Function()` until `0 -> 1` subscriber activation and refetches on subsequent reactivations.
  - Safely manages single-subscription `Stream<T>` instances (`async*` generators) across `1 -> 0 -> 1` cycles by spawning a fresh stream on each activation.
  - Implemented bulkhead isolation upon deactivation to prevent late-settling completions from contaminating subsequent states.
  - Unified internal factory architecture into `_AsyncFactoryMixin`.
- **Fault Tolerance & Synchronous Resilience**: Hardened synchronous throw protection on `future.then` and `stream.listen` invocation, ensuring synchronous bridge initiation failures transition directly into error state without escaping as unhandled errors.
- **Documentation & Spec Auditing**: Documented stream reactivation trade-offs in `_PragueVltava` and synchronized all architectural foundation documents with living documentation tests.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.4.

## 0.2.3

- **Documentation & Examples**: Audited and aligned all architectural foundation documents, README, and API doc comments with the Truth Verification Protocol (TVP), converting all inline code snippets to 100% pure Dart.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.3.

## 0.2.2

- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.2.

## 0.2.1

- **Effect Architecture**: Promoted `sealed class Effect` to the canonical entrypoint with standardized sub-factories (`Effect(...)`, `Effect.scoped(...)`, `Effect.debounce(...)`, `Effect.throttle(...)`). Liquidated legacy top-level `effect` functor in favor of the unified `Effect` contract.
- **Lifecycle & Temporal Pipeline**: Standardized effect lifecycle naming (`EffectScope`, `onCleanup`), hardened same-turn trailing cancellation, and strengthened dual-edge validation.
- **Ecosystem**: Synchronized release with Blooming ecosystem v0.2.1.

## 0.2.0

### Breaking Changes & Migration Guide

- **State Producer Instantiation Unification**: Concrete constructors for state controllers (`BloomController`, `RawBloomController`, `BloomSignalController`, `BloomCollectionController`) are now encapsulated and private (`._()`). All state creation must use the unified hierarchical **`blooming`** functor family.
  - **Migration Guide**:
    - `BloomController(init)` → `blooming(init)`
    - `BloomController.late()` → `blooming.late<T>()`
    - `BloomController.error(e)` → `blooming.error<T>(e)`
    - `RawBloomController(init)` → `blooming.raw(init)`
    - `RawBloomController.late()` → `blooming.raw.late<T>()`
    - `BloomSignalController()` → `blooming.signal()`
    - `BloomCollectionController.list(init)` → `blooming.list(init)`
    - `BloomCollectionController.map(init)` → `blooming.map(init)`
    - `BloomCollectionController.set(init)` → `blooming.set(init)`
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

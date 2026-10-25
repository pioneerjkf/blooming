# Declarative UI Refresh & Stale-While-Revalidate Patterns Specification
## (Declarative UI Refresh & Stale-While-Revalidate Patterns)

> **"When users pull to refresh, lists disappearing into loading spinners impairs visual continuity. Bloom's SWR pipeline retains cached data while coordinating background revalidation declaratively."**  
> — *Bloom Framework Core Systems Group*

---

## 1. Overview and Background: The Challenge of Flicker-Free Refreshing

Traditional Flutter applications implementing pull-to-refresh encounter common friction points:

1. **Screen Flicker and Skeleton Resets**:
   - `FutureBuilder` and standard state managers reset to `ConnectionState.waiting` or `isLoading = true` during re-fetching.
   - Visible content vanishes, replaced by loading spinners that disrupt the user experience.
2. **Boilerplate for Multi-Faceted State**:
   - Manually managing flags across cached data, top progress indicators, and error snackbars across individual `StatefulWidget` classes creates excessive ceremony.

The `.retained()` SWR buffer in `package:blooming` and widget primitives in `package:blooming_flutter` (`BloomAsyncBuilder`, `BloomPendingIndicator`) collapse this workflow into a single declarative pipeline.

---

## 2. Flutter SWR Architecture and State Transitions

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        Flutter SWR UI Architecture                     │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   [Upstream Query Source] ──► .retained(pending: isPendingCoupler)     │
│                                           │                            │
│                                           ▼ (Presents Stale Data)      │
│   [BloomAsyncBuilder / UI] ◄── [Buffered BloomSnapshot (No Flicker!)]    │
│                                           │                            │
│   [RefreshIndicator] ───────► querySource.refresh()                    │
│                               (Emits dirty pulse & runs background I/O)│
└────────────────────────────────────────────────────────────────────────┘
```

```text
[Pull-to-Refresh Gesture] ──► refreshSignal.emit()
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │ bufferedFeed (SWR Pending)          │
                  │  * data: 'Retains existing items'   │
                  │  * isPending: true (Active top bar) │
                  │  * hasData: true                    │
                  └─────────────────────────────────────┘
                                     │
                            [Network Fetch Settled]
                                     ▼
                  ┌─────────────────────────────────────┐
                  │ bufferedFeed (Settled)              │
                  │  * data: 'Swaps to fresh payload'   │
                  │  * isPending: false                 │
                  │  * hasData: true                    │
                  └─────────────────────────────────────┘
```

---

## 3. `BloomAsyncBuilder`: 4-State Declarative Branching

`BloomAsyncBuilder<T>` isolates asynchronous reactive state into `data`, `loading`, `error`, and `empty`:

```dart
BloomAsyncBuilder<List<Article>>(
  bloom: articlesBloom,
  pending: isPendingBloom,
  data: (context, articles) => ArticleListView(articles: articles),
  loading: (context) => const ArticleSkeletonShimmer(),
  error: (context, error, stack) => ErrorRetryCard(error: error),
  empty: (context) => const EmptyNotice(message: 'No articles published'),
  preserveDataOnPending: true, // Default: Preserves stale cache during refresh
);

// Or seamlessly via Named Record tuple shorthand:
BloomAsyncBuilder<List<Article>>.tuple(
  fetchArticles().toBloomTuple(),
  data: (context, articles) => ArticleListView(articles: articles),
  loading: (context) => const ArticleSkeletonShimmer(),
  error: (context, error, stack) => ErrorRetryCard(error: error),
  empty: (context) => const EmptyNotice(message: 'No articles published'),
);
```

### Intelligent Empty Detection
- **Empty Collections**: When an `empty` callback is provided and the valid payload is an empty collection (`Iterable.isEmpty` or `Map.isEmpty`), the `empty` view renders automatically, eliminating manual `if (list.isEmpty)` checks.
- **Empty Node State (`BloomPhase.empty`)**: When the upstream node is in `BloomPhase.empty`:
  - If `pending == true`: Renders `loading(context)`.
  - If `pending == false`: Renders `empty!(context)` if provided, otherwise falls back to `loading(context)`.
  *(Note: Empty screen routing in `BloomAsyncBuilder` is determined by `pending == false` and the presence of the `empty` callback, not by `emptyReason` existence.)*

### `preserveDataOnPending` Control
- `true` (default): Background revalidation (`pending == true`) retains the current `data` view rather than falling back to `loading` skeletons (Flicker-Free SWR).
- `false`: If the node currently holds valid data (`target.hasData == true`), transitions immediately into the `loading` callback during background re-evaluation.
  *(Note: If the node is currently in an `error` state, the `error` UI is retained even when `pending == true` and `preserveDataOnPending: false`.)*

---

## 4. `BloomPendingIndicator`: Lightweight Non-Intrusive Progress Canvas

Instead of full-screen overlays, `BloomPendingIndicator` renders a surgical 2px indeterminate indicator at the bottom of an `AppBar`:

```dart
// packages/blooming_flutter/lib/src/widgets/async.dart
final class BloomPendingIndicator extends BloomWidget implements PreferredSizeWidget {
  ...
  @override
  Size get preferredSize => Size.fromHeight(height); // Directly couples to AppBar.bottom
}
```

- **`composed.drive`-Driven Canvas**: Renders on the GPU canvas via `_PendingBarPainter` and hardware VSYNC ticks, bypassing widget rebuilds.
- **Subtree Isolation**: Surrounding views incur zero rebuilds; only the indicator canvas updates.

---

## 5. Production Integration Pattern

```dart
// BloomSignalController is from package:blooming (re-exported by blooming_flutter)
final refreshSignal = BloomSignalController();
final userFeed = computed.future((via) {
  via(refreshSignal.bloom);
  return apiService.fetchUserTimeline();
});
final pendingCoupler = BloomCoupler<bool>.late();
final bufferedFeed = userFeed.retained(pending: pendingCoupler);

class UserTimelineView extends StatelessWidget {
  const UserTimelineView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        // BloomPendingIndicator renders smoothly on AppBar.bottom during background I/O
        bottom: BloomPendingIndicator(target: pendingCoupler.bloom),
      ),
      body: BloomAsyncBuilder<List<TimelineItem>>(
        bloom: bufferedFeed,
        pending: pendingCoupler.bloom,
        loading: (context) => const Center(child: CircularProgressIndicator()),
        error: (context, error, stack) => Center(
          child: ElevatedButton(
            onPressed: refreshSignal.emit,
            child: const Text('Retry'),
          ),
        ),
        data: (context, timeline) => RefreshIndicator(
          onRefresh: () async => refreshSignal.emit(),
          child: ListView.builder(
            itemCount: timeline.length,
            itemBuilder: (context, index) => TimelineItemTile(item: timeline[index]),
          ),
        ),
      ),
    );
  }
}
```

---

## 6. Foundational Engineering Invariants

1. **Zero-Flicker Invariant**:
   When revalidation occurs on existing valid data, `hasData` remains `true`, preventing UI layout shifts or skeleton flashes.
2. **Atomic SWR Transitions**:
   Payloads update strictly upon full query resolution, never exposing intermediate undefined states.
3. **Isolated Pending Canvas**:
   `isPending` signals route directly to the leaf `BloomPendingIndicator`, keeping main data trees uninvoked.

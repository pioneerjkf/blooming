# Blooming Extensions

Official reactive collection operators and functional pipeline extensions for [Bloom](https://pub.dev/packages/blooming).

---

## Overview

`blooming_extensions` extends `Bloom<Iterable<E>>`, `Bloom<List<E>>`, and `Bloom<Set<E>>` with high-performance, lazy reactive collection operators.

All operators integrate seamlessly into the Bloom 2-Phase LPDAG engine:
- **Push-Dirty / Lazy-Pull**: Mutations in source collections trigger lightweight invalidation pulses; derivations evaluate lazily on-demand.
- **Immutable & Pure**: All list-producing derivations return `List.unmodifiable` views to ensure deterministic unidirectional data flow.
- **Glitch-Free**: Aggregations and filtered projections resolve consistently across complex dependency graphs without intermediate tearing.

---

## Features

- **Reactive Projections**: `.elements.map(...)`, `.elements.where(...)`, `.elements.take(...)`, `.elements.skip(...)`, `.elements.expand(...)`
- **Numeric Aggregations**: `.elements.sum`, `.elements.average`
- **Comparable Computations**: `.elements.min`, `.elements.max`, `.elements.minOrNull`, `.elements.maxOrNull`, `.elements.sorted(...)`, `.elements.sortedDescending(...)`
- **Search & Grouping**: `.elements.firstWhereOrNull(...)`, `.elements.lastWhereOrNull(...)`, `.elements.singleWhereOrNull(...)`, `.elements.groupBy(...)`, `.elements.slices(...)`
- **Index-Aware Operators**: `.elements.foldIndexed(...)`, `.elements.reduceIndexed(...)`, `.elements.none(...)`, `.elements.flattenedToList()`, `.elements.flattenedToSet()`
- **List Indexing**: `.elements.binarySearch(...)`, `.elements.lowerBound(...)`

---

## Getting Started

Add `blooming` and `blooming_extensions` to your `pubspec.yaml`:

```yaml
dependencies:
  blooming: ^0.1.0
  blooming_extensions: ^0.1.0
```

### Example Usage

```dart
import 'package:blooming/blooming.dart';
import 'package:blooming/effect.dart';
import 'package:blooming_extensions/blooming_extensions.dart';

void main() async {
  final numbersController = BloomController<List<double>>([10.0, 20.0, 30.0]);

  // Derived reactive aggregation nodes
  final sumBloom = numbersController.bloom.elements.sum;
  final avgBloom = numbersController.bloom.elements.average;

  // Reactively observe aggregations
  final runner = sumBloom.effect(() {
    print('Sum updated: ${untracked(sumBloom)}');
  }).run();

  // Mutating the upstream collection triggers lightweight on-demand evaluation
  numbersController.set([5.0, 15.0, 25.0, 35.0]);

  await Future<void>.delayed(Duration.zero);
  runner.deactivate();
}
```

---

## License

Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

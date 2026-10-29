# blooming_flutter_test

[![Pub Version](https://img.shields.io/pub/v/blooming_flutter_test.svg?style=flat-square)](https://pub.dev/packages/blooming_flutter_test)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg?style=flat-square)](https://github.com/pioneerjkf/blooming/blob/main/LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B.svg?style=flat-square&logo=flutter)](https://flutter.dev)

Unified Flutter testing harness and hierarchical widget state mocking system for the [blooming_flutter](https://pub.dev/packages/blooming_flutter) reactive UI framework.

## Features

- **Full `blooming_test` Re-export**: Import `blooming_flutter_test` to access both pure Dart unit testing utilities (`bloomTest`, `isDormant`, `hasGlitchFreedom`, `isData`, `isEmptyState`, `isErrorState`) and Flutter widget testing APIs in a single package.
- **Hierarchical Widget Mocking (`BloomTestScope` & `BloomOverride`)**: Declaratively inject mock nodes, static constants, empty placeholders, or simulated errors into the widget hierarchy via `BloomProvider`.
- **Declarative Widget Runner (`bloomWidgetTest`)**: Run widget tests with automatic scoped override injection and clean environment setup.
- **Convenient Scoped Pump (`pumpScopedWidget`)**: Direct extension on `WidgetTester` to pump any UI subtree pre-configured with active overrides.

---

## Installation

Add `blooming_flutter_test` to your `dev_dependencies` in `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  blooming_flutter_test: ^0.2.2
```

---

## Usage

### 1. Unified Imports

`package:blooming_flutter_test/blooming_flutter_test.dart` exposes everything you need:

```dart
import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
import 'package:blooming_flutter_test/blooming_flutter_test.dart';
```

### 2. Declarative Widget Testing with `bloomWidgetTest`

```dart
void main() {
  final counterBloom = blooming(0).bloom;

  bloomWidgetTest(
    'renders counter with injected override value',
    overrides: [
      counterBloom.overrideWithValue(42),
    ],
    test: (tester) async {
      await tester.pumpScopedWidget(
        MaterialApp(
          home: composed((context, via) => Text('Count: ${via.of<int>(context)}')),
        ),
      );

      expect(find.text('Count: 42'), findsOneWidget);
    },
  );
}
```

### 3. Tree-Level State Overrides with `BloomTestScope`

Override dependencies with custom mock nodes, errors, or empty states without touching production business logic:

```dart
testWidgets('renders fallback when service emits error', (tester) async {
  final userBloom = blooming<String>('Alice').bloom;

  await tester.pumpWidget(
    MaterialApp(
      home: BloomTestScope(
        overrides: [
          userBloom.overrideWithError(Exception('No Internet')),
        ],
        child: composed((context, via) {
          final state = via.state(context.bloomOf<String>());
          return Text(state.hasError ? 'Offline' : 'User: ${state.data}');
        }),
      ),
    ),
  );

  expect(find.text('Offline'), findsOneWidget);
});
```

### 4. Dynamic Reactive Mutations in Widget Tests

Verify 2-Phase LPDAG widget rebuild cycles on user interaction or state mutation:

```dart
bloomWidgetTest(
  'increments display when controller mutates',
  test: (tester) async {
    final counter = blooming(0);

    await tester.pumpScopedWidget(
      MaterialApp(
        home: BloomProvider<int>(
          bloom: counter.bloom,
          child: composed((context, via) => Text('Count: ${via.of<int>(context)}')),
        ),
      ),
    );

    expect(find.text('Count: 0'), findsOneWidget);

    // Mutate state
    counter.data = 1;
    await tester.pump();

    expect(find.text('Count: 1'), findsOneWidget);
  },
);
```

### 5. Running Pure Unit Tests

Because `blooming_flutter_test` re-exports `blooming_test`, your unit tests and widget tests share the same toolset:

```dart
bloomTest<BloomController<int>>(
  'pure business logic unit test',
  build: () => blooming(10),
  target: (ctrl) => ctrl.bloom,
  act: (ctrl) => ctrl.data = 20,
  expect: () => [10, 20],
);
```

---

## Complete Executable Example

Check out the full, runnable widget showcase at [`example/blooming_flutter_test_example.dart`](example/blooming_flutter_test_example.dart). Run it directly via:

```bash
flutter test example/blooming_flutter_test_example.dart
```

---

## License

Apache License 2.0. Copyright 2023-2026 Youngjune Jeon.

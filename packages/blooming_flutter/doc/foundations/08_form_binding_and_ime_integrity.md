# Form Input & Listenable Interoperability Invariants Specification
## (Form Input & Listenable Bridges: Native TextEditingController + toBloomBy)

> **"Forms in Flutter belong to the platform UI layer. By preserving native `TextEditingController` ownership over IME composition and caret kinematics, Bloom bridges text updates into reactive graphs with zero overhead, zero wrappers, and zero listener leaks."**  
> — *Bloom Framework Core Systems Group*

---

## 1. Overview and Background: The Unidirectional State Paradigm

Synchronizing Flutter's standard `TextEditingController` with reactive state in complex apps has traditionally led developers to build heavy bidirectional wrapper controllers. However, bidirectional synchronization often introduces subtle edge cases:
- Intermediate state re-assignments can accidentally disrupt ongoing OS IME composition (such as Korean Hangul syllable assembly or Japanese Kanji conversion).
- Bidirectional listeners require complex mutexes to avoid infinite ping-pong notification loops.

`package:blooming_flutter` resolves this by embracing **Unidirectional Data Flow**:
1. **Flutter owns the Input Buffer**: Standard `TextEditingController` handles typing, cursor movements, selection, and platform IME without third-party wrapper interference.
2. **Bloom bridges the stream via `.toBloomBy()`**: The controller's text stream is extracted into a reactive `Bloom<String>` node on-demand with automatic **Demand-Driven Dormancy** (zero listener overhead when offstage).
3. **Automated Lifecycle via `Bloom.managed`**: Controllers are allocated on mount and cleanly disposed upon unmount without requiring `StatefulWidget` boilerplate.

---

## 2. Standard Form Pipeline Architecture

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   Standard Bloom Form Input Flow                        │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   [ Keyboard Input / IME ]                                             │
│              │                                                         │
│              ▼                                                         │
│     TextEditingController (Native Flutter UI Layer)                   │
│              │                                                         │
│              ▼ .toBloomBy((c) => c.text)                                │
│       Bloom<String> (Reactive LPDAG Stream)                             │
│              │                                                         │
│              ├──► computed((via) => via(textBloom).length)              │
│              └──► computed.future((via) => api.search(via(textBloom)))  │
│                                                                        │
│   [ Demand-Driven Dormancy ]:                                          │
│   Listener is attached ONLY when active subscribers exist,             │
│   and automatically detached when the UI unmounts.                     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Production Code Patterns

### 1. Reactive Search Input with Debounced Query
```dart
// 1. Lifecycle-managed TextEditingController: auto-allocated and disposed upon unmount
final searchControllerBloom = managed<TextEditingController>(
  create: (via) => TextEditingController(),
  dispose: (c) => c.dispose(),
  graceful: Graceful.microtask,
);

// 2. Extract reactive text stream with toBloomBy
late final queryBloom = searchControllerBloom.toBloomBy((c) => c.text);

// 3. Debounce search query into an asynchronous API query
late final searchResults = computed.future<List<String>>((via) async {
  final query = via(queryBloom.debounce(const Duration(milliseconds: 300)));
  if (query.isEmpty) return const [];
  return api.search(query);
});

// 4. Pure declarative BloomWidget
base class SearchBarWidget extends BloomWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final results = via(searchResults);

    return Column(
      children: [
        TextField(
          controller: via(searchControllerBloom),
          decoration: const InputDecoration(hintText: 'Search anything...'),
        ),
        if (results.isPending) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: results.data?.length ?? 0,
            itemBuilder: (context, i) => ListTile(title: Text(results.data![i])),
          ),
        ),
      ],
    );
  }
}
```

### 2. Multi-Field Form with Validation
```dart
final formKey = GlobalKey<FormState>();

final emailCtrlBloom = managed<TextEditingController>(
  create: (via) => TextEditingController(),
  dispose: (c) => c.dispose(),
  graceful: Graceful.microtask,
);

final passwordCtrlBloom = managed<TextEditingController>(
  create: (via) => TextEditingController(),
  dispose: (c) => c.dispose(),
  graceful: Graceful.microtask,
);

late final emailBloom = emailCtrlBloom.toBloomBy((c) => c.text);
late final passwordBloom = passwordCtrlBloom.toBloomBy((c) => c.text);

// Reactive form validity computation without full widget rebuilds
late final isFormValidBloom = computed<bool>((via) {
  final email = via(emailBloom);
  final password = via(passwordBloom);
  return email.contains('@') && password.length >= 8;
});

base class LoginForm extends BloomWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    final isValid = via(isFormValidBloom);

    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: via(emailCtrlBloom),
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextFormField(
            controller: via(passwordCtrlBloom),
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          ElevatedButton(
            onPressed: isValid ? () => submitForm() : null,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
```

---

## 4. Foundational Engineering Invariants

1. **Native IME & Caret Fidelity**:
   By relying directly on Flutter's native `TextEditingController`, all platform-specific IME behaviors (Hangul assembly, Kanji candidates, accent diacritics) and mid-string caret positions are preserved with 100% platform fidelity.
2. **Zero-Leak Dormancy**:
   `toBloomBy` automatically attaches a listener to the controller when observed by active UI elements and detaches it upon Inactive Dormancy.
3. **Ecosystem Compatibility**:
   Any specialized `TextEditingController` subclass (e.g. masked inputs, currency formatters) can be plugged directly into Bloom via `.toBloomBy((c) => c.text)` without requiring custom wrapper adapters.

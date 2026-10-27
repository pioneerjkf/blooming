// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/effect.dart';
import 'package:blooming/blooming.dart';

void main() async {
  print('=== Bloom Reactive Engine: Core Pipeline Showcase ===\n');

  // 1. Reactive Node: Source Handle (Producer / Consumer Separation) & Discrete Signal Trigger
  final searchController = blooming<String>('');
  final refreshTrigger = blooming.signal(); // Discrete manual refresh trigger

  // 2. Fluent Operators & Dynamic Triad (Debounce + Async Derivation + Distinct)
  final debouncedQuery = searchController.bloom.debounced(
    const Duration(milliseconds: 50),
  );

  final searchResults = computed.future(
    (via) async {
      via(refreshTrigger.bloom); // Declarative re-fetch trigger on discrete pulse
      final query = via(debouncedQuery);
      if (query.trim().isEmpty) return <String>[];

      // Simulating remote search query
      return [
        'Package: blooming ($query)',
        'Documentation: $query guide',
        'API Reference: $query architecture',
      ];
    },
    initialFactory: () => <String>[],
  ).distinct();

  // 3. Reactive Terminal: Side-Effect Runner (Push-dirty scheduled dispatch)
  final resultsRunner = searchResults.effect(() {
    print('[UI Terminal] Fresh Results: ${untracked(searchResults)}');
  }).start();

  // 4. Execution & Side-Effects (Zero-cycle terminal sink from package:blooming/effect.dart)
  final analyticsRunner = searchController.bloom.effect.debounce(
    const Duration(milliseconds: 50),
    () {
      final query = searchController.data;
      if (query.isNotEmpty) {
        print('[Side-Effect] 📊 Logged search analytics: "$query"');
      }
    },
  ).start();

  // 5. State Mutation Upstream
  print('-> Updating query to "dart"');
  searchController.data = 'dart';

  // Instant Synchronous Lazy-Pull (Direct property access with 0 tracking overhead)
  print('-> Instant Raw Read: searchController.data = "${searchController.data}"');

  // Await debounced timers and async microtask resolution
  await Future<void>.delayed(const Duration(milliseconds: 150));
  await Future<void>.delayed(Duration.zero);

  // 6. Safe 3-State FSM Phase Pattern Matching (Dart 3 Exhaustive Switch)
  final message = switch (untracked.state(searchResults).phase) {
    BloomPhase.valid => '[FSM Phase] Confirmed valid results: ${untracked(searchResults).length} items',
    BloomPhase.empty => '[FSM Phase] Pending or Empty',
    BloomPhase.error => '[FSM Phase] Error occurred: ${untracked.state(searchResults).error}',
  };
  print(message);

  // 7. Discrete Signal Emission (Manual Refresh / Invalidation Trigger)
  print('\n-> Emitting manual refresh pulse (Pull-to-Refresh)');
  refreshTrigger.emit();
  await Future<void>.delayed(Duration.zero);

  // 8. Clean up: Detach upstream edges (Zero-leak Inactive Dormancy)
  print('\n-> Stopping runners');
  resultsRunner.stop();
  analyticsRunner.stop();
}

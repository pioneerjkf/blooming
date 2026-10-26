// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:blooming/blooming.dart';

/// Showcase 1: Reactive Nodes - Source Handles & 3-State FSM Snapshot
///
/// Demonstrates:
/// 1. [BloomController] & [RawBloomController] (Producer vs Consumer encapsulation)
/// 2. [BloomSignalController] (Discrete event signals)
/// 3. [BloomSnapshot] & 3-State FSM Pattern Matching (`data`, `empty`, `error`)
void main() {
  print('--- 1. Producer / Consumer Encapsulation ---');
  // Controller is the mutable Producer handle; .bloom is the read-only Consumer view
  final counterController = blooming<int>(0);
  final Bloom<int> counterView = counterController.bloom;

  print('Initial Counter: ${untracked(counterView)}');
  counterController.data = 42;
  print('Updated Counter: ${untracked(counterView)}\n');

  print('--- 2. Discrete Event Signals ---');
  // Signals model stateless pulses (e.g. button clicks, refresh events)
  final refreshSignalController = blooming.signal();
  final BloomSignal refreshSignal = refreshSignalController.bloom;

  // Pattern A: Discrete invalidation pulse via BloomVia
  final autoRefreshed = computed((via) {
    via(refreshSignal);
    return 'AutoRefreshed -> counter: ${via(counterView)}';
  });

  // Pattern B: Dynamic tracking via BloomVia (when tick sequence number is needed)
  final syncCount = computed((via) {
    final signalTick = via(refreshSignal);
    final value = via(counterView);
    return 'Synced #$signalTick -> value: $value';
  });

  print(untracked(autoRefreshed));
  print(untracked(syncCount)); // Initial tick 0
  refreshSignalController.emit(); // Emits next version tick
  print(untracked(autoRefreshed));
  print(untracked(syncCount)); // Synced #1 -> value: 42\n

  print('--- 3. 3-State FSM Snapshot ([BloomSnapshot]) ---');
  // State 1: Valid Data
  final validNode = Bloom<String>.constant('Active Session');
  print('State: hasData=${untracked.state(validNode).hasData}, data="${untracked(validNode)}"');

  // State 2: Explicit Empty (null is a valid data, empty is a distinct FSM state)
  final emptyNode = Bloom<String>.empty('WaitingForNetwork');
  print('State: isEmpty=${untracked.state(emptyNode).isEmpty}, reason="${untracked.state(emptyNode).emptyReason}"');

  // State 3: Failure Boundary
  final errorNode = Bloom<String>.error(Exception('Connection timeout'));
  print('State: hasError=${untracked.state(errorNode).hasError}, error="${untracked.state(errorNode).error}"\n');

  print('--- 4. Safe Pattern Matching via untracked.state(node).phase ---');
  void printStatus(Bloom<String> node) {
    final state = untracked.state(node);
    switch (state.phase) {
      case BloomPhase.valid:
        print('  -> [VALID]: ${untracked(node)}');
      case BloomPhase.empty:
        print('  -> [EMPTY]: Unready (${state.emptyReason})');
      case BloomPhase.error:
        print('  -> [ERROR]: Failed with ${state.error}');
    }
  }

  printStatus(validNode);
  printStatus(emptyNode);
  printStatus(errorNode);
}

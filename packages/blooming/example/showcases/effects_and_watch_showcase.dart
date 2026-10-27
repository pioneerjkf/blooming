// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:blooming/effect.dart';
import 'package:blooming/blooming.dart';

/// Showcase 4: Execution & Side-Effects (1-Tick Compressed)
///
/// Demonstrates Bloom's terminal side-effects architecture:
/// 1. `bloom.effect().start()`: Standalone active runner dedicated to executing a 1:1 single node side-effect
/// 2. [Effect] via [EffectRunner]: Dynamic [BloomVia] dependency tracking with standalone execution
/// 3. [EffectScope]: Declarative effect providing [EffectScope] for teardown / cleanup callbacks
/// 4. `bloom.effect.debounce()` & `bloom.effect.throttle()`: Time-domain rate limiters
void main() async {
  print('=== Execution & Side-Effects ===\n');

  // ---------------------------------------------------------------------------
  // 1. bloom.effect().start(): 1:1 State Side-Effect
  // ---------------------------------------------------------------------------
  print('--- 1. bloom.effect().start() ---');
  final score = blooming<int>(0);

  final scoreRunner = score.bloom.effect(() {
    print('  [Runner] Score updated to: ${untracked(score.bloom)}');
  }).start();

  score.data = 10;
  await Future<void>.delayed(Duration.zero); // Microtask batch flush
  scoreRunner.stop();
  print('');

  // ---------------------------------------------------------------------------
  // 2. Effect.via + start(): Dynamic BloomVia Terminal Sink
  // ---------------------------------------------------------------------------
  print('--- 2. Effect.via().start() ---');
  final user = blooming<String>('Alice');
  final role = blooming<String>('Member');

  // Executes automatically when any dependency read via [via] mutates
  final auditRunner = Effect.via((via) {
    final currentName = via(user.bloom);
    final currentRole = via(role.bloom);
    print('  [Audit Runner] 📝 Logging: User $currentName has role $currentRole');
  }).start();

  await Future<void>.delayed(Duration.zero); // Initial run

  role.data = 'SuperAdmin';
  await Future<void>.delayed(Duration.zero); // Reacts to role change

  auditRunner.stop();
  print('');

  // ---------------------------------------------------------------------------
  // 3. effect.scoped: Cleanup & Teardown Handlers
  // ---------------------------------------------------------------------------
  print('--- 3. effect.scoped with Cleanup ---');
  final channel = blooming<String>('general');

  // Runs on mutations and cleans up resources from previous turn
  final channelRunner = channel.bloom.effect.scoped((scope) {
    final currentChannel = channel.data;
    print('  [Channel Runner] 📡 Subscribing to #$currentChannel');

    scope.onCleanup(() {
      print('  [Channel Cleanup] 🛑 Leaving channel #$currentChannel');
    });
  }).start();

  channel.data = 'announcements';
  await Future<void>.delayed(Duration.zero);

  channel.data = 'random';
  await Future<void>.delayed(Duration.zero);

  channelRunner.stop();
  print('');

  // ---------------------------------------------------------------------------
  // 4. bloom.effect.debounce & throttle
  // ---------------------------------------------------------------------------
  print('--- 4. bloom.effect.debounce & throttle ---');
  final searchInput = blooming<String>('');

  final debouncedLogger = searchInput.bloom.effect.debounce(
    const Duration(milliseconds: 30),
    () {
      print('  [Debounced Effect] 🚀 Search API Request: "${searchInput.data}"');
    },
  ).start();

  // Bursty input
  searchInput.data = 'fl';
  searchInput.data = 'flu';
  searchInput.data = 'flutt';
  searchInput.data = 'flutter';

  // Wait for debounce silence window
  await Future<void>.delayed(const Duration(milliseconds: 50));
  debouncedLogger.stop();
  print('\n=== End Showcase ===');
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
import '../../models/section.dart';
import '../../sections/async_swr_builder_section.dart';

/// Interactive Demo User model for async showcases.
class DemoUser {
  const DemoUser({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarIcon,
    required this.bio,
    required this.fetchedAt,
  });

  final String id;
  final String name;
  final String role;
  final IconData avatarIcon;
  final String bio;
  final DateTime fetchedAt;
}

/// Sub-store for Section 06: Async UI, SWR & BloomPendingIndicator.
class AsyncSwrBuilderStore {
  AsyncSwrBuilderStore({int initialLatency = 500})
      : _latencyMs = blooming<int>(initialLatency) {
    _rawFuture = computed.future<DemoUser?>((via) async {
      final query = via(_query.bloom);
      final latency = via(_latencyMs.bloom);

      // Artificial asynchronous latency simulation
      if (latency > 0) {
        await Future<void>.delayed(Duration(milliseconds: latency));
      }

      if (query == 'Error') {
        throw Exception('Simulated Network 500: Failed to fetch user profile');
      }

      if (query == 'Empty') {
        return null;
      }

      return switch (query) {
        'Alice' => DemoUser(
            id: 'usr_001',
            name: 'Alice Johnson',
            role: 'Principal Systems Architect',
            avatarIcon: Icons.architecture_rounded,
            bio: 'Specializing in LPDAG graph compilers & reactive systems.',
            fetchedAt: DateTime.now(),
          ),
        'Bob' => DemoUser(
            id: 'usr_002',
            name: 'Bob Smith',
            role: 'Kernel Performance Hacker',
            avatarIcon: Icons.memory_rounded,
            bio: 'Obsessed with zero-alloc inline functors & cache lines.',
            fetchedAt: DateTime.now(),
          ),
        'Charlie' => DemoUser(
            id: 'usr_003',
            name: 'Charlie Davis',
            role: 'Product UX Designer',
            avatarIcon: Icons.palette_rounded,
            bio: 'Designing flicker-free micro-interactions & fluid motion.',
            fetchedAt: DateTime.now(),
          ),
        _ => DemoUser(
            id: 'usr_999',
            name: query,
            role: 'Guest Contributor',
            avatarIcon: Icons.person_rounded,
            bio: 'Exploring declarative reactive Flutter architectures.',
            fetchedAt: DateTime.now(),
          ),
      };
    });

    userProfile = _rawFuture.retained(pending: _pendingCoupler);
  }

  final _query = blooming<String>('Alice');
  final _preserveData = blooming<bool>(true);
  final BloomController<int> _latencyMs;
  final _fetchCount = blooming<int>(1);
  final _pendingCoupler = BloomCoupler<bool>.late();

  late final Bloom<DemoUser?> _rawFuture;

  /// Retained SWR node holding prior user profile data during background re-queries.
  late final Bloom<DemoUser?> userProfile;

  Bloom<String> get query => _query.bloom;
  Bloom<bool> get preserveData => _preserveData.bloom;
  Bloom<int> get latencyMs => _latencyMs.bloom;
  Bloom<int> get fetchCount => _fetchCount.bloom;
  Bloom<bool> get pending => _pendingCoupler.bloom;

  /// Retained SWR tuple holding ({data, pending}) directly for BloomAsyncBuilder.tuple.
  ({Bloom<DemoUser?> data, Bloom<bool> pending}) get userTuple =>
      (data: userProfile, pending: pending);

  void setQuery(String newQuery) {
    _fetchCount.set(_fetchCount.data + 1);
    _query.set(newQuery);
  }

  void togglePreserveData() => _preserveData.set(!_preserveData.data);

  void setLatency(int ms) => _latencyMs.set(ms);

  void refresh() {
    _fetchCount.set(_fetchCount.data + 1);
    final current = _query.data;
    // Re-trigger by setting identical or re-query
    _query.set(current);
  }

  ShowcaseSection get section => ShowcaseSection(
        id: '06_async_swr_builder',
        number: '06',
        title: 'Async UI, SWR & BloomPendingIndicator',
        subtitle:
            'Declarative 4-state asynchronous building, flicker-free SWR, and surgical pending indicators',
        badge: 'Async SWR',
        icon: Icons.cloud_sync_rounded,
        codeSnippet: '''
// 1. Declarative 4-state builder with SWR (Stale-While-Revalidate)
BloomAsyncBuilder<DemoUser?>(
  bloom: store.userProfile,
  pending: store.pending,
  preserveDataOnPending: true, // Flicker-free: retains stale data while refetching!
  data: (context, user) => user == null ? const EmptyNotice() : UserCard(user: user),
  loading: (context) => const ShimmerPlaceholder(),
  error: (context, error, stack) => ErrorCard(error: error),
  empty: (context) => const EmptyNotice(),
);

// 2. Surgical isolated Pending Indicator (Zero rebuild to surrounding tree)
BloomPendingIndicator(
  target: store.pending,
  height: 3.5,
  color: Colors.indigoAccent,
);

// 3. Ergonomic Tuple Shorthand (Directly binds to ({data, pending}))
BloomAsyncBuilder<DemoUser?>.tuple(
  store.userTuple,
  preserveDataOnPending: true,
  data: (context, user) => Text('Loaded: \${user?.name}'),
  loading: (context) => const CircularProgressIndicator(),
  error: (context, err, _) => Text('Error: \$err'),
  empty: (context) => const Text('No profile'),
);
''',
        highlights: const [
          'Zero-Flicker SWR: Retains previous valid data during background re-evaluation with preserveDataOnPending: true.',
          'BloomPendingIndicator: Surgical 2px~4px linear micro-indicator binding to Bloom<bool> with 0 rebuild to surrounding tree.',
          '4-State Declarative Pattern: Clean separation of data, loading, error, and empty branch states.',
          'Ergonomic Tuple Shorthand: BloomAsyncBuilder.tuple accepts ({Bloom<T> data, Bloom<bool> pending}) directly from toBloomTuple() or retainedTuple().',
        ],
        roadmapTree: '''
[Bloom Async UI & SWR Pipeline]
 ├── BloomAsyncBuilder<T>(...)               -> Declarative 4-State SWR Builder
 │    ├── BloomAsyncBuilder.tuple(tuple)     -> Ergonomic named shorthand for ({data, pending})
 │    ├── bloom: Bloom<T>                     -> Primary reactive state node
 │    ├── pending: Bloom<bool>                -> Background mutation / fetch indicator
 │    ├── preserveDataOnPending: true       -> Zero-Flicker stale cache retention
 │    ├── data: (context, data) => ...
 │    ├── loading: (context) => ...
 │    ├── error: (context, err, stack) => ...
 │    └── empty: (context) => ...
 │
 └── BloomPendingIndicator(...)              -> Surgical isolated micro-indicator
      ├── target: Bloom<bool>                -> Direct binding with 0 tree rebuild
      └── height / color / backgroundColor
''',
        builder: () => AsyncSwrBuilderSectionDemo(),
      );
}

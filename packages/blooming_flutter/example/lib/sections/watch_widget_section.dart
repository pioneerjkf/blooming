// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
import '../components/showcase_card.dart';
import '../store/showcase_store.dart';

/// Section 01: BloomWidget & Dynamic Dependency Discovery
base class BloomWidgetSectionDemo extends BloomWidget {
  const BloomWidgetSectionDemo({super.key});

  @override
  Widget build(BuildContext context, BloomVia via) {
    // Zero prop-drilling: Look up parent ShowcaseStore from BloomProvider
    final store = via.of<ShowcaseStore>(context).sections.bloomWidget;

    // Dynamic dependency discovery:
    // When showDetails is false, store.userStatus is NEVER watched.
    final count = via(store.counter);
    final showDetails = via(store.showDetails);

    return Column(
      children: [
        ShowcaseCard(
          title: 'Dynamic Dependency Discovery',
          badge: 'BloomWidget',
          description:
              'BloomWidget dynamically discovers and diffs active Bloom dependencies in 1-pass zero-allocation Epoch diffing. Unexecuted branches never register dependency graph edges.',
          child: Column(
            children: [
              SandboxContainer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Counter Value: $count',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigoAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (showDetails) ...[
                      // This branch is only tracked when showDetails == true
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.green.withAlpha(100)),
                        ),
                        child: Text(
                          'User Status: ${via(store.userStatus)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        '(Detail branch inactive — status Bloom is not watched)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Controls
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: store.increment,
                    child: const Text('Increment Count'),
                  ),
                  OutlinedButton(
                    onPressed: store.reset,
                    child: const Text('Reset'),
                  ),
                  FilterChip(
                    label: const Text('Toggle Dynamic Branch'),
                    selected: showDetails,
                    onSelected: store.toggleDetails,
                  ),
                  if (showDetails)
                    OutlinedButton(
                      onPressed: store.cycleUserStatus,
                      child: const Text('Change Status'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

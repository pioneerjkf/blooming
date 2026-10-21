// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
import '../../models/section.dart';
import '../../sections/foundation_bridge_section.dart';

/// Sub-store for Section 09: Foundation & Listenable Bridge
class FoundationBridgeStore {
  final textController = TextEditingController(text: 'Reactive Flutter');
  late final textBloom = textController.toBloomBy((c) => c.text);

  final counterController = BloomController<int>(10);
  late final counterListenable = counterController.bloom.toListenable();

  void incrementCounter() => counterController.set(counterController.data + 1);

  void resetCounter() => counterController.set(10);

  ShowcaseSection get section => ShowcaseSection(
        id: '11_foundation_bridge',
        number: '11',
        title: 'Foundation & Listenable Bridges',
        subtitle: 'Two-way bridges between Flutter Listenable and Bloom nodes',
        badge: 'Bridges',
        icon: Icons.sync_alt_rounded,
        codeSnippet: '''
// 1. Input Bridge: Convert TextEditingController to reactive Bloom
final textController = TextEditingController();
late final textBloom = textController.toBloomBy((c) => c.text);

// 2. Output Bridge: Convert Bloom to ValueListenable
final counter = BloomController<int>(0);
final ValueListenable<int> listenable = counter.bloom.toListenable();''',
        highlights: const [
          'Listenable.toBloom() / toBloomBy(): Bridges Flutter inputs seamlessly into Bloom pipelines.',
          'Bloom.toListenable(): Enables interoperability with standard Flutter ValueListenableBuilders.',
          'Automatic subscription lifecycle upon Bloom activation/deactivation.',
        ],
        roadmapTree: '''
Listenable.toBloom() / .toBloomBy(selector)      -> Bridges Flutter inputs to Bloom<T>
Bloom<T>.toListenable()                        -> Bridges Bloom<T> to ValueListenable<T>
Stream<T>.toBloom()                            -> Bridges async streams to Bloom<T>
''',
        builder: () => FoundationBridgeSectionDemo(),
      );
}

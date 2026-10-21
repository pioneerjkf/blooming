// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blooming_flutter/blooming_flutter.dart';
import 'package:blooming_flutter_example/main.dart';
import 'package:blooming_flutter_example/store/showcase_store.dart';

void main() {
  testWidgets(
      'BloomShowcaseApp renders and switches through all 18 sections without exceptions',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final store = ShowcaseStore(textEditingGraceful: Graceful.none);
    await tester.pumpWidget(BloomShowcaseApp(store: store));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify initial render (Section 01)
    expect(find.text('Bloom Flutter Showcase'), findsOneWidget);
    expect(find.text('BloomWidget & Dynamic Discovery'), findsWidgets);

    final app = tester.widget<BloomShowcaseApp>(find.byType(BloomShowcaseApp));
    final sections = store.sections.all;

    // Iterate through all sections
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      app.store.selectSection(i);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(section.title), findsWidgets);
    }
    // Test toggle sidebar
    app.store.toggleSidebar();
    await tester.pump(const Duration(milliseconds: 300));
    app.store.toggleSidebar();
    await tester.pump(const Duration(milliseconds: 300));

    // Flush any pending async timers
    await tester.pump(const Duration(seconds: 1));
  });
}

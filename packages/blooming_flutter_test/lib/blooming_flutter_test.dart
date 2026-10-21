// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

/// Complete, unified testing harness for Flutter apps using the Bloom reactive framework.
///
/// Re-exports pure Dart `blooming_test` completely, allowing developers and AI agents to import
/// a single package for all unit tests and widget tests.
///
/// Provides:
/// * [bloomWidgetTest] declarative widget test runner
/// * [BloomTestScope] & [BloomOverride] declarative node mocking system
/// * [BloomTesterScopeExtension.pumpScopedWidget]
/// * Full `blooming_test` re-export ([bloomTest], [FakeAsync], [isDormant], [isActive], [hasGlitchFreedom], etc.)
/// * Full `flutter_test` re-export ([testWidgets], [find], [expect], [WidgetTester], etc.)
library blooming_flutter_test;

// Re-export pure Dart blooming_test (hiding flutter_test conflicts)
export 'package:blooming_test/blooming_test.dart'
    hide
        test,
        group,
        expect,
        expectLater,
        isInstanceOf,
        setUp,
        setUpAll,
        tearDown,
        tearDownAll;

// Re-export Flutter official test framework
export 'package:flutter_test/flutter_test.dart';

// Export Flutter-specific Bloom test features
export 'src/runner.dart';
export 'src/scope.dart';

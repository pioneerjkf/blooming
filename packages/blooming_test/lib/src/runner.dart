// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart' as test_pkg;
import 'package:blooming/blooming.dart';

import 'matchers.dart';

// =============================================================================
// bloomTest Declarative Reactive Test Runner
// =============================================================================

/// A declarative, atomic unit test runner tailored specifically for the Bloom reactive framework.
///
/// Encapsulates the entire testing lifecycle of reactive state pipelines:
/// 1. Instantiates the state container or store via [build].
/// 2. If [target] is provided, automatically establishes an active observation subscription
///    ([RawBloomTerminal]), recording an ordered sequence of [BloomSnapshot] emissions.
/// 3. Executes state mutations via [act].
/// 4. If [wait] is specified, controls virtual time via [fakeAsync] and flushes microtasks.
/// 5. Validates expected state transitions via [expect] (matching [BloomSnapshot] sequences or raw values).
/// 6. Verifies invocations and mocks via [verify].
/// 7. Automatically detaches all subscriptions and executes [tearDown] with 0% state pollution.
///
/// * [description]: The description of the unit test case.
/// * [build]: Factory callback constructing the state container or store under test.
/// * [seed]: Optional setup callback invoked on the built target before subscribing to [target].
/// * [target]: Optional selector returning the [Bloom] node to observe and record snapshots from.
/// * [act]: Optional callback performing synchronous or asynchronous state mutations on the target.
/// * [wait]: Optional virtual time duration to elapse via [fakeAsync] after [act].
/// * [expect]: Optional callback returning the expected list of values, snapshots, or [test_pkg.Matcher].
/// * [errors]: Optional callback returning the expected list or matcher of uncaught exceptions thrown in [act].
/// * [verify]: Optional post-act verification callback receiving the built instance.
/// * [tearDown]: Optional cleanup callback invoked in a `finally` block after terminal deactivation.
/// * [tags]: Optional test tags forwarded to `package:test`.
/// * [retry]: Optional retry count forwarded to `package:test`.
/// * [testOn]: Optional platform selector expression forwarded to `package:test`.
/// * [timeout]: Optional test execution [test_pkg.Timeout] forwarded to `package:test`.
/// * [skip]: Whether to skip this test case. Defaults to `false`.
///
/// ## Examples
/// ```dart
/// bloomTest<CounterStore>(
///   'increments counter value and records snapshots',
///   build: () => CounterStore(),
///   target: (store) => store.count.bloom,
///   act: (store) => store.increment(),
///   expect: () => [
///     BloomSnapshot(0),
///     BloomSnapshot(1),
///   ],
/// );
/// ```
void bloomTest<T>(
  String description, {
  required T Function() build,
  void Function(T target)? seed,
  Bloom Function(T target)? target,
  FutureOr<void> Function(T target)? act,
  Duration? wait,
  dynamic Function()? expect,
  dynamic Function()? errors,
  void Function(T target)? verify,
  void Function(T target)? tearDown,
  dynamic tags,
  int? retry,
  dynamic testOn,
  test_pkg.Timeout? timeout,
  bool skip = false,
}) {
  test_pkg.test(
    description,
    () async {
      if (wait != null) {
        fakeAsync((async) {
          final instance = build();
          seed?.call(instance);
          RawBloomTerminal? terminal;
          final snapshots = <BloomSnapshot>[];
          final caughtErrors = <Object>[];

          try {
            if (target != null) {
              final node = target(instance);
              snapshots.add(untracked.state(node).snapshot);
              terminal = RawBloomTerminal(
                node,
                onInvalidated: () {
                  snapshots.add(untracked.state(node).snapshot);
                },
              );
              terminal.activate();
            }

            Object? asyncActError;
            StackTrace? asyncActStackTrace;
            try {
              final actResult = act?.call(instance);
              if (actResult is Future) {
                actResult.catchError((Object error, StackTrace stackTrace) {
                  asyncActError = error;
                  asyncActStackTrace = stackTrace;
                });
              }
              async.elapse(wait);
              async.flushMicrotasks();

              if (asyncActError != null) {
                if (errors == null) {
                  Error.throwWithStackTrace(
                    asyncActError!,
                    asyncActStackTrace ?? StackTrace.current,
                  );
                }
                caughtErrors.add(asyncActError!);
              }
            } catch (error) {
              if (errors == null) rethrow;
              caughtErrors.add(error);
            }

            if (expect != null) {
              _assertExpect(snapshots, expect());
            }

            if (errors != null) {
              test_pkg.expect(caughtErrors, errors());
            }

            verify?.call(instance);
          } finally {
            terminal?.deactivate();
            tearDown?.call(instance);
          }
        });
      } else {
        final instance = build();
        seed?.call(instance);
        RawBloomTerminal? terminal;
        final snapshots = <BloomSnapshot>[];
        final caughtErrors = <Object>[];

        try {
          if (target != null) {
            final node = target(instance);
            snapshots.add(untracked.state(node).snapshot);
            terminal = RawBloomTerminal(
              node,
              onInvalidated: () {
                snapshots.add(untracked.state(node).snapshot);
              },
            );
            terminal.activate();
          }

          try {
            final actResult = act?.call(instance);
            if (actResult is Future) {
              await actResult;
            }
            await Future<void>.delayed(Duration.zero);
          } catch (error) {
            if (errors == null) rethrow;
            caughtErrors.add(error);
          }

          if (expect != null) {
            _assertExpect(snapshots, expect());
          }

          if (errors != null) {
            test_pkg.expect(caughtErrors, errors());
          }

          verify?.call(instance);
        } finally {
          terminal?.deactivate();
          tearDown?.call(instance);
        }
      }
    },
    tags: tags,
    retry: retry,
    testOn: testOn,
    timeout: timeout,
    skip: skip,
  );
}

void _assertExpect(List<BloomSnapshot> snapshots, dynamic expected) {
  if (expected is test_pkg.Matcher) {
    test_pkg.expect(snapshots, expected);
    return;
  }
  if (expected is List) {
    if (expected.isEmpty) {
      test_pkg.expect(snapshots, test_pkg.isEmpty);
      return;
    }
    // Check if expected items are BloomSnapshots or Matchers
    final isSnapshotOrMatcherList = expected.every(
      (e) => e is BloomSnapshot || e is test_pkg.Matcher,
    );
    if (isSnapshotOrMatcherList) {
      final matchers = expected.map((e) {
        if (e is test_pkg.Matcher) return e;
        if (e is BloomSnapshot) {
          if (e.hasData) return isData(e.data);
          if (e.isEmpty) return isEmptyState(e.emptyReason);
          if (e.hasError) return isErrorState(e.error);
        }
        return test_pkg.equals(e);
      }).toList();
      test_pkg.expect(snapshots, matchers);
      return;
    }
    // Otherwise compare with raw values
    final rawValues = snapshots.map((s) => s.hasData ? s.data : s).toList();
    test_pkg.expect(rawValues, expected);
    return;
  }
  test_pkg.expect(snapshots, expected);
}

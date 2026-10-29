// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:blooming/blooming.dart';

// =============================================================================
// LPDAG Reactive State & Lifecycle Custom Matchers
// =============================================================================

/// Matches an LPDAG node ([Bloom], [BloomController], [BloomCoupler], or [LpdagStatus])
/// that is currently in a dormant state (0 downstream subscribers, inactive).
const Matcher isDormant = _IsDormantMatcher();

/// Matches an LPDAG node ([Bloom], [BloomController], [BloomCoupler], or [LpdagStatus])
/// that is currently in an active state (has downstream subscribers).
const Matcher isActive = _IsActiveMatcher();

/// Creates a matcher that asserts a [Bloom], [BloomController], or [BloomCoupler] node
/// has exactly [count] active downstream subscribers.
///
/// * [count]: The expected number of active downstream target edges.
Matcher hasSubscribers(int count) => _HasSubscribersMatcher(count);

/// Matches a reactive node or snapshot sequence verifying that no recorded [BloomSnapshot]
/// is in an error state.
const Matcher hasGlitchFreedom = _HasGlitchFreedomMatcher();

/// Creates a matcher verifying that a [BloomSnapshot], [BloomState], [Bloom], or [BloomController]
/// is in a valid Data state and matches [expected].
///
/// * [expected]: The expected data value or [Matcher] to validate against.
Matcher isData(dynamic expected) => _IsDataMatcher(expected);

/// Creates a matcher verifying that a [BloomSnapshot], [BloomState], [Bloom], or [BloomController]
/// is in an Empty state, optionally verifying [reason].
///
/// * [reason]: Optional expected empty reason payload.
Matcher isEmptyState([Object? reason]) => _IsEmptyStateMatcher(reason);

/// Creates a matcher verifying that a [BloomSnapshot], [BloomState], [Bloom], or [BloomController]
/// is in an Error state, optionally matching [error].
///
/// * [error]: Optional expected error object or [Matcher] to validate against.
Matcher isErrorState([dynamic error]) => _IsErrorStateMatcher(error);

// -----------------------------------------------------------------------------
// Matcher Implementations
// -----------------------------------------------------------------------------

Bloom? _extractBloom(dynamic item) {
  if (item is Bloom) return item;
  if (item is BloomController) return item.bloom;
  if (item is BloomCoupler) return item.bloom;
  return null;
}

final class _IsDormantMatcher extends Matcher {
  const _IsDormantMatcher();

  @override
  bool matches(dynamic item, Map matchState) {
    final bloom = _extractBloom(item);
    if (bloom != null) {
      final targetCount = bloom.debug.targetCount;
      final isNodeActive = bloom.debug.snapshot().isActive;
      if (targetCount > 0 || isNodeActive) {
        matchState['targetCount'] = targetCount;
        matchState['isActive'] = isNodeActive;
        return false;
      }
      return true;
    }
    if (item is LpdagStatus) {
      if (item.isActive) {
        matchState['isActive'] = true;
        return false;
      }
      return true;
    }
    matchState['error'] = 'Object $item is not an LPDAG node or status';
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('a dormant LPDAG node (inactive, 0 subscribers)');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState.containsKey('error')) {
      return mismatchDescription.add(matchState['error'].toString());
    }
    final targets = matchState['targetCount'];
    final active = matchState['isActive'];
    return mismatchDescription
        .add('was active with $targets subscribers (isActive: $active)');
  }
}

final class _IsActiveMatcher extends Matcher {
  const _IsActiveMatcher();

  @override
  bool matches(dynamic item, Map matchState) {
    final bloom = _extractBloom(item);
    if (bloom != null) {
      final targetCount = bloom.debug.targetCount;
      final isNodeActive = bloom.debug.snapshot().isActive;
      if (targetCount == 0 && !isNodeActive) {
        matchState['targetCount'] = targetCount;
        matchState['isActive'] = isNodeActive;
        return false;
      }
      return true;
    }
    if (item is LpdagStatus) {
      if (!item.isActive) {
        matchState['isActive'] = false;
        return false;
      }
      return true;
    }
    matchState['error'] = 'Object $item is not an LPDAG node or status';
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('an active LPDAG node with active subscribers');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState.containsKey('error')) {
      return mismatchDescription.add(matchState['error'].toString());
    }
    return mismatchDescription
        .add('was dormant (0 subscribers, isActive: false)');
  }
}

final class _HasSubscribersMatcher extends Matcher {
  const _HasSubscribersMatcher(this.count);

  final int count;

  @override
  bool matches(dynamic item, Map matchState) {
    final bloom = _extractBloom(item);
    if (bloom != null) {
      final targetCount = bloom.debug.targetCount;
      if (targetCount != count) {
        matchState['actualCount'] = targetCount;
        return false;
      }
      return true;
    }
    matchState['error'] = 'Object $item is not a Bloom node or controller';
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('an LPDAG node with exactly $count subscribers');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState.containsKey('error')) {
      return mismatchDescription.add(matchState['error'].toString());
    }
    return mismatchDescription
        .add('had ${matchState['actualCount']} subscribers');
  }
}

final class _HasGlitchFreedomMatcher extends Matcher {
  const _HasGlitchFreedomMatcher();

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Iterable) {
      final list = item.toList();
      // Verifies that no recorded BloomSnapshot in the sequence is in an error state.
      for (var i = 0; i < list.length; i++) {
        final current = list[i];
        if (current is BloomSnapshot && current.hasError) {
          // If an error is explicitly recorded that was a glitch exception:
          matchState['glitch'] =
              'Found error snapshot at index $i: ${current.error}';
          return false;
        }
      }
      return true;
    }
    // A single snapshot or Bloom node is trivially glitch-free
    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('a glitch-free reactive evaluation sequence');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState.containsKey('glitch')) {
      return mismatchDescription.add(matchState['glitch'].toString());
    }
    return mismatchDescription
        .add('observed inconsistent intermediate state during evaluation');
  }
}

BloomSnapshot? _toSnapshot(dynamic item) {
  if (item is BloomSnapshot) return item;
  if (item is BloomState) return item.snapshot;
  if (item is Bloom) return untracked.state(item).snapshot;
  if (item is BloomController) return untracked.state(item.bloom).snapshot;
  return null;
}

final class _IsDataMatcher extends Matcher {
  const _IsDataMatcher(this.expected);

  final dynamic expected;

  @override
  bool matches(dynamic item, Map matchState) {
    final snapshot = _toSnapshot(item);
    if (snapshot == null) {
      matchState['error'] = '$item is not a BloomSnapshot or reactive node';
      return false;
    }
    if (!snapshot.hasData) {
      matchState['state'] = snapshot.toString();
      return false;
    }
    final data = snapshot.data;
    final matcher =
        expected is Matcher ? expected as Matcher : equals(expected);
    final subState = {};
    if (!matcher.matches(data, subState)) {
      matchState['actualData'] = data;
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) => description
      .add('a valid Data state matching ')
      .addDescriptionOf(expected);

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState.containsKey('error')) {
      return mismatchDescription.add(matchState['error'].toString());
    }
    if (matchState.containsKey('state')) {
      return mismatchDescription
          .add('was not in Data state: ${matchState['state']}');
    }
    if (matchState.containsKey('subMismatch')) {
      return mismatchDescription.add(matchState['subMismatch'].toString());
    }
    return mismatchDescription.add('had data ${matchState['actualData']}');
  }
}

final class _IsEmptyStateMatcher extends Matcher {
  const _IsEmptyStateMatcher([this.reason]);

  final Object? reason;

  @override
  bool matches(dynamic item, Map matchState) {
    final snapshot = _toSnapshot(item);
    if (snapshot == null) {
      matchState['error'] = '$item is not a BloomSnapshot or reactive node';
      return false;
    }
    if (!snapshot.isEmpty) {
      matchState['state'] = snapshot.toString();
      return false;
    }
    if (reason != null &&
        snapshot.emptyReason != reason &&
        snapshot.emptyReason?.toString() != reason.toString()) {
      matchState['actualReason'] = snapshot.emptyReason;
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('an Empty state');
    if (reason != null) {
      description.add(' with reason "$reason"');
    }
    return description;
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState.containsKey('error')) {
      return mismatchDescription.add(matchState['error'].toString());
    }
    if (matchState.containsKey('state')) {
      return mismatchDescription
          .add('was not in Empty state: ${matchState['state']}');
    }
    return mismatchDescription
        .add('had emptyReason "${matchState['actualReason']}"');
  }
}

final class _IsErrorStateMatcher extends Matcher {
  const _IsErrorStateMatcher([this.expectedError]);

  final dynamic expectedError;

  @override
  bool matches(dynamic item, Map matchState) {
    final snapshot = _toSnapshot(item);
    if (snapshot == null) {
      matchState['error'] = '$item is not a BloomSnapshot or reactive node';
      return false;
    }
    if (!snapshot.hasError) {
      matchState['state'] = snapshot.toString();
      return false;
    }
    if (expectedError != null) {
      final actualErr = snapshot.error;
      if (expectedError is Matcher) {
        final matcher = expectedError as Matcher;
        final subState = {};
        if (!matcher.matches(actualErr, subState)) {
          matchState['subMismatch'] = matcher
              .describeMismatch(
                actualErr,
                StringDescription(),
                subState,
                false,
              )
              .toString();
          return false;
        }
        return true;
      }
      if (actualErr != expectedError &&
          actualErr.toString() != expectedError.toString()) {
        matchState['actualError'] = actualErr;
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('an Error state');
    if (expectedError != null) {
      description.add(' matching ').addDescriptionOf(expectedError);
    }
    return description;
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (matchState.containsKey('error')) {
      return mismatchDescription.add(matchState['error'].toString());
    }
    if (matchState.containsKey('state')) {
      return mismatchDescription
          .add('was not in Error state: ${matchState['state']}');
    }
    if (matchState.containsKey('subMismatch')) {
      return mismatchDescription.add(matchState['subMismatch'].toString());
    }
    return mismatchDescription.add('had error ${matchState['actualError']}');
  }
}

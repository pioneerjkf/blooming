// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../framework.dart';

// =============================================================================
// Bloom State Exceptions & Diagnostic Errors
// =============================================================================

/// The base class for all recoverable runtime exceptions in the Bloom state domain.
///
/// Bloom establishes a clear boundary between recoverable runtime failures
/// and structural programming bugs:
///
/// * **Recoverable Failures ([BloomException])**:
///   These represent dynamic operational issues (e.g. extracting data from an error
///   or empty snapshot). These are designed to be inspected and handled gracefully,
///   with action-oriented diagnostic suggestions.
///
/// * **Structural Programmatic Bugs ([StateError])**:
///   (e.g. [LpdagReentrancyError]). These represent violations of graph construction
///   or synchronous cyclic update loops that must fail fast during development.
@pragma('flutter:keep-to-string-in-subtypes')
abstract class BloomException implements Exception {
  /// Base constant constructor for all [BloomException] instances.
  const BloomException();
}

/// Thrown when an attempt is made to extract data from an invalid snapshot state.
///
/// Reading `.data` on an empty or error snapshot throws this exception
/// to immediately pinpoint missing data or unhandled upstream errors (Fail-Fast).
///
/// ## Actionable Resolution
/// 1. Use `.dataOrNull` or `.dataOrElse(() => fallback)` to handle dormant or failed states gracefully.
/// 2. Check `.hasData` before extracting `.data`.
/// 3. Use exhaustive pattern matching via `switch (snapshot.phase)` or `switch (snapshot)`.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Unconditionally reading .data on an unverified snapshot
/// final user = userSnapshot.data; // Throws BloomSnapshotExtractionException if empty or error!
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Safe extraction with fallback or pattern matching
/// final user = userSnapshot.dataOrNull ?? User.guest();
/// ```
abstract class BloomSnapshotExtractionException extends BloomException {
  /// Base constructor for snapshot and state extraction exceptions.
  const BloomSnapshotExtractionException._(this.state, this.details);

  /// Creates a [BloomSnapshotExtractionException] matching the specified [state].
  ///
  /// Maintained for factory backward compatibility.
  factory BloomSnapshotExtractionException(
    String state,
    String details, {
    Object? emptyReason,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (state == 'Empty') {
      return BloomEmptyExtractionException(details, emptyReason: emptyReason);
    }
    return BloomErrorExtractionException(
      details,
      error: error ?? StateError(details),
      stackTrace: stackTrace,
    );
  }

  /// The string descriptor of the invalid state (e.g. 'Empty', 'Error').
  final String state;

  /// Diagnostic description of where and why extraction failed.
  final String details;

  /// Optional causal reason if the state was in an empty phase.
  Object? get emptyReason => null;

  /// The original upstream error object if state was in an error phase.
  Object? get error => null;

  /// The original stack trace if state was in an error phase.
  StackTrace? get stackTrace => null;
}

/// Thrown when attempting to extract payload (.data) from an Empty state or snapshot.
///
/// ## Actionable Resolution
/// 1. Inspect [emptyReason] to determine what prerequisite or guard gated this computation.
/// 2. DO NOT remove precondition guards; resolve the missing prerequisite upstream instead.
/// 3. In UI components, check `node.isEmpty` and `node.emptyReason` to render pending states.
/// 4. Use `.dataOrNull` or `.dataOrElse(() => fallback)` to handle dormant states gracefully.
class BloomEmptyExtractionException extends BloomSnapshotExtractionException {
  /// Creates a [BloomEmptyExtractionException] with diagnostic context and causal reason.
  const BloomEmptyExtractionException(
    String details, {
    this.emptyReason,
  }) : super._('Empty', details);

  @override
  final Object? emptyReason;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln(''
          '[Bloom] State/Snapshot Extraction Failure: '
          'Attempted to extract payload from an invalid state (Empty).');

    if (emptyReason != null) {
      String safeReason;
      try {
        safeReason = emptyReason.toString();
      } catch (e) {
        try {
          safeReason = '<Unprintable emptyReason: $e>';
        } catch (_) {
          safeReason = '<Unprintable emptyReason>';
        }
      }
      buffer
        ..writeln('\n======================================')
        ..writeln('DIAGNOSTIC EMPTY REASON:')
        ..writeln(safeReason)
        ..writeln('======================================\n')
        ..writeln('[AI / Developer Action Guide]')
        ..writeln('1. DO NOT remove or bypass the precondition guard.')
        ..writeln('2. Check upstream prerequisites: Ensure dependencies required by')
        ..writeln('   "$safeReason" are fulfilled before dereferencing .data.')
        ..writeln('3. Declarative UI: Inspect "node.isEmpty" and "node.emptyReason"')
        ..writeln('   to render an unready placeholder or disable actions.')
        ..writeln('4. Safe extraction: If graceful fallback is intended, use')
        ..writeln("   'node.dataOrNull' or 'node.dataOrElse(() => fallback)'.");
    } else {
      buffer
        ..writeln(''
            'Extracting data from an Empty state throws a Fail-Fast '
            'exception.')
        ..writeln(''
            'Context: $details')
        ..writeln('\n[AI / Developer Action Guide]')
        ..writeln('1. The node is uninitialized or dormant (no input has been pushed yet).')
        ..writeln('2. If using BloomController, ensure an initial value was provided or push an event.')
        ..writeln('3. Inspect "node.hasData" or "node.isEmpty" before dereferencing.')
        ..writeln("4. Safely handle the state using 'node.dataOrNull' or 'node.dataOrElse(() => fallback)'.");
    }

    return buffer.toString();
  }
}

/// Thrown when attempting to extract payload (.data) from an Error state or snapshot.
///
/// ## Actionable Resolution
/// 1. Inspect [error] and [stackTrace] to diagnose the failure in upstream computations.
/// 2. Fix the error in the upstream transformer, effect, or producer.
/// 3. Guard against failure using `.hasError` or fallback via `.dataOrNull`.
class BloomErrorExtractionException extends BloomSnapshotExtractionException {
  /// Creates a [BloomErrorExtractionException] with diagnostic context, error cause, and stack trace.
  const BloomErrorExtractionException(
    String details, {
    required this.error,
    StackTrace? stackTrace,
  })  : stackTrace = stackTrace ?? StackTrace.empty,
        super._('Error', details);

  @override
  final Object error;

  @override
  final StackTrace stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln(''
          '[Bloom] State/Snapshot Extraction Failure: '
          'Attempted to extract payload from an invalid state (Error).')
      ..writeln(''
          'Extracting data from an Error state throws a Fail-Fast '
          'exception.')
      ..writeln(''
          'Context: $details\n')
      ..writeln('======================================')
      ..writeln('ORIGINAL PIPELINE ERROR CAUSE:');
    try {
      buffer.writeln('$error');
    } catch (e) {
      try {
        buffer.writeln('<Unprintable error: $e>');
      } catch (_) {
        buffer.writeln('<Unprintable error>');
      }
    }
    if (stackTrace != StackTrace.empty) {
      buffer.writeln('\nORIGINAL STACK TRACE:');
      try {
        buffer.writeln('$stackTrace');
      } catch (_) {
        buffer.writeln('<Unprintable stackTrace>');
      }
    }
    buffer
      ..writeln('======================================\n')
      ..writeln('[AI / Developer Action Guide]')
      ..writeln('1. Fix the original pipeline error shown above.')
      ..writeln("2. Safely handle the state using 'node.dataOrNull' or 'node.dataOrElse(() => fallback)'.")
      ..writeln(
        "3. Verify the state validity with 'node.hasData' or inspect 'node.error' when 'node.hasError' is true.",
      );

    return buffer.toString();
  }
}

/// Thrown when attempting to query error or stack trace metadata from a non-error snapshot.
///
/// ## Actionable Resolution
/// Always verify `snapshot.hasError == true` before querying `.error` or `.stackTrace`.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Reading .error on a valid or empty snapshot
/// final err = snapshot.error; // Throws BloomSnapshotStateException if not in error!
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Guard before inspecting error metadata
/// if (snapshot.hasError) {
///   print('Failure: ${snapshot.error}');
/// }
/// ```
class BloomSnapshotStateException extends BloomException {
  /// Creates a [BloomSnapshotStateException] with invalid access context.
  ///
  /// * [state]: The current state of the snapshot.
  /// * [details]: Diagnostic description of the invalid access attempt.
  ///
  /// **Ensures:**
  /// * Returns a [BloomSnapshotStateException] instance.
  const BloomSnapshotStateException(this.state, this.details);

  /// The current state of the snapshot.
  final String state;

  /// Diagnostic description of the invalid access attempt.
  final String details;

  @override
  String toString() => ''
      '[Bloom/API] Invalid State Access: Querying state metadata '
      '(error/stackTrace) from an incompatible state ($state).\n'
      'Under Bloom type-safe snapshot contracts, error and stackTrace '
      'metadata are only guaranteed to exist on an Error state.\n'
      'Context: $details\n'
      "Ensure '.hasError' is true before inspecting error metadata.";
}

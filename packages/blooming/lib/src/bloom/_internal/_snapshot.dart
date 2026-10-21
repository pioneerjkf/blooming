// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

base class _ValidBloomSnapshot<T> implements BloomSnapshot<T> {
  const _ValidBloomSnapshot(this.data);

  @override
  @pragma('vm:prefer-inline')
  BloomSnapshot<T> get snapshot => this;

  @override
  @pragma('vm:prefer-inline')
  BloomPhase get phase => BloomPhase.valid;

  @override
  @pragma('vm:prefer-inline')
  bool get hasData => true;

  @override
  @pragma('vm:prefer-inline')
  bool get isEmpty => false;

  @override
  @pragma('vm:prefer-inline')
  bool get hasError => false;

  @override
  final T data;

  @override
  @pragma('vm:prefer-inline')
  Object? get emptyReason => null;

  @override
  @pragma('vm:prefer-inline')
  T? get dataOrNull => data;

  @override
  @pragma('vm:prefer-inline')
  T dataOrElse(T Function() fallback) => data;

  @override
  @pragma('vm:prefer-inline')
  Object get error => throw BloomSnapshotStateException('Valid', 'No error was found in this valid BloomSnapshot<$T>.');

  @override
  @pragma('vm:prefer-inline')
  StackTrace get stackTrace =>
      throw BloomSnapshotStateException('Valid', 'No stackTrace was found in this valid BloomSnapshot<$T>.');

  @override
  @pragma('vm:prefer-inline')
  bool equals(covariant BloomState<T> other, [bool Function(T previous, T next)? equals]) {
    if (identical(this, other)) return true;
    if (other is! _ValidBloomSnapshot<T> && !other.hasData) return false;
    if (identical(data, other.data)) return true;
    return null != equals ? equals(data, other.data) : other.data == data;
  }
}

base class _ErrorBloomSnapshot<T> implements BloomSnapshot<T> {
  const _ErrorBloomSnapshot(this.error, [StackTrace? stackTrace]) : stackTrace = stackTrace ?? StackTrace.empty;

  @override
  @pragma('vm:prefer-inline')
  BloomSnapshot<T> get snapshot => this;

  @override
  @pragma('vm:prefer-inline')
  BloomPhase get phase => BloomPhase.error;

  @override
  @pragma('vm:prefer-inline')
  bool get hasData => false;

  @override
  @pragma('vm:prefer-inline')
  bool get isEmpty => false;

  @override
  @pragma('vm:prefer-inline')
  bool get hasError => true;

  @override
  @pragma('vm:prefer-inline')
  T get data => throw BloomSnapshotExtractionException(
        'Error',
        'This BloomSnapshot<$T> contains an error instead of data.',
        error: error,
        stackTrace: stackTrace,
      );

  @override
  @pragma('vm:prefer-inline')
  Object? get emptyReason => null;

  @override
  @pragma('vm:prefer-inline')
  T? get dataOrNull => null;

  @override
  @pragma('vm:prefer-inline')
  T dataOrElse(T Function() fallback) => fallback.call();

  @override
  @pragma('vm:prefer-inline')
  final Object error;

  @override
  @pragma('vm:prefer-inline')
  final StackTrace stackTrace;

  @override
  @pragma('vm:prefer-inline')
  bool equals(covariant BloomState<T> other, [bool Function(T previous, T next)? equals]) {
    if (identical(this, other)) return true;

    return other.hasError && other.error == error && other.stackTrace == stackTrace;
  }
}

base class _EmptyBloomSnapshot<T> implements BloomSnapshot<T> {
  const _EmptyBloomSnapshot([this.emptyReason]);

  @override
  final Object? emptyReason;

  @override
  @pragma('vm:prefer-inline')
  BloomSnapshot<T> get snapshot => this;

  @override
  @pragma('vm:prefer-inline')
  BloomPhase get phase => BloomPhase.empty;

  @override
  @pragma('vm:prefer-inline')
  bool get hasData => false;

  @override
  @pragma('vm:prefer-inline')
  bool get isEmpty => true;

  @override
  @pragma('vm:prefer-inline')
  bool get hasError => false;

  @override
  @pragma('vm:prefer-inline')
  T get data => throw BloomSnapshotExtractionException('Empty', 'No data available in this empty BloomSnapshot<$T>.');

  @override
  @pragma('vm:prefer-inline')
  T? get dataOrNull => null;

  @override
  @pragma('vm:prefer-inline')
  T dataOrElse(T Function() fallback) => fallback.call();

  @override
  @pragma('vm:prefer-inline')
  Object get error => throw BloomSnapshotStateException('Empty', 'No error was found in this empty BloomSnapshot<$T>.');

  @override
  @pragma('vm:prefer-inline')
  StackTrace get stackTrace =>
      throw BloomSnapshotStateException('Empty', 'No stackTrace was found in this empty BloomSnapshot<$T>.');

  @override
  @pragma('vm:prefer-inline')
  bool equals(covariant BloomState<T> other, [bool Function(T previous, T next)? equals]) {
    if (identical(this, other)) return true;

    return other.isEmpty && other.emptyReason == emptyReason;
  }
}

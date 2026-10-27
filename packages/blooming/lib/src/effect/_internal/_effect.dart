// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

// =============================================================================
// Concrete Declarative Effect Node Implementations
// =============================================================================

/// Concrete unary manifest implementation of [Effect] composing a [_UnaryManifestEffectTerminal].
final class _UnaryManifestEffect extends Effect {
  _UnaryManifestEffect(
    Bloom source,
    void Function() action, {
    bool Function()? guard,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  })  : _terminal = _UnaryManifestEffectTerminal(
          source,
          action,
          guard: guard,
          take: take,
          onUncaughtError: onUncaughtError,
        ),
        super._();

  @override
  final _UnaryManifestEffectTerminal _terminal;
}

/// Concrete manifest implementation of [Effect] composing a [_NaryManifestEffectTerminal].
final class _ManifestEffect extends Effect {
  _ManifestEffect(
    Iterable<Bloom> targets,
    void Function() action, {
    bool Function()? guard,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  })  : _terminal = _NaryManifestEffectTerminal(
          targets,
          action,
          guard: guard,
          take: take,
          onUncaughtError: onUncaughtError,
        ),
        super._();

  @override
  final _NaryManifestEffectTerminal _terminal;
}

/// Concrete unary manifest handled implementation of [Effect] composing a [_HandledUnaryManifestEffectTerminal].
final class _HandledUnaryManifestEffect extends Effect {
  _HandledUnaryManifestEffect(
    Bloom source,
    void Function(EffectScope scope) action, {
    bool Function()? guard,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  })  : _terminal = _HandledUnaryManifestEffectTerminal(
          source,
          action,
          guard: guard,
          take: take,
          onUncaughtError: onUncaughtError,
        ),
        super._();

  @override
  final _HandledUnaryManifestEffectTerminal _terminal;
}

/// Concrete manifest handled implementation of [Effect] composing a [_HandledNaryManifestEffectTerminal].
final class _HandledManifestEffect extends Effect {
  _HandledManifestEffect(
    Iterable<Bloom> targets,
    void Function(EffectScope scope) action, {
    bool Function()? guard,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  })  : _terminal = _HandledNaryManifestEffectTerminal(
          targets,
          action,
          guard: guard,
          take: take,
          onUncaughtError: onUncaughtError,
        ),
        super._();

  @override
  final _HandledNaryManifestEffectTerminal _terminal;
}

/// Concrete composite group implementation of [Effect] composing an [_EffectGroupTerminal].
final class _EffectGroup extends Effect {
  _EffectGroup(Iterable<Effect> effects) : this._(List.unmodifiable(effects.toSet()));

  _EffectGroup._(List<Effect> uniqueEffects)
      : effects = uniqueEffects,
        _terminal = _EffectGroupTerminal(uniqueEffects),
        super._();

  final List<Effect> effects;

  @override
  final _EffectGroupTerminal _terminal;
}

/// Concrete implementation of [Effect] composing a [_ViaEffectTerminal].
final class _ViaEffect extends Effect {
  _ViaEffect(
    void Function(BloomVia via) action, {
    bool Function(BloomVia via)? guard,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  })  : _terminal = _ViaEffectTerminal(
          action,
          guard: guard,
          onUncaughtError: onUncaughtError,
        ),
        super._();

  @override
  final _ViaEffectTerminal _terminal;
}

/// Concrete implementation of [Effect] composing a [_HandledViaEffectTerminal].
final class _HandledViaEffect extends Effect {
  _HandledViaEffect(
    void Function(BloomVia via, EffectScope scope) action, {
    bool Function(BloomVia via)? guard,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  })  : _terminal = _HandledViaEffectTerminal(
          action,
          guard: guard,
          onUncaughtError: onUncaughtError,
        ),
        super._();

  @override
  final _HandledViaEffectTerminal _terminal;
}

// =============================================================================
// Concrete Declarative Debounce & Throttle Effect Nodes
// =============================================================================

/// Concrete unary debounce manifest effect composing a [_UnaryDebounceEffectTerminal].
final class _UnaryManifestDebounceEffect extends Effect {
  _UnaryManifestDebounceEffect(
    Bloom source,
    Duration duration,
    void Function() action, {
    bool Function()? guard,
    bool leading = false,
    bool trailing = true,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  })  : _terminal = _UnaryDebounceEffectTerminal(
          source,
          duration,
          action,
          guard: guard,
          leading: leading,
          trailing: trailing,
          take: take,
          onUncaughtError: onUncaughtError,
        ),
        super._();

  @override
  final _UnaryDebounceEffectTerminal _terminal;

  Duration get duration => _terminal.duration;

  bool get leading => _terminal.leading;

  bool get trailing => _terminal.trailing;
}

/// Concrete n-ary debounce manifest effect composing a [_NaryDebounceEffectTerminal].
final class _ManifestDebounceEffect extends Effect {
  _ManifestDebounceEffect(
    Iterable<Bloom> targets,
    Duration duration,
    void Function() action, {
    bool Function()? guard,
    bool leading = false,
    bool trailing = true,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  })  : _terminal = _NaryDebounceEffectTerminal(
          targets,
          duration,
          action,
          guard: guard,
          leading: leading,
          trailing: trailing,
          take: take,
          onUncaughtError: onUncaughtError,
        ),
        super._();

  @override
  final _NaryDebounceEffectTerminal _terminal;

  Duration get duration => _terminal.duration;

  bool get leading => _terminal.leading;

  bool get trailing => _terminal.trailing;
}

/// Concrete unary throttle manifest effect composing a [_UnaryThrottleEffectTerminal].
final class _UnaryManifestThrottleEffect extends Effect {
  _UnaryManifestThrottleEffect(
    Bloom source,
    Duration duration,
    void Function() action, {
    bool Function()? guard,
    bool leading = true,
    bool trailing = true,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  })  : _terminal = _UnaryThrottleEffectTerminal(
          source,
          duration,
          action,
          guard: guard,
          leading: leading,
          trailing: trailing,
          take: take,
          onUncaughtError: onUncaughtError,
        ),
        super._();

  @override
  final _UnaryThrottleEffectTerminal _terminal;

  Duration get duration => _terminal.duration;

  bool get leading => _terminal.leading;

  bool get trailing => _terminal.trailing;
}

/// Concrete n-ary throttle manifest effect composing a [_NaryThrottleEffectTerminal].
final class _ManifestThrottleEffect extends Effect {
  _ManifestThrottleEffect(
    Iterable<Bloom> targets,
    Duration duration,
    void Function() action, {
    bool Function()? guard,
    bool leading = true,
    bool trailing = true,
    int? take,
    void Function(Object error, StackTrace stackTrace)? onUncaughtError,
  })  : _terminal = _NaryThrottleEffectTerminal(
          targets,
          duration,
          action,
          guard: guard,
          leading: leading,
          trailing: trailing,
          take: take,
          onUncaughtError: onUncaughtError,
        ),
        super._();

  @override
  final _NaryThrottleEffectTerminal _terminal;

  Duration get duration => _terminal.duration;

  bool get leading => _terminal.leading;

  bool get trailing => _terminal.trailing;
}

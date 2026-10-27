// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../framework.dart';

/// Internal edge terminal connecting an [EffectRunner] to its target [Effect].
final class _RunnerTerminal extends _Terminal with _UnaryEdgeMixin<Effect> {
  _RunnerTerminal(Effect effect) : super() {
    _source = effect;
    _pulledVersion = effect._version;
  }

  @override
  late final Effect _source;

  @override
  @pragma('vm:prefer-inline')
  void _invalidate() {
    // EffectRunner is a terminal edge holder. No downstream dirty propagation required.
  }
}

/// Concrete implementation of [EffectRunner] encapsulating a [_RunnerTerminal].
final class _EffectRunnerImpl implements EffectRunner {
  _EffectRunnerImpl(this.effect) : _terminal = _RunnerTerminal(effect);

  @override
  final Effect effect;

  final _RunnerTerminal _terminal;

  @override
  bool get isActive => _terminal.isActive && effect._terminal.isActive;

  @override
  @pragma('vm:prefer-inline')
  void start() => _terminal.activate();

  @override
  @pragma('vm:prefer-inline')
  void stop() => _terminal.deactivate();
}

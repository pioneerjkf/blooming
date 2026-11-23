// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

/// Official static analysis rules and automated lint checks for the Bloom reactive state framework and Blooming Flutter.
///
/// Enforces architectural invariants such as Producer/Consumer separation, zero-escaping
/// `BloomVia` scopes, proper controller lifecycle disposal, and rebuild isolation.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analysis_server_plugin/edit/range_factory.dart';
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity, LintCode;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:meta/meta.dart';

// Util parts
part 'src/util/flutter_ast_utils.dart';
part 'src/util/bloom_type_checker.dart';

// Core rule parts (Pure Dart LPDAG / Reactive Invariants)
part 'src/rules/core/avoid_async_in_computed.dart';
part 'src/rules/core/avoid_async_in_managed.dart';
part 'src/rules/core/avoid_catching_via_short_circuit.dart';
part 'src/rules/core/avoid_escaping_via.dart';
part 'src/rules/core/avoid_state_writes_in_pipeline.dart';
part 'src/rules/core/avoid_unnecessary_via_scope.dart';
part 'src/rules/core/avoid_untracked_bloom_read.dart';
part 'src/rules/core/avoid_via_state_when_value_suffices.dart';

// Flutter rule parts (UI / Lifecycle / Widget Guards)
part 'src/rules/flutter/avoid_bridging_in_build.dart';
part 'src/rules/flutter/avoid_escaping_scoped_controller.dart';
part 'src/rules/flutter/avoid_bloom_creation_in_build.dart';
part 'src/rules/flutter/deactivate_effect_runner.dart';
part 'src/rules/flutter/prefer_composed_child.dart';
part 'src/rules/flutter/prefer_bloom_over_controller.dart';
part 'src/rules/flutter/prefer_bloom_widget.dart';

// Self-Healing QuickFix parts
part 'src/fixes/wrap_with_via_fix.dart';
part 'src/fixes/replace_via_state_data_fix.dart';
part 'src/fixes/replace_stateless_with_bloom_widget_fix.dart';
part 'src/fixes/convert_to_computed_async_fix.dart';

/// Top-level plugin instance discovered by the Dart Analysis Server.
final plugin = BloomingPlugin();

/// All analysis rules provided by `blooming_lints`.
List<AbstractAnalysisRule> createBloomingRules() => [
  // Core Reactive Invariant Rules (Pure Dart)
  AvoidAsyncInComputed(),
  AvoidAsyncInManaged(),
  AvoidCatchingViaShortCircuit(),
  AvoidEscapingVia(),
  AvoidStateWritesInPipeline(),
  AvoidUnnecessaryViaScope(),
  AvoidUntrackedBloomRead(),
  AvoidViaStateWhenValueSuffices(),

  // Flutter Integration Rules (UI & Lifecycle Guards)
  AvoidBridgingInBuild(),
  AvoidEscapingScopedController(),
  AvoidBloomCreationInBuild(),
  DeactivateEffectRunner(),
  PreferComposedChild(),
  PreferBloomOverController(),
  PreferBloomWidget(),
];

/// Official `analysis_server_plugin` entrypoint for `blooming_lints`.
class BloomingPlugin extends Plugin {
  @override
  String get name => 'blooming_lints';

  @override
  FutureOr<void> register(PluginRegistry registry) {
    for (final rule in createBloomingRules()) {
      registry.registerWarningRule(rule);
    }

    registry
      ..registerFixForRule(
        AvoidAsyncInComputed.code,
        ConvertToComputedAsyncFix.new,
      )
      ..registerFixForRule(AvoidUntrackedBloomRead.code, WrapWithViaFix.new)
      ..registerFixForRule(
        AvoidUntrackedBloomRead.untrackedCode,
        WrapWithViaFix.new,
      )
      ..registerFixForRule(
        AvoidViaStateWhenValueSuffices.code,
        ReplaceViaStateDataFix.new,
      )
      ..registerFixForRule(
        PreferBloomWidget.code,
        ReplaceStatelessWithBloomWidgetFix.new,
      );
  }
}

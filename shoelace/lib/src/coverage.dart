// coverage.dart — typed model of the zedup-shoelace JSON contract.
//
// Conventions:
//   - `final class` on every model — closed for extension, signals
//     immutability and value semantics.
//   - Switch expressions with relational patterns + when guards — no
//     scattered `if/else` for what is fundamentally enum-derivation.
//   - `fromJson` destructures via `as` only at the boundary; downstream
//     code never touches `Map<String, dynamic>`.

import 'package:flutter/material.dart';

/// Schema version of the JSON payload. Adding a revision = add a case +
/// every `parse` switch breaks until updated.
enum CoverageSchema {
  v1('zedup-shoelace/v1');

  const CoverageSchema(this.id);
  final String id;

  static CoverageSchema parse(String s) => switch (s) {
        'zedup-shoelace/v1' => CoverageSchema.v1,
        _ => throw FormatException('Unknown coverage schema: "$s"'),
      };
}

/// Per-segment / per-(variant, feature) coverage status. Drawn from the
/// matrix data — never written into the JSON directly.
enum SegmentStatus {
  /// At least one test covers the pair.
  tested,

  /// Required pair, no test — the visible gap.
  gap,

  /// Variant doesn't participate in this feature — not required.
  notApplicable;

  /// Reduces a pair of coverage ratios to a `SegmentStatus`. The lace is
  /// "owned" by the FROM node — when FROM is fully covered, the chord lights
  /// up in FROM's color regardless of the destination.
  static SegmentStatus fromRatios(double from, double to) =>
      switch (from) {
        >= 1.0 => SegmentStatus.tested,
        _ => SegmentStatus.gap,
      };
}

/// One vertex on the outer circle.
@immutable
final class VariantInfo {
  const VariantInfo({
    required this.name,
    required this.type,
    required this.color,
    required this.features,
    required this.coverageRatio,
  });

  final String name;
  final String type;
  final Color color;
  final List<String> features;
  final double coverageRatio;

  /// `<Type>.<name>` — used to match against gaps/tests/usages entries.
  String get qualifiedName => '$type.$name';

  bool get isFullyCovered => coverageRatio >= 1.0;

  factory VariantInfo.fromJson(Map<String, dynamic> json) => VariantInfo(
        name: json['name'] as String,
        type: json['type'] as String,
        color: _parseHexColor(json['color'] as String),
        features: List<String>.unmodifiable(
          (json['features'] as List).cast<String>(),
        ),
        coverageRatio: (json['coverageRatio'] as num).toDouble(),
      );
}

/// One uncovered (variant, feature) pair.
@immutable
final class GapInfo {
  const GapInfo({required this.variant, required this.feature});
  final String variant;
  final String feature;

  factory GapInfo.fromJson(Map<String, dynamic> json) => GapInfo(
        variant: json['variant'] as String,
        feature: json['feature'] as String,
      );
}

/// Source location pair shared by tests and usages.
@immutable
final class SourceLocation {
  const SourceLocation({required this.file, required this.line});
  final String file;
  final int line;

  String get displayPath => '$file:$line';
}

/// One registered test for a (variant, feature) at file:line.
@immutable
final class TestInfo {
  const TestInfo({
    required this.variant,
    required this.feature,
    required this.location,
  });

  final String variant;
  final String feature;
  final SourceLocation location;

  factory TestInfo.fromJson(Map<String, dynamic> json) => TestInfo(
        variant: json['variant'] as String,
        feature: json['feature'] as String,
        location: SourceLocation(
          file: json['file'] as String,
          line: json['line'] as int,
        ),
      );
}

/// One non-test reference to a variant at file:line.
@immutable
final class UsageInfo {
  const UsageInfo({required this.variant, required this.location});

  final String variant;
  final SourceLocation location;

  factory UsageInfo.fromJson(Map<String, dynamic> json) => UsageInfo(
        variant: json['variant'] as String,
        location: SourceLocation(
          file: json['file'] as String,
          line: json['line'] as int,
        ),
      );
}

/// Top-level decoded snapshot.
@immutable
final class CoverageData {
  const CoverageData({
    required this.schema,
    required this.generatedAt,
    required this.variants,
    required this.features,
    required this.gaps,
    required this.tests,
    required this.usages,
  });

  final CoverageSchema schema;
  final DateTime generatedAt;
  final List<VariantInfo> variants;
  final List<String> features;
  final List<GapInfo> gaps;
  final List<TestInfo> tests;
  final List<UsageInfo> usages;

  /// Average coverageRatio across variants. Vacuously 0.0 for empty input.
  double get coverageRatio => switch (variants.length) {
        0 => 0,
        final n => variants.fold(0.0, (a, v) => a + v.coverageRatio) / n,
      };

  bool get isFullyCovered => switch (gaps.length) {
        0 when variants.isNotEmpty => true,
        _ => false,
      };

  /// Number of (variant, feature) pairs that are required but not covered.
  int get gapCount => gaps.length;

  /// Status for a `(variantQualifiedName, feature)` pair.
  SegmentStatus statusOf({required String variant, required String feature}) {
    final v = variants.firstWhere(
      (v) => v.qualifiedName == variant,
      orElse: () => throw ArgumentError('Unknown variant: $variant'),
    );
    return switch (v.features.contains(feature)) {
      false => SegmentStatus.notApplicable,
      true when gaps.any(
        (g) => g.variant == variant && g.feature == feature,
      ) =>
        SegmentStatus.gap,
      true => SegmentStatus.tested,
    };
  }

  factory CoverageData.fromJson(Map<String, dynamic> json) => CoverageData(
        schema: CoverageSchema.parse(json['schema'] as String),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
        variants: List<VariantInfo>.unmodifiable([
          for (final v in (json['variants'] as List).cast<Map<String, dynamic>>())
            VariantInfo.fromJson(v),
        ]),
        features: List<String>.unmodifiable(
          (json['features'] as List).cast<String>(),
        ),
        gaps: List<GapInfo>.unmodifiable([
          for (final g in (json['gaps'] as List).cast<Map<String, dynamic>>())
            GapInfo.fromJson(g),
        ]),
        tests: List<TestInfo>.unmodifiable([
          for (final t in (json['tests'] as List).cast<Map<String, dynamic>>())
            TestInfo.fromJson(t),
        ]),
        usages: List<UsageInfo>.unmodifiable([
          for (final u in (json['usages'] as List).cast<Map<String, dynamic>>())
            UsageInfo.fromJson(u),
        ]),
      );
}

/// Parses `#rrggbb` or `#rrggbbaa` (with or without leading `#`).
/// Switch expression on length keeps the format contract explicit.
Color _parseHexColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return switch (cleaned.length) {
    6 => Color(int.parse('FF$cleaned', radix: 16)),
    8 => Color(int.parse(cleaned, radix: 16)),
    _ => throw FormatException('Hex color must be 6 or 8 chars, got "$hex"'),
  };
}

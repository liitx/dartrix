// coverage.dart — typed model of the zedup-shoelace JSON contract.
//
// Conventions:
//   - `final class` on every model — closed for extension, signals
//     immutability and value semantics.
//   - Switch expressions with relational patterns and when guards.
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

/// Coverage status of one (variant, feature) cell. Naming aligns with
/// dartrix's `CellState`.
enum SegmentStatus {
  /// Required cell with at least one test.
  covered,

  /// Required cell with no test — the visible gap.
  gap,

  /// Variant does not participate in this feature — not required.
  notApplicable;

  /// Reduces a coverage ratio to a `SegmentStatus`. Used by the chord
  /// label badge — the chord is owned by the TO node, so the badge
  /// tracks TO's coverage.
  static SegmentStatus forCoverage(double ratio) => switch (ratio) {
        >= 1.0 => SegmentStatus.covered,
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

/// Top-level decoded coverage snapshot.
@immutable
final class CoverageSnapshot {
  const CoverageSnapshot({
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

  /// Average per-variant coverage ratio across the snapshot. 0.0 on empty.
  double get averageCoverage => switch (variants.length) {
        0 => 0,
        final n => variants.fold(0.0, (a, v) => a + v.coverageRatio) / n,
      };

  bool get isFullyCovered => switch (gaps.length) {
        0 when variants.isNotEmpty => true,
        _ => false,
      };

  /// Number of (variant, feature) pairs that are required but not covered.
  int get gapCount => gaps.length;

  /// Status of one (variant, feature) cell. Variant comes from [variants];
  /// feature is one of [features].
  SegmentStatus cellStatus({
    required VariantInfo variant,
    required String feature,
  }) {
    return switch (variant.features.contains(feature)) {
      false => SegmentStatus.notApplicable,
      true when gaps.any(
        (g) => g.variant == variant.qualifiedName && g.feature == feature,
      ) =>
        SegmentStatus.gap,
      true => SegmentStatus.covered,
    };
  }

  factory CoverageSnapshot.fromJson(Map<String, dynamic> json) =>
      CoverageSnapshot(
        schema: CoverageSchema.parse(json['schema'] as String),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
        variants: List<VariantInfo>.unmodifiable([
          for (final v
              in (json['variants'] as List).cast<Map<String, dynamic>>())
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
Color _parseHexColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return switch (cleaned.length) {
    6 => Color(int.parse('FF$cleaned', radix: 16)),
    8 => Color(int.parse(cleaned, radix: 16)),
    _ => throw FormatException('Hex color must be 6 or 8 chars, got "$hex"'),
  };
}

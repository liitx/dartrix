// shoelace_snapshot.dart — typed parser for the zedup-shoelace JSON snapshot
//
// Consumers (renderers in zedup nocterm screens, HTML visualizers, future
// Dart-native painters) parse the snapshot file produced by zedup's
// `launchShoelaceViz` and consume typed data instead of poking at raw JSON.
//
// Supports v1, v2, v3 schema strings. Unknown / missing fields default
// gracefully so a v3 reader can still parse a v2 snapshot, and a v2-only
// reader (older code) silently ignores the v3 additions.
//
// dartrix does NOT import zedup. The TestStatus and FailureType identities
// are carried as raw strings; consumers that need to roundtrip into typed
// enums look them up against their own enum.values.

import 'dart:convert';

/// Schema string emitted by zedup. Used to tell consumers which fields
/// they can rely on without scanning every record.
enum ShoelaceSchema {
  v1,
  v2,
  v3,
  unknown;

  static ShoelaceSchema fromString(String? raw) => switch (raw) {
        'zedup-shoelace/v1' => ShoelaceSchema.v1,
        'zedup-shoelace/v2' => ShoelaceSchema.v2,
        'zedup-shoelace/v3' => ShoelaceSchema.v3,
        _ => ShoelaceSchema.unknown,
      };

  /// The on-the-wire schema string zedup emits. Null for [unknown] since
  /// it does not round-trip.
  String? get wireValue => switch (this) {
        ShoelaceSchema.v1      => 'zedup-shoelace/v1',
        ShoelaceSchema.v2      => 'zedup-shoelace/v2',
        ShoelaceSchema.v3      => 'zedup-shoelace/v3',
        ShoelaceSchema.unknown => null,
      };

  bool get supportsTestStatus => this == ShoelaceSchema.v3;
  bool get supportsScopeContext =>
      this == ShoelaceSchema.v2 || this == ShoelaceSchema.v3;
}

/// One test point in the snapshot. v3 fields default to safe values when
/// reading an older schema.
class SnapshotTestPoint {
  const SnapshotTestPoint({
    required this.variant,
    required this.feature,
    required this.file,
    required this.line,
    this.containingGroup,
    this.status = 'unknown',
    this.failureMessage,
    this.logPath,
    this.failureType,
  });

  final String variant; // qualified — e.g. "BranchType.feat"
  final String feature; // enum name — e.g. "newBranch"
  final String file;
  final int line;
  final String? containingGroup;

  // v3 additions — default to safe values when reading older schemas.
  final String status;
  final String? failureMessage;
  final String? logPath;
  final String? failureType;

  /// True when [status] indicates a captured failure (failing or error).
  /// Drives shoelace's three-state rendering — worst-state-wins per region.
  bool get isFailing => status == 'failing' || status == 'error';

  /// True when [status] indicates a captured pass.
  bool get isPassing => status == 'passing';

  factory SnapshotTestPoint.fromJson(Map<String, dynamic> json) {
    return SnapshotTestPoint(
      variant: json['variant'] as String? ?? '',
      feature: json['feature'] as String? ?? '',
      file: json['file'] as String? ?? '',
      line: json['line'] as int? ?? 0,
      containingGroup: json['containingGroup'] as String?,
      status: json['status'] as String? ?? 'unknown',
      failureMessage: json['failureMessage'] as String?,
      logPath: json['logPath'] as String?,
      failureType: json['failureType'] as String?,
    );
  }
}

/// One usage point — non-test reference to a variant.
class SnapshotUsagePoint {
  const SnapshotUsagePoint({
    required this.variant,
    required this.file,
    required this.line,
    this.containingClass,
    this.containingMethod,
  });

  final String variant;
  final String file;
  final int line;
  final String? containingClass;
  final String? containingMethod;

  factory SnapshotUsagePoint.fromJson(Map<String, dynamic> json) {
    return SnapshotUsagePoint(
      variant: json['variant'] as String? ?? '',
      file: json['file'] as String? ?? '',
      line: json['line'] as int? ?? 0,
      containingClass: json['containingClass'] as String?,
      containingMethod: json['containingMethod'] as String?,
    );
  }
}

/// One uncovered cell — variant × feature with no test registered.
class SnapshotGap {
  const SnapshotGap({required this.variant, required this.feature});
  final String variant;
  final String feature;
  factory SnapshotGap.fromJson(Map<String, dynamic> json) => SnapshotGap(
        variant: json['variant'] as String? ?? '',
        feature: json['feature'] as String? ?? '',
      );
}

/// One variant entry from the snapshot's top-level variants array.
class SnapshotVariant {
  const SnapshotVariant({
    required this.name,
    required this.type,
    required this.color,
    required this.features,
    required this.coverageRatio,
  });
  final String name;
  final String type;
  final String color;
  final List<String> features;
  final double coverageRatio;
  factory SnapshotVariant.fromJson(Map<String, dynamic> json) =>
      SnapshotVariant(
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
        color: json['color'] as String? ?? '',
        features: ((json['features'] as List<dynamic>?) ?? const [])
            .cast<String>(),
        coverageRatio: (json['coverageRatio'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Top-level typed snapshot. Field-tolerant — older schemas parse with
/// v3-only fields defaulting to safe values.
class ShoelaceSnapshot {
  const ShoelaceSnapshot({
    required this.schema,
    required this.generatedAt,
    required this.variants,
    required this.features,
    required this.gaps,
    required this.tests,
    required this.usages,
  });

  final ShoelaceSchema schema;
  final String generatedAt;
  final List<SnapshotVariant> variants;
  final List<String> features;
  final List<SnapshotGap> gaps;
  final List<SnapshotTestPoint> tests;
  final List<SnapshotUsagePoint> usages;

  /// Parses JSON text. Throws FormatException on invalid JSON; tolerates
  /// missing top-level keys by defaulting them to empty.
  static ShoelaceSnapshot parse(String jsonText) {
    final raw = jsonDecode(jsonText);
    if (raw is! Map<String, dynamic>) {
      throw FormatException('shoelace snapshot must be a JSON object');
    }
    return ShoelaceSnapshot._fromMap(raw);
  }

  factory ShoelaceSnapshot._fromMap(Map<String, dynamic> json) {
    return ShoelaceSnapshot(
      schema: ShoelaceSchema.fromString(json['schema'] as String?),
      generatedAt: json['generatedAt'] as String? ?? '',
      variants: ((json['variants'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(SnapshotVariant.fromJson)
          .toList(),
      features: ((json['features'] as List<dynamic>?) ?? const [])
          .cast<String>(),
      gaps: ((json['gaps'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(SnapshotGap.fromJson)
          .toList(),
      tests: ((json['tests'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(SnapshotTestPoint.fromJson)
          .toList(),
      usages: ((json['usages'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(SnapshotUsagePoint.fromJson)
          .toList(),
    );
  }

  /// Worst-state-wins aggregate per (variant, feature) pair.
  /// Returns 'failing' when any test for the pair is failing/error,
  /// 'passing' when all tests pass, 'missing' when no tests exist,
  /// 'unknown' when tests exist but none have a captured outcome.
  String aggregateStateFor(String variant, String feature) {
    final tests = this.tests
        .where((t) => t.variant == variant && t.feature == feature)
        .toList();
    if (tests.isEmpty) return 'missing';
    if (tests.any((t) => t.isFailing)) return 'failing';
    if (tests.every((t) => t.isPassing)) return 'passing';
    return 'unknown';
  }
}

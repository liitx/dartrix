// confidence.dart — how far a candidate's proof has converged on confidence
//
// confidence = w1*variant coverage + w2*boundary + w3*topology reach + w4*impact
//
// Variant coverage is derived from the entry's own variant lists, so it cannot
// be asserted; the other three are measured by the consumer and recorded as
// factors. Every factor and every weight is between 0 and 1.

/// What the consumer measured for one proof run, each in 0..1.
class ConfidenceFactors {
  /// Records the three measured factors.
  const ConfidenceFactors({
    required this.boundary,
    required this.topologyReach,
    required this.impact,
  });

  /// The highest complexity level at which the candidate held, as a fraction of
  /// the levels tried.
  final double boundary;

  /// Neighbors confirmed over neighbors named.
  final double topologyReach;

  /// Duplication or dead paths removed, as a fraction of what was found.
  final double impact;

  /// Whether every factor is between 0 and 1.
  bool get isInRange => [boundary, topologyReach, impact]
      .every((factor) => factor >= 0 && factor <= 1);

  /// The factors by name, for the ledger.
  Map<String, double> toJson() => {
        FactorField.boundary.name: boundary,
        FactorField.topologyReach.name: topologyReach,
        FactorField.impact.name: impact,
      };

  /// Reads [json]; null if a factor is missing or is not a number.
  static ConfidenceFactors? tryFromJson(Map<String, Object?> json) {
    final values = {
      for (final field in FactorField.values) field: json[field.name],
    };
    if (values.values.any((v) => v is! num)) return null;
    return ConfidenceFactors(
      boundary: (values[FactorField.boundary]! as num).toDouble(),
      topologyReach: (values[FactorField.topologyReach]! as num).toDouble(),
      impact: (values[FactorField.impact]! as num).toDouble(),
    );
  }
}

/// The names the factors are written under.
enum FactorField {
  /// [ConfidenceFactors.boundary].
  boundary,

  /// [ConfidenceFactors.topologyReach].
  topologyReach,

  /// [ConfidenceFactors.impact].
  impact,
}

/// How much each part of the confidence counts. They sum to 1.
class ConfidenceWeights {
  /// Refuses weights that are negative or do not sum to 1.
  factory ConfidenceWeights({
    required double coverage,
    required double boundary,
    required double topologyReach,
    required double impact,
  }) {
    final all = [coverage, boundary, topologyReach, impact];
    if (all.any((w) => w < 0) || (all.reduce((a, b) => a + b) - 1).abs() > 1e-9) {
      throw ArgumentError('weights must be non-negative and sum to 1: $all');
    }
    return ConfidenceWeights._(coverage, boundary, topologyReach, impact);
  }

  const ConfidenceWeights._(
    this.coverage,
    this.boundary,
    this.topologyReach,
    this.impact,
  );

  /// The starting weights. An assumption, not a result: coverage of the spec is
  /// the claim itself so it counts most, and the rest are equal until a
  /// calibration against seeded faults says otherwise.
  static const initial = ConfidenceWeights._(0.4, 0.2, 0.2, 0.2);

  /// Weight of the variants covered over the variants in the spec.
  final double coverage;

  /// Weight of the normalized boundary.
  final double boundary;

  /// Weight of the topology reach.
  final double topologyReach;

  /// Weight of the impact.
  final double impact;

  /// The confidence of [factors] when [coverage] of the spec's variants is
  /// covered.
  double confidenceOf(ConfidenceFactors factors, {required double coverage}) =>
      this.coverage * coverage +
      boundary * factors.boundary +
      topologyReach * factors.topologyReach +
      impact * factors.impact;
}

/// The fraction of [variantsInSpec] that [variantsCovered] names. An empty spec
/// has nothing to cover, which counts as fully covered.
double variantCoverageOf(
  List<String> variantsInSpec,
  List<String> variantsCovered,
) =>
    variantsInSpec.isEmpty
        ? 1
        : variantsInSpec.where(variantsCovered.contains).length /
            variantsInSpec.length;

/// Where a candidate's confidence is heading.
enum ConfidenceTrend {
  /// Fewer than two measured entries.
  notEnoughHistory,

  /// The last entry is higher than the one before it.
  rising,

  /// The last entry equals the one before it: the proof has stopped converging.
  stalled,

  /// The last entry is lower than the one before it.
  dropped;

  /// Whether a candidate in this trend is listed for attention.
  bool get isFlagged => this == stalled || this == dropped;

  /// The trend of [series], oldest first.
  static ConfidenceTrend of(List<double> series) {
    if (series.length < 2) return notEnoughHistory;
    final change = series.last - series[series.length - 2];
    if (change.abs() < 1e-9) return stalled;
    return change > 0 ? rising : dropped;
  }
}

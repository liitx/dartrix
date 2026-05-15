// gap_cross_reference.dart — match shoelace gaps to candidate usage points
//
// Subsumes dartrix Phase 1 of the tabled handoff. Given a SnapshotGap
// `(variant, feature)` and the full snapshot, returns the usage rows the
// detail panel should render underneath the gap, ranked by relevance.
//
// Two-tier heuristic:
//   1. Soft-match: usages whose file path contains the feature name (the
//      assumption being that test files for a feature live in directories
//      named for it). Returned first.
//   2. Variant-only fallback: all usages of the variant, ordered by file.
//      Returned when soft-match yields no rows so the panel always shows
//      something actionable.
//
// Strategy is exposed as an enum so the matrix-driven tests can iterate
// every (variant × feature) gap × every strategy and assert the contract
// holds.

import 'shoelace_snapshot.dart';

/// Strategy a [GapCrossReference] used to produce its rows.
enum CrossReferenceStrategy {
  /// File-path soft match against the feature name produced ≥1 row.
  softMatch,

  /// Soft match returned empty; rows are all usages of the variant.
  variantOnly,

  /// No usages exist for the variant at all — rows is empty.
  empty;

  /// Human-readable label for the detail panel's footer hint.
  String get label => switch (this) {
        CrossReferenceStrategy.softMatch    => 'File-path soft match',
        CrossReferenceStrategy.variantOnly  => 'All usages of variant',
        CrossReferenceStrategy.empty        => 'No usages found',
      };
}

/// Result of cross-referencing a gap against a snapshot.
class GapCrossReference {
  const GapCrossReference({
    required this.gap,
    required this.usages,
    required this.strategy,
  });

  final SnapshotGap gap;

  /// Usages to render underneath the gap row. Empty when no usages exist.
  final List<SnapshotUsagePoint> usages;

  /// Which heuristic produced [usages]. Lets the UI render a footer hint.
  final CrossReferenceStrategy strategy;
}

extension GapCrossReferenceExtension on ShoelaceSnapshot {
  /// Cross-reference [gap] against this snapshot's usage list. See
  /// [CrossReferenceStrategy] for the two-tier fallback semantics.
  GapCrossReference crossReferenceFor(SnapshotGap gap) {
    final variantUsages =
        usages.where((u) => u.variant == gap.variant).toList();
    if (variantUsages.isEmpty) {
      return GapCrossReference(
        gap: gap,
        usages: const [],
        strategy: CrossReferenceStrategy.empty,
      );
    }
    final softMatched = variantUsages
        .where((u) => u.file.contains(gap.feature))
        .toList();
    if (softMatched.isNotEmpty) {
      return GapCrossReference(
        gap: gap,
        usages: softMatched,
        strategy: CrossReferenceStrategy.softMatch,
      );
    }
    return GapCrossReference(
      gap: gap,
      usages: variantUsages,
      strategy: CrossReferenceStrategy.variantOnly,
    );
  }
}

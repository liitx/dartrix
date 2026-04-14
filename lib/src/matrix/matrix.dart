// matrix.dart — coverage derivation from AppType cross-products
//
// DartrixMatrix takes the registered domain enums (as List<AppType> per axis)
// and derives the full coverage matrix:
//   rows    = domain enum variants (WorkStatus.values, BranchType.values, ...)
//   columns = features those variants participate in (via AppType.features)
//   cells   = coverage state: tested | gap | not applicable
//
// The matrix does not run tests — it models what needs testing.
// Tests register their coverage via DartrixMatrix.cover().
// DartrixMatrix.gaps() returns every uncovered required cell.
//
// Usage:
//   final matrix = DartrixMatrix(
//     axes: [WorkStatus.values, BranchType.values, ZedProfile.values],
//     features: ZedFeature.values,
//   );
//   matrix.cover(WorkStatus.wip, ZedFeature.dashboard);
//   matrix.gaps(); // → uncovered (variant, feature) pairs

import '../types/app_type.dart';
import '../types/feature_type.dart';

/// A single cell in the matrix — one (variant, feature) pair.
typedef MatrixCell = ({AppType variant, FeatureType feature});

/// Coverage state of a single cell.
enum CellState {
  /// Test registered for this (variant, feature) pair.
  covered,

  /// Variant participates in feature but no test registered.
  gap,

  /// Variant does not participate in this feature — not required.
  notApplicable,
}

/// Derives and tracks coverage for a set of domain enum variants
/// across a set of features.
class DartrixMatrix {
  DartrixMatrix({
    required List<List<AppType>> axes,
    required List<FeatureType> features,
  })  : _features = features,
        _variants = axes.expand((a) => a).toList();

  final List<FeatureType> _features;
  final List<AppType> _variants;
  final Set<MatrixCell> _covered = {};

  /// Register a test as covering a (variant, feature) pair.
  ///
  ///   matrix.cover(WorkStatus.wip, ZedFeature.dashboard);
  void cover(AppType variant, FeatureType feature) {
    _covered.add((variant: variant, feature: feature));
  }

  /// Returns all (variant, feature) pairs that are required but not covered.
  ///
  ///   matrix.gaps() → [(variant: WorkStatus.blocked, feature: ZedFeature.dashboard)]
  List<MatrixCell> gaps() {
    final result = <MatrixCell>[];
    for (final variant in _variants) {
      for (final feature in _features) {
        if (!variant.features.contains(feature)) continue; // not applicable
        final cell = (variant: variant, feature: feature);
        if (!_covered.contains(cell)) result.add(cell);
      }
    }
    return result;
  }

  /// Returns the CellState for a specific (variant, feature) pair.
  CellState stateOf(AppType variant, FeatureType feature) {
    if (!variant.features.contains(feature)) return CellState.notApplicable;
    final cell = (variant: variant, feature: feature);
    return _covered.contains(cell) ? CellState.covered : CellState.gap;
  }

  /// All registered variants.
  List<AppType> get variants => List.unmodifiable(_variants);

  /// All registered features.
  List<FeatureType> get features => List.unmodifiable(_features);
}

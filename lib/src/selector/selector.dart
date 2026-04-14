// selector.dart — typed test selector for Dartrix coverage registration
//
// A DartrixSelector bundles the three things every matrix test needs:
//   variant     — the AppType enum value under test
//   feature     — the FeatureType context being exercised
//   description — human-readable test name (typically from a fixture getter)
//
// Consumer apps define concrete selectors that also carry fixture-derived
// test inputs (e.g. BranchItem, prompt sequences). The generic S parameter
// in testSelector() preserves the concrete type so the test body receives
// the full selector without casting.
//
// Example (in zedup):
//   class BranchStatusSelector implements DartrixSelector {
//     const BranchStatusSelector(this.status);
//     final WorkStatus status;
//
//     @override AppType get variant      => status;
//     @override FeatureType get feature  => ZedFeature.dashboard;
//     @override String get description   => status.expectedLabel;
//
//     BranchItem get branchItem => BranchItem(
//       type:   BranchType.feat,
//       branch: '${BranchType.feat.expectedPrefix}/${status.name}',
//       title:  status.expectedLabel,
//       status: status,
//       ticket: '',
//       created: '2024-01-01',
//     );
//   }

import '../types/app_type.dart';
import '../types/feature_type.dart';

/// Carries the variant, feature, and description for a single matrix test.
/// Concrete selectors add fixture-derived test inputs as typed getters.
abstract interface class DartrixSelector {
  /// The AppType enum value under test — the row in the matrix.
  AppType get variant;

  /// The FeatureType context being exercised — the column in the matrix.
  FeatureType get feature;

  /// Human-readable test name. Derive from a fixture getter, not a bare string.
  String get description;
}

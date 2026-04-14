// selector.dart — typed test selector for Dartrix coverage registration
//
// A DartrixSelector bundles the three things every matrix test needs:
//   variant     — the AppType enum value under test
//   feature     — the FeatureType context being exercised
//   description — human-readable test name (typically from a fixture getter)
//
// Two paths to a selector:
//
// 1. AppType.getSelector(feature) — zero boilerplate for the common case.
//    Returns a TypedSelector<V> where V is the concrete enum type.
//    The test body reads variant, feature, description plus any fixture
//    data directly from sel.variant (via fixture extensions on the enum).
//
//    for (final type in BranchType.values) {
//      testSelector(matrix, type.getSelector(ZedFeature.dashboard), (sel) {
//        expect(
//          feature(branches: [sel.variant.sampleBranchItem]).run(),
//          equals(ListFlowState.exit),
//        );
//      });
//    }
//
// 2. Concrete DartrixSelector class — for selectors that carry pre-computed
//    fixture data as typed getters, or that require multiple constructor
//    parameters (e.g. both type and profile). Define a class that implements
//    DartrixSelector and add the typed getters the test body needs.

import '../types/app_type.dart';
import '../types/feature_type.dart';

/// Carries the variant, feature, and description for a single matrix test.
abstract interface class DartrixSelector {
  /// The AppType enum value under test — the row in the matrix.
  AppType get variant;

  /// The FeatureType context being exercised — the column in the matrix.
  FeatureType get feature;

  /// Human-readable test name. Derive from a fixture getter, not a bare string.
  String get description;
}

/// A [DartrixSelector] where [variant] is preserved as its concrete [AppType]
/// subtype [V], eliminating casts in the test body.
///
/// Created via [AppTypeGetSelector.getSelector] — never constructed directly.
class TypedSelector<V extends AppType> implements DartrixSelector {
  const TypedSelector(this.variant, this.feature, this.description);

  @override
  final V variant;

  @override
  final FeatureType feature;

  @override
  final String description;
}

extension AppTypeGetSelector<V extends AppType> on V {
  /// Creates a [TypedSelector] for this variant and [feature].
  ///
  /// The body in [testSelector] receives [TypedSelector<V>], so [sel.variant]
  /// is already typed as [V]. Read all fixture data from [sel.variant] via
  /// fixture extensions — no bare strings, no casts.
  TypedSelector<V> getSelector(FeatureType feature) =>
      TypedSelector<V>(this, feature, description);
}

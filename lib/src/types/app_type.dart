// app_type.dart — shared contract for all dartrix type hierarchies
//
// Every enum in the app's type hierarchy implements AppType.
// This gives the matrix a uniform interface to traverse all registered types
// regardless of whether they are features, components, helpers, or classes.
//
// Implementing AppType on a domain enum (e.g. WorkStatus, BranchType):
//   - declares the enum as a first-class participant in the matrix
//   - makes its variants visible to coverage derivation
//   - enforces that every variant declares its feature participation
//
// Example:
//   enum WorkStatus implements AppType {
//     wip, inReview, blocked, done, cancelled;
//
//     @override String get description => label;
//
//     @override Set<FeatureType> get features => switch (this) {
//       WorkStatus.wip      => {FeatureType.dashboard, FeatureType.promote},
//       WorkStatus.inReview => {FeatureType.dashboard},
//       // ... exhaustive — compile error if WorkStatus gets a new value
//     };
//   }

import 'feature_type.dart';

abstract interface class AppType {
  /// Dart enum name — provided free by every enum via Enum.name.
  String get name;

  /// Human-readable description shown in matrix output.
  String get description;

  /// Which features this variant participates in.
  /// Exhaustive switch in every implementing enum — compile error on new variant.
  Set<FeatureType> get features;
}

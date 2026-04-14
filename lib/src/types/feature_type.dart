// feature_type.dart — supertype enum for app features
//
// A feature is a user-facing capability of the app.
// Each FeatureType value declares which ComponentTypes, HelperTypes,
// and ClassTypes it depends on — the matrix derives what needs testing.
//
// Consumer apps extend this pattern by implementing their own FeatureType-like
// enum and registering it with the matrix. dartrix ships this as the base
// contract; apps supply the values.
//
// Example (in zedup):
//   enum ZedFeature implements FeatureType {
//     dashboard(description: 'Work item dashboard with profile tabs'),
//     newBranch(description: 'New git branch creation flow'),
//     promote(description: 'WIP branch promotion flow'),
//     refresh(description: 'GitHub PR status sync');
//
//     const ZedFeature({required this.description});
//     @override final String description;
//     @override String get name => this.name; // from Enum
//   }

/// Marker interface for feature enums.
/// Consumer apps implement this on their own feature enum.
abstract interface class FeatureType {
  String get name;
  String get description;
}

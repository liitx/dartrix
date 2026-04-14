// helper_type.dart — supertype enum for injectable helpers and utilities
//
// A helper is a function typedef, utility class, or injectable dependency
// (e.g. ProcessRunner, RegistryLoader, ProfileDetector).
// Each HelperType value declares which features inject it,
// so the matrix knows which helper variants need testing per feature.
//
// Example (in zedup):
//   enum ZedHelper implements HelperType {
//     processRunner(description: 'Runs git/gh subprocesses — injectable for tests'),
//     registryLoader(description: 'Loads WorkRegistry from disk — injectable'),
//     profileDetector(description: 'Detects ZedProfile from git context');
//
//     const ZedHelper({required this.description});
//     @override final String description;
//   }

/// Marker interface for helper enums.
/// Consumer apps implement this on their own helper enum.
abstract interface class HelperType {
  String get name;
  String get description;
}

// dartrix_config.dart — runtime activation context dartrix can read
//
// Dartrix is the matrix coverage framework. Consumers (zedup, claudart,
// app code) tell dartrix which feature names are *active* in the running
// project — typically by adapting an external config like zedup's typed
// activation projection.
//
// dartrix does NOT depend on zedup; it consumes any object that implements
// this contract. Default `DartrixConfig.all()` treats everything as active
// (no filtering), preserving today's matrix behavior for projects that
// don't wire a config.
//
// Use cases:
//   - Filter `testSelector()` registrations so disabled features don't run.
//   - Filter shoelace coverage rendering to active variants only.
//   - Surface "this variant is dimmed because feature X is inactive" in
//     diagnostic output.

abstract class DartrixConfig {
  /// Returns true when [featureName] is enabled in the running project.
  /// Names match the enum variant `.name` (e.g. 'newBranch', 'promote').
  bool isFeatureActive(String featureName);

  /// All active feature names. Empty when this config has no filtering
  /// (treats everything as active — see `DartrixConfig.all`).
  Set<String> get activeFeatureNames;

  /// The active profile name (e.g. 'liitx', 'toyota'). Null when the
  /// consumer hasn't supplied a profile.
  String? get activeProfile;

  /// All-active default — every feature treated as active, no filtering.
  /// Use this when no external config is wired; matches dartrix's pre-S5
  /// behavior.
  factory DartrixConfig.all() = _AllActiveConfig;

  /// Static set of active features, plus optional profile name. Useful for
  /// tests and for consumers that have already resolved the active set.
  factory DartrixConfig.fromFeatures(Set<String> features, {String? profile}) =
      _FromFeaturesConfig;
}

class _AllActiveConfig implements DartrixConfig {
  const _AllActiveConfig();
  @override
  bool isFeatureActive(String featureName) => true;
  @override
  Set<String> get activeFeatureNames => const {};
  @override
  String? get activeProfile => null;
}

class _FromFeaturesConfig implements DartrixConfig {
  const _FromFeaturesConfig(this.activeFeatureNames, {String? profile})
      : activeProfile = profile;
  @override
  final Set<String> activeFeatureNames;
  @override
  final String? activeProfile;
  @override
  bool isFeatureActive(String featureName) =>
      activeFeatureNames.contains(featureName);
}

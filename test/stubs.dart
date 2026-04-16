// stubs.dart — shared test fixtures for dartrix unit tests
//
// Minimal AppType and FeatureType implementations used across test files.
// The exhaustive switch on features() means adding a variant without updating
// the switch is a compile error — the same enforcement dartrix requires of consumers.

import 'package:dartrix/dartrix.dart';

enum TestFeature implements FeatureType {
  alpha('Alpha feature'),
  beta('Beta feature');

  const TestFeature(this.description);

  @override
  final String description;
}

enum TestType implements AppType {
  rover,
  buster;

  @override
  String get description => name;

  @override
  Set<FeatureType> get features => switch (this) {
        TestType.rover  => {TestFeature.alpha},
        TestType.buster => {TestFeature.alpha, TestFeature.beta},
      };
}

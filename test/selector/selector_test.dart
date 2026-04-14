// selector_test.dart — TypedSelector and AppTypeGetSelector.getSelector()
//
// Verifies that getSelector() produces a TypedSelector where:
//   - variant is typed as the concrete AppType subtype (no cast needed)
//   - feature is the passed FeatureType
//   - description matches AppType.description

import 'package:test/test.dart';
import 'package:dartrix/dartrix.dart';

// ── Minimal stubs ─────────────────────────────────────────────────────────────

enum _TestFeature implements FeatureType {
  alpha('Alpha feature'),
  beta('Beta feature');

  const _TestFeature(this.description);

  @override
  final String description;
}

enum _TestType implements AppType {
  rover,
  buster;

  @override
  String get description => name;

  @override
  Set<FeatureType> get features => switch (this) {
        _TestType.rover  => {_TestFeature.alpha},
        _TestType.buster => {_TestFeature.alpha, _TestFeature.beta},
      };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AppTypeGetSelector.getSelector', () {
    const cases = [
      (variant: _TestType.rover,  feature: _TestFeature.alpha, expectedDescription: 'rover'),
      (variant: _TestType.buster, feature: _TestFeature.alpha, expectedDescription: 'buster'),
      (variant: _TestType.buster, feature: _TestFeature.beta,  expectedDescription: 'buster'),
    ];

    for (final c in cases) {
      test('${c.variant}.getSelector(${c.feature})', () {
        final sel = c.variant.getSelector(c.feature);
        expect(sel.variant, equals(c.variant));
        expect(sel.feature, equals(c.feature));
        expect(sel.description, equals(c.expectedDescription));
      });
    }

    test('sel.variant is typed as concrete enum — no cast needed', () {
      final sel = _TestType.rover.getSelector(_TestFeature.alpha);
      // sel.variant is _TestType, not AppType — access enum fields directly
      final _TestType typed = sel.variant;
      expect(typed, equals(_TestType.rover));
    });

    test('getSelector implements DartrixSelector', () {
      final sel = _TestType.buster.getSelector(_TestFeature.beta);
      expect(sel, isA<DartrixSelector>());
    });
  });
}

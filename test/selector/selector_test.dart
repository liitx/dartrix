// selector_test.dart — TypedSelector, AppTypeGetSelector.getSelector(), testSelector()
//
// Three concerns:
//   1. Selector fields — getSelector() produces correct variant, feature, description
//      Loop is over TestType.values × variant.features — adding a variant without
//      updating the exhaustive switch in stubs.dart is a compile error.
//   2. Type preservation — sel.variant is typed as the concrete enum, no cast needed.
//   3. Matrix integration — testSelector() registers coverage on a Dartrix instance;
//      tearDownAll enforces no gaps remain after all loops complete.

import 'package:test/test.dart';
import 'package:dartrix/dartrix.dart';

import '../stubs.dart';

void main() {
  // ── Selector field verification ───────────────────────────────────────────

  group('AppTypeGetSelector.getSelector — selector fields', () {
    for (final variant in TestType.values) {
      for (final feature in variant.features) {
        test('${variant.name}.getSelector(${(feature as Enum).name})', () {
          final sel = variant.getSelector(feature);
          expect(sel.variant, equals(variant));
          expect(sel.feature, equals(feature));
          expect(sel.description, equals(variant.description));
        });
      }
    }

    test('sel.variant is typed as concrete enum — no cast needed', () {
      final sel = TestType.rover.getSelector(TestFeature.alpha);
      // Compile-time check: sel.variant is TestType, not AppType
      final TestType typed = sel.variant;
      expect(typed, equals(TestType.rover));
    });

    test('getSelector result implements DartrixSelector', () {
      final sel = TestType.buster.getSelector(TestFeature.beta);
      expect(sel, isA<DartrixSelector>());
    });
  });

  // ── testSelector — sync matrix integration ──────────────────────────────

  group('testSelector — registers coverage on matrix (sync)', () {
    final matrix = Dartrix(
      axes: [TestType.values],
      features: TestFeature.values,
    );

    for (final variant in TestType.values) {
      for (final feature in variant.features) {
        testSelector(matrix, variant.getSelector(feature), (sel) {
          expect(sel.variant, equals(variant));
          expect(sel.feature, equals(feature));
        });
      }
    }

    tearDownAll(() {
      final gaps = matrix.gaps();
      if (gaps.isNotEmpty) fail(MatrixRenderer(matrix).renderGaps());
    });
  });

  // ── testSelector — async matrix integration ──────────────────────────────

  group('testSelector — registers coverage on matrix (async)', () {
    final matrix = Dartrix(
      axes: [TestType.values],
      features: TestFeature.values,
    );

    for (final variant in TestType.values) {
      for (final feature in variant.features) {
        testSelector(matrix, variant.getSelector(feature), (sel) async {
          // Simulate async work — coverage must register after this resolves
          await Future<void>.value();
          expect(sel.variant, equals(variant));
          expect(sel.feature, equals(feature));
        });
      }
    }

    tearDownAll(() {
      final gaps = matrix.gaps();
      if (gaps.isNotEmpty) fail(MatrixRenderer(matrix).renderGaps());
    });
  });
}

// matrix_test.dart — Dartrix coverage tracking and MatrixRenderer output
//
// Verifies the core matrix contract:
//   - cover() registers a (variant, feature) cell
//   - gaps() returns required cells not yet covered
//   - stateOf() reflects all three CellState values correctly
//   - notApplicable cells never surface as gaps
//   - MatrixRenderer output reflects actual matrix state

import 'package:test/test.dart';
import 'package:dartrix/dartrix.dart';

import '../stubs.dart';

void main() {
  // ── Dartrix ───────────────────────────────────────────────────────────────

  group('Dartrix', () {
    late Dartrix matrix;

    setUp(() {
      matrix = Dartrix(
        axes: [TestType.values],
        features: TestFeature.values,
      );
    });

    // stateOf — all three CellState values
    group('stateOf', () {
      test('gap — required cell not yet covered', () {
        expect(
          matrix.stateOf(TestType.rover, TestFeature.alpha),
          equals(CellState.gap),
        );
      });

      test('covered — required cell after cover()', () {
        matrix.cover(TestType.rover, TestFeature.alpha);
        expect(
          matrix.stateOf(TestType.rover, TestFeature.alpha),
          equals(CellState.covered),
        );
      });

      test('notApplicable — variant does not declare feature', () {
        // rover.features = {alpha} — beta is not applicable
        expect(
          matrix.stateOf(TestType.rover, TestFeature.beta),
          equals(CellState.notApplicable),
        );
      });
    });

    // gaps()
    group('gaps', () {
      test('all required cells are gaps before any coverage', () {
        // Required: (rover,alpha), (buster,alpha), (buster,beta) = 3 cells
        expect(matrix.gaps().length, equals(3));
      });

      test('gap closes after cover()', () {
        matrix.cover(TestType.rover, TestFeature.alpha);
        final gaps = matrix.gaps();
        expect(gaps.length, equals(2));
        expect(
          gaps.any((g) => g.variant == TestType.rover && g.feature == TestFeature.alpha),
          isFalse,
        );
      });

      test('no gaps after all required cells covered', () {
        for (final variant in TestType.values) {
          for (final feature in variant.features) {
            matrix.cover(variant, feature);
          }
        }
        expect(matrix.gaps(), isEmpty);
      });

      test('notApplicable cell never surfaces as a gap', () {
        // Cover everything — (rover, beta) must still not appear
        for (final variant in TestType.values) {
          for (final feature in variant.features) {
            matrix.cover(variant, feature);
          }
        }
        expect(
          matrix.gaps().any((g) => g.variant == TestType.rover && g.feature == TestFeature.beta),
          isFalse,
        );
      });
    });

    // accessors
    test('variants — returns all registered variants', () {
      expect(matrix.variants, containsAll(TestType.values));
      expect(matrix.variants.length, equals(TestType.values.length));
    });

    test('features — returns all registered features', () {
      expect(matrix.features, containsAll(TestFeature.values));
      expect(matrix.features.length, equals(TestFeature.values.length));
    });
  });

  // ── MatrixRenderer ────────────────────────────────────────────────────────

  group('MatrixRenderer', () {
    late Dartrix matrix;
    late MatrixRenderer renderer;

    setUp(() {
      matrix = Dartrix(
        axes: [TestType.values],
        features: TestFeature.values,
      );
      renderer = MatrixRenderer(matrix);
    });

    test('render — contains all variant names', () {
      final output = renderer.render();
      for (final variant in TestType.values) {
        expect(output, contains(variant.name));
      }
    });

    test('render — contains all feature names', () {
      final output = renderer.render();
      for (final feature in TestFeature.values) {
        expect(output, contains(feature.name));
      }
    });

    test('render — gap symbol ✗ present before any coverage', () {
      expect(renderer.render(), contains('✗'));
    });

    test('render — covered symbol ✓ present after cover()', () {
      matrix.cover(TestType.rover, TestFeature.alpha);
      expect(renderer.render(), contains('✓'));
    });

    test('render — notApplicable symbol · present for rover×beta', () {
      expect(renderer.render(), contains('·'));
    });

    test('renderGaps — lists all uncovered required cells', () {
      final output = renderer.renderGaps();
      expect(output, startsWith('GAPS'));
      expect(output, contains('rover'));
      expect(output, contains('alpha'));
    });

    test('renderGaps — no gaps message when fully covered', () {
      for (final variant in TestType.values) {
        for (final feature in variant.features) {
          matrix.cover(variant, feature);
        }
      }
      expect(renderer.renderGaps(), equals('No gaps — all variants covered.'));
    });
  });
}

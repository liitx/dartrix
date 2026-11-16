// confidence_test.dart — the confidence of a proof is a weighted sum written
// out here, and the weights and factors are refused when they cannot be one

import 'package:dartrix/dartrix.dart';
import 'package:test/test.dart';

void main() {
  group('ConfidenceWeights', () {
    final weights = ConfidenceWeights(
        coverage: 0.5, boundary: 0.25, topologyReach: 0.125, impact: 0.125);

    const cases = <({
      String name,
      double coverage,
      ConfidenceFactors factors,
      double expected,
    })>[
      (
        name: 'everything at its best',
        coverage: 1,
        factors: ConfidenceFactors(boundary: 1, topologyReach: 1, impact: 1),
        expected: 1,
      ),
      (
        name: 'nothing',
        coverage: 0,
        factors: ConfidenceFactors(boundary: 0, topologyReach: 0, impact: 0),
        expected: 0,
      ),
      (
        name: 'only coverage',
        coverage: 1,
        factors: ConfidenceFactors(boundary: 0, topologyReach: 0, impact: 0),
        expected: 0.5,
      ),
      (
        name: 'only the boundary',
        coverage: 0,
        factors: ConfidenceFactors(boundary: 1, topologyReach: 0, impact: 0),
        expected: 0.25,
      ),
      (
        name: 'only the topology reach',
        coverage: 0,
        factors: ConfidenceFactors(boundary: 0, topologyReach: 1, impact: 0),
        expected: 0.125,
      ),
      (
        name: 'only the impact',
        coverage: 0,
        factors: ConfidenceFactors(boundary: 0, topologyReach: 0, impact: 1),
        expected: 0.125,
      ),
      (
        name: 'a mix',
        coverage: 0.5,
        factors: ConfidenceFactors(boundary: 0.5, topologyReach: 0.5, impact: 0.5),
        expected: 0.5,
      ),
    ];

    for (final scenario in cases) {
      test('${scenario.name} is ${scenario.expected}', () {
        expect(
          weights.confidenceOf(scenario.factors, coverage: scenario.coverage),
          closeTo(scenario.expected, 1e-9),
        );
      });
    }

    test('the initial weights sum to 1', () {
      const w = ConfidenceWeights.initial;
      expect(w.coverage + w.boundary + w.topologyReach + w.impact, closeTo(1, 1e-9));
    });

    test('the initial weights count coverage most', () {
      const w = ConfidenceWeights.initial;
      expect(w.coverage, greaterThan(w.boundary));
    });

    test('weights that do not sum to 1 are refused', () {
      expect(
        () => ConfidenceWeights(
            coverage: 0.5, boundary: 0.5, topologyReach: 0.5, impact: 0),
        throwsArgumentError,
      );
    });

    test('a weight of exactly 0 is allowed', () {
      expect(
        ConfidenceWeights(coverage: 1, boundary: 0, topologyReach: 0, impact: 0).coverage,
        1,
      );
    });

    test('weights that miss 1 by less than the tolerance are allowed', () {
      expect(
        ConfidenceWeights(
                coverage: 0.5, boundary: 0.5 + 5e-10, topologyReach: 0, impact: 0)
            .boundary,
        0.5 + 5e-10,
      );
    });

    test('weights that miss 1 by more than the tolerance are refused', () {
      expect(
        () => ConfidenceWeights(
            coverage: 0.5, boundary: 0.5 + 2e-9, topologyReach: 0, impact: 0),
        throwsArgumentError,
      );
    });

    test('a negative weight is refused', () {
      expect(
        () => ConfidenceWeights(
            coverage: 1.5, boundary: -0.5, topologyReach: 0, impact: 0),
        throwsArgumentError,
      );
    });
  });

  group('ConfidenceFactors', () {
    test('factors at the ends of the range are in range', () {
      expect(
        const ConfidenceFactors(boundary: 0, topologyReach: 1, impact: 0.5).isInRange,
        isTrue,
      );
    });

    group('one factor out of range', () {
      for (final value in [-0.01, 1.01]) {
        for (final field in FactorField.values) {
          test('$value for ${field.name}', () {
            final factors = ConfidenceFactors(
              boundary: field == FactorField.boundary ? value : 0.5,
              topologyReach: field == FactorField.topologyReach ? value : 0.5,
              impact: field == FactorField.impact ? value : 0.5,
            );
            expect(factors.isInRange, isFalse);
          });
        }
      }
    });
  });

  group('variantCoverageOf', () {
    const cases = <({
      String name,
      List<String> inSpec,
      List<String> covered,
      double expected,
    })>[
      (name: 'all covered', inSpec: ['a', 'b'], covered: ['a', 'b'], expected: 1),
      (name: 'half covered', inSpec: ['a', 'b'], covered: ['a'], expected: 0.5),
      (name: 'none covered', inSpec: ['a', 'b'], covered: [], expected: 0),
      (name: 'an empty spec', inSpec: [], covered: [], expected: 1),
      (
        name: 'a variant outside the spec does not count',
        inSpec: ['a', 'b'],
        covered: ['a', 'z'],
        expected: 0.5,
      ),
    ];
    for (final scenario in cases) {
      test('${scenario.name} is ${scenario.expected}', () {
        expect(variantCoverageOf(scenario.inSpec, scenario.covered), scenario.expected);
      });
    }
  });

  group('ConfidenceTrend', () {
    const cases = <({
      String name,
      List<double> series,
      ConfidenceTrend trend,
      bool flagged,
    })>[
      (name: 'no entries', series: [], trend: ConfidenceTrend.notEnoughHistory, flagged: false),
      (name: 'one entry', series: [0.5], trend: ConfidenceTrend.notEnoughHistory, flagged: false),
      (name: 'rising', series: [0.2, 0.5], trend: ConfidenceTrend.rising, flagged: false),
      (name: 'equal', series: [0.5, 0.5], trend: ConfidenceTrend.stalled, flagged: true),
      (name: 'falling', series: [0.5, 0.2], trend: ConfidenceTrend.dropped, flagged: true),
      (
        name: 'only the last step counts: rose, then stalled',
        series: [0.1, 0.5, 0.5],
        trend: ConfidenceTrend.stalled,
        flagged: true,
      ),
      (
        name: 'only the last step counts: fell, then rose',
        series: [0.9, 0.2, 0.5],
        trend: ConfidenceTrend.rising,
        flagged: false,
      ),
      (
        name: 'a difference below the tolerance is a stall',
        series: [0.5, 0.5 + 5e-10],
        trend: ConfidenceTrend.stalled,
        flagged: true,
      ),
      (
        name: 'a difference above the tolerance is a rise',
        series: [0.5, 0.5 + 2e-9],
        trend: ConfidenceTrend.rising,
        flagged: false,
      ),
    ];
    for (final scenario in cases) {
      test('${scenario.name} is ${scenario.trend.name}', () {
        expect(ConfidenceTrend.of(scenario.series), scenario.trend);
      });
      test('${scenario.name} is ${scenario.flagged ? '' : 'not '}flagged', () {
        expect(ConfidenceTrend.of(scenario.series).isFlagged, scenario.flagged);
      });
    }
  });
}

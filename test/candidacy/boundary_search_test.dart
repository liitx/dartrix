// boundary_search_test.dart — bisecting finds the last level that held with few
// runs, says so when a candidate never broke or never held, and checks the
// monotone assumption instead of trusting it

import 'package:dartrix/dartrix.dart';
import 'package:test/test.dart';

/// A predicate that holds up to and including [limit].
bool Function(int) holdsUpTo(int limit) => (level) => level <= limit;

void main() {
  group('findBoundary', () {
    const levels = [1, 2, 4, 8, 16, 32];

    // Runs counted by hand: the bottom, the top, then each middle probed.
    const cases = <({
      String name,
      int limit,
      int? highest,
      int? lowestFail,
      int runs,
    })>[
      (name: 'never held', limit: 0, highest: null, lowestFail: 1, runs: 1),
      (name: 'held only at the bottom', limit: 1, highest: 1, lowestFail: 2, runs: 4),
      (name: 'held through 2', limit: 2, highest: 2, lowestFail: 4, runs: 4),
      (name: 'held through 4', limit: 4, highest: 4, lowestFail: 8, runs: 4),
      (name: 'held through 8', limit: 8, highest: 8, lowestFail: 16, runs: 5),
      (name: 'held through 16', limit: 16, highest: 16, lowestFail: 32, runs: 5),
      (name: 'never broke', limit: 32, highest: 32, lowestFail: null, runs: 2),
    ];
    for (final scenario in cases) {
      test(scenario.name, () {
        final found = findBoundary(levels, holdsUpTo(scenario.limit));
        expect((found.highestHolding, found.lowestFailing),
            (scenario.highest, scenario.lowestFail));
      });

      test('${scenario.name} takes ${scenario.runs} runs', () {
        expect(findBoundary(levels, holdsUpTo(scenario.limit)).evaluations,
            scenario.runs);
      });
    }

    test('no levels finds nothing and runs nothing', () {
      final found = findBoundary(const [], (_) => true);
      expect((found.highestHolding, found.lowestFailing, found.evaluations),
          (null, null, 0));
    });

    test('one level that holds never broke', () {
      final found = findBoundary(const [5], (_) => true);
      expect((found.highestHolding, found.lowestFailing), (5, null));
    });

    test('one level that fails never held', () {
      final found = findBoundary(const [5], (_) => false);
      expect((found.highestHolding, found.lowestFailing), (null, 5));
    });

    test('a thousand levels are found in about ten runs', () {
      final many = List.generate(1000, (i) => i);
      expect(findBoundary(many, holdsUpTo(617)).evaluations, lessThanOrEqualTo(12));
    });

    test('the found boundary is exact for every limit of a long list', () {
      final many = List.generate(50, (i) => i);
      for (var limit = 0; limit < 50; limit++) {
        final found = findBoundary(many, holdsUpTo(limit));
        expect(found.highestHolding, limit, reason: 'limit $limit');
      }
    });
  });

  group('firstNonMonotone', () {
    const levels = [1, 2, 3, 4, 5];

    test('a predicate that holds up to a limit is monotone', () {
      expect(firstNonMonotone(levels, holdsUpTo(3)), isNull);
    });

    test('one that always holds is monotone', () {
      expect(firstNonMonotone(levels, (_) => true), isNull);
    });

    test('one that never holds is monotone', () {
      expect(firstNonMonotone(levels, (_) => false), isNull);
    });

    test('a level that holds after a failure is named', () {
      expect(firstNonMonotone(levels, (level) => level != 3), 4);
    });

    test('only the first such level is named', () {
      expect(firstNonMonotone(levels, (level) => level == 1 || level == 4 || level == 5), 4);
    });

    test('bisecting a non-monotone predicate can miss it, the check finds it', () {
      bool holds(int level) => level != 2;
      final bisected = findBoundary(levels, holds);
      expect(
        (bisected.highestHolding, firstNonMonotone(levels, holds)),
        isNot((bisected.highestHolding, null)),
      );
    });
  });

  group('normalizedBoundary', () {
    const levels = [1, 2, 4, 8];

    test('no level held is 0', () {
      expect(normalizedBoundary(levels, null), 0);
    });

    test('the bottom level held is a quarter', () {
      expect(normalizedBoundary(levels, 1), 0.25);
    });

    test('the top level held is 1', () {
      expect(normalizedBoundary(levels, 8), 1);
    });

    test('a middle level is its position over the count', () {
      expect(normalizedBoundary(levels, 4), 0.75);
    });

    test('no levels is 0', () {
      expect(normalizedBoundary(const [], 3), 0);
    });
  });
}

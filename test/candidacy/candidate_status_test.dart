// candidate_status_test.dart — the moves a candidate may make, and what each
// target status requires of the entry that records it
//
// Every (from, to) pair is classified by a table written out in
// candidacy_stubs.dart, not read from the enum under test.

import 'package:dartrix/dartrix.dart';
import 'package:test/test.dart';

import 'candidacy_stubs.dart';

void main() {
  group('CandidateStatus', () {
    test('every status has a row in the expected moves', () {
      expect(expectedLegalMoves.keys.toSet(), CandidateStatus.values.toSet());
    });

    group('canMoveTo', () {
      for (final from in CandidateStatus.values) {
        for (final to in CandidateStatus.values) {
          final legal = expectedLegalMoves[from]!.contains(to);
          test('${from.name} -> ${to.name} is ${legal ? 'legal' : 'illegal'}',
              () {
            expect(from.canMoveTo(to), legal);
          });
        }
      }
    });

    group('requiresPassedAudit', () {
      const expected = {CandidateStatus.proven, CandidateStatus.bounded};
      for (final status in CandidateStatus.values) {
        test(
            '${status.name} ${expected.contains(status) ? 'requires' : 'does not require'} a passed audit',
            () {
          expect(status.requiresPassedAudit, expected.contains(status));
        });
      }
    });

    group('requiresFullVariantCoverage', () {
      for (final status in CandidateStatus.values) {
        final expected = status == CandidateStatus.proven;
        test(
            '${status.name} ${expected ? 'requires' : 'does not require'} every spec variant covered',
            () {
          expect(status.requiresFullVariantCoverage, expected);
        });
      }
    });

    group('requiresFactors', () {
      const expected = {
        CandidateStatus.proven,
        CandidateStatus.bounded,
        CandidateStatus.axiom,
      };
      for (final status in CandidateStatus.values) {
        test(
            '${status.name} ${expected.contains(status) ? 'requires' : 'does not require'} confidence factors',
            () {
          expect(status.requiresFactors, expected.contains(status));
        });
      }
    });

    group('requiresEvidence', () {
      for (final status in CandidateStatus.values) {
        final expected = status != CandidateStatus.candidate;
        test(
            '${status.name} ${expected ? 'requires' : 'does not require'} evidence',
            () {
          expect(status.requiresEvidence, expected);
        });
      }
    });

    group('requiresJustifiedThreshold', () {
      for (final status in CandidateStatus.values) {
        final expected = status == CandidateStatus.axiom;
        test(
            '${status.name} ${expected ? 'requires' : 'does not require'} a justification and a threshold',
            () {
          expect(status.requiresJustifiedThreshold, expected);
        });
      }
    });
  });
}

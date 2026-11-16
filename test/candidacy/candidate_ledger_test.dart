// candidate_ledger_test.dart — the candidate ledger is append-only and refuses
// an entry that breaks a rule, with the refusal named
//
// Each rule is tested by an entry that is valid in every other respect, built
// by validEntry, so a refusal can only come from the one fact that changed.

import 'package:dartrix/dartrix.dart';
import 'package:test/test.dart';

import 'candidacy_stubs.dart';

void main() {
  group('CandidateLedger', () {
    group('the first entry of a candidate', () {
      for (final status in CandidateStatus.values) {
        final accepted = status == CandidateStatus.candidate;
        test(
            '${status.name} is ${accepted ? 'accepted' : 'refused as firstStatusNotCandidate'}',
            () {
          expect(
            CandidateLedger().append(validEntry(status)),
            accepted ? isNull : LedgerRefusal.firstStatusNotCandidate,
          );
        });
      }
    });

    group('a move from the last status', () {
      for (final from in CandidateStatus.values) {
        for (final to in CandidateStatus.values) {
          final legal = expectedLegalMoves[from]!.contains(to);
          test(
              '${from.name} -> ${to.name} is ${legal ? 'accepted' : 'refused as illegalMove'}',
              () {
            expect(
              ledgerAt(from).append(validEntry(to)),
              legal ? isNull : LedgerRefusal.illegalMove,
            );
          });
        }
      }
    });

    group('evidence', () {
      for (final status in CandidateStatus.values) {
        if (status == CandidateStatus.candidate) continue;
        test('${status.name} without evidence is refused as noEvidence', () {
          final ledger = status == CandidateStatus.underTest
              ? ledgerAt(CandidateStatus.candidate)
              : ledgerAt(_before(status));
          expect(ledger.append(validEntry(status, evidence: const [])),
              LedgerRefusal.noEvidence);
        });
      }

      test('a candidate needs none', () {
        expect(CandidateLedger().append(validEntry(CandidateStatus.candidate, evidence: const [])), isNull);
      });
    });

    group('the Phase 0 audit', () {
      for (final target in [CandidateStatus.proven, CandidateStatus.bounded]) {
        for (final check in ProofAuditCheck.values) {
          for (final outcome in ProofAuditOutcome.values) {
            if (outcome == ProofAuditOutcome.passed) continue;
            test(
                '${target.name} with ${check.name} ${outcome.name} is refused as auditNotPassed',
                () {
              final audit = ProofAudit({
                for (final other in ProofAuditCheck.values)
                  other: other == check ? outcome : ProofAuditOutcome.passed,
              });
              expect(
                ledgerAt(CandidateStatus.underTest)
                    .append(validEntry(target, audit: audit)),
                LedgerRefusal.auditNotPassed,
              );
            });
          }
        }
      }

      test('refuted needs no passed audit: a failed proof is still a result', () {
        expect(
          ledgerAt(CandidateStatus.underTest).append(validEntry(
              CandidateStatus.refuted,
              audit: ProofAudit.notRun())),
          isNull,
        );
      });
    });

    group('the scope of a claim', () {
      test('covering a variant the spec does not name is refused', () {
        expect(
          ledgerAt(CandidateStatus.underTest).append(validEntry(
              CandidateStatus.bounded,
              variantsCovered: const ['alpha', 'gamma'])),
          LedgerRefusal.coversVariantOutsideSpec,
        );
      });

      test('proven with a spec variant uncovered is refused as variantsMissing', () {
        expect(
          ledgerAt(CandidateStatus.underTest).append(validEntry(
              CandidateStatus.proven, variantsCovered: const ['alpha'])),
          LedgerRefusal.variantsMissing,
        );
      });

      test('bounded with a spec variant uncovered is accepted', () {
        expect(
          ledgerAt(CandidateStatus.underTest).append(validEntry(
              CandidateStatus.bounded, variantsCovered: const ['alpha'])),
          isNull,
        );
      });
    });

    group('an axiom', () {
      test('without a justification is refused', () {
        expect(
          ledgerAt(CandidateStatus.proven)
              .append(validEntry(CandidateStatus.axiom, justification: '  ')),
          LedgerRefusal.axiomWithoutJustification,
        );
      });

      test('without a threshold is refused', () {
        expect(
          ledgerAt(CandidateStatus.proven).append(CandidateLedgerEntry(
            candidateId: 'stub',
            status: CandidateStatus.axiom,
            specReference: 'docs/stub.md, section 1',
            mockDatasetVersion: 'mock-1',
            evidence: const ['e'],
            justification: 'j',
            variantsInSpec: stubVariantsInSpec,
            variantsCovered: stubVariantsInSpec,
            audit: passedAudit(),
            factors: fullFactors,
          )),
          LedgerRefusal.axiomWithoutThreshold,
        );
      });
    });

    group('the confidence factors', () {
      for (final target in [
        CandidateStatus.proven,
        CandidateStatus.bounded,
      ]) {
        test('${target.name} without factors is refused as factorsMissing', () {
          expect(
            ledgerAt(CandidateStatus.underTest).append(CandidateLedgerEntry(
              candidateId: 'stub',
              status: target,
              specReference: 'docs/stub.md, section 1',
              mockDatasetVersion: 'mock-1',
              evidence: const ['e'],
              justification: 'j',
              variantsInSpec: stubVariantsInSpec,
              variantsCovered: stubVariantsInSpec,
              audit: passedAudit(),
            )),
            LedgerRefusal.factorsMissing,
          );
        });
      }

      for (final field in FactorField.values) {
        for (final value in [-0.1, 1.1]) {
          test('$value for ${field.name} is refused as factorOutOfRange', () {
            final factors = ConfidenceFactors(
              boundary: field == FactorField.boundary ? value : 1,
              topologyReach: field == FactorField.topologyReach ? value : 1,
              impact: field == FactorField.impact ? value : 1,
            );
            expect(
              ledgerAt(CandidateStatus.underTest)
                  .append(validEntry(CandidateStatus.underTest, factors: factors)),
              LedgerRefusal.factorOutOfRange,
            );
          });
        }
      }

      test('a re-test at underTest is accepted', () {
        expect(
          ledgerAt(CandidateStatus.underTest)
              .append(validEntry(CandidateStatus.underTest)),
          isNull,
        );
      });
    });

    group('an axiom threshold', () {
      for (final threshold in [-0.1, 1.1]) {
        test('$threshold is refused as thresholdOutOfRange', () {
          expect(
            ledgerAt(CandidateStatus.proven)
                .append(validEntry(CandidateStatus.axiom, threshold: threshold)),
            LedgerRefusal.thresholdOutOfRange,
          );
        });
      }

      test('0 is allowed', () {
        expect(
          ledgerAt(CandidateStatus.proven)
              .append(validEntry(CandidateStatus.axiom, threshold: 0)),
          isNull,
        );
      });

      test('1 is allowed when the confidence is 1', () {
        expect(
          ledgerAt(CandidateStatus.proven)
              .append(validEntry(CandidateStatus.axiom, threshold: 1)),
          isNull,
        );
      });

      test('above the entry confidence is refused as confidenceBelowThreshold', () {
        const lowFactors =
            ConfidenceFactors(boundary: 0, topologyReach: 0, impact: 0);
        // coverage 1 -> 0.4 under the initial weights
        expect(
          ledgerAt(CandidateStatus.proven).append(validEntry(
              CandidateStatus.axiom, factors: lowFactors, threshold: 0.5)),
          LedgerRefusal.confidenceBelowThreshold,
        );
      });

      test('equal to the entry confidence is accepted', () {
        const lowFactors =
            ConfidenceFactors(boundary: 0, topologyReach: 0, impact: 0);
        expect(
          ledgerAt(CandidateStatus.proven).append(validEntry(
              CandidateStatus.axiom, factors: lowFactors, threshold: 0.4)),
          isNull,
        );
      });
    });

    group('the trend of a candidate', () {
      CandidateLedger withSeries(List<double> series) {
        final ledger = ledgerAt(CandidateStatus.candidate);
        for (final value in series) {
          ledger.append(validEntry(
            CandidateStatus.underTest,
            factors: ConfidenceFactors(boundary: value, topologyReach: 0, impact: 0),
          ));
        }
        return ledger;
      }

      test('one measured entry is not enough history', () {
        expect(withSeries([0.5]).trendOf('stub'), ConfidenceTrend.notEnoughHistory);
      });

      test('a higher last entry is rising', () {
        expect(withSeries([0.2, 0.6]).trendOf('stub'), ConfidenceTrend.rising);
      });

      test('an equal last entry is stalled', () {
        expect(withSeries([0.2, 0.6, 0.6]).trendOf('stub'), ConfidenceTrend.stalled);
      });

      test('a stalled candidate is flagged', () {
        expect(withSeries([0.2, 0.6, 0.6]).flagged, ['stub']);
      });

      test('a lower last entry is dropped', () {
        expect(withSeries([0.6, 0.2]).trendOf('stub'), ConfidenceTrend.dropped);
      });

      test('a dropped candidate is flagged', () {
        expect(withSeries([0.6, 0.2]).flagged, ['stub']);
      });

      test('a rising candidate is not flagged', () {
        expect(withSeries([0.2, 0.6]).flagged, isEmpty);
      });

      test('an entry without factors is not in the series', () {
        final ledger = withSeries([0.2])..append(validEntry(CandidateStatus.underTest));
        expect(ledger.confidenceSeries('stub').length, 1);
      });

      test('the series follows the ledger weights', () {
        final ledger = CandidateLedger(
          weights: ConfidenceWeights(
              coverage: 0, boundary: 1, topologyReach: 0, impact: 0),
        )
          ..append(validEntry(CandidateStatus.candidate))
          ..append(validEntry(CandidateStatus.underTest,
              factors: const ConfidenceFactors(boundary: 0.3, topologyReach: 1, impact: 1)));
        expect(ledger.confidenceSeries('stub'), [0.3]);
      });
    });

    group('append only', () {
      test('a refused entry leaves the ledger unchanged', () {
        final ledger = ledgerAt(CandidateStatus.candidate);
        ledger.append(validEntry(CandidateStatus.axiom));
        expect(ledger.entries.length, 1);
      });

      test('an accepted entry is added after the earlier ones', () {
        final ledger = ledgerAt(CandidateStatus.candidate);
        ledger.append(validEntry(CandidateStatus.underTest));
        expect(ledger.entries.map((e) => e.status),
            [CandidateStatus.candidate, CandidateStatus.underTest]);
      });

      test('the entries it exposes cannot be changed', () {
        final ledger = ledgerAt(CandidateStatus.candidate);
        expect(() => ledger.entries.add(validEntry(CandidateStatus.underTest)),
            throwsUnsupportedError);
      });

      test('appending does not change an earlier entry', () {
        final ledger = ledgerAt(CandidateStatus.candidate);
        final first = ledger.entries.first;
        ledger.append(validEntry(CandidateStatus.underTest));
        expect(ledger.entries.first, same(first));
      });
    });

    group('candidates are independent', () {
      test('a second candidate starts from candidate, whatever the first reached', () {
        final ledger = ledgerAt(CandidateStatus.axiom);
        expect(
          ledger.append(validEntry(CandidateStatus.underTest, candidateId: 'other')),
          LedgerRefusal.firstStatusNotCandidate,
        );
      });

      test('statusOf names the last status of each candidate', () {
        final ledger = ledgerAt(CandidateStatus.proven)
          ..append(validEntry(CandidateStatus.candidate, candidateId: 'other'));
        expect(
          (ledger.statusOf('stub'), ledger.statusOf('other')),
          (CandidateStatus.proven, CandidateStatus.candidate),
        );
      });

      test('statusOf an unknown candidate is null', () {
        expect(CandidateLedger().statusOf('nobody'), isNull);
      });
    });

    group('json lines', () {
      test('write then parse gives the same entries', () {
        final ledger = ledgerAt(CandidateStatus.axiom);
        final parsed = CandidateLedger.parse(ledger.toJsonLines());
        expect(parsed.ledger.entries, ledger.entries);
      });

      test('a clean parse has no refusals', () {
        final parsed = CandidateLedger.parse(ledgerAt(CandidateStatus.axiom).toJsonLines());
        expect(parsed.refusals, isEmpty);
      });

      test('blank lines are skipped', () {
        final text = '\n${ledgerAt(CandidateStatus.candidate).toJsonLines()}\n\n';
        expect(CandidateLedger.parse(text).ledger.entries.length, 1);
      });

      test('a line that is not JSON is refused as malformed, with its line number', () {
        final parsed = CandidateLedger.parse('not json');
        expect(parsed.refusals, [(line: 1, refusal: LedgerRefusal.malformedEntry)]);
      });

      test('a line with an unknown status is refused as unknownStatus', () {
        final good = ledgerAt(CandidateStatus.candidate).toJsonLines();
        final bad = good.replaceFirst('"candidate"', '"almostProven"');
        expect(CandidateLedger.parse(bad).refusals,
            [(line: 1, refusal: LedgerRefusal.unknownStatus)]);
      });

      test('a refused line is not in the parsed ledger', () {
        final parsed = CandidateLedger.parse('not json');
        expect(parsed.ledger.entries, isEmpty);
      });

      test('an illegal move in the text is refused by the same rules as append', () {
        final lines = [
          validEntry(CandidateStatus.candidate),
          validEntry(CandidateStatus.axiom),
        ].map((e) => CandidateLedger.encode(e)).join('\n');
        expect(CandidateLedger.parse(lines).refusals,
            [(line: 2, refusal: LedgerRefusal.illegalMove)]);
      });
    });
  });
}

/// The status a candidate must stand at to move to [status].
CandidateStatus _before(CandidateStatus status) => switch (status) {
      CandidateStatus.candidate => CandidateStatus.candidate,
      CandidateStatus.underTest => CandidateStatus.candidate,
      CandidateStatus.proven ||
      CandidateStatus.bounded ||
      CandidateStatus.refuted =>
        CandidateStatus.underTest,
      CandidateStatus.axiom => CandidateStatus.proven,
    };

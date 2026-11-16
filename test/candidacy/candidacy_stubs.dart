// candidacy_stubs.dart — shared fixtures for the candidacy tests
//
// A valid entry for every status, so a test of one rule changes exactly the
// one fact that rule is about and nothing else.

import 'package:dartrix/dartrix.dart';

/// The variants the stub candidate's spec names.
const stubVariantsInSpec = ['alpha', 'beta'];

/// Every factor at its best.
const fullFactors =
    ConfidenceFactors(boundary: 1, topologyReach: 1, impact: 1);

/// A passed Phase 0 audit: every check passed.
ProofAudit passedAudit() => ProofAudit({
      for (final check in ProofAuditCheck.values) check: ProofAuditOutcome.passed,
    });

/// A valid entry for [status]: every rule the status carries is met.
CandidateLedgerEntry validEntry(
  CandidateStatus status, {
  String candidateId = 'stub',
  List<String> evidence = const ['test/stub_test.dart: holds'],
  ProofAudit? audit,
  List<String> variantsCovered = stubVariantsInSpec,
  String justification = 'the proof held',
  double? threshold,
  String? boundary,
  ConfidenceFactors? factors,
}) =>
    CandidateLedgerEntry(
      candidateId: candidateId,
      status: status,
      specReference: 'docs/stub.md, section 1',
      mockDatasetVersion: 'mock-1',
      evidence: evidence,
      justification: justification,
      variantsInSpec: stubVariantsInSpec,
      variantsCovered: variantsCovered,
      audit: audit ?? passedAudit(),
      boundary: boundary,
      threshold: status == CandidateStatus.axiom ? (threshold ?? 0.8) : threshold,
      factors: factors ?? (status.requiresFactors ? fullFactors : null),
    );

/// The moves a candidate may make, written out here and not read from the enum,
/// so changing a rule on the enum fails a test.
const expectedLegalMoves = <CandidateStatus, Set<CandidateStatus>>{
  CandidateStatus.candidate: {CandidateStatus.underTest},
  CandidateStatus.underTest: {
    CandidateStatus.underTest,
    CandidateStatus.proven,
    CandidateStatus.bounded,
    CandidateStatus.refuted,
  },
  CandidateStatus.proven: {CandidateStatus.axiom},
  CandidateStatus.bounded: {},
  CandidateStatus.refuted: {},
  CandidateStatus.axiom: {},
};

/// A ledger whose candidate [id] stands at [status] by valid entries.
CandidateLedger ledgerAt(CandidateStatus status, {String id = 'stub'}) {
  final path = switch (status) {
    CandidateStatus.candidate => [CandidateStatus.candidate],
    CandidateStatus.underTest => [
        CandidateStatus.candidate,
        CandidateStatus.underTest,
      ],
    CandidateStatus.proven => [
        CandidateStatus.candidate,
        CandidateStatus.underTest,
        CandidateStatus.proven,
      ],
    CandidateStatus.bounded => [
        CandidateStatus.candidate,
        CandidateStatus.underTest,
        CandidateStatus.bounded,
      ],
    CandidateStatus.refuted => [
        CandidateStatus.candidate,
        CandidateStatus.underTest,
        CandidateStatus.refuted,
      ],
    CandidateStatus.axiom => [
        CandidateStatus.candidate,
        CandidateStatus.underTest,
        CandidateStatus.proven,
        CandidateStatus.axiom,
      ],
  };
  final ledger = CandidateLedger();
  for (final step in path) {
    final refusal = ledger.append(validEntry(step, candidateId: id));
    if (refusal != null) {
      throw StateError('fixture path refused at ${step.name}: ${refusal.name}');
    }
  }
  return ledger;
}

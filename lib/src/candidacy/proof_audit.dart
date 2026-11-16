// proof_audit.dart — Phase 0: is the infrastructure under a proof trustworthy?
//
// A proof is only as valid as the mocks under it. Before a candidate is
// proven or bounded, each check below must have passed; an unchecked check
// counts against the proof, never for it.

/// One thing Phase 0 verifies about the harness, fixtures and mock data.
enum ProofAuditCheck {
  /// The mock data matches the spec of the feature and its variants (the spec
  /// is cited).
  mocksMatchSpec,

  /// The mocks are deterministic and reproducible.
  mocksDeterministic,

  /// Every test can fail: a negative or mutation case shows it.
  everyTestCanFail,

  /// No mock makes a test tautological (passing because the mock mirrors the
  /// assertion).
  noTautologicalMock,

  /// The covered variants and the missing ones are listed.
  variantCoverageExplicit,
}

/// What a check found.
enum ProofAuditOutcome {
  /// The check ran and the harness met it.
  passed,

  /// The check ran and the harness did not meet it.
  failed,

  /// The check has not been run.
  notChecked,
}

/// The outcome of every Phase 0 check for one candidate's mocks.
class ProofAudit {
  /// Records [outcomes]; a check with no entry is not checked.
  ProofAudit(Map<ProofAuditCheck, ProofAuditOutcome> outcomes)
      : _outcomes = Map.unmodifiable(outcomes);

  /// An audit in which nothing has been checked.
  ProofAudit.notRun() : _outcomes = const {};

  final Map<ProofAuditCheck, ProofAuditOutcome> _outcomes;

  /// What [check] found; [ProofAuditOutcome.notChecked] if it was not recorded.
  ProofAuditOutcome outcomeOf(ProofAuditCheck check) =>
      _outcomes[check] ?? ProofAuditOutcome.notChecked;

  /// The checks that did not pass, in the order the checks are declared.
  List<ProofAuditCheck> get unmet => [
        for (final check in ProofAuditCheck.values)
          if (outcomeOf(check) != ProofAuditOutcome.passed) check,
      ];

  /// Whether every check passed.
  bool get isPassed => unmet.isEmpty;

  /// The recorded outcomes by name, in declaration order.
  Map<String, String> toJson() => {
        for (final check in ProofAuditCheck.values)
          if (_outcomes.containsKey(check)) check.name: _outcomes[check]!.name,
      };

  /// Reads [json]; null if it names a check or an outcome that does not exist.
  static ProofAudit? tryFromJson(Map<String, Object?> json) {
    final outcomes = <ProofAuditCheck, ProofAuditOutcome>{};
    for (final entry in json.entries) {
      final check = ProofAuditCheck.values.asNameMap()[entry.key];
      final outcome = entry.value is String
          ? ProofAuditOutcome.values.asNameMap()[entry.value]
          : null;
      if (check == null || outcome == null) return null;
      outcomes[check] = outcome;
    }
    return ProofAudit(outcomes);
  }
}

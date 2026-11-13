// candidate_status.dart — where a candidate stands, and the moves it may make
//
// A candidate is a falsifiable postulate about a feature, variant or
// topological relationship. It is proven, bounded or refuted on evidence, and
// only a proven one becomes an axiom. The rules live on the enum so a ledger
// asks the status, never re-states the rule.

/// Where a candidate stands.
enum CandidateStatus {
  /// Stated as one falsifiable sentence; nothing has been run.
  candidate,

  /// A proof is being run on it.
  underTest,

  /// Held for every variant its spec names, on mocks whose audit passed.
  proven,

  /// Held only up to a boundary, or for some of the spec's variants.
  bounded,

  /// A result that contradicts it was found.
  refuted,

  /// A proven candidate later work may rely on without re-proving it.
  axiom;

  /// The statuses a candidate at this status may move to. Exhaustive: a new
  /// status fails to compile until its moves are decided.
  Set<CandidateStatus> get legalNext => switch (this) {
        candidate => {underTest},
        underTest => {proven, bounded, refuted},
        proven => {axiom},
        bounded || refuted || axiom => const {},
      };

  /// Whether a candidate at this status may move to [next].
  bool canMoveTo(CandidateStatus next) => legalNext.contains(next);

  /// Whether the entry recording this status needs a Phase 0 audit in which
  /// every check passed: a proof is only as valid as the mocks under it. A
  /// refutation is a result whatever the mocks, so it needs none.
  bool get requiresPassedAudit => this == proven || this == bounded;

  /// Whether the entry must cover every variant its spec names: a proof covers
  /// no variants beyond the ones tested, so a partial one is `bounded`.
  bool get requiresFullVariantCoverage => this == proven;

  /// Whether the entry must cite evidence.
  bool get requiresEvidence => this != candidate;

  /// Whether the entry must carry a justification and the threshold it states.
  bool get requiresJustifiedThreshold => this == axiom;
}

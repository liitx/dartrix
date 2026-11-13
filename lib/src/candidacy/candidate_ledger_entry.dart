// candidate_ledger_entry.dart — one line of the candidate ledger

import 'dart:convert';

import 'candidate_status.dart';
import 'proof_audit.dart';

/// Why the ledger refuses an entry.
enum LedgerRefusal {
  /// The candidate's first entry is not `candidate`.
  firstStatusNotCandidate,

  /// The move from the candidate's last status is not one the status allows.
  illegalMove,

  /// The entry covers a variant its spec does not name.
  coversVariantOutsideSpec,

  /// The status needs evidence and the entry cites none.
  noEvidence,

  /// The status needs a passed Phase 0 audit and a check did not pass.
  auditNotPassed,

  /// `proven` while a variant the spec names is not covered; that is `bounded`.
  variantsMissing,

  /// An axiom with a blank justification.
  axiomWithoutJustification,

  /// An axiom that states no threshold.
  axiomWithoutThreshold,

  /// The line names a status that does not exist.
  unknownStatus,

  /// The line is not an entry: not JSON, a missing or mistyped field, or an
  /// unknown audit check.
  malformedEntry,
}

/// The fields of an entry, as they are written.
enum LedgerField {
  /// Which candidate this is about.
  candidateId(isRequired: true),

  /// The status the candidate moves to.
  status(isRequired: true),

  /// The spec section the entry rests on.
  specReference(isRequired: true),

  /// The version of the mock data the proof ran on.
  mockDatasetVersion(isRequired: true),

  /// What the entry rests on: tests, runs, ledger rows.
  evidence(isRequired: true),

  /// Why the status is justified.
  justification(isRequired: true),

  /// Every variant the spec names.
  variantsInSpec(isRequired: true),

  /// The variants the proof covered.
  variantsCovered(isRequired: true),

  /// The Phase 0 audit of the mocks.
  audit(isRequired: true),

  /// The highest complexity at which the candidate still held.
  boundary(isRequired: false),

  /// The threshold an axiom was promoted above.
  threshold(isRequired: false);

  const LedgerField({required this.isRequired});

  /// Whether a written entry must carry it.
  final bool isRequired;
}

/// A candidate's status at one point, with what it rests on.
class CandidateLedgerEntry {
  /// Records one step of a candidate. The lists are copied.
  CandidateLedgerEntry({
    required this.candidateId,
    required this.status,
    required this.specReference,
    required this.mockDatasetVersion,
    required List<String> evidence,
    required this.justification,
    required List<String> variantsInSpec,
    required List<String> variantsCovered,
    required this.audit,
    this.boundary,
    this.threshold,
  })  : evidence = List.unmodifiable(evidence),
        variantsInSpec = List.unmodifiable(variantsInSpec),
        variantsCovered = List.unmodifiable(variantsCovered);

  /// Which candidate this is about.
  final String candidateId;

  /// The status the candidate moves to.
  final CandidateStatus status;

  /// The spec section the entry rests on.
  final String specReference;

  /// The version of the mock data the proof ran on.
  final String mockDatasetVersion;

  /// What the entry rests on.
  final List<String> evidence;

  /// Why the status is justified.
  final String justification;

  /// Every variant the spec names.
  final List<String> variantsInSpec;

  /// The variants the proof covered.
  final List<String> variantsCovered;

  /// The Phase 0 audit of the mocks.
  final ProofAudit audit;

  /// The highest complexity at which the candidate still held, if measured.
  final String? boundary;

  /// The threshold an axiom was promoted above.
  final String? threshold;

  /// The entry as a JSON object, optional fields left out when absent.
  Map<String, Object?> toJson() => {
        LedgerField.candidateId.name: candidateId,
        LedgerField.status.name: status.name,
        LedgerField.specReference.name: specReference,
        LedgerField.mockDatasetVersion.name: mockDatasetVersion,
        LedgerField.evidence.name: evidence,
        LedgerField.justification.name: justification,
        LedgerField.variantsInSpec.name: variantsInSpec,
        LedgerField.variantsCovered.name: variantsCovered,
        LedgerField.audit.name: audit.toJson(),
        if (boundary != null) LedgerField.boundary.name: boundary,
        if (threshold != null) LedgerField.threshold.name: threshold,
      };

  /// Reads [json]: the entry, or the reason it is not one. Nothing is
  /// defaulted: an unknown status is named, not turned into another.
  static ({CandidateLedgerEntry? entry, LedgerRefusal? refusal}) tryParse(
    Map<String, Object?> json,
  ) {
    const malformed = (entry: null, refusal: LedgerRefusal.malformedEntry);
    String? text(LedgerField field) {
      final value = json[field.name];
      return value is String ? value : null;
    }

    List<String>? texts(LedgerField field) {
      final value = json[field.name];
      return value is List && value.every((e) => e is String)
          ? value.cast<String>()
          : null;
    }

    final candidateId = text(LedgerField.candidateId);
    final statusName = text(LedgerField.status);
    final specReference = text(LedgerField.specReference);
    final mockDatasetVersion = text(LedgerField.mockDatasetVersion);
    final evidence = texts(LedgerField.evidence);
    final justification = text(LedgerField.justification);
    final variantsInSpec = texts(LedgerField.variantsInSpec);
    final variantsCovered = texts(LedgerField.variantsCovered);
    final auditJson = json[LedgerField.audit.name];
    final audit = auditJson is Map<String, Object?>
        ? ProofAudit.tryFromJson(auditJson)
        : null;
    final optionalTypesHold = [LedgerField.boundary, LedgerField.threshold]
        .every((f) => json[f.name] == null || json[f.name] is String);
    if (candidateId == null ||
        statusName == null ||
        specReference == null ||
        mockDatasetVersion == null ||
        evidence == null ||
        justification == null ||
        variantsInSpec == null ||
        variantsCovered == null ||
        audit == null ||
        !optionalTypesHold) {
      return malformed;
    }
    final status = CandidateStatus.values.asNameMap()[statusName];
    if (status == null) {
      return (entry: null, refusal: LedgerRefusal.unknownStatus);
    }
    return (
      entry: CandidateLedgerEntry(
        candidateId: candidateId,
        status: status,
        specReference: specReference,
        mockDatasetVersion: mockDatasetVersion,
        evidence: evidence,
        justification: justification,
        variantsInSpec: variantsInSpec,
        variantsCovered: variantsCovered,
        audit: audit,
        boundary: text(LedgerField.boundary),
        threshold: text(LedgerField.threshold),
      ),
      refusal: null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CandidateLedgerEntry &&
      jsonEncode(toJson()) == jsonEncode(other.toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

// candidate_ledger.dart — the append-only record of every candidate
//
// The ledger holds no file I/O: it validates entries and reads and writes JSON
// lines, and the consumer decides where the lines are kept. An entry that
// breaks a rule is refused with a named reason and leaves the ledger as it was.

import 'dart:collection';
import 'dart:convert';

import 'candidate_ledger_entry.dart';
import 'candidate_status.dart';
import 'confidence.dart';

/// What reading JSON lines produced: the ledger of the accepted lines, and the
/// refusal for each line that was not accepted.
typedef LedgerParse = ({
  CandidateLedger ledger,
  List<({int line, LedgerRefusal refusal})> refusals,
});

/// An append-only record of candidates, each moving through [CandidateStatus].
class CandidateLedger {
  /// An empty ledger that computes confidence under [weights].
  CandidateLedger({this.weights = ConfidenceWeights.initial});

  /// The weights confidence is computed with.
  final ConfidenceWeights weights;

  final List<CandidateLedgerEntry> _entries = [];

  /// The confidence of each of [candidateId]'s entries that carries factors,
  /// oldest first.
  List<double> confidenceSeries(String candidateId) => [
        for (final entry in _entries)
          if (entry.candidateId == candidateId)
            if (entry.confidenceUnder(weights) case final confidence?) confidence,
      ];

  /// Where [candidateId]'s confidence is heading.
  ConfidenceTrend trendOf(String candidateId) =>
      ConfidenceTrend.of(confidenceSeries(candidateId));

  /// The candidates whose confidence has stalled or dropped, in the order they
  /// first appear.
  List<String> get flagged => [
        for (final id in {for (final e in _entries) e.candidateId})
          if (trendOf(id).isFlagged) id,
      ];

  /// Every accepted entry, oldest first. It cannot be changed.
  List<CandidateLedgerEntry> get entries => UnmodifiableListView(_entries);

  /// The last status recorded for [candidateId]; null if it has none.
  CandidateStatus? statusOf(String candidateId) {
    for (final entry in _entries.reversed) {
      if (entry.candidateId == candidateId) return entry.status;
    }
    return null;
  }

  /// Why [entry] would be refused, or null if it would be accepted.
  LedgerRefusal? refusalFor(CandidateLedgerEntry entry) {
    final last = statusOf(entry.candidateId);
    if (last == null) {
      if (entry.status != CandidateStatus.candidate) {
        return LedgerRefusal.firstStatusNotCandidate;
      }
    } else if (!last.canMoveTo(entry.status)) {
      return LedgerRefusal.illegalMove;
    }
    if (!entry.variantsCovered.every(entry.variantsInSpec.contains)) {
      return LedgerRefusal.coversVariantOutsideSpec;
    }
    if (entry.status.requiresEvidence && entry.evidence.isEmpty) {
      return LedgerRefusal.noEvidence;
    }
    if (entry.status.requiresPassedAudit && !entry.audit.isPassed) {
      return LedgerRefusal.auditNotPassed;
    }
    if (entry.status.requiresFullVariantCoverage &&
        !entry.variantsInSpec.every(entry.variantsCovered.contains)) {
      return LedgerRefusal.variantsMissing;
    }
    final factors = entry.factors;
    if (entry.status.requiresFactors && factors == null) {
      return LedgerRefusal.factorsMissing;
    }
    if (factors != null && !factors.isInRange) {
      return LedgerRefusal.factorOutOfRange;
    }
    if (entry.status.requiresJustifiedThreshold) {
      if (entry.justification.trim().isEmpty) {
        return LedgerRefusal.axiomWithoutJustification;
      }
      final threshold = entry.threshold;
      if (threshold == null) return LedgerRefusal.axiomWithoutThreshold;
      if (threshold < 0 || threshold > 1) {
        return LedgerRefusal.thresholdOutOfRange;
      }
      if (entry.confidenceUnder(weights)! < threshold) {
        return LedgerRefusal.confidenceBelowThreshold;
      }
    }
    return null;
  }

  /// Adds [entry] if no rule refuses it. Returns the refusal, or null when it
  /// was accepted.
  LedgerRefusal? append(CandidateLedgerEntry entry) {
    final refusal = refusalFor(entry);
    if (refusal == null) _entries.add(entry);
    return refusal;
  }

  /// One entry as one JSON line, without the newline.
  static String encode(CandidateLedgerEntry entry) => jsonEncode(entry.toJson());

  /// Every entry as JSON lines, each ending in a newline.
  String toJsonLines() => [for (final e in _entries) '${encode(e)}\n'].join();

  /// Reads JSON lines through the same rules as [append]. Blank lines are
  /// skipped; a refused line is reported with its 1-based number.
  static LedgerParse parse(
    String text, {
    ConfidenceWeights weights = ConfidenceWeights.initial,
  }) {
    final ledger = CandidateLedger(weights: weights);
    final refusals = <({int line, LedgerRefusal refusal})>[];
    final lines = const LineSplitter().convert(text);
    for (var index = 0; index < lines.length; index++) {
      if (lines[index].trim().isEmpty) continue;
      final line = index + 1;
      final LedgerRefusal? refusal;
      try {
        final decoded = jsonDecode(lines[index]);
        if (decoded is! Map<String, Object?>) {
          refusal = LedgerRefusal.malformedEntry;
        } else {
          final parsed = CandidateLedgerEntry.tryParse(decoded);
          refusal = parsed.refusal ?? ledger.append(parsed.entry!);
        }
      } on FormatException {
        refusals.add((line: line, refusal: LedgerRefusal.malformedEntry));
        continue;
      }
      if (refusal != null) refusals.add((line: line, refusal: refusal));
    }
    return (ledger: ledger, refusals: refusals);
  }
}

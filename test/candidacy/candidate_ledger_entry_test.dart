// candidate_ledger_entry_test.dart — an entry is one line of the ledger; it
// round trips through JSON, and a line that is not an entry is refused with a
// typed reason instead of being defaulted

import 'dart:convert';

import 'package:dartrix/dartrix.dart';
import 'package:test/test.dart';

import 'candidacy_stubs.dart';

void main() {
  group('CandidateLedgerEntry', () {
    final entry = validEntry(CandidateStatus.axiom, boundary: 'depth 3');

    test('writes exactly the fields the ledger names, for an axiom', () {
      expect(entry.toJson().keys.toSet(), LedgerField.values.map((f) => f.name).toSet());
    });

    test('leaves out the optional fields it does not have', () {
      final json = validEntry(CandidateStatus.underTest).toJson();
      expect(json.keys.toSet(), {
        for (final field in LedgerField.values)
          if (field.isRequired) field.name,
      });
    });

    test('round trips through JSON', () {
      final parsed = CandidateLedgerEntry.tryParse(
        jsonDecode(jsonEncode(entry.toJson())) as Map<String, Object?>,
      );
      expect(parsed.entry, entry);
    });

    test('round trips without the optional fields', () {
      final bare = validEntry(CandidateStatus.underTest);
      expect(CandidateLedgerEntry.tryParse(bare.toJson()).entry, bare);
    });

    group('an optional field of the wrong type is refused as malformed', () {
      for (final field in LedgerField.values.where((f) => !f.isRequired)) {
        test(field.name, () {
          final json = entry.toJson()..[field.name] = 42;
          expect(CandidateLedgerEntry.tryParse(json).refusal,
              LedgerRefusal.malformedEntry);
        });
      }
    });

    test('a parsed entry refuses nothing', () {
      expect(
        CandidateLedgerEntry.tryParse(entry.toJson()).refusal,
        isNull,
      );
    });

    group('a missing required field is refused as malformed', () {
      for (final field in LedgerField.values.where((f) => f.isRequired)) {
        test(field.name, () {
          final json = entry.toJson()..remove(field.name);
          final parsed = CandidateLedgerEntry.tryParse(json);
          expect((parsed.entry, parsed.refusal),
              (null, LedgerRefusal.malformedEntry));
        });
      }
    });

    group('a field of the wrong type is refused as malformed', () {
      for (final field in LedgerField.values.where((f) => f.isRequired)) {
        test(field.name, () {
          final json = entry.toJson()..[field.name] = 42;
          final parsed = CandidateLedgerEntry.tryParse(json);
          expect(parsed.refusal, LedgerRefusal.malformedEntry);
        });
      }
    });

    test('an unknown status name is refused as unknownStatus, not defaulted', () {
      final json = entry.toJson()..[LedgerField.status.name] = 'almostProven';
      expect(CandidateLedgerEntry.tryParse(json).refusal,
          LedgerRefusal.unknownStatus);
    });

    test('an unknown audit check is refused as malformed', () {
      final json = entry.toJson()
        ..[LedgerField.audit.name] = {'noSuchCheck': 'passed'};
      expect(CandidateLedgerEntry.tryParse(json).refusal,
          LedgerRefusal.malformedEntry);
    });

    test('entries with the same facts are equal', () {
      expect(validEntry(CandidateStatus.proven),
          validEntry(CandidateStatus.proven));
    });

    test('entries that differ in one fact are not equal', () {
      expect(validEntry(CandidateStatus.proven),
          isNot(validEntry(CandidateStatus.proven, justification: 'other')));
    });
  });
}

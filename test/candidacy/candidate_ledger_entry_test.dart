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
      const badValue = {
        LedgerField.boundary: 42,
        LedgerField.threshold: 'high',
        LedgerField.factors: 42,
      };
      for (final field in LedgerField.values.where((f) => !f.isRequired)) {
        test(field.name, () {
          final json = entry.toJson()..[field.name] = badValue[field];
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

    group('the confidence factors', () {
      test('round trip through JSON', () {
        const factors =
            ConfidenceFactors(boundary: 0.25, topologyReach: 0.5, impact: 0.75);
        final withFactors = validEntry(CandidateStatus.underTest, factors: factors);
        final parsed = CandidateLedgerEntry.tryParse(withFactors.toJson()).entry;
        expect(parsed!.factors!.toJson(), factors.toJson());
      });

      for (final field in FactorField.values) {
        test('${field.name} that is not a number is malformed', () {
          final json = _withFactorField(field, 'high');
          expect(CandidateLedgerEntry.tryParse(json).refusal,
              LedgerRefusal.malformedEntry);
        });

        test('${field.name} missing is malformed', () {
          final json = _withFactorField(field, null);
          expect(CandidateLedgerEntry.tryParse(json).refusal,
              LedgerRefusal.malformedEntry);
        });
      }

      test('an integer is read as the number it is', () {
        final json = _withFactorField(FactorField.impact, 1);
        expect(CandidateLedgerEntry.tryParse(json).entry!.factors!.impact, 1.0);
      });

      test('the threshold of an axiom round trips as a number', () {
        final axiom = validEntry(CandidateStatus.axiom, threshold: 0.9);
        expect(CandidateLedgerEntry.tryParse(axiom.toJson()).entry!.threshold, 0.9);
      });

      test('an entry has no confidence without factors', () {
        expect(validEntry(CandidateStatus.underTest).confidenceUnder(ConfidenceWeights.initial),
            isNull);
      });

      test('an entry confidence counts the derived coverage', () {
        // half the spec covered: 0.4*0.5 + 0.2*1 + 0.2*1 + 0.2*1
        final entry = validEntry(CandidateStatus.bounded,
            variantsCovered: const ['alpha']);
        expect(entry.confidenceUnder(ConfidenceWeights.initial), closeTo(0.8, 1e-9));
      });
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

/// A proven entry's JSON with one factor replaced by [value], or removed if null.
Map<String, Object?> _withFactorField(FactorField field, Object? value) {
  final json = validEntry(CandidateStatus.proven).toJson();
  final factors = Map<String, Object?>.of(
      (json[LedgerField.factors.name]! as Map).cast<String, Object?>());
  if (value == null) {
    factors.remove(field.name);
  } else {
    factors[field.name] = value;
  }
  json[LedgerField.factors.name] = factors;
  return json;
}

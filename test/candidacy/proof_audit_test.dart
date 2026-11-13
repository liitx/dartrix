// proof_audit_test.dart — Phase 0: a proof is only as valid as the mocks under
// it, so every check must have passed before a candidate is proven or bounded

import 'package:dartrix/dartrix.dart';
import 'package:test/test.dart';

import 'candidacy_stubs.dart';

void main() {
  group('ProofAudit', () {
    test('an audit with no outcomes has every check unmet', () {
      expect(ProofAudit.notRun().unmet, ProofAuditCheck.values);
    });

    test('an audit with no outcomes has not passed', () {
      expect(ProofAudit.notRun().isPassed, isFalse);
    });

    test('an audit with every check passed has passed', () {
      expect(passedAudit().isPassed, isTrue);
    });

    test('an audit with every check passed has nothing unmet', () {
      expect(passedAudit().unmet, isEmpty);
    });

    group('one check not passed', () {
      for (final check in ProofAuditCheck.values) {
        for (final outcome in ProofAuditOutcome.values) {
          if (outcome == ProofAuditOutcome.passed) continue;
          final audit = ProofAudit({
            for (final other in ProofAuditCheck.values)
              other: other == check ? outcome : ProofAuditOutcome.passed,
          });
          test('${check.name} ${outcome.name} leaves the audit not passed', () {
            expect(audit.isPassed, isFalse);
          });
          test('${check.name} ${outcome.name} is the only unmet check', () {
            expect(audit.unmet, [check]);
          });
        }
      }
    });

    test('a check with no recorded outcome counts as not checked', () {
      final audit = ProofAudit({
        for (final check in ProofAuditCheck.values.skip(1))
          check: ProofAuditOutcome.passed,
      });
      expect(audit.outcomeOf(ProofAuditCheck.values.first),
          ProofAuditOutcome.notChecked);
    });

    group('json', () {
      test('round trips', () {
        final audit = ProofAudit({
          ProofAuditCheck.mocksMatchSpec: ProofAuditOutcome.passed,
          ProofAuditCheck.everyTestCanFail: ProofAuditOutcome.failed,
        });
        expect(ProofAudit.tryFromJson(audit.toJson())!.toJson(), audit.toJson());
      });

      test('an unknown check name is refused', () {
        expect(ProofAudit.tryFromJson({'noSuchCheck': 'passed'}), isNull);
      });

      test('an unknown outcome name is refused', () {
        expect(
            ProofAudit.tryFromJson({ProofAuditCheck.mocksMatchSpec.name: 'maybe'}),
            isNull);
      });
    });
  });
}

// shoelace_snapshot_test.dart — ShoelaceSnapshot parser covers v1/v2/v3.

import 'dart:convert';

import 'package:dartrix/dartrix.dart';
import 'package:test/test.dart';

void main() {
  group('ShoelaceSchema.fromString', () {
    test('recognizes known schema strings', () {
      expect(ShoelaceSchema.fromString('zedup-shoelace/v1'),
          equals(ShoelaceSchema.v1));
      expect(ShoelaceSchema.fromString('zedup-shoelace/v2'),
          equals(ShoelaceSchema.v2));
      expect(ShoelaceSchema.fromString('zedup-shoelace/v3'),
          equals(ShoelaceSchema.v3));
    });

    test('returns unknown for missing or unrecognized strings', () {
      expect(ShoelaceSchema.fromString(null), equals(ShoelaceSchema.unknown));
      expect(ShoelaceSchema.fromString('something-else'),
          equals(ShoelaceSchema.unknown));
    });

    test('v3 supportsTestStatus', () {
      expect(ShoelaceSchema.v3.supportsTestStatus, isTrue);
      expect(ShoelaceSchema.v2.supportsTestStatus, isFalse);
    });
  });

  group('SnapshotTestPoint v3 parsing', () {
    test('reads status, failureMessage, logPath, failureType', () {
      final p = SnapshotTestPoint.fromJson({
        'variant': 'BranchType.feat',
        'feature': 'newBranch',
        'file': 'test/features/branch/x.dart',
        'line': 42,
        'status': 'failing',
        'failureMessage': 'expected feat got fix',
        'logPath': '/tmp/test-log.txt',
        'failureType': 'gitCheckoutFailed',
      });
      expect(p.status, equals('failing'));
      expect(p.isFailing, isTrue);
      expect(p.isPassing, isFalse);
      expect(p.failureMessage, equals('expected feat got fix'));
      expect(p.logPath, equals('/tmp/test-log.txt'));
      expect(p.failureType, equals('gitCheckoutFailed'));
    });

    test('defaults v3 fields when reading v2-style records', () {
      final p = SnapshotTestPoint.fromJson({
        'variant': 'BranchType.feat',
        'feature': 'newBranch',
        'file': 'x.dart',
        'line': 1,
        'containingGroup': 'rendering',
      });
      expect(p.status, equals('unknown'));
      expect(p.failureMessage, isNull);
      expect(p.logPath, isNull);
      expect(p.failureType, isNull);
      expect(p.isFailing, isFalse);
      expect(p.isPassing, isFalse);
    });

    test('error status counts as failing for aggregate worst-state-wins', () {
      final p = SnapshotTestPoint.fromJson({
        'variant': 'X.a',
        'feature': 'f',
        'file': 'x.dart',
        'line': 1,
        'status': 'error',
      });
      expect(p.isFailing, isTrue);
    });
  });

  group('ShoelaceSnapshot.parse', () {
    String writeV3({required List<Map<String, dynamic>> tests}) {
      return jsonEncode({
        'schema': 'zedup-shoelace/v3',
        'generatedAt': '2026-05-15T12:00:00Z',
        'variants': [],
        'features': ['newBranch', 'promote'],
        'gaps': [
          {'variant': 'BranchType.chore', 'feature': 'promote'},
        ],
        'tests': tests,
        'usages': [],
      });
    }

    test('parses a v3 snapshot with typed fields', () {
      final json = writeV3(tests: [
        {
          'variant': 'BranchType.feat',
          'feature': 'newBranch',
          'file': 'x.dart',
          'line': 1,
          'status': 'passing',
        },
        {
          'variant': 'BranchType.feat',
          'feature': 'promote',
          'file': 'y.dart',
          'line': 2,
          'status': 'failing',
          'failureType': 'gitPushFailed',
        },
      ]);
      final snap = ShoelaceSnapshot.parse(json);
      expect(snap.schema, equals(ShoelaceSchema.v3));
      expect(snap.tests.length, equals(2));
      expect(snap.tests[1].failureType, equals('gitPushFailed'));
      expect(snap.gaps.length, equals(1));
      expect(snap.features, equals(['newBranch', 'promote']));
    });

    test('tolerates missing top-level keys', () {
      final json = jsonEncode({'schema': 'zedup-shoelace/v3'});
      final snap = ShoelaceSnapshot.parse(json);
      expect(snap.tests, isEmpty);
      expect(snap.gaps, isEmpty);
      expect(snap.usages, isEmpty);
      expect(snap.features, isEmpty);
    });

    test('throws FormatException for non-object JSON', () {
      expect(() => ShoelaceSnapshot.parse('"not an object"'),
          throwsA(isA<FormatException>()));
    });

    test('reads v2 snapshot without throwing — defaults v3 fields', () {
      final json = jsonEncode({
        'schema': 'zedup-shoelace/v2',
        'generatedAt': '2026-05-06T12:00:00Z',
        'variants': [],
        'features': ['newBranch'],
        'gaps': [],
        'tests': [
          {
            'variant': 'BranchType.feat',
            'feature': 'newBranch',
            'file': 'x.dart',
            'line': 1,
            // no status field — pre-v3 schema
          }
        ],
        'usages': [],
      });
      final snap = ShoelaceSnapshot.parse(json);
      expect(snap.schema, equals(ShoelaceSchema.v2));
      expect(snap.tests.first.status, equals('unknown'));
    });
  });

  group('ShoelaceSnapshot.aggregateStateFor — worst-state-wins', () {
    test('returns missing when no tests exist for the (variant, feature) pair', () {
      final snap = ShoelaceSnapshot.parse(jsonEncode({'schema': 'zedup-shoelace/v3'}));
      expect(snap.aggregateStateFor('X.a', 'f'), equals('missing'));
    });

    test('returns failing if any test for the pair is failing', () {
      final json = jsonEncode({
        'schema': 'zedup-shoelace/v3',
        'tests': [
          {'variant': 'X.a', 'feature': 'f', 'file': 'x.dart', 'line': 1, 'status': 'passing'},
          {'variant': 'X.a', 'feature': 'f', 'file': 'y.dart', 'line': 2, 'status': 'failing'},
        ],
      });
      final snap = ShoelaceSnapshot.parse(json);
      expect(snap.aggregateStateFor('X.a', 'f'), equals('failing'));
    });

    test('returns passing when all tests for the pair pass', () {
      final json = jsonEncode({
        'schema': 'zedup-shoelace/v3',
        'tests': [
          {'variant': 'X.a', 'feature': 'f', 'file': 'x.dart', 'line': 1, 'status': 'passing'},
          {'variant': 'X.a', 'feature': 'f', 'file': 'y.dart', 'line': 2, 'status': 'passing'},
        ],
      });
      final snap = ShoelaceSnapshot.parse(json);
      expect(snap.aggregateStateFor('X.a', 'f'), equals('passing'));
    });

    test('returns unknown when tests exist but none have captured outcomes', () {
      final json = jsonEncode({
        'schema': 'zedup-shoelace/v3',
        'tests': [
          {'variant': 'X.a', 'feature': 'f', 'file': 'x.dart', 'line': 1, 'status': 'unknown'},
        ],
      });
      final snap = ShoelaceSnapshot.parse(json);
      expect(snap.aggregateStateFor('X.a', 'f'), equals('unknown'));
    });
  });
}

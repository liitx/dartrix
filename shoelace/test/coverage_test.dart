// coverage_test.dart — schema round-trip against a real zedup-written file.

import 'dart:convert';
import 'dart:io';

import 'package:dartrix_shoelace/src/coverage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoverageSnapshot.fromJson — schema parsing', () {
    test('parses the v1 schema', () {
      final snapshot = CoverageSnapshot.fromJson(_minimalV1());
      expect(snapshot.schema, equals(CoverageSchema.v1));
    });

    test('rejects an unknown schema', () {
      final json = _minimalV1()..['schema'] = 'unknown';
      expect(() => CoverageSnapshot.fromJson(json), throwsFormatException);
    });

    test('decodes hex colors', () {
      final snapshot = CoverageSnapshot.fromJson(_minimalV1());
      expect(snapshot.variants.single.color.r, closeTo(0xff / 255, 1e-3));
      expect(snapshot.variants.single.color.g, closeTo(0x00 / 255, 1e-3));
      expect(snapshot.variants.single.color.b, closeTo(0x00 / 255, 1e-3));
    });

    test('rejects malformed hex colors', () {
      final json = _minimalV1();
      (json['variants'] as List).first['color'] = '#xyz';
      expect(() => CoverageSnapshot.fromJson(json), throwsFormatException);
    });
  });

  group('SegmentStatus.forCoverage', () {
    test('1.0 → covered', () {
      expect(
        SegmentStatus.forCoverage(1.0),
        equals(SegmentStatus.covered),
      );
    });

    test('partial coverage → gap', () {
      expect(
        SegmentStatus.forCoverage(0.5),
        equals(SegmentStatus.gap),
      );
    });

    test('zero coverage → gap', () {
      expect(
        SegmentStatus.forCoverage(0.0),
        equals(SegmentStatus.gap),
      );
    });
  });

  group('integration with a zedup-written file', () {
    test('parses ~/.zedup/shoelace-coverage.json when present', () {
      final path =
          '${Platform.environment['HOME']}/.zedup/shoelace-coverage.json';
      final file = File(path);
      if (!file.existsSync()) {
        return; // skip — no zedup-written file in this env
      }
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final snapshot = CoverageSnapshot.fromJson(json);
      expect(
        snapshot.schema,
        anyOf(equals(CoverageSchema.v1), equals(CoverageSchema.v2)),
      );
      expect(snapshot.variants, isNotEmpty);
      expect(snapshot.averageCoverage, isA<double>());
    });
  });

  group('CoverageSnapshot.fromJson — v2 schema', () {
    test('parses the v2 schema', () {
      final snapshot = CoverageSnapshot.fromJson(_minimalV2());
      expect(snapshot.schema, equals(CoverageSchema.v2));
    });

    test('reads containingGroup on tests when present', () {
      final snapshot = CoverageSnapshot.fromJson(_minimalV2());
      expect(
        snapshot.tests.single.containingGroup,
        equals('WorkStatus / rendering'),
      );
    });

    test('reads containingClass and containingMethod on usages when present', () {
      final snapshot = CoverageSnapshot.fromJson(_minimalV2());
      expect(snapshot.usages.single.containingClass, equals('BranchTile'));
      expect(snapshot.usages.single.containingMethod, equals('_statusBadge'));
    });

    test('v2 payload missing scope fields parses with nulls (field-tolerant)', () {
      final json = _minimalV2();
      (json['tests'] as List).first.remove('containingGroup');
      (json['usages'] as List).first.remove('containingClass');
      (json['usages'] as List).first.remove('containingMethod');
      final snapshot = CoverageSnapshot.fromJson(json);
      expect(snapshot.tests.single.containingGroup, isNull);
      expect(snapshot.usages.single.containingClass, isNull);
      expect(snapshot.usages.single.containingMethod, isNull);
    });

    test('v1 payload still parses with null scope fields', () {
      final snapshot = CoverageSnapshot.fromJson(_minimalV1WithEntries());
      expect(snapshot.schema, equals(CoverageSchema.v1));
      expect(snapshot.tests.single.containingGroup, isNull);
      expect(snapshot.usages.single.containingClass, isNull);
      expect(snapshot.usages.single.containingMethod, isNull);
    });
  });
}

Map<String, dynamic> _minimalV1() => {
      'schema': 'zedup-shoelace/v1',
      'generatedAt': '2026-05-04T00:00:00.000',
      'variants': [
        {
          'name': 'a',
          'type': 'TestType',
          'color': '#ff0000',
          'features': ['feat'],
          'coverageRatio': 0.5,
        },
      ],
      'features': ['feat'],
      'gaps': [
        {'variant': 'TestType.a', 'feature': 'feat'},
      ],
      'tests': const <Map<String, dynamic>>[],
      'usages': const <Map<String, dynamic>>[],
    };

Map<String, dynamic> _minimalV1WithEntries() => {
      ..._minimalV1(),
      'schema': 'zedup-shoelace/v1',
      'tests': [
        {
          'variant': 'TestType.a',
          'feature': 'feat',
          'file': 'test/foo_test.dart',
          'line': 10,
        },
      ],
      'usages': [
        {
          'variant': 'TestType.a',
          'file': 'lib/foo.dart',
          'line': 20,
        },
      ],
    };

Map<String, dynamic> _minimalV2() => {
      'schema': 'zedup-shoelace/v2',
      'generatedAt': '2026-05-06T00:00:00.000',
      'variants': [
        {
          'name': 'inReview',
          'type': 'WorkStatus',
          'color': '#3366ff',
          'features': ['dashboard'],
          'coverageRatio': 0.0,
        },
      ],
      'features': ['dashboard'],
      'gaps': [
        {'variant': 'WorkStatus.inReview', 'feature': 'dashboard'},
      ],
      'tests': [
        {
          'variant': 'WorkStatus.inReview',
          'feature': 'dashboard',
          'file': 'test/features/dashboard/zedup_dashboard_test.dart',
          'line': 142,
          'containingGroup': 'WorkStatus / rendering',
        },
      ],
      'usages': [
        {
          'variant': 'WorkStatus.inReview',
          'file': 'lib/src/features/dashboard/zedup_dashboard.dart',
          'line': 87,
          'containingClass': 'BranchTile',
          'containingMethod': '_statusBadge',
        },
      ],
    };

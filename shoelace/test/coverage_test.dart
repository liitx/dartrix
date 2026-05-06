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
      expect(snapshot.schema, equals(CoverageSchema.v1));
      expect(snapshot.variants, isNotEmpty);
      expect(snapshot.averageCoverage, isA<double>());
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

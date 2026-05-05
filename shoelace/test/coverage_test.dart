// coverage_test.dart — schema round-trip against a real zedup-written file.

import 'dart:convert';
import 'dart:io';

import 'package:dartrix_shoelace/src/coverage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoverageData.fromJson — schema parsing', () {
    test('parses the v1 schema', () {
      final data = CoverageData.fromJson(_minimalV1());
      expect(data.schema, equals(CoverageSchema.v1));
    });

    test('rejects an unknown schema', () {
      final json = _minimalV1()..['schema'] = 'unknown';
      expect(() => CoverageData.fromJson(json), throwsFormatException);
    });

    test('decodes hex colors', () {
      final data = CoverageData.fromJson(_minimalV1());
      expect(data.variants.single.color.r, closeTo(0xff / 255, 1e-3));
      expect(data.variants.single.color.g, closeTo(0x00 / 255, 1e-3));
      expect(data.variants.single.color.b, closeTo(0x00 / 255, 1e-3));
    });

    test('rejects malformed hex colors', () {
      final json = _minimalV1();
      (json['variants'] as List).first['color'] = '#xyz';
      expect(() => CoverageData.fromJson(json), throwsFormatException);
    });
  });

  group('SegmentStatus.fromRatios', () {
    test('both fully covered → tested', () {
      expect(
        SegmentStatus.fromRatios(1.0, 1.0),
        equals(SegmentStatus.tested),
      );
    });

    test('one ratio less than 1.0 → gap', () {
      expect(
        SegmentStatus.fromRatios(0.5, 1.0),
        equals(SegmentStatus.gap),
      );
    });

    test('zero ratios → gap', () {
      expect(
        SegmentStatus.fromRatios(0.0, 0.0),
        equals(SegmentStatus.gap),
      );
    });

    test('FROM 100% with TO 0% → tested (chord owned by FROM)', () {
      expect(
        SegmentStatus.fromRatios(1.0, 0.0),
        equals(SegmentStatus.tested),
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
      final data = CoverageData.fromJson(json);
      expect(data.schema, equals(CoverageSchema.v1));
      expect(data.variants, isNotEmpty);
      expect(data.coverageRatio, isA<double>());
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

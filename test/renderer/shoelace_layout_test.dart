// shoelace_layout_test.dart — coverage for the shoelace primitive
//
// Three planes verified independently:
//   - Lace path geometry (visit order via segment fromIndex/toIndex).
//   - Per-node coverage ratio (covered / participating).
//   - Per-segment lit logic (both endpoints fully covered).
//
// Discipline: loop wraps `test()`; never one test() with a loop body.
// Adding an enum variant here forces the fixture switch to update —
// compile error on omission.

import 'dart:math' as math;

import 'package:dartrix/dartrix.dart';
import 'package:test/test.dart';

import '../stubs.dart';

/// Eight-variant fixture for testing larger lace paths.
enum BigType implements AppType {
  a,
  b,
  c,
  d,
  e,
  f,
  g,
  h;

  @override
  String get description => name;

  @override
  Set<FeatureType> get features => switch (this) {
        BigType.a => {TestFeature.alpha},
        BigType.b => {TestFeature.alpha},
        BigType.c => {TestFeature.alpha},
        BigType.d => {TestFeature.alpha},
        BigType.e => {TestFeature.alpha},
        BigType.f => {TestFeature.alpha},
        BigType.g => {TestFeature.alpha},
        BigType.h => {TestFeature.alpha},
      };
}

/// Expected lace path for a given N, computed from the canonical
/// `0 → N-1 → 1 → N-2 → ...` rule. Used to assert segment fromIndex/toIndex.
List<int> _expectedPath(int n) {
  final p = <int>[];
  var lo = 0;
  var hi = n - 1;
  while (lo <= hi) {
    if (p.length.isEven) {
      p.add(lo);
      lo++;
    } else {
      p.add(hi);
      hi--;
    }
  }
  return p;
}

void main() {
  // ── Lace path via segments ──────────────────────────────────────────────────
  group('lace path', () {
    final matrix = Dartrix(axes: [BigType.values], features: [TestFeature.alpha]);

    for (final n in [2, 3, 4, 5, 6, 7, 8]) {
      test('N=$n produces N-1 segments visiting the expected path', () {
        final variants = BigType.values.take(n).toList();
        final layout = shoelaceLayoutOf(matrix, variants);
        final path = _expectedPath(n);

        expect(layout.segments.length, equals(n - 1));
        for (var step = 0; step < n - 1; step++) {
          expect(layout.segments[step].fromIndex, equals(path[step]));
          expect(layout.segments[step].toIndex, equals(path[step + 1]));
          expect(layout.segments[step].step, equals(step));
        }
      });
    }

    test('N=7 path is exactly [0, 6, 1, 5, 2, 4, 3]', () {
      final layout = shoelaceLayoutOf(matrix, BigType.values.take(7).toList());
      final visited = <int>[
        layout.segments.first.fromIndex,
        for (final s in layout.segments) s.toIndex,
      ];
      expect(visited, equals([0, 6, 1, 5, 2, 4, 3]));
    });
  });

  // ── Degenerate sizes ────────────────────────────────────────────────────────
  group('degenerate sizes', () {
    final matrix = Dartrix(axes: [TestType.values], features: TestFeature.values);

    test('N=0 returns empty nodes and empty segments', () {
      final layout = shoelaceLayoutOf(matrix, const <AppType>[]);
      expect(layout.nodes, isEmpty);
      expect(layout.segments, isEmpty);
    });

    test('N=1 returns one node and zero segments', () {
      final layout = shoelaceLayoutOf(matrix, [TestType.rover]);
      expect(layout.nodes.length, equals(1));
      expect(layout.segments, isEmpty);
    });

    test('N=2 returns two nodes and one segment', () {
      final layout = shoelaceLayoutOf(matrix, TestType.values);
      expect(layout.nodes.length, equals(2));
      expect(layout.segments.length, equals(1));
      expect(layout.segments.single.fromIndex, equals(0));
      expect(layout.segments.single.toIndex, equals(1));
      expect(layout.segments.single.step, equals(0));
    });
  });

  // ── Node placement ──────────────────────────────────────────────────────────
  group('node placement', () {
    final matrix = Dartrix(axes: [BigType.values], features: [TestFeature.alpha]);
    final layout = shoelaceLayoutOf(matrix, BigType.values.take(4).toList());

    for (var i = 0; i < 4; i++) {
      test('node[$i] angle is 2π·$i/4', () {
        expect(layout.nodes[i].angle, closeTo(2 * math.pi * i / 4, 1e-9));
      });
    }

    test('node count equals variant count', () {
      expect(layout.nodes.length, equals(4));
    });

    for (var i = 0; i < 4; i++) {
      test('node[$i].variant matches variants[$i]', () {
        expect(layout.nodes[i].variant, equals(BigType.values[i]));
      });
    }
  });

  // ── Coverage ratio ──────────────────────────────────────────────────────────
  group('coverage ratio', () {
    test('rover with 0 features covered → ratio 0.0', () {
      final m = Dartrix(axes: [TestType.values], features: TestFeature.values);
      final layout = shoelaceLayoutOf(m, [TestType.rover]);
      expect(layout.nodes.single.coverageRatio, equals(0.0));
    });

    test('rover with 1 of 1 feature covered → ratio 1.0', () {
      final m = Dartrix(axes: [TestType.values], features: TestFeature.values)
        ..cover(TestType.rover, TestFeature.alpha);
      final layout = shoelaceLayoutOf(m, [TestType.rover]);
      expect(layout.nodes.single.coverageRatio, equals(1.0));
    });

    test('buster with 0 of 2 features covered → ratio 0.0', () {
      final m = Dartrix(axes: [TestType.values], features: TestFeature.values);
      final layout = shoelaceLayoutOf(m, [TestType.buster]);
      expect(layout.nodes.single.coverageRatio, equals(0.0));
    });

    test('buster with 1 of 2 features covered → ratio 0.5', () {
      final m = Dartrix(axes: [TestType.values], features: TestFeature.values)
        ..cover(TestType.buster, TestFeature.alpha);
      final layout = shoelaceLayoutOf(m, [TestType.buster]);
      expect(layout.nodes.single.coverageRatio, equals(0.5));
    });

    test('buster with 2 of 2 features covered → ratio 1.0', () {
      final m = Dartrix(axes: [TestType.values], features: TestFeature.values)
        ..cover(TestType.buster, TestFeature.alpha)
        ..cover(TestType.buster, TestFeature.beta);
      final layout = shoelaceLayoutOf(m, [TestType.buster]);
      expect(layout.nodes.single.coverageRatio, equals(1.0));
    });
  });

  // ── Segment lit logic ───────────────────────────────────────────────────────
  group('segment lit', () {
    test('both endpoints fully covered → lit', () {
      final m = Dartrix(axes: [TestType.values], features: TestFeature.values)
        ..cover(TestType.rover, TestFeature.alpha)
        ..cover(TestType.buster, TestFeature.alpha)
        ..cover(TestType.buster, TestFeature.beta);
      final layout = shoelaceLayoutOf(m, TestType.values);
      expect(layout.segments.single.isLit, isTrue);
    });

    test('one endpoint has gap → dashed', () {
      final m = Dartrix(axes: [TestType.values], features: TestFeature.values)
        ..cover(TestType.rover, TestFeature.alpha);
      // buster missing both alpha and beta coverage
      final layout = shoelaceLayoutOf(m, TestType.values);
      expect(layout.segments.single.isLit, isFalse);
    });

    test('both endpoints have gaps → dashed', () {
      final m = Dartrix(axes: [TestType.values], features: TestFeature.values);
      final layout = shoelaceLayoutOf(m, TestType.values);
      expect(layout.segments.single.isLit, isFalse);
    });

    test('partial coverage on one endpoint → dashed', () {
      final m = Dartrix(axes: [TestType.values], features: TestFeature.values)
        ..cover(TestType.rover, TestFeature.alpha)
        ..cover(TestType.buster, TestFeature.alpha);
      // buster.beta still uncovered
      final layout = shoelaceLayoutOf(m, TestType.values);
      expect(layout.segments.single.isLit, isFalse);
    });
  });

  // ── Variant selection ───────────────────────────────────────────────────────
  group('variant selection', () {
    test('different variant lists produce different node sets', () {
      final m = Dartrix(axes: [TestType.values, BigType.values],
          features: [TestFeature.alpha]);
      final t1 = shoelaceLayoutOf(m, TestType.values);
      final t2 = shoelaceLayoutOf(m, BigType.values);
      expect(t1.nodes.length, equals(2));
      expect(t2.nodes.length, equals(8));
      expect(t1.nodes.first.variant, equals(TestType.rover));
      expect(t2.nodes.first.variant, equals(BigType.a));
    });
  });
}

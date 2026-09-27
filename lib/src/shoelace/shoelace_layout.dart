// shoelace_layout.dart — pure-data shoelace coverage geometry
//
// Derives a fractal coverage visualization from a Dartrix matrix.
// Renderers (nocterm in zedup, HTML canvas, Flutter widgets) consume the
// layout and decide how to draw it. This file ships only data — no
// rendering, no Flutter, no state machine.
//
// Phase 1: variants laced into a continuous shoelace path; lit/dashed
// segments reflect coverage state. Drill-down (level 2+) lives in
// consumers per dartrix's "no runtime tracking" rule.

import 'dart:math' as math;

import '../matrix/matrix.dart';
import '../types/app_type.dart';

/// One variant placed on the unit circle.
final class ShoelaceNode {
  const ShoelaceNode({
    required this.variant,
    required this.angle,
    required this.coverageRatio,
  });

  /// The variant this node represents.
  final AppType variant;

  /// Position on the unit circle, radians, evenly distributed:
  /// `angle = 2π * i / N`. 0 = right (+x), counterclockwise.
  final double angle;

  /// Covered participating cells / total participating cells, in [0, 1].
  /// Vacuously 1.0 when the variant participates in zero features.
  final double coverageRatio;
}

/// One segment on the continuous shoelace path.
final class ShoelaceSegment {
  const ShoelaceSegment({
    required this.fromIndex,
    required this.toIndex,
    required this.step,
    required this.isLit,
  });

  /// Index into [ShoelaceLayout.nodes] of the lace's start.
  final int fromIndex;

  /// Index into [ShoelaceLayout.nodes] of the lace's end.
  final int toIndex;

  /// Position in the lace path, `0..N-2`. Renderers can color by step.
  final int step;

  /// True ↔ both endpoints have full coverage of every feature they
  /// declare in `AppType.features`.
  final bool isLit;
}

/// Pure-data shoelace layout — geometry plus coverage, no rendering.
final class ShoelaceLayout {
  const ShoelaceLayout({required this.nodes, required this.segments});

  /// One node per variant. `nodes.length == variants.length`.
  final List<ShoelaceNode> nodes;

  /// `nodes.length - 1` segments forming the continuous shoelace path
  /// `0 → N-1 → 1 → N-2 → 2 → N-3 → ...`. Empty when `nodes.length < 2`.
  final List<ShoelaceSegment> segments;
}

/// Builds a shoelace layout for the given variants against [matrix].
///
/// `matrix` provides coverage state via `stateOf`; `variants` chooses which
/// nodes to place on the circle. For multi-axis matrices, call once per
/// enum (e.g. `shoelaceLayoutOf(m, WorkStatus.values)`).
///
/// Lenient on degenerate sizes:
/// - N = 0 → empty layout
/// - N = 1 → one node, zero segments
/// - N = 2 → two nodes, one segment
ShoelaceLayout shoelaceLayoutOf(Dartrix matrix, List<AppType> variants) {
  final n = variants.length;

  final nodes = <ShoelaceNode>[
    for (var i = 0; i < n; i++)
      ShoelaceNode(
        variant: variants[i],
        angle: n == 0 ? 0 : 2 * math.pi * i / n,
        coverageRatio: _coverageRatioOf(matrix, variants[i]),
      ),
  ];

  final path = _lacePath(n);
  final segments = <ShoelaceSegment>[
    for (var step = 0; step < path.length - 1; step++)
      ShoelaceSegment(
        fromIndex: path[step],
        toIndex: path[step + 1],
        step: step,
        isLit: _isFullyCovered(matrix, variants[path[step]]) &&
            _isFullyCovered(matrix, variants[path[step + 1]]),
      ),
  ];

  return ShoelaceLayout(nodes: nodes, segments: segments);
}

/// Continuous shoelace visit order: `[0, N-1, 1, N-2, 2, N-3, ...]`.
/// The path crosses the circle, ending at the middle index.
///
/// ∀ n ≥ 0 → `_lacePath(n).length == n`. The `lo <= hi` invariant
/// produces exactly n entries before terminating.
List<int> _lacePath(int n) {
  final path = <int>[];
  var lo = 0;
  var hi = n - 1;
  while (lo <= hi) {
    if (path.length.isEven) {
      path.add(lo);
      lo++;
    } else {
      path.add(hi);
      hi--;
    }
  }
  return path;
}

/// Covered participating cells / total participating cells. Vacuously 1.0
/// when the variant participates in zero features (empty set).
double _coverageRatioOf(Dartrix matrix, AppType variant) {
  final participating = variant.features;
  if (participating.isEmpty) return 1;
  var covered = 0;
  for (final feature in participating) {
    if (matrix.stateOf(variant, feature) == CellState.covered) covered++;
  }
  return covered / participating.length;
}

/// True ↔ every feature in `variant.features` has `CellState.covered`.
/// Vacuously true for a variant with zero participating features.
bool _isFullyCovered(Dartrix matrix, AppType variant) {
  for (final feature in variant.features) {
    if (matrix.stateOf(variant, feature) != CellState.covered) return false;
  }
  return true;
}

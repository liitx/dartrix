// lace_path.dart — pure-Dart geometry for the shoelace visual.
//
// No Flutter imports — just Offset-free math you can unit-test in seconds.
// The painter consumes these to draw vertex positions and segment chords.

import 'dart:math' as math;

/// Continuous shoelace visit order: `[0, N-1, 1, N-2, 2, N-3, ...]`. The
/// path crosses the circle each step, ending at the middle index.
///
/// ∀ n ≥ 0 → `lacePath(n).length == n`
///   — the `lo <= hi` invariant produces exactly n entries.
List<int> lacePath(int n) {
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

/// Polar angle of vertex `i` of `n`, evenly distributed on the unit circle
/// counter-clockwise from `(1, 0)`. `angle = 2π · i / n`.
double vertexAngle(int i, int n) {
  if (n <= 0) return 0;
  return 2 * math.pi * i / n;
}

/// Cartesian position of a vertex on a circle of radius [radius] centered
/// at ([centerX], [centerY]). Y is flipped because canvas Y grows downward.
({double x, double y}) vertexPosition({
  required double angle,
  required double centerX,
  required double centerY,
  required double radius,
}) {
  return (
    x: centerX + radius * math.cos(angle),
    y: centerY - radius * math.sin(angle),
  );
}

/// One drawable segment of the shoelace path, by node index pair + step.
final class LaceSegment {
  const LaceSegment({
    required this.fromIndex,
    required this.toIndex,
    required this.step,
  });

  final int fromIndex;
  final int toIndex;
  final int step;
}

/// Builds the `n - 1` ordered lace segments from the shoelace visit order.
List<LaceSegment> laceSegments(int n) {
  final path = lacePath(n);
  return [
    for (var step = 0; step < path.length - 1; step++)
      LaceSegment(
        fromIndex: path[step],
        toIndex: path[step + 1],
        step: step,
      ),
  ];
}

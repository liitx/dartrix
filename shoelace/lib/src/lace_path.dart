// lace_path.dart — pure-Dart geometry for the shoelace visual.
//
// No Flutter imports — just Offset-free math you can unit-test in seconds.
// The painter consumes these to compute vertex positions and segment chords.

import 'dart:math' as math;

/// Continuous shoelace visit order: `[0, N-1, 1, N-2, 2, N-3, ...]`. The
/// path crosses the circle each step, ending at the middle index.
///
/// ∀ vertexCount ≥ 0 → `lacePath(vertexCount).length == vertexCount`
///   — the `low <= high` invariant produces exactly that many entries.
List<int> lacePath(int vertexCount) {
  final path = <int>[];
  var low = 0;
  var high = vertexCount - 1;
  while (low <= high) {
    if (path.length.isEven) {
      path.add(low);
      low++;
    } else {
      path.add(high);
      high--;
    }
  }
  return path;
}

/// Polar angle of vertex [vertexIndex] of [vertexCount], evenly distributed
/// on the unit circle counter-clockwise from `(1, 0)`.
/// Formula: `2π · vertexIndex / vertexCount`.
double vertexAngle(int vertexIndex, int vertexCount) {
  if (vertexCount <= 0) return 0;
  return 2 * math.pi * vertexIndex / vertexCount;
}

/// Cartesian position of a vertex on a circle of [radius] centered at
/// ([centerX], [centerY]). Y is flipped because canvas Y grows downward.
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

/// Builds the `vertexCount - 1` ordered lace segments from the visit order.
List<LaceSegment> laceSegments(int vertexCount) {
  final path = lacePath(vertexCount);
  return [
    for (var step = 0; step < path.length - 1; step++)
      LaceSegment(
        fromIndex: path[step],
        toIndex: path[step + 1],
        step: step,
      ),
  ];
}

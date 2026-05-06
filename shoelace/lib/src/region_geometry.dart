// region_geometry.dart — per-vertex region paths for the shoelace disc.
//
// Single source of truth for region geometry. The painter consumes
// `regionPathsFor` to fill each variant's region with its color; the
// canvas widget consumes the same function to hit-test taps. Neither
// owns the geometry; both depend on this module.
//
// Construction:
//   - Interior lace-path vertex (positions 1..N-2) → apex-triangle:
//     apex + the two chords meeting at the apex + the arc on the far
//     side of the disc connecting the two chord endpoints (the arc that
//     does NOT pass through the apex).
//   - Endpoint vertex (positions 0 and N-1) → rim lune: apex + the one
//     chord leaving the apex + the short rim arc from the chord's other
//     endpoint back to the apex.
//   - Degenerate N=1 → the whole disc belongs to the single variant.
//
// Pure function. No state, no painting, no hit-testing concerns — just
// returns a `Path` per variant index.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'lace_path.dart';

/// Returns one closed `Path` per variant index. The keys are vertex
/// indices in the original variant order (NOT lace-path order). Each
/// path is in the coordinate space of a SizedBox at origin (0,0) with
/// the painter's standard center at ([centerX], [centerY]).
///
/// `vertexCount = 0` returns an empty map.
Map<int, Path> regionPathsFor({
  required int vertexCount,
  required double centerX,
  required double centerY,
  required double discRadius,
}) {
  if (vertexCount == 0) return const {};

  final discBounds = Rect.fromCircle(
    center: Offset(centerX, centerY),
    radius: discRadius,
  );

  if (vertexCount == 1) {
    return {0: Path()..addOval(discBounds)};
  }

  final path = lacePath(vertexCount);
  final result = <int, Path>{};
  for (var vertexIndex = 0; vertexIndex < vertexCount; vertexIndex++) {
    final lacePosition = path.indexOf(vertexIndex);
    final isPathStart = lacePosition == 0;
    final isPathEnd = lacePosition == vertexCount - 1;
    result[vertexIndex] = (isPathStart || isPathEnd)
        ? _endpointRegion(
            apexIndex: vertexIndex,
            otherIndex: isPathStart ? path[1] : path[vertexCount - 2],
            vertexCount: vertexCount,
            centerX: centerX,
            centerY: centerY,
            discRadius: discRadius,
            discBounds: discBounds,
          )
        : _interiorRegion(
            apexIndex: vertexIndex,
            prevIndex: path[lacePosition - 1],
            nextIndex: path[lacePosition + 1],
            vertexCount: vertexCount,
            centerX: centerX,
            centerY: centerY,
            discRadius: discRadius,
            discBounds: discBounds,
          );
  }
  return result;
}

Path _endpointRegion({
  required int apexIndex,
  required int otherIndex,
  required int vertexCount,
  required double centerX,
  required double centerY,
  required double discRadius,
  required Rect discBounds,
}) {
  final apexPosition = vertexPosition(
    angle: vertexAngle(apexIndex, vertexCount),
    centerX: centerX,
    centerY: centerY,
    radius: discRadius,
  );
  final otherPosition = vertexPosition(
    angle: vertexAngle(otherIndex, vertexCount),
    centerX: centerX,
    centerY: centerY,
    radius: discRadius,
  );
  final canvasOtherAngle = -vertexAngle(otherIndex, vertexCount);
  final canvasApexAngle = -vertexAngle(apexIndex, vertexCount);
  final sweep = _shortArcSweep(canvasOtherAngle, canvasApexAngle);

  return Path()
    ..moveTo(apexPosition.x, apexPosition.y)
    ..lineTo(otherPosition.x, otherPosition.y)
    ..arcTo(discBounds, canvasOtherAngle, sweep, false)
    ..close();
}

Path _interiorRegion({
  required int apexIndex,
  required int prevIndex,
  required int nextIndex,
  required int vertexCount,
  required double centerX,
  required double centerY,
  required double discRadius,
  required Rect discBounds,
}) {
  final apexPosition = vertexPosition(
    angle: vertexAngle(apexIndex, vertexCount),
    centerX: centerX,
    centerY: centerY,
    radius: discRadius,
  );
  final prevPosition = vertexPosition(
    angle: vertexAngle(prevIndex, vertexCount),
    centerX: centerX,
    centerY: centerY,
    radius: discRadius,
  );
  final canvasPrevAngle = -vertexAngle(prevIndex, vertexCount);
  final canvasNextAngle = -vertexAngle(nextIndex, vertexCount);
  final canvasApexAngle = -vertexAngle(apexIndex, vertexCount);
  final sweep =
      _farSideArcSweep(canvasPrevAngle, canvasNextAngle, canvasApexAngle);

  return Path()
    ..moveTo(apexPosition.x, apexPosition.y)
    ..lineTo(prevPosition.x, prevPosition.y)
    ..arcTo(discBounds, canvasPrevAngle, sweep, false)
    ..lineTo(apexPosition.x, apexPosition.y)
    ..close();
}

/// Signed sweep that takes the shorter rotation from [fromAngle] to
/// [toAngle] in canvas-radians. Result is in (-π, π]; positive = canvas-
/// CW, negative = canvas-CCW.
double _shortArcSweep(double fromAngle, double toAngle) {
  var delta = (toAngle - fromAngle) % (2 * math.pi);
  if (delta > math.pi) delta -= 2 * math.pi;
  return delta;
}

/// Signed sweep from [fromAngle] to [toAngle] taking whichever direction
/// does NOT pass through [avoidAngle]. Used to pick the far-side arc for
/// an interior region — the apex must not lie on the arc that closes
/// its own region.
double _farSideArcSweep(
  double fromAngle,
  double toAngle,
  double avoidAngle,
) {
  final clockwiseSweep = (toAngle - fromAngle) % (2 * math.pi);
  final avoidOffset = (avoidAngle - fromAngle) % (2 * math.pi);
  if (avoidOffset > 0 && avoidOffset < clockwiseSweep) {
    return clockwiseSweep - 2 * math.pi;
  }
  return clockwiseSweep;
}

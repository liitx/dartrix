// shoelace_painter.dart — Flutter CustomPainter for the smooth shoelace.
//
// Draws into a Canvas, back to front:
//   1. Disc base — soft radial gradient that gives the empty disc its
//      "premium" inner depth. Region fills sit on top with low alpha so
//      the gradient subtly bleeds through.
//   2. Per-vertex regions — every variant owns a closed area on the disc.
//      Apex-triangles for interior lace-path vertices, rim lunes for the
//      two endpoints. Fill = apex variant color; alpha encodes coverage so
//      uncovered regions stay visible-but-dim. Regions tile the disc.
//   3. Faint outer guide ring along the inscribed circle.
//   4. Lace chords — color = TO-node color. Covered chords get a glow
//      pass under the main stroke for a neon-edge effect.
//   5. Vertex dots — colored fill with a soft halo. Focused vertex
//      brighter and larger.
//
// Every visual knob (strokes, fills, glow blurs, halos, gradient stops)
// lives in `AppPaint` in tokens.dart. Disc geometry constants
// (`AppLayout.discRadiusRatio`) live there too because the canvas widget
// needs to agree on them.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'coverage.dart';
import 'lace_path.dart';
import 'ui/tokens.dart';

class ShoelacePainter extends CustomPainter {
  ShoelacePainter({required this.snapshot, required this.focusedIndex});

  final CoverageSnapshot snapshot;
  final int focusedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshot.variants.isEmpty) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final discRadius =
        math.min(size.width, size.height) / 2 * AppLayout.discRadiusRatio;

    _drawDiscBase(canvas, centerX, centerY, discRadius);
    _drawRegions(canvas, centerX, centerY, discRadius);
    _drawGuideRing(canvas, centerX, centerY, discRadius);
    _drawLaces(canvas, centerX, centerY, discRadius);
    _drawVertices(canvas, centerX, centerY, discRadius);
  }

  // ── Layers ────────────────────────────────────────────────────────────────

  /// Soft radial gradient on the disc area. Lighter at center, fading to
  /// the background hue at the rim. Creates the "inner depth" feel that
  /// region fills layer on top of.
  void _drawDiscBase(
    Canvas canvas,
    double centerX,
    double centerY,
    double discRadius,
  ) {
    final shader = ui.Gradient.radial(
      Offset(centerX, centerY),
      discRadius,
      const [
        AppPaint.discCenterTint,
        AppPaint.discMidTint,
        AppPaint.discRimTint,
      ],
      AppPaint.discGradientStops,
    );
    canvas.drawCircle(
      Offset(centerX, centerY),
      discRadius,
      Paint()
        ..shader = shader
        ..isAntiAlias = true,
    );
  }

  /// Per-vertex region geometry. Each variant owns a closed area on the
  /// disc filled with its own color; alpha tracks coverage so uncovered
  /// regions stay visible-but-dim. Interior lace-path vertices get
  /// apex-triangles; the two endpoints get rim lunes. Together they tile
  /// the disc.
  void _drawRegions(
    Canvas canvas,
    double centerX,
    double centerY,
    double discRadius,
  ) {
    final vertexCount = snapshot.variants.length;
    if (vertexCount == 0) return;

    final discBounds =
        Rect.fromCircle(center: Offset(centerX, centerY), radius: discRadius);

    if (vertexCount == 1) {
      // Degenerate case: a single variant owns the whole disc.
      _fillRegion(
        canvas,
        Path()..addOval(discBounds),
        snapshot.variants.first,
      );
      return;
    }

    final path = lacePath(vertexCount);
    for (var vertexIndex = 0; vertexIndex < vertexCount; vertexIndex++) {
      final lacePosition = path.indexOf(vertexIndex);
      final isPathStart = lacePosition == 0;
      final isPathEnd = lacePosition == vertexCount - 1;
      final regionPath = (isPathStart || isPathEnd)
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
      _fillRegion(canvas, regionPath, snapshot.variants[vertexIndex]);
    }
  }

  /// Region for a lace-path endpoint vertex (path-start or path-end). Lune
  /// bounded by the apex, the one chord leaving the apex, and the short
  /// rim arc from the chord's other endpoint back to the apex. The chord
  /// neighbor is always disc-adjacent at lace-path positions 0 and N-1.
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

  /// Region for an interior lace-path vertex (positions 1..N-2). Apex-
  /// triangle bounded by the apex, both chords meeting at the apex, and
  /// the arc on the far side of the disc connecting the two chord
  /// endpoints — the arc that does NOT pass through the apex.
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

  /// Shared region paint. Translucent so the disc gradient bleeds through.
  void _fillRegion(Canvas canvas, Path path, VariantInfo variant) {
    final ratio = variant.coverageRatio.clamp(0.0, 1.0);
    final alpha = AppPaint.regionAlphaMin +
        (AppPaint.regionAlphaMax - AppPaint.regionAlphaMin) * ratio;
    canvas.drawPath(
      path,
      Paint()
        ..color = variant.color.withValues(alpha: alpha)
        ..isAntiAlias = true,
    );
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

  /// Faint stippled guide ring along the inscribed circle.
  void _drawGuideRing(
    Canvas canvas,
    double centerX,
    double centerY,
    double discRadius,
  ) {
    canvas.drawCircle(
      Offset(centerX, centerY),
      discRadius,
      Paint()
        ..color = AppColor.guideRing.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppPaint.guideRingStroke
        ..isAntiAlias = true,
    );
  }

  /// Lace chords colored by the TO node — the chord points at it, so it
  /// carries that node's color. Covered chords get a wide blurred halo
  /// behind the sharp core for a lit neon edge.
  void _drawLaces(
    Canvas canvas,
    double centerX,
    double centerY,
    double discRadius,
  ) {
    final vertexCount = snapshot.variants.length;
    if (vertexCount < 2) return;
    for (final segment in laceSegments(vertexCount)) {
      final toVariant = snapshot.variants[segment.toIndex];
      final fromPosition = vertexPosition(
        angle: vertexAngle(segment.fromIndex, vertexCount),
        centerX: centerX,
        centerY: centerY,
        radius: discRadius,
      );
      final toPosition = vertexPosition(
        angle: vertexAngle(segment.toIndex, vertexCount),
        centerX: centerX,
        centerY: centerY,
        radius: discRadius,
      );
      _drawChord(
        canvas,
        Offset(fromPosition.x, fromPosition.y),
        Offset(toPosition.x, toPosition.y),
        toVariant.color,
        toVariant.coverageRatio,
      );
    }
  }

  /// One chord. Uniform [AppPaint.chordCoreWidth] core stroke for every
  /// chord so thickness reads consistently across covered and gap
  /// segments. Alpha encodes coverage. Covered chords get a wide blurred
  /// glow halo behind the core for a lit neon edge.
  void _drawChord(
    Canvas canvas,
    Offset from,
    Offset to,
    Color chordColor,
    double coverageRatio,
  ) {
    final ratio = coverageRatio.clamp(0.0, 1.0);

    if (ratio >= 1.0) {
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = chordColor.withValues(alpha: AppPaint.chordGlowAlpha)
          ..strokeWidth = AppPaint.chordGlowWidth
          ..strokeCap = StrokeCap.round
          ..maskFilter = const ui.MaskFilter.blur(
            ui.BlurStyle.normal,
            AppPaint.chordGlowBlur,
          )
          ..isAntiAlias = true,
      );
    }

    final coreAlpha = AppPaint.chordAlphaMin +
        (AppPaint.chordAlphaMax - AppPaint.chordAlphaMin) * ratio;
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = chordColor.withValues(alpha: coreAlpha)
        ..strokeWidth = AppPaint.chordCoreWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  /// Vertex dots — colored fill with a strong soft halo. Focused vertex
  /// gets a brighter halo plus an emphasis ring for clarity.
  void _drawVertices(
    Canvas canvas,
    double centerX,
    double centerY,
    double discRadius,
  ) {
    final vertexCount = snapshot.variants.length;
    for (var vertexIndex = 0; vertexIndex < vertexCount; vertexIndex++) {
      final variant = snapshot.variants[vertexIndex];
      final isFocused = vertexIndex == focusedIndex;
      final position = vertexPosition(
        angle: vertexAngle(vertexIndex, vertexCount),
        centerX: centerX,
        centerY: centerY,
        radius: discRadius,
      );

      final haloAlpha = isFocused
          ? AppPaint.vertexFocusedHaloAlpha
          : AppPaint.vertexHaloAlpha;
      final haloBlur =
          isFocused ? AppPaint.vertexFocusedHaloBlur : AppPaint.vertexHaloBlur;
      final haloRadius = isFocused
          ? AppPaint.vertexFocusedHaloRadius
          : AppPaint.vertexHaloRadius;
      canvas.drawCircle(
        Offset(position.x, position.y),
        haloRadius,
        Paint()
          ..color = variant.color.withValues(alpha: haloAlpha)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, haloBlur),
      );

      final coreRadius = isFocused
          ? AppPaint.vertexFocusedCoreRadius
          : AppPaint.vertexCoreRadius;
      canvas.drawCircle(
        Offset(position.x, position.y),
        coreRadius,
        Paint()..color = variant.color,
      );

      if (isFocused) {
        canvas.drawCircle(
          Offset(position.x, position.y),
          AppPaint.vertexFocusRingRadius,
          Paint()
            ..color = AppColor.emphasis.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = AppPaint.vertexFocusRingStroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ShoelacePainter old) {
    return old.snapshot != snapshot || old.focusedIndex != focusedIndex;
  }
}

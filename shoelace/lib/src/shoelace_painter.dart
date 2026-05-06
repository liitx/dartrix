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
import 'region_geometry.dart';
import 'ui/tokens.dart';

class ShoelacePainter extends CustomPainter {
  ShoelacePainter({required this.snapshot, required this.focusedIndex});

  final CoverageSnapshot snapshot;
  final int? focusedIndex;

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
  /// regions stay visible-but-dim. Geometry is delegated to
  /// `regionPathsFor` so the painter and the canvas's hit-test agree on
  /// one source of truth.
  void _drawRegions(
    Canvas canvas,
    double centerX,
    double centerY,
    double discRadius,
  ) {
    final paths = regionPathsFor(
      vertexCount: snapshot.variants.length,
      centerX: centerX,
      centerY: centerY,
      discRadius: discRadius,
    );
    for (final entry in paths.entries) {
      _fillRegion(canvas, entry.value, snapshot.variants[entry.key]);
    }
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

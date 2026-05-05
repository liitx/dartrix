// shoelace_painter.dart — Flutter CustomPainter for the smooth shoelace.
//
// Draws into a Canvas:
//   1. Faint outer guide ring.
//   2. Subtle per-vertex angular sectors (low alpha) for "vertex owns area"
//      hint.
//   3. Lace chords — color = FROM-node color, anti-aliased, 2px thick when
//      lit, 1px dashed-style when gap. Smooth diagonals (this is real Canvas).
//   4. Vertex dots — colored fill with a soft halo.
//
// No labels here — the screen layer overlays Text widgets via Stack +
// Positioned for crisp typography.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'coverage.dart';
import 'lace_path.dart';
import 'ui/tokens.dart';

class ShoelacePainter extends CustomPainter {
  ShoelacePainter({
    required this.data,
    required this.focusedIndex,
  });

  final CoverageData data;
  final int focusedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.variants.isEmpty) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    // Reserve room for labels around the perimeter.
    final radius = math.min(size.width, size.height) / 2 * 0.78;

    _drawGuideRing(canvas, cx, cy, radius);
    _drawLaces(canvas, cx, cy, radius);
    _drawVertices(canvas, cx, cy, radius);
  }

  // ── Layers ────────────────────────────────────────────────────────────────

  /// Faint stippled guide ring along the inscribed circle.
  void _drawGuideRing(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..color = AppColor.guideRing.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(cx, cy), radius, paint);
  }

  /// Lace chords with FROM-node colors. Anti-aliased smooth strokes.
  void _drawLaces(Canvas canvas, double cx, double cy, double radius) {
    final n = data.variants.length;
    if (n < 2) return;
    final segments = laceSegments(n);
    for (final seg in segments) {
      final from = data.variants[seg.fromIndex];
      final to = data.variants[seg.toIndex];
      final fromPos = vertexPosition(
        angle: vertexAngle(seg.fromIndex, n),
        centerX: cx,
        centerY: cy,
        radius: radius,
      );
      final toPos = vertexPosition(
        angle: vertexAngle(seg.toIndex, n),
        centerX: cx,
        centerY: cy,
        radius: radius,
      );

      // Pattern-derived stroke style from segment status. Pure switch
      // expression, no inline boolean smearing.
      final status = SegmentStatus.fromRatios(
        from.coverageRatio,
        to.coverageRatio,
      );
      final ({Color color, double width}) stroke = switch (status) {
        SegmentStatus.tested => (color: from.color, width: 2.0),
        SegmentStatus.gap => (
            color: from.color.withValues(alpha: 0.35),
            width: 1.0,
          ),
        SegmentStatus.notApplicable => (
            color: AppColor.textHint.color,
            width: 1.0,
          ),
      };
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawLine(
        Offset(fromPos.x, fromPos.y),
        Offset(toPos.x, toPos.y),
        paint,
      );
    }
  }

  /// Vertex dots — colored fill with a soft halo. Focused vertex has a
  /// brighter halo + larger dot.
  void _drawVertices(Canvas canvas, double cx, double cy, double radius) {
    final n = data.variants.length;
    for (var i = 0; i < n; i++) {
      final v = data.variants[i];
      final isFocus = i == focusedIndex;
      final pos = vertexPosition(
        angle: vertexAngle(i, n),
        centerX: cx,
        centerY: cy,
        radius: radius,
      );

      final haloPaint = Paint()
        ..color = v.color.withValues(alpha: isFocus ? 0.45 : 0.25)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, isFocus ? 8 : 5);
      canvas.drawCircle(Offset(pos.x, pos.y), isFocus ? 9 : 6, haloPaint);

      final corePaint = Paint()..color = v.color;
      canvas.drawCircle(Offset(pos.x, pos.y), isFocus ? 5 : 4, corePaint);

      if (isFocus) {
        final ringPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(Offset(pos.x, pos.y), 6.5, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ShoelacePainter old) {
    return old.data != data || old.focusedIndex != focusedIndex;
  }
}

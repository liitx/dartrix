// shoelace_canvas.dart — circular shoelace canvas with vertex labels.
//
// Layout strategy:
//   - Maximum disc diameter capped (`AppLayout.maxDiscDiameter`) so wide
//     viewports do not stretch the disc to fill the entire body.
//   - Outer Padding (`AppLayout.labelPadding`) reserves overflow space
//     for label widgets.
//   - Stack(clipBehavior: Clip.none) lets labels render past the SizedBox
//     edge into that reserved padding zone.
//
// Hit testing:
//   - GestureDetector wraps the Stack inside the SizedBox (NOT the outer
//     Padding) so `details.localPosition` is in painter-local coordinates.
//   - On tap, `regionPathsFor` produces the same per-vertex Paths the
//     painter draws. The first `path.contains(localPosition)` returns
//     the focused index; misses call `onVariantTap(null)` to clear focus.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'coverage.dart';
import 'lace_path.dart';
import 'region_geometry.dart';
import 'shoelace_painter.dart';
import 'ui/tokens.dart';

class ShoelaceCanvas extends StatelessWidget {
  const ShoelaceCanvas({
    required this.snapshot,
    required this.focusedIndex,
    required this.onVariantTap,
    super.key,
  });

  final CoverageSnapshot snapshot;
  final int? focusedIndex;
  final ValueChanged<int?> onVariantTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppLayout.labelPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final canvasSide = math.min(available, AppLayout.maxDiscDiameter);
          if (canvasSide <= 0) return const SizedBox.shrink();
          return Center(
            child: SizedBox(
              width: canvasSide,
              height: canvasSide,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) =>
                    _handleTap(details.localPosition, canvasSide),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: ShoelacePainter(
                          snapshot: snapshot,
                          focusedIndex: focusedIndex,
                        ),
                      ),
                    ),
                    ..._buildLabels(canvasSide),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Hit-test the tapped position against the per-vertex region paths.
  /// First match wins; a miss clears focus by emitting null.
  void _handleTap(Offset localPosition, double canvasSide) {
    final paths = regionPathsFor(
      vertexCount: snapshot.variants.length,
      centerX: canvasSide / 2,
      centerY: canvasSide / 2,
      discRadius: canvasSide / 2 * AppLayout.discRadiusRatio,
    );
    for (final entry in paths.entries) {
      if (entry.value.contains(localPosition)) {
        onVariantTap(entry.key);
        return;
      }
    }
    onVariantTap(null);
  }

  List<Widget> _buildLabels(double canvasSide) {
    final vertexCount = snapshot.variants.length;
    if (vertexCount == 0) return const [];
    final centerX = canvasSide / 2;
    final centerY = canvasSide / 2;
    final discRadius = canvasSide / 2 * AppLayout.discRadiusRatio;
    final labelRadius = discRadius + AppLayout.labelGap;

    return [
      for (var vertexIndex = 0; vertexIndex < vertexCount; vertexIndex++)
        _VariantLabel(
          variant: snapshot.variants[vertexIndex],
          isFocused: vertexIndex == focusedIndex,
          containerSide: canvasSide,
          centerX: centerX,
          centerY: centerY,
          labelRadius: labelRadius,
          angle: vertexAngle(vertexIndex, vertexCount),
        ),
    ];
  }
}

class _VariantLabel extends StatelessWidget {
  const _VariantLabel({
    required this.variant,
    required this.isFocused,
    required this.containerSide,
    required this.centerX,
    required this.centerY,
    required this.labelRadius,
    required this.angle,
  });

  final VariantInfo variant;
  final bool isFocused;
  final double containerSide;
  final double centerX;
  final double centerY;
  final double labelRadius;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final position = vertexPosition(
      angle: angle,
      centerX: centerX,
      centerY: centerY,
      radius: labelRadius,
    );
    final isLeftHalf = math.cos(angle) < 0;

    // Quadrant-aware vertical anchor — labels above the vertex when in
    // the top half of the disc, below when in the bottom half, vertically
    // centered when near the horizontal axis. Prevents the label from
    // sitting on top of the vertex dot at 6 / 12 o'clock.
    final dy = position.y - centerY;
    final centerBand = labelRadius * AppLayout.labelCenterBandRatio;
    final topValue = switch (dy) {
      _ when dy.abs() < centerBand =>
        position.y - AppLayout.labelLineHeight / 2,
      _ when dy < 0 =>
        position.y - AppLayout.labelLineHeight - AppLayout.labelGap / 3,
      _ => position.y + AppLayout.labelGap / 3,
    };

    return Positioned(
      left: isLeftHalf ? null : position.x,
      right: isLeftHalf ? containerSide - position.x : null,
      top: topValue,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxLabelWidth),
        child: Text(
          variant.name,
          softWrap: false,
          overflow: TextOverflow.fade,
          maxLines: 1,
          textAlign: isLeftHalf ? TextAlign.right : TextAlign.left,
          style: AppText.body.styleWith(variant.color).copyWith(
                fontWeight: isFocused ? FontWeight.bold : FontWeight.w500,
                shadows: isFocused
                    ? [
                        Shadow(
                          color: variant.color.withValues(
                            alpha: AppPaint.labelFocusShadowAlpha,
                          ),
                          blurRadius: AppPaint.labelFocusShadowBlur,
                        ),
                      ]
                    : null,
              ),
        ),
      ),
    );
  }
}

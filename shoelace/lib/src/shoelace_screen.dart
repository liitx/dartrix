// shoelace_screen.dart — body for `CoverageLoaded`. NOT a Scaffold.
//
// Composition:
//   Column
//     ├─ _Header        — title + tagline + source path
//     ├─ Expanded Row
//     │    ├─ Expanded _Canvas       — CustomPaint + Positioned labels
//     │    └─ SidePanel              — variants + lace segments
//     └─ _ProgressStrip — coverage bar + gap count

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'coverage.dart';
import 'lace_path.dart';
import 'shoelace_painter.dart';
import 'side_panel.dart';
import 'ui/tokens.dart';

class ShoelaceScreen extends StatefulWidget {
  const ShoelaceScreen({
    required this.data,
    required this.sourcePath,
    super.key,
  });

  final CoverageData data;
  final String sourcePath;

  @override
  State<ShoelaceScreen> createState() => _ShoelaceScreenState();
}

class _ShoelaceScreenState extends State<ShoelaceScreen> {
  int _focusedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(sourcePath: widget.sourcePath),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _Canvas(
                  data: widget.data,
                  focusedIndex: _focusedIndex,
                ),
              ),
              SidePanel(
                data: widget.data,
                focusedIndex: _focusedIndex,
                onVariantTap: (i) => setState(() => _focusedIndex = i),
              ),
            ],
          ),
        ),
        _ProgressStrip(data: widget.data),
      ],
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.sourcePath});

  final String sourcePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl.px,
        vertical: AppSpacing.md.px + 2,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColor.border.color)),
      ),
      child: Row(
        children: [
          Text(
            UiLabel.appTitle.text,
            style: AppText.appTitle.styleWith(Colors.white),
          ),
          SizedBox(width: AppSpacing.lg.px),
          Text(
            UiLabel.tagline.text,
            style: AppText.hint.styleWith(AppColor.textMuted.color),
          ),
          const Spacer(),
          Text(
            sourcePath,
            style: AppText.monoTiny.styleWith(AppColor.textHint.color),
          ),
        ],
      ),
    );
  }
}

// ── Canvas (CustomPaint + Positioned labels) ────────────────────────────────

class _Canvas extends StatelessWidget {
  const _Canvas({required this.data, required this.focusedIndex});

  final CoverageData data;
  final int focusedIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: ShoelacePainter(
                      data: data,
                      focusedIndex: focusedIndex,
                    ),
                  ),
                ),
                ..._buildLabels(side),
              ],
            ),
          ),
        );
      },
    );
  }

  /// One Positioned Text per vertex, anchored just outside the inscribed
  /// circle on the same radial as the vertex dot.
  List<Widget> _buildLabels(double side) {
    final n = data.variants.length;
    if (n == 0) return const [];
    final cx = side / 2;
    final cy = side / 2;
    final radius = side / 2 * 0.78;
    final outerRadius = radius + 18;

    return [
      for (var i = 0; i < n; i++)
        _VariantLabel(
          variant: data.variants[i],
          isFocused: i == focusedIndex,
          containerSide: side,
          centerX: cx,
          centerY: cy,
          outerRadius: outerRadius,
          angle: vertexAngle(i, n),
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
    required this.outerRadius,
    required this.angle,
  });

  final VariantInfo variant;
  final bool isFocused;
  final double containerSide;
  final double centerX;
  final double centerY;
  final double outerRadius;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final pos = vertexPosition(
      angle: angle,
      centerX: centerX,
      centerY: centerY,
      radius: outerRadius,
    );
    final isLeftHalf = math.cos(angle) < 0;
    final color = isFocused ? Colors.white : variant.color;

    return Positioned(
      left: isLeftHalf ? null : pos.x,
      right: isLeftHalf ? containerSide - pos.x : null,
      top: pos.y - 8,
      child: Text(
        variant.name,
        style: AppText.body.styleWith(color).copyWith(
              fontWeight:
                  isFocused ? FontWeight.bold : FontWeight.w500,
            ),
      ),
    );
  }
}

// ── Progress strip ──────────────────────────────────────────────────────────

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.data});

  final CoverageData data;

  @override
  Widget build(BuildContext context) {
    final ratio = data.coverageRatio;
    final pct = (ratio * 100).round();
    final isComplete = ratio >= 1.0;
    final fillColor = isComplete
        ? AppColor.statusComplete.color
        : AppColor.accent.color;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl.px,
        AppSpacing.md.px,
        AppSpacing.xl.px,
        AppSpacing.md.px + 2,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColor.border.color)),
      ),
      child: Row(
        children: [
          Text(
            UiLabel.stripCoverage.text,
            style: AppText.sectionHeader
                .styleWith(AppColor.textMuted.color),
          ),
          SizedBox(width: AppSpacing.md.px),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: AppColor.border.color,
                valueColor: AlwaysStoppedAnimation<Color>(fillColor),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md.px),
          Text(
            '$pct%',
            style: AppText.count.styleWith(
              isComplete ? fillColor : Colors.white,
            ),
          ),
          SizedBox(width: AppSpacing.sm.px),
          if (data.gapCount > 0)
            _GapCountLabel(count: data.gapCount)
          else
            Text(
              UiLabel.badgeComplete.text,
              style: AppText.bodyMuted
                  .styleWith(fillColor)
                  .copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
            ),
        ],
      ),
    );
  }
}

class _GapCountLabel extends StatelessWidget {
  const _GapCountLabel({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final word = count == 1 ? 'gap' : 'gaps';
    return Text(
      '$count $word',
      style: AppText.bodyMuted.styleWith(AppColor.statusGap.color),
    );
  }
}

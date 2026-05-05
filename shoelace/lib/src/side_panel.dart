// side_panel.dart — VARIANTS + LACE SEGMENTS lists alongside the canvas.

import 'package:flutter/material.dart';

import 'coverage.dart';
import 'lace_path.dart';
import 'ui/tokens.dart';

class SidePanel extends StatelessWidget {
  const SidePanel({
    required this.data,
    required this.focusedIndex,
    required this.onVariantTap,
    super.key,
  });

  final CoverageData data;
  final int focusedIndex;
  final ValueChanged<int> onVariantTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.px),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppColor.border.color)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(label: UiLabel.sectionVariants),
            for (var i = 0; i < data.variants.length; i++)
              _VariantRow(
                variant: data.variants[i],
                isFocused: i == focusedIndex,
                onTap: () => onVariantTap(i),
              ),
            SizedBox(height: AppSpacing.lg.px),
            const _SectionHeader(label: UiLabel.sectionLaceSegments),
            ..._segmentRows(),
          ],
        ),
      ),
    );
  }

  List<Widget> _segmentRows() {
    final n = data.variants.length;
    if (n < 2) return const [];
    return [
      for (final seg in laceSegments(n))
        _SegmentRow(
          from: data.variants[seg.fromIndex],
          to: data.variants[seg.toIndex],
        ),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final UiLabel label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg.px,
        AppSpacing.xs.px,
        AppSpacing.lg.px,
        AppSpacing.sm.px,
      ),
      child: Text(
        label.text,
        style: AppText.sectionHeader.styleWith(AppColor.textMuted.color),
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.variant,
    required this.isFocused,
    required this.onTap,
  });

  final VariantInfo variant;
  final bool isFocused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (variant.coverageRatio * 100).round();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg.px,
          vertical: AppSpacing.xs.px + 2,
        ),
        child: Row(
          children: [
            _Dot(color: variant.color, focused: isFocused),
            SizedBox(width: AppSpacing.sm.px),
            Expanded(
              child: Text(
                variant.name,
                style: AppText.body
                    .styleWith(
                      isFocused ? Colors.white : AppColor.textPrimary.color,
                    )
                    .copyWith(
                      fontWeight: isFocused
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
              ),
            ),
            Text(
              '$pct%',
              style: AppText.bodyMuted
                  .styleWith(AppColor.textMuted.color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({required this.from, required this.to});

  final VariantInfo from;
  final VariantInfo to;

  /// Pattern-driven derivation of the badge label + color from segment status.
  /// `notApplicable` shouldn't reach this row (segments only join required
  /// variants), but the exhaustive switch makes the contract explicit.
  ({UiLabel label, Color color}) get _badge {
    final status =
        SegmentStatus.fromRatios(from.coverageRatio, to.coverageRatio);
    return switch (status) {
      SegmentStatus.tested => (
          label: UiLabel.badgeTested,
          color: AppColor.statusComplete.color,
        ),
      SegmentStatus.gap => (
          label: UiLabel.badgeGap,
          color: AppColor.statusGap.color,
        ),
      SegmentStatus.notApplicable => (
          label: UiLabel.badgeGap,
          color: AppColor.textHint.color,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.px,
        vertical: AppSpacing.xs.px,
      ),
      child: Row(
        children: [
          _Dot(color: from.color, focused: false, size: 8),
          SizedBox(width: AppSpacing.sm.px - 2),
          Text(
            from.name,
            style: AppText.bodyMuted.styleWith(from.color),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.px),
            child: Text(
              UiLabel.arrow.text,
              style: AppText.bodyMuted.styleWith(AppColor.textHint.color),
            ),
          ),
          Expanded(
            child: Text(
              to.name,
              style: AppText.bodyMuted
                  .styleWith(AppColor.textPrimary.color),
            ),
          ),
          Text(
            badge.label.text,
            style: AppText.badge.styleWith(badge.color),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.focused,
    this.size = 10,
  });

  final Color color;
  final bool focused;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: focused ? Border.all(color: Colors.white, width: 1.5) : null,
      ),
    );
  }
}

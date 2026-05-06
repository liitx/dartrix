// side_panel.dart — variants list / lace segments list (overview mode) and
// focused-variant drilldown with usages, tests, and gaps (detail mode).
//
// Width is controlled by the parent (SizedBox in wide layouts, Drawer in
// compact). The panel itself does not impose a width.
//
// Mode switch:
//   - focusedIndex == null  → overview mode (existing behaviour).
//   - focusedIndex != null  → detail mode for snapshot.variants[focusedIndex].
//
// The three detail sections (`_UsagesList`, `_TestsList`, `_GapsList`)
// are level-agnostic: they take a list of typed items and render rows.
// v3+ sub-circle drilldown will compose them inside nested circles.

import 'package:flutter/material.dart';

import 'coverage.dart';
import 'lace_path.dart';
import 'ui/tokens.dart';

class SidePanel extends StatelessWidget {
  const SidePanel({
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
    final focused = focusedIndex;
    final inDetailMode =
        focused != null && focused >= 0 && focused < snapshot.variants.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.background.color,
        border: Border(left: BorderSide(color: AppColor.border.color)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.px),
        child: inDetailMode
            ? _DetailMode(
                snapshot: snapshot,
                focusedVariant: snapshot.variants[focused],
                onBack: () => onVariantTap(null),
              )
            : _OverviewMode(
                snapshot: snapshot,
                focusedIndex: focusedIndex,
                onVariantTap: onVariantTap,
              ),
      ),
    );
  }
}

class _OverviewMode extends StatelessWidget {
  const _OverviewMode({
    required this.snapshot,
    required this.focusedIndex,
    required this.onVariantTap,
  });

  final CoverageSnapshot snapshot;
  final int? focusedIndex;
  final ValueChanged<int?> onVariantTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(label: UiLabel.sectionVariants),
        for (var i = 0; i < snapshot.variants.length; i++)
          _VariantRow(
            variant: snapshot.variants[i],
            isFocused: i == focusedIndex,
            onTap: () => onVariantTap(i),
          ),
        SizedBox(height: AppSpacing.lg.px),
        const _SectionHeader(label: UiLabel.sectionLaceSegments),
        ..._segmentRows(),
      ],
    );
  }

  List<Widget> _segmentRows() {
    final n = snapshot.variants.length;
    if (n < 2) return const [];
    return [
      for (final seg in laceSegments(n))
        _SegmentRow(
          from: snapshot.variants[seg.fromIndex],
          to: snapshot.variants[seg.toIndex],
        ),
    ];
  }
}

class _DetailMode extends StatelessWidget {
  const _DetailMode({
    required this.snapshot,
    required this.focusedVariant,
    required this.onBack,
  });

  final CoverageSnapshot snapshot;
  final VariantInfo focusedVariant;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final usages = snapshot.usages
        .where((u) => u.variant == focusedVariant.qualifiedName)
        .toList(growable: false);
    final tests = snapshot.tests
        .where((t) => t.variant == focusedVariant.qualifiedName)
        .toList(growable: false);
    final gaps = snapshot.gaps
        .where((g) => g.variant == focusedVariant.qualifiedName)
        .toList(growable: false);
    final pct = (focusedVariant.coverageRatio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onBack,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg.px,
              vertical: AppSpacing.xs.px,
            ),
            child: Text(
              UiLabel.detailBack.text,
              style: AppText.hint.styleWith(AppColor.textMuted.color),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg.px,
            AppSpacing.sm.px,
            AppSpacing.lg.px,
            AppSpacing.md.px,
          ),
          child: Row(
            children: [
              _Dot(color: focusedVariant.color, focused: true),
              SizedBox(width: AppSpacing.sm.px),
              Expanded(
                child: Text(
                  focusedVariant.name,
                  style: AppText.appTitle
                      .styleWith(AppColor.emphasis.color)
                      .copyWith(letterSpacing: 0),
                ),
              ),
              Text(
                '$pct%',
                style: AppText.count.styleWith(AppColor.textMuted.color),
              ),
            ],
          ),
        ),
        _UsagesList(usages: usages),
        SizedBox(height: AppSpacing.md.px),
        _TestsList(tests: tests),
        SizedBox(height: AppSpacing.md.px),
        _GapsList(gaps: gaps),
      ],
    );
  }
}

class _UsagesList extends StatelessWidget {
  const _UsagesList({required this.usages});

  final List<UsageInfo> usages;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      header: UiLabel.detailUsages,
      emptyLabel: UiLabel.detailNoUsages,
      isEmpty: usages.isEmpty,
      children: [
        for (final usage in usages)
          _LocationRow(
            location: usage.location,
            scope: _formatClassMethod(
              containingClass: usage.containingClass,
              containingMethod: usage.containingMethod,
            ),
          ),
      ],
    );
  }
}

class _TestsList extends StatelessWidget {
  const _TestsList({required this.tests});

  final List<TestInfo> tests;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      header: UiLabel.detailTests,
      emptyLabel: UiLabel.detailNoTests,
      isEmpty: tests.isEmpty,
      children: [
        for (final t in tests)
          _LocationRow(
            location: t.location,
            scope: t.containingGroup,
            trailingFeature: t.feature,
          ),
      ],
    );
  }
}

class _GapsList extends StatelessWidget {
  const _GapsList({required this.gaps});

  final List<GapInfo> gaps;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      header: UiLabel.detailGaps,
      emptyLabel: UiLabel.detailFullyCovered,
      isEmpty: gaps.isEmpty,
      children: [
        for (final g in gaps)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg.px,
              vertical: AppSpacing.xs.px,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    g.feature,
                    style: AppText.body
                        .styleWith(AppColor.textPrimary.color),
                  ),
                ),
                Text(
                  UiLabel.badgeGap.text,
                  style: AppText.badge.styleWith(AppColor.statusGap.color),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.header,
    required this.emptyLabel,
    required this.isEmpty,
    required this.children,
  });

  final UiLabel header;
  final UiLabel emptyLabel;
  final bool isEmpty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(label: header),
        if (isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg.px,
              vertical: AppSpacing.xs.px,
            ),
            child: Text(
              emptyLabel.text,
              style: AppText.bodyMuted.styleWith(AppColor.textHint.color),
            ),
          )
        else
          ...children,
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.location,
    this.scope,
    this.trailingFeature,
  });

  final SourceLocation location;
  final String? scope;
  final String? trailingFeature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.px,
        vertical: AppSpacing.xs.px,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (scope != null && scope!.isNotEmpty)
            Text(
              scope!,
              style: AppText.body.styleWith(AppColor.textPrimary.color),
            ),
          SizedBox(height: AppSpacing.xs.px - 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SelectableText(
                  location.displayPath,
                  style: AppText.monoTiny.styleWith(AppColor.textHint.color),
                ),
              ),
              if (trailingFeature != null) ...[
                SizedBox(width: AppSpacing.sm.px),
                Text(
                  trailingFeature!,
                  style: AppText.bodyMuted.styleWith(AppColor.textMuted.color),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

String? _formatClassMethod({
  required String? containingClass,
  required String? containingMethod,
}) {
  return switch ((containingClass, containingMethod)) {
    (final c?, final m?) => '$c.$m',
    (final c?, null) => c,
    (null, final m?) => m,
    (null, null) => null,
  };
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
                      isFocused
                          ? AppColor.emphasis.color
                          : AppColor.textPrimary.color,
                    )
                    .copyWith(
                      fontWeight:
                          isFocused ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ),
            Text(
              '$pct%',
              style: AppText.bodyMuted.styleWith(AppColor.textMuted.color),
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

  /// Pattern-driven derivation of the badge label and color from segment
  /// status. The chord is owned by the TO node, so the badge tracks TO's
  /// coverage. `notApplicable` should not reach this row but the
  /// exhaustive switch makes the contract explicit.
  ({UiLabel label, Color color}) get _badge {
    final status = SegmentStatus.forCoverage(to.coverageRatio);
    return switch (status) {
      SegmentStatus.covered => (
          label: UiLabel.badgeCovered,
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
              style: AppText.bodyMuted.styleWith(AppColor.textPrimary.color),
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
        border: focused
            ? Border.all(color: AppColor.emphasis.color, width: 1.5)
            : null,
      ),
    );
  }
}

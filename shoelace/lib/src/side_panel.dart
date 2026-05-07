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
    final typeName = snapshot.variants.isEmpty
        ? UiLabel.sectionVariants.text
        : snapshot.variants.first.type;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColor.background.color,
        border: Border(left: BorderSide(color: AppColor.border.color)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.px),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg.px,
                AppSpacing.sm.px,
                AppSpacing.lg.px,
                AppSpacing.md.px,
              ),
              child: Text(
                typeName,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style:
                    AppText.enumHeader.styleWith(AppColor.textPrimary.color),
              ),
            ),
            if (inDetailMode)
              _DetailMode(
                snapshot: snapshot,
                focusedVariant: snapshot.variants[focused],
                onBack: () => onVariantTap(null),
              )
            else
              _OverviewMode(
                snapshot: snapshot,
                focusedIndex: focusedIndex,
                onVariantTap: onVariantTap,
              ),
          ],
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.px),
      child: _VariantsTable(
        snapshot: snapshot,
        focusedIndex: focusedIndex,
        onVariantTap: onVariantTap,
      ),
    );
  }
}

class _VariantsTable extends StatelessWidget {
  const _VariantsTable({
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
        for (var i = 0; i < snapshot.variants.length; i++)
          _VariantTableRow(
            variant: snapshot.variants[i],
            regionState: snapshot.regionStateFor(snapshot.variants[i]).state,
            isFocused: i == focusedIndex,
            onTap: () => onVariantTap(i),
          ),
      ],
    );
  }
}

({UiLabel label, Color color}) _statusBadgeFor(RegionState state) =>
    switch (state) {
      RegionState.covered => (
          label: UiLabel.badgeCovered,
          color: AppColor.statusComplete.color,
        ),
      RegionState.failing => (
          label: UiLabel.badgeFailing,
          color: AppColor.statusFailing.color,
        ),
      RegionState.missing => (
          label: UiLabel.badgeGap,
          color: AppColor.statusGap.color,
        ),
    };

class _VariantTableRow extends StatelessWidget {
  const _VariantTableRow({
    required this.variant,
    required this.regionState,
    required this.isFocused,
    required this.onTap,
  });

  final VariantInfo variant;
  final RegionState regionState;
  final bool isFocused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (variant.coverageRatio * 100).round();
    final badge = _statusBadgeFor(regionState);
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isFocused
              ? AppColor.emphasis.color.withValues(alpha: 0.04)
              : null,
          border: Border(
            bottom: BorderSide(color: AppColor.border.color, width: 0.5),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.xs.px + 2,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    _Dot(color: variant.color, focused: isFocused),
                    SizedBox(width: AppSpacing.sm.px),
                    Flexible(
                      child: Text(
                        variant.name,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body
                            .styleWith(variant.color)
                            .copyWith(
                              fontWeight: isFocused
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              _columnSeparator,
              SizedBox(
                width: 56,
                child: Text(
                  '$pct%',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style:
                      AppText.body.styleWith(AppColor.textMuted.color).copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                ),
              ),
              _columnSeparator,
              SizedBox(
                width: 96,
                child: Text(
                  badge.label.text,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: AppText.badge.styleWith(badge.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget get _columnSeparator => Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.px),
        child: Container(
          width: 0.5,
          height: 18,
          color: AppColor.border.color,
        ),
      );
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
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body
                      .styleWith(focusedVariant.color)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: AppSpacing.sm.px),
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
        _GapsList(gaps: gaps, usages: usages),
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
        for (final t in tests) _TestRow(test: t),
      ],
    );
  }
}

class _TestRow extends StatelessWidget {
  const _TestRow({required this.test});

  final TestInfo test;

  ({UiLabel label, Color color}) get _icon => switch (test.status) {
        TestStatus.passing => (
            label: UiLabel.iconPassing,
            color: AppColor.statusComplete.color,
          ),
        TestStatus.failing || TestStatus.error => (
            label: UiLabel.iconFailing,
            color: AppColor.statusFailing.color,
          ),
        TestStatus.skipped => (
            label: UiLabel.iconSkipped,
            color: AppColor.textHint.color,
          ),
        null => (
            label: UiLabel.iconUnknown,
            color: AppColor.textHint.color,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final icon = _icon;
    final isFailing = test.status == TestStatus.failing ||
        test.status == TestStatus.error;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.px,
        vertical: AppSpacing.xs.px,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSpacing.lg.px,
            child: Text(
              icon.label.text,
              style: AppText.body.styleWith(icon.color),
            ),
          ),
          SizedBox(width: AppSpacing.xs.px),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (test.containingGroup case final scope?
                    when scope.isNotEmpty)
                  Text(
                    scope,
                    style: AppText.body.styleWith(AppColor.textPrimary.color),
                  ),
                SizedBox(height: AppSpacing.xs.px - 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SelectableText(
                        test.location.displayPath,
                        style: AppText.monoTiny
                            .styleWith(AppColor.textHint.color),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm.px),
                    Text(
                      test.feature,
                      style: AppText.bodyMuted
                          .styleWith(AppColor.textMuted.color),
                    ),
                  ],
                ),
                if (isFailing) ...[
                  if (test.failureMessage case final msg?
                      when msg.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.xs.px),
                    Text(
                      msg,
                      style: AppText.body
                          .styleWith(AppColor.statusFailing.color),
                    ),
                  ],
                  if (test.logPath case final path? when path.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.xs.px),
                    SelectableText(
                      '${UiLabel.detailFailureLogHint.text}$path',
                      style: AppText.monoTiny
                          .styleWith(AppColor.textHint.color),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GapsList extends StatelessWidget {
  const _GapsList({required this.gaps, required this.usages});

  final List<GapInfo> gaps;
  final List<UsageInfo> usages;

  /// Soft-match: case-insensitive substring of feature name in the file
  /// path. Handles `lib/src/features/dashboard/...` matching feature
  /// `dashboard` without hard-coding a project layout.
  List<UsageInfo> _usagesForFeature(String feature) {
    final needle = feature.toLowerCase();
    return [
      for (final u in usages)
        if (u.location.file.toLowerCase().contains(needle)) u,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (gaps.isEmpty) {
      return _DetailSection(
        header: UiLabel.detailGaps,
        emptyLabel: UiLabel.detailFullyCovered,
        isEmpty: true,
        children: const [],
      );
    }

    final perGap = [
      for (final g in gaps) (gap: g, usages: _usagesForFeature(g.feature)),
    ];
    final useFallback = perGap.every((row) => row.usages.isEmpty);

    return _DetailSection(
      header: UiLabel.detailGaps,
      emptyLabel: UiLabel.detailFullyCovered,
      isEmpty: false,
      children: [
        if (useFallback) ...[
          _SectionHeader(label: UiLabel.detailUsagesOfVariant),
          for (final u in usages)
            _LocationRow(
              location: u.location,
              scope: _formatClassMethod(
                containingClass: u.containingClass,
                containingMethod: u.containingMethod,
              ),
            ),
          SizedBox(height: AppSpacing.sm.px),
          for (final row in perGap) _GapRow(gap: row.gap, matchedUsages: const []),
        ] else
          for (final row in perGap)
            _GapRow(gap: row.gap, matchedUsages: row.usages),
      ],
    );
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow({required this.gap, required this.matchedUsages});

  final GapInfo gap;
  final List<UsageInfo> matchedUsages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.px,
        vertical: AppSpacing.xs.px,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  gap.feature,
                  style: AppText.body.styleWith(AppColor.textPrimary.color),
                ),
              ),
              Text(
                UiLabel.badgeGap.text,
                style: AppText.badge.styleWith(AppColor.statusGap.color),
              ),
            ],
          ),
          if (matchedUsages.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md.px,
                AppSpacing.xs.px,
                0,
                0,
              ),
              child: Text(
                UiLabel.detailNoUsagesForGap.text,
                style: AppText.bodyMuted.styleWith(AppColor.textHint.color),
              ),
            )
          else
            for (final u in matchedUsages)
              Padding(
                padding: EdgeInsets.only(left: AppSpacing.md.px),
                child: _LocationRow(
                  location: u.location,
                  scope: _formatClassMethod(
                    containingClass: u.containingClass,
                    containingMethod: u.containingMethod,
                  ),
                ),
              ),
        ],
      ),
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
  const _LocationRow({required this.location, this.scope});

  final SourceLocation location;
  final String? scope;

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
          if (scope case final s? when s.isNotEmpty)
            Text(
              s,
              style: AppText.body.styleWith(AppColor.textPrimary.color),
            ),
          SizedBox(height: AppSpacing.xs.px - 2),
          SelectableText(
            location.displayPath,
            style: AppText.monoTiny.styleWith(AppColor.textHint.color),
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

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.focused,
  });

  final Color color;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
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

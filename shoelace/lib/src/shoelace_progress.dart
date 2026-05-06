// shoelace_progress.dart — bottom progress bar mounted in Scaffold's
// bottomNavigationBar slot. Inset via internal padding so the bar does
// not stretch flush to the viewport edges.

import 'package:flutter/material.dart';

import 'coverage.dart';
import 'ui/tokens.dart';

class CoverageProgressBar extends StatelessWidget {
  const CoverageProgressBar({required this.snapshot, super.key});

  final CoverageSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final ratio = snapshot.averageCoverage;
    final pct = (ratio * 100).round();
    final isComplete = ratio >= 1.0;
    final fillColor =
        isComplete ? AppColor.statusComplete.color : AppColor.accent.color;

    return Material(
      color: AppColor.background.color,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColor.border.color)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl.px,
          vertical: AppSpacing.md.px,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Text(
                UiLabel.stripCoverage.text,
                style:
                    AppText.sectionHeader.styleWith(AppColor.textMuted.color),
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
                  isComplete ? fillColor : AppColor.emphasis.color,
                ),
              ),
              SizedBox(width: AppSpacing.sm.px),
              if (snapshot.gapCount > 0)
                _GapCount(count: snapshot.gapCount)
              else
                Text(
                  UiLabel.badgeComplete.text,
                  style: AppText.bodyMuted.styleWith(fillColor).copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GapCount extends StatelessWidget {
  const _GapCount({required this.count});

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

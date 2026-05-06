// status_view.dart — body widgets for the non-loaded LoadStates.
//
// StatusMessage covers Idle and Loading; ErrorMessage covers Failed.
// Kept out of shoelace_page.dart so the page reads as routing + layout.

import 'package:flutter/material.dart';

import 'ui/tokens.dart';

class StatusMessage extends StatelessWidget {
  const StatusMessage({
    required this.message,
    this.detail,
    this.spinner = false,
    super.key,
  });

  final String message;
  final String? detail;
  final bool spinner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spinner) ...[
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: AppSpacing.lg.px),
          ],
          Text(
            message,
            style: AppText.body.styleWith(AppColor.textMuted.color),
          ),
          if (detail != null) ...[
            SizedBox(height: AppSpacing.xs.px),
            Text(
              detail!,
              style: AppText.monoTiny.styleWith(AppColor.textHint.color),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorMessage extends StatelessWidget {
  const ErrorMessage({
    required this.path,
    required this.message,
    super.key,
  });

  final String path;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl.px),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              UiLabel.errorTitle.text,
              style: AppText.appTitle
                  .styleWith(AppColor.statusError.color)
                  .copyWith(letterSpacing: 0),
            ),
            SizedBox(height: AppSpacing.md.px),
            Text(
              message,
              style: AppText.body.styleWith(AppColor.textPrimary.color),
            ),
            SizedBox(height: AppSpacing.lg.px),
            SelectableText(
              path,
              style: AppText.monoTiny.styleWith(AppColor.textMuted.color),
            ),
          ],
        ),
      ),
    );
  }
}

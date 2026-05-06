// shoelace_app_bar.dart — Scaffold appBar with title, tagline, source path.
//
// Uses Material AppBar so the drawer hamburger appears automatically when
// Scaffold.drawer is provided (compact viewports).

import 'package:flutter/material.dart';

import 'load_state.dart';
import 'ui/tokens.dart';

class ShoelaceAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ShoelaceAppBar({required this.state, super.key});

  final LoadState state;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  String get _sourcePath => switch (state) {
        CoverageLoaded(:final sourcePath) => sourcePath,
        CoverageLoading(:final path) => path,
        CoverageFailed(:final path) => path,
        CoverageIdle() => '',
      };

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColor.background.color,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: Border(bottom: BorderSide(color: AppColor.border.color)),
      iconTheme: IconThemeData(color: AppColor.textMuted.color),
      titleSpacing: AppSpacing.lg.px,
      title: Row(
        children: [
          Text(
            UiLabel.appTitle.text,
            style: AppText.appTitle.styleWith(AppColor.emphasis.color),
          ),
          SizedBox(width: AppSpacing.lg.px),
          Flexible(
            child: Text(
              UiLabel.tagline.text,
              style: AppText.hint.styleWith(AppColor.textMuted.color),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      actions: [
        if (_sourcePath.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.xl.px),
            child: Center(
              child: Text(
                _sourcePath,
                style: AppText.monoTiny.styleWith(AppColor.textHint.color),
              ),
            ),
          ),
      ],
    );
  }
}

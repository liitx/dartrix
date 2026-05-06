// app_theme.dart — ThemeData construction for the shoelace shell.
//
// All visual tokens (colors, labels, spacing, layout, typography) live in
// `tokens.dart`. This file assembles them into a ThemeData. To tweak the
// app's overall look, edit tokens.dart. To change how those tokens map
// onto Material's theme system, edit this file.

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the shoelace ThemeData. Currently dark-only — widen the
/// signature with a `Brightness` parameter when a light variant lands.
ThemeData buildShoelaceTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColor.background.color,
    canvasColor: AppColor.background.color,
    dividerColor: AppColor.border.color,
    iconTheme: IconThemeData(color: AppColor.textMuted.color),
    colorScheme: ColorScheme.dark(
      surface: AppColor.background.color,
      primary: AppColor.accent.color,
      secondary: AppColor.accent.color,
      error: AppColor.statusError.color,
      onSurface: AppColor.textPrimary.color,
    ),
  );
}

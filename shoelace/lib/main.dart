// main.dart — dartrix_shoelace web entry point.
//
// MaterialApp + ShoelacePage at the root, no wrapper widget. Theme
// construction lives in `src/ui/app_theme.dart`; visual tokens live in
// `src/ui/tokens.dart`. The embedding host (zedup's local HttpServer)
// serves the snapshot at /coverage.json from the same origin as the app.

import 'package:flutter/material.dart';

import 'src/coverage_loader.dart';
import 'src/shoelace_page.dart';
import 'src/ui/app_theme.dart';
import 'src/ui/tokens.dart';

void main() {
  runApp(MaterialApp(
    title: UiLabel.appWindowTitle.text,
    debugShowCheckedModeBanner: false,
    theme: buildShoelaceTheme(),
    home: ShoelacePage(snapshotUrl: defaultSnapshotUrl()),
  ));
}

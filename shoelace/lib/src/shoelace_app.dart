// shoelace_app.dart — root MaterialApp + single Scaffold.
//
// Architecture:
//   ShoelaceApp     → MaterialApp (theme + window title)
//     _Home         → ONE Scaffold; body = bodyForState(_loadStateStream)
//       ┌─ Idle / Loading       → _StatusBody (centered text + spinner)
//       ├─ CoverageLoaded       → _LoadedBody (header / canvas / progress)
//       └─ CoverageLoadFailed   → _ErrorBody (formatted error + path)
//
// Inner widgets never wrap themselves in Scaffold — they're bodies.

import 'package:flutter/material.dart';

import 'coverage_loader.dart';
import 'load_state.dart';
import 'shoelace_screen.dart';
import 'ui/tokens.dart';

class ShoelaceApp extends StatelessWidget {
  const ShoelaceApp({required this.coverageJsonPath, super.key});

  final String coverageJsonPath;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: UiLabel.appWindowTitle.text,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColor.background.color,
        useMaterial3: true,
      ),
      home: _Home(coverageJsonPath: coverageJsonPath),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.coverageJsonPath});

  final String coverageJsonPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background.color,
      body: StreamBuilder<LoadState>(
        stream: watchCoverage(coverageJsonPath),
        initialData: const IdleLoad(),
        builder: (context, snap) => _bodyFor(snap.data ?? const IdleLoad()),
      ),
    );
  }

  /// Exhaustive switch on the sealed [LoadState] hierarchy. Adding a new
  /// state forces this switch to update or the build fails.
  Widget _bodyFor(LoadState state) => switch (state) {
        IdleLoad() =>
          const _StatusBody(message: UiLabel.initializing, spinner: false),
        LoadingCoverage(:final path) => _StatusBody(
            message: UiLabel.loadingPrefix,
            detail: path,
            spinner: true,
          ),
        CoverageLoaded(:final data, :final sourcePath) => ShoelaceScreen(
            data: data,
            sourcePath: sourcePath,
          ),
        CoverageLoadFailed(:final path, :final message) => _ErrorBody(
            path: path,
            message: message,
          ),
      };
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({
    required this.message,
    this.detail,
    this.spinner = false,
  });

  final UiLabel message;
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
            message.text,
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

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.path, required this.message});

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

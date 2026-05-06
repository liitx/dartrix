// shoelace_page.dart — single Scaffold root for the visualizer.
//
// Slot ownership (no chrome lives inside the body content):
//   - appBar:   ShoelaceAppBar (title, tagline, source path)
//   - drawer:   variants/segments list on compact viewports
//   - body:     state-aware switch on LoadState
//
// Layout dimensions (compactBreakpoint, sidePanelWidth, maxBodyWidth,
// canvasAreaHeight) live in `AppLayout` so the canvas widget and painter
// agree on disc geometry without duplicating constants.

import 'package:flutter/material.dart';

import 'coverage.dart';
import 'coverage_loader.dart';
import 'load_state.dart';
import 'shoelace_app_bar.dart';
import 'shoelace_canvas.dart';
import 'shoelace_progress.dart';
import 'side_panel.dart';
import 'status_view.dart';
import 'ui/tokens.dart';

class ShoelacePage extends StatefulWidget {
  const ShoelacePage({required this.snapshotUrl, super.key});

  final String snapshotUrl;

  @override
  State<ShoelacePage> createState() => _ShoelacePageState();
}

class _ShoelacePageState extends State<ShoelacePage> {
  late final Stream<LoadState> _stream = watchSnapshot(widget.snapshotUrl);
  int? _focusedIndex;

  void _focus(int? index) => setState(() => _focusedIndex = index);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LoadState>(
      stream: _stream,
      initialData: const CoverageIdle(),
      builder: (context, snap) {
        final state = snap.data ?? const CoverageIdle();
        final width = MediaQuery.of(context).size.width;
        final isCompact = width < AppLayout.compactBreakpoint;
        final loaded = state is CoverageLoaded ? state : null;

        return Scaffold(
          backgroundColor: AppColor.background.color,
          appBar: ShoelaceAppBar(state: state),
          drawer: isCompact && loaded != null
              ? Drawer(
                  backgroundColor: AppColor.background.color,
                  child: SafeArea(
                    child: SidePanel(
                      snapshot: loaded.snapshot,
                      focusedIndex: _focusedIndex,
                      onVariantTap: (i) {
                        _focus(i);
                        Navigator.of(context).maybePop();
                      },
                    ),
                  ),
                )
              : null,
          body: _Body(
            state: state,
            focusedIndex: _focusedIndex,
            onVariantTap: _focus,
            isCompact: isCompact,
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.focusedIndex,
    required this.onVariantTap,
    required this.isCompact,
  });

  final LoadState state;
  final int? focusedIndex;
  final ValueChanged<int?> onVariantTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      CoverageIdle() => StatusMessage(message: UiLabel.initializing.text),
      CoverageLoading(:final path) => StatusMessage(
          message: UiLabel.loadingPrefix.text,
          detail: path,
          spinner: true,
        ),
      CoverageLoaded(:final snapshot) => _LoadedBody(
          snapshot: snapshot,
          focusedIndex: focusedIndex,
          onVariantTap: onVariantTap,
          isCompact: isCompact,
        ),
      CoverageFailed(:final path, :final message) => ErrorMessage(
          path: path,
          message: message,
        ),
    };
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.snapshot,
    required this.focusedIndex,
    required this.onVariantTap,
    required this.isCompact,
  });

  final CoverageSnapshot snapshot;
  final int? focusedIndex;
  final ValueChanged<int?> onVariantTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final canvas = ShoelaceCanvas(
      snapshot: snapshot,
      focusedIndex: focusedIndex,
      onVariantTap: onVariantTap,
    );
    final progress = CoverageProgressBar(snapshot: snapshot);

    if (isCompact) {
      return Column(
        children: [
          Expanded(child: canvas),
          progress,
        ],
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxBodyWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: AppLayout.canvasAreaHeight,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: canvas),
                    SizedBox(
                      width: AppLayout.sidePanelWidth,
                      child: SidePanel(
                        snapshot: snapshot,
                        focusedIndex: focusedIndex,
                        onVariantTap: onVariantTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpacing.sm.px),
            progress,
          ],
        ),
      ),
    );
  }
}

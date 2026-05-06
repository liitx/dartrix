// load_state.dart — sealed state for the snapshot-loading pipeline.
//
// Sealed → exhaustive switch in the renderer. Adding a state without
// updating the switch is a compile error.

import 'coverage.dart';

sealed class LoadState {
  const LoadState();
}

/// Pre-init: no read attempted yet.
final class CoverageIdle extends LoadState {
  const CoverageIdle();
}

/// In-flight read.
final class CoverageLoading extends LoadState {
  const CoverageLoading(this.path);
  final String path;
}

/// Successful decode.
final class CoverageLoaded extends LoadState {
  const CoverageLoaded(this.snapshot, {required this.sourcePath});
  final CoverageSnapshot snapshot;
  final String sourcePath;
}

/// Read failed (file missing, bad JSON, schema mismatch).
final class CoverageFailed extends LoadState {
  const CoverageFailed({
    required this.path,
    required this.message,
    required this.error,
  });

  final String path;
  final String message;
  final Object error;
}

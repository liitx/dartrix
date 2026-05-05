// load_state.dart — sealed state for the JSON-loading pipeline.
//
// Sealed → exhaustive switch in the screen. Adding a state without
// updating the renderer is a compile error.

import 'coverage.dart';

sealed class LoadState {
  const LoadState();
}

/// Pre-init: no read attempted yet.
final class IdleLoad extends LoadState {
  const IdleLoad();
}

/// In-flight read.
final class LoadingCoverage extends LoadState {
  const LoadingCoverage(this.path);
  final String path;
}

/// Successful decode.
final class CoverageLoaded extends LoadState {
  const CoverageLoaded(this.data, {required this.sourcePath});
  final CoverageData data;
  final String sourcePath;
}

/// Read failed (file missing, bad JSON, schema mismatch).
final class CoverageLoadFailed extends LoadState {
  const CoverageLoadFailed({
    required this.path,
    required this.message,
    required this.error,
  });

  final String path;
  final String message;
  final Object error;
}

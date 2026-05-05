// coverage_loader.dart — async JSON file reader, returns a LoadState.
//
// Keeps async-IO details out of the widget tree. The screen subscribes
// to a Stream<LoadState> and re-renders on each emission.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'coverage.dart';
import 'load_state.dart';

/// Default file path zedup writes to.
String defaultCoverageJsonPath() {
  final home = Platform.environment['HOME'] ?? '/tmp';
  return '$home/.zedup/shoelace-coverage.json';
}

/// Loads + decodes the coverage snapshot once.
Future<LoadState> loadCoverageOnce(String path) async {
  try {
    final file = File(path);
    if (!file.existsSync()) {
      return CoverageLoadFailed(
        path: path,
        message: 'File not found. Run zedup and press [s] to generate it.',
        error: const FileSystemException('not found'),
      );
    }
    final raw = await file.readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final data = CoverageData.fromJson(json);
    return CoverageLoaded(data, sourcePath: path);
  } on FormatException catch (e) {
    return CoverageLoadFailed(
      path: path,
      message: 'JSON parse failed: ${e.message}',
      error: e,
    );
  } catch (e) {
    return CoverageLoadFailed(
      path: path,
      message: 'Load failed: $e',
      error: e,
    );
  }
}

/// Watches the file at [path]. Emits an initial [LoadingCoverage], then a
/// terminal [CoverageLoaded] / [CoverageLoadFailed] for each change. Re-runs
/// the load whenever the file is modified.
Stream<LoadState> watchCoverage(String path) async* {
  yield LoadingCoverage(path);
  yield await loadCoverageOnce(path);

  // Watch the parent directory — File.watch doesn't fire on macOS for
  // single-file paths in some cases. Filter events by filename.
  final dir = Directory(File(path).parent.path);
  final filename = File(path).uri.pathSegments.last;
  if (!dir.existsSync()) return;

  await for (final event in dir.watch()) {
    if (event.path.endsWith(filename)) {
      yield LoadingCoverage(path);
      yield await loadCoverageOnce(path);
    }
  }
}

// coverage_loader.dart — fetches the snapshot JSON over HTTP.
//
// On web there's no filesystem access — the JSON is served from the same
// origin as the app by the embedding host (zedup's local HttpServer).

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'coverage.dart';
import 'load_state.dart';

/// Default URL the embedding host serves the snapshot at.
String defaultSnapshotUrl() => '/coverage.json';

/// Loads and decodes the coverage snapshot once.
Future<LoadState> loadSnapshotOnce(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 404) {
      return CoverageFailed(
        path: url,
        message: 'Snapshot missing — run zedup and press [s] to generate it.',
        error: const FormatException('404'),
      );
    }
    if (response.statusCode != 200) {
      return CoverageFailed(
        path: url,
        message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        error: const FormatException('non-200 status'),
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final snapshot = CoverageSnapshot.fromJson(json);
    return CoverageLoaded(snapshot, sourcePath: url);
  } on FormatException catch (e) {
    return CoverageFailed(
      path: url,
      message: 'JSON parse failed: ${e.message}',
      error: e,
    );
  } catch (e) {
    return CoverageFailed(
      path: url,
      message: 'Load failed: $e',
      error: e,
    );
  }
}

/// One-shot stream: emits [CoverageLoading] then a terminal state.
/// Browser reload re-runs the load — there's no filesystem watch on web.
Stream<LoadState> watchSnapshot(String url) async* {
  yield CoverageLoading(url);
  yield await loadSnapshotOnce(url);
}

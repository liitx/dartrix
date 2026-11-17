// verify.dart — a dartrix change is checked against its dependents before it is
// pushed: deprecations first, then analysis, then each dependent's full suite.
//
//   dart run tool/dependents/verify.dart
//
// Each dependent found beside this checkout is copied to a scratch directory,
// pointed at this dartrix by a path override, and put through the steps in
// `VerifyStep` order; the first failure skips the rest. The dependent's own
// checkout is not touched.

import 'dart:io';

import 'package:dartrix/dartrix.dart';

const _deprecationMarker = 'deprecated_member_use';

Set<String> _deprecationLines(ProcessResult analysis) => {
      for (final line in '${analysis.stdout}'.split('\n'))
        if (line.contains(_deprecationMarker)) line.trim(),
    };

Future<ProcessResult> _run(String dir, String exe, List<String> args) =>
    Process.run(exe, args, workingDirectory: dir);

Future<Map<VerifyStep, StepOutcome>> _verify(Dependent dependent) async {
  final source = Directory('../${dependent.directoryName}').absolute.path;
  final scratch = Directory.systemTemp
      .createTempSync('dartrix_verify_${dependent.name}_')
      .path;
  await Process.run('rsync', [
    '-a', '--exclude=.git', '--exclude=.dart_tool', '--exclude=build', '--exclude=pubspec_overrides.yaml',
    '$source/', scratch,
  ]);
  // Some suites run git in their own repository, so the copy is one.
  await _run(scratch, 'git', ['init', '-q']);
  // Deprecations the dependent already has (another package's) are not dartrix's:
  // only a deprecation that appears once dartrix is the local one counts.
  await _run(scratch, 'dart', ['pub', 'get']);
  final before = _deprecationLines(await _run(scratch, 'dart', ['analyze']));
  File('$scratch/pubspec_overrides.yaml').writeAsStringSync(
    'dependency_overrides:\n  dartrix:\n    path: ${Directory.current.absolute.path}\n',
  );
  final got = await _run(scratch, 'dart', ['pub', 'get']);
  final analysis = await _run(scratch, 'dart', ['analyze']);
  final passed = <VerifyStep, bool>{
    VerifyStep.deprecations: got.exitCode == 0 &&
        _deprecationLines(analysis).difference(before).isEmpty,
    VerifyStep.analyze: got.exitCode == 0 && !'${analysis.stdout}'.contains(' error - '),
  };
  if (passed[VerifyStep.deprecations]! && passed[VerifyStep.analyze]!) {
    final tests = await _run(scratch, 'dart', ['test']);
    passed[VerifyStep.test] = tests.exitCode == 0;
  }
  Directory(scratch).deleteSync(recursive: true);
  return outcomesInOrder(passed);
}

Future<void> main() async {
  var allReady = true;
  for (final dependent in Dependent.values) {
    if (!Directory('../${dependent.directoryName}').existsSync()) {
      stdout.writeln('${dependent.name}: checkout not found, check by hand');
      allReady = false;
      continue;
    }
    final outcomes = await _verify(dependent);
    allReady = allReady && readyToPush(outcomes);
    stdout.writeln('${dependent.name}: ${[
      for (final step in VerifyStep.values) '${step.name} ${outcomes[step]!.name}'
    ].join(', ')}');
  }
  stdout.writeln(allReady ? 'ready to push' : 'not ready to push');
  exitCode = allReady ? 0 : 1;
}

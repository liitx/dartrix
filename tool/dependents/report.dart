// report.dart — what each dependent of dartrix has to do for dartrix's current commit.
//
//   dart run tool/dependents/report.dart
//
// Reads each dependent's pubspec.yaml from the checkout beside this one and
// prints the section a dartrix PR carries ("Dependents to update").

import 'dart:io';

import 'package:dartrix/dartrix.dart';

void main() {
  final head = Process.runSync('git', ['rev-parse', 'HEAD']).stdout as String;
  final pubspecTexts = <Dependent, String>{};
  for (final dependent in Dependent.values) {
    final file = File('../${dependent.directoryName}/pubspec.yaml');
    if (file.existsSync()) pubspecTexts[dependent] = file.readAsStringSync();
  }
  stdout.write(renderDependentsReport(
    headRef: head.trim(),
    pubspecTexts: pubspecTexts,
  ));
}

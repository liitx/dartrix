// main.dart — dartrix_shoelace entry point.
//
// Reads the coverage snapshot from the path given on the command line,
// or falls back to the default location written by zedup's [s] launcher.

import 'package:flutter/material.dart';

import 'src/coverage_loader.dart';
import 'src/shoelace_app.dart';

void main(List<String> args) {
  final path = switch (args) {
    [final first, ...] => first,
    _ => defaultCoverageJsonPath(),
  };
  runApp(ShoelaceApp(coverageJsonPath: path));
}

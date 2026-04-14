// dartrix — enum-driven test matrix framework
//
// Ensures complete coverage of every enum variant across every feature,
// component, helper, and class in a Dart app. No redundancy. No gaps.
//
// Usage:
//   import 'package:dartrix/dartrix.dart';
//
// Define your app's type hierarchy as enhanced enums implementing AppType.
// Each domain enum declares which features it participates in.
// The matrix derives coverage from the cross-product and surfaces gaps.

export 'src/types/app_type.dart';
export 'src/types/feature_type.dart';
export 'src/types/component_type.dart';
export 'src/types/helper_type.dart';
export 'src/types/class_type.dart';
export 'src/matrix/matrix.dart';
export 'src/renderer/matrix_renderer.dart';
export 'src/selector/selector.dart';
export 'src/selector/test_selector.dart';

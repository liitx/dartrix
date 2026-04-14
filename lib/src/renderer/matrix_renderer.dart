// matrix_renderer.dart — terminal and string output for Dartrix
//
// Renders the coverage matrix as:
//   - terminal table (for dart test output and CLI)
//   - plain string (for HTML generation or logging)
//
// Symbols:
//   ✓  covered
//   ✗  gap — missing test
//   ·  not applicable — variant does not participate in this feature

import '../matrix/matrix.dart';
import '../types/app_type.dart';
import '../types/feature_type.dart';

extension _AppTypeName on AppType {
  String get name => (this as Enum).name;
}

extension _FeatureTypeName on FeatureType {
  String get name => (this as Enum).name;
}

class MatrixRenderer {
  const MatrixRenderer(this.matrix);

  final Dartrix matrix;

  /// Renders the matrix as a plain-text table.
  ///
  ///   Feature:    dashboard  newBranch  promote
  ///   wip             ✓         ✓         ✓
  ///   inReview        ✓         ·         ·
  ///   blocked         ✗         ·         ·
  String render() {
    final features = matrix.features;
    final variants = matrix.variants;

    final variantWidth = variants.map((v) => v.name.length).reduce((a, b) => a > b ? a : b) + 2;
    final colWidth = features.map((f) => f.name.length).reduce((a, b) => a > b ? a : b) + 2;

    final header = 'Feature:'.padRight(variantWidth) +
        features.map((f) => f.name.padRight(colWidth)).join();

    final rows = variants.map((variant) {
      final cells = features.map((feature) {
        final symbol = switch (matrix.stateOf(variant, feature)) {
          CellState.covered       => '✓',
          CellState.gap           => '✗',
          CellState.notApplicable => '·',
        };
        return symbol.padRight(colWidth);
      }).join();
      return variant.name.padRight(variantWidth) + cells;
    }).join('\n');

    return '$header\n$rows';
  }

  /// Renders only the gaps — for test failure output.
  ///
  ///   GAPS (2):
  ///     WorkStatus.blocked  ×  dashboard
  ///     WorkStatus.done     ×  dashboard
  String renderGaps() {
    final gaps = matrix.gaps();
    if (gaps.isEmpty) return 'No gaps — all variants covered.';
    final lines = gaps.map((c) => '  ${c.variant.name}  ×  ${c.feature.name}');
    return 'GAPS (${gaps.length}):\n${lines.join('\n')}';
  }
}

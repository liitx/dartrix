// matrix_renderer_test.dart — MatrixRenderer.render column layout
//
// Each column is as wide as the longest name in it plus two spaces (the
// renderer's own doc comment: names padded so the table lines up). The expected
// tables below are written out by hand from that rule, never built with the
// same padding call the renderer uses, so a wrong width fails.

import 'package:dartrix/dartrix.dart';
import 'package:test/test.dart';

enum _Feature implements FeatureType {
  dashboard('Dashboard'),
  promote('Promote');

  const _Feature(this.description);

  @override
  final String description;
}

enum _Status implements AppType {
  wip,
  inReview;

  @override
  String get description => name;

  @override
  Set<FeatureType> get features => switch (this) {
        _Status.wip      => {_Feature.dashboard, _Feature.promote},
        _Status.inReview => {_Feature.dashboard},
      };
}

void main() {
  group('MatrixRenderer.render', () {
    late Dartrix matrix;
    late MatrixRenderer renderer;

    setUp(() {
      matrix = Dartrix(axes: [_Status.values], features: _Feature.values);
      renderer = MatrixRenderer(matrix);
    });

    // Longest variant: inReview (8) + 2 = 10. Longest feature: dashboard (9) + 2
    // = 11. Gap ✗, not applicable ·.
    test('pads each name to its longest plus two, with every cell a gap', () {
      expect(
        renderer.render(),
        'Feature:  dashboard  promote    \n'
        'wip       ✗          ✗          \n'
        'inReview  ✗          ·          ',
      );
    });

    test('shows a covered cell as ✓ in the same column', () {
      matrix.cover(_Status.wip, _Feature.promote);
      expect(
        renderer.render(),
        'Feature:  dashboard  promote    \n'
        'wip       ✗          ✓          \n'
        'inReview  ✗          ·          ',
      );
    });
  });
}

// test_selector.dart — testSelector() wraps test() with automatic coverage
//
// Replaces manual matrix.cover() calls scattered in test bodies.
// Coverage registration is structural — it happens after body() completes,
// unconditionally, as part of the selector contract.
//
// The generic S parameter preserves the concrete selector type so the body
// receives the full selector (including app-specific input getters) without
// requiring a cast.
//
// Usage:
//   testSelector(matrix, BranchStatusSelector(WorkStatus.inReview), (sel) {
//     expect(
//       feature(branches: [sel.branchItem], prompt: scripted(['1', 'q'])).run(),
//       equals(ListFlowState.cancelled),
//     );
//   });
//
// Equivalent to:
//   test(selector.description, () {
//     // body ...
//     matrix.cover(selector.variant, selector.feature);
//   });

import 'package:test/test.dart';

import '../matrix/matrix.dart';
import 'selector.dart';

/// Wraps [test] with automatic [Dartrix.cover] registration.
///
/// [S] is the concrete selector type — the body receives it directly,
/// preserving access to all fixture-derived input getters without casting.
void testSelector<S extends DartrixSelector>(
  Dartrix matrix,
  S selector,
  void Function(S selector) body,
) {
  test(selector.description, () {
    body(selector);
    matrix.cover(selector.variant, selector.feature);
  });
}

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
// Both sync and async bodies are supported via FutureOr<void>:
//
//   // sync
//   testSelector(matrix, status.getSelector(AppFeature.dashboard), (sel) {
//     expect(sel.variant.label, isNotEmpty);
//   });
//
//   // async
//   testSelector(matrix, status.getSelector(AppFeature.dashboard), (sel) async {
//     final result = await fetch(sel.variant);
//     expect(result, isNotEmpty);
//   });
//
// Equivalent to:
//   test(selector.description, () async {
//     // body ...
//     matrix.cover(selector.variant, selector.feature);
//   });

import 'dart:async';

import 'package:test/test.dart';

import '../matrix/matrix.dart';
import 'selector.dart';

/// Wraps [test] with automatic [Dartrix.cover] registration.
///
/// [S] is the concrete selector type — the body receives it directly,
/// preserving access to all fixture-derived input getters without casting.
///
/// Both sync and async bodies are supported. Coverage registers only after
/// the body completes — a failing async body never appears covered.
void testSelector<S extends DartrixSelector>(
  Dartrix matrix,
  S selector,
  FutureOr<void> Function(S selector) body,
) {
  test(selector.description, () async {
    await body(selector);
    matrix.cover(selector.variant, selector.feature);
  });
}

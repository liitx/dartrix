// gap_cross_reference_test.dart — GapCrossReference contract per
// CrossReferenceStrategy variant.
//
// Strict matrix-driven paradigm. The dartrix data layer is stringly-typed
// by design (no zedup enum dependency), so test inputs flow through
// typed locals (_TestVariant, _TestFeature) and a single builder. Bare
// strings appear only inside enum value declarations and the builder —
// never in test bodies.

import 'dart:convert';

import 'package:dartrix/dartrix.dart';
import 'package:test/test.dart';

// ── Typed test inputs ────────────────────────────────────────────────────────

/// Test-only enum mirroring the qualified variant names dartrix expects
/// from zedup's emitter. Keeps every bare-string declaration on one line
/// per variant and forces tests to iterate over `.values` instead of
/// retyping the qualified name.
enum _TestVariant {
  branchFeat('BranchType.feat'),
  branchChore('BranchType.chore');

  const _TestVariant(this.qualifiedName);
  final String qualifiedName;
}

/// Feature names tests reference. Used both for `feature` fields and for
/// composing file paths so the soft-match heuristic has a deterministic
/// target. `_TestFeature.name` is the wire string.
enum _TestFeature {
  newBranch,
  promote,
  unrelated,
}

({_TestVariant variant, _TestFeature feature}) _gap(
  _TestVariant variant,
  _TestFeature feature,
) =>
    (variant: variant, feature: feature);

({_TestVariant variant, _TestFeature dir, int line}) _usage(
  _TestVariant variant,
  _TestFeature dir, {
  int line = 1,
}) =>
    (variant: variant, dir: dir, line: line);

/// Builds a v3 shoelace snapshot payload from typed inputs. Centralizes
/// every wire-string concern: schema, file-path shape, JSON encoding.
String _snapshot({
  required List<({_TestVariant variant, _TestFeature feature})> gaps,
  required List<({_TestVariant variant, _TestFeature dir, int line})> usages,
}) =>
    jsonEncode({
      'schema': ShoelaceSchema.v3.wireValue,
      'gaps': [
        for (final g in gaps)
          {'variant': g.variant.qualifiedName, 'feature': g.feature.name},
      ],
      'usages': [
        for (final u in usages)
          {
            'variant': u.variant.qualifiedName,
            'file': 'lib/src/features/${u.dir.name}/handler.dart',
            'line': u.line,
          },
      ],
    });

SnapshotGap _toSnapshotGap(({_TestVariant variant, _TestFeature feature}) g) =>
    SnapshotGap(variant: g.variant.qualifiedName, feature: g.feature.name);

// ── Fixture: one snapshot/gap pair per CrossReferenceStrategy variant ────────

extension CrossReferenceStrategyFixture on CrossReferenceStrategy {
  String get expectedLabel => switch (this) {
        CrossReferenceStrategy.softMatch   => 'File-path soft match',
        CrossReferenceStrategy.variantOnly => 'All usages of variant',
        CrossReferenceStrategy.empty       => 'No usages found',
      };

  ({ShoelaceSnapshot snapshot, SnapshotGap gap}) get fixtureCase {
    return switch (this) {
      // softMatch: variant has usages, at least one file path contains
      // the feature name.
      CrossReferenceStrategy.softMatch => () {
          final gap = _gap(_TestVariant.branchFeat, _TestFeature.newBranch);
          return (
            snapshot: ShoelaceSnapshot.parse(_snapshot(
              gaps: [gap],
              usages: [
                _usage(_TestVariant.branchFeat, _TestFeature.newBranch, line: 42),
                _usage(_TestVariant.branchFeat, _TestFeature.unrelated),
              ],
            )),
            gap: _toSnapshotGap(gap),
          );
        }(),
      // variantOnly: variant has usages but none match the feature name.
      CrossReferenceStrategy.variantOnly => () {
          final gap = _gap(_TestVariant.branchFeat, _TestFeature.promote);
          return (
            snapshot: ShoelaceSnapshot.parse(_snapshot(
              gaps: [gap],
              usages: [
                _usage(_TestVariant.branchFeat, _TestFeature.unrelated),
              ],
            )),
            gap: _toSnapshotGap(gap),
          );
        }(),
      // empty: variant has no usages anywhere.
      CrossReferenceStrategy.empty => () {
          final gap = _gap(_TestVariant.branchChore, _TestFeature.newBranch);
          return (
            snapshot: ShoelaceSnapshot.parse(_snapshot(
              gaps: [gap],
              usages: [
                _usage(_TestVariant.branchFeat, _TestFeature.unrelated),
              ],
            )),
            gap: _toSnapshotGap(gap),
          );
        }(),
    };
  }

  int get expectedUsageCount => switch (this) {
        CrossReferenceStrategy.softMatch   => 1,
        CrossReferenceStrategy.variantOnly => 1,
        CrossReferenceStrategy.empty       => 0,
      };
}

void main() {
  group('GapCrossReference.strategy classifies fixture cases correctly', () {
    for (final strategy in CrossReferenceStrategy.values) {
      test(strategy.name, () {
        final c = strategy.fixtureCase;
        final result = c.snapshot.crossReferenceFor(c.gap);
        expect(result.strategy, equals(strategy));
      });
    }
  });

  group('GapCrossReference.usages count matches strategy expectations', () {
    for (final strategy in CrossReferenceStrategy.values) {
      test(strategy.name, () {
        final c = strategy.fixtureCase;
        final result = c.snapshot.crossReferenceFor(c.gap);
        expect(result.usages.length, equals(strategy.expectedUsageCount));
      });
    }
  });

  group('CrossReferenceStrategy.label', () {
    for (final strategy in CrossReferenceStrategy.values) {
      test(strategy.name, () {
        expect(strategy.label, equals(strategy.expectedLabel));
      });
    }
  });

  group('GapCrossReference.gap echoes the queried gap', () {
    for (final strategy in CrossReferenceStrategy.values) {
      test(strategy.name, () {
        final c = strategy.fixtureCase;
        final result = c.snapshot.crossReferenceFor(c.gap);
        expect(result.gap.variant, equals(c.gap.variant));
        expect(result.gap.feature, equals(c.gap.feature));
      });
    }
  });

  test('softMatch strategy returns only usages whose file contains the feature name', () {
    final c = CrossReferenceStrategy.softMatch.fixtureCase;
    final result = c.snapshot.crossReferenceFor(c.gap);
    expect(result.strategy, equals(CrossReferenceStrategy.softMatch));
    for (final u in result.usages) {
      expect(u.file, contains(c.gap.feature));
    }
  });

  test('variantOnly strategy returns ALL usages of the variant', () {
    final c = CrossReferenceStrategy.variantOnly.fixtureCase;
    final result = c.snapshot.crossReferenceFor(c.gap);
    final allVariantUsages =
        c.snapshot.usages.where((u) => u.variant == c.gap.variant).toList();
    expect(result.usages.length, equals(allVariantUsages.length));
  });
}

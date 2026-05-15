// gap_cross_reference_test.dart — GapCrossReference contract per
// CrossReferenceStrategy variant.
//
// Strict matrix-driven paradigm:
//   - One fixture per CrossReferenceStrategy returning a snapshot + gap
//     that *should* yield that strategy.
//   - Generic body asserts `crossReferenceFor(gap).strategy == variant`
//     and checks the rows shape matches the strategy's contract.
//
// No bare-string test names for the strategy axis; variant identity is
// the row identity.

import 'dart:convert';

import 'package:dartrix/dartrix.dart';
import 'package:test/test.dart';

// ── Fixture: one snapshot/gap pair per CrossReferenceStrategy variant ────────

extension CrossReferenceStrategyFixture on CrossReferenceStrategy {
  /// Expected human-readable label for the detail panel footer.
  String get expectedLabel => switch (this) {
        CrossReferenceStrategy.softMatch   => 'File-path soft match',
        CrossReferenceStrategy.variantOnly => 'All usages of variant',
        CrossReferenceStrategy.empty       => 'No usages found',
      };

  /// Returns (snapshot, gap) tuned to produce this strategy when run.
  /// The body of every cross-reference test uses this — no bespoke
  /// per-strategy test setup, just per-strategy fixture data.
  ({ShoelaceSnapshot snapshot, SnapshotGap gap}) get fixtureCase {
    return switch (this) {
      // softMatch: variant has usages, at least one file path contains
      // the feature name.
      CrossReferenceStrategy.softMatch => (
          snapshot: ShoelaceSnapshot.parse(jsonEncode({
            'schema': 'zedup-shoelace/v3',
            'gaps': [
              {'variant': 'BranchType.feat', 'feature': 'newBranch'},
            ],
            'usages': [
              {
                'variant': 'BranchType.feat',
                'file': 'lib/src/features/newBranch/handler.dart',
                'line': 42,
              },
              {
                'variant': 'BranchType.feat',
                'file': 'lib/src/features/unrelated/x.dart',
                'line': 1,
              },
            ],
          })),
          gap: const SnapshotGap(
              variant: 'BranchType.feat', feature: 'newBranch'),
        ),
      // variantOnly: variant has usages but none match the feature name.
      CrossReferenceStrategy.variantOnly => (
          snapshot: ShoelaceSnapshot.parse(jsonEncode({
            'schema': 'zedup-shoelace/v3',
            'gaps': [
              {'variant': 'BranchType.feat', 'feature': 'promote'},
            ],
            'usages': [
              {
                'variant': 'BranchType.feat',
                'file': 'lib/src/random/file.dart',
                'line': 1,
              },
            ],
          })),
          gap: const SnapshotGap(
              variant: 'BranchType.feat', feature: 'promote'),
        ),
      // empty: variant has no usages anywhere.
      CrossReferenceStrategy.empty => (
          snapshot: ShoelaceSnapshot.parse(jsonEncode({
            'schema': 'zedup-shoelace/v3',
            'gaps': [
              {'variant': 'BranchType.chore', 'feature': 'newBranch'},
            ],
            'usages': [
              // No usages for BranchType.chore — empty path triggers.
              {
                'variant': 'BranchType.feat',
                'file': 'lib/x.dart',
                'line': 1,
              },
            ],
          })),
          gap: const SnapshotGap(
              variant: 'BranchType.chore', feature: 'newBranch'),
        ),
    };
  }

  /// Expected number of usage rows the cross-reference should return.
  int get expectedUsageCount => switch (this) {
        CrossReferenceStrategy.softMatch   => 1,
        CrossReferenceStrategy.variantOnly => 1,
        CrossReferenceStrategy.empty       => 0,
      };
}

void main() {
  // ── Matrix row 1: strategy classification ────────────────────────────────
  // Every CrossReferenceStrategy variant must be reachable. The fixture
  // case for the variant is tuned to produce that variant; if the heuristic
  // ever changes and a case no longer produces its declared strategy, this
  // group fails per-variant.

  group('GapCrossReference.strategy classifies fixture cases correctly', () {
    for (final strategy in CrossReferenceStrategy.values) {
      test(strategy.name, () {
        final c = strategy.fixtureCase;
        final result = c.snapshot.crossReferenceFor(c.gap);
        expect(result.strategy, equals(strategy));
      });
    }
  });

  // ── Matrix row 2: row count per strategy ─────────────────────────────────

  group('GapCrossReference.usages count matches strategy expectations', () {
    for (final strategy in CrossReferenceStrategy.values) {
      test(strategy.name, () {
        final c = strategy.fixtureCase;
        final result = c.snapshot.crossReferenceFor(c.gap);
        expect(result.usages.length, equals(strategy.expectedUsageCount));
      });
    }
  });

  // ── Matrix row 3: strategy.label has expected text ───────────────────────

  group('CrossReferenceStrategy.label', () {
    for (final strategy in CrossReferenceStrategy.values) {
      test(strategy.name, () {
        expect(strategy.label, equals(strategy.expectedLabel));
      });
    }
  });

  // ── Matrix row 4: result.gap round-trips the input gap ──────────────────

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

  // ── Soft-match specifics: only soft-matched rows survive ─────────────────
  // This is a behavior-level assertion that the soft-match strategy
  // actually filters by file path — beyond just claiming the strategy.

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

# Changelog

All notable changes to dartrix are documented here.
Each entry maps 1:1 to a GitHub issue and a package version bump.

---

## [Unreleased]

### Added — shoelace Flutter visualizer (under `shoelace/`)

**Per-vertex region geometry, hit testing, drilldown panel.**
- New `shoelace/lib/src/region_geometry.dart` — pure function `regionPathsFor(...)` returns `Map<int, Path>` per variant index. Painter and canvas hit-testing both consume it (single source of truth, neither widget owns the geometry).
- `shoelace/lib/src/shoelace_painter.dart` — apex-triangle for interior lace-path vertices, rim lune for endpoints. Together they tile the disc. Region color = apex variant color; alpha = `coverageRatio`. Disc gets a soft radial gradient under regions for inner-depth feel. Chord glow halo when fully covered.
- `shoelace/lib/src/shoelace_canvas.dart` — `GestureDetector` wraps the inner Stack so `localPosition` aligns with painter coordinates. Hit-tests `regionPathsFor`; first match calls `onVariantTap(index)`, miss calls `onVariantTap(null)`.
- `shoelace/lib/src/shoelace_page.dart` — single Scaffold with proper slot ownership (appBar, body, drawer for compact viewports). `_focusedIndex` typed `int?`; default `null` so overview is the first paint.
- `shoelace/lib/src/side_panel.dart` — split into overview mode and detail mode keyed off `focusedIndex`. Detail renders three reusable section components: `_UsagesList` (file:line + class.method), `_TestsList` (file:line + group breadcrumb), `_GapsList` (feature + GAP badge).

**Schema v2 — drilldown context (additive, backward-compatible).**
- `shoelace/lib/src/coverage.dart` — `CoverageSchema += v2`. `UsageInfo += nullable containingClass, containingMethod`. `TestInfo += nullable containingGroup` (full group ancestry breadcrumb, joined " / ").
- Field-tolerant parsing: `fromJson` reads new fields unconditionally as nullable strings regardless of schema version. v1 payloads still parse, v2 payloads with missing fields default to null, v1 with unexpected fields does not crash.
- `shoelace/test/coverage_test.dart` — added v2 round-trip group: schema parse, scope-field reading, field tolerance on missing v2 fields, v1 backward compatibility.

**Centralized theming.**
- `shoelace/lib/src/ui/tokens.dart` — `AppColor`, `UiLabel`, `AppSpacing`, `AppText`, `AppLayout`, `AppPaint`. Single file, exhaustive enums for chrome strings + colors; `AppPaint` class for every painter visual knob (region alphas, chord strokes/glow, vertex sizing/halo, focus ring, guide ring, disc gradient stops).
- `shoelace/lib/src/ui/app_theme.dart` — ThemeData construction reads from tokens.
- `AppColor.emphasis` token replaces scattered `Colors.white` literals.

**Naming pass throughout shoelace.**
- `CoverageData` → `CoverageSnapshot`. `coverageRatio` getter → `averageCoverage`. `statusOf({String, String})` → `cellStatus({VariantInfo, String})`.
- `LoadState` subclasses standardized: `CoverageIdle`, `CoverageLoading`, `CoverageLoaded`, `CoverageFailed`.
- `coverageJsonUrl` → `snapshotUrl`; `loadCoverageOnce` → `loadSnapshotOnce`; `watchCoverage` → `watchSnapshot`.
- Painter / canvas params expanded: `vertexCount`, `centerX/Y`, `apexIndex`, `prevIndex`, `nextIndex`, `fromAngle`, `toAngle`, `discBounds`, `discRadius`, `lacePosition`, `clockwiseSweep`.
- `SegmentStatus.tested` → `SegmentStatus.covered` (matches dartrix `CellState`).

**Shoelace web shell.**
- main.dart contains `MaterialApp` directly (no wrapper widget).
- web/ directory tracked: index.html, manifest.json, favicon, icons.
- web/coverage.json gitignored (developer symlink to `~/.zedup/shoelace-coverage.json`).

### Added — dartrix package

- `ShoelaceLayout`, `ShoelaceNode`, `ShoelaceSegment`, `shoelaceLayoutOf` — pure-data shoelace coverage geometry primitive. Variants placed on a unit circle as nodes; N-1 segments along the continuous lacing path. No rendering, no Flutter, no usage registry. Multi-axis matrices supported by calling once per enum. Lenient on degenerate sizes (N ∈ {0, 1, 2}).
- `testSelector()` now accepts async bodies — `FutureOr<void> Function(S)` replaces `void Function(S)`. Existing sync bodies are unaffected. Coverage registers only after the body resolves — a failing async body never appears covered.

### Fixed
- `Dartrix`, `MatrixRenderer`, and `testSelector()` now validated by dartrix's own test suite. Added `test/matrix/matrix_test.dart` and `test/stubs.dart`; wired `test/selector/selector_test.dart` to a live `Dartrix` instance with `tearDownAll` gap enforcement. 29 tests.
- `test/matrix/matrix_test.dart`: two renderer tests collapsed `TestType.values` and `TestFeature.values` into single test bodies. Split into one `test()` per value — failure now identifies the specific variant. (#14)

### Planned
See [PLAN.md — The 6-phase roadmap](PLAN.md#the-6-phase-roadmap) for the active roadmap. High-level:
- Phase 1 — Gap cross-reference (dartrix shoelace): each gap row enriched with cross-referenced usage locations.
- Phase 2 — Test status integration (cross-repo, schema v3): `TestStatus` enum (passing / failing / error), three-state region rendering.
- Phase 3 — `[t]` TUI screen + template system (zedup): typed templates per project (dc-flutter, generic), define pickers, replace `open coverage/index.html` with shoelace.
- Phase 4 — Test runner cache + diff-aware re-runs (zedup): `~/.zedup/test-cache/`, 5hr max-age, coarse `pubspec.lock` invalidation.
- Phase 5 — GUI design subagent (claudart): planner delegates visual-design work to a specialized agent.
- Phase 6 — Cleanup audit (post-merge, all repos).

---

## [0.1.2] — 2026-04-13

### Added
- `DartrixSelector` — abstract interface carrying `variant`, `feature`, and
  `description` for a single matrix test. Consumer apps implement this and
  add fixture-derived input getters. (#5)
- `testSelector<S>()` — wraps `test()` and registers `matrix.cover()`
  automatically after the body runs. The generic `S` preserves the concrete
  selector type — no cast needed in the test body. (#5)
- `TypedSelector<V>` — concrete `DartrixSelector` where `variant` is preserved
  as its concrete `AppType` subtype `V`. Created via `AppType.getSelector()` —
  never constructed directly. (#6)
- `AppTypeGetSelector.getSelector(feature)` — extension on any `AppType` variant.
  Returns `TypedSelector<V>` so the test body reads `sel.variant` as the concrete
  enum type without casting. Replaces explicit `DartrixSelector` subclasses. (#6)
- `test` moved from `dev_dependencies` to `dependencies` — consumers get
  `testSelector()` transitively. (#5)

### Context
APIs proven in zedup before landing here. `TypedSelector<V>` superseded 8 explicit
`DartrixSelector` subclasses — no boilerplate selector class needed; `sel.variant`
is already the concrete enum type. See zedup `retired/selectors_retired.md`.

---

## [0.1.1] — 2026-04-13

### Changed
- Renamed `DartrixMatrix` → `Dartrix` — the package name is the class name.
  `new Dartrix(axes: ..., features: ...)` reads cleanly; `Matrix` suffix was
  redundant. (#4)

---

## [0.1.0] — 2026-04-13

### Added
- `Dartrix` — coverage matrix class. Takes `axes` (domain enum value lists)
  and `features`. Tracks `cover()` calls, derives `gaps()`, returns
  `stateOf()` per cell. (#1)
- `CellState` — `covered`, `gap`, `notApplicable`. (#1)
- `MatrixCell` — `({AppType variant, FeatureType feature})` typedef. (#1)
- `MatrixRenderer` — `render()` prints full table (✓ ✗ ·); `renderGaps()`
  prints named gap list for test failure output. (#2)
- Type hierarchy marker interfaces: `AppType`, `FeatureType`, `ComponentType`,
  `HelperType`, `ClassType`. (#3)
  - `AppType` — domain enum variants; declares `features` getter with
    exhaustive switch (compile error on new variant without update).
  - `FeatureType`, `ComponentType`, `HelperType`, `ClassType` — marker
    interfaces for app registration and matrix documentation.

### Context
Initial scaffold. Extracted from zedup's test architecture — the enum-driven
coverage model was proven there before dartrix existed as a standalone package.
`Dartrix` was originally named `DartrixMatrix`; renamed in 0.1.1.

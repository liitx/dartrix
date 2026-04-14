# Changelog

All notable changes to dartrix are documented here.
Each entry maps 1:1 to a GitHub issue and a package version bump.

---

## [Unreleased]

### Planned
- `testSelectorGroup()` — group wrapper for selector loops (#8)
- `coverAll(variants, feature)` — bulk coverage convenience (#7)
- `DartrixCubit` adapter template (#9)
- `DartrixBloc` adapter template (#10)
- `DartrixRiverpod` adapter template (#11)
- `DartrixIsolate` adapter template (#12)
- Publish to pub.dev (#13)

---

## [0.1.2] — 2026-04-13

### Added
- `DartrixSelector` — abstract interface carrying `variant`, `feature`, and
  `description` for a single matrix test. Consumer apps implement this and
  add fixture-derived input getters. (#5)
- `testSelector<S>()` — wraps `test()` and registers `matrix.cover()`
  automatically after the body runs. The generic `S` preserves the concrete
  selector type — no cast needed in the test body. (#5)
- `test` moved from `dev_dependencies` to `dependencies` — consumers get
  `testSelector()` transitively. (#5)

### Context
API proven in zedup (`BranchStatusSelector` × `ZedFeature.dashboard`) before
landing here. Pattern: implement `DartrixSelector` in the consumer app,
validate the signature works end-to-end, then promote to dartrix.

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

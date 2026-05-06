# dartrix

**Enum-driven test matrix framework for Dart.**

dartrix turns your domain enums into a living coverage contract. Every variant declares which features it participates in via an exhaustive switch — adding a new variant without updating that switch is a **compile error**, not a missing test discovered at 2am.

The framework ships with **shoelace** — a Flutter web visualizer that renders coverage as a fractal disc. Click any region to drill into per-variant detail: usages, tests, gaps with file:line + class.method + group breadcrumb context.

> **Deep dive:** [PLAN.md](PLAN.md) is the master roadmap. It carries the mathematics, the fractal hierarchy, the schema contract, the 6-phase roadmap, the proof-by-example template, and the project-templating pattern. This README is a curated entry point.

---

## The problem

You have a `Status` enum:

```dart
enum Status { draft, published, archived }
```

And a `dashboard` feature that renders each status differently. You write tests for `draft` and `published`, ship, and later add `archived`. The tests still pass. The dashboard silently renders nothing for archived items.

dartrix makes that silent gap impossible.

> Read more: [Coverage is emphatic](PLAN.md#coverage-is-emphatic) — what makes structural cell coverage different from line coverage.

---

## How it works — the matrix in 60 seconds

<details>
<summary><strong>Click to expand — minimal end-to-end example</strong></summary>

**1. Define your features.**

```dart
enum AppFeature implements FeatureType {
  dashboard('Main content dashboard'),
  editor('Rich text editor'),
  export('PDF / CSV export');

  const AppFeature(this.description);
  @override final String description;
}
```

**2. Make your domain enums declare participation.**

```dart
enum Status implements AppType {
  draft, published, archived, deleted;

  @override String get description => name;

  @override Set<FeatureType> get features => switch (this) {
    Status.draft     => {AppFeature.dashboard, AppFeature.editor},
    Status.published => {AppFeature.dashboard, AppFeature.export},
    Status.archived  => {AppFeature.dashboard},
    Status.deleted   => {},
  };
}
```

Add `Status.suspended` later and forget the switch? **Compile error.** The exhaustive switch is the contract.

**3. Wire the matrix in your test main.**

```dart
final matrix = Dartrix(axes: [Status.values], features: AppFeature.values);

for (final status in Status.values) {
  if (status.features.contains(AppFeature.dashboard)) {
    testSelector(matrix, status.getSelector(AppFeature.dashboard), (sel) {
      // ... assert dashboard renders status correctly ...
    });
  }
}

tearDownAll(() {
  if (matrix.gaps().isNotEmpty) fail(MatrixRenderer(matrix).renderGaps());
});
```

**4. Read the gap output.**

```
GAPS (3):
  Status.published × editor
  Status.archived  × export
  Status.archived  × editor
```

Specific cells. Not "76% line coverage." Each row is a `(variant, feature)` pair you can fix.

</details>

> **Full walkthrough:** [Proof by example](PLAN.md#proof-by-example) in PLAN.md walks a TODO app through compile-time enforcement → gap surfaced → drilldown → test added → coverage closes.

---

## The shoelace visualizer

The Flutter web app under [`shoelace/`](shoelace/) consumes the JSON snapshot any consumer (zedup, dc-flutter, your app) emits. It renders the matrix as a disc — each variant a region, region color the variant's color, region opacity proportional to coverage.

```
Disc → click a region → detail panel
       ↓
       Usages   (file:line + class.method)
       Tests    (file:line + group breadcrumb)
       Gaps     (feature + GAP badge + cross-referenced usages)
```

Each click drills one level deeper. The hierarchy descends broad → narrow:

| Level | What you see                              | Click target              |
|-------|-------------------------------------------|---------------------------|
| 0     | One node per AppType enum (planned, P3+)  | Click → enter that enum   |
| 1     | One node per variant of focused enum      | Click → focus that variant|
| 2     | Detail panel — usages, tests, gaps        | Click usage → sub-circle  |
| 3     | Sub-circle: per-call-site (planned)       | Click site → leaf         |
| 4     | Leaf: file:line preview (planned)         | Open in editor            |

> **Deep dive:** [The fractal hierarchy](PLAN.md#the-fractal-hierarchy) maps each level to its marker interface and explains the recursive geometry.

---

## Public API

| Type                      | Role                                                                       |
|---------------------------|----------------------------------------------------------------------------|
| `Dartrix`                 | The matrix. `axes`, `features`, `cover()`, `gaps()`, `stateOf()`           |
| `MatrixCell`              | `({AppType variant, FeatureType feature})` typedef                         |
| `CellState`               | `covered` / `gap` / `notApplicable`                                        |
| `MatrixRenderer`          | `render()` table + `renderGaps()` failure output                           |
| `AppType`                 | Marker interface for domain enums; declares `features` getter              |
| `FeatureType`             | Marker interface for feature axis enums                                    |
| `ClassType`, `HelperType`, `ComponentType` | Markers for Level 3 sub-circle node types (planned)        |
| `DartrixMethod`           | Marker for Level 4 method classification (planned)                         |
| `DartrixSelector`         | Abstract: `variant`, `feature`, `description`                              |
| `TypedSelector<V>`        | Concrete selector preserving variant subtype                               |
| `testSelector<S>()`       | Wraps `test()`, registers `cover()` automatically after body passes        |
| `ShoelaceLayout`          | Pure-data shoelace coverage geometry                                       |
| `shoelaceLayoutOf(matrix, variants)` | Builds the layout data                                          |

> **Deep dive:** [What's been built](PLAN.md#whats-been-built) in PLAN.md tracks each version's additions; [CHANGELOG.md](CHANGELOG.md) is the version-stamped log.

---

## DartrixSelector — typed test selectors

`matrix.cover()` works, but it's manual — scattered in test bodies, easy to forget, easy to call after a failing `expect` (which means it never runs). `DartrixSelector` solves this structurally.

<details>
<summary><strong>Zero-boilerplate path — `AppType.getSelector()`</strong></summary>

Every `AppType` variant already knows how to produce its own selector via the built-in extension:

```dart
for (final status in Status.values.where((s) => s.isActive)) {
  testSelector(matrix, status.getSelector(AppFeature.dashboard), (sel) {
    // sel.variant is Status — typed, no cast
    expect(sel.variant.label, isNotEmpty);
  });
}
```

`status.getSelector(AppFeature.dashboard)` returns a `TypedSelector<Status>` — `sel.variant` is already `Status`, not the base `AppType`. No subclass, no boilerplate. Read fixture data from `sel.variant` via your fixture extensions.

</details>

<details>
<summary><strong>Concrete subclass path — when you need typed input getters</strong></summary>

If the test body needs pre-computed fixture data beyond what `sel.variant` exposes directly:

```dart
class StatusDashboardSelector implements DartrixSelector {
  const StatusDashboardSelector(this.status);
  final Status status;

  @override AppType get variant      => status;
  @override FeatureType get feature  => AppFeature.dashboard;
  @override String get description   => status.label;

  Widget get widget => DashboardRow(status: status, label: status.label);
}
```

`testSelector<S>()` registers coverage automatically after the body completes:

```dart
testSelector(matrix, StatusDashboardSelector(status), (sel) {
  expect(sel.widget.label, equals(sel.status.label));
  // matrix.cover() fires automatically — broken tests never appear covered
});
```

The generic `S` parameter preserves the concrete selector type — the body receives `StatusDashboardSelector` directly, no cast needed.

</details>

### Why selectors over manual `cover()`

| | `matrix.cover()`                    | `testSelector()`                    |
|---|----------------------------------|--------------------------------------|
| Coverage registration | Manual, in body         | Automatic, structural                |
| Risk of missing cover | Yes — easy to forget    | No                                   |
| Risk of cover after failed expect | Yes        | No                                   |
| Test name | Hardcoded string                  | `selector.description`               |
| Concrete type in body | Cast required           | Preserved via `S`                    |

---

## ShoelaceLayout — coverage as geometry

`MatrixRenderer` prints the matrix as ASCII. `shoelaceLayoutOf` produces the same coverage state as **pure-data geometry** so consumers can render the matrix as a fractal coverage visual: each enum becomes a circle, variants are nodes around the circumference, and a continuous shoelace path laces them together.

```dart
final layout = shoelaceLayoutOf(matrix, Status.values);

for (final node in layout.nodes) {
  // node.variant       — Status.draft, Status.published, ...
  // node.angle         — radians, evenly distributed on the unit circle
  // node.coverageRatio — covered participating cells / total, in [0, 1]
}

for (final segment in layout.segments) {
  // segment.fromIndex / segment.toIndex — indices into nodes
  // segment.step                         — position in the lace, 0..N-2
  // segment.isLit                        — true ↔ both endpoints fully covered
}
```

The shoelace layout is geometry only — no rendering, no Flutter, no usage registry. Renderers (the Flutter web app under `shoelace/`, HTML canvas, future TUI) consume the layout and decide how to draw it.

> **Deep dive:** [The mathematics](PLAN.md#the-mathematics) explains the lace path formula, the cell function, the coverage ratio, and the disc geometry constants.

---

## The marker interfaces

dartrix ships marker interfaces consumers implement on their domain enums. Each marker maps to a level in the fractal hierarchy.

| Interface       | For                                            | Level    | Status   |
|-----------------|------------------------------------------------|----------|----------|
| `AppType`       | Domain enum variants (`Status`, `Role`, etc.)  | L0/L1    | shipped  |
| `FeatureType`   | User-facing capabilities (`dashboard`, `editor`) | axis   | shipped  |
| `ComponentType` | Renderable UI units (`header`, `row`, `modal`) | L3       | planned  |
| `HelperType`    | Injectable dependencies (`fetcher`, `formatter`) | L3     | planned  |
| `ClassType`     | Domain models (`Document`, `UserProfile`)      | L3       | planned  |
| `DartrixMethod` | Method classifications (factory / fetch / ...) | L4       | planned  |

> **Deep dive:** [The fractal hierarchy](PLAN.md#the-fractal-hierarchy) maps each marker to its role and explains how consumers slot in.

---

## Adopting dartrix in your project

The pattern any project follows. Each step is exhaustive-switch enforced.

1. Declare your domain enums as `AppType`.
2. Declare your feature axis as `FeatureType`.
3. Declare `AppType.features` (the participation switch).
4. Wire the matrix in your test main.
5. Use `testSelector()` per variant per feature.
6. Add a `tearDownAll` gap check.

Optional (Phase 3+):

7. Declare your domain models as `ClassType`.
8. Declare your dependencies as `HelperType`.
9. Declare your renderable units as `ComponentType`.
10. Slot methods to `DartrixMethod`.

> **Deep dive:** [Templating](PLAN.md#templating--the-pattern-any-project-follows) in PLAN.md is the full template with examples and rationale per step.

---

## Multiple axes

The matrix supports multiple domain enums on separate axes — each is crossed against the same feature set:

```dart
final matrix = Dartrix(
  axes: [
    Status.values,
    Role.values,
    ContentType.values,
  ],
  features: AppFeature.values,
);
```

Each variant declares its own participation independently. The matrix unions them all.

---

## Roadmap

dartrix is mid-roadmap toward 1.0. The current ship is schema v2 (drilldown context). Upcoming phases:

| Phase | Scope                                                 | Status      |
|-------|-------------------------------------------------------|-------------|
| 1     | Gap cross-reference (dartrix shoelace)                | scoped      |
| 2     | Test status integration (cross-repo, schema v3)       | planned     |
| 3     | `[t]` TUI screen + template system (zedup-side)       | planned     |
| 4     | Test runner cache + diff-aware re-runs (zedup-side)   | planned     |
| 5     | GUI design subagent (claudart-side)                   | planned     |
| 6     | Cleanup audit (post-merge, all repos)                 | planned     |

> **Deep dive:** [The 6-phase roadmap](PLAN.md#the-6-phase-roadmap) in PLAN.md has scope, deliverables, dependencies, and exit criteria per phase.

---

## Installation

dartrix is not yet published to pub.dev. Reference it via git:

```yaml
# pubspec.yaml
dev_dependencies:
  dartrix:
    git:
      url: https://github.com/liitx/dartrix.git
```

Requires Dart SDK `>=3.5.0`.

---

## Philosophy

- **Compile-time over runtime.** Exhaustive switches catch gaps before tests run.
- **Participation, not just presence.** A variant that genuinely doesn't participate in a feature marks itself `{}` — not a gap, not skipped, declared.
- **Selectors over manual registration.** The selector is the test — it carries the variant, the feature context, and the fixture-derived inputs. Coverage is a consequence, not a chore.
- **Proven before promoted.** Every dartrix API is validated in a real consumer app (zedup) before landing in the framework.
- **No magic.** No code generation, no reflection, no annotations. Just interfaces, switches, and a map.
- **Schema as boundary contract.** The JSON snapshot between data producers and the visualizer is versioned and additive. Consumers and producers ship independently.
- **Project-agnostic visualization.** shoelace renders whatever JSON arrives. Variant types and feature names come from the snapshot, not from imports.

---

## Related

- **[zedup](https://github.com/liitx/zedup)** — Zed IDE profile manager, work item tracker, and the first dartrix consumer + data producer.
- **[claudart](https://github.com/liitx/claudart)** — AI session orchestration and workspace management for Claude Code.
- **[shoelace/](shoelace/)** — The Flutter web visualizer that consumes the JSON snapshot.

# shoelace

**Flutter web visualizer for the dartrix coverage matrix.**

Renders the matrix `M ⊆ V × F` as a fractal disc. Each variant is a vertex on the rim. Each chord links variants in shoelace order. Per-variant region fill encodes test state: covered (green), failing (red), missing (no fill). Click a region → side panel drills into usages, tests, and gaps with file:line + class.method context.

> See the [top-level README](../README.md) for the framework, the math, and the schema contract. This file documents only the web app.

---

## Quickstart

```bash
# 1. Build
flutter build web --pwa-strategy=none

# 2. Point it at a coverage snapshot
ln -sf ~/.zedup/shoelace-coverage.json build/web/coverage.json

# 3. Serve
cd build/web && python3 -m http.server 49999
# open http://localhost:49999/
```

`--pwa-strategy=none` skips the service worker so a single hard-refresh shows the latest build.

For dev iteration with hot-reload:

```bash
flutter run -d chrome
```

---

## What it reads

A JSON snapshot at `web/coverage.json` (or `build/web/coverage.json` after build). The reader is **field-tolerant**: v1, v2, and v3 schemas all parse, with newer fields defaulting to null on older payloads.

| Schema | Adds |
|---|---|
| `zedup-shoelace/v1` | variants, features, gaps, tests, usages |
| `zedup-shoelace/v2` | + `containingClass`, `containingMethod`, `containingGroup` scope context |
| `zedup-shoelace/v3` | + per-test `status`, `failureMessage`, `logPath`, `cachedAt`, `staleness` |

> **Deep dive:** [Schema contract](../PLAN.md#schema-contract) in PLAN.md.

---

## Region color = test state

Region color tracks state, not variant identity. Variant colors live in the rim dot and the chord stroke.

| State | Region | When |
|---|---|---|
| `covered` | green ([`AppColor.statusComplete`](lib/src/ui/tokens.dart)) | every required cell has a passing test |
| `failing` | red ([`AppColor.statusFailing`](lib/src/ui/tokens.dart)) | any test for the variant has `status: failing` or `status: error` |
| `missing` | no fill — concentric rings + chord glow show through | variant has at least one gap and zero failing tests |

Worst-state-wins: failing > missing > covered.

---

## Click to drill

| Click target | Action |
|---|---|
| disc region | focus that variant → side panel detail mode |
| `← Back to overview` | return to variants table |
| any non-region area | clear focus |

Detail mode shows three sections per focused variant:

- **USAGES** — every reference to the variant in `lib/`, with `class.method` scope
- **TESTS** — registered tests, with status icon (`✓` `✗` `○` `?`) and group breadcrumb
- **GAPS** — uncovered features. When a gap's feature name appears in any usage path, those usages render indented underneath the gap row (cross-reference). When no gap soft-matches, an `USAGES OF THIS VARIANT` fallback header surfaces all usages once.

---

## Layout

| File | Role |
|---|---|
| [`lib/src/coverage.dart`](lib/src/coverage.dart) | typed snapshot model + parser + `RegionState` aggregation |
| [`lib/src/region_geometry.dart`](lib/src/region_geometry.dart) | per-vertex region paths (apex-triangle + rim-lune) |
| [`lib/src/shoelace_painter.dart`](lib/src/shoelace_painter.dart) | CustomPainter — disc, rings, regions, chords, vertices |
| [`lib/src/shoelace_canvas.dart`](lib/src/shoelace_canvas.dart) | hit testing + label positioning |
| [`lib/src/side_panel.dart`](lib/src/side_panel.dart) | overview table + detail mode |
| [`lib/src/ui/tokens.dart`](lib/src/ui/tokens.dart) | `AppColor`, `AppText`, `AppLayout`, `AppPaint`, `UiLabel` — every chrome value lives here |

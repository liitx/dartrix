# dartrix

**Enum-driven test matrix framework for Dart.**

dartrix turns your domain enums into a living coverage contract. Every enum variant declares which features it participates in via an exhaustive switch — adding a new variant without updating that switch is a **compile error**, not a missing test discovered at 2am.

---

## The problem

You have a `Status` enum:

```dart
enum Status { draft, published, archived }
```

And a `dashboard` feature that renders each status differently. You write tests for `draft` and `published`, ship, and later add `archived`. The tests still pass. The dashboard silently renders nothing for archived items.

dartrix makes that silent gap impossible.

---

## How it works — the matrix

**1. Define your app's features as an enum:**

```dart
enum AppFeature implements FeatureType {
  dashboard('Main content dashboard'),
  editor('Rich text editor'),
  export('PDF / CSV export');

  const AppFeature(this.description);

  @override final String description;
}
```

**2. Make your domain enums declare participation:**

```dart
enum Status implements AppType {
  draft, published, archived, deleted;

  @override String get description => name;

  @override Set<FeatureType> get features => switch (this) {
    Status.draft     => {AppFeature.dashboard, AppFeature.editor},
    Status.published => {AppFeature.dashboard, AppFeature.export},
    Status.archived  => {AppFeature.dashboard},
    Status.deleted   => {},  // not visible in any feature
  };
}
```

Add `Status.suspended` later and forget to update `features`? **Compile error.** The exhaustive switch enforces the contract at build time.

**3. Register coverage in your tests:**

```dart
void main() {
  final matrix = Dartrix(
    axes: [Status.values],
    features: AppFeature.values,
  );

  for (final status in Status.values) {
    test('dashboard renders $status', () {
      // ... your render assertion ...
      matrix.cover(status, AppFeature.dashboard);
    });
  }

  tearDownAll(() {
    final gaps = matrix.gaps();
    if (gaps.isNotEmpty) {
      fail(MatrixRenderer(matrix).renderGaps());
    }
  });
}
```

**4. See exactly what's missing:**

```
GAPS (2):
  Status.published  ×  editor
  Status.archived   ×  export
```

Or print the full matrix:

```
Feature:      dashboard  editor  export
draft             ✓         ✓      ·
published         ✓         ✗      ✓
archived          ✓         ·      ✗
deleted           ·         ·      ·
```

- `✓` covered
- `✗` gap — test required but missing
- `·` not applicable — variant doesn't participate in this feature

---

## DartrixSelector — typed test selectors

`matrix.cover()` works, but it's manual — scattered in test bodies, easy to forget, easy to call after a failing `expect` (which means it never runs). `DartrixSelector` solves this structurally.

A selector bundles the three things every matrix test needs:

```dart
abstract interface class DartrixSelector {
  AppType get variant;      // the enum value under test
  FeatureType get feature;  // the feature context
  String get description;   // test name — derive from a fixture, not a bare string
}
```

Your app defines concrete selectors that also carry fixture-derived test inputs:

```dart
class StatusDashboardSelector implements DartrixSelector {
  const StatusDashboardSelector(this.status);
  final Status status;

  @override AppType get variant      => status;
  @override FeatureType get feature  => AppFeature.dashboard;
  @override String get description   => status.label; // from your fixture extension

  // Fixture-derived inputs — no bare strings
  Widget get widget => DashboardRow(status: status, label: status.label);
}
```

**`testSelector<S>()`** wraps `test()` and registers coverage automatically — no manual `matrix.cover()` needed:

```dart
for (final status in Status.values.where((s) => s.isActive)) {
  testSelector(matrix, StatusDashboardSelector(status), (sel) {
    expect(sel.widget.label, equals(sel.status.label));
    expect(render(sel.widget), isNotNull);
    // matrix.cover() fires automatically after body completes
  });
}
```

The generic `S` parameter preserves the concrete selector type — the body receives `StatusDashboardSelector` directly, no cast needed.

### Why selectors over manual cover()

| | `matrix.cover()` | `testSelector()` |
|---|---|---|
| Coverage registration | Manual, in body | Automatic, structural |
| Risk of missing cover | Yes — easy to forget | No |
| Risk of cover after failed expect | Yes — throws before reaching it | No |
| Test name | Hardcoded string | `selector.description` |
| Input construction | Inline in test | Typed getter on selector |
| Concrete type in body | Cast required | Preserved via `S` |

---

## The type hierarchy

dartrix ships four marker interfaces your app's enums implement:

| Interface       | For                                           |
|-----------------|-----------------------------------------------|
| `AppType`       | Domain enum variants (Status, Role, Category) |
| `FeatureType`   | User-facing capabilities (dashboard, editor)  |
| `ComponentType` | Renderable UI units (header, row, modal)       |
| `HelperType`    | Injectable dependencies (fetcher, formatter)  |
| `ClassType`     | Domain models (Document, UserProfile)         |

`AppType` is the workhorse — domain enums implement this and declare `features`. The rest are marker interfaces your app registers with the matrix for documentation and tooling.

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

## Planned

- `testSelectorGroup()` — group wrapper for selector loops
- `coverAll(variants, feature)` — convenience for covering multiple variants at once
- `DartrixCubit` — Cubit state adapter template (coverage via state emissions)
- `DartrixBloc` — Bloc adapter template
- `DartrixRiverpod` — Riverpod provider adapter template
- `DartrixIsolate` — concurrent/async coverage adapter

See [open issues](https://github.com/liitx/dartrix/issues) for status and context.

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
- **Proven before promoted.** Every dartrix API is validated in a real consumer app before landing in the framework.
- **No magic.** No code generation, no reflection, no annotations. Just interfaces, switches, and a map.
- **Scales with your enum count.** 3 variants or 30 — the matrix grows with your domain without changing your test structure.

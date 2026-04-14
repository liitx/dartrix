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

## How it works

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
  final matrix = DartrixMatrix(
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
final matrix = DartrixMatrix(
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
- **No magic.** dartrix is ~150 lines. No code generation, no reflection, no annotations. Just interfaces, switches, and a map.
- **Scales with your enum count.** 3 variants or 30 — the matrix grows with your domain without changing your test structure.

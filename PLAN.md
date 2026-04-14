# dartrix — plan

This file is the never-lose-context document for dartrix.
README.md = current API. CHANGELOG.md = version history. PLAN.md = vision + reasoning + where we are.

---

## Vision

dartrix is a test matrix framework for Dart apps built on enhanced enums.
The core insight: your domain enums already know which features they participate in.
dartrix makes that knowledge structural — a compile-time exhaustive switch becomes
the coverage contract, and the framework surfaces gaps as named failures rather than
silent omissions.

The long-term goal: a family of adapters (`DartrixCubit`, `DartrixBloc`,
`DartrixRiverpod`, `DartrixIsolate`) that plug into any Dart/Flutter state management
pattern. Each adapter registers coverage as a side effect of state transitions — not a
manual chore in test bodies.

---

## Design principles

**Proven before promoted.**
Every dartrix API is validated in a real consumer app (zedup) before landing in the
framework. This means we never abstract speculatively. The API earns its existence
from real usage.

**Compile-time over runtime.**
Exhaustive switches in `AppType.features` catch gaps before tests run. Adding a new
enum variant without declaring its feature participation is a compile error.

**Selectors over manual registration.**
`DartrixSelector` + `testSelector()` replace scattered `matrix.cover()` calls.
Coverage is structural — a consequence of using the selector, not a chore to remember.

**No magic.**
No code generation, no reflection, no annotations. Just interfaces, switches, a map,
and one function that wraps `test()`.

---

## Relationship to zedup

zedup is dartrix's proving ground. The flow:

```
design in conversation
        ↓
implement in zedup (concrete, real tests)
        ↓
confirm it works end-to-end
        ↓
promote to dartrix (abstract interface + function)
        ↓
zedup bumps dartrix dep and removes its local impl
```

This means zedup will sometimes carry temporary local implementations that are
"ahead" of dartrix. That's intentional — zedup confirms the API before dartrix
commits to it.

---

## What's been built

### v0.1.0 — Core matrix
- `Dartrix` class — `axes`, `features`, `cover()`, `gaps()`, `stateOf()`
- `CellState` — `covered` / `gap` / `notApplicable`
- `MatrixCell` — `({AppType variant, FeatureType feature})` typedef
- `MatrixRenderer` — `render()` table + `renderGaps()` failure output
- Type hierarchy: `AppType`, `FeatureType`, `ComponentType`, `HelperType`, `ClassType`

**Why AppType.features uses an exhaustive switch:**
The switch is the enforcement mechanism. Dart's exhaustiveness checker makes it a
compile error to add a new enum variant without declaring its feature participation.
This is the compile-time coverage detector — no runtime check can do this.

### v0.1.1 — Rename
- `DartrixMatrix` → `Dartrix`

**Why:** The package name is the class name. `Matrix` suffix was redundant noise.

### v0.1.2 — Selectors
- `DartrixSelector` interface — `variant`, `feature`, `description`
- `testSelector<S>()` — wraps `test()`, registers `cover()` automatically, generic `S`
  preserves concrete selector type

**Why the generic S matters:**
Without `S`, test bodies need to cast `sel as ConcreteSelector` to access app-specific
input getters. With `S extends DartrixSelector`, the concrete type flows through.
No cast, no runtime risk.

**Why coverage after body, not before:**
If `cover()` ran before the body, a test could register coverage and then fail its
assertions — the matrix would show covered but the test would be broken. Running
`cover()` after the body ensures coverage only registers when the test actually passes.

---

## What's next

### Immediate — remaining zedup selectors
zedup needs selectors for every (variant × feature) loop that currently uses manual
`matrix.cover()`. Once those are built and proven, that pattern feeds back into
dartrix's documentation and potentially a `testSelectorGroup()` helper.

See zedup's PLAN.md for the full selector backwork plan.

### Near-term — framework conveniences
- `coverAll(variants, feature)` — bulk coverage for tests that legitimately cover all
  variants at once (invariant checks, snapshot tests). Not a replacement for
  `testSelector` — a complement for a different test shape.
- `testSelectorGroup()` — wraps a list of homogeneous selectors, reduces for-loop
  boilerplate at call sites.

### Adapter templates — proven in zedup first
Each adapter proves the pattern in zedup before landing in dartrix:

1. **`DartrixCubit`** — zedup builds its Cubit layer first. The adapter intercepts
   `emit()` and registers coverage against the emitted state's variant. Zedup confirms
   the API, then dartrix gets it.

2. **`DartrixBloc`** — same pattern, Bloc events instead of Cubit state.

3. **`DartrixRiverpod`** — provider/notifier interception. Zedup doesn't use Riverpod
   today, but the pattern will be proven in another consumer app before shipping.

4. **`DartrixIsolate`** — zedup's refresh feature runs in an Isolate. Coverage cells
   need to cross the isolate boundary. This is the hardest adapter — blocked on zedup's
   refresh implementation.

### When pub.dev
After:
- All core APIs stable (matrix, selector, testSelector)
- At least `DartrixCubit` proven and shipped
- `dart pub publish --dry-run` at 0 warnings
- Version at 1.0.0

---

## Key decisions log

| Decision | Why |
|----------|-----|
| `Dartrix` not `DartrixMatrix` | Package name is the class name |
| `test` in `dependencies` not `dev_dependencies` | Consumers need `testSelector()` transitively |
| `AppType.features` returns `Set<FeatureType>` not `List` | Set semantics — participation, not ordering |
| `name` removed from marker interfaces | Dart analyzer doesn't recognize `Enum.name` as satisfying an abstract interface `name` declaration — use `(this as Enum).name` in dartrix internals |
| Selector carries `description` not `name` | `description` is derived from fixture, `name` is the Dart enum identity — distinct concerns |
| Coverage registered after body | Prevents broken tests from appearing covered |
| zedup as proving ground before dartrix gets the API | Speculative APIs get wrong — real usage proves the right shape |

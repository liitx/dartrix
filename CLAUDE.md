# dartrix — CLAUDE.md

## Profile

You are the **dartrix framework architect**.

dartrix is a small, precise library. Every API in it has been proven wrong at least once in a real consumer app (zedup) before landing here. Your job is to maintain that discipline — nothing ships speculatively, nothing abstracts for hypothetical consumers.

When you work on dartrix, you are not building features. You are **promoting patterns that zedup has already proven correct.** If zedup hasn't proven it, dartrix doesn't get it yet.

---

## Read first — always

Before any code change, read `PLAN.md`. It is the authoritative document for:
- What dartrix is and why
- What has been built and the reasoning behind each decision
- What is next and in what order
- The zedup proving-ground flow

The reading order for a new session:
1. `PLAN.md` — vision + reasoning + where we are
2. `README.md` — current public API (what consumers see)
3. `CHANGELOG.md` — version history 1:1 with GitHub issues

---

## Document hierarchy

| Document | Role | Authority |
|----------|------|-----------|
| `PLAN.md` | Vision, reasoning, roadmap | **Authoritative** |
| `README.md` | Public API documentation | Reflects current released state |
| `CHANGELOG.md` | Version history | 1:1 with package versions |

If README and PLAN disagree on what's next: PLAN wins.
If CHANGELOG and README disagree on what exists: CHANGELOG wins (it's versioned).

---

## Design constraints

**Proven before promoted.** If an API doesn't have a working implementation in zedup with real tests, it doesn't land in dartrix. No exceptions.

**No speculative abstractions.** Three similar lines of code is better than a premature helper. If only zedup uses a pattern, it stays in zedup until a second consumer validates it.

**Compile-time over runtime.** Every enforcement mechanism should be a compile error, not a runtime check.

**No magic.** No code generation, no reflection, no annotations.

---

## Testing constraints

**Loop wraps `test()` — never the reverse.** When iterating over enum values, the `for` loop must create one `test()` per value. A loop inside a single `test()` body collapses all failures into one indistinguishable case.

```dart
// Wrong — one test, failure doesn't say which variant broke
test('render contains all variant names', () {
  for (final v in TestType.values) { expect(output, contains(v.name)); }
});

// Right — one test per variant, failure is precise
for (final v in TestType.values) {
  test('render contains variant: ${v.name}', () {
    expect(renderer.render(), contains(v.name));
  });
}
```

**`flutter_test` corollary.** In `flutter_test`, the equivalent pattern is `ValueVariant<T>` passed as the `variant:` parameter to `testWidgets()` / `test()`. The `loom_lints:check_test_variant` rule enforces this in `dc-flutter`. The discipline is identical — the mechanism differs by framework.

**`testSelector()` is the dartrix idiom.** For matrix-registered tests, prefer `testSelector()` over a raw loop + `matrix.cover()`. The selector carries the variant, feature, and description; coverage registers automatically after the body.

---

## Git rules

- Author: `Aksana Buster <ab@liitx.com>` — verify `git config user.email` before committing
- Never commit to `main` directly — use feature/fix/docs branches
- Never push to remote without explicit user confirmation
- Never add Co-Authored-By or contributor lines to commits
- PR → merge → version bump → CHANGELOG entry

---

## What dartrix is not

- Not a test runner — it wraps `package:test`, doesn't replace it
- Not a code generator — no build_runner, no annotations
- Not a runtime coverage tool — compile-time enforcement is the goal
- Not a general Dart utility library — it is specifically for enum-driven test matrix coverage

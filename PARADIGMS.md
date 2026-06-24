# dartrix — PARADIGMS

> Version: 0.1.0 — semver. A breaking paradigm shift bumps major; a new paradigm or
> clarification bumps minor/patch. Owned workspaces track latest; external consumers pin a
> version. Major bumps land as explicit migration PRs.
>
> The design law for code built with dartrix's philosophy. dartrix owns this file. claudart
> reads it and applies it when constructing or refactoring code. zedup and other owned
> workspaces are consumers shaped by it.
>
> This is a living document. See "Growth" at the end: a paradigm enters the law only once it
> is clear (proven in code, not speculative), the same discipline as claudart's skills
> promotion and archive `superseded_by` rule.

---

## Roles

- **dartrix** — the law. Enforces what is compile-time enforceable (enum × feature matrix
  coverage, exhaustive switches). Documents the paradigms that are not compile-enforceable
  here. **Owns the posture function** below and exports it, so the derivation is portable, not
  locked inside claudart.
- **claudart** — applies the law. Every construct/refactor session loads this file, runs the
  exported posture function, and conforms code decisions to it.
- **consumers** (zedup, etc.) — shaped by the dartrix → claudart flow. A consumer does not run
  its own posture engine; claudart enforces *on* it. A consumer may opt into the exported
  posture function directly if it wants the same derivation.

## Scoping — enforce for owned workspaces, never refactor foreign ones

External packages that depend on dartrix get only its compile-time matrix by default. The
paradigms below, the lints, and claudart's enforcement are opt-in for owned workspaces.
dartrix never reaches into a foreign codebase to restructure it. The posture function is
exported so a willing external consumer can adopt it; it is never imposed.

---

## Posture is derived from work intent, never a manual flag

claudart classifies every task as `AgentCategory × IntentClass × ComplexityTier` (one
`categorize` step). A **total function, owned and exported by dartrix**, maps that
classification to a posture per dimension. Posture is a lattice, never on/off:

| Posture | Meaning | When |
|---|---|---|
| `consider` | Always on, even explore. Compact grounding. Never restructures, never gates. | every task |
| `enforce` | New or changed code must conform. | `implement` intent |
| `restructure` | May rewrite existing code to conform. | `refactor` category |

`consider` is the floor — present for explore and analyze too. It is **grounding context, not
a discovery gate**: a summary plus the shoelace structure map that the agent reasons *with*,
never a filter that narrows candidates during exploration. It is cheap and prompt-cacheable,
and it pays for itself — a grounded agent does not re-derive conventions (fewer tokens) and
extends the real enum spine instead of inventing types or Flutter-override patterns (fewer
hallucinations). The heavy per-dimension rules load only at `enforce` / `restructure`.

**Intent is inferred from the diff, not self-declared.** The posture function reads the change
surface — enum touched → `architecture`; bare literals introduced → `consts`; widget tree
changed → `widgetStructure`; prop chains added → `dataFlow` — so derivation is deterministic
and matrix-testable, not a subjective label an agent assigns itself.

**Escape hatch.** When work needs `restructure` but only `enforce` is feasible now (e.g. a
hotfix), the agent escalates with an explicit, logged note — never a silent blanket bypass.

## Shoelace scan — the non-invasive guard (construction only)

Before *construction* (not exploration), claudart scans the dartrix matrix (shoelace) to map
the existing enums, features, and gaps. That clarity makes additions non-invasive: the agent
extends the existing spine rather than overriding the architecture already in place.

"Non-invasive" is a risk-surface metric, not a feeling: an addition is non-invasive when it
touches no public API and no state machine, and stays within a small change surface (target:
≤ ~100 changed lines across ≤ ~3 files). Beyond that, treat it as `restructure` and surface
the scope.

## Conflicts and precedence

When two paradigms collide in one change, resolve by dimension precedence, highest first:
`testing` → `architecture` → `consts` → `stateManagement` → `dataFlow` → `widgetStructure`
(correctness and the enum spine win over presentation). If a genuine contradiction has no
precedence answer, it is a gap — open a feedback PR (see Growth) rather than guessing.

---

## The dimensions

### architecture
- Enhanced enums are the spine. One variant per thing that exists in the domain.
- Shared attributes are enum fields, set through named constructors that encode the shape
  variance (e.g. `.flex` vs `.fixed`). Derived attributes are getters.
- Extensions map an enum to framework types (e.g. enum → nocterm `Component`), so the enum
  core stays pure and matrix-testable.
- A generic component takes the enum: `Component.of(enumVariant)`.

### widgetStructure
- Content is contained in its box: `clipBehavior: Clip.hardEdge`, bounded content via
  `LayoutBuilder` / `Expanded` / `Flexible`. Content never overflows its box.
- Screens compose a shared scaffold, not hand-rolled chrome.
- Layout is responsive (LayoutBuilder), not fixed widths or magic flex numbers.

### stateManagement
- Prefer `InheritedComponent` / context lookup over prop-drilling when a better alternative
  exists (e.g. `TuiTheme.of(context)` rather than threading `theme` through every widget).

### dataFlow
- Context and typed projections over long prop chains.

### consts
- No bare numeric or string literals in `lib/`. Const values live in one central place as
  enums (enumerable sets) or `abstract final class` (lone scalars).
- A feature projects the central universe to its subset via a `getConsts` extension getter
  returning a record. Set theory: the central file is the universe; `getConsts` is a total
  function `variant → subset`; subsets overlap (shared consts referenced many times).

### testing
- Matrix-driven via `AppType` / `FeatureType`. Enum-owned test groups, generic bodies, test
  names from variant identity. Adding an enum variant without coverage is a compile error.

---

## Growth

The law grows as architecture grows, but only when a paradigm is clear.

- A new pattern is a candidate, not law, until it is proven in real code across more than one
  use.
- When promoting a candidate: add it under the right dimension, state the rule and the
  rationale, tag which posture activates it, and bump the version.
- **Feedback loop is explicit.** When claudart hits a case PARADIGMS does not cover, it opens
  a PR on this file proposing the rule — it does not extrapolate silently. Paradigm evolution
  is auditable, never hidden in claudart's logic.
- When a paradigm is superseded: name what replaced it (the `superseded_by` discipline). If
  you cannot name the replacement, it is not ready to change.
- Re-evaluate the dimensions when new architecture lands. Do not churn the law on speculation.

---
name: spec-designer
description: Interview the user phase-by-phase to co-design a software change following spec-driven development (SDD) as practiced by OpenSpec (openspec.dev) — produces proposal.md, design.md, tasks.md and a spec.md requirements delta before any code is written. Use when asked to "design a spec", "write a proposal", "plan a change", "do SDD", "use OpenSpec", or to define requirements/scenarios for a new feature or change.
---

You are running a **spec-driven design interview**. The deliverable is a
reviewable OpenSpec change proposal — not code. Do not write or edit
implementation code during this skill; only planning artifacts (and, at the
very end, optionally the `openspec/specs/` baseline if the user wants it
seeded). If mid-interview the user starts asking you to implement something,
gently redirect: finish the spec first, implement after it's approved.

## Core OpenSpec concepts (keep these straight)

- **`openspec/specs/<capability>/spec.md`** — the *current, agreed* truth for
  one capability. Never edited directly for a change in flight; only updated
  when a change is archived.
- **`openspec/changes/<change-name>/`** — one in-flight change proposal:
  - `proposal.md` — why, what, impact (business/user framing)
  - `design.md` — technical approach, alternatives, tradeoffs (**only** for
    non-trivial changes — skip it for small/obvious ones, see Phase 0)
  - `tasks.md` — numbered implementation checklist
  - `specs/<capability>/spec.md` — the **delta**: `## ADDED Requirements`,
    `## MODIFIED Requirements`, `## REMOVED Requirements` sections, each
    containing full `### Requirement:` blocks with `#### Scenario:` blocks.
- **Requirement** — a single `SHALL` obligation of the system.
- **Scenario** — a concrete `WHEN`/`THEN` (optionally `GIVEN`) example proving
  a requirement, in a `#### Scenario: <title>` block under its requirement.
- **Capability** — a coherent slice of system behavior (`auth-session`,
  `checkout-cart`), not a whole feature area and not a single function. A
  change usually touches 1-3 capabilities.

Philosophy to hold onto throughout: **fluid not rigid, iterative not
waterfall, minimal process to reach a good-enough plan**. Don't manufacture
ceremony (e.g. a `design.md` full of non-decisions) just to fill the
template — every artifact must earn its place.

## Phase 0 — Kickoff and scope the interview itself

Ask a single open question first (don't batch this with anything else):

> "In a sentence or two, what change do you want to design a spec for?"

From the answer, and a quick look at the repo, decide and **tell the user**
what you're about to do before diving into phases:

1. **Locate or initialize `openspec/`.**
   - `Glob` for `openspec/specs/**/spec.md` and `openspec/changes/*/` in the
     current project.
   - If `openspec/` doesn't exist: tell the user you'll initialize it fresh
     (`openspec/specs/` will start empty — that's normal for a first
     change) and create the directories as you go. Don't run the `openspec`
     CLI — you don't need it; you're authoring the same file conventions by
     hand.
   - If it exists: `Read` any `openspec/specs/<capability>/spec.md` files
     that look related to the requested change (by name or by grepping for
     relevant terms) — you need to know current requirements before drafting
     deltas against them.
2. **Judge complexity** — this decides which phases below you actually run:
   - *Trivial* (single obvious requirement, no architectural choice, no
     ambiguity): compress Phases 1-5 into one combined round of questions,
     skip `design.md` entirely.
   - *Normal/complex* (new capability, touches multiple components, has
     real alternatives or open questions): run all phases below in full,
     sequentially, one phase per turn — ask, then **stop and wait for the
     answer** before moving to the next phase. Do not dump all phases as one
     giant question list; that defeats the point of an interview.
3. **Propose a change name** (kebab-case, verb-led: `add-remember-me`,
   `fix-session-timeout`, `refactor-payment-retry`) and confirm it, or adjust
   based on pushback.

## Phase 1 — Problem & context

Ask (adapt wording to what Phase 0 already revealed — don't re-ask what you
already know):
- What problem does this solve? Who hits it, and how do you know (a bug
  report, a support ticket, a product ask)?
- What happens today, concretely, without this change?
- Why now — what's the trigger/urgency?

Capture this as-is; it becomes `proposal.md`'s "Why".

## Phase 2 — Goals, non-goals, scope boundary

Ask:
- What must be true when this is done (goals, plainly stated)?
- What's explicitly **out of scope** — things adjacent that you're
  deliberately not touching? (This is the single most-skipped question and
  the single biggest source of scope creep later — press for at least one
  concrete non-goal.)
- Which existing capability/capabilities does this touch? Is this a new
  capability, or does it extend one you found in `openspec/specs/`?

## Phase 3 — Requirements

Work **one requirement at a time**, not as a brainstorm dump:
1. Propose a candidate requirement as a `SHALL` statement in plain language,
   derived from Phases 1-2.
2. Show it to the user, ask them to confirm/edit/reject.
3. Once confirmed, ask: is this `ADDED`, `MODIFIED` (existing requirement in
   `openspec/specs/<capability>/spec.md` changes behavior — quote the old
   text), or `REMOVED`?
4. Repeat until the user says the requirement set is complete. Push back
   gently on vague requirements ("the system should be fast") — ask for the
   testable version ("respond within Nms for X").

Keep a running numbered list visible in the chat so the user can say "change
requirement 3" without re-explaining it.

## Phase 4 — Scenarios

For **each** requirement from Phase 3, ask for (or draft and confirm) at
least one scenario in `WHEN <trigger>` / `THEN <outcome>` form (add `GIVEN
<precondition>` only when the precondition isn't obvious from context).
Push for the **unhappy path** too where it matters (error, edge case, empty
state) — a requirement with only its happy-path scenario is usually
under-specified. Don't force an unhappy-path scenario onto a requirement
where none is meaningful.

## Phase 5 — Design (skip if Phase 0 judged this trivial)

Only ask what's genuinely undecided — don't manufacture questions:
- Are there multiple viable technical approaches? What are they, and what's
  the tradeoff (performance, complexity, blast radius, reversibility)?
- Any existing pattern in this codebase you should follow instead of
  inventing a new one? (Worth a quick `Grep`/`Explore` pass before asking —
  don't make the user tell you what a codebase search would show.)
- Data/API/schema shape decisions that need to be pinned down before tasks
  can be written?
- Open questions that block implementation but don't block writing the spec
  (flag them explicitly in `design.md` under "Open Questions" rather than
  stalling the interview on them).

## Phase 6 — Tasks

Break the confirmed requirements + design into a numbered checklist,
grouped by requirement or by component, fine-grained enough that each task
is independently completable and roughly reviewable in one sitting
(sub-numbered, e.g. `1.1`, `1.2`). Show the draft, ask if anything's missing
or wrongly sequenced.

## Phase 7 — Consolidate, review, write

1. Print the **full consolidated draft** of every file you're about to
   write (proposal.md, design.md if present, tasks.md, each
   `specs/<capability>/spec.md` delta) as a single reviewable block.
2. Ask explicitly: "Write these files as shown, or anything to change
   first?" Treat this as a real gate — don't write until confirmed. Creating
   new files under `openspec/changes/` is low-risk/reversible, so once
   confirmed you don't need a second confirmation per file.
3. On confirmation, `Write` the files at:
   ```
   openspec/changes/<change-name>/proposal.md
   openspec/changes/<change-name>/design.md        (if applicable)
   openspec/changes/<change-name>/tasks.md
   openspec/changes/<change-name>/specs/<capability>/spec.md   (one per capability touched)
   ```
4. Tell the user what's next (out of this skill's scope): implementing
   `tasks.md`, and once done, archiving the change by merging the delta into
   `openspec/specs/<capability>/spec.md` and moving the change folder under
   `openspec/changes/archive/`. Don't do this automatically — it happens
   after real review/implementation, not as part of designing the spec.

## Templates

### `proposal.md`

```markdown
# <Change Name>

## Why
<Problem, who's affected, evidence, urgency — from Phase 1>

## What Changes
<Bullet summary of the behavior change, plain language — from Phase 1-2>

## Impact
- Capabilities: <list>
- Affected specs: <ADDED/MODIFIED/REMOVED per capability>
- Out of scope: <non-goals from Phase 2>
```

### `design.md` (only for non-trivial changes)

```markdown
# Design: <Change Name>

## Context
<Constraints, prior art in this codebase, why this needs a design doc>

## Approach
<Chosen approach and why>

## Alternatives Considered
- **<Alternative>** — <tradeoff, why rejected>

## Open Questions
- <Question> — <who/what resolves it, doesn't block spec approval>
```

### `tasks.md`

```markdown
# Tasks: <Change Name>

## 1. <Group / Requirement>
- [ ] 1.1 <Task>
- [ ] 1.2 <Task>

## 2. <Group / Requirement>
- [ ] 2.1 <Task>
```

### `specs/<capability>/spec.md` (delta, inside the change folder)

```markdown
## ADDED Requirements

### Requirement: <Name>
The system SHALL <obligation>.

#### Scenario: <Happy path title>
- WHEN <trigger>
- THEN <outcome>

#### Scenario: <Edge case title>
- GIVEN <precondition>
- WHEN <trigger>
- THEN <outcome>

## MODIFIED Requirements

### Requirement: <Name>
<Full new text of the requirement — not just the diff>

#### Scenario: <title>
- WHEN <trigger>
- THEN <outcome>

## REMOVED Requirements

### Requirement: <Name>
**Reason**: <why this no longer applies>
**Migration**: <what replaces it, if anything>
```

## Quality checklist before writing (mirrors `openspec validate`)

- Every requirement has ≥1 scenario.
- Every scenario has `WHEN` + `THEN` (and `GIVEN` only if it adds real
  precondition info).
- `MODIFIED` requirements quote the **full new requirement text**, not a
  diff fragment.
- `REMOVED` requirements state a reason and, if relevant, a migration path.
- Non-goals from Phase 2 are actually reflected in `proposal.md`'s Impact
  section — a spec that never says what it *won't* do is incomplete.
- `design.md` exists only if it contains at least one real decision or
  tradeoff — delete the phase output if it turned out empty.

## Gotchas

- **Don't let Phase 3 turn into a monologue.** If the user starts listing
  five requirements at once, that's fine — split them out and confirm each,
  but don't silently invent requirements they didn't ask for.
- **A capability is not a change.** If the interview reveals the "change"
  is really an entire new capability with many independent requirements,
  say so and suggest splitting into multiple smaller changes rather than
  one sprawling proposal — OpenSpec proposals are meant to be reviewable in
  minutes.
- **Existing `spec.md` is the source of truth for `MODIFIED`/`REMOVED`.**
  Never guess the old requirement text from memory — `Read` the actual file
  before drafting a delta against it.

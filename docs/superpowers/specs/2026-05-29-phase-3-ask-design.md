# Phase 3 — ASK: Design Spec

**Date:** 2026-05-29
**Issue:** [#22](https://github.com/rafaeltcosta86/context-optimizer/issues/22)
**Status:** Awaiting user review

---

## Problem

After SCAN (Phase 1) and DIAGNOSE (Phase 2) complete automatically, the skill may lack information that cannot be inferred from files alone. Phase 3 fills the smallest possible gap by asking the user only what is truly unknown — never re-asking what the scan already answered.

---

## Approach: Signal-count-then-branch

Two clearly separated paths activated by signal count. Chosen over alternatives because it maps cleanly to the spec, is easy to TDD with two distinct fixtures, and has no risk of weak-state questions leaking into normal-state runs.

---

## Section 1 — Signal Counting

Count "usable signals" from the Scan Report. One signal per qualifying source:

| Source | Counts if |
|--------|-----------|
| Context file | ≥ 5 lines (per file — multiple files each count individually). "Context file" = agent config files only: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.cursorrules`, `.cursor/rules/*.mdc`. `README.md` is NOT counted — it is read for project summary in Phase 1 but is not an agent context file. |
| Hook | any hook detected (project-level or global) |
| Memory | count > 0 populated entries |
| Project type | clear type from manifest (not "unknown") |

**Threshold:** count < 3 → weak-state branch. Count ≥ 3 → normal-state branch.

**Rationale for per-file counting:** the existing `diagnose-fixture-diagnosis-report.md` TDD anchor records `Weak-state: No — usable signals ≥ 3` for a fixture with CLAUDE.md (13 lines) + AGENTS.md (6 lines) + package.json and no hooks or memory. Per-file counting (3 signals) is the only interpretation consistent with that anchor.

---

## Section 2 — Two Branches

### Weak-state (count < 3)

Ask all 3 fixed questions in a single message. Wait for user response. No additional questions regardless of diagnosis gaps.

Fixed questions (verbatim from ARCHITECTURE.md §2 Phase 3 step 2):

- Q1: *In one or two sentences, what does this project do?*
- Q2: *What are the rules a new agent must never break in this project?*
- Q3: *What changes most frequently in the active work — issues/PRs in a tracker, tasks in a board, or something else?*

Answers populate the diagnosis report as if inferred from files — they feed into Phase 4 RECOMMEND directly.

### Normal-state (count ≥ 3)

Walk the Diagnosis Report for gaps the scan cannot answer. Fire 0–3 surgical questions based on these triggers:

| Trigger condition | Question to ask |
|---|---|
| ≥ 2 platforms detected AND no `AGENTS.md` present | Should rules be unified in `AGENTS.md` (cross-tool) or kept per-platform? |
| Stage signals score = 1 (ambiguous — one weak signal only) | Is this project organized as a sequential workflow or is the numbering coincidental? |
| `gh` not authenticated (or not installed) — determined by reading the Scan Report's `## In-Flight State` section: if it shows "Skipped" or "no gh auth", this trigger fires. Phase 3 does NOT re-run gh commands. | Do you want dynamic in-flight queries (requires `gh auth login`) or a static roadmap file (you maintain manually)? |

If **0 triggers fire**: emit ASK-REPORT immediately, no user wait, proceed to Phase 4.
If **≥ 1 trigger fires**: ask all triggered questions together in one message, wait for response, then emit ASK-REPORT.

**Hard rule:** never re-ask what the scan already answered. Violations break user trust.

---

## Section 3 — ASK-REPORT Format

Always emitted, regardless of mode or question count. Delimited block:

```
---ASK-REPORT-START---

# Ask Report — {project name}

**Mode:** weak-state | normal-state
**Signal count:** N

## Questions Asked

1. {question text}
2. {question text}

_No questions needed._ (when 0 questions in normal-state)

## Answers Received

1. {user's answer}
2. {user's answer}

_N/A_ (when 0 questions)

**Ask complete.**

---ASK-REPORT-END---
```

After the block emitted: **proceed immediately to Phase 4 — RECOMMEND** without pausing for user input.

---

## Section 4 — TDD Fixtures

### Fixture 1: `diagnose-fixture` → normal-state path

**Signal count:** CLAUDE.md (13 lines ✅) + AGENTS.md (6 lines ✅) + package.json (manifest ✅) = 3 → normal-state.

**Trigger evaluation:**
- ≥ 2 platforms + no AGENTS.md? → No (AGENTS.md present) → no question
- Stage signals = 1? → 0 stage signals in fixture → no question
- `gh` not authenticated? → No gh hook present → **fires** → 1 question asked

**TDD anchor:** `examples/after/diagnose-fixture-ask-report.md`
- Mode: normal-state
- Signal count: 3
- Questions Asked: the gh dynamic/static question
- Answers Received: hardcoded fixture answer (e.g. "static roadmap file")

### Fixture 2: new `weak-fixture` → weak-state path

**Structure:** minimal project with only a 3-line `CLAUDE.md` (< 5 lines = 0 file signals) and a bare `README.md`. No manifest, no hooks, no memory.

**Signal count:** 0 → weak-state.

**TDD anchor:** `examples/after/weak-fixture-ask-report.md`
- Mode: weak-state
- Signal count: 0
- Questions Asked: all 3 fixed questions
- Answers Received: hardcoded fixture answers

### CI Extension

`scripts/validate-fixture.sh` extended to validate Phase 3 output against both anchors, consistent with existing Phase 1 and Phase 2 validation pattern.

---

## Constraints (from ARCHITECTURE.md §10)

- C-1: skill never modifies source code — Phase 3 is read + ask only, no writes
- C-2: no user content deleted — N/A for this phase
- Phase 3 is explicitly read-only; all writes are deferred to Phase 5

---

## Open Questions

None — all design decisions resolved during brainstorming session.

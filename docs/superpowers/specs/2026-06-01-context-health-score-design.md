# Design Spec — Context Health Score (Issue #26)

**Date:** 2026-06-01
**Issue:** [#26](https://github.com/rafaeltcosta86/context-optimizer/issues/26)
**Status:** Approved — ready for implementation planning

---

## Problem

Phase 2 DIAGNOSE emits a table-heavy, dimension-first report. The user must process 5 dimension tables + 4 cross-cutting checks to form a mental model of overall context health. The "so what" is buried at the end.

## Goal

Add a `## Context Health Score` block as the first section of the Diagnosis Report, giving the user an immediate verdict — current state, projected improvement, and which gaps matter most — before reading any detail tables.

---

## Decisions

| Question | Decision |
|---|---|
| Multi-platform aggregation | Per-platform score rows + one aggregate row (Option C) |
| Duplication penalty source | Both `duplicated` status entries AND canonical-source violation entries are consulted; de-duplicated union drives the penalty (−2 per unique violation) |
| Score 10 condition | present-good + zero violations tied to that dimension (per-dimension independent) |
| Known Patterns location | Add `## Known Patterns` stub to skill body with one entry: `score-health-computation` |

---

## Score Algorithm

### Per-dimension score

| Status | Score |
|---|---|
| `missing` | 0 |
| `present-weak` | 4 |
| `present-good` (with violations tied to this dimension) | 8 |
| `present-good` (no violations tied to this dimension) | 10 |
| `duplicated` | max(0, 8 − (2 × unique violations implicating this platform)) — violations counted from the de-duplicated union of `duplicated` status entries and canonical-source violation entries |

### Cross-cutting violation → dimension mapping

| Violation type | Dimension affected | Effect |
|---|---|---|
| Layer 3/4 contamination | In-flight | Blocks +2 bonus; keeps present-good at 8 |
| Canonical-source violation | Duplication | −2 per violation per implicated platform |
| Size compliance | none | No score impact |
| Auto-load coverage | none | No score impact |

### Aggregation

- **Per-platform aggregate** = `sum(5 dimension scores) / 5`, rounded to nearest integer
- **Overall aggregate** = average of per-platform aggregates, rounded to nearest integer

### Priority map (fixed)

| Dimension | Priority |
|---|---|
| In-flight | P1 |
| Startup | P1 |
| Identity | P2 |
| Workflow | P2 |
| Duplication | P3 |

### Projected score

Recompute overall aggregate with all P1+P2 dimensions set to 10 (P3 dimensions unchanged). Represents the state after all high-priority recommendations are applied.

---

## Report Format

The `## Context Health Score` block is the **first section** inside `---DIAGNOSIS-REPORT-START---`, before `## Dimension Evaluation`.

```
## Context Health Score

Current: 4 / 10
After recommendations: 9 / 10  (+5)

| Platform     | Identity | Workflow | In-flight | Startup | Duplication | Score |
|--------------|----------|----------|-----------|---------|-------------|-------|
| Claude Code  | 10       | 10       | 4         | 0       | 6           | 6/10  |
| Cursor       | 0        | 4        | 0         | 0       | 10          | 3/10  |
| Cross-tool   | 4        | 10       | 0         | 0       | 6           | 4/10  |
| **Aggregate**|          |          |           |         |             | **4/10** |

> 2 P1 gaps blocking agent efficiency. Applying top P1+P2 recommendations brings score to 9/10.
```

**Verdict line formula:** `"{N} P1 gaps blocking agent efficiency. Applying top P1+P2 recommendations brings score to {projected}/10."` where N = count of P1 dimensions scoring < 8 across any platform.

The 6 existing sections follow unchanged:
1. `## Dimension Evaluation`
2. `## Layer 3/4 Contamination`
3. `## Canonical-Source Violations`
4. `## Size Compliance`
5. `## Auto-Load Coverage`
6. `## Diagnosis Summary`

Total sections in Diagnosis Report: **7**.

---

## Concrete Fixture Numbers (diagnose-fixture)

**Input state from `examples/before/diagnose-fixture/`:**

| Platform | Identity | Workflow | In-flight | Startup | Duplication | Avg |
|---|---|---|---|---|---|---|
| Claude Code | 10 | 10 | 4 | 0 | 6 | **6** |
| Cursor | 0 | 4 | 0 | 0 | 10 | **3** |
| Cross-tool | 4 | 10 | 0 | 0 | 6 | **4** |
| **Aggregate** | | | | | | **4** |

Derivation notes:
- Claude Code / Identity = 10: present-good, no violations tied to Identity
- Claude Code / Workflow = 10: present-good, no violations tied to Workflow
- Claude Code / In-flight = 4: present-weak (contamination violation blocks bonus but base is already 4)
- Claude Code / Startup = 0: missing
- Claude Code / Duplication = 6: duplicated status → base 8, minus 2 for canonical-source violation (CLAUDE.md implicated) = 6
- Cursor / Duplication = 10: present-good, not implicated in canonical-source violation
- Cross-tool / Duplication = 6: duplicated status → base 8, minus 2 for canonical-source violation (AGENTS.md implicated) = 6

**Projected (P1+P2 applied):**

| Platform | Projected avg |
|---|---|
| Claude Code | 9 |
| Cursor | 10 |
| Cross-tool | 9 |
| **Overall** | **9** |

Current 4/10 → After recommendations 9/10 (+5).

---

## Skill Body Changes

### Change 1 — New Step 6: Compute Health Score

Insert before current Step 6 "Emit" (which becomes Step 7):

> **6. Compute the Context Health Score.** Using all dimension statuses and cross-cutting check results from Steps 1–5, compute per-platform scores per the `score-health-computation` Known Pattern. Record:
> - Per-platform × per-dimension scores
> - Per-platform aggregate (average of 5 dimensions, rounded)
> - Overall aggregate (average of per-platform aggregates, rounded)
> - Projected overall (P1+P2 dimensions set to 10, recomputed)
> - Count of P1 dimensions scoring < 8 across any platform

### Change 2 — Update Step 7 (current Step 6) Emit

Add `## Context Health Score` as the first mandatory section before `## Dimension Evaluation`. Section count in the emit list: 6 → 7.

### Change 3 — New `## Known Patterns` section (end of skill body)

```markdown
## Known Patterns

### score-health-computation

**Trigger:** Phase 2 Step 6 (score compute) and Phase 4 (projected score per recommendation)

**Score mapping:**
- `missing` → 0
- `present-weak` → 4
- `present-good` with violations tied to this dimension → 8
- `present-good` with no violations → 10
- `duplicated` → max(0, 8 − (2 × unique violations implicating this platform)); violations = de-duplicated union of `duplicated` status entries and canonical-source violation entries

**Violation → dimension mapping:**
- Layer 3/4 contamination → In-flight (blocks +2 bonus)
- Canonical-source violations → Duplication (−2 per violation per implicated platform)

**Aggregation:** per-platform avg = sum(5 dims)/5 rounded; overall = avg of per-platform avgs rounded

**Projected:** recompute with all P1+P2 dimensions set to 10; P3 unchanged

**Priority map (fixed):** In-flight=P1, Startup=P1, Identity=P2, Workflow=P2, Duplication=P3
```

---

## Fixture + CI Changes

### `examples/after/diagnose-fixture-diagnosis-report.md`

Prepend `## Context Health Score` block with concrete fixture numbers (4/10 current, 9/10 projected, per-platform table, verdict line) before the existing `## Dimension Evaluation` section. All 6 existing sections preserved unchanged.

### `scripts/validate-diagnosis.sh`

Add to SECTIONS array:
```bash
"## Context Health Score"
```

Add to ASSERTIONS array:
```bash
"After recommendations:"
"P1 gaps blocking agent efficiency"
```

---

## Full Change Inventory

| File | Change type |
|---|---|
| `skill/context-optimizer.md` | +Step 6, update Step 7, +Known Patterns section |
| `examples/after/diagnose-fixture-diagnosis-report.md` | Prepend score block |
| `scripts/validate-diagnosis.sh` | +1 section check, +2 assertions |

No new files. No other files touched.

---

## Acceptance Criteria (from issue)

- [ ] Diagnosis Report opens with `## Context Health Score` block (current score, projected score, delta)
- [ ] Score table shows all 5 dimensions per platform + aggregate row, with individual score
- [ ] One-line verdict: P1 gap count + what applying top recommendations achieves
- [ ] Detailed dimension tables follow the summary (preserved, not removed)
- [ ] Score definition documented in `## Known Patterns` section of skill body
- [ ] Fixture `diagnose-fixture-diagnosis-report.md` updated to include score block
- [ ] CI validation script updated to assert score block present

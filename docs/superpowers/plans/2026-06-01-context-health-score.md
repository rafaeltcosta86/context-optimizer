# Context Health Score Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `## Context Health Score` block as the first section of the Diagnosis Report, giving an immediate per-platform × dimension score table, overall score, projected score, and one-line verdict before the existing detail tables.

**Architecture:** TDD for a Markdown skill — write CI assertions (RED), write the fixture expected output (GREEN for CI), then update the skill procedure body to match. Three files change: `scripts/validate-diagnosis.sh` (CI assertions), `examples/after/diagnose-fixture-diagnosis-report.md` (TDD anchor), `skill/context-optimizer.md` (procedure + Known Patterns).

**Tech Stack:** Bash (CI script), Markdown (skill body + fixture). `npm test` runs both validation scripts against their fixture files via stdin redirection.

**Spec:** `docs/superpowers/specs/2026-06-01-context-health-score-design.md`

---

## File Map

| File | Change |
|---|---|
| `scripts/validate-diagnosis.sh` | Add `## Context Health Score` to SECTIONS; add 2 ASSERTIONS |
| `examples/after/diagnose-fixture-diagnosis-report.md` | Prepend score block before `## Dimension Evaluation` |
| `skill/context-optimizer.md` | Add Step 6 (compute), renumber Step 6→7 (emit, +score section), append `## Known Patterns` |

---

## Task 1: Add CI Assertions (RED)

**Files:**
- Modify: `scripts/validate-diagnosis.sh`

- [ ] **Step 1: Verify current tests pass**

```bash
npm test
```

Expected output: `PASS: all sections and assertions verified` (twice — once for each fixture). If it fails, stop and investigate before proceeding.

- [ ] **Step 2: Add `## Context Health Score` to SECTIONS array**

In `scripts/validate-diagnosis.sh`, the SECTIONS array currently starts with `"## Dimension Evaluation"`. Add `"## Context Health Score"` as the first entry:

```bash
SECTIONS=(
    "## Context Health Score"
    "## Dimension Evaluation"
    "## Layer 3/4 Contamination"
    "## Canonical-Source Violations"
    "## Size Compliance"
    "## Auto-Load Coverage"
    "## Diagnosis Summary"
)
```

- [ ] **Step 3: Add score block assertions to ASSERTIONS array**

The ASSERTIONS array currently starts with `"duplicated"`. Add two new entries before it:

```bash
ASSERTIONS=(
    "After recommendations:"
    "P1 gaps blocking agent efficiency"
    "duplicated"
    "Current PR: #42"
    "Never force-push to main"
    "Diagnosis complete."
)
```

- [ ] **Step 4: Run test to confirm RED**

```bash
npm test
```

Expected: the diagnosis validation fails with:
```
FAIL: Missing ## Context Health Score
```
(The scan fixture validation should still pass.)

- [ ] **Step 5: Commit RED**

```bash
git add scripts/validate-diagnosis.sh
git commit -m "test: assert Context Health Score block in diagnosis fixture (RED)"
```

---

## Task 2: Write Fixture Expected Output (GREEN for CI)

**Files:**
- Modify: `examples/after/diagnose-fixture-diagnosis-report.md`

- [ ] **Step 1: Locate the insertion point**

Open `examples/after/diagnose-fixture-diagnosis-report.md`. Find the `---` separator line that appears between the metadata block and `## Dimension Evaluation` (around line 9). The score block goes between that separator and `## Dimension Evaluation`.

- [ ] **Step 2: Insert the score block**

Replace the existing content between the opening metadata and `## Dimension Evaluation` so the file reads:

```markdown
---DIAGNOSIS-REPORT-START---

# Diagnosis Report — acme-cli

**Source:** Scan Report for `examples/before/diagnose-fixture/`
**Status legend:** present-good · present-weak · missing · duplicated

---

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

---

## Dimension Evaluation
```

Everything from `## Dimension Evaluation` onward is unchanged.

- [ ] **Step 3: Run test to confirm GREEN**

```bash
npm test
```

Expected: both fixtures pass:
```
PASS: all sections and assertions verified
PASS: all sections and assertions verified
```

- [ ] **Step 4: Commit GREEN**

```bash
git add examples/after/diagnose-fixture-diagnosis-report.md
git commit -m "test: add Context Health Score block to diagnose fixture (GREEN)"
```

---

## Task 3: Add Known Patterns Section to Skill Body

**Files:**
- Modify: `skill/context-optimizer.md`

- [ ] **Step 1: Append Known Patterns section**

At the very end of `skill/context-optimizer.md` (after the Phase 5 stub line), append:

```markdown

## Known Patterns

### score-health-computation

**Trigger:** Phase 2 Step 6 (score compute) and Phase 4 (projected score per recommendation)

**Per-dimension score mapping:**
- `missing` → 0
- `present-weak` → 4
- `present-good` with violations tied to this dimension → 8
- `present-good` with no violations → 10
- `duplicated` → max(0, 8 − (2 × unique violations implicating this platform)); violations = de-duplicated union of `duplicated` status entries and canonical-source violation entries

**Violation → dimension mapping:**
- Layer 3/4 contamination → In-flight dimension (blocks +2 bonus; keeps present-good at 8)
- Canonical-source violations → Duplication dimension (−2 per unique violation per implicated platform)

**Aggregation:**
- Per-platform aggregate = sum(5 dimension scores) / 5, rounded to nearest integer
- Overall aggregate = average of per-platform aggregates, rounded to nearest integer

**Projected score:** Recompute overall aggregate with all P1+P2 dimensions set to 10; P3 (Duplication) unchanged.

**Priority map (fixed):**
- In-flight: P1
- Startup: P1
- Identity: P2
- Workflow: P2
- Duplication: P3
```

- [ ] **Step 2: Run tests to confirm still GREEN**

```bash
npm test
```

Expected: both fixtures still pass (Known Patterns section doesn't affect validation).

- [ ] **Step 3: Commit**

```bash
git add skill/context-optimizer.md
git commit -m "feat: add score-health-computation Known Pattern to skill body"
```

---

## Task 4: Add Step 6 (Compute) and Update Step 7 (Emit) in Phase 2

**Files:**
- Modify: `skill/context-optimizer.md`

- [ ] **Step 1: Insert new Step 6 — Compute Health Score**

In `skill/context-optimizer.md`, find the Phase 2 procedure. After Step 5 (`**Auto-load coverage check.**`) and before the current Step 6 (`**Emit the Diagnosis Report.**`), insert:

```markdown
6.  **Compute the Context Health Score.** Using all dimension statuses and cross-cutting check results from Steps 1–5, apply the `score-health-computation` Known Pattern. Compute and record:
    *   Per-platform × per-dimension scores (Identity, Workflow, In-flight, Startup, Duplication for each detected platform)
    *   Per-platform aggregate score: `sum(5 dimension scores) / 5`, rounded to nearest integer
    *   Overall aggregate score: average of per-platform aggregates, rounded to nearest integer
    *   Projected overall score: recompute with all P1+P2 dimensions set to 10 (P3 Duplication unchanged)
    *   Count of P1 dimensions (In-flight, Startup) scoring < 8 across any platform

```

- [ ] **Step 2: Renumber old Step 6 to Step 7 and add score section to emit list**

Find the current Step 6 (`**Emit the Diagnosis Report.**`). Change it to Step 7 and update the section list to add `## Context Health Score` as the first of the 7 sections:

```markdown
7.  **Emit the Diagnosis Report.** Produce a block delimited by `---DIAGNOSIS-REPORT-START---` and `---DIAGNOSIS-REPORT-END---`. Start with `# Diagnosis Report — {project name}`, then two metadata lines: `**Source:** Scan Report for {scanned path}` and `**Status legend:** present-good · present-weak · missing · duplicated`. Then these 7 sections in order:
    *   `## Context Health Score` — `Current: {overall} / 10`, `After recommendations: {projected} / 10 ({delta})`, then a table with columns `Platform | Identity | Workflow | In-flight | Startup | Duplication | Score` (one row per detected platform using per-dimension scores from Step 6, plus a `**Aggregate**` row showing the overall aggregate), then a one-line verdict: `> {N} P1 gaps blocking agent efficiency. Applying top P1+P2 recommendations brings score to {projected}/10.`
    *   `## Dimension Evaluation` — one row per detected platform, columns: `Platform | Identity | Workflow | In-flight | Startup | Duplication`.
    *   `## Layer 3/4 Contamination` — columns `File | Status | Detail`; render `✅ None detected` when clean.
    *   `## Canonical-Source Violations` — columns `Rule | Appears in`; render `✅ None detected` when clean.
    *   `## Size Compliance` — columns `File | Lines | Limit | Status`.
    *   `## Auto-Load Coverage` — columns `Orphan content | Location | Issue`; render `✅ Full coverage` when clean.
    *   `## Diagnosis Summary` — reports: platforms evaluated, gaps (count of `missing` + `present-weak`), violations (contamination + canonical-source + size), and weak-state Yes/No (usable signals < 3).

    End with `**Diagnosis complete.**`.
```

- [ ] **Step 3: Run tests to confirm still GREEN**

```bash
npm test
```

Expected: both fixtures still pass (CI validates fixture files, not live skill output).

- [ ] **Step 4: Commit**

```bash
git add skill/context-optimizer.md
git commit -m "feat: add Phase 2 Step 6 score compute and update emit step for Context Health Score"
```

---

## Task 5: Verify and Open PR

- [ ] **Step 1: Final test run**

```bash
npm test
```

Expected:
```
PASS: all sections and assertions verified
PASS: all sections and assertions verified
```

- [ ] **Step 2: Review all changes**

```bash
git diff main
```

Confirm:
- `scripts/validate-diagnosis.sh`: 1 new SECTIONS entry + 2 new ASSERTIONS entries
- `examples/after/diagnose-fixture-diagnosis-report.md`: score block prepended before `## Dimension Evaluation`
- `skill/context-optimizer.md`: new Step 6 inserted, old Step 6 renumbered to Step 7 with updated section list, `## Known Patterns` section appended

- [ ] **Step 3: Open PR linked to issue #26**

```bash
gh pr create \
  --title "feat: add Context Health Score to Diagnosis Report (issue #26)" \
  --body "$(cat <<'EOF'
## Summary

- Adds `## Context Health Score` as the first section of the Diagnosis Report
- Per-platform × dimension score table with aggregate row; overall and projected scores
- Score algorithm defined in new `## Known Patterns` section (`score-health-computation` entry)
- Diagnose fixture updated; CI validation script updated with 3 new assertions

Closes #26

## Test plan

- [ ] `npm test` passes (both fixtures)
- [ ] Fixture score block matches spec numbers (4/10 current, 9/10 projected, per-platform table)
- [ ] `## Context Health Score` appears before `## Dimension Evaluation` in fixture
- [ ] Known Patterns section present at end of skill body with correct algorithm
EOF
)"
```

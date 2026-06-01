# Phase 4 RECOMMEND — Turns-Saved Metric + Suppression Filter

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Phase 4 (RECOMMEND) of the context-optimizer skill with turns-saved as the primary impact metric and a hard filter suppressing recommendations that save fewer than 3 turns.

**Architecture:** TDD-first — write the expected output fixture before touching the skill body. Three files change: the fixture (TDD anchor), `docs/ARCHITECTURE.md` (spec update), and `skill/context-optimizer.md` (stub → full implementation). Phase 4 maps each diagnosis gap to a Known Pattern, looks up a hardcoded turns-saved estimate, applies the filter, and emits a structured RECOMMEND report.

**Tech Stack:** Markdown skill (natural-language procedure for Claude Code), YAML examples in ARCHITECTURE.md, fixture-based TDD.

**Spec:** `docs/superpowers/specs/2026-06-01-phase4-turns-saved-design.md`

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `examples/after/diagnose-fixture-recommend-report.md` | Create | TDD anchor — exact expected RECOMMEND output for the diagnose-fixture project |
| `docs/ARCHITECTURE.md` | Modify (lines ~205–249) | Phase 4 spec: add turns_saved/suppressed to YAML, update table, remove no-filter statement, add filter rule + suppressed section spec |
| `skill/context-optimizer.md` | Modify (line 157) | Replace Phase 4 stub with full procedure |

---

## Task 1: Write the TDD fixture (RED)

**Files:**
- Create: `examples/after/diagnose-fixture-recommend-report.md`

This is the TDD anchor. It defines what Phase 4 MUST produce when invoked against `examples/before/diagnose-fixture/`. Write it before touching the skill.

The fixture is based on the `diagnose-fixture` diagnosis report (see `examples/after/diagnose-fixture-diagnosis-report.md`), which found:

| Platform | In-flight | Startup | Other gaps |
|---|---|---|---|
| Claude Code | present-weak (static `Current PR: #42`) | missing | Layer 3/4 contamination |
| Cursor | missing | missing | identity=missing, workflow=present-weak |
| Cross-tool | missing | missing | identity=present-weak |
| All | — | — | Canonical-source: "Never force-push to main" in both CLAUDE.md + AGENTS.md |

Pattern mapping:
- Claude Code startup missing → `layer-0-startup-guide` (2–3 turns) → active
- Static in-flight + contamination → `dynamic-in-flight` (2–4 turns) → active (full fix); `static-in-flight-fallback` (1–2 turns) → suppressed (lightweight alternative)
- Cursor/Cross-tool gaps → `cross-tool-agents-md` (2–3 turns) → active
- Canonical-source dedup → `canonical-source-dedup` (1 turn) → suppressed
- No stage-contract: diagnose-fixture stage signal score < 4

Ordering of active recs by turns_saved upper bound descending, then maintenance ascending:
- R-1: `dynamic-in-flight` max=4 > R-2/R-3 max=3 → first
- R-2: `layer-0-startup-guide` max=3, maint=zero → before R-3 (maint=low)
- R-3: `cross-tool-agents-md` max=3, maint=low → last

- [ ] **Step 1: Create the fixture file**

Create `examples/after/diagnose-fixture-recommend-report.md` with this exact content:

```markdown
---RECOMMEND-REPORT-START---

# Recommend Report — acme-cli

## Active Recommendations

| ID  | Title                                         | Turns saved | +tokens | Maint |
|-----|-----------------------------------------------|-------------|---------|-------|
| R-1 | Replace static in-flight with dynamic gh hook | 2–4/session |      20 | zero  |
| R-2 | Add Session Startup section to CLAUDE.md      | 2–3/session |      50 | zero  |
| R-3 | Expand AGENTS.md with cross-tool context      | 2–3/session |      30 | low   |

## Token Detail

**R-1:** +20 tokens/session (~0.01s latency, negligible). Estimated savings: 300 tokens/session avoided.
**R-2:** +50 tokens/session (~0.03s latency, negligible). Estimated savings: 400 tokens/session avoided.
**R-3:** +30 tokens/session (~0.02s latency, negligible). Estimated savings: 200 tokens/session avoided.

## Suppressed Recommendations (< 3 turns threshold)

| Pattern                     | Turns saved | Reason suppressed   |
|-----------------------------|-------------|---------------------|
| `static-in-flight-fallback` | 1–2         | max 2 < threshold 3 |
| `canonical-source-dedup`    | 1           | max 1 < threshold 3 |

---RECOMMEND-REPORT-END---
```

- [ ] **Step 2: Commit the RED anchor**

```bash
git add examples/after/diagnose-fixture-recommend-report.md
git commit -m "test: add diagnose-fixture recommend expected output (RED)"
```

---

## Task 2: Update ARCHITECTURE.md Phase 4 spec

**Files:**
- Modify: `docs/ARCHITECTURE.md` (lines ~205–249)

Four changes in the Phase 4 section:
1. YAML example: add `turns_saved` + `suppressed` fields, update ordering comment
2. Table: replace `-tokens` column with `Turns saved`
3. Remove the "no filter" sentence
4. Add filter rule + suppressed section spec

- [ ] **Step 1: Update the YAML example**

Find this block in `docs/ARCHITECTURE.md` (around line 211):

```yaml
recommendation:
  id: REC-001
  title: "Expand CLAUDE.md with Quick Start section"
  pattern: layer-0-startup-guide       # from Known Patterns
  rationale: "CLAUDE.md is auto-loaded; without a startup section, agents waste turns discovering basics"
  changes:
    - file: CLAUDE.md
      operation: add_section
      content: |
        # <project name>
        **What it is:** ...
        **Workflow:** ...
        ## Session Startup
        Read: <files>
        Run: <commands>
  token_cost_per_session: 50          # tokens added to every session
  estimated_savings_per_session: 600  # tokens avoided in discovery
  maintenance: zero                    # zero | low | manual
  caveats: []                          # populated for cross-agent recommendations
```

Replace with:

```yaml
recommendation:
  id: REC-001
  title: "Expand CLAUDE.md with Quick Start section"
  pattern: layer-0-startup-guide       # from Known Patterns
  rationale: "CLAUDE.md is auto-loaded; without a startup section, agents waste turns discovering basics"
  changes:
    - file: CLAUDE.md
      operation: add_section
      content: |
        # <project name>
        **What it is:** ...
        **Workflow:** ...
        ## Session Startup
        Read: <files>
        Run: <commands>
  turns_saved: "2–3"                   # primary metric — discovery turns eliminated per session
  token_cost_per_session: 50           # secondary — tokens added to every session
  estimated_savings_per_session: 600   # secondary — tokens avoided in discovery
  maintenance: zero                    # zero | low | manual
  suppressed: false                    # true when turns_saved upper bound < 3
  caveats: []                          # populated for cross-agent recommendations
```

- [ ] **Step 2: Update the ordering comment**

Find: `**Ordering:** Descending by \`estimated_savings_per_session\`.`

Replace with: `**Ordering:** Descending by \`turns_saved\` upper bound. Ties broken by \`maintenance\` ascending (zero < low < manual).`

- [ ] **Step 3: Update the presentation table**

Find:

```
| ID  | Title                                     | +tokens | -tokens | Maint  |
|-----|-------------------------------------------|---------|---------|--------|
| R-1 | Expand CLAUDE.md with Quick Start         |     50  |    600  | zero   |
| R-2 | Add dynamic gh hook for in-flight state   |     20  |    300  | zero   |
| R-3 | Move stable identity to memory files      |      0  |    150  | zero   |
| R-4 | Deduplicate rules btw CLAUDE.md/AGENTS.md |      0  |     80  | low    |
| ... | ...                                       |   ...   |   ...   | ...    |
```

Replace with:

```
| ID  | Title                                     | Turns saved  | +tokens | Maint  |
|-----|-------------------------------------------|--------------|---------|--------|
| R-1 | Add dynamic gh hook for in-flight state   | 2–4/session  |      20 | zero   |
| R-2 | Expand CLAUDE.md with Quick Start         | 2–3/session  |      50 | zero   |
| R-3 | Unify rules in AGENTS.md                  | 2–3/session  |       0 | low    |
```

- [ ] **Step 4: Replace the no-filter statement and add filter rule**

Find:

```
The user selects which recommendations to apply. **The skill does not filter by ROI threshold.** It shows the data and asks: *Which of the above should be applied?*

**Output:** Approved recommendation set.
```

Replace with:

```
**Filter rule:** Recommendations with a `turns_saved` upper bound < 3 are suppressed — excluded from the active table, included in the `## Suppressed Recommendations (< 3 turns threshold)` section of the RECOMMEND report. The threshold is fixed at 3 and is not configurable.

**Suppressed section:** Suppressed recommendations appear in the RECOMMEND report for auditability and are passed to Phase 5 to write under `## Suppressed (< 3 turns threshold)` in `context-spec.md`.

After presenting the active table, the skill asks: *Which of the above should be applied?*

**Output:** Approved recommendation set (active only) + suppressed list for Phase 5.
```

- [ ] **Step 5: Commit**

```bash
git add docs/ARCHITECTURE.md
git commit -m "docs: update ARCHITECTURE.md Phase 4 spec with turns-saved metric and filter rule"
```

---

## Task 3: Implement Phase 4 skill body

**Files:**
- Modify: `skill/context-optimizer.md` (line 157 — Phase 4 stub)

Replace the single stub line with the full Phase 4 procedure. The procedure instructs Claude (the skill executor) how to run Phase 4.

- [ ] **Step 1: Replace the Phase 4 stub**

Find this line in `skill/context-optimizer.md`:

```
Stub: Generating prioritized recommendations with token cost, estimated savings, and mandatory Known Pattern mapping (or ad-hoc tagging). After presenting recommendations: if the user approves, **proceed immediately to Phase 5 — IMPLEMENT**; if the user provides feedback or rejects, refine the recommendations and re-present before proceeding.
```

Replace the entire Phase 4 section content (the stub line only — keep the `### Phase 4 — RECOMMEND` header) with:

```markdown
**Purpose:** Translate diagnosis into a prioritized, transparent list of proposed changes, expressed in turns saved (not raw tokens). Suppress low-impact recommendations below the 3-turns-saved threshold.

**Inputs:** The Scan Report, Diagnosis Report, and Ask Report from Phases 1–3.

**Turns-Saved Lookup Table** (hardcoded — do not deviate):

| Pattern | Turns saved | Suppressed? |
|---|---|---|
| `dynamic-in-flight` | 2–4 | no |
| `layer-0-startup-guide` | 2–3 | no |
| `cross-tool-agents-md` | 2–3 | no |
| `stage-contract` | 3–5 | no |
| `static-in-flight-fallback` | 1–2 | yes |
| `layer-3-extraction` | 1–2 | yes |
| `canonical-source-dedup` | 1 | yes |
| `section-routing` | 1 | yes |

For any gap or violation that does not map to a Known Pattern above, assign `turns_saved: "1–2"` and do **not** suppress (conservative default — show unknown patterns to the user).

**Procedure:**

1.  **Generate recommendations.** For each `missing` or `present-weak` dimension and each violation (Layer 3/4 contamination, canonical-source, size over-limit) in the Diagnosis Report, generate one recommendation. Map each to the closest Known Pattern from the lookup table above. Use the pattern that best describes the fix, not the symptom.

2.  **Look up turns_saved.** For each recommendation, read `turns_saved` from the table. For ad-hoc (no matching pattern), use `"1–2"`.

3.  **Apply filter.** Parse the upper bound of `turns_saved` (the number after `–`, or the single number if no range). If upper bound < 3, mark the recommendation as suppressed.

4.  **Order active recommendations.** Sort non-suppressed recommendations by `turns_saved` upper bound descending. Break ties by maintenance ascending: zero < low < manual.

5.  **Estimate token cost.** For each active recommendation, estimate:
    *   Adding a `CLAUDE.md` section (≈ 30–60 lines): `token_cost_per_session: 50`, `estimated_savings_per_session: 400`
    *   Adding a hook script: `token_cost_per_session: 20`, `estimated_savings_per_session: 300`
    *   Expanding or creating `AGENTS.md`: `token_cost_per_session: 30`, `estimated_savings_per_session: 200`
    *   Deduplication only: `token_cost_per_session: 0`, `estimated_savings_per_session: 80`
    Use these as order-of-magnitude estimates — do not over-engineer.

6.  **Emit the RECOMMEND report.** Produce a block delimited by `---RECOMMEND-REPORT-START---` and `---RECOMMEND-REPORT-END---`. Start with `# Recommend Report — {project name}`, then these 3 sections in order:
    *   `## Active Recommendations` — table with columns `ID | Title | Turns saved | +tokens | Maint`. Format `Turns saved` as `N–M/session` (or `N/session` for single values). If no active recommendations, render `✅ No actionable recommendations found.`
    *   `## Token Detail` — one line per active recommendation: `**R-N:** +X tokens/session (~Ys latency, negligible). Estimated savings: Z tokens/session avoided.` Omit this section if no active recommendations.
    *   `## Suppressed Recommendations (< 3 turns threshold)` — table with columns `Pattern | Turns saved | Reason suppressed`. Use format `max N < threshold 3` in the reason column. Render `✅ None suppressed` if all recommendations pass the filter.

7.  **Present active recommendations.** After the report block, ask the user: *Which of the above should be applied?*
    *   If the user approves all or a subset → record the approved set and **proceed immediately to Phase 5 — IMPLEMENT**.
    *   If the user provides feedback or rejects → refine the recommendations and re-present before proceeding.
```

- [ ] **Step 2: Verify the Phase 4 section looks correct**

Open `skill/context-optimizer.md` and confirm:
- `### Phase 4 — RECOMMEND` header is present
- The stub line is gone
- The new procedure ends before `### Phase 5 — IMPLEMENT`
- No formatting errors (tables render, no broken markdown)

- [ ] **Step 3: Commit**

```bash
git add skill/context-optimizer.md
git commit -m "feat: implement Phase 4 RECOMMEND with turns-saved metric and suppression filter"
```

---

## Task 4: Manual GREEN verification

**Files:**
- Read: `examples/before/diagnose-fixture/` (input)
- Read: `examples/after/diagnose-fixture-recommend-report.md` (expected)

Manually invoke the skill against the diagnose-fixture project and compare the RECOMMEND output to the expected fixture.

- [ ] **Step 1: Invoke the skill**

Open a new Claude Code session in `examples/before/diagnose-fixture/`. Run:

```
/skill context-optimizer
```

Let it run through Phase 1 (SCAN), Phase 2 (DIAGNOSE), Phase 3 (ASK), and Phase 4 (RECOMMEND). Copy the content between `---RECOMMEND-REPORT-START---` and `---RECOMMEND-REPORT-END---` from the output.

- [ ] **Step 2: Compare actual vs expected**

Compare the copied output to `examples/after/diagnose-fixture-recommend-report.md`. Check:
- Active recommendations table: same rows, same order (R-1=dynamic-in-flight, R-2=layer-0-startup-guide, R-3=cross-tool-agents-md)
- Turns saved values match
- Token detail section present with correct values
- Suppressed table: `static-in-flight-fallback` and `canonical-source-dedup` present

- [ ] **Step 3: Iterate if needed**

If actual ≠ expected:
- Identify which part of the Phase 4 procedure produced incorrect output
- Edit `skill/context-optimizer.md` to fix the procedure
- Re-invoke and re-compare
- Commit each fix: `fix: Phase 4 <description of fix>`

- [ ] **Step 4: Commit GREEN**

Once actual output matches expected fixture:

```bash
git commit --allow-empty -m "test: Phase 4 RECOMMEND output matches diagnose-fixture (GREEN)"
```

(Use `--allow-empty` only if no further code changes were needed in Step 3 — otherwise commit the actual changes instead.)

---

## Task 5: Advance PDLC stage

- [ ] **Step 1: Move issue to stage:approval**

```bash
gh issue edit 27 --add-label "stage:approval" --remove-label "stage:detailing"
```

- [ ] **Step 2: Confirm**

Run `gh issue view 27` and verify label shows `stage:approval`.

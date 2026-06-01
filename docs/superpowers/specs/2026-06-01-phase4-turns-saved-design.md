# Design — Phase 4 RECOMMEND: Turns-Saved Metric + Suppression Filter

**Issue:** #27
**Date:** 2026-06-01
**Status:** Approved

---

## Problem

Phase 4 (RECOMMEND) is currently a stub. The ARCHITECTURE.md spec designs it around `token_cost_per_session` / `estimated_savings_per_session` metrics. Raw token numbers are meaningless to most developers ($0.00005 per 30 tokens). What matters is how many back-and-forth discovery turns an agent wastes per session.

Additionally, the current spec explicitly states "skill does NOT filter by ROI threshold" — showing low-impact recommendations that cost more cognitive overhead to review than they save.

---

## Decision

Replace token numbers with **turns saved** as the primary metric. Keep token numbers as secondary detail for power users. Suppress recommendations with estimated turns saved < 3 (hardcoded threshold — YAGNI, not configurable).

---

## Data Model

Each recommendation gains `turns_saved` (primary) and `suppressed` fields. Token fields remain as secondary.

```yaml
recommendation:
  id: REC-001
  title: "Expand CLAUDE.md with Quick Start section"
  pattern: layer-0-startup-guide
  rationale: "CLAUDE.md is auto-loaded; without a startup section, agents waste turns discovering basics"
  changes:
    - file: CLAUDE.md
      operation: add_section
      content: |
        ## Session Startup
        Read: <files>
        Run: <commands>
  turns_saved: "2–3"                    # primary metric
  token_cost_per_session: 50            # secondary — retained for power users
  estimated_savings_per_session: 600    # secondary — retained for power users
  maintenance: zero
  suppressed: false                     # true when turns_saved upper bound < 3
  caveats: []
```

### Turns-Saved Lookup Table (hardcoded in skill body)

| Pattern | Turns saved | Passes filter (max ≥ 3)? |
|---|---|---|
| `layer-0-startup-guide` | 2–3 | ✅ shown |
| `dynamic-in-flight` | 2–4 | ✅ shown |
| `cross-tool-agents-md` | 2–3 | ✅ shown |
| `stage-contract` | 3–5 | ✅ shown |
| `static-in-flight-fallback` | 1–2 | ❌ suppressed |
| `layer-3-extraction` | 1–2 | ❌ suppressed |
| `canonical-source-dedup` | 1 | ❌ suppressed |
| `section-routing` | 1 | ❌ suppressed |

**Filter rule:** suppress when the upper bound of `turns_saved` range is < 3.

---

## RECOMMEND Report Format

Delimited by `---RECOMMEND-REPORT-START---` / `---RECOMMEND-REPORT-END---`.

```
# Recommend Report — {project name}

## Active Recommendations

| ID  | Title                                     | Turns saved  | +tokens | Maint |
|-----|-------------------------------------------|--------------|---------|-------|
| R-1 | Expand CLAUDE.md with Quick Start         | 2–3/session  |      50 | zero  |
| R-2 | Add dynamic gh hook for in-flight state   | 2–4/session  |      20 | zero  |
| R-3 | Unify rules in AGENTS.md                  | 2–3/session  |       0 | low   |

## Token Detail

**R-1:** +50 tokens/session (~0.03s latency, negligible). Estimated savings: 600 tokens/session avoided.
**R-2:** +20 tokens/session (~0.01s latency, negligible). Estimated savings: 300 tokens/session avoided.
**R-3:** +0 tokens/session. Estimated savings: 80 tokens/session avoided.

## Suppressed Recommendations (< 3 turns threshold)

| Pattern | Turns saved | Reason suppressed |
|---|---|---|
| `static-in-flight-fallback` | 1–2 | max 2 < threshold 3 |
| `canonical-source-dedup`    | 1   | max 1 < threshold 3 |
```

After report: present active recs to user. If approved → Phase 5. If feedback → refine + re-present.

---

## ARCHITECTURE.md Changes

1. YAML example: add `turns_saved` + `suppressed` fields; keep token fields as secondary.
2. Presentation table: replace `+tokens | -tokens` columns with `Turns saved | +tokens`.
3. Remove: `"The skill does not filter by ROI threshold."` (line 247).
4. Add filter rule: recommendations with `turns_saved` upper bound < 3 are suppressed — excluded from Active Recommendations, included in Suppressed section of the RECOMMEND report for Phase 5 to write to `context-spec.md`.

---

## Skill Body Changes

Replace Phase 4 stub (single line) with full procedure:

1. For each gap/violation from Diagnosis Report, map to Known Pattern → look up `turns_saved`.
2. Apply filter: set `suppressed: true` for recs where `turns_saved` max < 3.
3. Order active recs descending by `turns_saved` upper bound.
4. Emit RECOMMEND report (active table + token detail + suppressed table).
5. Present active recs to user. Await approval or feedback.
6. On approval → chain to Phase 5. On feedback → refine + re-present.

---

## TDD Fixture

**New file:** `examples/after/diagnose-fixture-recommend-report.md`

Based on `diagnose-fixture` (acme-cli) diagnosis:

**Active (3 recs):**
- R-1: Add startup section to CLAUDE.md → `layer-0-startup-guide` (2–3 turns)
- R-2: Add dynamic gh hook for in-flight state → `dynamic-in-flight` (2–4 turns)
- R-3: Expand AGENTS.md to cover Cursor gaps → `cross-tool-agents-md` (2–3 turns)

**Suppressed (2 recs):**
- `static-in-flight-fallback` — replace static `Current PR: #42` line (1–2 turns, max < 3)
- `canonical-source-dedup` — dedup "Never force-push to main" across CLAUDE.md + AGENTS.md (1 turn, max < 3)

No `stage-contract` — diagnose-fixture stage signal score < 4.

---

## Implementation Order (TDD)

1. Write `examples/after/diagnose-fixture-recommend-report.md` (RED anchor — before any skill changes)
2. Update `docs/ARCHITECTURE.md` Phase 4 spec
3. Implement `skill/context-optimizer.md` Phase 4 procedure
4. Manual invoke against `examples/before/diagnose-fixture/` → compare actual vs expected (GREEN)
5. Commit sequence: `test: add diagnose-fixture recommend expected output (RED)` → `feat: ...` → `refactor: ...`

---

## Out of Scope

- Phase 5 `context-spec.md` suppressed section write — deferred (Phase 5 is still a stub; that's a separate issue).
- Making threshold configurable — YAGNI.
- Ad-hoc pattern turns-saved estimates (patterns not in lookup table) — handle in Phase 4 implementation as "unknown pattern → conservative estimate, no suppression".

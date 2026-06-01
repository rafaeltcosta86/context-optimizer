# Design: Phase Chaining Fix — Output-Anchor Pattern

**Date:** 2026-06-01
**Issue:** #24 — skill Phase 1 pauses and asks permission before Phase 2
**Status:** Approved

## Problem

After Phase 1 emits `---SCAN-REPORT-END---`, the model generates `"Phase 1 complete. Proceed to Phase 2 — DIAGNOSE?"` instead of chaining automatically. Prior fixes (PR #20, #21) added `"proceed immediately to Phase N+1"` at the END of each phase section — same structural approach, same failure across 3 attempts.

**Root cause:** End-of-phase instructions are weak anchors. By the time the model finishes generating a 50+ line Scan Report, the instruction is contextually distant and the model's "check in with user" instinct overrides it.

## Design

### 1. Pipeline Preamble

Add a pipeline execution contract block at the TOP of `## Procedure`, before `### Phase 1 — SCAN`. The model reads the no-stop contract before any tool call happens.

```markdown
**Pipeline execution contract:** This skill runs as a single uninterrupted pipeline in one response. Do NOT stop, summarize, or ask for confirmation between phases. Do NOT ask "Should I proceed?" between phases. The only permitted pause points are:
- **Phase 3** — when questions need to be asked: stop and wait for user response
- **Phase 4** — after emitting recommendations: stop and wait for user approval or feedback

All other phase transitions are automatic. Begin Phase 1 immediately.
```

### 2. Output-Anchor Lines

Add a mandatory continuation line inside each report block. The model writes this as its own output — making continuation part of its generated text rather than a separate instruction to obey.

**Phase 1 report (last line before closing delimiter):**
```
**→ Scan complete. Proceeding to Phase 2 — DIAGNOSE immediately.**
```

**Phase 2 report (last line before closing delimiter):**
```
**→ Diagnosis complete. Proceeding to Phase 3 — ASK immediately.**
```

**Phase 3 report — conditional:**
- 0 questions needed: include `**→ Ask complete. Proceeding to Phase 4 — RECOMMEND immediately.**`
- Questions asked: omit anchor line; model stops and waits for user response before emitting the ASK report

### 3. Existing Footer Instructions

The existing `"proceed immediately"` instructions at the end of each phase section are retained as secondary reinforcement. No removal needed.

## Files to Modify

- `skill/context-optimizer.md` — add preamble + anchor lines per phase report format

## Acceptance Criteria

- Invoking `/skill context-optimizer` runs Phase 1 → Phase 2 → Phase 3 without pausing between phases
- Skill only pauses at Phase 3 if questions need to be asked (normal-state with triggers, or weak-state)
- CI fixture test validates chained output (SCAN-REPORT + DIAGNOSIS-REPORT + ASK-REPORT in single run)

## What This Does NOT Change

- Report delimiter format (anchor line is inside the block, not a new delimiter)
- Phase 3 pause behavior when questions are asked
- Phase 4 approval wait behavior
- Phase 5 stub

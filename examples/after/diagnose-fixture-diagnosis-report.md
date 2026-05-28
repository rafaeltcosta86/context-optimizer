---DIAGNOSIS-REPORT-START---

# Diagnosis Report — diagnose-fixture

## Dimension Evaluation

| Platform | Identity | Workflow | In-flight | Startup | Duplication |
|---|---|---|---|---|---|
| Claude Code | present-good | present-good | present-weak | missing | duplicated |
| Cursor | missing | missing | missing | missing | missing |
| Gemini | missing | missing | missing | missing | missing |
| Cross-tool | missing | present-weak | missing | missing | duplicated |

## Layer 3/4 Contamination

- `CLAUDE.md`: Contains volatile state ("Current PR") which pollutes stable Layer 3 context.

## Canonical-Source Violations

- **Violation:** Rule "Always write tests before code." is duplicated.
  - `CLAUDE.md`
  - `AGENTS.md`

## Size Compliance

- `docs/dev.md`: 250 lines exceeds the 200-line limit for reference files.

## Auto-Load Coverage

- Orphaned content detected: `AGENTS.md` rules are not referenced in the auto-loaded `CLAUDE.md`.
- Orphaned content detected: `docs/dev.md` is not referenced in any auto-loaded file.

## Diagnosis Summary

- **Stale In-flight Signal:** `docs/dev.md` is > 7 days old and may contain stale information.
- **Critical Issues:** Duplication of workflow rules between `CLAUDE.md` and `AGENTS.md`; Layer 3/4 contamination in `CLAUDE.md`.
- **Recommendation Path:** Consolidate rules into `AGENTS.md`, remove volatile state from `CLAUDE.md`, and add a Startup section referencing reference docs.

---DIAGNOSIS-REPORT-END---

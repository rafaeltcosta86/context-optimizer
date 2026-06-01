---SCAN-REPORT-START---

# Scan Report — my-hello-app

**Scanned:** `examples/before/hello-fixture/`
**Project type:** npm package (`package.json` → name: `my-hello-app`)
**Summary:** A simple hello world CLI application.

---

## Detected Agent Platforms

| Platform | Status | Files found |
|---|---|---|
| Claude Code | ✅ present | `CLAUDE.md` (5 lines) |
| Cursor | ❌ absent | `.cursorrules` — not found; `.cursor/rules/` — not found |
| Gemini CLI / Antigravity | ❌ absent | `GEMINI.md` — not found; `.gemini/` — not found |
| Cross-tool | ❌ absent | `AGENTS.md` — not found |

---

## Context File Details

### `CLAUDE.md` (5 lines)
- Has startup section: **No**
- Has workflow rules: **No**
- Has invariants: **No**
- Content: project name + 2-line description only

---

## Hooks

| Hook | Status |
|---|---|
| `.claude/hooks/` | ❌ not found |
| Global `~/.claude/hooks/session-start.sh` | ❌ not found |

---

## Memory

- `~/.claude/projects/*/memory/MEMORY.md`: ❌ not found
- Memory entries: 0

---

## Git

**Not a git repository** — git metadata steps skipped.

---

## In-Flight State (gh)

**Skipped** — project is not a git repository.

---

## Stage Signals

| Signal type | Detected |
|---|---|
| Agent config with workflow rules | ❌ |
| Stage-gate labels (gh) | skipped |
| Sequential folders or numbered stages | ❌ |
| Hook emitting in-flight state | ❌ |

**Total signals: 0**

> ⚠️ Signal count < 3 — Phase 3 will trigger the weak-state fallback (3-question dialog).

**→ Scan complete. Proceeding to Phase 2 — DIAGNOSE immediately.**

---SCAN-REPORT-END---
---DIAGNOSIS-REPORT-START---

# Diagnosis Report — acme-cli

**Source:** Scan Report for `examples/before/diagnose-fixture/`
**Status legend:** present-good · present-weak · missing · duplicated

---

## Dimension Evaluation

| Platform | Identity | Workflow | In-flight | Startup | Duplication |
|---|---|---|---|---|---|
| Claude Code | present-good | present-good | present-weak | missing | duplicated |
| Cursor | missing | present-weak | missing | missing | present-good |
| Cross-tool (AGENTS.md) | present-weak | present-good | missing | missing | duplicated |

---

## Layer 3/4 Contamination

| File | Status | Detail |
|---|---|---|
| `CLAUDE.md` | ⚠️ flagged | Static in-flight state `Current PR: #42` (Layer 4) inside a stable-identity file (Layer 3). Goes stale; emit via dynamic hook instead. |

---

## Canonical-Source Violations

| Rule | Appears in |
|---|---|
| "Never force-push to main" | `CLAUDE.md`, `AGENTS.md` |

---

## Size Compliance

| File | Lines | Limit | Status |
|---|---|---|---|
| `CLAUDE.md` | 13 | 150 | ✅ |
| `AGENTS.md` | 6 | 200 | ✅ |
| `.cursorrules` | 1 | 150 | ✅ |

---

## Auto-Load Coverage

| Orphan content | Location | Issue |
|---|---|---|
| Build / test commands | `docs/dev.md` | Not referenced from any auto-loaded (Layer 0) file — agent must discover it. |

---

## Diagnosis Summary

- Platforms evaluated: 3
- Gaps (missing + present-weak): 9
- Violations (contamination + canonical-source + size): 2
- Weak-state: No — usable signals ≥ 3

**Diagnosis complete.**
**→ Diagnosis complete. Proceeding to Phase 3 — ASK immediately.**

---DIAGNOSIS-REPORT-END---
---ASK-REPORT-START---

# Ask Report — acme-cli

**Mode:** normal-state
**Signal count:** 3

## Questions Asked

1. Do you want dynamic in-flight queries (requires `gh auth login`) or a static roadmap file (you maintain manually)?

## Answers Received

1. Static roadmap file.

**Ask complete.**

---ASK-REPORT-END---

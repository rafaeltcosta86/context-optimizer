# context-optimizer — AI Agent Instructions

This template is the contract between the project and any external AI agent
(Claude Code, Cursor, Copilot, Jules, Codex, Sweep, etc.). Read this before committing any change.

## Project Overview

Host-portable Claude Code skill that scans any project and recommends token-efficient context optimizations for new AI agent sessions. The skill detects session-start context gaps and produces a prioritized, token-cost-transparent recommendation set for the developer to approve.

**Structure:**
```
skill/context-optimizer.md    ← the skill itself (Claude Code v1.0)
docs/                         ← specification (PRD, ARCHITECTURE, COMPETITIVE_ANALYSIS, IMPLEMENTATION_GUIDE, SPEC_README)
examples/before/              ← input fixture projects (test inputs)
examples/after/               ← expected output reports (TDD anchors — write FIRST)
known-patterns/               ← extracted Known Patterns library (if skill grows > 1200 lines)
```

## Before Any Change

```bash
git fetch origin && git checkout main && git pull
```

Always start from the current `main` HEAD. Never work over stale snapshots.

## Invariants / Non-negotiable business rules

### I-1: eXtreme Programming + TDD (methodology invariant)
1. **Walking skeleton over horizontal scaffolds.** Every phase ships a real, testable, end-to-end capability. A phase with no testable user outcome must be replanned.
2. **Red → Green → Refactor.** No production code (skill body, hook, fixture) without a failing test first. For Markdown skills, the "test" is a fixture pair: input project under `examples/before/<name>/` + expected output under `examples/after/<name>-<report>.md`. Write the expected output FIRST, then iterate the skill body until it matches.
3. **Small steps, fast feedback.** Commit after every red/green/refactor transition. Never batch multiple feature steps in one commit.
4. **Simple design + YAGNI.** Refactor only when tests force it. No future-proofing.
5. **Continuous integration.** Every commit must leave `main` in a runnable, validated state.
6. **Reference:** Invoke `superpowers:test-driven-development` before any implementation step.

### C-1: No source code modification
The skill must never modify source code — only context configuration files (`CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `AGENTS.md`, memory files, `docs/`).

### C-2: Non-destructive writes only
The skill must never delete user content. All "replace" operations are non-destructive merges with explicit per-change user consent.

### C-3: Single-session, no external dependencies
The skill must run inside a single Claude Code (or Cursor / Gemini-Antigravity) session with default tool access. No external service dependencies (no RAG, no remote APIs, no DB).

### C-4: Single-file install
v1.0 must be installable as a single `.md` file dropped into `~/.claude/skills/`. No package manager, no daemon, no setup script.

### C-5: Layer 3 / Layer 4 separation
Stable identity (project purpose, invariants, workflow rules) → memory files or `docs/`. Volatile in-flight state (current PR, active issue) → dynamic hooks. These must never appear in the same file.

### C-6: Cross-host caveats
Every file the skill writes for a host it is NOT currently running inside (e.g., writing `.cursorrules` from Claude Code) must include a caveat header declaring it was generated cross-host and may need user verification.

### C-7: Audit record mandatory
`context-spec.md` must be produced on every implementation phase invocation, even when only 1 recommendation is applied.

### C-8: Known Patterns mapping
Every recommendation must map to a named Known Pattern OR be tagged `ad-hoc`. No untagged recommendations.

### C-9: Procedure identity across ports
The skill's 5-phase procedure + Known Patterns + layer model must remain identical across v1.0 (Claude Code), v1.1 (Cursor), v1.2 (Gemini/Antigravity). Only the invocation mechanism and write paths differ.

### Human-in-the-Loop
No external side-effect actions (writing files, pushing changes, modifying configs) without explicit human approval per action. Phases 1–4 of the skill are read-only. Phase 5 writes only after the user approves each recommendation individually.

## Mandatory Workflow

0. **Identity**: Always prefix your GitHub comments with `🤖 **Agent:** ` to distinguish yourself.
1. **Initial State**: When beginning work on a new issue, your very first action must be to apply the `stage:exploration` label using the GitHub CLI (`gh issue edit <N> --add-label "stage:exploration"`).
2. Read the issue entirely — understand its type (US/BUG/TASK/SPIKE) and the Acceptance Criteria.
3. Read `docs/pdlc.md` — understand the PDLC and the Definition of Done in this project.
4. Read all files mentioned in the issue's technical context.
5. Implement the **minimum viable change** that satisfies the ACs — do not refactor beyond scope.
6. Run tests: `No automated test runner in Phase 1 — verify fixtures manually: diff examples/after/<fixture>-report.md <actual-output>.md`
7. Create a Pull Request with `Closes #N` in the body — automation moves the board.

### Spec format (Upstream Agents)

When detailing a solution in an issue body, you must **always** include both the user story and the acceptance criteria. Never append only the ACs to an existing text; rewrite the full issue body in this standard format:

```
**As** [user],
**I want** [action],
**so that** [benefit].

---

## Acceptance Criteria

**AC1 — ...**
- Given ...
- When ...
- Then ...

**AC2 — ...**
...

## Files to modify
- `path/to/file.md` — what changes
```

## Pipeline Updates

To add or configure optional agents (Jules, QA Agent, Sentinel) at any time:

```bash
npx create-agentic-pdlc --update
```

## What NOT to do

- Never commit directly to `main`.
- Never open a PR without passing the tests (or manually verifying fixtures).
- Never implement beyond the immediate scope of the issue.
- Never create future-proofing abstractions for hypothetical features.
- Never add or remove `stage:*` or `qa:*` labels manually. These are owned by GitHub Actions automation and the PM only.
- **Labels reserved for the PM (human) ONLY — agent MUST NOT apply these under any circumstances:**
  - `spec:approved` — triggers Jules dispatch + board card move to Development
  - `qa:approved` — triggers board card move to Code Review / PR
  - `qa:needs-work` — triggers rework loop
- Never invoke the skill on itself recursively (do not run `context-optimizer` with the context-optimizer repo as target while developing it — use `examples/` fixtures instead).
- Never auto-apply skill recommendations without explicit per-recommendation user approval.
- Never write Phase 5 (implement) code before the Phase 1–4 read-only phases complete and user consents.

## Capability Tests (board automation smoke tests)

When verifying board automation without shipping a real feature:

1. Create the test issue. Observe it appears in the Idea column — this verifies `Add to Board on Open`.
2. To test the `spec:approved → Development` flow: **ask the user (navigator) to add the label manually**. The agent must never add `spec:approved` on any issue, including test issues.
3. After the user confirms the card moved: close the issue with `gh issue close <N> --reason "not planned" --comment "Capability test passed. Closing."`.
4. Manually archive the card from the board via the GitHub Projects UI or `archiveProjectV2Item` GraphQL mutation.
5. Strip any automation-added labels (`stage:development`, `agent:jules`, `agent:working`) using `gh issue edit <N> --remove-label`.

## Project Standards

- **Tests:** No automated test runner in Phase 1 — verify fixtures manually
- **Lint/Types:** Not configured (Markdown skill — no runtime)
- **Typecheck:** Not applicable
- **Build:** Not applicable

### TDD Fixture Convention
Every procedure change in `skill/context-optimizer.md` must be validated against `examples/`. The fixture pair is the test:
1. Author `examples/after/<fixture>-<report>.md` FIRST (the expected output)
2. Update the skill body until the actual output matches
3. Commit: red (fixture), green (skill body), refactor (cleanup)

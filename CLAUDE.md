# context-optimizer — Project Briefing

## Project Identity

This repo implements `context-optimizer` — a host-portable Claude Code skill that scans any project and recommends token-efficient context optimizations for new AI agent sessions.

**Specification is canonical.** All design decisions live in `docs/`:
- `docs/SPEC_README.md` — reading order and glossary
- `docs/PRD.md` — problem, goals, success criteria, release roadmap
- `docs/ARCHITECTURE.md` — 5-phase skill design, layer model, constraints
- `docs/COMPETITIVE_ANALYSIS.md` — positioning, scope boundaries
- `docs/IMPLEMENTATION_GUIDE.md` — phased build plan, specialist skill mapping

Do not re-derive from memory — read them.

## PDLC Framework

This project runs on **agentic-pdlc**. Read `AGENTS.md` before any commit. Read `docs/pdlc.md` for the board layout and Definition of Done.

Every issue flows: 💡 Idea → 🔍 Exploration → 🧠 Brainstorming → 📐 Detail Solution → ✅ Approval → ⚙️ Development → 🧪 Testing → 👁 Code Review / PR → 🚀 Ready for Production.

**PDLC stage gate:** `gh pr create` is blocked by `.claude/settings.json` PreToolUse hook unless the linked issue has `stage:approval` or `stage:development` label. Never bypass except on `hotfix/` branches with explicit PM instruction.

## Hard Invariants (non-negotiable)

### I-1: eXtreme Programming + TDD
All v1.0 development of this skill MUST follow XP practices and TDD:

- **Walking skeleton over horizontal scaffolds.** Every phase ships a real, testable, end-to-end capability. A phase with no testable user outcome must be replanned before execution begins.
- **Red → Green → Refactor.** No production code (skill body, hook, fixture, CI config) without a failing test first. For Markdown skills, the "test" is a fixture pair: input project under `examples/before/<name>/` + expected output under `examples/after/<name>-<report>.md`. Write the expected output FIRST, then iterate the skill body until it matches.
- **Small steps, fast feedback.** Commit after every red/green/refactor transition. Never batch multiple feature steps in one commit. Every commit must be green (CI passes, fixtures match).
- **Pair programming.** The user is the navigator; the agent is the driver. The agent proposes nothing without explicit user consent for that step.
- **Continuous integration.** Every commit must leave `main` in a runnable, validated state. No WIP commits to `main`.
- **Simple design + YAGNI.** Refactor only when tests force it. Never add functionality "for later". No YAGNI violations.
- **Collective ownership.** The skill markdown body is code — its sections are testable contracts. Any contributor can improve any section.

**How to TDD a Markdown skill** (where unit tests don't fit cleanly):
1. Author `examples/before/<fixture>/` — the input project (CLAUDE.md, README, package.json, etc.)
2. Author `examples/after/<fixture>-<report>.md` — the EXACT expected output (the TDD anchor)
3. Write/update the skill procedure section that produces that output
4. Manually invoke the skill against the fixture and compare actual vs expected
5. Iterate until exact match
6. Commit: `test: add <fixture> expected output (RED)` → `feat: skill Scan produces expected <fixture> output (GREEN)` → `refactor: ...`

**Reference:** Invoke `superpowers:test-driven-development` before any implementation step.

## Workflow Rules

- Read the spec in order declared in `docs/SPEC_README.md` before touching code
- Use `superpowers:writing-plans` to author phase plans; get user approval before executing
- Use the specialist skill mapping from `docs/IMPLEMENTATION_GUIDE.md` §2 at each step
- Phase gates from `docs/IMPLEMENTATION_GUIDE.md` are mandatory — no skipping
- Every phase must deliver a testable, end-to-end capability (I-1 walking-skeleton clause)
- Board automation is authoritative for issue state — do not manually move cards

## What's In Flight

- Phase 0 (PDLC framework install): in progress — board IDs pending PAT creation
- Phase 1 (skill loads + scans): not started — awaits Phase 0 completion
- All later phases: not started

See the GitHub Project Board for the live kanban state.

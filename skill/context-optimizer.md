---
name: context-optimizer
description: Use this skill to scan any project and recommend token-efficient improvements to how new AI agent sessions receive context. Supports Claude Code, Cursor, and Gemini CLI / Antigravity. Use when starting work on a project that doesn't have well-structured session-start context for AI agents.
---

## Purpose
When a developer opens a new Claude Code (or Cursor, or Gemini CLI / Antigravity) session in an existing project, the AI agent often starts with near-zero awareness of the project's identity, workflow, invariants, and current state. This "discovery overhead" forces the agent to spend the first 1–3 turns discovering basics, burning tokens, increasing latency, and diluting attention. `context-optimizer` solves this by diagnosing session-context gaps and recommending token-efficient improvements to ensure agents are productive from turn 1.

## When to Use This Skill
- Starting work on a project that does not have a `CLAUDE.md` or equivalent context file.
- Returning to a project after a long break where context might have drifted.
- Onboarding a new project that needs to support multiple agents (Claude Code, Cursor, Gemini).
- When you suspect existing context files are stale or inconsistent with the current project state.

## What This Skill Does NOT Do
- Provide mid-session memory or RAG-style retrieval for large codebases.
- Orchestrate complex multi-agent pipelines or automated workflow execution.
- Directly modify business logic or source code (it only writes context configuration files).

## Procedure

**Pipeline execution contract:** This skill runs as a single uninterrupted pipeline in one response. Do NOT stop, summarize, or ask for confirmation between phases. Do NOT ask "Should I proceed?" between phases. The only permitted pause points are:
- **Phase 3** — when questions need to be asked: stop and wait for user response
- **Phase 4** — after emitting recommendations: stop and wait for user approval or feedback

**Phase transition format (mandatory):** Each automatic phase transition outputs the opening delimiter of the next phase on the line immediately following either the closing delimiter of the current phase or, if no closing delimiter exists, the last user-visible content — no blank line, no text of any kind between them. Example: `---DIAGNOSIS-REPORT-START---` on the very next line after the Phase 1 status line; `---ASK-REPORT-START---` on the very next line after `---DIAGNOSIS-REPORT-END---`.

All other phase transitions are automatic. Begin Phase 1 immediately by emitting the status line and running tool calls.

### Phase 1 — SCAN

**Purpose:** Gather raw project context via tool calls. No analysis or synthesis occurs in this phase.

**First action (mandatory):** Before any tool calls, output exactly this line to the user:
*Scanning project structure...*

**Procedure (Pure I/O):**

1.  **Glob for agent configurations.** Claude Code (`CLAUDE.md`, `.claude/settings.json`, `.claude/hooks/*`, memory), Cross-tool (`AGENTS.md`), Cursor (`.cursorrules`, `.cursor/rules/*.mdc`), Gemini (`GEMINI.md`, `.gemini/*`, `.agent/workflows/*.md`), Global user-level (`~/.claude/settings.json`, `~/.claude/hooks/session-start.sh`), and reference files (`docs/*.md`, `CONTRIBUTING.md`, `README.md`).
2.  **Read project metadata.** Read found context files, project manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `mix.exs`), and first 30 lines of `README.md`.
3.  **Check environment.** If `test -e .git` passes, run `git rev-parse --abbrev-ref HEAD`, `git log --oneline -5`, and `git status --short`. Additionally, if the `test -e .git` check passed and `gh auth status` passes, run `gh issue list` and `gh pr list`.

**Output Rule:** Phase 1 produces no user-visible output other than the status line. All synthesis (scoring, signals) is deferred to Phase 2.

**Transition (mandatory):** Output `---DIAGNOSIS-REPORT-START---` on the line immediately after the status line (no additional text). Begin Phase 2 content on the line after `---DIAGNOSIS-REPORT-START---`.

### Phase 2 — DIAGNOSE

**Purpose:** Evaluate Phase 1 scan data against 5 dimensions and 4 cross-cutting diagnostics, then emit a structured Diagnosis Report consumed by Phases 3–5. This phase is **read-only** — never write project files here.

**Inputs:** The project data gathered during Phase 1 tool calls (held in context — not rendered to user).

**Procedure:**

1.  **Evaluate the 5 dimensions per detected platform.** For each platform detected during Phase 1 (Claude Code, Cursor, Gemini, Cross-tool/`AGENTS.md`), assign each dimension one status: `present-good`, `present-weak`, `missing`, or `duplicated`.
    *   **Identity:** Does a context file state what the project IS (purpose + type) in its first lines? Full summary → `present-good`; named but no purpose → `present-weak`; absent → `missing`.
    *   **Workflow:** Are mandatory steps, stage gates, or build/test commands documented? Complete → `present-good`; coding-style-only / partial → `present-weak`; absent → `missing`.
    *   **In-flight:** Does the agent see active work? Dynamic SessionStart `gh` hook → `present-good`; static roadmap or "Current PR/issue" line (goes stale) → `present-weak`; none → `missing`.
    *   **Startup:** Is there an explicit "Read X first" / "Run Y on start"? Present → `present-good`; absent → `missing`.
    *   **Duplication:** Does a rule in this file also appear verbatim in another context file? If yes → `duplicated`; if the file's rules are unique → `present-good`. (`duplicated` is a violation, not a gap — it counts toward canonical-source violations, not the gap total.)

2.  **Layer 3/4 contamination check.** Flag any context file mixing stable identity/invariants (Layer 3) with volatile in-flight state (Layer 4) — e.g. a static `Current PR: #N`, "active issue", or "this week's priorities" line inside `CLAUDE.md`/`AGENTS.md`/memory. Report file + offending content + fix (emit via dynamic hook).

3.  **Canonical-source check.** For each non-trivial rule (workflow step, invariant, any "always"/"never" statement), count occurrences across all context files. ≥2 files = violation. Report rule text + the files.

4.  **Size compliance check.** Compare each context file's line count to its limit. Limits by file type:
    *   `CLAUDE.md` — 150 lines
    *   `AGENTS.md` — 200 lines
    *   `GEMINI.md` — 150 lines
    *   `.cursorrules` — 150 lines
    *   Any `.cursor/rules/*.mdc` — 150 lines
    *   Any `CONTEXT.md` — 80 lines
    *   Any other reference file (`docs/`, etc.) — 200 lines
    Report file, lines, limit, ✅ (within) or ⚠️ (over).

5.  **Auto-load coverage check.** Identify rules/commands living only in a non-auto-loaded file (not Layer 0) and not referenced/summarized from the auto-loaded layer. Report each orphan + its location.

6.  **Synthesize scan data.** Perform all data synthesis and scoring:
    *   **Detect stage signals:** Apply the multi-signal heuristic to calculate a weighted stage signals score and a raw scan signal count (**Total signals: {N}**): Numbered folders (1), `output/` subdirectories (2), `README` mentions (2), `CONTEXT.md` (3), sequential GitHub Actions (3), stage labels (3). If the weighted score ≥ 4, recommend stage contracts. If N < 3, trigger weak-state for Phase 3.
    *   **Compute Context Health Score:** Apply the `score-health-computation` Known Pattern using results from Steps 1–5. Record: per-platform aggregate score, overall aggregate, and projected overall score.
    *   **Dimension gaps:** Count distinct P1 dimensions (In-flight, Startup) where at least one platform's score < 8.

7.  **Emit the Diagnosis Report.** Produce a block delimited by `---DIAGNOSIS-REPORT-START---` and `---DIAGNOSIS-REPORT-END---`. Start with `# Diagnosis Report — {project name}`, then two metadata lines: `**Source:** Phase 1 scan of {scanned path}` and `**Status legend:** present-good · present-weak · missing · duplicated`. Then these 7 sections in order:
    *   `## Context Health Score` — `Current: {overall} / 10`, `After recommendations: {projected} / 10 ({delta})`, then a table with columns `Platform | Identity | Workflow | In-flight | Startup | Duplication | Score` (one row per detected platform using per-dimension scores from Step 6, plus a `**Aggregate**` row showing the overall aggregate), then a one-line verdict: `> {N} P1 gaps blocking agent efficiency. Applying top P1+P2 recommendations brings score to {projected}/10.`
    *   `## Dimension Evaluation` — one row per detected platform, columns: `Platform | Identity | Workflow | In-flight | Startup | Duplication`.
    *   `## Layer 3/4 Contamination` — columns `File | Status | Detail`; render `✅ None detected` when clean.
    *   `## Canonical-Source Violations` — columns `Rule | Appears in`; render `✅ None detected` when clean.
    *   `## Size Compliance` — columns `File | Lines | Limit | Status`.
    *   `## Auto-Load Coverage` — columns `Orphan content | Location | Issue`; render `✅ Full coverage` when clean.
    *   `## Diagnosis Summary` — reports: platforms evaluated, gaps (count of `missing` + `present-weak`), violations (contamination + canonical-source + size), and weak-state Yes/No (usable signals < 3).

    The last lines in the diagnosis report body are the anchors:
    **Diagnosis complete.**
    **→ Diagnosis complete. Proceeding to Phase 3 — ASK immediately.**

**Transition (mandatory):** Output `---DIAGNOSIS-REPORT-END---` on one line, then `---ASK-REPORT-START---` on the **immediately next line** — no blank line, no text between them. Begin Phase 3 content on the line after `---ASK-REPORT-START---`.

### Phase 3 — ASK

**Purpose:** Fill the smallest possible gap in understanding by asking the user only what cannot be inferred from the scan.

**Inputs:** Phase 1 scan data and the Diagnosis Report.

**Procedure:**

1.  **Count usable scan signals.** Calculate the signal count from Phase 1 gathered data:
    *   **Context file:** +1 signal for every context file (such as `.cursorrules`, `AGENTS.md`, or `GEMINI.md`) with ≥ 5 lines.
    *   **Hooks:** +1 signal if any project or global hook is detected.
    *   **Memory:** +1 signal if memory count > 0.
    *   **Manifest:** +1 signal if a clear project type was identified from the manifest.

2.  **Branch based on signal count:**
    *   **If Signal count < 3 (Weak-state):** Ask exactly 3 fixed questions in a single message and wait for the user's response:
        *   Q1: In one or two sentences, what does this project do?
        *   Q2: What are the rules a new agent must never break in this project?
        *   Q3: What changes most frequently in the active work — issues/PRs in a tracker, tasks in a board, or something else?
    *   **If Signal count ≥ 3 (Normal-state):** Inspect the Diagnosis Report for gaps the scan cannot resolve. Ask 0–3 surgical questions. Triggers include:
        *   Multiple platforms detected but no `AGENTS.md`: *Should rules be unified in `AGENTS.md` (cross-tool) or kept per-platform?*
        *   Stage signals score = 1 (ambiguous): *Is this project organized as a sequential workflow (each folder = a stage) or is the numbering coincidental?*
        *   `gh` not authenticated, or no `gh` hook in a git root (determined from Phase 1 in-flight state data which shows "Skipped" or "no gh auth" — Phase 3 does NOT re-run `gh` commands): *Do you want dynamic in-flight queries (requires installing `gh`, running `gh auth login`, and being inside a git repository verified via `test -e .git`) or a static roadmap file (you maintain manually)?*
        If no gaps exist, skip asking entirely.

3.  **Hard Invariant:** Never re-ask what the scan already answered.

4.  **Hard Invariant:** Never use preference annotations (e.g. "(Recommended)", "(preferred)") in questions or options. All choices must be presented neutrally; the skill's prior is only expressed in Phase 4.

5.  **Emit the Ask Report.** Produce a block delimited by `---ASK-REPORT-START---` and `---ASK-REPORT-END---`.
    *   Start with `# Ask Report — {project name}`.
    *   Include metadata: `**Mode:** weak-state | normal-state` and `**Signal count:** N`.
    *   `## Questions Asked`: List all questions posed to the user (or "None" if skipped).
    *   `## Answers Received`: Record the user's responses (or "N/A" if skipped).
    *   End with `**Ask complete.**`.
    *   If 0 questions were asked, also append the anchor line: **→ Ask complete. Proceeding to Phase 4 — RECOMMEND immediately.**

**Transition:**
- If 0 questions were asked: output `---ASK-REPORT-END---` on one line, then `---RECOMMEND-REPORT-START---` on the **immediately next line** — no blank line, no text between them.
- If questions were asked: output `---ASK-REPORT-END---` and pause for user response. After the user responds, begin Phase 4 — RECOMMEND.

### Phase 4 — RECOMMEND

**Purpose:** Translate diagnosis into a prioritized, transparent list of proposed changes, expressed in terms of developer productivity (turns saved).

**Inputs:** Phase 1 scan data, Diagnosis Report, and Ask Report.

**Procedure:**

1.  **Generate recommendations.** For each gap or violation identified in the Diagnosis Report, map it to a Known Pattern (see the `## Known Patterns` section) or tag it as `ad-hoc`.

2.  **Estimate impact.** For each recommendation, calculate:
    *   **Turns saved:** The estimated number of discovery turns eliminated per session (e.g., 1–2 turns). Use the table in `## Known Patterns` for estimates.
    *   **Token cost:** The number of tokens added to the session-start context (e.g., +30 tokens).

3.  **Apply Threshold Filter (Hard Rule):**
    *   Any recommendation estimated to save **fewer than 3 turns** (i.e., patterns estimating ≤ 2 turns max) MUST be suppressed from the main recommendation list.
    *   Suppressed recommendations are NOT discarded; they are moved to a "Suppressed" list to be logged in `context-spec.md` during Phase 5.

4.  **Present recommendations.** Display the non-suppressed recommendations in a table, ordered by turns saved (descending). Use the following format for each row:
    *   **Turns saved:** N–M turns/session (Primary metric)
    *   **Token cost:** +X tokens/session (~Ys latency, negligible)

    **Example row:**
    | ID | Title | Turns saved | Token cost |
    |---|---|---|---|
    | R-1 | Add dynamic gh hook | 2–4 turns/session | +30 tokens/session (~0.02s latency, negligible) |

5.  **Seek approval.** Present the list to the user.
    *   If the user approves one or more: **proceed immediately to Phase 5 — IMPLEMENT**.
    *   If the user provides feedback or rejects: refine the recommendations and re-present.

**Output:** A list of approved recommendations and a list of suppressed recommendations.

### Phase 5 — IMPLEMENT

**Purpose:** Apply approved recommendations via non-destructive merges and produce a `context-spec.md` audit record.

**Procedure:**

1.  **Group changes by file.** For all approved recommendations, identify the target files.

2.  **Apply non-destructive merges.**
    *   For existing files (e.g., `CLAUDE.md`, `AGENTS.md`): Use `Edit` or `replace_with_git_merge_diff` to merge new sections. NEVER overwrite the entire file if it contains user content.
    *   For new files (e.g., hooks, memory files): Create the file with the required content.
    *   **Enforce Layer Separation:** Ensure Layer 3 (stable) and Layer 4 (volatile) content never mix in the same file.

3.  **Cross-host caveat header.** If writing to a file for a host other than the one currently running (e.g., writing `.cursorrules` from Claude Code), prepend the mandatory caveat:
    `# Added by context-optimizer (running in <current host>) — verify behavior in <target host> before relying on this`

4.  **Produce `context-spec.md`.** Create or update `context-spec.md` in the project root. It MUST contain:
    *   **## Applied Recommendations:** List of REC-IDs applied.
    *   **## Suppressed (< 3 turns threshold):** List of recommendations that were filtered out in Phase 4 because they saved < 3 turns.
    *   **## Project Snapshot:** Metadata about the scan signals and detected platforms.

5.  **Final Summary.** Provide a brief summary of what was changed and where to find the audit record.

## Known Patterns

| Pattern | Turns saved | Rationale |
|---|---|---|
| layer-0-startup-guide | 2–3 turns | Adds explicit "Read X/Run Y" instructions to auto-loaded files, eliminating agent guessing at start. |
| dynamic-in-flight | 2–4 turns | Enables agent to see real-time issues/PRs via hooks; replaces turns spent manually globbing for state. |
| static-in-flight-fallback | 1–2 turns | Provides a manually-maintained roadmap; helpful but prone to staleness (suppressed if < 3 turns). |
| layer-3-extraction | 1–2 turns | Moves stable rules to memory; improves attention but discovery turns saved are low (suppressed if < 3 turns). |
| canonical-source-dedup | 1 turn | Fixes conflicting rules; prevents agent confusion but rarely saves multiple turns (suppressed if < 3 turns). |
| section-routing | 1 turn | Pointers to specific file sections; improves precision, saves minor scrolling/reading turns (suppressed if < 3 turns). |
| cross-tool-agents-md | 2–3 turns | Unifies rules across platforms; eliminates per-platform discovery turns in multi-agent repos. |
| stage-contract | 3–5 turns | Implements per-stage CONTEXT.md files; highest impact for complex, sequential workflows. |

### score-health-computation

**Trigger:** Phase 2 Step 6 (score compute) and Phase 4 (projected score per recommendation)

**Per-dimension score mapping:**
- `missing` → 0
- `present-weak` → 4
- `present-good` with violations tied to this dimension → 8
- `present-good` with no violations → 10
- `duplicated` → max(0, 8 − (2 × unique violations implicating this platform)); violations = de-duplicated union of `duplicated` status entries and canonical-source violation entries; a platform is implicated if its context file appears in the `Appears in` column of the Canonical-Source Violations section

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

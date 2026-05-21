# Product Requirements Document — `context-optimizer`

**Document type:** Comprehensive PRD
**Owner:** Product (community-distributed open-source skill)
**Status:** Approved for implementation (v1.0); v2.0 roadmap defined
**Last updated:** 2026-05-19

> **Versioning convention used in this document:**
> Items tagged **[v1.0]** are the initial release scope. Items tagged **[v2.0]** are roadmap (lower priority, separated cleanly from v1.0 commitments). The implementing agent **must complete v1.0 first** before any v2.0 work.

---

## 1. Problem Statement

### The pain

On one hand, keeping an extensive conversation in one single session makes the agent to start **losing the quality of its responses**.

On the other hand, when a developer opens a new Claude Code (or Cursor, or Gemini CLI / Antigravity) session in an existing project, the AI agent starts with **near-zero awareness** of the project's identity, workflow, invariants, and current state. The agent must spend the first 1–3 turns discovering basics that the developer already knows:

- *What is this project?*
- *What's the workflow / what rules exist?*
- *What's actively being worked on right now?*
- *What should I read first?*

These discovery turns burn tokens, increase latency, dilute attention with low-signal context, and force the developer to repeat themselves across sessions.

### Who experiences it

Any developer who:
- Uses AI coding agents (Claude Code, Cursor, Gemini CLI, Antigravity) on projects with non-trivial conventions
- Opens multiple sessions on the same project over time
- Works on projects where in-flight state (open issues, current PR, active branch) matters for decision-making
- Maintains multiple projects with different conventions

### Quantified pain (from the source conversation, applied to `agentic-pdlc`)

| Discovery cost without project context | Tokens per session |
|---|---|
| Agent reads `package.json` to infer project type | ~50 |
| Agent reads `AGENTS.md` cold to learn workflow | ~400 |
| Agent reads `README.md` to learn purpose | ~200 |
| 1–2 exploratory exchanges before useful work | ~200–300 |
| **Total typical discovery overhead** | **~600–900 tokens** |

Plus **1–2 wasted turns** per session — the most expensive cost (latency + user attention).

### Current solutions don't solve this

| Solution | Why it fails for this problem |
|---|---|
| Hand-written `CLAUDE.md` | Becomes a policy file, not a startup guide. Falls out of date. Doesn't generalize. |
| Generic global session-start hooks | Don't know the specific project — output is the same regardless of project context |
| Hand-rolled per-project hooks | One-off — every project requires bespoke design, no shared patterns |
| Memory systems (e.g. `~/.claude/memory/`) | Infrastructure exists but rarely populated; manual to set up; per-project |
| Static "roadmap" files | Drift quickly — stale data is worse than missing data |
| Existing community tools (CAR, ICM, meta-harness, Continuous Claude, CCv3, claude-code-dotfiles) | None solve the specific problem of "given any existing project, automatically diagnose and improve session-start context." See `COMPETITIVE_ANALYSIS.md` |

### Why now

- AI coding agents are now used across multiple platforms (Claude Code, Cursor, Gemini CLI, Antigravity) by the same developer on the same project
- Cross-tool context formats are converging (`AGENTS.md`, `GEMINI.md`, `CLAUDE.md`) but no tool helps developers maintain context consistency across them
- Existing community solutions address adjacent problems (workflow orchestration, RAG retrieval, mid-session memory) but leave a gap at session start
- Token costs and context-window attention dilution remain real economic and quality concerns

---

## 2. Goals & Success Criteria

### 2.1 Business / Strategic goals (community open-source)

- **G-B1:** Become the default tool developers reach for when onboarding any project to AI agent collaboration.
- **G-B2:** Establish a sharable "proposer prior" — codified patterns for AI agent context optimization that improve over time via community contribution.
- **G-B3:** Bridge the multi-agent gap (Claude Code, Cursor, Gemini/Antigravity) so a single project can serve all three with consistent context.

### 2.2 User goals

A developer using `context-optimizer` on any project can:

- **G-U1:** Diagnose the project's session-context gaps in under 5 minutes of skill invocation
- **G-U2:** Apply token-efficient improvements without manually designing them
- **G-U3:** Get an auditable record (`context-spec.md`) of what was found, why each change was recommended, and what was explicitly out of scope
- **G-U4:** Trust that the skill will not make claims about platforms it can't directly verify (untested platforms get caveat lines, not silent assumptions)

### 2.3 Success criteria — measurable

All criteria must be objectively verifiable, not subjective ("feels better").

| ID | Criterion | Measurement | Target |
|---|---|---|---|
| SC-1 | Discovery overhead reduced on optimized projects | Compare tokens spent on project-discovery questions/file-reads in the first 2 turns of a new session, before vs. after optimization | ≥ 60% reduction (e.g., 600t → 240t or better) |
| SC-2 | First-useful-action latency | Number of turns until the agent performs the first action that advances the user's actual task (vs. exploring) | First action by turn 2 in ≥ 80% of new sessions on optimized projects |
| SC-3 | Spec auditability | Every recommendation made by the skill must appear in `context-spec.md` with rationale and "out-of-scope" companion | 100% of recommendations traceable |
| SC-4 | Multi-agent coverage when applicable | When a project contains config for multiple agents (e.g., both `CLAUDE.md` and `.cursorrules`), the skill optimizes both with appropriate caveats | All detected agent configs receive a recommendation OR an explicit "skipped because" note |
| SC-5 | Weak-scan resilience | When scan signals are insufficient (< 3 signals detected), the skill falls back to a structured 3-question dialog rather than producing low-quality recommendations | Fallback triggered correctly on a project with empty/missing context files |
| SC-6 | No silent ROI gatekeeping | The skill presents token cost + estimated savings for each recommendation; it never silently rejects a recommendation based on a hard-coded ROI threshold | Every recommendation in the output includes both numbers |
| SC-7 | Layer 3 / Layer 4 separation enforced by design | The skill's own outputs (CLAUDE.md additions, memory files) never mix stable identity (Layer 3) with in-flight artifacts (Layer 4) in the same file | Manual inspection on 3 reference projects shows clean separation |
| SC-8 | Untested-platform safety | Generated config for Cursor and Gemini/Antigravity includes an explicit caveat line; summary output flags these for user validation | 100% of cross-agent recommendations carry caveat |

### 2.4 Validation method

To validate success criteria post-implementation, the implementing agent must:

1. Run `context-optimizer` on at least 3 reference projects with different shapes:
   - **A.** A workflow-heavy project (e.g., `agentic-pdlc` — labels, stage gates, GitHub Actions automation)
   - **B.** A multi-agent project (contains both `CLAUDE.md` AND `.cursorrules` OR `GEMINI.md`)
   - **C.** A weak-state project (empty/minimal `CLAUDE.md`, no hooks, vague README)
2. For each project: open a new agent session before and after optimization; record tokens spent on discovery in the first 2 turns
3. Confirm: SC-5 fires on project C; SC-4 covers project B; SC-1 measured on project A

### 2.5 Leading vs. lagging metrics

| Type | Metric |
|---|---|
| **Leading** (predict success) | Number of recommendations applied per invocation; percentage of users who run the skill on a 2nd project; fraction of recommendations that come from "known patterns" vs. ad-hoc |
| **Lagging** (measure outcome) | Discovery-token reduction (SC-1); first-useful-action latency (SC-2); community-reported drift between context files (canonical-sources violations caught after the fact) |

---

## 3. Solution Overview

A host-portable skill (ships as a Claude Code skill in v1.0; Cursor port in v1.1; Gemini/Antigravity port in v1.2) that runs a 5-phase consulting flow on any project when invoked from inside the user's chosen host:

```
┌─────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│ 1. SCAN         │ →  │ 2. DIAGNOSE      │ →  │ 3. ASK           │
│ Read project    │    │ Evaluate 5       │    │ Targeted Qs only │
│ context files & │    │ dimensions +     │    │ when scan can't  │
│ infra signals   │    │ layer model      │    │ infer (max 3)    │
└─────────────────┘    └──────────────────┘    └────────┬─────────┘
                                                        │
                                                        ▼
                       ┌──────────────────┐    ┌──────────────────┐
                       │ 5. IMPLEMENT     │ ←  │ 4. RECOMMEND     │
                       │ Per-agent        │    │ Present cost +   │
                       │ adapters +       │    │ savings numbers  │
                       │ caveat lines     │    │ (no threshold)   │
                       └──────────────────┘    └──────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │ context-spec.md  │
                       │ Audit record:    │
                       │ found, why, oos  │
                       └──────────────────┘
```

Full architectural detail is in `ARCHITECTURE.md`. This PRD captures the product intent; the architecture document captures the design contract.

### Key behavioral commitments

- **Scan-first:** The skill never asks a question that could be inferred from the project's files. It earns its right to ask by exhausting passive scanning first.
- **Host-native, project-scoped:** The skill ships in formats native to each supported AI agent host (Claude Code, Cursor, Gemini CLI / Antigravity). A user picks **one host per project** and invokes the skill from within that host to optimize that project. Cross-host invocation is the typical use case (different projects, different hosts) — not parallel agents on the same project.
- **Multi-agent fallback:** When a single project happens to contain context files for multiple agents (e.g., both `CLAUDE.md` AND `.cursorrules`), the skill detects all of them and optimizes each, with caveat lines for hosts it isn't currently running inside.
- **Token-efficient by golden rule:** Every recommendation presents its token cost (added per session) and estimated savings (avoided per session). The user — not the skill — decides whether the trade is worth it.
- **Auditable:** The skill produces `context-spec.md` documenting what was found, why each recommendation was made, and what was deliberately out of scope.
- **Honest about uncertainty:** For host platforms the skill cannot directly test in its current invocation (e.g., skill running in Claude Code generating Cursor config), generated files include caveat lines and summary output flags them for user validation.

---

## 4. Users & Use Cases

### 4.1 Primary user segment

**Solo developers and small teams** using AI coding agents (Claude Code, Cursor, Gemini CLI, Antigravity) on projects where:
- Multiple sessions occur over time
- Different projects may use different host agents (e.g., Project A in Claude Code, Project B in Cursor)
- The project has non-trivial conventions (workflow rules, invariants, in-flight state)
- Token cost and first-turn quality matter

The typical user has **multiple projects, each tied to one preferred host agent**. The skill must be invokable from within whatever host is being used for that project.

### 4.2 Secondary user segment

**Developer-experience engineers** at companies adopting AI coding tools who need to standardize how project context is delivered to AI agents across their organization.

### 4.3 Use cases

| ID | Use case | Trigger | Outcome |
|---|---|---|---|
| UC-1 | Onboard a project using Claude Code | Developer runs the skill inside Claude Code on a project they primarily develop with Claude Code | `CLAUDE.md` becomes a startup guide; hooks inject in-flight state; memory files capture stable identity |
| UC-1b | Onboard a project using Cursor | Developer runs the skill inside Cursor on a project they primarily develop with Cursor | `.cursor/rules/*.mdc` becomes a startup guide; in-flight state surfaced via Cursor-native mechanism |
| UC-1c | Onboard a project using Gemini CLI / Antigravity | Developer runs the skill inside Gemini/Antigravity on a project they primarily develop there | `GEMINI.md` becomes a startup guide; `.gemini/config.yaml` and (Antigravity-specific) `.agents/skills/` updated |
| UC-2 | Audit existing project for context staleness | Developer suspects their context files are stale or contradictory | Skill detects canonical-source violations and Layer 3/4 contamination; produces fix recommendations |
| UC-3 | Single project that happens to use multiple agents | Project has both `CLAUDE.md` AND `.cursorrules` because two contributors use different hosts | Skill (running in whichever host the current developer is using) detects both, optimizes each, applies caveat lines for the non-host platform |
| UC-4 | Diagnose a "weak" project | Project has minimal `CLAUDE.md` / `GEMINI.md`, no hooks, terse README | Skill falls back to 3-question dialog; produces a starter context layer based on user answers |
| UC-5 | Re-optimize after major project change | Project workflow changed (new GitHub Actions, new stage labels, new agent platform) | Skill re-scans, surfaces what's no longer canonical, recommends updates |
| UC-6 | Same skill, different projects, different hosts | User has one project in Claude Code, another in Cursor; wants to apply the same optimization patterns to both | User installs the host-native version of the skill in each environment; same conceptual procedure, host-appropriate outputs |

### 4.4 Anti-personas (not targets)

- **ML/AI researchers running benchmark-based harness search:** They should use `meta-harness`. See `COMPETITIVE_ANALYSIS.md`.
- **Teams building heavy multi-stage workflow systems:** They should adopt `ICM`. The skill may recommend ICM patterns where applicable but does not replace ICM.
- **Users needing RAG-style retrieval for large codebases:** They should use `CCv3` or similar. The skill addresses session-start, not query-time retrieval.

---

## 5. Functional Requirements

Format: `REQ-NNN: System shall ... [Priority]`. Priority: **P0** (must for launch), **P1** (should), **P2** (nice-to-have).

### 5.1 Scan phase requirements

- **REQ-001 [P0]:** The skill shall read the following files when present in the project root or its `.claude/`, `.cursor/`, `.gemini/`, `.agent/`, `.agents/` subdirectories, without prompting the user: `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.cursor/rules/*.mdc`, `AGENTS.md`, `.gemini/config.yaml`, `.gemini/styleguide.md`, `.claude/settings.json`, `.claude/settings.local.json`, `.agent/workflows/*.md`, `.agents/skills/SKILL.md`.
- **REQ-002 [P0]:** The skill shall read user-level hooks at `~/.claude/settings.json` and any `~/.claude/hooks/*.sh` referenced in it (read-only, never modify without consent).
- **REQ-003 [P0]:** The skill shall read `~/.claude/projects/<project>/memory/MEMORY.md` and any files indexed therein, if present.
- **REQ-004 [P0]:** The skill shall read project manifest files when present (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`) and the first 30 lines of `README.md` as a project-summary fallback.
- **REQ-005 [P0]:** The skill shall query git metadata: `git rev-parse --abbrev-ref HEAD`, `git log --oneline -5`, `git status --short`.
- **REQ-006 [P1]:** When `gh` CLI is authenticated, the skill may run lightweight read-only queries (`gh issue list`, `gh pr list`) to assess in-flight state; this is informational for the diagnosis phase and never blocks scan completion.

### 5.2 Diagnose phase requirements

- **REQ-010 [P0]:** The skill shall evaluate each detected AI agent platform against 5 dimensions: **identity**, **workflow**, **in-flight**, **startup**, **duplication**. Each dimension produces one of: `present-good`, `present-weak`, `missing`, `duplicated`.
- **REQ-011 [P0]:** The skill shall apply the Layer 3 / Layer 4 contamination check: when a single context file contains both stable identity facts (e.g., project purpose, invariants) AND volatile in-flight data (e.g., current PR number, active issue), this is flagged as contamination requiring separation.
- **REQ-012 [P0]:** The skill shall apply the canonical-source check: when the same rule appears in two or more context files (e.g., a workflow rule duplicated between `CLAUDE.md` and `AGENTS.md`), this is flagged as a canonical-source violation requiring deduplication with one-way references.
- **REQ-013 [P0]:** The skill shall detect workflow / stage signals using a multi-signal heuristic: requires **2+ of**: numbered folders (`01-`, `02-`); `output/` or `artifacts/` subdirectories inside workflow folders; `CONTEXT.md` files inside subdirectories; GitHub Actions with sequential job dependencies; labels with prefix patterns (`stage:`, `phase:`); README mentioning "stages" / "pipeline" / "workflow" / "steps". A single numbered-folder signal alone is insufficient.
- **REQ-014 [P1]:** When stage signals are detected (REQ-013), the skill shall recommend creating ICM-style stage contracts (`CONTEXT.md` with Inputs/Process/Outputs tables) in each workflow folder.

### 5.3 Ask phase requirements

- **REQ-020 [P0]:** The skill shall ask at most 3 clarifying questions after diagnose, only for information the scan could not infer.
- **REQ-021 [P0]:** When the scan yields fewer than 3 useful signals (no `CLAUDE.md` / no hooks / no substantive README), the skill shall enter a structured "weak-state" fallback dialog with exactly 3 questions: *(a)* What does this project do? *(b)* What are the rules an agent must never break? *(c)* What changes most frequently in the work-in-progress?
- **REQ-022 [P1]:** When detected agents are configured but the skill cannot determine which one is the user's primary platform, it shall ask once: which platform should be prioritized when there is conflict?

### 5.4 Recommend phase requirements

- **REQ-030 [P0]:** Each recommendation shall include four fields: *(a)* what changes, *(b)* token cost added per session, *(c)* estimated tokens saved per session, *(d)* maintenance burden (`zero` / `low` / `manual`).
- **REQ-031 [P0]:** The skill shall **not** apply a hard-coded ROI threshold to filter recommendations. It presents the numbers; the user decides.
- **REQ-032 [P0]:** Recommendations shall be ordered by estimated savings, descending.
- **REQ-033 [P0]:** Every recommendation shall map to one of the documented "known patterns" in the skill's proposer prior OR be flagged as `ad-hoc` (novel pattern, not yet codified).
- **REQ-034 [P0]:** The skill shall require user approval before applying any recommendation (no silent writes).
- **REQ-035 [P1]:** When the user declines a recommendation, the skill shall capture this in `context-spec.md` as an "explicitly out-of-scope decision" with the user's reason if provided.

### 5.5 Implement phase requirements

- **REQ-040 [P0] [v1.0]:** When the skill is invoked inside Claude Code, it shall write or update: `CLAUDE.md`, `.claude/settings.json` hook entries, memory files in `~/.claude/projects/<project>/memory/`. It must preserve existing content not covered by the recommendation.
- **REQ-041 [P0] [v1.0]:** When the project contains Cursor configuration files (`.cursorrules` or `.cursor/rules/`) AND the skill is **not currently running inside Cursor**, the skill shall write to `.cursor/rules/*.mdc` (preferred) or `.cursorrules` (legacy fallback). Every such cross-host generated file shall include a caveat line: `# Added by context-optimizer (running in <current host>) — verify behavior in Cursor before relying on this`.
- **REQ-042 [P0] [v1.0]:** When the project contains Gemini/Antigravity configuration AND the skill is **not currently running inside Gemini CLI / Antigravity**, the skill shall write to `GEMINI.md` and optionally `.gemini/config.yaml`, with the analogous caveat line.
- **REQ-043 [P0] [v1.0]:** When the skill recommends a SessionStart hook with dynamic GitHub queries, the generated hook script shall include an opt-in variable at the top: `ENABLE_GH_QUERIES=true  # set false for short-session projects (<10min typical)`.
- **REQ-044 [P0] [v1.0]:** Layer 3 / Layer 4 separation shall be enforced by the skill's own write logic: stable identity (project purpose, invariants) goes to memory files; startup behavior (what to read, what to run) goes to the host-native Layer-0 file (`CLAUDE.md` / `GEMINI.md` / `.cursor/rules/main.mdc`); in-flight state is generated dynamically via hooks. These are non-overlapping by design.
- **REQ-045 [P0] [v1.0]:** When the skill detects an existing context-file pattern (e.g., a project already has a hand-written `CLAUDE.md` with a startup section), it shall add to / refine the existing structure rather than overwrite it.
- **REQ-046 [P0] [v1.0]:** When the skill IS running inside the host whose files it is writing (e.g., running in Cursor and writing `.cursor/rules/`), the caveat line is **not** required — the skill has direct knowledge of that host's behavior.

### 5.6 Cross-Host Distribution Requirements

- **REQ-047 [P0] [v1.0]:** The skill shall ship as a Claude Code-native skill (`.md` file with frontmatter, installable to `~/.claude/skills/`). This is the v1.0 reference implementation.
- **REQ-048 [P1] [v1.x]:** The skill shall be portable to Cursor (e.g., `.cursor/rules/context-optimizer.mdc` referenceable in Cursor chat) and Gemini/Antigravity (e.g., `.agents/skills/context-optimizer/SKILL.md`). v1.0 documents the porting path; actual ports may ship as v1.1 (Cursor) and v1.2 (Gemini/Antigravity).
- **REQ-049 [P0] [v1.0]:** Regardless of host, the skill's procedure (5 phases, layer model, Known Patterns) shall remain identical. Only the invocation mechanism and host-native write paths differ.

### 5.7 Audit-record requirements

- **REQ-050 [P0] [v1.0]:** The skill shall produce a `context-spec.md` file in the project root (or a user-specified location) documenting:
  - **Project snapshot:** detected agents, project type, scan signals, host the skill ran inside
  - **Diagnosis summary:** per-dimension evaluation across the 5 dimensions
  - **Recommendations applied:** each with cost/savings/maintenance
  - **Recommendations declined:** with reason
  - **Out of scope:** what the skill deliberately did not touch (with reasoning)
  - **Known patterns referenced:** which versioned patterns were applied
- **REQ-051 [P1] [v1.0]:** The `context-spec.md` shall be git-committed by default, so future invocations can detect prior optimization decisions and respect them.

### 5.8 Proposer-prior requirements

- **REQ-060 [P0] [v1.0]:** The skill file shall contain a versioned section titled `Known Patterns` that lists the named patterns the skill applies (Layer architecture, Section routing, Canonical sources, Dynamic in-flight, Caveat-on-untested, etc.).
- **REQ-061 [P1] [v1.0]:** Each known pattern shall include: a name, a one-line description, a triggering condition (when the skill applies it), and a brief rationale.

---

## 6. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-1 | Performance | Full skill invocation (scan + diagnose + ask + recommend) shall complete in ≤ 90 seconds on a typical project (≤ 200 tracked files in scanned context paths) |
| NFR-2 | Performance | Generated SessionStart hooks shall add ≤ 3 seconds to session startup time when `ENABLE_GH_QUERIES=true` |
| NFR-3 | Reliability | The skill shall fail safely: any scan error in one file must not block scanning of others; partial scan is acceptable, silent failure is not |
| NFR-4 | Reliability | All file writes shall be idempotent: re-invoking the skill must not produce diverging output on an unchanged project |
| NFR-5 | Compatibility | The skill shall run inside any current Claude Code installation without requiring additional plugins, MCP servers, or external services |
| NFR-6 | Compatibility | The skill shall not require `gh` CLI authentication to function; `gh`-dependent features degrade gracefully when unavailable |
| NFR-7 | Portability | All generated config (`CLAUDE.md`, `.cursor/rules/`, `GEMINI.md`, hooks) shall be plain text files committable to any standard git repository |
| NFR-8 | Maintainability | All files referenced by the skill (`CLAUDE.md`, generated memory files, `context-spec.md`) shall stay under documented size limits: `CLAUDE.md` ≤ 150 lines after optimization; memory files ≤ 80 lines each; `context-spec.md` no fixed limit but structured for grep-ability |
| NFR-9 | Observability | All recommendations and their rationale shall be plain text in `context-spec.md` — no hidden state, no opaque database |
| NFR-10 | Safety | The skill shall never `rm` or delete user content. Any "replace" operation shall be a non-destructive merge or shall require explicit user confirmation |

---

## 7. Out of Scope

Explicit boundaries to prevent scope creep. Each item below maps to either an alternative tool that *does* solve it, or a deliberate non-goal.

| Out of scope | Why | Alternative |
|---|---|---|
| Multi-stage workflow orchestration (numbered folders as stages, stage contracts with Inputs/Process/Outputs, output handoffs) | Different problem (task-time orchestration, not session-start) | ICM — `Interpreted-Context-Methdology`. The skill may **recommend** ICM adoption when stage signals detected, but does not implement workflow orchestration itself. |
| RAG / semantic retrieval over large codebases | Different problem (query-time retrieval, not session start) | CCv3 (`OCWC22/claude-code-context-optimizer`); other RAG tools |
| Benchmark-based automated search over harness configurations | Different problem (optimization at scale, requires evaluation loop and budget) | Stanford `meta-harness` |
| Long-running multi-session conversation continuity (preserving in-conversation decisions across compactions) | Different problem (mid-/post-session, not pre-session) | `Continuous Claude` (`parcadei/Continuous-Claude-v3`) |
| Global Claude Code config installation (curl-installable defaults) | Different problem (global defaults, not project-aware) | `claude-code-dotfiles` (`IFAKA/claude-code-dotfiles`) |
| Writing actual project documentation (READMEs, architecture docs, API docs) | Out of charter; project documentation serves humans, not session-start AI context | Standard documentation tools |
| Modifying business logic or source code in the project | Strict boundary: skill writes context files only | n/a |
| Production-grade context analytics dashboards | Not a feature; out-of-scope for v1 community release | Future consideration; community can build on `context-spec.md` |
| Cloud-hosted / SaaS version of the skill | The skill is local-first by design (operates on local filesystem) | n/a |
| Support for AI agents beyond Claude Code, Cursor, Gemini CLI, and Antigravity in v1 | Scope limit for first release; expandable later | n/a (community contribution welcome) |
| **Organic memory growth during real work** (agent calls a `save_project_fact` tool mid-session to add stable facts discovered while working) | **Scoped to v2.0** (see §12 Roadmap). v1.0 is setup-only: skill populates initial memory; no ongoing growth mechanism. | OpenClaw-inspired pattern (https://gist.github.com/dabit3/bc60d3bea0b02927995cd9bf53c3db32) absorbed in v2.0 |

---

## 8. Decisions & Rationale

The following non-obvious decisions were made during design. Each is preserved here so future maintainers know why.

### D-1: Scan-first, not ask-first

**Decision:** The skill scans the project before asking any questions. Questions only fire if scan can't infer.

**Rationale:** Asking the user something inferrable from files wastes their time and erodes trust. The user's input is the most expensive resource in the loop; reserve it for things only the user knows.

### D-2: No hard-coded ROI threshold

**Decision:** The skill presents cost and savings numbers per recommendation but never silently filters out recommendations based on a fixed ratio.

**Rationale:** ROI threshold is arbitrary (no empirical basis for 5× vs. 3× vs. 10×). The right threshold depends on session frequency, project complexity, and user preference — variables the skill cannot reliably estimate. Surfacing the data lets the user apply their own threshold.

### D-3: Dynamic over static for in-flight data

**Decision:** When recommending how to surface "what's in flight" (active issues, current PR), the skill prefers a dynamic `gh issue list` hook over a static `current-roadmap.md` file.

**Rationale:** Static files become stale; stale data is *worse* than missing data because new sessions waste tokens discovering the file is wrong. Dynamic queries trade ~2 seconds of latency for correctness — a better trade for most projects.

### D-4: Layer 3 / Layer 4 separation enforced at write-time, not check-time

**Decision:** The skill prevents identity-vs-state mixing by always writing them to different files (stable identity → memory files; volatile state → dynamic hooks). It does not run a runtime checker.

**Rationale:** A runtime checker adds complexity without preventing the underlying issue. Designing the write logic so contamination is impossible by construction is simpler and more robust.

### D-5: Multi-agent support without multi-agent testing

**Decision:** The skill generates recommendations for Cursor and Gemini/Antigravity but always with a caveat line in the generated file and a flag in the summary output.

**Rationale:** Honest uncertainty handling beats false confidence. The skill runs inside Claude Code; it cannot directly verify Cursor or Gemini behavior. Caveat lines transfer the validation responsibility to the user, who *can* verify by opening the other platform.

### D-6: Stage contracts only when signaled

**Decision:** ICM-style stage contracts (Inputs/Process/Outputs tables in `CONTEXT.md`) are recommended only when 2+ workflow signals are detected. A single numbered-folder signal alone is insufficient.

**Rationale:** Numbered folders are a weak signal (`01-setup/` `02-docs/` could be documentation structure, not stages). False positives lead to inappropriate recommendations. Multi-signal requirement reduces false positives at modest cost in false negatives.

### D-7: Output an audit record (`context-spec.md`)

**Decision:** Every invocation produces a permanent record of what was found, what was changed, what was declined, what was out of scope.

**Rationale:** Borrowed from `meta-harness` `domain_spec.md` pattern. Provides auditability, supports incremental re-optimization (next invocation can read prior record), and surfaces the skill's reasoning to community contributors who might propose improvements to the proposer prior.

### D-8: Versioned `Known Patterns` section in the skill

**Decision:** The skill embeds an explicit list of named patterns it applies (Layer architecture, Section routing, Canonical sources, etc.) versioned in the skill file itself.

**Rationale:** Borrowed from `meta-harness` proposer-prior concept. Makes the skill's reasoning legible to users and contributors; supports evolution over time; allows users to anchor recommendations to known patterns rather than ad-hoc judgments.

---

## 9. Launch Plan

### 9.1 Distribution

- **Repository:** New GitHub repository at `<user>/context-optimizer`. License: MIT (matches comparable community tools).
- **Installation:** Two paths offered:
  1. **Skill copy:** Single `.md` skill file copied to `~/.claude/skills/`. Simplest path; preferred for v1.
  2. **Installer script:** Optional `install.sh` (curl-installable) that copies the skill file plus a starter `Known Patterns` doc. Modeled after `claude-code-dotfiles` distribution.
- **Discovery:** README.md in repo describes use case, links to a short demo (asciinema or animated gif), and points to comparable tools (with their distinct purposes) for users who landed on the wrong tool.

### 9.2 Rollout

| Phase | Audience | Validation |
|---|---|---|
| **Phase A — Internal validation** | Author's own projects (`agentic-pdlc`, 2+ others) | All 8 success criteria pass on at least 1 project each |
| **Phase B — Limited share** | 5–10 trusted developers | Feedback collected; "Known Patterns" updated based on patterns surfaced |
| **Phase C — Public release** | Open community on GitHub + a short blog post / X thread positioning vs. alternatives | Inbound issues triaged; community contributions accepted on `Known Patterns` |

### 9.3 Go/No-Go criteria for public release

- All P0 functional requirements complete
- All 8 success criteria verified on at least one reference project
- `context-spec.md` produces clean output on all 3 reference project types (A/B/C in Section 2.4)
- Self-protection mechanisms verified: weak-scan fallback fires; ROI numbers present in every recommendation; caveat lines present in cross-agent files
- COMPETITIVE_ANALYSIS.md publicly accessible so users arriving from search can self-redirect if their problem is actually adjacent

---

## 10. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Skill recommends Cursor/Gemini changes that don't behave as expected on those platforms | Medium | Medium (user trust loss) | Caveat lines + summary flag (REQ-041, REQ-042); document validation steps in IMPLEMENTATION_GUIDE.md |
| Users misuse the skill for problems it doesn't address (workflow orchestration, RAG) | Medium | Low | Explicit `Out of Scope` table (Section 7) + redirect-to-alternative in README.md |
| Known Patterns list becomes stale as platforms evolve | High over time | Medium | Versioned in skill file; community contribution path documented; `context-spec.md` flags `ad-hoc` recommendations not yet codified |
| Skill produces high token cost on its own (irony) | Low | Medium | NFR-1 caps invocation time; scan reads bounded set of files; no recursive descent into `node_modules`/`venv`/`.git` |
| Generated `CLAUDE.md` conflicts with user's existing hand-written content | Medium | Medium | REQ-045: refine rather than overwrite; require explicit user approval for non-trivial merges |
| Community confusion with similarly-named projects (e.g., `claude-code-context-optimizer` / CCv3) | High at release | Low | COMPETITIVE_ANALYSIS.md positions clearly; README explicitly notes "not the RAG tool" |

---

## 11. Open Questions (for the implementing agent)

These were left deliberately open in the spec for the implementing agent to resolve during build:

| ID | Question | Suggested default |
|---|---|---|
| Q-1 | Should the skill prompt for user-level git config (name, email) when recommending git-committed `context-spec.md`? | No — assume git is configured; if not, recommend `git config` manually before re-invoking |
| Q-2 | Should the skill version-track its own outputs (e.g., `context-spec.md` includes the version of context-optimizer that produced it)? | Yes — include `generated-by: context-optimizer@vX.Y.Z` in `context-spec.md` frontmatter |
| Q-3 | How should the skill handle nested projects (monorepo with sub-projects each having their own `CLAUDE.md`)? | v1: operate on the directory the skill is invoked from; document monorepo handling as future work |
| Q-4 | When the user has explicit `caveman` mode or similar style preferences, how should generated context files respect them? | v1: respect Markdown structure; defer style transformation to user post-generation |

---

## 12. Release Roadmap

Explicit boundary between **v1.0** (initial scope, this PRD) and **v2.0** (lower-priority roadmap, designed but deliberately deferred). Everything in §1–§11 above is **v1.0** unless tagged otherwise.

### 12.1 v1.0 — Setup-driven session-start optimization (this PRD's scope)

Already specified in full above. Summary:
- Scan-first 5-phase procedure (scan → diagnose → ask → recommend → implement)
- Host-native distribution starting with Claude Code; Cursor and Gemini/Antigravity ports as v1.1 / v1.2 (REQ-048)
- Per-project memory populated **at invocation time**, based on scan + diagnose
- Cross-host caveat lines when generating config for a host the skill isn't currently running inside
- `context-spec.md` audit record on every run

**What v1.0 explicitly does NOT cover:** memory does not grow after the initial invocation. The user must re-invoke the skill manually to capture changes in project state.

### 12.2 v2.0 — Organic memory growth during real work (deferred)

**Problem v2.0 addresses:** v1.0 sets up project memory at invocation time. But during normal work, the agent encounters facts about the project that would be worth remembering ("this codebase uses 4-space indent", "tests live in `/spec` not `/tests`", "the team prefers `feat:` not `feature/` for branch names"). v1.0 has no mechanism to capture these without re-running the full skill — leaving useful nuances unrecorded.

**Approach v2.0 absorbs:** the OpenClaw memory pattern (https://gist.github.com/dabit3/bc60d3bea0b02927995cd9bf53c3db32) — give the agent a tool to write to memory mid-session, with rules that constrain what's worth saving.

**Proposed v2.0 design** (subject to refinement when v2.0 work begins):

- **TOOL-V2-1:** A `save_project_fact` tool exposed to the agent in the project's host environment. Tool signature: `save_project_fact(category: str, fact: str, evidence: str)`.
- **TOOL-V2-2:** A companion `recall_project_facts` tool that lets the agent retrieve previously-saved facts during work.
- **REQ-V2-1:** The tool must enforce a stable-only filter — only Layer 3 facts (project identity, conventions, invariants) may be saved, never Layer 4 (current PR, active issue). Tool description includes explicit examples of what's allowed and what's rejected.
- **REQ-V2-2:** Every saved fact must include evidence (where the agent learned this — file path, line, or user statement). Without evidence, the call fails.
- **REQ-V2-3:** Saved facts merge into the existing memory directory created by v1.0. The audit record (`context-spec.md`) records growth events so the user can see what was added.
- **REQ-V2-4:** v2.0 tools ship as host-native: a Claude Code tool for the Claude port, equivalent for Cursor and Gemini/Antigravity. The procedure for deciding what to save is identical across hosts.

**v2.0 success criteria (initial draft, to be refined):**

| ID | Criterion | Target |
|---|---|---|
| SC-V2-1 | Saved-fact relevance | ≥ 80% of saved facts retain usefulness 30 days later (audited via `context-spec.md` history) |
| SC-V2-2 | No Layer 4 contamination | 0 saved facts containing volatile/run-specific content |
| SC-V2-3 | Audit traceability | 100% of saved facts have associated evidence in `context-spec.md` |

**v2.0 explicit dependencies on v1.0:**
- v2.0 cannot ship until v1.0 is shipped and at least one host-native port (v1.1 or v1.2) is in use
- v2.0 reuses the v1.0 layer model and Known Patterns library
- v2.0 reuses the v1.0 `context-spec.md` format (with additional `growth-events` section)

**v2.0 is explicitly NOT a substitute for v1.0.** Cold-start (a project that has never been optimized) is still solved by v1.0's scan-first setup. v2.0 only extends v1.0's coverage to the "ongoing work" phase.

### 12.3 Sequencing

```
v1.0  (Claude Code skill, setup phase)         ← THIS PRD
  │
  ├─→ v1.1  (Cursor port, setup phase)
  │
  ├─→ v1.2  (Gemini/Antigravity port, setup phase)
  │
  └─→ v2.0  (Organic memory growth, all hosts)  ← ROADMAP, lower priority
```

**Do not begin v2.0 work until v1.0 is shipped, validated on the 3 reference projects, and at least one community user has run it end-to-end successfully.**

---

## 13. Glossary (terms used throughout)

See `README.md#glossary` for shared definitions. PRD-specific terms:

| Term | Meaning |
|---|---|
| **Recommendation** | A discrete proposed change to the project's context infrastructure, with cost/savings/maintenance attached |
| **Diagnosis** | The skill's structured evaluation of the project's session-start context across 5 dimensions |
| **Audit record** | The `context-spec.md` file the skill produces to document its reasoning |
| **Caveat line** | A self-aware comment in generated files indicating the skill cannot verify behavior on that platform |
| **Known pattern** | A versioned, named recipe in the skill's proposer prior |
| **Ad-hoc recommendation** | A recommendation not yet codified as a Known Pattern; surfaced for potential future codification |
| **Host** | The AI agent environment from which the skill is invoked (Claude Code, Cursor, Gemini CLI / Antigravity). One project = one primary host in the typical case. |
| **Cross-host generation** | Writing config for an agent platform the skill is not currently running inside; triggers the caveat-line requirement |
| **Organic memory growth (v2.0)** | The skill-extending pattern in which the host agent calls a `save_project_fact` tool during normal work to add stable facts to memory; explicitly v2.0 scope, not v1.0 |

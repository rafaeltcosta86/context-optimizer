# Architecture — `context-optimizer`

**Document type:** System & Skill Architecture
**Audience:** Implementing agent + future maintainers
**Companion documents:** `PRD.md` (what), `IMPLEMENTATION_GUIDE.md` (how to build), `COMPETITIVE_ANALYSIS.md` (what it's not)

---

## 1. System Overview

`context-optimizer` is a **host-portable skill** — a Markdown procedure that ships in formats native to each supported AI agent host (Claude Code, Cursor, Gemini CLI / Antigravity). The user invokes it from within whichever host they are using for a given project.

The skill is a **prompt + a procedure**, not an executable. All work is performed by the AI agent that loads it, using standard tools available in that host (Read, Write, Edit, Glob, Grep, Bash for git/gh).

There is **no backend**, **no SaaS**, **no daemon**, and **no external infrastructure**. The skill operates exclusively on local filesystem state and optionally on local `gh` CLI calls.

**v1.0 reference implementation:** Claude Code skill. v1.1 (Cursor) and v1.2 (Gemini/Antigravity) ports follow the same procedure with host-specific invocation and write paths. See `PRD.md` §12 Release Roadmap.

### Context diagram

```
                  ┌─────────────────────────────────────────────┐
                  │             USER (developer)                │
                  └──────────────────┬──────────────────────────┘
                                     │ invokes via host-native mechanism
                                     │ (e.g., /skill in Claude Code;
                                     │  reference in chat for Cursor;
                                     │  agent skill in Antigravity)
                                     ▼
   ┌──────────────────────────────────────────────────────────────┐
   │   HOST SESSION  (one of: Claude Code | Cursor | Gemini/AG)   │
   │                                                               │
   │   ┌────────────────────────────────────────────────────────┐  │
   │   │     SKILL: context-optimizer (loaded into ctx)         │  │
   │   │  • Procedure: scan → diagnose → ask → recommend → impl │  │
   │   │    (IDENTICAL across hosts)                            │  │
   │   │  • Known Patterns (versioned prior)                    │  │
   │   │  • Per-host adapter recipes                            │  │
   │   └─────────────────────┬──────────────────────────────────┘  │
   │                         │ uses                                 │
   │                         ▼                                      │
   │   ┌────────────────────────────────────────────────────────┐  │
   │   │   STANDARD TOOLS: Read, Write, Edit, Glob, Grep, Bash  │  │
   │   │   (host-equivalent — see §5)                           │  │
   │   └─────────────────────┬──────────────────────────────────┘  │
   └─────────────────────────┼─────────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                ▼                          ▼
   ┌──────────────────────┐    ┌─────────────────────────┐
   │  PROJECT FILESYSTEM  │    │   LOCAL git / gh CLI    │
   │                      │    │                         │
   │  • CLAUDE.md         │    │  • git log / status     │
   │  • GEMINI.md         │    │  • gh issue/pr list     │
   │  • .cursor/rules/    │    │    (opt-in, gracefully  │
   │  • .claude/settings  │    │     degrades)           │
   │  • AGENTS.md         │    └─────────────────────────┘
   │  • memory files      │
   │  • package.json …    │
   └──────────────────────┘
```

**Typical user pattern:** one project = one host. User running Claude Code on Project A invokes the Claude Code version of the skill on Project A. User running Cursor on Project B invokes the Cursor version of the skill on Project B. Same procedure, different host, different write targets.

**Edge case — single project, multiple agents:** when a project has context files for multiple hosts (e.g., both `CLAUDE.md` and `.cursorrules` because two collaborators use different hosts), the skill optimizes all detected configs but applies caveat lines to anything outside its current host.

### Architectural principles

1. **Skill as procedure, not executable.** All logic is expressed in the skill's Markdown body. The host AI agent executes the procedure using standard tools. No compilation, no runtime, no binary.
2. **Host-portable.** Same procedure ships natively in each supported host's skill / rules / agent format. The procedure is host-agnostic; only invocation and write paths differ.
3. **Local-first.** No external services required. Everything runs against local files and optionally local `gh` CLI.
4. **Read-then-write with consent gate.** Phases 1–4 are read-only. Only Phase 5 writes, and only with explicit user approval.
5. **Idempotent writes.** Re-running the skill on an unchanged project produces no diff.
6. **Honest uncertainty.** When generating config for a host the skill isn't currently running inside, generated artifacts say so in-line (caveat lines).
7. **Plain text everything.** No databases, no opaque state. All outputs are committable text files.

---

## 2. The Five Phases — Detailed Design

### Phase 1 — SCAN

**Purpose:** Build a complete picture of the project's current session-context infrastructure without asking the user anything.

**Inputs:** the project root directory (assumed to be the working directory at invocation).

**Procedure:**

1. **Detect agent configurations.** Glob for the following files and directories. Record what's present, what's missing, and the size of each present file.

   | Platform | Files to detect |
   |---|---|
   | Claude Code | `CLAUDE.md` (project root), `.claude/settings.json`, `.claude/settings.local.json`, `.claude/hooks/*`, `~/.claude/projects/<proj>/memory/MEMORY.md` |
   | Cross-tool | `AGENTS.md` (any version) |
   | Cursor | `.cursorrules` (legacy), `.cursor/rules/*.mdc` |
   | Gemini CLI / Antigravity | `GEMINI.md`, `.gemini/config.yaml`, `.gemini/styleguide.md`, `.agent/workflows/*.md`, `.agents/skills/SKILL.md` |
   | Global user-level | `~/.claude/settings.json` (read-only), `~/.claude/hooks/session-start.sh` (read-only) |

2. **Read all detected agent context files in full.** No truncation. These files are typically small (< 200 lines); reading them fully is necessary for diagnostic accuracy.

3. **Read project manifest.** First file found among: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `mix.exs`. Parse for project name, type, dependencies.

4. **Read README.md (first 30 lines).** Extract project summary if no agent context file already provides it.

5. **Query git metadata** via Bash:
   - `git rev-parse --abbrev-ref HEAD` (current branch)
   - `git log --oneline -5` (recent activity pattern)
   - `git status --short` (uncommitted changes hint)

6. **Optionally query `gh` for in-flight state.** Only if `gh auth status` reports authenticated:
   - `gh issue list --state open --label "stage:development" --json number,title --limit 5`
   - `gh pr list --state open --json number,title,headRefName --limit 5`

   Failure of any `gh` call is non-fatal — phase continues without these signals.

7. **Detect workflow / stage signals.** Apply the multi-signal heuristic (see §4 Detection Signals).

8. **Build the scan report.** Internal data structure used by Phase 2:
   ```yaml
   detected_agents: [claude-code, cursor]  # one or more
   project:
     type: npm-cli              # inferred from manifest
     name: <project-name>       # from manifest or directory basename
     summary: "..."             # from README or manifest description
   context_files:
     CLAUDE.md: {present: true, lines: 5, has_startup_section: false}
     AGENTS.md: {present: true, lines: 82, ...}
     # ...
   hooks:
     session_start: {present: true, source: global, outputs: [...]}
   memory:
     populated: false
     count: 0
   git: {branch: feat/x, recent_commits: [...], dirty: false}
   in_flight: {issues: [...], prs: [...]}   # if gh available
   stage_signals: 0      # multi-signal score
   ```

**Output:** internal scan report. Not written to disk yet.

**Edge cases:**
- Project not in a git repo → skip git/gh steps; note in scan report
- Read failure on any single file → continue with others; note partial scan
- `gh` not installed → skip `gh` steps; note in scan report (no error to user)

---

### Phase 2 — DIAGNOSE

**Purpose:** Evaluate the scan report against the 5 dimensions and produce a structured diagnosis.

**Procedure:** For each detected agent platform, evaluate each dimension and assign one of: `present-good`, `present-weak`, `missing`, `duplicated`.

| Dimension | Question | Signals |
|---|---|---|
| **Identity** | Does any context file tell the agent what the project IS? | Project summary present in `CLAUDE.md` / `GEMINI.md` / `AGENTS.md`? Project type inferable in first 5 lines? |
| **Workflow** | Does any context file tell the agent the rules and procedure? | Mandatory steps documented? Stage gates documented? Tests/build commands listed? |
| **In-flight** | Does the agent see what's active right now? | SessionStart hook with `gh issue list`? Static roadmap? Static file > 7 days old → flag as likely stale |
| **Startup** | Does the agent know what to read/run in first 30 seconds? | Explicit "Read X first" or "Run Y on start" in any auto-loaded file? |
| **Duplication** | Is any information appearing in multiple places at risk of drift? | Same rule in `CLAUDE.md` AND `AGENTS.md`? Same project description in `CLAUDE.md` AND `README.md` first lines? |

**Additional diagnostics applied across all platforms:**

- **Layer 3 / Layer 4 contamination check:** Any context file that mixes stable identity (project purpose, invariants — Layer 3) with volatile state (current PR, active issue — Layer 4) is flagged. See §3 Layer Model.

- **Canonical sources check:** For each non-trivial rule (workflow step, invariant, "always" / "never" statement), detect occurrences across all context files. ≥2 occurrences = canonical-source violation.

- **Size compliance check:** Files exceeding documented limits flagged:
  - `CLAUDE.md` > 150 lines after current state
  - Any `CONTEXT.md` > 80 lines
  - Reference files > 200 lines

- **Auto-load coverage check:** What rules require an agent to "discover" them via reading a non-auto-loaded file? Identify orphan content that should be referenced or summarized in the auto-loaded layer.

**Output:** Diagnosis report. Internal data structure consumed by Phases 3, 4, and 5.

---

### Phase 3 — ASK

**Purpose:** Fill the smallest possible gap in understanding by asking the user only what cannot be inferred from files.

**Procedure:**

1. **Count usable scan signals.** A "useful signal" = a context file with substantive content OR a detected hook OR a populated memory file OR a clear project type from manifest. Signals < 3 → enter **weak-state fallback** (step 2). Otherwise → proceed to step 3.

2. **Weak-state fallback (3 questions, fixed):**
   - Q1: *In one or two sentences, what does this project do?*
   - Q2: *What are the rules a new agent must never break in this project?*
   - Q3: *What changes most frequently in the active work — issues/PRs in a tracker, tasks in a board, or something else?*

   The skill must not ask more than these 3 questions in fallback mode. Answers populate the diagnosis report as if they had been inferred from files.

3. **Normal-state cirurgical questions (0–3 max):** Ask only when the diagnosis surfaces something the scan can't determine. Examples:
   - When multiple platforms detected but no `AGENTS.md`: *Should rules be unified in `AGENTS.md` (cross-tool) or kept per-platform?*
   - When stage signals = 1 (ambiguous): *Is this project organized as a sequential workflow (each folder = a stage) or is the numbering coincidental?*
   - When `gh` is not authenticated: *Do you want dynamic in-flight queries (requires `gh auth login`) or a static roadmap file (you maintain manually)?*

4. **Never re-ask what scan answered.** This is a hard rule — violations break trust.

**Output:** Augmented diagnosis report.

---

### Phase 4 — RECOMMEND

**Purpose:** Translate diagnosis into a prioritized, transparent list of proposed changes.

**Procedure:** For each gap or violation in diagnosis, generate a recommendation. Each recommendation must include:

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

**Ordering:** Descending by `estimated_savings_per_session`.

**Presentation to user:** The skill presents recommendations in a table:

```
| ID  | Title                                     | +tokens | -tokens | Maint  |
|-----|-------------------------------------------|---------|---------|--------|
| R-1 | Expand CLAUDE.md with Quick Start         |     50  |    600  | zero   |
| R-2 | Add dynamic gh hook for in-flight state   |     20  |    300  | zero   |
| R-3 | Move stable identity to memory files      |      0  |    150  | zero   |
| R-4 | Deduplicate rules btw CLAUDE.md/AGENTS.md |      0  |     80  | low    |
| ... | ...                                       |   ...   |   ...   | ...    |
```

The user selects which recommendations to apply. **The skill does not filter by ROI threshold.** It shows the data and asks: *Which of the above should be applied?*

**Output:** Approved recommendation set.

---

### Phase 5 — IMPLEMENT

**Purpose:** Apply approved recommendations and produce the audit record.

**Procedure:**

1. **Order of operations:**
   - Group recommendations by target file
   - For each file, apply all relevant changes in a single non-destructive merge
   - Generate new files only after existing-file edits succeed

2. **Per-agent adapter recipes (see §5 Per-Agent Adapters):**
   - Claude Code recommendations → `CLAUDE.md`, `.claude/settings.json` hook entries, memory files
   - Cursor recommendations → `.cursor/rules/*.mdc` with caveat header
   - Gemini / Antigravity recommendations → `GEMINI.md`, `.gemini/config.yaml` with caveat header

3. **Layer separation enforced at write time:**
   - Stable identity (project purpose, invariants, workflow rules) → memory files
   - Startup behavior (what to read, what to run, hard constraints) → `CLAUDE.md` (and equivalents)
   - In-flight state → never written as static; only emitted via dynamic hooks
   - These categories never overlap in a single file — guaranteed by the writing procedure, not by post-hoc checking

4. **Generate `context-spec.md`** in the project root. Contents:
   ```markdown
   ---
   generated-by: context-optimizer@<version>
   generated-at: <ISO-8601 timestamp>
   ---

   # Context Optimization Spec — <project name>

   ## Project Snapshot
   - Detected agents: ...
   - Project type: ...
   - Scan signals: ...

   ## Diagnosis Summary
   <5-dimension table>

   ## Applied Recommendations
   <list of REC-XXX with file paths and rationale>

   ## Declined Recommendations
   <list with user reason if provided>

   ## Out of Scope (Deliberately Not Touched)
   <list with reasoning>

   ## Known Patterns Referenced
   <list>

   ## Ad-Hoc Recommendations
   <items not yet codified in Known Patterns — candidates for community contribution>
   ```

5. **Final summary to user:** Single message listing:
   - What was changed (paths, brief description)
   - What needs user validation (cross-agent files with caveats)
   - Pointer to `context-spec.md` for the full audit record

**Output:** Modified context files + `context-spec.md`.

**Idempotency:** Re-running on the resulting state produces no new recommendations (or only `ad-hoc` ones that emerged from new project changes).

---

## 3. Layer Model

The skill internally classifies all context into five layers, borrowed and adapted from ICM (https://github.com/RinDig/Interpreted-Context-Methdology).

| Layer | Name | What lives here | Examples in this skill's outputs |
|---|---|---|---|
| **0** | Always loaded | Auto-injected on every session | `CLAUDE.md`, `GEMINI.md`, `.cursorrules` |
| **1** | Task routing | What-to-load instructions | Startup section *inside* Layer 0 files; AGENTS.md when cross-tool |
| **2** | Workspace context | Per-domain context (for projects with sub-domains) | `CONTEXT.md` in subdirs (rarely produced — only when stage signals ≥ 2) |
| **3** | Stable reference (factory) | Project identity, invariants, workflow rules | Memory files; `docs/` references |
| **4** | Run-specific artifacts (product) | In-flight state, current work | SessionStart hook outputs (dynamic); never static files |

### Why Layer 3 vs. Layer 4 matters

**Layer 3 contamination by Layer 4** is the most common context anti-pattern observed during design:

| Anti-pattern | Why it fails |
|---|---|
| `CLAUDE.md` says "Current PR: #80" | Stale within hours. Every session reads incorrect data and wastes tokens discovering the truth. |
| Memory file lists "active issues" | Memory was designed for stable facts; staleness pollutes the persistence guarantee. |
| `AGENTS.md` includes "this week's priorities" | Mixes contract (Layer 3) with product (Layer 4). Drift propagates to every agent reading the contract. |

**Resolution:** the skill writes Layer 3 to files; emits Layer 4 via dynamic hooks. By construction, they cannot mix.

### Token budgets per layer (guidance, not enforcement)

| Layer | Target budget per session | Why |
|---|---|---|
| 0 (always loaded) | ≤ 1,000 tokens | Paid on every conversation; stays lean |
| 1 (routing) | ≤ 300 tokens | Read once at startup |
| 2 (workspace) | 200–500 tokens each | Read per task domain |
| 3 (stable ref) | varies | Loaded selectively when referenced |
| 4 (run artifacts) | 50–200 tokens | Generated dynamically; bounded |

These are guidance numbers used by the recommendation generator. They are not hard caps.

---

## 4. Detection Signals (multi-signal heuristic)

To decide whether to recommend ICM-style stage contracts (workflow patterns), the skill uses a multi-signal score. **A single signal is never sufficient** — false positives ruined naïve heuristics like "numbered folders".

| Signal | Weight | Detection |
|---|---|---|
| Numbered folders (`01-`, `02-`) | weak (1) | Glob `[0-9]*-*/` at root or within `workspaces/`, `stages/` |
| `output/` or `artifacts/` subdirectories | medium (2) | Within any candidate stage folder |
| `CONTEXT.md` files in subdirectories | strong (3) | Glob `**/CONTEXT.md` (not at root) |
| GitHub Actions with sequential job dependencies | strong (3) | Parse `.github/workflows/*.yml` for `needs:` chains |
| Labels with stage prefix | strong (3) | Detect `stage:`, `phase:`, `pipeline:` patterns in label config or sample issues via `gh` |
| README mentions workflow / pipeline / stages | medium (2) | Grep first 100 lines of README for these terms |

**Rule:** total score ≥ 4 OR ≥ 1 strong signal + ≥ 1 other signal = recommend stage contracts. Otherwise, do not.

Document the score in `context-spec.md` so the user can audit the decision.

---

## 5. Per-Host Adapters

The skill ships in three host-native flavors (Claude Code v1.0, Cursor v1.1, Gemini/Antigravity v1.2). Each flavor uses the same procedure but writes to its host's native context files. When the skill is invoked from inside host X, host X's writes carry no caveat. When the skill encounters config files for a non-current host on the same project, it writes to those files **with** caveat lines.

The recipes are versioned in the skill's `Known Patterns` section.

### 5.1 Claude Code adapter (v1.0 — reference implementation)

**Files the adapter writes to:**

| File | Purpose | What goes here |
|---|---|---|
| `CLAUDE.md` | Layer 0 always-loaded context | Quick Start (project summary + workflow + startup checklist) + policy rules |
| `.claude/settings.json` | Hook registration | SessionStart hook entry pointing to generated script |
| `.claude/hooks/session-briefing.sh` | Dynamic Layer 4 emission | `gh issue list` / `gh pr list` calls with `ENABLE_GH_QUERIES` opt-in |
| `~/.claude/projects/<proj>/memory/MEMORY.md` | Memory index | Pointers to individual memory files |
| `~/.claude/projects/<proj>/memory/project_purpose.md` | Layer 3 identity | Project type, stack, purpose |
| `~/.claude/projects/<proj>/memory/workflow_invariants.md` | Layer 3 rules | Non-negotiable rules |

**Generated `CLAUDE.md` skeleton:**

```markdown
# <project name>

**What it is:** <one line>
**Workflow:** <one line — e.g., labels-driven, stages, free-form>
**Stack:** <one line>

## Session Startup

Read: <key files with #section refs where possible>
Run: <one command, ideally `gh issue list` or equivalent>

# <Existing policy section preserved if present>
```

**Generated `session-briefing.sh` skeleton:**

```bash
#!/bin/bash
ENABLE_GH_QUERIES=true  # set false for short-session projects (<10min typical)

# … (lightweight git/gh queries, guarded by command -v gh && gh auth status)
```

### 5.2 Cursor adapter (v1.1 port — same procedure, Cursor-native invocation)

**Invocation in v1.1:** the skill ships as `.cursor/rules/context-optimizer.mdc` (or as documented procedure the user references in Cursor chat). When invoked **inside Cursor**, the adapter executes the same 5-phase procedure and writes to:

| File | Purpose |
|---|---|
| `.cursor/rules/project-context.mdc` (preferred) or `.cursorrules` (legacy) | Layer 0 equivalent for Cursor |

**Caveat rule:** when invoked inside Cursor, generated `.cursor/rules/*.mdc` files carry **no caveat** — the skill is in the host whose behavior it can verify. When the skill is invoked inside a different host (e.g., Claude Code) and writes to `.cursor/rules/` because Cursor config exists on the project, the caveat **is** required:

```
# Added by context-optimizer (running in <current host>) — verify behavior in Cursor before relying on this
```

**Cursor specifics:** Cursor reads `.cursorrules` (legacy) automatically; `.cursor/rules/*.mdc` is the newer format. The adapter prefers `.mdc` when `.cursor/rules/` already exists; otherwise creates `.cursorrules`.

### 5.3 Gemini CLI / Antigravity adapter (v1.2 port)

**Invocation in v1.2:** the skill ships as `.agents/skills/context-optimizer/SKILL.md` for Antigravity (v1.20.3+); for Gemini CLI, the skill is invoked via a documented procedure referenced from `GEMINI.md`. When invoked inside Gemini/Antigravity, the adapter writes to:

| File | Purpose |
|---|---|
| `GEMINI.md` | Shared Layer 0 context (Gemini CLI + Antigravity) |
| `.gemini/config.yaml` (optional) | Antigravity-specific config |
| `.gemini/styleguide.md` (optional) | Style preferences (if user provides any) |

**Note on AGENTS.md:** Antigravity v1.20.3+ supports `AGENTS.md` as a cross-tool format. When the skill detects multiple agents, it may recommend consolidating cross-tool rules into `AGENTS.md` and keeping per-tool files thin. This is a recommendation surfaced to the user; the user decides.

**Caveat rule:** identical to Cursor — no caveat when invoked inside Gemini/Antigravity; caveat required when invoked from another host writing to Gemini files.

### 5.4 Cross-tool `AGENTS.md` adapter

When ≥ 2 agents are detected, the skill recommends consolidating shared rules in `AGENTS.md`. Per-agent files reference `AGENTS.md` for shared rules, then add tool-specific overrides.

```
AGENTS.md (shared workflow, invariants — Layer 3)
  ↑
  ├── CLAUDE.md  (Claude-specific startup + reference to AGENTS.md)
  ├── GEMINI.md  (Gemini-specific startup + reference to AGENTS.md)
  └── .cursor/rules/  (Cursor-specific + reference to AGENTS.md)
```

This pattern reduces drift across platforms (one-way reference, canonical source rule honored).

---

## 6. Known Patterns (the versioned proposer prior)

A bullet-listed, named library of patterns the skill knows to apply. Versioned inside the skill file under a `## Known Patterns` heading. Each pattern has: name, one-line description, trigger condition, rationale, expected savings.

Initial list for v1.0:

| Pattern | Trigger | What it does |
|---|---|---|
| `layer-0-startup-guide` | Diagnosis: startup = `missing` or `weak` | Add Quick Start section to Layer 0 file |
| `dynamic-in-flight` | Diagnosis: in-flight = `missing`; `gh` authenticated | Generate SessionStart hook with `gh issue list` opt-in |
| `static-in-flight-fallback` | Diagnosis: in-flight = `missing`; `gh` NOT authenticated | Generate `current-roadmap.md` with NEXT/LATER format and stale-warning |
| `layer-3-extraction` | Layer 3/4 contamination detected | Move stable identity from Layer 0 file to memory files |
| `canonical-source-dedup` | Same rule found ≥ 2 files | Move rule to one canonical file; replace others with reference |
| `section-routing` | Multi-section file > 80 lines | Replace blanket "read X" instructions with "read X#section" pointers |
| `cross-tool-agents-md` | ≥ 2 agent platforms detected | Recommend `AGENTS.md` consolidation |
| `caveat-on-untested` | Generated config for Cursor or Gemini | Insert caveat header into generated file |
| `stage-contract` | Stage signals ≥ 4 | Recommend ICM-style `CONTEXT.md` per stage folder |
| `roi-transparency` | Always | Present cost + savings numbers for every recommendation |

When the diagnosis surfaces a gap not matched by any Known Pattern, the recommendation is tagged `ad-hoc` and surfaced for community contribution.

---

## 7. Data Flow

```
   User invokes /skill context-optimizer
              │
              ▼
   ┌────────────────────────┐
   │  Scan (read-only)      │ ───┐
   └──────────┬─────────────┘    │
              │                   │
              ▼                   │
   ┌────────────────────────┐    │
   │  Diagnose              │    │
   └──────────┬─────────────┘    │
              │                   │
              ▼                   │
   ┌────────────────────────┐    │  (scan + diagnose
   │  Weak state?           │    │   are read-only
   │   yes → 3-question     │    │   throughout)
   │        fallback        │    │
   │   no  → surgical 0-3   │    │
   └──────────┬─────────────┘    │
              │                   │
              ▼                   │
   ┌────────────────────────┐    │
   │  Recommend (table)     │ ◄──┘
   └──────────┬─────────────┘
              │
              ▼
   ┌────────────────────────┐
   │  User selects R-N      │
   └──────────┬─────────────┘
              │
              ▼
   ┌────────────────────────┐
   │  Implement (writes)    │
   │  + per-agent adapters  │
   │  + Layer separation    │
   │  + caveat headers      │
   └──────────┬─────────────┘
              │
              ▼
   ┌────────────────────────┐
   │  context-spec.md       │
   │  Summary to user       │
   └────────────────────────┘
```

---

## 8. Trade-off Analysis (architect lens)

Honest review of design decisions. Each row names the chosen path and the realistic alternative.

| Decision | Alternative | Why alternative could win | Lock-in / cost to switch |
|---|---|---|---|
| **Single skill file, no installer** | Curl-installable repo (claude-code-dotfiles model) | Better updateability; can ship Known Patterns updates separately from the procedure | Low — wrapping in an installer is a 1-day task post-v1 |
| **Local-first, no SaaS** | Hosted version with shared Known Patterns | Cross-user pattern aggregation; could learn from anonymized `context-spec.md` records | Medium — would require new privacy/storage design |
| **Dynamic in-flight via `gh`** | Static roadmap files | No dependency on `gh` auth; works offline | Low — pattern already includes static-fallback variant |
| **Multi-agent in v1 (Claude + Cursor + Gemini)** | Claude-only v1, add others in v2 | Faster ship; safer testing | Medium — designing the adapter abstraction now is cheaper than retrofitting |
| **Prompt-only procedure (skill Markdown)** | Python tool with deterministic logic | More reliable; testable; no LLM nondeterminism in the scan logic | High — would change the project from "skill" to "tool"; harder community distribution |
| **No ROI threshold gate** | Suggest a default threshold (5×) | Reduces user decision fatigue | Low — could add a "highlight recommended" annotation later |
| **`context-spec.md` in project root** | Hidden file in `.claude/` subdirectory | Less visual clutter | Low — path is configurable |

### 10× / 100× thinking

The skill is a tool used by individual developers on individual projects. Scale concerns are limited but real:

| Scale dimension | Where it breaks first |
|---|---|
| Project size (10× more files) | Glob scans at `**/*` patterns could time out on very large monorepos. Mitigation: explicit exclude list (`node_modules`, `venv`, `.git`, `dist`, `build`); soft cap on number of files read per scan (e.g., 200) |
| Known Patterns library (10× patterns) | Skill file becomes too long for context window. Mitigation: split into pattern files referenced from skill body |
| User base (community adoption) | Drift between user expectations and skill behavior; abuse cases (skill used for things it's not designed for) | Mitigation: aggressive `Out of Scope` in README; clear redirect to CAR/ICM/meta-harness/etc. |

### Three highest-likelihood failure points

1. **Cursor / Gemini format drift** (Months 3–6 after release): Cursor `.mdc` format evolves, or Antigravity changes how it loads `GEMINI.md` / `AGENTS.md`. Caveat lines mitigate user surprise, but Known Patterns will need updates.

2. **Prompt fragility** (Months 1–3): The skill is a long Markdown prompt. Edge cases in projects (unusual file structures, mixed languages, edge encoding) can produce off-spec outputs. Mitigation: idempotency requirement (NFR-4) — re-runs converge; explicit test on 3 reference project types (PRD §2.4).

3. **Community confusion** (At release): Similar names (CCv3 is also called `claude-code-context-optimizer`). Inbound users land on the wrong tool. Mitigation: COMPETITIVE_ANALYSIS.md positions clearly; README explicitly differentiates.

### Technical debt accumulated in first 12 months (realistic)

If shipped as designed and adopted modestly (50–500 users):

- ~2 weeks: maintaining Known Patterns as platforms evolve
- ~1 week: handling edge cases reported by users (monorepos, exotic project structures)
- ~1 week: triaging community contributions to Known Patterns (review, integration, versioning)
- ~3 days: documentation updates (`COMPETITIVE_ANALYSIS.md` as new tools emerge)

Total: ~5 weeks of reactive engineering in year 1. Front-loaded heavily in months 1–3.

---

## 9. Agentic vs. Traditional Comparison

The skill itself is an agentic tool — a prompt executed by an LLM rather than a deterministic procedure. Where does this help vs. hurt?

| Dimension | Agentic skill | Equivalent Python CLI |
|---|---|---|
| **Build time** | Lower — most logic is prose | Higher — requires real code, tests, packaging |
| **Adaptability to new projects** | High — LLM handles novel structures | Lower — would require config schemas for each project type |
| **Determinism** | Lower — same project might get slightly different recommendation phrasing | High — same input → same output |
| **Testability** | Lower — hard to unit-test LLM outputs | High — standard test pyramid applies |
| **Cost per invocation** | Token cost of running the skill (paid by user's existing Claude subscription) | Compute cost of running a script (negligible) |
| **Community contribution** | High — patterns are Markdown, easy to PR | Lower — requires reading code |
| **Risk of off-spec behavior** | Medium — depends on Known Patterns clarity | Low |

**Verdict:** Agentic skill is the right call for v1 because the problem is genuinely judgment-heavy (deciding what to recommend given partial signals) and the community-contribution path is strongest for Markdown patterns. Migrating to a deterministic CLI is a v2+ option if scale demands it.

---

## 10. Constraints and Invariants

Hard constraints that the implementing agent must not violate.

| ID | Constraint |
|---|---|
| C-1 | The skill must never modify source code, only context configuration files |
| C-2 | The skill must never delete user content. "Replace" operations are non-destructive merges with explicit consent |
| C-3 | The skill must run inside a single host session (Claude Code / Cursor / Gemini-Antigravity) with default tool access — no external service dependencies |
| C-4 | The v1.0 skill must be installable as a single `.md` file in `~/.claude/skills/`. v1.1 and v1.2 ports use the host-native equivalent install path. |
| C-5 | Layer 3 and Layer 4 outputs must never appear in the same file (enforced at write time) |
| C-6 | Every cross-host generated file (config written for a host the skill isn't currently running inside) must include the caveat header (REQ-041, REQ-042). Files written for the current host carry no caveat (REQ-046). |
| C-7 | `context-spec.md` must be produced on every implementation phase, even when only 1 recommendation is applied |
| C-8 | Every recommendation must map to a Known Pattern OR be tagged `ad-hoc` (no untagged recommendations) |
| C-9 | The skill procedure (5 phases + Known Patterns + layer model) must remain identical across host ports. Only invocation mechanism and write paths differ between v1.0, v1.1, v1.2. |

---

## 11. Implementation File Layout (target end state in the new repo)

The skill ships in one Markdown procedure with host-specific install targets. The repository contains:

```
context-optimizer/
├── README.md                              # Public-facing readme (links to PRD, etc.)
├── LICENSE                                # MIT
├── skill/
│   ├── context-optimizer.md               # v1.0 — Claude Code skill (frontmatter + procedure)
│   ├── context-optimizer.cursor.mdc       # v1.1 — Cursor port (same procedure, Cursor frontmatter)
│   └── context-optimizer.antigravity.md   # v1.2 — Antigravity/Gemini port (.agents/skills/ format)
├── docs/
│   ├── PRD.md                             # Copied from spec dir
│   ├── ARCHITECTURE.md                    # Copied from spec dir
│   ├── COMPETITIVE_ANALYSIS.md            # Copied from spec dir
│   └── IMPLEMENTATION_GUIDE.md            # Copied from spec dir
├── examples/
│   ├── before/                            # Sample weak-state project
│   ├── after/                             # Same project after skill run
│   └── context-spec.md.example            # Sample audit record
├── known-patterns/
│   └── v1/                                # Pattern definitions shared across all host ports
└── install/
    ├── claude-code.sh                     # v1.0 install: cp to ~/.claude/skills/
    ├── cursor.sh                          # v1.1 install: cp to project's .cursor/rules/
    └── antigravity.sh                     # v1.2 install: cp to .agents/skills/context-optimizer/
```

**v1.0 ships only `context-optimizer.md` (Claude Code).** v1.1 adds the Cursor port; v1.2 adds the Antigravity port. The shared `known-patterns/v1/` directory is referenced by all three host ports — single source of truth for pattern definitions.

The exact internal layout of the skill file itself is in `IMPLEMENTATION_GUIDE.md`.

---

## 12. Open Architectural Questions

Same as `PRD.md#open-questions` plus:

- **Q-A1:** Should the skill maintain a local cache of "last scan" results to enable diff-based re-optimization? *Recommended default: no for v1 — `context-spec.md` is the persistent record; the scan re-runs from scratch.*
- **Q-A2:** Should Known Patterns be embedded in the skill body or loaded from a sibling file? *Recommended default: embedded for v1, extracted to sibling file when pattern count > 15.*
- **Q-A3:** Should multi-agent recommendations be batched (all platforms in one apply step) or sequential (apply Claude first, ask before continuing to Cursor)? *Recommended default: batched, all changes presented together for one user decision.*

---

## 13. v2.0 Roadmap — Organic Memory Growth (deferred, design sketch)

> **Status: Lower-priority roadmap. Do not begin v2.0 work until v1.0 is shipped, validated on the 3 reference projects, and at least one community user has run it end-to-end successfully.** See `PRD.md` §12.2 for product framing. This section sketches the architectural shape only.

### 13.1 Problem v2.0 addresses

v1.0 populates project memory **at invocation time** based on scan + diagnose. After the optimization session ends, memory is frozen until the user manually re-invokes the skill. During real work, the agent often encounters Layer 3 facts ("this codebase uses 4-space indent", "tests live in `/spec` not `/tests`", "the team prefers `feat:` not `feature/` branch prefix") that have no path to memory without re-running the full skill.

### 13.2 Pattern absorbed from OpenClaw

The OpenClaw memory model (https://gist.github.com/dabit3/bc60d3bea0b02927995cd9bf53c3db32) gives the agent a `save_memory` tool that it invokes mid-work when it judges a fact worth persisting. Memory grows organically. The pattern is sound but requires constraints to prevent contamination.

### 13.3 Design sketch

**New tools** (added to v1.0's procedure as host-native tools in v2.0):

| Tool | Purpose | Layer constraint |
|---|---|---|
| `save_project_fact(category, fact, evidence)` | Append a stable fact to the project's memory directory | Layer 3 only — must be project-identity, conventions, invariants |
| `recall_project_facts(query)` | Search saved facts during work | Read-only |

**Tool contract (enforced by tool description, not runtime):**

1. `category` must be one of a fixed enum: `convention`, `invariant`, `architecture`, `domain-knowledge`. Run-specific categories (`current-pr`, `today's-task`) are **rejected by description**.
2. `fact` must be stated as a present-tense rule or property, not a transient observation. "Tests use pytest" is allowed; "I'm currently fixing bug #42" is not.
3. `evidence` is mandatory. Must reference a file path, git history, or explicit user statement. Without evidence the call fails — preventing hallucinated facts.

**Memory write logic:**

- v2.0 appends to memory files created by v1.0 (`workflow_invariants.md`, `project_purpose.md`, or new file per category)
- The audit record (`context-spec.md`) gets a new section: `## Growth Events` with timestamp, category, fact, evidence, source agent
- Idempotency: same fact + same evidence twice = no-op
- Conflict: a new fact contradicting an existing fact triggers user review (write blocked until user resolves)

### 13.4 What v2.0 does NOT change

- v1.0's scan-first procedure stays
- v1.0's Known Patterns library stays (likely receives a new pattern `organic-growth-tool` documenting the v2.0 tool itself)
- v1.0's `context-spec.md` format stays, extended with `Growth Events`
- v1.0's layer model stays — v2.0 tools enforce the model harder

### 13.5 Sequencing constraint

v2.0 depends on v1.0 being shipped in at least one host. The first host to receive v2.0 is the same host already optimized for v1.0 in that user's project. The tool ships host-native (Claude Code tool first, then Cursor, then Antigravity).

### 13.6 Why deferred

- v1.0 cold-start (project never optimized) is the dominant pain. v2.0 only helps post-setup.
- v2.0 requires telemetry from real v1.0 usage to know which categories of facts emerge most often during work — informs the category enum.
- v2.0 has unsolved risk: agent saving incorrect facts. v1.0 must establish trust first.

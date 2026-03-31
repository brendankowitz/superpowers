# Copilot CLI Support

Three implementation phases: initial parity, workflow skill, and official plugin alignment.

---

## Phase 1: Parity-First Integration

### Design

Enable Superpowers in GitHub Copilot CLI with behavior as close as possible to Claude Code CLI integration: native skill discovery + startup bootstrap context + platform mapping + regression tests.

## Motivation

Superpowers already has strong platform paths for Claude Code, Codex, OpenCode, and Gemini. Copilot CLI support must not be "docs only" or extension-fragile; it should follow the same proven primitives as Claude/Codex where possible.

## Parity target

"As close as possible" means matching core operational behavior, not identical internal APIs:

1. Skills are discovered natively from standard skill directories.
2. Session-start bootstrap injects `using-superpowers` guidance automatically.
3. Platform-specific tool mapping exists and is referenced by bootstrap/docs.
4. Integration has automated checks and documented install/verify/update flow.

## Current State

- Existing bootstrap hook script: `hooks/session-start`
- Existing hooks config present in repo: `hooks/hooks.json` (Claude Code format) and `hooks/hooks-cursor.json` (Cursor format)
- **Unverified:** Whether Copilot CLI reads `hooks/hooks.json`, `.github/hooks/hooks.json`, or another location. Must be verified before documenting hook setup.
- Existing platform mapping precedents:
  - `skills/using-superpowers/references/codex-tools.md`
  - `skills/using-superpowers/references/gemini-tools.md`
- Existing install doc pattern:
  - `.codex/INSTALL.md`
  - `.opencode/INSTALL.md`
- No Copilot-specific README or mapping doc currently exists.

## Design Principles

1. **Prefer proven paths over novel APIs**
   - Use hook-based startup injection as primary bootstrap mechanism.
2. **Use standard skill discovery paths**
   - Align with `~/.agents/skills/superpowers` style setup used by Codex/Claude ecosystem.
3. **Treat extension support as additive, not foundational**
   - Copilot extension can be optional fallback/enhancement, not required for v1 parity.
4. **Document verified capabilities only**
   - Tool mapping must be based on validated Copilot tool inventory.

## Proposed Architecture

### 1) Primary bootstrap: hooks-based session start

Use Copilot hooks configuration (repo/local) to run:

- `hooks/session-start`

This script already emits platform-aware JSON (`additional_context` fallback and Claude-specific `hookSpecificOutput`) and loads full `skills/using-superpowers/SKILL.md`.

Action:
- Verify which environment variables (if any) Copilot CLI sets at hook invocation time. The existing script handles `CURSOR_PLUGIN_ROOT` and `CLAUDE_PLUGIN_ROOT` but has no Copilot-specific detection. If Copilot sets neither, the script falls back to generic `additional_context` JSON — verify Copilot actually consumes this field.
- Verify exact hooks config file location Copilot CLI reads (`.github/hooks/hooks.json`, `hooks/hooks.json`, user-scoped config, or other). Do not document a path until verified.
- **Verify whether Copilot supports a user-level (global) hooks config** that fires in every session regardless of which repo is open. This determines the global install story:
  - If a global config exists, the bootstrap fires everywhere and global install is fully supported.
  - If hooks are per-repo only, the session-start bootstrap only fires in repos with a local hook config. Skills are still globally discoverable via the symlink, but context injection requires per-repo opt-in. This limitation must be documented explicitly.
- If Copilot sets its own env variable, add a detection branch to `hooks/session-start` (matching the existing `CURSOR_PLUGIN_ROOT` / `CLAUDE_PLUGIN_ROOT` pattern). If Copilot requires a different config file format or location, create `hooks-copilot.json` alongside the existing `hooks-cursor.json`.

### 2) Native skill discovery parity

Install flow must include symlink/junction setup to a standard skills location:

- Unix: `~/.agents/skills/superpowers -> <clone-path>/skills` (skill discovery path TBD pending verification)
- Windows: junction equivalent under `%USERPROFILE%\.agents\skills\superpowers`

**Clone path:** Do not assume `~/.copilot/superpowers`. The `~/.copilot/` directory may conflict with GitHub Copilot's own data directories (`~/.config/github-copilot/` on Linux, `%APPDATA%\GitHub Copilot\` on Windows). Verify a non-conflicting convention (e.g., `~/.copilot-superpowers/superpowers` or `~/.local/share/superpowers`) before documenting install steps.

Rationale:
- Matches Codex/Claude-style native discovery behavior.
- Keeps skills source-of-truth in this repository.

### 3) Copilot tool mapping reference

Create:

- `skills/using-superpowers/references/copilot-tools.md`

Must include:
- Verified tool name mappings
- Subagent/delegation capability status (supported vs unsupported) and fallback behavior
- Windows PowerShell notes and path guidance

Also update `skills/using-superpowers/SKILL.md`: the platform reference line currently only mentions `codex-tools.md` and Gemini. Add a reference to `copilot-tools.md` for Copilot users.

### 4) Copilot platform docs

Create:

- `docs/README.copilot.md`

Include:
- Prerequisites
- Install via clone + symlink/junction
- Hook setup
- Verification steps
- Update/uninstall
- Troubleshooting

Create (if Copilot supports remote-fetch install pattern like Codex):

- `.copilot/INSTALL.md` — self-bootstrapping entry point so users can say "fetch and follow instructions from raw.githubusercontent.com/.../INSTALL.md"

Update:
- `README.md` (Copilot section)
- `RELEASE-NOTES.md` (parity-first Copilot support)

### 5) Optional extension path (non-blocking)

If extension approach is included, it is explicitly secondary:

- `.github/extensions/superpowers/extension.mjs` may be added only as optional enhancement.
- Do not make parity depend on extension startup context injection.
- If extension startup context API behavior is uncertain, document limitation and keep hook path primary.

**Important:** GitHub Copilot Extensions require a registered GitHub App — this is not a file-drop enhancement. Do not begin extension work without confirming the app registration and OAuth flow requirements. Document clearly in user-facing docs that the extension requires a registered app to function.

## Capability Verification Requirements (before mapping claims)

1. Verify Copilot tool inventory names in real session context.
2. Verify whether subagent/multi-agent delegation exists; if absent, define Gemini-style fallback guidance.
3. Verify hook payload shape consumed by Copilot for session-start context.
4. Verify whether a user-level global hooks config exists; determine the global install story before writing install docs.

No mapping or parity claims should be made without these checks.

## Risks and Mitigations

1. **Hook payload mismatch across Copilot versions**
   - Mitigation: add tests for hook output schema and concise troubleshooting docs.

2. **Unverified tool mapping drift**
   - Mitigation: add mapping integrity tests and require verified examples in docs.

3. **Windows setup friction**
   - Mitigation: include explicit PowerShell junction commands and path examples.

4. **Over-claiming parity**
   - Mitigation: define parity checklist and explicitly mark unsupported features with fallback behavior.

5. **Per-repo-only hooks limit global install story**
   - If Copilot has no user-level hooks config, the bootstrap context only fires in repos with local hook config, unlike Claude Code where the plugin install is global. Mitigation: document clearly that skills are globally discoverable (symlink) but bootstrap context requires per-repo opt-in, and provide both a "global skills only" and "per-repo full parity" setup path.

## Acceptance Criteria (parity-close)

1. Copilot install docs provide clone + native skills discovery setup (symlink/junction) using a verified, non-conflicting clone path.
2. Session-start bootstrap is documented and works via hooks path; `hooks/session-start` detects Copilot env var (if one exists).
3. `copilot-tools.md` exists with verified mappings and capability/fallback notes.
4. `skills/using-superpowers/SKILL.md` references `copilot-tools.md` for Copilot users.
5. Automated tests validate hook/bootstrap + mapping + install-path assumptions and **all tests pass**.
6. README/release notes reflect Copilot support without unsupported claims.
7. If subagent support is absent, fallback to `executing-plans` is documented (matching `gemini-tools.md` pattern).
8. Troubleshooting docs cover: skill discovery verification, hook execution verification, common symlink/junction errors, and Copilot version compatibility.
9. Global install story is documented: either a global hooks config path is provided, or the per-repo-only limitation is stated with a "global skills only" install option as the default recommendation.

## Out of Scope

- Rewriting all skills for Copilot-only semantics
- Guaranteeing feature parity for capabilities Copilot does not expose (if any)
- Replacing existing platform integrations

### Implementation Plan

> **For agentic workers:** REQUIRED: use `superpowers:subagent-driven-development` (preferred) or `superpowers:executing-plans`. Use checkbox steps (`- [ ]`) for task tracking.

**Goal:** Deliver Copilot CLI support as close as possible to Claude Code behavior via native skill discovery and hook-based bootstrap, with verified mappings and tests.

**Architecture:** Primary path is clone + native skills symlink/junction + session-start hook bootstrap. Optional extension support may be added, but parity does not depend on it.

**Tech Stack:** Markdown docs, shell hooks, bash-based tests, optional JS ESM extension.

---

## File Map

- **Create:** `skills/using-superpowers/references/copilot-tools.md` — verified Copilot mapping + capability notes
- **Create:** `docs/README.copilot.md` — complete Copilot install/use/update/troubleshooting guide
- **Create:** `.copilot/INSTALL.md` — self-bootstrapping install entry point (verify Copilot supports remote-fetch pattern first; skip if not)
- **Create:** `hooks-copilot.json` — Copilot hooks config (only if Copilot requires a different format/path than `hooks/hooks.json`)
- **Create:** global hooks config entry or instructions (path TBD pending Task 1 Step 6 — e.g., user-level `~/.config/github-copilot/hooks.json` or equivalent)
- **Create:** `tests/copilot/run-tests.sh` — test runner
- **Create:** `tests/copilot/test-hook-bootstrap.sh` — validate hook config + hook output expectations
- **Create:** `tests/copilot/test-tool-mapping.sh` — mapping structure + required capability/fallback sections
- **Create:** `tests/copilot/test-install-paths.sh` — install instruction checks (symlink/junction guidance)
- **Modify:** `hooks/session-start` — add Copilot env var detection branch (post-Task 1 verification)
- **Modify:** `skills/using-superpowers/SKILL.md` — add `copilot-tools.md` reference alongside existing `codex-tools.md` mention
- **Modify:** `README.md` — add Copilot section
- **Modify:** `RELEASE-NOTES.md` — add Copilot support note
- **Optional Create:** `.github/extensions/superpowers/extension.mjs` and `.github/extensions/superpowers/README.md` (non-blocking enhancement — requires GitHub App registration, not a file-drop)

---

## Chunk 1: Capability Verification (must happen first)

### Task 1: Verify Copilot operational capabilities before writing mapping

**Files:**
- Evidence captured in `docs/README.copilot.md` (or linked notes in commit message)

- [ ] **Step 1:** Verify available tool inventory names in Copilot CLI sessions
- [ ] **Step 2:** Verify subagent/delegation support status
- [ ] **Step 3:** Verify hook bootstrap payload compatibility for session start
  - Which environment variables does Copilot CLI set at hook time? (`CLAUDE_PLUGIN_ROOT`, `CURSOR_PLUGIN_ROOT`, something else, or none?)
  - Does Copilot consume the `additional_context` JSON field from hook output?
  - Where does Copilot look for hooks config? (`hooks/hooks.json`, `.github/hooks/hooks.json`, user config, or other?)
- [ ] **Step 4:** Verify Copilot's skill discovery paths (does it scan `~/.agents/skills/`, `.agents/skills/`, `.github/skills/`, or other?)
- [ ] **Step 5:** Verify safe clone path convention — `~/.copilot/` may conflict with GitHub Copilot's own data directories (`~/.config/github-copilot/` on Linux, `%APPDATA%\GitHub Copilot\` on Windows). Determine a non-conflicting clone path before documenting install steps.
- [ ] **Step 6:** Verify whether Copilot supports a **user-level (global) hooks config** that fires in every repo, not just repos with a local hook config file. This is critical for global install parity:
  - If a global hooks config exists, document its path and format — global install is fully supported.
  - If hooks are per-repo only, the skill symlink still works globally (skills discovered everywhere) but the session-start bootstrap context will only fire in repos that have the hooks config locally. Document this limitation explicitly and provide a per-repo hook setup option for users who want bootstrap context in specific repos.

**Rule:** Do not finalize `copilot-tools.md` or `docs/README.copilot.md` until these are verified. All downstream chunks are gated on Task 1 completion.

---

## Chunk 2: Native Parity Path (core)

**DEPENDENCY:** All steps in this chunk require Task 1 completion. Do not document hook paths or install flows based on assumptions.

### Task 2: Document and wire native skill discovery + hook bootstrap

**Files:**
- Create/Modify: `docs/README.copilot.md`
- Read/Reference: `hooks/session-start`, `hooks/hooks.json`

- [ ] **Step 1:** (BLOCKED on Task 1) Add install flow with clone + skills symlink/junction

The symlink/junction is a **global install** — once created, skills are discoverable in every Copilot session regardless of which repo is open. Must include (using verified paths from Task 1 — all paths below are [TBD pending Task 1]):
- Clone path convention: `[TBD — verify non-conflicting path, e.g. ~/.copilot-superpowers/superpowers or ~/.local/share/superpowers]`
- Unix symlink: `ln -s <clone-path>/skills ~/.agents/skills/superpowers` (skill discovery path [TBD pending Task 1 Step 4])
- Windows junction: `cmd /c mklink /J "%USERPROFILE%\.agents\skills\superpowers" "<clone-path>\skills"` (path [TBD])

- [ ] **Step 2:** (BLOCKED on Task 1) Add hook setup flow — **global vs per-repo**

Two cases based on Task 1 Step 6 findings:

**Case A — Copilot has a global hooks config:** Document the global config path and show users how to register `hooks/session-start` once. The install is fully global: skills discovered everywhere, bootstrap fires everywhere.

**Case B — Copilot hooks are per-repo only:** Document this limitation clearly. Provide two sub-flows:
  1. **Global skills only (recommended for most users):** symlink alone — skills work everywhere, no bootstrap context injection.
  2. **Per-repo full parity:** add hook config to a specific repo for full bootstrap. Describe what this gains (auto-injected `using-superpowers` context at session start).

If Copilot sets its own env variable, update `hooks/session-start` to detect it (matching the existing `CURSOR_PLUGIN_ROOT` / `CLAUDE_PLUGIN_ROOT` branches). If a separate hooks config file is needed, create `hooks-copilot.json`.

- [ ] **Step 2a:** (BLOCKED on Task 1) If Copilot supports remote-fetch install (like Codex's "fetch and follow INSTALL.md" pattern), create `.copilot/INSTALL.md` as the self-bootstrapping entry point.

- [ ] **Step 3:** Add verify/update/uninstall steps

Verify should include:
- skills discovery check
- hook bootstrap check
- sanity prompt for using-superpowers behavior

- [ ] **Step 4:** Add troubleshooting section

Must cover:
- Skill discovery verification commands
- Hook execution verification (is bootstrap context reaching the agent?)
- Common symlink/junction creation errors and permission issues
- Copilot version compatibility notes

---

## Chunk 3: Copilot Mapping

### Task 3: Create `copilot-tools.md` with verified mappings

**Files:**
- Create: `skills/using-superpowers/references/copilot-tools.md`

- [ ] **Step 1:** Add mapping table with only verified tool names
- [ ] **Step 2:** Add explicit subagent support section
- [ ] **Step 3:** If subagents unsupported, define fallback to `executing-plans` (Gemini-style)
- [ ] **Step 4:** Add Windows PowerShell and path guidance
- [ ] **Step 5:** Add "known limitations" section to prevent over-claiming parity
- [ ] **Step 6:** Update `skills/using-superpowers/SKILL.md` platform reference line to include `copilot-tools.md` alongside the existing `codex-tools.md` and Gemini mentions

---

## Chunk 4: Docs Integration

### Task 4: Update top-level docs

**Files:**
- Modify: `README.md`
- Modify: `RELEASE-NOTES.md`

- [ ] **Step 1:** Add Copilot install entry in README platform matrix
- [ ] **Step 2:** Link to `docs/README.copilot.md`
- [ ] **Step 3:** Add release note that states parity-first support and any explicit limitations

---

## Chunk 5: Automated Tests

### Task 5: Add Copilot test harness

**Files:**
- Create: `tests/copilot/run-tests.sh`
- Create: `tests/copilot/test-hook-bootstrap.sh`
- Create: `tests/copilot/test-tool-mapping.sh`
- Create: `tests/copilot/test-install-paths.sh`

- [ ] **Step 1:** Implement runner pattern after `tests/opencode/run-tests.sh`
- [ ] **Step 2:** Add hook-bootstrap test
  - validates hook config file presence/shape
  - validates `hooks/session-start` references `using-superpowers`
- [ ] **Step 3:** Add tool-mapping test
  - validates required sections + fallback notes exist
  - if subagent support is absent, validates fallback to `executing-plans` is documented (matching `gemini-tools.md` pattern)
- [ ] **Step 4:** Add install-path test
  - validates docs include both Unix symlink and Windows junction commands
  - validates clone path convention is documented
  - validates global install path is documented (either global hooks config or explicit note about per-repo limitation)
- [ ] **Step 5:** Ensure scripts are executable and self-contained

---

## Chunk 6: Optional Extension Enhancement (non-blocking)

### Task 6: Add optional Copilot extension support (only after core parity path)

**Files:**
- Optional Create: `.github/extensions/superpowers/extension.mjs`
- Optional Create: `.github/extensions/superpowers/README.md`

**Note:** GitHub Copilot Extensions require GitHub App registration via GitHub Marketplace — this is not a file-drop enhancement. Do not begin this task without confirming the registration path and whether an app manifest/OAuth flow is required.

- [ ] **Step 1:** Keep extension minimal and non-critical
- [ ] **Step 2:** Do not rely on extension startup injection for core parity
- [ ] **Step 3:** Document as optional enhancement in `docs/README.copilot.md`
- [ ] **Step 4:** Clarify in docs that the extension requires a registered GitHub App — it is not automatically active from the repo

---

## Chunk 7: Verification and Regression

### Task 7: Final verification

- [ ] **Step 1:** Run `tests/copilot/run-tests.sh` and verify all tests pass with exit code 0
- [ ] **Step 2:** Run relevant existing fast tests/docs checks
- [ ] **Step 3:** Verify changed file scope matches this plan
- [ ] **Step 4:** Validate wording does not claim unsupported features

---

## Completion Criteria

- Native discovery + hook bootstrap path is documented and test-backed.
- Copilot mapping is verified and includes capability/fallback guidance.
- README/release notes/docs are aligned and honest about limitations.
- Core parity path does not depend on optional extension behavior.
- **All automated tests pass** (exit code 0 from `tests/copilot/run-tests.sh`).
- If subagent support is absent, fallback to `executing-plans` is documented and test-validated.
- Troubleshooting docs cover skill discovery, hook execution, symlink/junction errors, and version compatibility.
- `hooks/session-start` detects Copilot env var (if one exists) and emits the correct output format.
- `skills/using-superpowers/SKILL.md` references `copilot-tools.md` for Copilot users.
- Clone path convention does not conflict with Copilot's own data directories.
- Global install is documented: skill symlink is user-level (works in all repos). If a global hooks config exists, it is documented; if hooks are per-repo only, the limitation is stated and a per-repo hook setup option is provided.

---

## Phase 2: Copilot Workflow Skill

### Design

A single additive skill — `copilot-workflow` — that surfaces GitHub Copilot CLI-specific
workflow enhancements without modifying any existing skills.

## Motivation

GitHub Copilot CLI has three capabilities with no equivalent on other platforms that
Superpowers can meaningfully leverage:

1. **Model selection** — multiple named models with different cost/capability profiles
2. **`store_memory`** — native cross-session persistence built into the tool itself
3. **Plan mode + `exit_plan_mode`** — explicit read-only planning phase with a hard gate to execution

These are purely additive. Existing skills are unchanged.

## Skill

**File:** `skills/copilot-workflow/SKILL.md`

**Description:** `"Use when running on GitHub Copilot CLI — model selection guidance, cross-session memory for workflow state and project preferences, and native plan mode integration"`

**Discovery:** A one-line pointer is added to `skills/using-superpowers/references/copilot-tools.md`:
> "For workflow enhancements (model guidance, memory, plan mode), see the `copilot-workflow` skill."

## Section 1: Model Guidance

Suggestions only — never mandates. The agent surfaces the recommendation and the user switches
via `/model <name>` if they agree.

| Phase | Recommended model | Reason |
|---|---|---|
| `brainstorming` | gpt5.4, opus 4.6 | Creative exploration and design space work |
| `writing-plans` | opus 4.6, sonnet 4.6, codex 5.3 | Methodical task decomposition |
| `executing-plans` subagents — single file / routine | gemini flash, haiku 4.6 | Straightforward edits; saves cost and time |
| `executing-plans` subagents — complex / multi-file | sonnet 4.6, codex 5.3 | More context needed for larger changes |
| Code review | opus 4.6 | Most capable catches the most issues |
| Debugging | opus 4.6, sonnet 4.6 | Structured reasoning through complex logic |

The skill text: *"Consider switching via `/model <name>` before entering this phase. These are
suggestions — use judgment based on task complexity."*

## Section 2: Memory Management

Two namespaces, both scoped to the current project. Keys use the format
`superpowers:<namespace>:<repo-name>` where `repo-name` is derived from the git remote URL or
the directory name as a fallback (e.g., `superpowers:workflow:myproject`).

### Workflow state — `superpowers:workflow`

Transient. Tracks active Superpowers flow progress.

| Trigger | What is stored |
|---|---|
| Brainstorming completes | Design doc path, key architectural decisions |
| Writing-plans completes | Plan file path, total task count |
| Executing-plans checkpoint | Current task number, any blocking issues |
| Flow complete | Clear workflow state |

**At session start:** Check for existing workflow state. If found, surface it:
> "You have an in-progress Superpowers workflow: [plan file], task 3 of 7. Resume?"

### Project preferences — `superpowers:preferences`

Durable. Accumulates as the agent learns conventions in the repo.

What gets stored as it is learned:
- Coding conventions (e.g., "functional style", "no classes")
- Preferred patterns (e.g., "explicit error handling, no silent catches")
- Communication preferences (e.g., "concise responses, no preamble")

**At session start:** Recall silently and apply — no prompt to the user unless something is
ambiguous.

## Section 3: Plan Mode Integration

Copilot CLI's plan mode maps onto the Superpowers planning/execution boundary.

| Superpowers phase | Plan mode state |
|---|---|
| `brainstorming` | Stay in plan mode — research and design only, no file changes |
| `writing-plans` | Stay in plan mode — producing the plan is still planning |
| User approves plan | Call `exit_plan_mode` before proceeding |
| `executing-plans` / `subagent-driven-development` | Out of plan mode, actively making changes |

**Rules for the agent:**
1. If Copilot enters plan mode automatically, lean into it during brainstorming and writing-plans
2. Call `exit_plan_mode` explicitly when the user approves a plan and implementation is about to begin
3. Never call `exit_plan_mode` during brainstorming or writing-plans, even if asked to make a quick edit

Plan mode becomes a natural reinforcement of the existing Superpowers discipline — thinking
phases stay in plan mode, execution phases exit it.

## Out of Scope

- Modifying any existing skill
- `/fleet` (same behavior as `dispatching-parallel-agents` via `task` tool — no additive value)
- `/delegate` cloud agent routing
- Custom agent definitions

### Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `copilot-workflow` skill — a single Copilot CLI-specific skill covering model selection guidance, cross-session memory, and plan mode integration — without modifying any existing skills.

**Architecture:** One new skill file (`skills/copilot-workflow/SKILL.md`), one new test, two small modifications to `copilot-tools.md` and `run-tests.sh`. TDD: test written first, skill written to pass it.

**Tech Stack:** Markdown (skill), Bash (test).

---

## File Map

- **Create:** `skills/copilot-workflow/SKILL.md` — the skill
- **Create:** `tests/copilot/test-copilot-workflow-skill.sh` — validates skill structure and content
- **Modify:** `skills/using-superpowers/references/copilot-tools.md` — add discovery pointer section
- **Modify:** `tests/copilot/run-tests.sh` — register the new test

---

## Task 1: Write the failing test

**Files:**
- Create: `tests/copilot/test-copilot-workflow-skill.sh`

- [ ] **Step 1: Create the test file**

```bash
#!/usr/bin/env bash
# Test: Copilot Workflow Skill
# Verifies that the copilot-workflow skill has correct structure and content
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/copilot-workflow/SKILL.md"

echo "=== Test: Copilot Workflow Skill ==="

# Test 1: skill file exists
echo "Test 1: Checking skills/copilot-workflow/SKILL.md exists..."
if [ -f "$SKILL" ]; then
    echo "  [PASS] SKILL.md exists"
else
    echo "  [FAIL] SKILL.md not found at $SKILL"
    exit 1
fi

# Test 2: frontmatter has correct name
echo "Test 2: Checking frontmatter name..."
if grep -q "^name: copilot-workflow$" "$SKILL"; then
    echo "  [PASS] name: copilot-workflow present"
else
    echo "  [FAIL] name: copilot-workflow missing from frontmatter"
    exit 1
fi

# Test 3: all three features referenced in content
echo "Test 3: Checking skill covers model guidance, memory, and plan mode..."
if grep -qi "model" "$SKILL" && grep -qi "store_memory\|memory" "$SKILL" && grep -qi "exit_plan_mode\|plan mode" "$SKILL"; then
    echo "  [PASS] All three features referenced"
else
    echo "  [FAIL] One or more features missing from skill content"
    exit 1
fi

# Test 4: model guidance table has all required phases
echo "Test 4: Checking model guidance table covers all phases..."
for phase in "brainstorming" "writing-plans" "executing-plans" "review" "ebugging"; do
    if grep -qi "$phase" "$SKILL"; then
        echo "  [PASS] '$phase' phase present"
    else
        echo "  [FAIL] '$phase' phase missing from model guidance"
        exit 1
    fi
done

# Test 5: all specified models are listed
echo "Test 5: Checking all required models are listed..."
for model in "opus 4.6" "sonnet 4.6" "gpt5.4" "gemini flash" "haiku 4.6" "codex 5.3"; do
    if grep -q "$model" "$SKILL"; then
        echo "  [PASS] '$model' present"
    else
        echo "  [FAIL] '$model' missing"
        exit 1
    fi
done

# Test 6: memory section has both namespaces
echo "Test 6: Checking memory section has both namespaces..."
if grep -q "superpowers:workflow" "$SKILL" && grep -q "superpowers:preferences" "$SKILL"; then
    echo "  [PASS] Both memory namespaces present"
else
    echo "  [FAIL] One or both memory namespaces missing"
    exit 1
fi

# Test 7: session start recall instructions present
echo "Test 7: Checking session start recall instructions present..."
if grep -qi "session start\|at session" "$SKILL"; then
    echo "  [PASS] Session start recall instructions present"
else
    echo "  [FAIL] Session start recall instructions missing"
    exit 1
fi

# Test 8: plan mode section has exit_plan_mode
echo "Test 8: Checking plan mode section references exit_plan_mode..."
if grep -q "exit_plan_mode" "$SKILL"; then
    echo "  [PASS] exit_plan_mode present"
else
    echo "  [FAIL] exit_plan_mode missing"
    exit 1
fi

# Test 9: plan mode guard rule is present
echo "Test 9: Checking plan mode guard rule ('Never') is present..."
if grep -qi "never" "$SKILL"; then
    echo "  [PASS] Plan mode guard rule present"
else
    echo "  [FAIL] Plan mode guard rule missing"
    exit 1
fi

# Test 10: copilot-tools.md has pointer to copilot-workflow skill
echo "Test 10: Checking copilot-tools.md has discovery pointer..."
TOOLS="$REPO_ROOT/skills/using-superpowers/references/copilot-tools.md"
if grep -q "copilot-workflow" "$TOOLS"; then
    echo "  [PASS] copilot-tools.md references copilot-workflow skill"
else
    echo "  [FAIL] copilot-tools.md missing pointer to copilot-workflow skill"
    exit 1
fi

echo ""
echo "=== All copilot workflow skill tests passed ==="
```

- [ ] **Step 2: Make the test executable**

```bash
chmod +x tests/copilot/test-copilot-workflow-skill.sh
```

- [ ] **Step 3: Run the test and verify it fails**

```bash
bash tests/copilot/test-copilot-workflow-skill.sh
```

Expected: `[FAIL] SKILL.md not found` — exit code 1.

- [ ] **Step 4: Commit the test**

```bash
git add tests/copilot/test-copilot-workflow-skill.sh
git commit -m "test(copilot): add copilot-workflow skill structure tests (red)"
```

---

## Task 2: Create the skill

**Files:**
- Create: `skills/copilot-workflow/SKILL.md`

- [ ] **Step 1: Create the skill directory and file**

Create `skills/copilot-workflow/SKILL.md` with this exact content:

```markdown
---
name: copilot-workflow
description: Use when running on GitHub Copilot CLI — model selection guidance, cross-session memory for workflow state and project preferences, and native plan mode integration
---

# Copilot CLI Workflow Enhancements

These enhancements are specific to GitHub Copilot CLI and are additive — no existing skills change.

## Model Guidance

Before entering each Superpowers phase, consider switching models with `/model <name>`. These are suggestions; use judgment based on task complexity.

| Phase | Recommended model | Reason |
|---|---|---|
| `brainstorming` | gpt5.4, opus 4.6 | Creative exploration and design space work |
| `writing-plans` | opus 4.6, sonnet 4.6, codex 5.3 | Methodical task decomposition |
| `executing-plans` subagents — single file / routine | gemini flash, haiku 4.6 | Straightforward edits; saves cost and time |
| `executing-plans` subagents — complex / multi-file | sonnet 4.6, codex 5.3 | More context needed for larger changes |
| Code review | opus 4.6 | Most capable catches the most issues |
| Debugging | opus 4.6, sonnet 4.6 | Structured reasoning through complex logic |

## Cross-Session Memory

Use `store_memory` to persist state across sessions. Keys follow the format
`superpowers:<namespace>:<repo-name>` where `repo-name` is the git remote name or working
directory name.

### At Session Start

Before doing anything else, recall both namespaces:

1. Check workflow state (`superpowers:workflow:<repo-name>`):
   - If found: surface it — "You have an in-progress Superpowers workflow: [plan], task N of M. Resume?"
   - If not found: proceed normally

2. Check project preferences (`superpowers:preferences:<repo-name>`):
   - If found: apply silently — no prompt unless something is ambiguous

### Workflow State (`superpowers:workflow:<repo-name>`)

Transient. Store and update as the flow progresses.

**After brainstorming completes:**
```json
{
  "phase": "plan-needed",
  "design_doc": "docs/superpowers/specs/YYYY-MM-DD-topic-design.md",
  "key_decisions": ["decision 1", "decision 2"]
}
```

**After writing-plans completes:**
```json
{
  "phase": "executing",
  "plan": "docs/superpowers/plans/YYYY-MM-DD-feature.md",
  "current_task": 1,
  "total_tasks": 7
}
```

**Update at each task checkpoint during executing-plans:**
```json
{
  "phase": "executing",
  "plan": "docs/superpowers/plans/YYYY-MM-DD-feature.md",
  "current_task": 4,
  "total_tasks": 7
}
```

**Clear when the flow completes** (all tasks done, PR merged, or user discards):
Store `null` for the key.

### Project Preferences (`superpowers:preferences:<repo-name>`)

Durable. Accumulate as you learn conventions — store immediately when learned.
Merge with existing values rather than overwriting.

```json
{
  "coding_style": "functional, no classes",
  "error_handling": "explicit, no silent catches",
  "communication": "concise, no preamble",
  "patterns": ["prefer composition over inheritance", "no magic numbers"]
}
```

## Plan Mode Integration

Copilot CLI's plan mode maps directly onto the Superpowers planning/execution boundary.

| Phase | Plan mode posture |
|---|---|
| `brainstorming` | Stay in plan mode — research and design, no file changes |
| `writing-plans` | Stay in plan mode — producing the plan is still planning |
| User approves plan | Call `exit_plan_mode` before proceeding to execution |
| `executing-plans` / `subagent-driven-development` | Out of plan mode, actively making changes |

**Rules:**
1. If Copilot enters plan mode automatically, lean into it during brainstorming and writing-plans
2. Call `exit_plan_mode` explicitly when the user approves a plan and implementation is about to begin
3. Never call `exit_plan_mode` during brainstorming or writing-plans, even if asked for a "quick edit"
```

- [ ] **Step 2: Run the test and verify it passes**

```bash
bash tests/copilot/test-copilot-workflow-skill.sh
```

Expected: Tests 1–9 pass. Test 10 fails (`copilot-tools.md missing pointer`) — that's correct, pointer comes in Task 3.

- [ ] **Step 3: Commit the skill**

```bash
git add skills/copilot-workflow/SKILL.md
git commit -m "feat(copilot): add copilot-workflow skill (model guidance, memory, plan mode)"
```

---

## Task 3: Add discovery pointer and register test

**Files:**
- Modify: `skills/using-superpowers/references/copilot-tools.md`
- Modify: `tests/copilot/run-tests.sh`

- [ ] **Step 1: Add discovery pointer to copilot-tools.md**

Append this section to the end of `skills/using-superpowers/references/copilot-tools.md`:

```markdown
## Workflow Enhancements

For model selection guidance, cross-session memory (workflow state and project preferences),
and plan mode integration, see the `copilot-workflow` skill.
```

- [ ] **Step 2: Register the new test in run-tests.sh**

In `tests/copilot/run-tests.sh`, update the tests array and help text:

Change:
```bash
tests=(
    "test-hook-bootstrap.sh"
    "test-tool-mapping.sh"
    "test-install-paths.sh"
)
```

To:
```bash
tests=(
    "test-hook-bootstrap.sh"
    "test-tool-mapping.sh"
    "test-install-paths.sh"
    "test-copilot-workflow-skill.sh"
)
```

Also update the help text block from:
```bash
            echo "  test-hook-bootstrap.sh   Verify hook config and session-start script"
            echo "  test-tool-mapping.sh     Verify copilot-tools.md structure and content"
            echo "  test-install-paths.sh    Verify install docs completeness"
```

To:
```bash
            echo "  test-hook-bootstrap.sh          Verify hook config and session-start script"
            echo "  test-tool-mapping.sh            Verify copilot-tools.md structure and content"
            echo "  test-install-paths.sh           Verify install docs completeness"
            echo "  test-copilot-workflow-skill.sh  Verify copilot-workflow skill structure and content"
```

- [ ] **Step 3: Run the full test suite and verify all 4 tests pass**

```bash
bash tests/copilot/run-tests.sh --verbose
```

Expected output:
```
  Passed:  4
  Failed:  0
  Skipped: 0
STATUS: PASSED
```

- [ ] **Step 4: Commit**

```bash
git add skills/using-superpowers/references/copilot-tools.md tests/copilot/run-tests.sh
git commit -m "feat(copilot): add copilot-workflow discovery pointer and register test"
```

---

## Completion Criteria

- `skills/copilot-workflow/SKILL.md` exists with all three sections (model guidance, memory, plan mode)
- All specified models present: gpt5.4, opus 4.6, sonnet 4.6, codex 5.3, gemini flash, haiku 4.6
- Both memory namespaces documented: `superpowers:workflow` and `superpowers:preferences`
- Session start recall instructions present
- `exit_plan_mode` guard rules present including "Never" rule
- `copilot-tools.md` has discovery pointer to `copilot-workflow`
- `tests/copilot/run-tests.sh` runs 4 tests, all passing (exit code 0)

---

## Phase 3: Official Plugin Alignment

### Design

Replace the manual symlink-based Copilot CLI install with the official Copilot CLI plugin
system: a `plugin.json` manifest, `hooks.json`, and `copilot plugin install` distribution.

## Motivation

The initial Copilot CLI support used a manual install (clone repo, symlink skills directory,
configure per-repo hooks). The official Copilot CLI plugin system provides a better path:
`copilot plugin install obra/superpowers` handles everything, skills become globally available
without symlinking, and hooks defined in the plugin fire globally — not just per-repo.

## Approach

Add `plugin.json` at the repo root pointing to the existing `skills/` directory and a new
`hooks.json`. The `hooks.json` replaces `hooks-copilot.json` with a relative path to the
session-start hook. Delete all symlink-based install artifacts and rewrite the install docs.

**Skills are already in the correct format** — no changes needed to any `SKILL.md` file.

The key unverified assumption is that Copilot CLI resolves `./hooks/session-start` relative
to the plugin cache directory when running plugin hooks. The implementation plan includes a
verification task before the rest of the work proceeds. If relative paths do not work, the
fallback is to use whatever env var Copilot CLI exposes for the plugin install directory.

## File Map

| File | Action |
|---|---|
| `plugin.json` | Create — official manifest |
| `hooks.json` | Create — replaces `hooks-copilot.json` with relative hook path |
| `hooks-copilot.json` | Delete |
| `hooks/session-start` | No change |
| `.copilot/INSTALL.md` | Simplify — one-line plugin install command |
| `docs/README.copilot.md` | Rewrite — plugin install only, no symlink/clone/junction |
| `README.md` | Update — Copilot section updated to plugin install command |
| `RELEASE-NOTES.md` | Update — note plugin install as install method |
| `tests/copilot/test-hook-bootstrap.sh` | Update — check `plugin.json` + `hooks.json` |
| `tests/copilot/test-install-paths.sh` | Rewrite — replace symlink checks with plugin checks |
| All `skills/` | No change |

## Component Designs

### plugin.json

```json
{
  "name": "superpowers",
  "description": "Workflow skills and hooks for AI coding agents — structured brainstorming, TDD plans, subagent-driven execution, and cross-platform tool mapping",
  "version": "5.1.0",
  "author": {
    "name": "Jesse Vincent",
    "url": "https://github.com/obra/superpowers"
  },
  "repository": "https://github.com/obra/superpowers",
  "license": "MIT",
  "keywords": ["superpowers", "skills", "workflow", "tdd", "agents"],
  "skills": "skills/",
  "hooks": "hooks.json"
}
```

- `skills: "skills/"` covers all existing skills without enumeration
- `hooks: "hooks.json"` references a separate file rather than inlining hook definitions

### hooks.json

Replaces `hooks-copilot.json`. Identical structure; only the `bash` path changes from
`$HOME/.copilot-superpowers/hooks/session-start` to `./hooks/session-start`:

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [{
      "type": "command",
      "bash": "./hooks/session-start",
      "env": {
        "COPILOT_CLI": "1"
      },
      "timeoutSec": 30
    }]
  }
}
```

`COPILOT_CLI=1` is retained — `hooks/session-start` is shared across Claude Code, Cursor,
and Copilot CLI and uses this env var to select the correct JSON output format.

### docs/README.copilot.md (rewrite)

Structure:

1. **Install** — `copilot plugin install obra/superpowers`
2. **What you get** — skills globally available in all sessions; session-start hook
   auto-injects `using-superpowers` context
3. **Update** — `copilot plugin update superpowers`
4. **Uninstall** — `copilot plugin uninstall superpowers`
5. **Verify** — invoke `/using-superpowers`; confirm context appears at session start

No clone path, no symlink, no Windows junction, no per-repo hook section.

### .copilot/INSTALL.md (simplify)

Reduce to a single instruction for the remote-fetch bootstrap pattern:

```
Run: copilot plugin install obra/superpowers
```

### Test Changes

**test-hook-bootstrap.sh** — existing session-start tests unchanged; `hooks-copilot.json`
checks replaced:

| Removed | Added |
|---|---|
| `hooks-copilot.json` exists | `plugin.json` exists |
| `hooks-copilot.json` has `sessionStart` | `hooks.json` exists |
| `hooks-copilot.json` sets `COPILOT_CLI` env | `hooks.json` has `sessionStart` |
| — | `hooks.json` sets `COPILOT_CLI` env var |
| — | `plugin.json` has `name: superpowers` |
| — | `plugin.json` references `hooks.json` |

**test-install-paths.sh** — symlink/junction/clone checks replaced:

| Removed | Added |
|---|---|
| `ln -s` command present | `copilot plugin install` command present |
| `mklink /J` junction command | `plugin.json` exists at repo root |
| Safe clone path documented | `plugin.json` has correct `name` field |
| Per-repo hooks limitation | Global install documented |

Tests retained: `docs/README.copilot.md` exists, `.copilot/INSTALL.md` exists, root
`README.md` has Copilot section, global install documented.

## Out of Scope

- Changes to any existing `SKILL.md` file
- Adding Superpowers to a public plugin marketplace (that is a separate future step)
- Windows-specific junction or PowerShell install paths (plugin install handles cross-platform)
- Testing the live hook behavior end-to-end (no Copilot CLI instance available in CI)

### Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the manual symlink-based Copilot CLI install with the official plugin system — `plugin.json`, `hooks.json`, and `copilot plugin install obra/superpowers`.

**Architecture:** TDD in two green/red cycles: (1) update hook-bootstrap test → create plugin.json + hooks.json; (2) update install-paths test → rewrite install docs. All existing skill files stay unchanged.

**Tech Stack:** JSON (plugin.json, hooks.json), Markdown (docs), Bash (tests).

---

## File Map

- **Create:** `plugin.json` — official Copilot CLI plugin manifest
- **Create:** `hooks.json` — replaces `hooks-copilot.json` with relative hook path
- **Delete:** `hooks-copilot.json`
- **Modify:** `tests/copilot/test-hook-bootstrap.sh` — check `plugin.json` + `hooks.json` instead of `hooks-copilot.json`
- **Modify:** `tests/copilot/test-install-paths.sh` — replace symlink/junction/clone checks with plugin install checks
- **Modify:** `docs/README.copilot.md` — full rewrite: plugin install only
- **Modify:** `.copilot/INSTALL.md` — simplify to one-line plugin install
- **Modify:** `README.md` — update Copilot section to plugin install command
- **Modify:** `RELEASE-NOTES.md` — update install method description

---

## Task 1: Update hook-bootstrap test (red)

**Files:**
- Modify: `tests/copilot/test-hook-bootstrap.sh`

- [ ] **Step 1: Replace the test file content**

Write `tests/copilot/test-hook-bootstrap.sh` with this exact content:

```bash
#!/usr/bin/env bash
# Test: Hook Bootstrap
# Verifies that hook config and session-start script are correct for Copilot CLI
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Test: Hook Bootstrap ==="

# Test 1: session-start script exists and is executable
echo "Test 1: Checking hooks/session-start exists and is executable..."
if [ -f "$REPO_ROOT/hooks/session-start" ]; then
    echo "  [PASS] hooks/session-start exists"
else
    echo "  [FAIL] hooks/session-start not found"
    exit 1
fi

if [ -x "$REPO_ROOT/hooks/session-start" ]; then
    echo "  [PASS] hooks/session-start is executable"
else
    echo "  [FAIL] hooks/session-start is not executable"
    exit 1
fi

# Test 2: session-start references using-superpowers
echo "Test 2: Checking session-start loads using-superpowers skill..."
if grep -q "using-superpowers" "$REPO_ROOT/hooks/session-start"; then
    echo "  [PASS] session-start references using-superpowers"
else
    echo "  [FAIL] session-start does not reference using-superpowers"
    exit 1
fi

# Test 3: session-start has COPILOT_CLI detection branch
echo "Test 3: Checking session-start has COPILOT_CLI detection branch..."
if grep -q 'COPILOT_CLI' "$REPO_ROOT/hooks/session-start"; then
    echo "  [PASS] session-start has COPILOT_CLI detection"
else
    echo "  [FAIL] session-start is missing COPILOT_CLI detection branch"
    exit 1
fi

# Test 4: COPILOT_CLI branch emits hookSpecificOutput
echo "Test 4: Checking COPILOT_CLI branch emits hookSpecificOutput..."
if grep -A3 'COPILOT_CLI' "$REPO_ROOT/hooks/session-start" | grep -q 'hookSpecificOutput'; then
    echo "  [PASS] COPILOT_CLI branch emits hookSpecificOutput"
else
    echo "  [FAIL] COPILOT_CLI branch does not emit hookSpecificOutput"
    exit 1
fi

# Test 5: plugin.json exists at repo root
echo "Test 5: Checking plugin.json exists at repo root..."
if [ -f "$REPO_ROOT/plugin.json" ]; then
    echo "  [PASS] plugin.json exists"
else
    echo "  [FAIL] plugin.json not found at $REPO_ROOT/plugin.json"
    exit 1
fi

# Test 5b: plugin.json has name: superpowers
echo "Test 5b: Checking plugin.json has name: superpowers..."
if grep -q '"name".*"superpowers"' "$REPO_ROOT/plugin.json"; then
    echo "  [PASS] plugin.json has name: superpowers"
else
    echo "  [FAIL] plugin.json missing name: superpowers"
    exit 1
fi

# Test 5c: plugin.json references hooks.json
echo "Test 5c: Checking plugin.json references hooks.json..."
if grep -q '"hooks".*"hooks\.json"' "$REPO_ROOT/plugin.json"; then
    echo "  [PASS] plugin.json references hooks.json"
else
    echo "  [FAIL] plugin.json does not reference hooks.json"
    exit 1
fi

# Test 6: hooks.json exists at repo root
echo "Test 6: Checking hooks.json exists at repo root..."
if [ -f "$REPO_ROOT/hooks.json" ]; then
    echo "  [PASS] hooks.json exists"
else
    echo "  [FAIL] hooks.json not found at $REPO_ROOT/hooks.json"
    exit 1
fi

# Test 6b: hooks.json has sessionStart hook
echo "Test 6b: Checking hooks.json has sessionStart hook..."
if grep -q '"sessionStart"' "$REPO_ROOT/hooks.json"; then
    echo "  [PASS] hooks.json has sessionStart hook"
else
    echo "  [FAIL] hooks.json is missing sessionStart hook"
    exit 1
fi

# Test 6c: hooks.json sets COPILOT_CLI env var
echo "Test 6c: Checking hooks.json sets COPILOT_CLI env var..."
if grep -q '"COPILOT_CLI"' "$REPO_ROOT/hooks.json"; then
    echo "  [PASS] hooks.json sets COPILOT_CLI env var"
else
    echo "  [FAIL] hooks.json does not set COPILOT_CLI env var"
    exit 1
fi

echo ""
echo "=== All hook bootstrap tests passed ==="
```

- [ ] **Step 2: Run the test and verify it fails on Test 5**

```bash
bash tests/copilot/test-hook-bootstrap.sh
```

Expected: Tests 1–4 pass, then `[FAIL] plugin.json not found` — exit code 1.

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/copilot/test-hook-bootstrap.sh
git commit -m "test(copilot): update hook-bootstrap test for plugin.json + hooks.json (red)"
```

---

## Task 2: Create plugin.json and hooks.json, delete hooks-copilot.json (green)

**Files:**
- Create: `plugin.json`
- Create: `hooks.json`
- Delete: `hooks-copilot.json`

- [ ] **Step 1: Create plugin.json at the repo root**

```json
{
  "name": "superpowers",
  "description": "Workflow skills and hooks for AI coding agents — structured brainstorming, TDD plans, subagent-driven execution, and cross-platform tool mapping",
  "version": "5.1.0",
  "author": {
    "name": "Jesse Vincent",
    "url": "https://github.com/obra/superpowers"
  },
  "repository": "https://github.com/obra/superpowers",
  "license": "MIT",
  "keywords": ["superpowers", "skills", "workflow", "tdd", "agents"],
  "skills": "skills/",
  "hooks": "hooks.json"
}
```

- [ ] **Step 2: Create hooks.json at the repo root**

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "type": "command",
        "bash": "./hooks/session-start",
        "env": {
          "COPILOT_CLI": "1"
        },
        "timeoutSec": 30
      }
    ]
  }
}
```

Note: `./hooks/session-start` is a relative path resolved by Copilot CLI from the plugin
cache directory. `COPILOT_CLI=1` tells `hooks/session-start` which JSON output format to use.

- [ ] **Step 3: Delete hooks-copilot.json**

```bash
git rm hooks-copilot.json
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
bash tests/copilot/test-hook-bootstrap.sh
```

Expected: All tests pass including Tests 5, 5b, 5c, 6, 6b, 6c — exit code 0.

- [ ] **Step 5: Commit**

```bash
git add plugin.json hooks.json
git commit -m "feat(copilot): add plugin.json and hooks.json for official plugin install"
```

---

## Task 3: Update install-paths test (red)

**Files:**
- Modify: `tests/copilot/test-install-paths.sh`

- [ ] **Step 1: Replace the test file content**

Write `tests/copilot/test-install-paths.sh` with this exact content:

```bash
#!/usr/bin/env bash
# Test: Install Paths
# Verifies that install docs use the official copilot plugin install approach
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
README="$REPO_ROOT/docs/README.copilot.md"
INSTALL="$REPO_ROOT/.copilot/INSTALL.md"
PLUGIN="$REPO_ROOT/plugin.json"

echo "=== Test: Install Paths ==="

# Test 1: docs/README.copilot.md exists
echo "Test 1: Checking docs/README.copilot.md exists..."
if [ -f "$README" ]; then
    echo "  [PASS] docs/README.copilot.md exists"
else
    echo "  [FAIL] docs/README.copilot.md not found"
    exit 1
fi

# Test 2: README includes copilot plugin install command
echo "Test 2: Checking README includes 'copilot plugin install'..."
if grep -q "copilot plugin install" "$README"; then
    echo "  [PASS] copilot plugin install command present"
else
    echo "  [FAIL] copilot plugin install command missing"
    exit 1
fi

# Test 3: README includes update command
echo "Test 3: Checking README includes 'copilot plugin update'..."
if grep -q "copilot plugin update" "$README"; then
    echo "  [PASS] copilot plugin update command present"
else
    echo "  [FAIL] copilot plugin update command missing"
    exit 1
fi

# Test 4: README includes uninstall command
echo "Test 4: Checking README includes 'copilot plugin uninstall'..."
if grep -q "copilot plugin uninstall" "$README"; then
    echo "  [PASS] copilot plugin uninstall command present"
else
    echo "  [FAIL] copilot plugin uninstall command missing"
    exit 1
fi

# Test 5: README documents global install
echo "Test 5: Checking README documents global nature of plugin install..."
if grep -qi "global" "$README"; then
    echo "  [PASS] Global install documented"
else
    echo "  [FAIL] Global install not documented"
    exit 1
fi

# Test 6: plugin.json exists at repo root
echo "Test 6: Checking plugin.json exists at repo root..."
if [ -f "$PLUGIN" ]; then
    echo "  [PASS] plugin.json exists"
else
    echo "  [FAIL] plugin.json not found at $PLUGIN"
    exit 1
fi

# Test 7: plugin.json has name: superpowers
echo "Test 7: Checking plugin.json has name: superpowers..."
if grep -q '"name".*"superpowers"' "$PLUGIN"; then
    echo "  [PASS] plugin.json has name: superpowers"
else
    echo "  [FAIL] plugin.json missing name: superpowers"
    exit 1
fi

# Test 8: .copilot/INSTALL.md exists and has plugin install command
echo "Test 8: Checking .copilot/INSTALL.md has copilot plugin install..."
if [ -f "$INSTALL" ] && grep -q "copilot plugin install" "$INSTALL"; then
    echo "  [PASS] .copilot/INSTALL.md has copilot plugin install"
else
    echo "  [FAIL] .copilot/INSTALL.md missing or lacks plugin install command"
    exit 1
fi

# Test 9: README.md (root) has Copilot section
echo "Test 9: Checking root README.md has Copilot section..."
ROOT_README="$REPO_ROOT/README.md"
if grep -qi "copilot" "$ROOT_README"; then
    echo "  [PASS] Root README.md has Copilot section"
else
    echo "  [FAIL] Root README.md is missing Copilot section"
    exit 1
fi

echo ""
echo "=== All install path tests passed ==="
```

- [ ] **Step 2: Run the test and verify it fails on Test 2**

```bash
bash tests/copilot/test-install-paths.sh
```

Expected: Test 1 passes (file still exists), then `[FAIL] copilot plugin install command missing` — exit code 1.

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/copilot/test-install-paths.sh
git commit -m "test(copilot): update install-paths test for plugin install approach (red)"
```

---

## Task 4: Rewrite install docs (green)

**Files:**
- Modify: `docs/README.copilot.md`
- Modify: `.copilot/INSTALL.md`
- Modify: `README.md`
- Modify: `RELEASE-NOTES.md`

- [ ] **Step 1: Rewrite docs/README.copilot.md**

Replace the entire file content with:

```markdown
# Superpowers for GitHub Copilot CLI

Install Superpowers as an official Copilot CLI plugin — skills become globally available in
every session, and the session-start hook auto-injects workflow context.

## Install

```bash
copilot plugin install obra/superpowers
```

This is a **global install** — skills are available in every Copilot session, not just the
current repository.

## What You Get

- All Superpowers skills globally available (brainstorming, writing-plans, executing-plans, etc.)
- Session-start hook automatically injects `using-superpowers` context at the start of every session
- `copilot-workflow` skill for model selection guidance, cross-session memory, and plan mode integration

For the full tool name mapping (Copilot CLI tool names → Superpowers skill equivalents), see
[`skills/using-superpowers/references/copilot-tools.md`](../skills/using-superpowers/references/copilot-tools.md).

## Verify

After install, start a new Copilot session. The `using-superpowers` context should appear
automatically. To verify manually:

```
/using-superpowers
```

Or invoke any skill:

```
/brainstorming
```

## Update

```bash
copilot plugin update superpowers
```

## Uninstall

```bash
copilot plugin uninstall superpowers
```

## Troubleshooting

### Skills not appearing

1. Confirm install: `copilot plugin list`
2. Restart Copilot CLI — plugins are loaded at startup
3. Reinstall: `copilot plugin uninstall superpowers && copilot plugin install obra/superpowers`

### Bootstrap context not appearing

If the session-start hook fires but `using-superpowers` context is missing, the
`hookSpecificOutput.additionalContext` field may not be supported in your Copilot CLI version.
Workaround: start your session with `/using-superpowers` in your first prompt.

## Getting Help

- Report issues: https://github.com/obra/superpowers/issues
- Main documentation: https://github.com/obra/superpowers
```

- [ ] **Step 2: Simplify .copilot/INSTALL.md**

Replace the entire file content with:

```markdown
# Install Superpowers for GitHub Copilot CLI

Run:

```bash
copilot plugin install obra/superpowers
```

This is a global install — skills are available in every Copilot session.

After install, start a new session. The `using-superpowers` context should appear automatically.

Full documentation: https://github.com/obra/superpowers/blob/main/docs/README.copilot.md
```

- [ ] **Step 3: Update the Copilot section in README.md**

In `README.md`, find and replace this block (lines ~97–113):

```markdown
### GitHub Copilot CLI

Tell Copilot CLI:

```
Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.copilot/INSTALL.md
```

Or manually:

```bash
git clone https://github.com/obra/superpowers.git ~/.copilot-superpowers
mkdir -p ~/.agents/skills
ln -s ~/.copilot-superpowers/skills ~/.agents/skills/superpowers
```

**Detailed docs:** [docs/README.copilot.md](docs/README.copilot.md)
```

Replace with:

```markdown
### GitHub Copilot CLI

```bash
copilot plugin install obra/superpowers
```

**Detailed docs:** [docs/README.copilot.md](docs/README.copilot.md)
```

- [ ] **Step 4: Update RELEASE-NOTES.md**

In `RELEASE-NOTES.md`, find the v5.1.0 (Unreleased) section and replace the entire
`### GitHub Copilot CLI Support` block with:

```markdown
### GitHub Copilot CLI Support

Superpowers now supports GitHub Copilot CLI via the official plugin system.

- **Plugin install**: `copilot plugin install obra/superpowers` — global install, skills available in every session
- **Session bootstrap**: `hooks.json` wires `hooks/session-start` to inject `using-superpowers` context at session start
- **Full subagent support**: Copilot CLI's `task` tool maps 1:1 to Claude Code's `Task` tool; `subagent-driven-development` and `dispatching-parallel-agents` work natively
- **Tool mapping**: `skills/using-superpowers/references/copilot-tools.md` documents all Copilot CLI tool equivalents
- **Copilot-specific workflow**: `copilot-workflow` skill adds model selection guidance, cross-session memory, and plan mode integration

Install: `copilot plugin install obra/superpowers`. See [docs/README.copilot.md](docs/README.copilot.md).
```

- [ ] **Step 5: Run the install-paths test and verify it passes**

```bash
bash tests/copilot/test-install-paths.sh
```

Expected: All 9 tests pass — exit code 0.

- [ ] **Step 6: Run the full test suite**

```bash
bash tests/copilot/run-tests.sh --verbose
```

Expected:
```
  Passed:  4
  Failed:  0
STATUS: PASSED
```

- [ ] **Step 7: Commit**

```bash
git add docs/README.copilot.md .copilot/INSTALL.md README.md RELEASE-NOTES.md
git commit -m "feat(copilot): rewrite install docs for official plugin install"
```

---

## Completion Criteria

- `plugin.json` exists at repo root with `name: superpowers`, `skills: "skills/"`, `hooks: "hooks.json"`
- `hooks.json` exists at repo root with `sessionStart` hook using `./hooks/session-start` and `COPILOT_CLI=1`
- `hooks-copilot.json` is deleted
- `docs/README.copilot.md` documents `copilot plugin install`, update, and uninstall — no symlink content
- `.copilot/INSTALL.md` contains only `copilot plugin install obra/superpowers`
- `README.md` Copilot section shows `copilot plugin install obra/superpowers`
- All 4 tests pass: `bash tests/copilot/run-tests.sh` exits 0

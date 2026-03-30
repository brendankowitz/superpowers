# Copilot CLI Support Implementation Plan (Parity-First)

> **For agentic workers:** REQUIRED: use `superpowers:subagent-driven-development` (preferred) or `superpowers:executing-plans`. Use checkbox steps (`- [ ]`) for task tracking.

**Goal:** Deliver Copilot CLI support as close as possible to Claude Code behavior via native skill discovery and hook-based bootstrap, with verified mappings and tests.

**Architecture:** Primary path is clone + native skills symlink/junction + session-start hook bootstrap. Optional extension support may be added, but parity does not depend on it.

**Tech Stack:** Markdown docs, shell hooks, bash-based tests, optional JS ESM extension.

**Spec:** `docs/superpowers/specs/2026-03-30-copilot-cli-support-design.md`

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
- [ ] **Step 5:** Add “known limitations” section to prevent over-claiming parity
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


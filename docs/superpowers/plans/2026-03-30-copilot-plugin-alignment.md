# Copilot CLI Plugin Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the manual symlink-based Copilot CLI install with the official plugin system — `plugin.json`, `hooks.json`, and `copilot plugin install obra/superpowers`.

**Architecture:** TDD in two green/red cycles: (1) update hook-bootstrap test → create plugin.json + hooks.json; (2) update install-paths test → rewrite install docs. All existing skill files stay unchanged.

**Tech Stack:** JSON (plugin.json, hooks.json), Markdown (docs), Bash (tests).

**Spec:** `docs/superpowers/specs/2026-03-30-copilot-plugin-alignment-design.md`

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

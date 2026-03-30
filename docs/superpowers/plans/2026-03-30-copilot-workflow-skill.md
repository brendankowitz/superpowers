# Copilot Workflow Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `copilot-workflow` skill — a single Copilot CLI-specific skill covering model selection guidance, cross-session memory, and plan mode integration — without modifying any existing skills.

**Architecture:** One new skill file (`skills/copilot-workflow/SKILL.md`), one new test, two small modifications to `copilot-tools.md` and `run-tests.sh`. TDD: test written first, skill written to pass it.

**Tech Stack:** Markdown (skill), Bash (test).

**Spec:** `docs/superpowers/specs/2026-03-30-copilot-workflow-skill-design.md`

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

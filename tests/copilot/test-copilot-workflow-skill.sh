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

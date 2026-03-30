#!/usr/bin/env bash
# Test: Tool Mapping
# Verifies that copilot-tools.md has the required sections, mappings, and fallback notes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MAPPING="$REPO_ROOT/skills/using-superpowers/references/copilot-tools.md"

echo "=== Test: Tool Mapping ==="

# Test 1: copilot-tools.md exists
echo "Test 1: Checking copilot-tools.md exists..."
if [ -f "$MAPPING" ]; then
    echo "  [PASS] copilot-tools.md exists"
else
    echo "  [FAIL] copilot-tools.md not found at $MAPPING"
    exit 1
fi

# Test 2: Has mapping table with core tool names
echo "Test 2: Checking mapping table has core tools..."
for tool in "view" "create" "edit" "bash" "grep" "glob" "update_todo" "web_fetch"; do
    if grep -q "$tool" "$MAPPING"; then
        echo "  [PASS] '$tool' mapping present"
    else
        echo "  [FAIL] '$tool' mapping missing"
        exit 1
    fi
done

# Test 3: Has subagent dispatch section
echo "Test 3: Checking subagent dispatch section exists..."
if grep -qi "subagent" "$MAPPING"; then
    echo "  [PASS] Subagent dispatch section present"
else
    echo "  [FAIL] Subagent dispatch section missing"
    exit 1
fi

# Test 4: task tool is documented for subagent dispatch
echo "Test 4: Checking 'task' tool is documented for subagent dispatch..."
if grep -q '\btask\b' "$MAPPING"; then
    echo "  [PASS] 'task' tool documented"
else
    echo "  [FAIL] 'task' tool not documented"
    exit 1
fi

# Test 5: Has known limitations section
echo "Test 5: Checking known limitations section exists..."
if grep -qi "known limitations\|limitation" "$MAPPING"; then
    echo "  [PASS] Known limitations section present"
else
    echo "  [FAIL] Known limitations section missing"
    exit 1
fi

# Test 6: Limitation about per-repo hooks is documented
echo "Test 6: Checking per-repo hooks limitation is documented..."
if grep -qi "per.repo\|per repo" "$MAPPING"; then
    echo "  [PASS] Per-repo hooks limitation documented"
else
    echo "  [FAIL] Per-repo hooks limitation not documented"
    exit 1
fi

# Test 7: Has Windows path guidance
echo "Test 7: Checking Windows path guidance exists..."
if grep -qi "windows\|powershell\|mklink\|junction" "$MAPPING"; then
    echo "  [PASS] Windows path guidance present"
else
    echo "  [FAIL] Windows path guidance missing"
    exit 1
fi

# Test 8: SKILL.md references copilot-tools.md
echo "Test 8: Checking SKILL.md references copilot-tools.md..."
SKILL_MD="$REPO_ROOT/skills/using-superpowers/SKILL.md"
if grep -q "copilot-tools.md" "$SKILL_MD"; then
    echo "  [PASS] SKILL.md references copilot-tools.md"
else
    echo "  [FAIL] SKILL.md does not reference copilot-tools.md"
    exit 1
fi

echo ""
echo "=== All tool mapping tests passed ==="

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

# Test 5: hooks-copilot.json exists and has correct structure
echo "Test 5: Checking hooks-copilot.json exists..."
if [ -f "$REPO_ROOT/hooks-copilot.json" ]; then
    echo "  [PASS] hooks-copilot.json exists"
else
    echo "  [FAIL] hooks-copilot.json not found"
    exit 1
fi

echo "Test 5b: Checking hooks-copilot.json has sessionStart hook..."
if grep -q '"sessionStart"' "$REPO_ROOT/hooks-copilot.json"; then
    echo "  [PASS] hooks-copilot.json has sessionStart hook"
else
    echo "  [FAIL] hooks-copilot.json is missing sessionStart hook"
    exit 1
fi

echo "Test 5c: Checking hooks-copilot.json sets COPILOT_CLI env var..."
if grep -q '"COPILOT_CLI"' "$REPO_ROOT/hooks-copilot.json"; then
    echo "  [PASS] hooks-copilot.json sets COPILOT_CLI env var"
else
    echo "  [FAIL] hooks-copilot.json does not set COPILOT_CLI env var"
    exit 1
fi

echo ""
echo "=== All hook bootstrap tests passed ==="

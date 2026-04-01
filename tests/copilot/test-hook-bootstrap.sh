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

# Test 4: Copilot CLI path emits SDK-standard additionalContext (not hookSpecificOutput)
echo "Test 4: Checking session-start emits additionalContext for Copilot CLI..."
if grep -q 'additionalContext' "$REPO_ROOT/hooks/session-start"; then
    echo "  [PASS] session-start emits additionalContext"
else
    echo "  [FAIL] session-start does not emit additionalContext"
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

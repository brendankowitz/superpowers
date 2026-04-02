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

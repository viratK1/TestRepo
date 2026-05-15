#!/bin/bash

# Version Bump Enforcement Script
# Validates that at least one version is incremented in PR to develop branch
# Exit codes: 0 = valid, 1 = invalid/missing bump

set -e

BASE_SHA="${1:?ERROR: BASE_SHA required as first argument}"

UI_VERSION_FILE="app_ui/sciton-UI/qml/components/Style.qml"
CONTROLLER_VERSION_FILE="app_controller/Sciton/Inc/version.h"

echo "================================================"
echo "Checking version bump enforcement..."
echo "================================================"
echo "Base SHA: $BASE_SHA"
echo "Current SHA: $GITHUB_SHA"
echo ""

# Get list of changed files
CHANGED_FILES=$(git diff --name-only "$BASE_SHA" HEAD)

UI_CHANGED=false
CONTROLLER_CHANGED=false

if echo "$CHANGED_FILES" | grep -q "^$UI_VERSION_FILE$"; then
  UI_CHANGED=true
fi

if echo "$CHANGED_FILES" | grep -q "^$CONTROLLER_VERSION_FILE$"; then
  CONTROLLER_CHANGED=true
fi

echo "Files Changed:"
echo "  UI Version: $UI_CHANGED"
echo "  Controller Version: $CONTROLLER_CHANGED"
echo ""

# Extract old and new versions
if [ "$UI_CHANGED" = true ]; then
  OLD_UI=$(git show "$BASE_SHA:$UI_VERSION_FILE" | grep -oP 'build_ver:\s*"\K[^"]+')
  NEW_UI=$(git show HEAD:"$UI_VERSION_FILE" | grep -oP 'build_ver:\s*"\K[^"]+')
  echo "UI Version Change: $OLD_UI → $NEW_UI"
  
  # Extract numeric parts (first 4 digits)
  OLD_UI_NUM=$(echo "$OLD_UI" | grep -oP '^\d+')
  NEW_UI_NUM=$(echo "$NEW_UI" | grep -oP '^\d+')
  
  if [ -z "$OLD_UI_NUM" ] || [ -z "$NEW_UI_NUM" ]; then
    echo "[ERROR] Could not parse UI version format"
    exit 1
  fi
  
  if [ "$NEW_UI_NUM" -gt "$OLD_UI_NUM" ]; then
    echo "[OK] UI version incremented correctly"
    UI_VALID=true
  else
    echo "[ERROR] UI version numeric part must increase ($OLD_UI_NUM -> $NEW_UI_NUM)"
    UI_VALID=false
  fi
else
  UI_VALID=false
fi

if [ "$CONTROLLER_CHANGED" = true ]; then
  OLD_CONTROLLER=$(git show "$BASE_SHA:$CONTROLLER_VERSION_FILE" | grep -oP 'FW_VERSION\s*"\K[^"]+')
  NEW_CONTROLLER=$(git show HEAD:"$CONTROLLER_VERSION_FILE" | grep -oP 'FW_VERSION\s*"\K[^"]+')
  echo "Controller Version Change: $OLD_CONTROLLER → $NEW_CONTROLLER"
  
  # Convert versions to comparable format
  # Handle both semantic (1.2.3) and simple (306) formats
  OLD_CONTROLLER_NUM=$(echo "$OLD_CONTROLLER" | sed 's/\.//g')
  NEW_CONTROLLER_NUM=$(echo "$NEW_CONTROLLER" | sed 's/\.//g')
  
  if [ "$NEW_CONTROLLER_NUM" -gt "$OLD_CONTROLLER_NUM" ]; then
    echo "[OK] Controller version incremented correctly"
    CONTROLLER_VALID=true
  else
    echo "[ERROR] Controller version must increase ($OLD_CONTROLLER -> $NEW_CONTROLLER)"
    CONTROLLER_VALID=false
  fi
else
  CONTROLLER_VALID=false
fi

echo ""
echo "================================================"
echo "Validation Result:"
echo "================================================"

# At least one version must be valid
if [ "$UI_VALID" = true ] || [ "$CONTROLLER_VALID" = true ]; then
  echo "[PASS] At least one version was incremented"
  echo ""
  exit 0
else
  echo "[FAIL] No valid version bump found"
  echo ""
  echo "Requirements:"
  echo "  - UI Version: Increment numeric part (format: NNNN[A-Z])"
  echo "    Example: 0193C -> 0194C"
  echo "  - Controller Version: Increment version number"
  echo "    Example: 306 -> 307"
  echo ""
  echo "At least ONE must be incremented for merge approval."
  echo ""
  exit 1
fi

#!/bin/bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "NIXLPER COMMAND PALETTE DEBUGGING"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "1. Environment Check"
echo "   NIXLPER_INSTALL_DIR: ${NIXLPER_INSTALL_DIR:-NOT SET}"
echo "   Shell: $SHELL"
echo "   Interactive: $-"
echo ""

echo "2. Function Availability"
echo "   _build_command_registry: $(type -t _build_command_registry 2>/dev/null || echo 'NOT FOUND')"
echo "   _format_command_for_display: $(type -t _format_command_for_display 2>/dev/null || echo 'NOT FOUND')"
echo "   find_action: $(type -t find_action 2>/dev/null || echo 'NOT FOUND')"
echo ""

echo "3. Alias Check"
echo "   fa alias: $(alias fa 2>/dev/null || echo 'NOT FOUND')"
echo ""

echo "4. File Locations"
if [[ -n "${NIXLPER_INSTALL_DIR}" ]]; then
  echo "   Command palette file exists: $(test -f "${NIXLPER_INSTALL_DIR}/src/main/bash/functions_command_palette.sh" && echo 'YES' || echo 'NO')"
  echo "   nixlper.sh exists: $(test -f "${NIXLPER_INSTALL_DIR}/src/main/bash/nixlper.sh" && echo 'YES' || echo 'NO')"

  echo ""
  echo "5. Registry Content Test"
  if type -t _build_command_registry &>/dev/null; then
    echo "   Total commands in registry: $(_build_command_registry 2>/dev/null | wc -l)"
    echo ""
    echo "   First 10 commands in formatted view:"
    _build_command_registry 2>/dev/null | while read line; do
      _format_command_for_display "$line" 2>/dev/null
    done | head -10
    echo ""
    echo "   Commands with [alias] indicator:"
    _build_command_registry 2>/dev/null | while read line; do
      _format_command_for_display "$line" 2>/dev/null
    done | grep "\[alias\]" | wc -l
  fi
else
  echo "   Cannot check - NIXLPER_INSTALL_DIR not set"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "DIAGNOSTIC SUMMARY:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ -z "${NIXLPER_INSTALL_DIR}" ]]; then
  echo "❌ ISSUE: NIXLPER_INSTALL_DIR not set"
  echo "   FIX: Run 'source ~/.bashrc' or restart your terminal"
  echo ""
fi

if ! type -t _build_command_registry &>/dev/null; then
  echo "❌ ISSUE: Command palette functions not loaded"
  echo "   FIX: Run 'source ~/.bashrc' to reload all functions"
  echo ""
fi

if ! type -t find_action &>/dev/null; then
  echo "❌ ISSUE: find_action function not available"
  echo "   FIX: Run 'source ~/.bashrc'"
  echo ""
fi

if type -t _build_command_registry &>/dev/null; then
  TOTAL=$(_build_command_registry 2>/dev/null | wc -l)
  if [[ $TOTAL -lt 20 ]]; then
    echo "⚠️  WARNING: Only $TOTAL commands in registry (expected 25)"
    echo "   This might be normal if you only see 4 items in the palette"
    echo ""
  else
    echo "✅ SUCCESS: Registry has $TOTAL commands"
    echo ""
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "NEXT STEPS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Run: source ~/.bashrc"
echo "2. Run this debug script again: bash debug_palette.sh"
echo "3. If still showing 4 items, share the output with Claude"
echo ""

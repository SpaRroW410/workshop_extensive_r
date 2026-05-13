#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# render-all-profiles.sh
# Run from your workshop ROOT directory:  bash render-all-profiles.sh
# ═══════════════════════════════════════════════════════════════

set -e  # stop on any error

ROOT_DIR="$(pwd)"
CONFIG="$ROOT_DIR/config.json"

# ── Confirm running from correct directory ───────────────────
if [ ! -f "_quarto.yml" ]; then
  echo "❌ ERROR: _quarto.yml not found."
  echo "   Run this script from your workshop root directory."
  exit 1
fi

if [ ! -f "config.json" ]; then
  echo "❌ ERROR: config.json not found in root."
  exit 1
fi

# ── Helper: clean output folder before render ────────────────
clean_and_render() {
  local label="$1"
  local profile_flag="$2"
  local out_dir="$3"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Rendering: $label"
  echo "  Output:    $out_dir"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Remove existing output folder so stale files don't persist
  if [ -d "$out_dir" ]; then
    echo "  🗑️  Removing existing $out_dir ..."
    rm -rf "$out_dir"
  fi

  # Render
  if [ -z "$profile_flag" ]; then
    quarto render
  else
    quarto render --profile "$profile_flag"
  fi

  # Copy config.json into output folder for local preview
  if [ -d "$out_dir" ]; then
    cp "$CONFIG" "$out_dir/config.json"
    echo "  ✅ config.json copied to $out_dir"
  else
    echo "  ⚠️  WARNING: $out_dir was not created. Check for render errors."
  fi
}

# ── Render all profiles ───────────────────────────────────────
clean_and_render "Basic (default)"          ""                  "docs/basic"
clean_and_render "Moderate"                 "moderate"          "docs/moderate"
clean_and_render "Advanced"                 "advanced"          "docs/advanced"
clean_and_render "DataViz — Foundations"    "dataviz-base"      "docs/dataviz-base"
clean_and_render "DataViz — Complete"       "dataviz-complete"  "docs/dataviz-complete"

# ── Done ─────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "  ✅ All profiles rendered successfully"
echo "  📁 Output: docs/"
echo "════════════════════════════════════════"
echo ""
echo "  docs/basic/"
echo "  docs/moderate/"
echo "  docs/advanced/"
echo "  docs/dataviz-base/"
echo "  docs/dataviz-complete/"
echo ""
echo "  config.json copied to all profile folders for local preview."
echo "  GitHub Pages will use config.json from repo root."
echo "════════════════════════════════════════"

#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# render-all-profiles.sh
# Run from your workshop ROOT directory:
#   bash render-all-profiles.sh
# ═══════════════════════════════════════════════════════════════

set -e  # stop on any error

# Keep the terminal window open if an error occurs (helpful for Windows)
trap 'echo -e "\n❌ ERROR: Script failed at line $LINENO."; read -p "Press [Enter] to exit..."' ERR

ROOT_DIR="$(pwd)"
CONFIG="$ROOT_DIR/config.json"

# ── Guard: must run from project root ────────────────────────
if [ ! -f "_quarto.yml" ]; then
  echo "❌ ERROR: _quarto.yml not found."
  echo "   Run this script from your workshop root directory."
  exit 1
fi
if [ ! -f "config.json" ]; then
  echo "❌ ERROR: config.json not found in root."
  exit 1
fi

# ── Helper ────────────────────────────────────────────────────
render_profile() {
  local label="$1"
  local profile="$2"
  local out_dir="$3"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Rendering : $label"
  echo "  Profile   : --profile $profile"
  echo "  Output    : $out_dir"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Wipe stale output so no old files linger
  if [ -d "$out_dir" ]; then
    echo "  🗑️  Removing existing $out_dir ..."
    rm -rf "$out_dir"
  fi

  quarto render --profile "$profile"

  # Copy config.json so local preview works
  if [ -d "$out_dir" ]; then
    cp "$CONFIG" "$out_dir/config.json"
    echo "  ✅ config.json copied → $out_dir"
  else
    echo "  ⚠️  WARNING: $out_dir was not created — check for render errors."
  fi
}

# ── Step 1: Render landing page (index.qmd → docs/) ──────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Rendering : Landing page (index.qmd)"
echo "  Output    : docs/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Explicitly create the docs folder in case it was deleted
mkdir -p docs

# Render only index.qmd
quarto render index.qmd --output-dir docs --to html
cp config.json docs/config.json
echo "  ✅ index.html + config.json → docs/"

# ── Step 2: Render all profile sites ─────────────────────────
render_profile "Basic"                      "basic"           "docs/basic"
render_profile "Moderate"                   "moderate"        "docs/moderate"
render_profile "Advanced"                   "advanced"        "docs/advanced"
render_profile "DataViz — Foundations"      "dataviz-base"    "docs/dataviz-base"
render_profile "DataViz — Complete"         "dataviz-complete" "docs/dataviz-complete"

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "  ✅ All profiles rendered successfully"
echo "════════════════════════════════════════"
echo ""
echo "  docs/index.html          ← landing page"
echo "  docs/config.json         ← key config"
echo "  docs/basic/              ← Basic track"
echo "  docs/moderate/           ← Moderate track"
echo "  docs/advanced/           ← Advanced track"
echo "  docs/dataviz-base/       ← DataViz Foundations"
echo "  docs/dataviz-complete/   ← DataViz Complete"
echo ""
echo "  Local preview:"
echo "    cd docs && python -m http.server 8080"
echo "    Open: http://localhost:8080"
echo "════════════════════════════════════════"
echo ""

# Pause so the terminal doesn't close instantly
read -p "Press [Enter] to exit..."
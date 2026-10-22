#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# render-all-profiles.sh
# Run from your workshop ROOT directory:
#   bash render-all-profiles.sh           incremental: only changed .qmd files
#   bash render-all-profiles.sh --force   wipe output, re-render everything
#
# Each profile keeps a docs/<profile>/.render-stamp file. A .qmd is
# re-rendered only if it is newer than the stamp (or its html is missing).
# If shared config (_quarto*.yml, config.json, navigation.*, assets/)
# changed, that profile is fully re-rendered since every page is affected.
# ═══════════════════════════════════════════════════════════════

set -e  # stop on any error

# Keep the terminal window open if an error occurs (helpful for Windows)
trap 'echo -e "\n❌ ERROR: Script failed at line $LINENO."; read -p "Press [Enter] to exit..."' ERR

ROOT_DIR="$(pwd)"
CONFIG="$ROOT_DIR/config.json"

FORCE=0
if [ "${1:-}" = "--force" ]; then
  FORCE=1
  rm -rf _freeze   # also discard cached R results so code re-executes
fi

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

# ── Local machine overrides (e.g. QUARTO_R / R_LIBS_USER pointing at an
# ARM64 R install) — optional, gitignored, only present if you've set one
# up on this machine. Sourced (not just read by Quarto) so the values
# truly override anything already inherited from the shell/session.
if [ -f "_environment" ]; then
  while IFS='=' read -r key value; do
    case "$key" in ""|\#*) continue ;; esac
    export "$key=$value"
  done < "_environment"
fi


# ── Regenerate profile files from curriculum.yml (fails fast on broken links) ──
"${QUARTO_R:-Rscript}" scripts/build_profiles.R
# ── Helpers ───────────────────────────────────────────────────
# True if a project-wide input (affects every page) is newer than the stamp
global_changed() {
  local profile="$1" stamp="$2" f
  for f in _quarto.yml "_quarto-$profile.yml" config.json navigation.json navigation.yml; do
    if [ -f "$f" ] && [ "$f" -nt "$stamp" ]; then return 0; fi
  done
  if [ -n "$(find assets -type f -newer "$stamp" -print -quit 2>/dev/null)" ]; then
    return 0
  fi
  return 1
}

# .qmd inputs of a profile as project-relative POSIX paths
profile_inputs() {
  local root
  root="$(pwd -W 2>/dev/null || pwd)"
  quarto inspect --profile "$1" 2>/dev/null \
    | grep -o '"[A-Za-z]:\\\\[^"]*\.qmd"' \
    | sed -e 's/^"//' -e 's/"$//' -e 's#\\\\#/#g' \
    | sed -e "s#^$root/##" \
    | sort -u
}

render_profile() {
  local label="$1"
  local profile="$2"
  local out_dir="$3"
  local stamp="$out_dir/.render-stamp"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Rendering : $label"
  echo "  Profile   : --profile $profile"
  echo "  Output    : $out_dir"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local full=0
  if [ "$FORCE" = 1 ] || [ ! -f "$stamp" ] || global_changed "$profile" "$stamp"; then
    full=1
  fi

  local stale=() f html
  if [ "$full" = 0 ]; then
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      html="$out_dir/${f%.qmd}.html"
      if [ ! -f "$html" ] || [ "$f" -nt "$stamp" ]; then
        stale+=("$f")
      fi
    done < <(profile_inputs "$profile")

    if [ ${#stale[@]} -eq 0 ]; then
      echo "  ⏭️  No changed .qmd files — skipped."
      return 0
    fi
  fi

  # Stamp BEFORE rendering so edits made mid-render are caught next run
  local new_stamp
  new_stamp="$(mktemp)"

  if [ "$full" = 1 ]; then
    echo "  🔄 Full render (first run, --force, or shared config/assets changed)"
    if [ -d "$out_dir" ]; then
      echo "  🗑️  Removing existing $out_dir ..."
      rm -rf "$out_dir"
    fi
    quarto render --profile "$profile"
  else
    echo "  🔄 Re-rendering ${#stale[@]} changed file(s):"
    for f in "${stale[@]}"; do
      echo "     • $f"
      quarto render "$f" --profile "$profile"
    done
  fi

  # Copy config.json so local preview works
  if [ -d "$out_dir" ]; then
    cp "$CONFIG" "$out_dir/config.json"
    mv "$new_stamp" "$stamp"
    echo "  ✅ config.json copied → $out_dir"
  else
    rm -f "$new_stamp"
    echo "  ⚠️  WARNING: $out_dir was not created — check for render errors."
  fi
}

# ── Step 1: Render landing page (index.qmd → docs/) ──────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Rendering : Landing page (index.qmd)"
echo "  Output    : docs/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p docs
if [ "$FORCE" = 1 ] || [ ! -f docs/index.html ] || [ index.qmd -nt docs/index.html ]; then
  quarto render index.qmd --output-dir docs --to html
  echo "  ✅ index.html rendered → docs/"
else
  echo "  ⏭️  index.qmd unchanged — skipped."
fi
cp config.json docs/config.json

# ── Step 2: Render all profile sites ─────────────────────────
render_profile "Basic"                      "basic"           "docs/basic"
render_profile "Moderate"                   "moderate"        "docs/moderate"
render_profile "Advanced"                   "advanced"        "docs/advanced"
render_profile "DataViz — Foundations"      "dataviz-base"    "docs/dataviz-base"
render_profile "DataViz — Complete"         "dataviz-complete" "docs/dataviz-complete"
render_profile "Regression"                 "regression"       "docs/regression"
render_profile "Dungeons & Dataframes"      "dungeons"         "docs/dungeons"

# ── Old quest URLs (it lived inside the Regression track) → the game's own site ──
mkdir -p docs/regression/regression-quest
for f in docs/dungeons/dungeons/*.html; do
  [ -f "$f" ] || continue
  b="$(basename "$f")"
  printf '<!doctype html><meta charset="utf-8"><title>Moved</title><meta http-equiv="refresh" content="0; url=../../dungeons/dungeons/%s"><link rel="canonical" href="../../dungeons/dungeons/%s"><p>Dungeons &amp; Dataframes has moved: <a href="../../dungeons/dungeons/%s">continue</a>.</p>\n' "$b" "$b" "$b" > "docs/regression/regression-quest/$b"
done

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
echo "  docs/regression/         ← Regression"
echo "  docs/dungeons/           ← Dungeons & Dataframes (the game)"
echo ""
echo "  Local preview:"
echo "    cd docs && python -m http.server 8080"
echo "    Open: http://localhost:8080"
echo "════════════════════════════════════════"
echo ""

# Pause so the terminal doesn't close instantly
read -p "Press [Enter] to exit..."

#!/usr/bin/env bash
# Publish the rendered site to Cloudflare Pages: a deliberate, one-command release (LAUNCH_PLAN.md §1).
#
#   bash cloud/deploy.sh             publish to production
#   bash cloud/deploy.sh --preview   publish to a preview address only (production is untouched)
#
# Needs: CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID in the environment (or `npx wrangler login`),
# a rendered docs/ (bash render-all-profiles.sh), and `npm ci` run once in cloud/.
set -euo pipefail
cd "$(dirname "$0")"

BRANCH=main
if [ "${1:-}" = "--preview" ]; then BRANCH=preview; fi

if [ -n "$(git status --porcelain -- ../docs)" ]; then
  echo "docs/ has uncommitted changes. Commit them first, so the live site always matches a commit."
  exit 1
fi

if grep -q '00000000-0000-0000-0000-000000000000' wrangler.toml; then
  echo "wrangler.toml still has the placeholder database_id. Run: npx wrangler d1 create medstats"
  exit 1
fi

node stage.mjs
npx wrangler d1 migrations apply medstats --remote
npx wrangler pages deploy .deploy --project-name medstats --branch "$BRANCH" \
  --commit-hash "$(git rev-parse HEAD)" --commit-message "$(git log -1 --format=%s)"

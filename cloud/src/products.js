// Which published paths belong to which paid product, and which stay free.
//
// This file is the single source for two things:
//   1. the gate in functions/_middleware.js (who may see a page), and
//   2. _routes.json, written by stage.mjs, which tells Cloudflare to run Functions ONLY on
//      paid paths and /api. Free paths are excluded there, so they are served as plain static
//      files and keep working even if the daily Functions quota runs out (LAUNCH_PLAN.md §2).
//
// Rules use Cloudflare's _routes.json syntax, so the gate and Cloudflare read them the same way:
//   "/a/b"   exact path
//   "/a/b*"  every path that starts with "/a/b"
// Only a trailing "*" is used: Cloudflare documents nothing else.
// Pages redirects "/x/page.html" to "/x/page", so a page rule is written "/x/page*" to cover both.
// Cloudflare allows 100 include + exclude rules in total; tests/products.test.js checks the count.
//
// STATUS: the product list and the free tier are the PROPOSAL in LAUNCH_PLAN.md §5.
// They must be confirmed before launch (plan, phase 2: "product list and free tier confirmed").

/** Products a user can hold. `all-access` holds every other product. */
export const PRODUCTS = {
  moderate: 'Moderate track',
  regression: 'Regression track and workshop',
  statistics: 'Statistical Analysis track and workshop',
  gis: 'GIS and Spatial Statistics',
  advanced: 'Advanced track and workshops A1 to A9',
  'game-full': 'Dungeons & Dataframes, all regions',
  'all-access': 'Everything',
};

/** Paid areas: rule -> product. The longest matching rule wins. */
export const PAID = [
  ['/moderate/*', 'moderate'],
  // The two Data Visualization electives are not in the plan's product list.
  // Decision (NIGHT_NOTES.md): Foundations goes with Moderate, Complete with Advanced.
  ['/dataviz-base/*', 'moderate'],
  ['/dataviz-complete/*', 'advanced'],
  ['/regression/*', 'regression'],
  ['/statistics/*', 'statistics'],
  ['/gis/*', 'gis'],
  ['/advanced/*', 'advanced'],
  ['/dungeons/dungeons/*', 'game-full'],
  // The game site carries a copy of the regression workshop for its "Read first" links.
  ['/dungeons/regression-workshop/*', 'regression'],
];

const ADVANCED_WORKSHOPS = {
  'survival-workshop': ['s1_time_to_event', 'lab1_data'],
  'counts-workshop': ['s1_counts_rates', 'lab1_counts'],
  'ordinal-workshop': ['s1_categorical_outcomes', 'lab1_outcomes'],
  'clustered-workshop': ['s1_clustered_data', 'lab1_clusters'],
  'survey-workshop': ['s1_survey_design', 'lab1_design'],
  'curves-workshop': ['s1_beyond_linear', 'lab1_linear'],
  'missing-workshop': ['s1_patterns_mechanisms', 'lab1_pattern'],
  'prediction-workshop': ['s1_building_model', 'lab1_build'],
  'causal-workshop': ['s1_causal_questions_dags', 'lab1_dag'],
};

/** Session 1 of a workshop: its slides, its lab and the cheat sheet. (Decks embed their CSS and scripts;
 *  the cheat sheet loads assets/cheatsheet.css, which is free via WORKSHOP_ASSETS below.) */
const sessionOne = (base, deck, lab) => [`${base}${deck}*`, `${base}labs/${lab}*`, `${base}cheatsheet*`];

/** Every workshop's assets/ folder: only the free cheat sheet's stylesheet is fetched from it at view time. */
const WORKSHOP_ASSETS = [
  '/regression/regression-workshop/assets/*',
  '/dungeons/regression-workshop/assets/*',
  '/gis/gis-workshop/assets/*',
  '/statistics/stats-workshop/assets/*',
];

/**
 * Free paths inside paid areas. Every rule here is also an exclude rule in _routes.json,
 * so none of these ever runs a Function.
 */
export const FREE = [
  // Each paid track's home page and the site furniture every page loads (CSS, JS, fonts),
  // so a visitor can see what a track holds before buying, and paid pages do not spend one
  // Function call per stylesheet. (Decision, NIGHT_NOTES.md: the plan lists no home pages.)
  // "/x/index.html" is not listed: Pages redirects it to "/x/", which is.
  ...['moderate', 'dataviz-base', 'dataviz-complete', 'regression', 'statistics', 'gis', 'advanced'].flatMap((t) => [
    `/${t}/`, `/${t}/welcome*`, `/${t}/site_libs/*`, `/${t}/assets/*`,
  ]),
  '/advanced/advanced-workshops*',

  // Session 1 and the cheat sheet of every workshop (plan §5), plus the synthetic datasets.
  ...sessionOne('/regression/regression-workshop/', 's1_foundations', 'lab1_explore'),
  '/regression/data/*',
  ...sessionOne('/dungeons/regression-workshop/', 's1_foundations', 'lab1_explore'),
  ...sessionOne('/statistics/stats-workshop/', 's1_know_your_data', 'lab1_describe'),
  '/statistics/data/*',
  ...sessionOne('/gis/gis-workshop/', 's1_spatial_data', 'lab1_data'),
  '/gis/gis/spatial_data_sf*', // Session 1 reading
  '/gis/gis/maps_choropleth*', // Session 1 reading
  '/gis/data/*',
  ...Object.entries(ADVANCED_WORKSHOPS).flatMap(([w, [deck, lab]]) => sessionOne(`/advanced/${w}/`, deck, lab)),
  '/advanced/data/*',

  // The game: the map, the campus, the placement check and Region 1 with its two tests.
  '/dungeons/dungeons/',
  '/dungeons/dungeons/index*',
  '/dungeons/dungeons/assets/*',
  '/dungeons/dungeons/campus*',
  '/dungeons/dungeons/readiness*',
  '/dungeons/dungeons/r1p*', // r1pretest and r1posttest
  '/dungeons/dungeons/b1_*',
  '/dungeons/dungeons/b2_*',
  '/dungeons/dungeons/b3_*',
  '/dungeons/dungeons/b4_*', // the page and its _files folder
  '/dungeons/dungeons/b5_*',
];

/** Free, but left out of _routes.json to stay under Cloudflare's 100-rule limit. These run the Function. */
export const FREE_VIA_FUNCTION = [
  ...WORKSHOP_ASSETS,
  ...Object.keys(ADVANCED_WORKSHOPS).map((w) => `/advanced/${w}/assets/*`),
  '/gis/gis/make_gis_data.R',
  '/dungeons/dungeons/roadmap*',
  '/dungeons/dungeons/site-design*',
];

export function ruleMatches(path, rule) {
  return rule.endsWith('*') ? path.startsWith(rule.slice(0, -1)) : path === rule;
}

/** Normalise a request path the way the gate compares it. Returns null for paths it refuses to judge. */
export function normalisePath(path) {
  let p;
  try { p = decodeURIComponent(path); } catch { return null; }
  if (!p.startsWith('/') || p.includes('\\') || p.includes('\0')) return null;
  p = p.replace(/\/{2,}/g, '/');
  if (/(^|\/)\.\.?(\/|$)/.test(p)) return null; // "." and ".." segments: never let them pick a free rule
  return p;
}

/**
 * The product a path needs, or null when it is free.
 * A path the gate cannot normalise is treated as needing all-access.
 */
export function productFor(rawPath) {
  const p = normalisePath(rawPath);
  if (p === null) return 'all-access';
  if (FREE.some((r) => ruleMatches(p, r)) || FREE_VIA_FUNCTION.some((r) => ruleMatches(p, r))) return null;
  let best = null;
  for (const [rule, product] of PAID) {
    // "/moderate" (no slash) belongs to "/moderate/*" as well.
    if (ruleMatches(p, rule) || p === rule.slice(0, -2)) {
      if (!best || rule.length > best[0].length) best = [rule, product];
    }
  }
  return best ? best[1] : null;
}

/** True when a user holding `held` (array of product ids) may open a page needing `product`. */
export function holds(held, product) {
  if (!product) return true;
  return held.includes(product) || held.includes('all-access');
}

/** The track sites shown on the landing page, and the product each needs (null = free). */
export const TRACKS = ['basic', 'moderate', 'regression', 'statistics', 'advanced', 'dataviz-base', 'dataviz-complete', 'gis', 'dungeons'];
export function trackProduct(track) {
  const hit = PAID.find(([rule]) => rule === `/${track}/*`);
  if (hit) return hit[1];
  return null; // basic, and the game (its Region 1 is free; later regions are gated page by page)
}

/** Cloudflare's _routes.json: Functions run on /api and on paid paths, never on free ones. */
export function routesJson() {
  return {
    version: 1,
    include: ['/api/*', '/_p/*', ...PAID.map(([rule]) => rule)],
    exclude: [...new Set(FREE)],
  };
}

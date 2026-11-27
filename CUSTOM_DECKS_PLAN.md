# Custom decks, notes, own slides and runnable code — plan

Written 2026-11-27, alongside [`LAUNCH_PLAN.md`](LAUNCH_PLAN.md) (Cloudflare launch in the next few weeks) and
[`MODULES_PLAN.md`](MODULES_PLAN.md). Nothing here is built yet.

## 1. What was asked, and decided

| Question | Decision (2026-11-27) |
|---|---|
| Who builds custom decks | **Learners and facilitators** |
| Slides from a product the user has not bought | **Shown locked** (title and "unlock"), never the content |
| Facilitator export | **PowerPoint with editable elements** (text, tables, charts), not pictures; also offline use |
| Everyone else's export | **PDF**, for custom decks and workshop decks |
| Which slides can be picked | **Workshop decks** only (12 workshops, 61 decks, about 1,070 slides) |
| Code on slides | **Runnable in the browser with webR** |
| Editing | Off by default: the deck looks and works exactly as now. An **Edit** toggle turns on editing (code, notes, own slides) |
| Where user content lives | **In the user's account** (Cloudflare D1), never in the repository or the site files |
| Own slides | An editor with **fonts, alignment, code block, output space** and layouts |

Still open: images in own slides (§5.4), notes on reading pages (§6, decision 4), who may export PowerPoint (§7).

## 2. webR: are our packages available? (checked 2026-11-27)

webR 0.6.1 (R 4.6.0), the current release. Two checks:

1. **Listed:** every package the workshop decks and labs load (52, from `library()` and `pkg::` calls) and all of its
   dependencies are in the webR package repository (`repo.r-wasm.org`, R 4.6 binaries).
2. **Loads in a real browser:** webR started in headless Chromium, each package installed and `library()`-ed.
   **All 51 non-base packages load** (`splines` ships with R).

| Group | Packages (all load in webR) |
|---|---|
| Data and plots | tidyverse, dplyr, tidyr, readr, readxl, writexl, janitor, jsonlite, scales, ggplot2, patchwork, see, knitr |
| Tests and effect sizes | rstatix, effectsize, car, nortest, exact2x2, emmeans, performance, broom, gtsummary |
| Regression | MASS, nnet, ordinal, brant, pscl, lmtest, sandwich, clubSandwich, mgcv, glmnet, pROC, dcurves |
| Clustered and survey | lme4, lmerTest, geepack, survey, srvyr |
| Survival | survival, ggsurvfit |
| Missing data | mice, naniar |
| Causal | MatchIt, cobalt, dagitty, EValue |
| Spatial | sf, spdep, spatialreg, smerc, classInt |

End-to-end check in the browser: read `prac_modded.xlsx`, ran the Session 4 Welch t-test (p = 2.93e-05, the same as
desktop R) and drew a ggplot.

**Not available:** `ggstatsplot` (needs `Rmpfr`). It is used on Basic/Moderate reading pages, not in workshops, so it
does not affect this plan.

**Load times** (first use; then cached by the browser): webR itself about 20 MB; most packages 1–3 s; `car` 7 s,
`spdep` 18 s, `tidyverse` 31 s. Consequence: load **only the packages a slide needs** (e.g. `dplyr` + `ggplot2`, not
the whole `tidyverse`), and only when the user switches Edit on.

**Caveats to test per workshop, not per package:** functions that need the internet or multiple cores
(`parallel`), and anything writing files outside the session. webR has no access to the user's own files.

## 3. How it works

### 3.1 Two modes on every workshop deck

| | View (default) | Edit (toggle, top right) |
|---|---|---|
| Looks | exactly as today: pre-rendered code and output | code blocks become editors with **Run** and **Reset** |
| Downloads | nothing extra | webR (about 20 MB, once) and the packages that deck uses |
| Notes | shown if the user has any | notes panel open and editable |
| Own slides | — | "＋ Add slide after this" |
| Saves | — | edits to code are **scratch** (Reset restores the original); "Save my version" keeps them in the account |

Edit is per user and remembered. Signed-out readers can switch Edit on and run code, but nothing is saved.

To run a deck's code, webR needs what the deck's hidden setup chunk does (`source("assets/setup.R")`, data files). At
build time a small script writes, per deck, the **setup code** and the list of **packages and data files** it needs
(`<deck>.webr.json`); the Edit mode runs it once, then the user's code.

### 3.2 Stable slide IDs (needed before anything is saved against slides)

Notes, saved code and custom decks point at slides. Today slide IDs come from titles (Quarto makes `#levene-test` from
"Levene test"), so **editing a title would orphan every note on it**. Before launch:

- every workshop slide gets an explicit ID: `## Compare the spreads {#s2-spread}`; a one-off script adds them;
- a check (in CI, like the quiz lint) fails on a missing, duplicate or **changed** ID;
- a removed slide keeps a "retired" entry, so a custom deck shows "this slide was removed" instead of breaking.

### 3.3 The slide catalogue

Built with the site: one JSON file per track listing every slide (workshop, deck, ID, title, product, whether it has
code or a quiz, small thumbnail). The builder reads it; it holds titles only, so locked slides show their title and no
content.

### 3.4 The custom deck player: one deck, assembled in the browser

The player fetches each source deck (same site, so the existing gate applies), cuts out the chosen slides by ID and
places them in **one** reveal.js deck with the decks' shared styles. All decks already use the same theme family, and
plots are embedded in the slides, so they carry over. Quizzes work as in the original deck. Benefits over showing
each deck in a frame: instant movement between slides, and one document to print.

- A slide the viewer may not open: the gate refuses the fetch, and the player shows a **locked card** (title, product,
  "Unlock").
- Own slides are drawn by the same player from their saved description (§5).

### 3.5 Storage (D1, in the user's account)

| Table | Holds |
|---|---|
| `note` | user, deck, slide ID, text, updated |
| `code_version` | user, deck, slide ID, chunk number, code, saved output |
| `custom_deck` | user, title, ordered list of items, share token (optional), updated |
| `own_slide` | user, slide description (JSON, §5.2), updated |

All behind `/api/...` Functions with the existing sign-in. **Nothing is written to the repository or the site.**
Limits per account (to protect the free D1 quota and stop abuse; numbers to confirm): 20 custom decks, 200 own slides,
notes up to 20,000 characters per slide, 100 KB per own slide. Saves are debounced (one request per few seconds of
typing, not per keystroke), so the 100,000 Function requests per day go a long way.

### 3.6 Safety

- Own slides are stored as **structured JSON**, never as HTML, and drawn by our own renderer; Markdown text is
  sanitised (DOMPurify). A shared deck therefore cannot inject a script into another user's page.
- User code runs **only in the viewer's own browser**, inside webR, and only when **they** press Run. Opening a shared
  deck shows the saved output; it never runs someone else's code automatically.
- webR runs in a web worker: no access to the site's cookies (sign-in cookies are httpOnly), the user's files or other
  tabs.
- Content-Security-Policy updated to allow webR (self-hosted, §8) and the package repository.

## 4. Export

### 4.1 PDF (everyone; custom decks and workshop decks)

The assembled deck (§3.4) uses reveal.js's print view; **"Download PDF"** opens it and the browser's *Save as PDF*
writes one file, one slide per page at 16:9. Locked slides print as their locked card, so a PDF never contains paid
content the user does not have. Quizzes print as the question without the answer; code prints with its current
output (the user's run, if they ran it).

### 4.2 PowerPoint with editable elements (facilitators)

PowerPoint cannot be made well in the browser from R output, so this runs **R on the facilitator's machine**
(the facilitator already has R for the workshop):

1. On the account page: "Download for PowerPoint" saves the custom deck as a small JSON file.
2. `Rscript tools/export_pptx.R my_deck.json` re-runs the R code of each chosen slide from the source `.qmd` and writes a
   `.pptx` with `officer`:
   - titles, bullets and callouts as **text boxes**;
   - tables as **real tables** (`flextable`);
   - ggplot charts as **editable shapes** (`rvg`): colours, labels and text can be changed in PowerPoint;
   - code as a monospaced text box; output as text or chart;
   - notes in the **speaker-notes pane**; own slides from their JSON;
   - quiz slides as a question slide with the answer in the notes.
3. Offline: the `.pptx`, plus the single-file HTML decks (they already work without internet).

The tool never runs another user's code: it uses the source decks and the facilitator's own slides only, and asks
before running code from an own slide.

A later option, if facilitators without R need it: the same export on a server (a paid Cloudflare feature or a small
R service). Not in this plan.

## 5. Own slides: the editor

### 5.1 What the editor offers

| Option | Choices |
|---|---|
| Layout | Title · Title + text · Two columns (50/50, 60/40, 40/60) · **Code + output** · Table · Section break |
| Font | Deck default (serif, as the workshops) · Source Sans 3 · Lato · Merriweather · Fira Code (code only) — a fixed set, so slides stay readable and export cleanly |
| Size | S · M · L · XL per block (relative to the deck, so a slide never overflows silently) |
| Alignment | left · centre · right · justified per block; vertical top · middle |
| Text | bold, italic, underline, bullet and numbered lists, links, inline code; colours from the deck palette only |
| Boxes | the decks' own callouts: **key**, **warning**, **equation / sentence to write** |
| Code block | R; font size; show/hide code; **Run** (webR); the packages it needs are detected from `library()` calls |
| **Output space** | Auto (fits the output) · Fixed: S, M, L or N lines · Beside the code (two columns) · Below the code; output type text or plot; plot width/height |
| Table | rows × columns, header row, alignment per column; or "table from code" (a data frame printed by R) |
| Speaker notes | as for workshop slides |

A **live preview** at the real slide size (1280 × 720) shows exactly what the deck will show, with an overflow warning
like the one the workshop checks use.

### 5.2 How an own slide is stored

```json
{ "layout": "code-output", "title": "My Welch test", "font": "deck", "align": "left",
  "blocks": [
    { "type": "text", "size": "M", "markdown": "Weight by sex, **Welch** t-test" },
    { "type": "code", "lang": "r", "size": "S", "code": "t.test(weight ~ sex, data = p)",
      "output": { "space": "beside", "kind": "text", "saved": "Welch Two Sample t-test ..." } }
  ],
  "notes": "Remind them R reports women minus men." }
```

The saved output means a viewer sees the result without running anything; Run refreshes it.

### 5.3 Where an own slide can go

In a custom deck, anywhere. In a workshop deck (Edit mode, "＋ Add slide after this"): the slide is saved in the
user's account and shown only to **that user** in that deck, marked "your slide". The workshop itself never changes.

### 5.4 Images (open)

Images need file storage (Cloudflare R2: 10 GB free) with a size limit per user and clean-up. Proposed for a later
step; text, tables, code and plots made by R cover most teaching slides.

## 6. Phases

Each phase can go live on its own. None blocks the launch except C0, which must be done **before any user data
refers to slides**.

| Phase | Deliverable | Proof it works | Size |
|---|---|---|---|
| **C0 · Stable slide IDs + catalogue** (before launch) | explicit IDs on all ~1,070 workshop slides; CI check; catalogue JSON per track | renaming a slide title keeps its ID; CI fails on a duplicate | 1 session |
| **C1 · Edit toggle + runnable workshop code** | view/edit toggle on every deck; webR self-hosted; per-deck setup files; Run/Reset | Lab code edited and run on a slide gives the desktop answer; View mode downloads nothing extra | 2 sessions |
| **C2 · Notes** | notes panel, D1 table, API, sync | a note written on a laptop appears on a phone | 1 session |
| **C3 · Custom decks** | builder (catalogue, search, drag to reorder), assembled player, locked cards, share link, **PDF** | a free user's deck shows paid slides locked; PDF of it has no paid content | 2–3 sessions |
| **C4 · Own slides** | editor (§5.1), preview, code + output with webR, slides in custom decks and "after this slide" | a slide made on one device plays in a deck on another; a shared deck never runs code on open | 2–3 sessions |
| **C5 · PowerPoint export** | `tools/export_pptx.R` with editable text, tables, charts, notes | a regression deck exported and edited in PowerPoint (bar recoloured, label changed) | 2 sessions |
| C6 · Images in own slides | R2 storage, limits, clean-up | — | 1–2 sessions |
| C7 · Facilitator sharing to a group | ties into LAUNCH_PLAN phase 5 (cohorts, seat codes) | participants open the facilitator's deck with their own access | with phase 5 |

Suggested timing: **C0 now** (before launch); **C1** can ship with or soon after the launch, since it needs no
database; **C2–C5** after launch, one by one.

## 7. Access and pricing: does a user need to buy a track to make a custom deck?

**Recommendation: no.** Making a custom deck should come with any free account, because it is the best way to show
what the paid workshops contain:

| | Free account | Owns a track (e.g. Regression) | Facilitator (proposal) |
|---|---|---|---|
| Build custom decks, notes, own slides | yes (limits as §3.5) | yes | yes, higher limits |
| Add any workshop slide | yes — slides of tracks they don't own show **locked** | unlocked for owned tracks | as their tracks |
| Run code (webR) | on free slides and own slides | on owned slides too | yes |
| PDF | yes (locked slides print locked) | yes | yes |
| PowerPoint export, sharing with a group | no | no | **yes** |

So a reader who only wants a custom deck of their own slides and the free Session 1 decks pays nothing; to **see** a
slide from Advanced they need Advanced. The "Facilitator" column could be its own product or come with the bundle that
includes all tracks: your decision (§9, decision 1).

## 8. Fit with Cloudflare (free plan)

- **webR self-hosted:** its largest file (`R.wasm`, 18.7 MB) is under the 25 MiB per-file limit, so webR can be served
  from our own domain (no dependence on a third party for the engine). Packages come from `repo.r-wasm.org` at first;
  mirroring the ~50 we use is possible later (about 300 files).
- **No cross-origin isolation needed:** webR's PostMessage mode works without the special headers, which would break
  fonts and other embedded resources.
- **Function requests:** assembling a custom deck fetches each source deck once (paid decks pass the gate: one request
  each); saves are debounced. Well inside 100,000 per day at launch numbers.
- **D1:** four small tables; storage per user is capped (§3.5).
- **Static pages stay static:** View mode adds one small script per deck and no requests, so free pages keep working
  even if the Function quota runs out.

## 9. Decisions needed

1. **Who gets PowerPoint export and group sharing:** a separate Facilitator product, or included with the all-tracks
   bundle? (§7)
2. **Limits for free accounts:** keep §3.5 numbers, or lower for free and higher for paid?
3. **Images in own slides** (C6): needed, or later?
4. **Notes on reading pages** (Basic, Moderate): the same notes panel, or workshop decks only?
5. **Shared decks:** may participants see the facilitator's own slides and notes, or only the workshop slides?

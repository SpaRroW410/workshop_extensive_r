#!/usr/bin/env python3
"""D8: link each base unit page to its Dungeons & Dataframes world (the other direction is worlds.js "read").

Adds one line after the lab paragraph of the page's "Practise in R" section. Idempotent.
The game lives at /dungeons/dungeons/ and every track is one folder below the site root, so the
link climbs to the root: "../" * (depth of the page in its track + 1).
"""
import re

WORLDS = {
    "r-foundations/getting-started.qmd": [("b1_first_script", "Your First Script")],
    "r-foundations/data-wrangling.qmd": [("b2_tidy_tavern", "Tidy Tavern")],
    "r-foundations/merging_dataset.qmd": [("b3_join_junction", "Join Junction")],
    "data-visualization/ggplot_grammar.qmd": [("b4_first_plots", "First Plots")],
    "plot-gallery/basic.qmd": [("b4_first_plots", "First Plots")],
    "statistical-analysis/statistical_tests.qmd": [("b5_which_test", "Which Test?"), ("m5_tests_in_context", "Tests in Context")],
    "r-foundations/cleaning_messy_data.qmd": [("m1_messy_data_dungeon", "Messy Data Dungeon")],
    "r-foundations/iteration.qmd": [("m2_loop_labyrinth", "Loop Labyrinth")],
    "data-visualization/best_practices.qmd": [("m3_explore_by_picture", "Explore by Picture")],
    "data-visualization/plot_data.qmd": [("m3_explore_by_picture", "Explore by Picture")],
    "gtsummary/gtsummary_tutorial.qmd": [("m4_table1_forge", "Table 1 Forge")],
    "statistical-analysis/data_analysis.qmd": [("m5_tests_in_context", "Tests in Context")],
}

for f, worlds in WORLDS.items():
    s = open(f).read()
    if "dungeons/dungeons/" in s:
        print("skip (has game link):", f); continue
    up = "../" * (f.count("/") + 1)
    links = " and ".join(f"**[{t}]({up}dungeons/dungeons/{h}.html)**" for h, t in worlds)
    line = f"🗺️ Then play the game world {links} in *Dungeons & Dataframes*."
    m = re.search(r"^## (🔧 )?Practise in R.*\n\n(.+\n)", s, re.M)
    if not m:
        print("NO Practise section:", f); continue
    s = s[:m.end()] + "\n" + line + "\n" + s[m.end():]
    open(f, "w").write(s)
    print("linked:", f)

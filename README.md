# Data Visualization Workshop

**Version:** 0.1.0\
**Status:** Private Launch\
**Maintainer:** Dr. Mukul Maheshwari

## 🔍 Overview

This workshop is a Quarto-powered learning tool that teaches you how to use R to make data visualizations that are easy to understand and based on evidence. It combines basic coding skills, best practices for visual storytelling, and a gallery of plot types, from simple to interactive.

The content is modular, easy for teachers to use, and made to work around real-world limitations. This site supports a thoughtful and hands-on way to talk about data, whether you're teaching, learning, or trying out new things.

## 📁 Folder Structure

```{=html}
<pre> 
quarto_webpage_visualization/ 
├── _quarto.yml # Global configuration 
├── theme_webp.css # Custom styling 
├── index.qmd # Landing page 
├── contact.qmd # Workshop background 
├── README.md # Project documentation 
├── data-visualization/ 
│ ├── intro.qmd 
│ ├── best-practices.qmd 
├── r-foundations/ 
│ ├── getting-started.qmd 
│ ├── data-wrangling.qmd 
├── plot-gallery/ 
│ ├── basic.qmd 
│ ├── advanced.qmd 
│ ├── interactive.qmd 
├── resources/ 
│ ├── color-theory.pdf 
│ ├── tidyverse-cheatsheet.pdf 
├── slides/ 
│ ├── workshop-intro.qmd 
│ ├── viz-principles.qmd 
├── images/ 
│ ├── chart-types.png 
│ ├── layout-guide.svg 
</pre>
```

## 📦 Requirements

To run and reproduce the workshop materials, ensure the following setup:

-   **R version:** ≥ 4.1\
-   **Required packages:**
    -   `ggplot2`
    -   `ggstatsplot`
    -   `tidyverse`

You can install all dependencies using:

``` r
install.packages(c("ggplot2", "ggstatsplot", "tidyverse"))
```

## 🎯 Goals

-   Teach cognitive science-based principles of effective visualization

-   Give learners and teachers resources that can be used again and again

-   Show how to use R and Quarto to make techniques that can be changed

-   Use hands-on examples to get people to think and try new things.

## 🚧 Status

-   This is a **private launch** for internal testing and refinement

-   External sharing is restricted until version ≥ 0.5

## 📬 Get in touch

Please contact Dr. Mukul Maheshwari directly if you have any ideas, want to work together, or want to know how to get early access.

## 🎓 Regression Workshop

The regression track hosts a full-day **Theory of Regression Analysis** workshop in `regression-workshop/`
(6 reveal.js decks, 6 fill-in-the-blank R labs with facilitator solutions, quiz engine, cheat sheet) on a simulated
NCD survey (`data/ncd_survey.csv`). See [`regression-workshop/README.md`](regression-workshop/README.md).

## 🧭 Advanced and GIS workshops

The same pattern (five reveal.js decks, five fill-in-the-blank R labs with facilitator solutions, a quiz per deck, a two-page cheat sheet,
a synthetic dataset built by `make_data.R`) is used for each further module. Each folder has its own README.

| Module | Folder | Profile |
|---|---|---|
| GIS and spatial statistics | `gis-workshop/` | `gis` |
| A1 Survival analysis | `survival-workshop/` | `advanced` |
| A2 Counts and rates | `counts-workshop/` | `advanced` |
| A3 Ordinal and multinomial outcomes | `ordinal-workshop/` | `advanced` |
| A4 Clustered and repeated data | `clustered-workshop/` | `advanced` |
| A5 Survey data and weights | `survey-workshop/` | `advanced` |
| A6 Curves and interactions | `curves-workshop/` | `advanced` |
| A7 Missing data | `missing-workshop/` | `advanced` |
| A8 Prediction models | `prediction-workshop/` | `advanced` |
| A9 Causal inference | `causal-workshop/` | `advanced` |

`advanced-workshops.qmd` lists every session. The quiz engine is shared: edit the master copy in `regression-workshop/assets/` and run
`scripts/sync_workshop_assets.sh`. Deck quizzes keep the score in the browser and offer a **Save score** button.

## 🎮 Dungeons & Dataframes

A browser game in `dungeons/` (profile `dungeons`) that practises the workshop content: Regions 1 to 3 are playable (basics, moderate, regression).
See [`dungeons/README.md`](dungeons/README.md) and [`dungeons/ROADMAP.md`](dungeons/ROADMAP.md).

The current state of every module, the checks that were run and the open points are in [`STATUS.md`](STATUS.md).


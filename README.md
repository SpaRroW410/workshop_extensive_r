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


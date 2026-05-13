
import os

moderate = """project:
  type: website
  output-dir: docs/moderate

website:
  title: "Data Visualization Workshop — Moderate"
  site-url: "."
  search: true

  navbar:
    logo-href: welcome.html
    left:
      - href: welcome.qmd
        text: "🏠 Home"
      - text: "R Foundations"
        menu:
          - text: "Getting Started"
            href: r-foundations/getting-started.qmd
          - text: "Intro to R"
            href: r-foundations/intro_to_r.qmd
          - text: "Data Wrangling (Tidyverse)"
            href: r-foundations/data-wrangling.qmd
          - text: "Merging Datasets"
            href: r-foundations/merging_dataset.qmd
          - text: "---"
          - text: "Applied: R Intro Examples"
            href: nctoh/intro_to_r_nctoh.qmd
          - text: "Applied: Wrangling Examples"
            href: nctoh/data_wrangle.qmd
      - text: "Data Visualization"
        menu:
          - text: "Grammar of Graphics"
            href: data-visualization/ggplot_grammar.qmd
          - text: "Best Practices"
            href: data-visualization/best_practices.qmd
          - text: "Matching Data to Plots"
            href: data-visualization/plot_data.qmd
          - text: "---"
          - text: "Module 1 — Foundations & Geoms"
            href: data-visualization/gram_ggplot/module_1_foundations_geoms.qmd
          - text: "Module 2 — Aesthetics, Faceting & Themes"
            href: data-visualization/gram_ggplot/module_2_aesthetics_faceting_themes.qmd
          - text: "---"
          - text: "Basic Plot Gallery"
            href: plot-gallery/basic.qmd
          - text: "Intermediate Plot Gallery"
            href: plot-gallery/moderate.qmd
          - text: "---"
          - text: "Applied: Visualization Examples"
            href: nctoh/data_visualization.qmd
      - text: "Specialized Plots"
        menu:
          - text: "Merged Visuals"
            href: specialized/merge_visuals.qmd
          - text: "Statistical Plots"
            href: specialized/plot_stats.qmd
      - text: "Statistical Analysis"
        menu:
          - text: "Test Selection Guide"
            href: statistical-analysis/statistical_tests.qmd
          - text: "ggstatsplot — Intro"
            href: statistical-analysis/ggstatsplot_intro.qmd
          - text: "ggstatsplot — Intermediate"
            href: statistical-analysis/ggstatsplot_moderate.qmd
          - text: "gtsummary Tables"
            href: statistical-analysis/gtsummary_tutorial.qmd
          - text: "---"
          - text: "Applied: Analysis Examples"
            href: nctoh/data_analysis_abridged.qmd
      - text: "Quarto"
        menu:
          - text: "Quarto Basics"
            href: statistical-analysis/reproducible_writing.qmd
          - text: "Quarto — Dynamic Documents"
            href: statistical-analysis/quarto_moderate.qmd
      - text: "Exporting & Tools"
        menu:
          - text: "Exporting Plots"
            href: exporting_tools/exporting_plots.qmd
          - text: "Plotting Tools"
            href: exporting_tools/plotting_tools.qmd
    right:
      - text: "Reference"
        icon: book
        menu:
          - text: "Contact Us"
            href: contact.qmd
          - text: "References"
            href: references.qmd
          - text: "Downloads"
            href: downloads.qmd

format:
  html:
    theme: flatly
    css: assets/theme_webp.css
    code-copy: true
    toc: true
    lightbox: auto
"""

advanced = """project:
  type: website
  output-dir: docs/advanced

website:
  title: "Data Visualization Workshop — Advanced"
  site-url: "."
  search: true

  navbar:
    logo-href: welcome.html
    left:
      - href: welcome.qmd
        text: "🏠 Home"
      - text: "R Foundations"
        menu:
          - text: "Getting Started"
            href: r-foundations/getting-started.qmd
          - text: "Intro to R"
            href: r-foundations/intro_to_r.qmd
          - text: "Data Wrangling (Tidyverse)"
            href: r-foundations/data-wrangling.qmd
          - text: "Merging Datasets"
            href: r-foundations/merging_dataset.qmd
          - text: "---"
          - text: "Applied: R Intro Examples"
            href: nctoh/intro_to_r_nctoh.qmd
          - text: "Applied: Wrangling Examples"
            href: nctoh/data_wrangle.qmd
      - text: "Data Visualization"
        menu:
          - text: "Grammar of Graphics"
            href: data-visualization/ggplot_grammar.qmd
          - text: "Best Practices"
            href: data-visualization/best_practices.qmd
          - text: "Matching Data to Plots"
            href: data-visualization/plot_data.qmd
          - text: "---"
          - text: "Module 1 — Foundations & Geoms"
            href: data-visualization/gram_ggplot/module_1_foundations_geoms.qmd
          - text: "Module 2 — Aesthetics, Faceting & Themes"
            href: data-visualization/gram_ggplot/module_2_aesthetics_faceting_themes.qmd
          - text: "Module 3 — Colors, Scales & Themes"
            href: data-visualization/gram_ggplot/module_3_colors_scales_themes.qmd
          - text: "Module 4 — Advanced Best Practices"
            href: data-visualization/gram_ggplot/module_4_advanced_best_practices.qmd
          - text: "---"
          - text: "Basic Plot Gallery"
            href: plot-gallery/basic.qmd
          - text: "Intermediate Plot Gallery"
            href: plot-gallery/moderate.qmd
          - text: "Advanced Plot Gallery"
            href: plot-gallery/advanced.qmd
          - text: "Practical Applications"
            href: plot-gallery/practical_application.qmd
          - text: "---"
          - text: "Applied: Visualization Examples"
            href: nctoh/data_visualization.qmd
          - text: "Applied: Practical Examples"
            href: nctoh/NCTOH_2026.qmd
      - text: "Specialized Plots"
        menu:
          - text: "Merged Visuals"
            href: specialized/merge_visuals.qmd
          - text: "Statistical Plots"
            href: specialized/plot_stats.qmd
          - text: "Interactive Plots"
            href: specialized/interactive.qmd
      - text: "Statistical Analysis"
        menu:
          - text: "Test Selection Guide"
            href: statistical-analysis/statistical_tests.qmd
          - text: "ggstatsplot — Intro"
            href: statistical-analysis/ggstatsplot_intro.qmd
          - text: "ggstatsplot — Intermediate"
            href: statistical-analysis/ggstatsplot_moderate.qmd
          - text: "ggstatsplot — Advanced"
            href: statistical-analysis/ggstatsplot_advanced.qmd
          - text: "gtsummary Tables"
            href: statistical-analysis/gtsummary_tutorial.qmd
          - text: "Data Analysis"
            href: statistical-analysis/data_analysis.qmd
          - text: "---"
          - text: "Applied: Analysis Examples"
            href: nctoh/data_analysis_abridged.qmd
      - text: "Quarto"
        menu:
          - text: "Quarto Basics"
            href: statistical-analysis/reproducible_writing.qmd
          - text: "Quarto — Dynamic Documents"
            href: statistical-analysis/quarto_moderate.qmd
          - text: "Quarto — Publication"
            href: statistical-analysis/quarto_advanced.qmd
      - text: "Exporting & Tools"
        menu:
          - text: "Exporting Plots"
            href: exporting_tools/exporting_plots.qmd
          - text: "Plotting Tools"
            href: exporting_tools/plotting_tools.qmd
          - text: "Debugging Plots"
            href: exporting_tools/debugging_plots.qmd
          - text: "Advanced Exporting"
            href: exporting_tools/advanced_exporting.qmd
    right:
      - text: "Reference"
        icon: book
        menu:
          - text: "Contact Us"
            href: contact.qmd
          - text: "References"
            href: references.qmd
          - text: "Downloads"
            href: downloads.qmd

format:
  html:
    theme: flatly
    css: assets/theme_webp.css
    code-copy: true
    toc: true
    lightbox: auto
"""

dataviz_base = """project:
  type: website
  output-dir: docs/dataviz-base

website:
  title: "Data Visualization — Foundations"
  site-url: "."
  search: true

  navbar:
    logo-href: welcome.html
    left:
      - href: welcome.qmd
        text: "🏠 Home"
      - text: "Data Visualization"
        menu:
          - text: "Grammar of Graphics"
            href: data-visualization/ggplot_grammar.qmd
          - text: "Best Practices"
            href: data-visualization/best_practices.qmd
          - text: "Matching Data to Plots"
            href: data-visualization/plot_data.qmd
          - text: "---"
          - text: "Module 1 — Foundations & Geoms"
            href: data-visualization/gram_ggplot/module_1_foundations_geoms.qmd
          - text: "Module 2 — Aesthetics, Faceting & Themes"
            href: data-visualization/gram_ggplot/module_2_aesthetics_faceting_themes.qmd
      - text: "Plot Gallery"
        menu:
          - text: "Basic Plots"
            href: plot-gallery/basic.qmd
          - text: "Intermediate Plots"
            href: plot-gallery/moderate.qmd
      - text: "Specialized Plots"
        menu:
          - text: "Merged Visuals"
            href: specialized/merge_visuals.qmd
          - text: "Statistical Plots"
            href: specialized/plot_stats.qmd
      - text: "Exporting & Tools"
        menu:
          - text: "Exporting Plots"
            href: exporting_tools/exporting_plots.qmd
          - text: "Plotting Tools"
            href: exporting_tools/plotting_tools.qmd
      - text: "Applied: Viz Examples"
        href: nctoh/data_visualization.qmd
    right:
      - text: "Reference"
        icon: book
        menu:
          - text: "Contact Us"
            href: contact.qmd
          - text: "References"
            href: references.qmd
          - text: "Downloads"
            href: downloads.qmd

format:
  html:
    theme: flatly
    css: assets/theme_webp.css
    code-copy: true
    toc: true
    lightbox: auto
"""

dataviz_complete = """project:
  type: website
  output-dir: docs/dataviz-complete

website:
  title: "Data Visualization — Complete"
  site-url: "."
  search: true

  navbar:
    logo-href: welcome.html
    left:
      - href: welcome.qmd
        text: "🏠 Home"
      - text: "Data Visualization"
        menu:
          - text: "Grammar of Graphics"
            href: data-visualization/ggplot_grammar.qmd
          - text: "Best Practices"
            href: data-visualization/best_practices.qmd
          - text: "Matching Data to Plots"
            href: data-visualization/plot_data.qmd
          - text: "---"
          - text: "Module 1 — Foundations & Geoms"
            href: data-visualization/gram_ggplot/module_1_foundations_geoms.qmd
          - text: "Module 2 — Aesthetics, Faceting & Themes"
            href: data-visualization/gram_ggplot/module_2_aesthetics_faceting_themes.qmd
          - text: "Module 3 — Colors, Scales & Themes"
            href: data-visualization/gram_ggplot/module_3_colors_scales_themes.qmd
          - text: "Module 4 — Advanced Best Practices"
            href: data-visualization/gram_ggplot/module_4_advanced_best_practices.qmd
      - text: "Plot Gallery"
        menu:
          - text: "Basic Plots"
            href: plot-gallery/basic.qmd
          - text: "Intermediate Plots"
            href: plot-gallery/moderate.qmd
          - text: "Advanced Plots"
            href: plot-gallery/advanced.qmd
          - text: "Practical Applications"
            href: plot-gallery/practical_application.qmd
      - text: "Specialized Plots"
        menu:
          - text: "Merged Visuals"
            href: specialized/merge_visuals.qmd
          - text: "Statistical Plots"
            href: specialized/plot_stats.qmd
          - text: "Interactive Plots"
            href: specialized/interactive.qmd
      - text: "Exporting & Tools"
        menu:
          - text: "Exporting Plots"
            href: exporting_tools/exporting_plots.qmd
          - text: "Plotting Tools"
            href: exporting_tools/plotting_tools.qmd
          - text: "Debugging Plots"
            href: exporting_tools/debugging_plots.qmd
          - text: "Advanced Exporting"
            href: exporting_tools/advanced_exporting.qmd
      - text: "Applied Examples"
        menu:
          - text: "Applied: Visualization Examples"
            href: nctoh/data_visualization.qmd
          - text: "Applied: Practical Examples"
            href: nctoh/NCTOH_2026.qmd
    right:
      - text: "Reference"
        icon: book
        menu:
          - text: "Contact Us"
            href: contact.qmd
          - text: "References"
            href: references.qmd
          - text: "Downloads"
            href: downloads.qmd

format:
  html:
    theme: flatly
    css: assets/theme_webp.css
    code-copy: true
    toc: true
    lightbox: auto
"""

os.makedirs("output", exist_ok=True)

files = {
    "output/quarto-moderate.yml": moderate,
    "output/quarto-advanced.yml": advanced,
    "output/quarto-dataviz-base.yml": dataviz_base,
    "output/quarto-dataviz-complete.yml": dataviz_complete,
}

for path, content in files.items():
    with open(path, "w") as f:
        f.write(content)
    print(f"Written: {path}")

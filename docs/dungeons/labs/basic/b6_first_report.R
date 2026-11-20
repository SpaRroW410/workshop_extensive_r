# ═══════════════════════════════════════════════════════════════
# BASIC LAB 6 — A first report
# Medical Statistics in R · Basic track · goes with: Regression Analysis and Quarto Basics
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

# This lab has two parts. Part A runs in R. Part B is a Quarto document: copy it into a new file
# called report.qmd (File > New File > Quarto Document) and press Render.

p <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv"); p <- p[file.exists(p)][1]
ncd <- read.csv(p)

# ── Part A, Task 1 ──────────────────────────────────────────────
# Goal: A simple linear regression of systolic BP on BMI; show the coefficients.
m <- ___(sbp ~ bmi, data = ncd)
summary(m)$coefficients

# ── Part A, Task 2 ──────────────────────────────────────────────
# Goal: The 95% confidence interval of the slope.
___(m)["bmi", ]

# ── Part B ──────────────────────────────────────────────────────
# Goal: Fill the blanks in this report (lines starting with #> are the document):
#> ---
#> title: "Blood pressure and BMI"
#> format: ___
#> ---
#> ```{r}
#> ncd <- ___("data/ncd_survey.csv")
#> m <- lm(sbp ~ bmi, data = ncd)
#> ```
#> Each extra unit of BMI was associated with `r round(___(m)["bmi"], 2)` mmHg higher systolic BP.

# Q1. Why is an inline `r ...` number better than typing the number into the text?

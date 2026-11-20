# ═══════════════════════════════════════════════════════════════
# BASIC LAB 1 — Your first script
# Medical Statistics in R · Basic track · goes with: Getting Started (Introduction to R)
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Store the number of patients screened today (48) in an object called screened, then print it.
screened ___ 48
screened

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: A vector of five systolic blood pressures; compute their mean.
sbp <- ___(128, 142, 135, 151, 119)
___(sbp)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Read the NCD survey (a CSV file) into a data frame called ncd.
p <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv"); p <- p[file.exists(p)][1]
ncd <- ___(p)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: How many rows (people) and columns (variables) does it have?
___(ncd)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Look at the structure: the name and type of every variable.
___(ncd)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Make sex a factor and check its levels.
ncd$sex <- ___(ncd$sex)
levels(ncd$sex)

# Q1. Why is a project folder better than setwd("C:/...") for this script?

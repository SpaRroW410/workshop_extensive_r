# Regenerates the extra practice files used by Region 2 tasks. Rscript dungeons/make_data_region2.R (repository root; seed fixed)
#   data/ncd_messy.csv    300 rows of the NCD survey made deliberately MESSY (names, labels, types, duplicates, impossible values)
#   data/bp_followup.csv  120 people measured twice (baseline, follow-up) in two groups; a skewed triglyceride column
suppressMessages({ library(readr); library(dplyr); library(stringr) })
ncd <- read_csv("data/ncd_survey.csv", show_col_types = FALSE)
set.seed(2027)
d <- ncd |> slice(1:300) |> select(id, age, sex, residence, bmi, salt_g, sbp, tobacco)
n <- nrow(d)
sex_lab <- case_when(d$sex == "Male" ~ sample(c("Male", "male", "M", "MALE"), n, TRUE, prob = c(.55, .2, .15, .1)),
                     TRUE ~ sample(c("Female", "female", "F", "FEMALE"), n, TRUE, prob = c(.55, .2, .15, .1)))
messy <- tibble(`Pt ID` = d$id, `Age (yrs)` = as.character(d$age), SEX = sex_lab,
                `Residence ` = ifelse(runif(n) < .2, paste0(d$residence, " "), d$residence),
                BMI = d$bmi, `Salt g/day` = ifelse(runif(n) < .25, paste0(d$salt_g, " g"), as.character(d$salt_g)),
                SBP = d$sbp, Tobacco = d$tobacco,
                `Visit date` = ifelse(runif(n) < .5, format(as.Date("2025-01-01") + sample(0:200, n, TRUE), "%Y-%m-%d"),
                                      format(as.Date("2025-01-01") + sample(0:200, n, TRUE), "%d/%m/%Y")))
messy$`Age (yrs)`[sample(n, 4)] <- "999"           # placeholder code for "unknown"
messy$`Age (yrs)`[sample(n, 3)] <- "unknown"       # text in a numeric column (the column is then read as text)
i <- sample(n, 3); messy$SBP[i] <- messy$SBP[i] * 10       # decimal typo (e.g. 1320)
messy$SBP[sample(n, 2)] <- 0                              # impossible
dup_exact <- messy[sample(n, 10), ]                        # 10 exact duplicate rows
dup_id <- messy[sample(n, 3), ]; dup_id$SBP <- dup_id$SBP + 8; dup_id$`Visit date` <- "2025-09-30"   # same person, different values
messy <- bind_rows(messy, dup_exact, dup_id)
messy <- messy[sample(nrow(messy)), ]
write_csv(messy, "data/ncd_messy.csv")

fu <- ncd |> slice(301:420) |> transmute(id, village, group = rep(c("Intervention", "Control"), each = 60), sbp_baseline = sbp)
fu$sbp_followup <- round(fu$sbp_baseline - ifelse(fu$group == "Intervention", 6, 1) + rnorm(nrow(fu), 0, 8))
fu$tg_mg_dl <- round(exp(rnorm(nrow(fu), log(150), 0.45)))          # right-skewed on purpose
write_csv(fu, "data/bp_followup.csv")

m <- read_csv("data/ncd_messy.csv", show_col_types = FALSE)
cat(sprintf("messy: %d rows (%d exact duplicates, 3 duplicate ids), %d sex labels, age type: %s\n", nrow(m), sum(duplicated(m)), n_distinct(m$SEX), class(m$`Age (yrs)`)))
stopifnot(n_distinct(m$SEX) >= 6, sum(duplicated(m)) >= 10, is.character(m$`Age (yrs)`), is.character(m$`Salt g/day`), any(m$`Age (yrs)` == "999"))
t <- t.test(fu$sbp_followup, fu$sbp_baseline, paired = TRUE)
stopifnot(t$p.value < 0.05, mean(fu$tg_mg_dl) > median(fu$tg_mg_dl) * 1.05)
cat("feature check passed\n")

# ═══════════════════════════════════════════════════════════════
# make_data.R — synthetic maternal health survey for the ordinal and multinomial workshop (no real women)
# Rscript ordinal-workshop/make_data.R        (repository root; seed fixed)
# Writes data/maternal_survey.csv : 1,500 women aged 15-49 with a birth in the last 3 years.
#   anaemia   ORDERED outcome: None < Mild < Moderate < Severe
#   delivery  NOMINAL outcome: Home / PHC / Public hospital / Private hospital
#   predictors: age, education, wealth (quintile 1-5), residence, tribal, parity, anc_visits, bmi
# Built-in structure (checked below; the script stops if a teaching feature is lost):
#   * anaemia: higher wealth/education/BMI and more ANC lower the odds of worse anaemia; proportional odds HOLDS for these
#   * tribal women have a different pattern: extra SEVERE anaemia without much shift between None and Mild -> proportional odds is VIOLATED for `tribal`
#   * delivery: wealth, education, ANC visits raise institutional delivery; wealth raises PRIVATE over public; rural lowers private
#   * every outcome category has at least 5% of women (no sparse categories)
# ═══════════════════════════════════════════════════════════════
suppressMessages({ library(dplyr); library(readr); library(MASS); library(nnet); library(brant) })
set.seed(2034)
n <- 1500
residence <- sample(c("Urban", "Rural"), n, TRUE, prob = c(.35, .65))
tribal <- rbinom(n, 1, ifelse(residence == "Rural", .22, .04))
wealth <- pmin(5, pmax(1, round(rnorm(n, ifelse(residence == "Urban", 3.8, 2.6) - 0.9 * tribal, 1.2))))
education <- cut(rnorm(n, 0.45 * (wealth - 3) + ifelse(residence == "Urban", .5, 0), 1.1), c(-Inf, -1, 0.1, 1, Inf), c("None", "Primary", "Secondary", "Higher"))
age <- round(pmin(49, pmax(15, rnorm(n, 27, 6))))
parity <- pmax(1L, rpois(n, 0.07 * (age - 15) + 0.9 - 0.2 * as.numeric(education == "Higher")) )
anc <- pmin(8L, pmax(0L, rpois(n, 2.2 + 0.55 * (wealth - 3) + 0.6 * as.numeric(education) - 0.5 * (residence == "Rural") - 0.4 * tribal)))
bmi <- round(pmax(14, rnorm(n, 20.5 + 0.7 * (wealth - 3) - 0.8 * tribal, 3)), 1)
# ── ordered outcome (proportional odds, then a tribal-specific shift of the upper categories) ──
eta <- -0.28 * (wealth - 3) - 0.20 * (as.numeric(education) - 2) - 0.07 * (bmi - 20.5) - 0.12 * anc + 0.10 * (parity - 2) + 0.012 * (age - 27)
cut <- c(-0.2, 1.3, 2.7)
pc <- function(k) plogis(cut[k] - eta)
u <- runif(n); lat <- rlogis(n)                                   # latent logistic: category = number of cut points below (lat + eta)
anaemia_num <- 1 + (lat + eta > cut[1]) + (lat + eta > cut[2]) + (lat + eta > cut[3])
bump <- tribal == 1 & anaemia_num == 3 & runif(n) < 0.5          # tribal women: moderate -> severe (upper threshold only)
anaemia_num[bump] <- 4
anaemia <- factor(c("None", "Mild", "Moderate", "Severe")[anaemia_num], levels = c("None", "Mild", "Moderate", "Severe"), ordered = TRUE)
# ── nominal outcome (multinomial logit; reference = Home) ──
w <- wealth - 3; e <- as.numeric(education) - 2; rural <- as.numeric(residence == "Rural")
lp_phc  <- 0.6 + 0.20 * w + 0.35 * e + 0.45 * (anc - 3) - 0.1 * rural - 0.2 * tribal
lp_pub  <- 0.7 + 0.30 * w + 0.45 * e + 0.50 * (anc - 3) - 0.4 * rural - 0.5 * tribal
lp_priv <- -0.6 + 0.80 * w + 0.60 * e + 0.45 * (anc - 3) - 1.0 * rural - 0.8 * tribal
P <- cbind(Home = 1, PHC = exp(lp_phc), `Public hospital` = exp(lp_pub), `Private hospital` = exp(lp_priv)); P <- P / rowSums(P)
delivery <- apply(P, 1, function(p) sample(colnames(P), 1, prob = p))
delivery <- factor(delivery, levels = c("Home", "PHC", "Public hospital", "Private hospital"))
d <- tibble(id = sprintf("W%04d", 1:n), age = age, education = education, wealth = wealth, residence = residence, tribal = c("No", "Yes")[tribal + 1],
            parity = parity, anc_visits = anc, bmi = bmi, anaemia = anaemia, delivery = delivery)
write_csv(d |> mutate(across(c(anaemia, delivery), as.character)), "data/maternal_survey.csv")

# ── feature check ──
m <- read_csv("data/maternal_survey.csv", show_col_types = FALSE) |>
  mutate(anaemia = factor(anaemia, levels = c("None", "Mild", "Moderate", "Severe"), ordered = TRUE), delivery = factor(delivery, levels = c("Home", "PHC", "Public hospital", "Private hospital")),
         education = factor(education, levels = c("None", "Primary", "Secondary", "Higher")), tribal = factor(tribal), residence = factor(residence, levels = c("Urban", "Rural")))
pa <- prop.table(table(m$anaemia)); pd <- prop.table(table(m$delivery))
po <- polr(anaemia ~ wealth + education + bmi + anc_visits + parity + age + tribal + residence, data = m, Hess = TRUE)
br <- brant(po)
mn <- multinom(delivery ~ wealth + education + anc_visits + residence + tribal, data = m, trace = FALSE)
cat("anaemia:", paste(names(pa), round(100 * pa), collapse = " | "), "\ndelivery:", paste(names(pd), round(100 * pd), collapse = " | "), "\n")
cat(sprintf("polr OR wealth = %.2f | brant omnibus p = %.4f | brant tribalYes p = %.4f | brant wealth p = %.3f\n", exp(coef(po)["wealth"]), br["Omnibus", "probability"], br["tribalYes", "probability"], br["wealth", "probability"]))
cf <- coef(mn); cat("multinom wealth coef (PHC, Public, Private):", paste(round(cf[, "wealth"], 2), collapse = ", "), "\n")
stopifnot(all(pa > .05), all(pd > .05), exp(coef(po)["wealth"]) < 0.9, br["tribalYes", "probability"] < 0.01, br["wealth", "probability"] > 0.05, br["bmi", "probability"] > 0.05,
          cf["Private hospital", "wealth"] > cf["Public hospital", "wealth"], cf["Private hospital", "residenceRural"] < -0.5, all(cf[, "anc_visits"] > 0))
cat("feature check passed\n")

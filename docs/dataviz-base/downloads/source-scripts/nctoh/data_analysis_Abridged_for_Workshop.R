
library(tidyverse)
library(readxl)
library(janitor)
library(pacman)
pacman::p_load(rstatix, nortest,exact2x2,car)

# Descriptive statistics


freq_table <- table(overall_up$tobacco_type)
print(freq_table) 
freq_table
# Proportion table
prop_table <- prop.table(freq_table)
prop_table

# Combined table
combined_table <- data.frame(
  Frequency = freq_table,
  Percentage = prop_table*100
)
combined_table


# Frequency and proportion using dplyr
summary_table <- overall_up |>
  mutate(wealth_index = factor(wealth_quintile,
      levels = c("Poorest","Poorer","Middle","Richer","Richest"))) |> 
  group_by(wealth_index) |>
  reframe(
    Frequency = n(),
    Percentage = paste(round(n()*100/ nrow(overall_up),2),"%")
  )
print(summary_table)



#Mean and SD
summary(overall_up$current_age)
sd(overall_up$current_age)

#Using tidyverse

overall_up|> 
  summarise( 
    mean_age = mean(current_age), 
    sd_age = sd(current_age),
    median_age = median(current_age),
    Q1 = quantile(current_age, 0.25),
    Q3 = quantile(current_age, 0.75),
    IQR = IQR(current_age),
    var_age = var(current_age), 
    min_age = min(current_age), 
    max_age = max(current_age) )


#Chi square

?chisq.test

#options(scipen = 999) to get value in decimals
#options(scipen = 0) to get value in scientific notation

# Two groups (both binary)
# > 5 frequency in each cell

# Create a contingency table
table_fuel_inter <- table(overall_up$fuel_type, overall_up$intervention)


# Print the table
print(table_fuel_inter)

# Chi-square test
chisq_m_5_b <- chisq.test(table_fuel_inter, correct = FALSE)

# Print the test results
print(chisq_m_5_b)

# < 5 frequency

overall_smoker <- overall_up |> 
  filter(tobacco_type == "smoker") |> 
  mutate(fagerstrom_b_0 = ifelse(fagerstrom_catft_0 == "Low", "Low", "Mod-High")) |> 
  mutate(fagerstrom_b_3 = ifelse(fagerstrom_catft_3 == "Low", "Low", "Mod-High")) |> 
  mutate(fagerstrom_b_6 = ifelse(fagerstrom_catft_6 == "Low", "Low", "Mod-High"))

# Create a contingency table
table_in_fa<- table(overall_smoker$intervention,overall_smoker$fagerstrom_b_0)


# Print the table
print(table_in_fa)

# Chi-square test
chisq_l_5_b <- chisq.test(table_in_fa)

# Print the test results
print(chisq_l_5_b)

# Fisher's Exact Test
fisher_test <- fisher.test(table_in_fa)

# Print the test results
print(fisher_test)


#Yates continuity correction: The correction subtracts 0.5 from the absolute difference between each observed and expected frequency before squaring,

#Paired responses for categorical

# Create a contingency table
table_bfr_aftr <- table(overall_smoker$fagerstrom_b_0, overall_smoker$)
print(table_bfr_aftr)

# McNemar Test
mcnemar_test <- mcnemar.test(table_bfr_aftr)

# Print the test results
print(mcnemar_test)

#if < 5 frequency then use exact McNemar test

library(exact2x2)


# Create a contingency table
table_bfr_aftr

# Exact McNemar Test
exact_mcnemar_test <- exact2x2::mcnemar.exact(table_bfr_aftr)

# Print the test results
print(exact_mcnemar_test)


#m*n matrix
table_mar_wealth <- table(overall_smoker$wealth_quintile,overall_smoker$fagerstrom_catft_0)

table_mar_wealth

chisq_mn <- chisq.test(table_mar_wealth)
chisq_mn




#Normality

#Histogram

# Create the histogram
hist(overall_up$current_age, 
     main = "Histogram with Density Line", 
     xlab = "Value", 
     ylab = "Frequency", col = "grey", border = "black", freq = FALSE)

# Add a density line
lines(density(overall_up$current_age), col = "red", lwd = 2)

#QQ plot
qqnorm(overall_up$sbp_0m) 
qqline(overall_up$sbp_0m, col = "red") # Not normal

#Shapiro
p1 <- overall_up[sample(nrow(overall_up),50),]

s.test <- shapiro.test(p1$current_age) #p>0.05 normal distribution
s.test



hist(p$height)


#Continuous variable


# Two group

# Normality fulfilled
# Related (Paired)

# Paired t Test
# differences between the paired observations should be normally distributed.

paired_t_test <- t.test(overall_up$sbp_0m, overall_up$sbp_3m, paired = TRUE)
paired_t_test


# Non - related (Un paired)

# Independent t Test - 
#   The two groups should be independent, 
#   equal variances.



# Checking equal variances
library(car)
car::leveneTest(sbp_0m ~ fuel_type , data = overall_up) #p value >0.05 - equal variance

bartlett.test(sbp_0m ~ fuel_type , data = overall_up) #p value >0.05 - homogenous



ind_t_test <- t.test(sbp_0m ~ fuel_type , var.equal = TRUE, data = overall_up)
ind_t_test

#var.equal = TRUE: Assumes equal variances between groups. If variances are not equal, set this to FALSE

# Related (Paired)

# Wilcoxon Matched Pairs (equivalent to paired t test of parametric)
# The differences between the paired observations should be symmetrically distributed.

wilcox_paired <- wilcox.test(overall_up$consumption_per_day_0m, overall_up$consumption_per_day_6m, paired = TRUE)
wilcox_paired

options(scipen = 0) # to get value in scientific notation
options(scipen = 999) # to get value in decimals



# Non - Normal
# Non - related (Un paired)

# Mann - Whitney U (equivalent to independent t test of parametric)
# The two groups should be independent, 
#     test is based on the ranks of the data rather than the data itself.

mann_whit <- wilcox.test(consumption_per_day_0m ~ intervention, data = overall_up, 
                         correct = FALSE)
mann_whit

# continuity correction
#       Sample Sizes Are Small (<100)
#       Discrete Data (ordinal)







# More than two group

# Parametric
# Non related (Un paired)

# one way ANOVA
# The groups should be independent, normally distributed, and have equal variances.
glimpse(overall_up$wealth_quintile)

aov_un <- aov(sbp_0m ~ wealth_quintile, overall_up)
summary(aov_un)

# pairwise test

# One way ANOVA
#   Tukey's Honestly Significant Difference (HSD) test.

tukey_res <- TukeyHSD(aov_un) 
print(tukey_res)


# Related (Paired)

# Repeated anova
#   The sphericity assumption should be met, which means the variances of the differences between all combinations of related groups should be equal.


library(rstatix)
res.aov <- anova_test(data = overall_long, dv = sbp, wid = member_id, within = time_months)
get_anova_table(res.aov)

res.aov$`Mauchly's Test for Sphericity` # p value >0.05 sphericity assumption is met 


#dv: (numeric) the dependent (or outcome) variable name.
#wid: variable name specifying the case/sample identifier.
#within: within-subjects factor or grouping variable

# repeated measure ANOVA
#   pairwise t-tests with Bonferroni correction.

pairwise_res_p <- pairwise.t.test(overall_long$sbp, overall_long$time_months, p.adjust.method = "bonferroni") 
print(pairwise_res_p)


# Non-parametric
# Non - related (Unpaired)

# Kruskal Wallis test (equivalent to one way anova test of parametric)
#   groups should be independent
#     test is based on the ranks of the data rather than the data itself.

kruskal_unp <- kruskal.test(consumption_per_day_0m ~ wealth_quintile, data = overall_up)
kruskal_unp

# Kruskal Wallis test
#   pairwise Wilcoxon tests with Bonferroni correction.


pairwise_wilcox <- pairwise.wilcox.test(overall_up$consumption_per_day_0m, 
                                        overall_up$wealth_quintile, 
                                        p.adjust.method = "bonferroni") 
print(pairwise_wilcox)


# Related (Paired)
# Friedman test (equivalent to repeated anova test of parametric)
#     The samples should be dependent



# Friedman test
friedman_res <- friedman.test(consumption_per_day ~ time_months | member_id, data = overall_long)
print(friedman_res)

# friedman test
# Post hoc pairwise Wilcoxon tests with Bonferroni correction
pairwise_res_np <- pairwise.wilcox.test(overall_long$consumption_per_day, 
                                        overall_long$time_months, p.adjust.method = "bonferroni", paired = TRUE)
print(pairwise_res_np)

#options(scipen = 999) to get value in decimals
#options(scipen = 0) to get value in scientific notation
  



rm(list = setdiff(ls(),list("overall_age_u", "data_dic","overall_long","overall_up")))


# Pearson's correlation
pearson <- cor.test(overall_up$sbp_0m, overall_up$current_age, method = "pearson")
pearson




# Spearman correlation
spearman <- cor.test(overall_up$consumption_per_day_0m, overall_up$current_age, method = "spearman", exact = FALSE)
spearman






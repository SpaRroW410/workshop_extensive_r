#tASK 1:Creating a new data frame
library(tidyverse)


#2.1 Exploring R dataset package
datasets::iris

#2.2 explore the first 6 rows by default
head(women)

# Setting working directory
setwd("D:/R studio/workshop/nctoh")

#task 3 Importing dataset

library(readxl)
df<- read_excel("community_trial_tob.xlsx")
names(df)

#Cleaning the dataset df
# install.packages(janitor)
library(janitor)

df<- df |> 
janitor::clean_names()

names(df)

hh <- read_excel("community_trial_tob.xlsx", sheet = 1)
indi<- read_excel("community_trial_tob.xlsx", sheet = 2)
foll_0<- read_excel("community_trial_tob.xlsx", sheet = 3)
foll_3 <- read_excel("community_trial_tob.xlsx", sheet = 4)
foll_6<- read_excel("community_trial_tob.xlsx", sheet = "followup_6m")
data_dic <- read_excel("community_trial_tob.xlsx", sheet = 6)

head(hh)
summary(indi)
dim(foll_0)
colnames(foll_3)
dplyr::glimpse(foll_6)

# merging datasets

#left join - every individual retained


indi_hh <- indi |> 
  left_join(hh, by = "hh_id")


# full_join - keeps everyone
followup_all <- foll_0 |>
  full_join(foll_3, by = "member_id", suffix = c("_0m", "_3m")) |>
  full_join(foll_6, by = "member_id", suffix = c("", "_6m"))

names(followup_all)


foll_0r <- foll_0 |> rename_with(~ paste0(.x, "_0m"), -member_id)
foll_3r <- foll_3 |> rename_with(~ paste0(.x, "_3m"), -member_id)
foll_6r <- foll_6 |> rename_with(~ paste0(.x, "_6m"), -member_id)

followup_all <- foll_0r |>
  full_join(foll_3r, by = "member_id") |>
  full_join(foll_6r, by = "member_id")


#right_join - keeps all joining observation

overall <- indi_hh |>
  right_join(followup_all, by = "member_id")

#inner join - only observation which are in both dataset


rm(list = setdiff(ls(),list("overall", "data_dic")))

library(tibble)

select_helpers <- tibble(
  helper = c(
    "starts_with()",
    "ends_with()",
    "contains()",
    "matches()",
    "everything()",
    "last_col()",
    "any_of()",
    "all_of()",
    "where()"
  ),
  purpose = c(
    "Select columns that start with a string",
    "Select columns that end with a string",
    "Select columns that contain a string",
    "Select columns using a regular expression",
    "Select all remaining columns",
    "Select the last column (optionally with offset)",
    "Select columns if they exist (no error if missing)",
    "Select columns that must exist (error if missing)",
    "Select columns based on a condition"
  ),
  example = c(
    "select(starts_with('sbp'))",
    "select(ends_with('_0m'))",
    "select(contains('age'))",
    "select(matches('^ft[1-6]$'))",
    "select(member_id, everything())",
    "select(last_col())",
    "select(any_of(c('age','sex')))",
    "select(all_of(c('age','sex')))",
    "select(where(is.numeric))"
  )
)

select_helpers


# All numeric variables
overall |> 
select(where(is.numeric))


# All follow-up variables
overall |> 
select(contains("_id"))

# Fagerström items only
overall |> 
select(matches("^ft[1-6]$"))

# Safe selection when variables may be missing
overall |> 
select(any_of(c("sbp", "dbp", "bmi")))


# select current age
overall |> 
  select(2)


#don't want certain groups
overall |> 
  select(-c(hh_id)) 


#mutate characters or coded variable as factor

overall <- overall |> 
  mutate(tobacco_type = factor(tobacco_type, levels = c(0,1,2), 
                      labels = c("None","smoker","chewer")))

##multiple conditions
overall <- overall|>
  mutate(
    years_of_use = current_age - age_of_onset,
    pack_years = if_else(
      tobacco_type == "smoker",
      (amount_per_day / 20) * years_of_use,
      NA
    ),
    times_year = ifelse(
      tobacco_type == "chewer",
      amount_per_day*years_of_use,
      NA
    )
    )

# creating categories from continuous data

overall <- overall |> 
  mutate(
    wealth_quintile = ntile(wealth_index, 5),
    wealth_quintile = case_when(
      wealth_quintile == 1 ~ "Poorest",
      wealth_quintile == 2 ~ "Poorer",
      wealth_quintile == 3 ~ "Middle",
      wealth_quintile == 4 ~ "Richer",
      wealth_quintile == 5 ~ "Richest"
    ),
    ft_0 = ft1_0m + ft2_0m + ft3_0m +
      ft4_0m + ft5_0m + ft6_0m,
    
    ft_3 = ft1_3m + ft2_3m + ft3_3m +
      ft4_3m + ft5_3m + ft6_3m,
    
    ft_6 = ft1_6m + ft2_6m + ft3_6m +
      ft4_6m + ft5_6m + ft6_6m,
    across(
      c(ft_0, ft_3, ft_6),
      ~ cut(
        .,
        breaks = c(-Inf, 2, 4, 6, Inf),
        labels = c("Low", "Moderate", "High", "Very high"),
        right = TRUE
      ),
      .names = "fagerstrom_cat{.col}"
    )
  )


# creating subset removing redundant variables

overall_up <- overall |> 
  select(-starts_with("ft"), -hh_id, -contains("months") )


# filter

# age above and equal to15 years

overall_age_u <- overall_up |> 
  filter(current_age >= 15)


# creating piped select nd filter

overall_age_u <- overall |> 
  select(-starts_with("ft"), -hh_id, -contains("months") ) |> 
  filter(current_age >= 15)

# summarise and group by
overall_age_u |> 
  group_by(wealth_quintile) |> 
  summarise(
    n = n(),
    mean_pack_years = mean(pack_years, na.rm = TRUE)
  )


# missing values
overall |> summarise(across(everything(), ~ sum(is.na(.)))) |> 
  t() |> 
  as.data.frame() |> 
  arrange(desc(V1))

# Longer data
overall_long <- overall_age_u |> 
  pivot_longer(
    cols = c(
      starts_with("sbp_"),
      starts_with("consumption_per_day_"),
      starts_with("fagerstrom_catft_")
    ),
    names_to = c(".value", "time"),
    names_pattern = "(sbp|consumption_per_day|fagerstrom_catft)_(0m|3m|6m|0|3|6)"
  )



overall_long <- overall_age_u |> 
rename(
  fagerstrom_catft_0m = fagerstrom_catft_0,
  fagerstrom_catft_3m = fagerstrom_catft_3,
  fagerstrom_catft_6m = fagerstrom_catft_6
) |> 
  pivot_longer(
  cols = c(
    starts_with("sbp_"),
    starts_with("consumption_per_day_"),
    starts_with("fagerstrom_catft_")
  ),
  names_to = c(".value", "time_months"),
  names_pattern = "(sbp|consumption_per_day|fagerstrom_catft)_(0m|3m|6m)"
)



rm(list = setdiff(ls(),list("overall_age_u", "data_dic","overall_long")))

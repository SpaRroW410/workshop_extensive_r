# Datasets

Every dataset in this folder is **simulated**: no row describes a real person. They may be published and
redistributed with the workshop material.

## Built by a script (re-create with the script; each prints a feature check)

| File | Script | Used by |
|---|---|---|
| `ncd_survey.csv` | `regression-workshop/make_data.R` | Regression workshop, game Regions 1–3 |
| `ncd_round1.csv`, `ncd_round2.csv`, `villages.csv` | `dungeons/make_data_region1.R` | game Region 1 (joins) |
| `ncd_messy.csv`, `bp_followup.csv` | `dungeons/make_data_region2.R` | game Region 2 |
| `gis/district_blocks.geojson`, `gis/facilities.csv` | `gis/make_gis_data.R` | GIS pages and workshop |
| `tb_cohort.csv` | `survival-workshop/make_data.R` | A1 Survival |
| `dengue_wards.csv` | `counts-workshop/make_data.R` | A2 Counts |
| `maternal_survey.csv` | `ordinal-workshop/make_data.R` | A3 Ordinal |
| `bp_trial.csv` | `clustered-workshop/make_data.R` | A4 Clustered |
| `survey_adults.csv`, `survey_population.csv` | `survey-workshop/make_data.R` | A5 Survey |
| `ncd_curves.csv` | `curves-workshop/make_data.R` | A6 Curves |
| `ncd_missing.csv` | `missing-workshop/make_data.R` | A7 Missing data |
| `diabetes_dev.csv`, `diabetes_valid.csv` | `prediction-workshop/make_data.R` | A8 Prediction |
| `htn_programme.csv` | `causal-workshop/make_data.R` | A9 Causal |

## Simulated by the authors, no script in this repository

Confirmed simulated and publishable by the authors on 2026-11-20. No generator script exists; if one is
ever needed (e.g. to change a column), it has to be written from the file's structure.

| File | Used by |
|---|---|
| `PublicHealth_BP_Dataset.xlsx` | plot galleries, ggplot modules, several base pages (21 pages) |
| `Healthcare_Network_Dataset.xlsx` | network plots (gallery 2.5, 3.5) |
| `prac_modded.xlsx` | `statistical-analysis/data_analysis.qmd` |
| `health_dataset_dm.xlsx` | not used by any page |

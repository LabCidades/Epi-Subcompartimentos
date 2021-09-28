library(rstan)
library(dplyr)
library(readr)
library(cmdstanr)
library(tibble)
library(lubridate)
library(tidyr)

# If necessary you can load with
seitd_files <- list.files(
			  here::here("results", "deaths_matrix_exp", "seitd"),
			  full.names = TRUE)
seeiittd_files <- list.files(
			here::here("results", "deaths_matrix_exp", "seeiittd"),
			full.names = TRUE)

# Results
seitd <- as_cmdstan_fit(seitd_files)
seeiittd  <- as_cmdstan_fit(seeiittd_files)

seitd_T <- seitd$summary("state_T")
seeiittd_T <- seeiittd$summary(c("state_T1", "state_T2"))

# Predicted Terminally-Ill
seitd_T_wide <- seitd_T %>%
    tidyr::extract(variable, c("state", "day"),
        "(.*)\\[([\\d{1}]+)\\]",
        convert = TRUE
    ) %>%
    select(state, day, median) %>%
    pivot_wider(
        names_from = state,
        values_from = median
    ) %>%
    mutate(day = seq(ymd("2020-02-25"), ymd("2021-06-14"), by = "1 day")) %>%
    rename_with(~ gsub("state_", "", .x), .cols = starts_with("state_"))

seeiittd_T_wide <- seeiittd_T %>%
    tidyr::extract(variable, c("state", "day"),
        "(.*)\\[([\\d{1}]+)\\]",
        convert = TRUE
    ) %>%
    select(state, day, median) %>%
    pivot_wider(
        names_from = state,
        values_from = median
    ) %>%
    mutate(day = seq(ymd("2020-02-25"), ymd("2021-06-14"), by = "1 day")) %>%
    rename_with(~ gsub("state_", "", .x), .cols = starts_with("state_")) %>%
    transmute(
      day, T = T1 + T2
    )

# SRAG Terminally-Ill
srag <- read_csv(here::here("data", "SRAG.csv")) %>%
    select(day = date, real_T = int) %>%
    filter(day >= "2020-02-25") %>%
    filter(day <= "2021-06-14")

# MAE Real vs Predicted
print("SEITD")
seitd_T_wide %>%
    left_join(srag, "day") %>%
    mutate(
        MAE = abs(T - real_T),
        RMSE = sqrt((T - real_T)^2)
    ) %>%
    summarise(
        RMSE_median = median(RMSE),
        RMSE_mean = mean(RMSE),
        MAE_median = median(MAE),
        MAE_mean = mean(MAE)
    )

print("SEEIITTD")
seeiittd_T_wide %>%
    left_join(srag, "day") %>%
    mutate(
        MAE = abs(T - real_T),
        RMSE = sqrt((T - real_T)^2)
    ) %>%
    summarise(
        RMSE_median = median(RMSE),
        RMSE_mean = mean(RMSE),
        MAE_median = median(MAE),
        MAE_mean = mean(MAE)
    )

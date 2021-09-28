library(rstan)
library(dplyr)
library(cmdstanr)
library(tibble)

# If necessary you can load with
seitd_files <- list.files(here::here("results", "deaths_matrix_exp", "seitd"), full.names = TRUE)
seeiittd_files <- list.files(here::here("results", "deaths_matrix_exp", "seeiittd"), full.names = TRUE)

# Results
seitd <- as_cmdstan_fit(seitd_files)
seeiittd  <- as_cmdstan_fit(seeiittd_files)
# Predicted Deaths
seitd_deaths <- seitd$summary("pred_weekly_deaths")
seeiittd_deaths <- seeiittd$summary("pred_weekly_deaths")

# R_t
# r_t <- deaths$summary("effective_reproduction_number")

# r_t %>%
#     summarise(
#         mean_mean = mean(mean),
#         mean_median = mean(median),
#         median_mean = median(mean),
#         median_median = median(median)
#     )

# Omega
# omega <- deaths$summary("omega")

# Real data
br <- readRDS(here::here("data", "brazil_nation.rds"))
real_deaths <- br %>%
    group_by(week = cut(date, "week")) %>%
    summarise(deaths = sum(new_deaths)) %>%
    pull(deaths) %>%
    ceiling() %>%
    as.integer() %>%
    enframe(name = "week", value = "real_deaths") %>%
    head(-1)

# MAE Real vs Predicted
print("SEITD")
seitd_deaths %>%
    bind_cols(real_deaths) %>%
    mutate(
        MAE_median = abs(median - real_deaths),
        MAE_mean = abs(mean - real_deaths)
    ) %>%
    summarise(
        MAE_median = mean(MAE_median),
        MAE_mean = mean(MAE_mean)
    )

print("SEEIITTD")
seeiittd_deaths %>%
    bind_cols(real_deaths) %>%
    mutate(
        MAE_median = abs(median - real_deaths),
        MAE_mean = abs(mean - real_deaths)
    ) %>%
    summarise(
        MAE_median = mean(MAE_median),
        MAE_mean = mean(MAE_mean)
    )

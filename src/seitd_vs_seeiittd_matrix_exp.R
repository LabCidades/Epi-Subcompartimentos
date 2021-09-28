library(cmdstanr)
library(dplyr)
library(lubridate)
library(readr)
library(tibble)
library(tidyr)
library(rstan)
library(loo)


seitd <- list.files(here::here("results", "deaths_matrix_exp", "seitd"), full.names = TRUE) %>%
    as_cmdstan_fit()

dt_setid <- seitd$summary(variables = "dT")
seitd <- seitd$summary(variables = c("state_S", "state_E", "state_I", "state_T", "state_D"))

seeiittd <- list.files(here::here("results", "deaths_matrix_exp", "seeiittd"), full.names = TRUE) %>%
    as_cmdstan_fit()

dt_seeiittd <- seeiittd$summary(variables = "dT")
seeiittd <- seeiittd$summary(variables = c("state_S",
                                           "state_E1", "state_E2",
                                           "state_I1", "state_I2",
                                           "state_T1", "state_T2",
                                           "state_D"))

seitd_wide <- seitd %>%
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
    mutate(D_d = D - lag(D, default = 0))


seitd_long <- seitd_wide %>%
    pivot_longer(-day, names_to = "state", values_to = "median")

seeiittd_wide <- seeiittd %>%
    tidyr::extract(variable, c("state", "day"),
        "(\\w[\\d]?)\\[([\\d{1}]+)\\]",
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
        day, S,
        E = E1 + E2,
        I = I1 + I2,
        T = T1 + T2,
        D
    ) %>%
    mutate(D_d = D - lag(D, default = 0))

seeiittd_long <- seeiittd_wide %>%
    pivot_longer(-day, names_to = "state", values_to = "median")

# Real Deaths
br <- readRDS(here::here("data", "brazil_nation.rds"))
real_deaths <- br %>%
    filter(date <= "2021-06-14") %>%
    pull(new_deaths) %>%
    cumsum() %>%
    enframe(name = "day", value = "real_deaths") %>%
    mutate(
        real_deaths_d = real_deaths - lag(real_deaths, default = 0),
        day = seq(ymd("2020-02-25"), ymd("2021-06-14"), by = "1 day")
    )

real_deaths %>%
    left_join(seitd_wide, "day") %>%
    left_join(seeiittd_wide, "day",
        suffix = c("_seitd", "_seeiitd")
    ) %>%
    write_csv(here::here("results", "states_analysis", "matrix_exp_seitd_vs_seeiittd.csv"))

# SRAG Terminally-Ill
srag <- read_csv(here::here("data", "SRAG.csv"))

# Plot Stuff

all_data <- seitd_long %>%
    mutate(group = "seitd") %>%
    bind_rows(seeiittd_long %>% mutate(group = "seeiittd")) %>%
    filter(state %in% c("T", "D_d")) %>%
    mutate(state = if_else(state == "D_d", "D", "T")) %>%
    left_join(real_deaths, "day") %>%
    left_join(srag %>% select(day = date, real_T = int), "day")

all_data %>%
    ggplot(aes(x = day, y = median, color = state, linetype = group)) +
    geom_line() +
    geom_line(aes(y = real_deaths_d, color = "real deaths")) +
    geom_line(aes(y = real_T, color = "real T")) +
    scale_color_brewer(palette = "Set1") +
    scale_y_continuous(labels = scales::label_number_si()) +
    theme(legend.position = "bottom")

ggsave(here::here("images", "T_D_seitd_vs_seeiittd_matrix_exp.png"), dpi = 300)

rstan_seitd <- rstan::read_stan_csv(list.files(here::here(
    "results",
    "deaths_matrix_exp",
    "seitd"
),
full.names = TRUE
))
rstan_seeiittd <- rstan::read_stan_csv(list.files(here::here(
    "results",
    "deaths_matrix_exp",
    "seeiittd"
),
full.names = TRUE
))
stan_dens(rstan_seitd,
    pars = "dT",
    separate_chains = FALSE
) +
    ggtitle("SEITD")
ggsave(here::here("images", "dT_SEITD_matrix_exp.png"), dpi = 300)
stan_dens(rstan_seeiittd,
    pars = "dT",
    separate_chains = FALSE
) +
    ggtitle("SEEIITTD")
ggsave(here::here("images", "dT_SEEIITTD_matrix_exp.png"), dpi = 300)

# LOO-CV
# Extract pointwise log-likelihood
# using merge_chains=FALSE returns an array, which is easier to
# use with relative_eff()
log_lik_seitd <- extract_log_lik(rstan_seitd, merge_chains = FALSE)
r_eff_seitd <- relative_eff(exp(log_lik_seitd), cores = 2)

log_lik_seeiittd <- extract_log_lik(rstan_seeiittd, merge_chains = FALSE)
r_eff_seeiittd <- relative_eff(exp(log_lik_seeiittd), cores = 2)

loo_seitd <- loo(log_lik_seitd, r_eff = r_eff_seitd, cores = 2)
loo_seeiittd <- loo(log_lik_seeiittd, r_eff = r_eff_seeiittd, cores = 2)

# Compare Models
comp <- loo_compare(loo_seitd, loo_seeiittd)
print("LOO: SEITD(1) vs SEEIITTD(2)")
print(comp, simplify = FALSE, digits = 3)

library(cmdstanr)
library(dplyr)

# based on Funko_Unko's contribution: https://discourse.mc-stan.org/t/codatmo-liverpool-uninove-models-slow-ode-implementation-and-trapezoidal-solver/22500/45

# SEEIITTD ----------------------------------------------------------------

model <- cmdstan_model(here::here("stan", "deaths_matrix_exp_seeiittd.stan"))

# Real data
br <- readRDS(here::here("data", "brazil_nation.rds"))

no_days <- br %>% nrow
population <- br %>% pull(estimated_population_2019) %>% max
new_deaths <- br %>% pull(new_deaths)

stan_data <- list(
  no_days = no_days,
  population = population,
  new_deaths = new_deaths,
  likelihood = 1,
  beta_regularization = 0.10,
  model_periodicity = 1
)

fit <- model$sample(data = stan_data,
                    seed = 321,
                    parallel_chains = 4,
                    output_dir = here::here("results", "deaths_matrix_exp", "seeiittd"))

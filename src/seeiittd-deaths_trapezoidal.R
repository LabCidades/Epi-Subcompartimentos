library(cmdstanr)
library(dplyr)
library(lubridate)
library(LaplacesDemon)

# Trapeizodal Rule Model
model <- cmdstan_model(here::here("stan", "deaths_trapezoidal_seeiittd.stan"))

# Real data
br <- readRDS(here::here("data", "brazil_nation_2020.rds"))

initial_time <- 0
total_time <- br %>% nrow
beta_pieces <- 7 # number of days to make beta_pieces (weekly)
n_beta_pieces <- ceiling(total_time / beta_pieces)
beta_left_t <- seq(0, total_time - 1, by = beta_pieces)
beta_right_t <- c(beta_left_t[2:n_beta_pieces], total_time + 1)
n_disease_states = 8 # seeiittd
population <- br %>% pull(estimated_population_2019) %>% max

#Deaths are reported weekly, reporting periods are every seven days
deaths_starts <- seq(1, (total_time / 7 - 1) * 7, by = 7)
deaths_stops <- seq(7, total_time, by = 7)
deaths_length <- min(c(length(deaths_starts), length(deaths_starts)))
deaths <- br %>%
  group_by(week = cut(date, "week")) %>%
  summarise(deaths = sum(new_deaths)) %>%
  pull(deaths) %>%
  ceiling %>%
  as.integer %>%
  head(-1)

# I have no idea what real data is...
real_data_length <- length(beta_left_t) + length(beta_right_t) + 1
real_data <- c(beta_left_t, beta_right_t, population)
integer_data_length <- 5
integer_data <- c(total_time, length(beta_left_t), length(beta_right_t), length(beta_left_t), n_disease_states)

stan_data <- list(
  initial_time = initial_time,
  n_beta_pieces = n_beta_pieces,
  beta_left_t = beta_left_t,
  beta_right_t = beta_right_t,
  T = total_time,
  times = seq_len(total_time),
  n_disease_states = n_disease_states,
  population = population,
  deaths_length = deaths_length,
  deaths_starts = deaths_starts,
  deaths_stops = deaths_stops,
  deaths = deaths,
  real_data_length = real_data_length,
  real_data = real_data,
  integer_data_length = integer_data_length,
  integer_data = integer_data,
  compute_likelihood = 1#,
  #relative_tolerance = 1e-5,
  #absolute_tolerance = 1e-5,
  #max_num_steps = 1e3L
)

fit <- model$sample(data = stan_data,
                        seed = 321,
                        init = function() list(initial_state_raw = c(runif(1, min = 0.99999, max = 1.0), runif(1, min = 0.0, max = 1.0)),
                                               beta_left = exp(runif(n_beta_pieces, min = -2, max = 0.5)),
                                               beta_right = exp(runif(n_beta_pieces, min = -2, max = 0.5)),
                                               dL = runif(1, min = 3.5, max = 4.0),
                                               dI = runif(1, min = 2.2, max = 2.6),
                                               dT = runif(1, min = 11.0, max = 13.0),
                                               omega = invlogit(runif(1, min = -5, max = -3))),
                    chains = 4,
                    parallel_chains = 4,
                    output_dir = here::here("results", "deaths_trapezoidal", "seeiittd"))

# If necessary you can load with
# files <- list.files(here::here("results", "deaths_trapezoidal"), full.names = TRUE)
# output <- read_cmdstan_csv(files)

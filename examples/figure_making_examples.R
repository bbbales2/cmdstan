library(tidyverse)
library(ggplot)
library(rstan)
library(bayesplot)
library(shinystan)

fit = read_stan_csv(c('/home/bbales2/cmdstan-rus-orig/examples/cmsx4.20modes.1.csv',
                      '/home/bbales2/cmdstan-rus-orig/examples/cmsx4.20modes.2.csv',
                      '/home/bbales2/cmdstan-rus-orig/examples/cmsx4.20modes.3.csv',
                      '/home/bbales2/cmdstan-rus-orig/examples/cmsx4.20modes.4.csv'))

# Histograms of parameters
extract(fit, c("c11", "a", "c44", "sigma")) %>% as.tibble %>%
  gather(parameter, values) %>%
  ggplot(aes(values)) +
  geom_histogram() +
  facet_wrap(~ parameter, scales = "free")

# Traceplots
extract(fit, c("c11", "a", "c44", "sigma")) %>% as.tibble %>%
  mutate(rn = row_number()) %>%
  gather(parameter, values, c(c11, a, c44, sigma)) %>%
  ggplot(aes(rn, values)) +
  geom_point(size = 0.1) +
  geom_line(size = 0.1) +
  facet_wrap(~ parameter, scales = "free")

# Postrior predictives
extract(fit, c('cu'))$cu %>% as.tibble %>%
  rename(cu1 = V1, cu2 = V2, cu3 = V3) %>%
  gather(parameter, values) %>%
  ggplot(aes(parameter, values)) +
  geom_violin()

# Bayesplot stuff
color_scheme_set(scheme = "viridis")
mcmc_trace(extract(fit, permute = FALSE, inc_warmup = TRUE), c("c11", "c12"))
mcmc_intervals(extract(fit, permute = FALSE, inc_warmup = FALSE), pars = c("c11", "c12"))
mcmc_combo(extract(fit, permute = FALSE, inc_warmup = FALSE), pars = c("c11", "c12"))
mcmc_pairs(extract(fit, permute = FALSE, inc_warmup = FALSE), pars = c("c11", "a", "c44"))

#launch_shinystan(fit)

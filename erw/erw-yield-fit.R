
# ------------------------------------------------------------------------------
# erw-yield-fit.R
#
# Bayesian hierarchical regression of log(yield_with_basalt / yield_control)
# on application rate, baseline soil pH, climate, grain size, and crop type.
#
# Fitted on the manually-compiled trial dataset in erw-trial-data.csv.
#
# IMPORTANT — small-n caveat
# --------------------------
# The trial dataset is currently ~14 rows. This is not enough to identify all
# fixed effects independently; the posterior is heavily prior-dominated. The
# fit is still useful because:
#   (a) it gives an honest representation of uncertainty
#   (b) the prediction step can produce credible intervals
#   (c) the framework is in place — as more ERW field trials publish results
#       (and they are, rapidly), append rows to the CSV and re-run this script.
#
# References for the modelling choices:
#   Aramburu Merlos et al. 2023 Geoderma   — meta-regression structure
#   Beerling et al. 2018 Nat. Plants       — log-ratio response variable
#   Bürkner 2017 J. Stat. Software         — brms hierarchical modelling
#
# Inputs:
#   erw-trial-data.csv
#
# Outputs:
#   erw_yield_fit.rds        (brmsfit object — used by erw-yield-predict.R)
#   erw_yield_fit_summary.txt
#   erw_yield_fit_posterior.csv  (posterior draws, columns = coefficients)
# ------------------------------------------------------------------------------

input_path  <- 'D:/# Jvasco/Working Papers/GAIA Guiding Acid Soil Investments/1-ex-ante-analysis/input-data/'
output_path <- 'D:/# Jvasco/Working Papers/GAIA Guiding Acid Soil Investments/1-ex-ante-analysis/output-data/'

# ------------------------------------------------------------------------------
# 1) load trial data

trials <- read.csv('erw-trial-data.csv', stringsAsFactors = FALSE)

# light QC
trials <- subset(trials, !is.na(log_y_ratio) & !is.na(se_log_y_ratio) & !is.na(rate_t_ha))
trials$log_rate  <- log(trials$rate_t_ha)
trials$log_grain <- log(trials$grain_size_um)

cat('Loaded ', nrow(trials), ' trial rows across ', length(unique(trials$crop)),
    ' crops and ', length(unique(trials$site)), ' sites.\n', sep = '')
cat('Confidence breakdown:\n')
print(table(trials$confidence))

# ------------------------------------------------------------------------------
# 2) priors — weakly informative
#
# Defaults assume:
#   - small positive intercept (~10% uplift baseline)
#   - log(rate) coefficient ~ 0.05 per log unit (a doubling of rate → ~3.5% extra uplift)
#   - pH coefficient near zero (effect of unit pH change on log ratio)
#   - climate coefficients near zero per unit of MAT/MAP
#   - grain size: negative on log scale (finer grain = more uplift)

library(brms)

priors <- c(
  prior(normal(0.10, 0.20), class = "Intercept"),
  prior(normal(0.05, 0.05), class = "b", coef = "log_rate"),
  prior(normal(0.00, 0.05), class = "b", coef = "pH_baseline"),
  prior(normal(0.00, 0.005), class = "b", coef = "MAT_C"),
  prior(normal(0.00, 0.0005), class = "b", coef = "MAP_mm"),
  prior(normal(-0.05, 0.05), class = "b", coef = "log_grain"),
  prior(exponential(5), class = "sd")
)

# ------------------------------------------------------------------------------
# 3) fit
#
# Response is log_y_ratio with known standard error → measurement-error syntax
# via `se(se_log_y_ratio)`.

formula <- bf(
  log_y_ratio | se(se_log_y_ratio, sigma = TRUE) ~
    log_rate + pH_baseline + MAT_C + MAP_mm + log_grain +
    (1 | crop) + (1 | site)
)

fit <- brm(
  formula = formula,
  data    = trials,
  prior   = priors,
  chains  = 4,
  iter    = 4000,
  warmup  = 1500,
  cores   = 4,
  control = list(adapt_delta = 0.95),
  seed    = 42
)

# ------------------------------------------------------------------------------
# 4) persist

saveRDS(fit, paste0(input_path, 'erw_yield_fit.rds'))

sink(paste0(output_path, '/erw_yield_fit_summary.txt'))
print(summary(fit))
cat('\n\n--- crop-level random intercepts ---\n')
print(ranef(fit)$crop)
cat('\n\n--- site-level random intercepts ---\n')
print(ranef(fit)$site)
sink()

post <- as_draws_df(fit)
write.csv(post, paste0(output_path, '/erw_yield_fit_posterior.csv'), row.names = FALSE)

# ------------------------------------------------------------------------------
# 5) diagnostics — quick summary

cat('\n--- fixed-effect posterior summaries ---\n')
print(fixef(fit))

cat('\n--- posterior-predictive checks ---\n')
pp <- pp_check(fit, ndraws = 50)
print(pp)

# ------------------------------------------------------------------------------

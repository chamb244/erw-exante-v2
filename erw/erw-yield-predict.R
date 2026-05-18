
# ------------------------------------------------------------------------------
# erw-yield-predict.R
#
# Applies the brmsfit from erw-yield-fit.R to per-pixel covariates on the SSA
# working grid. Produces a per-crop yield-uplift raster that erw-7 can
# consume in place of (yield_level / yield_loss − yield_level) from EcoCrop.
#
# This v1 uses posterior means of the fixed effects + crop-level random
# intercepts (analytical prediction). It is fast and adequate for headline
# maps, but loses posterior uncertainty per pixel. For uncertainty maps,
# replace `predict_yield_ratio()` with a `posterior_epred()` loop over a
# manageable sample of draws.
#
# Inputs:
#   erw_yield_fit.rds                       (from erw-yield-fit.R)
#   soilgrids_properties_cropland.tif       (from erw-1, pH layer)
#   WorldClim MAT and MAP                   (via geodata or pre-saved)
#   basalt_feedstock_chemistry.csv          (grain_size_um)
#   basalt_merlos.tif                       (per-crop rate via TAS layer)
#
# Outputs:
#   erw_yield_uplift_{crop}_median.tif      yield ratio = y_treat / y_control
#   erw_yield_uplift_{crop}_p05.tif         5th percentile (from posterior_epred,
#                                            if uncertainty arm enabled)
#   erw_yield_uplift_{crop}_p95.tif         95th percentile
#
# erw-7 reads `erw_yield_uplift_{crop}_median.tif` if present; otherwise it
# falls back to the EcoCrop-derived yield-loss raster.
# ------------------------------------------------------------------------------

# directories — resolved from the project root via the {here} package
# (anchored by the .here marker at the repo root)
library(here)
input_path  <- paste0(here::here('data'), '/')
output_path <- paste0(here::here('data'), '/')

library(brms)

# ------------------------------------------------------------------------------
# 1) load the fit and extract coefficient summaries

fit  <- readRDS(paste0(input_path, 'erw_yield_fit.rds'))
fix  <- fixef(fit)                       # matrix: coef × {Estimate, Est.Error, Q2.5, Q97.5}
re_c <- ranef(fit)$crop                  # array: crop × {Est, Err, Q2.5, Q97.5} × Intercept

b <- list(
  Intercept   = fix['Intercept',  'Estimate'],
  log_rate    = fix['log_rate',   'Estimate'],
  pH_baseline = fix['pH_baseline','Estimate'],
  MAT_C       = fix['MAT_C',      'Estimate'],
  MAP_mm      = fix['MAP_mm',     'Estimate'],
  log_grain   = fix['log_grain',  'Estimate']
)

crop_intercept <- function(crop_id) {
  if (crop_id %in% dimnames(re_c)[[1]]) re_c[crop_id, 'Estimate', 'Intercept']
  else 0
}

cat('Fitted fixed effects:\n'); print(unlist(b))
cat('Crop-level random intercepts:\n'); print(re_c[, 'Estimate', 'Intercept'])

# ------------------------------------------------------------------------------
# 2) covariate rasters on the working grid

ref <- terra::rast(paste0(input_path, 'basalt_merlos.tif'))[[1]]

pH  <- terra::rast(paste0(input_path, 'soilgrids_properties_cropland.tif'))[[2]]
pH  <- terra::resample(pH, ref)
names(pH) <- 'pH_baseline'

mat_stack <- geodata::worldclim_global(var = 'tavg', res = 10, path = paste0(input_path, '/worldclim'))
MAT <- terra::mean(mat_stack)
MAT <- terra::resample(terra::crop(MAT, ref), ref)
names(MAT) <- 'MAT_C'

map_stack <- geodata::worldclim_global(var = 'prec', res = 10, path = paste0(input_path, '/worldclim'))
MAP <- sum(map_stack)
MAP <- terra::resample(terra::crop(MAP, ref), ref)
names(MAP) <- 'MAP_mm'

# grain size from erw-3 feedstock CSV
fs <- read.csv(paste0(input_path, 'basalt_feedstock_chemistry.csv'))
grain_size_um <- as.numeric(fs$value[fs$parameter == 'grain_size_um'])
log_grain     <- log(grain_size_um)

# ------------------------------------------------------------------------------
# 3) per-crop rate raster (from erw-3, selecting the TAS layer that matches
#    each crop's ac_sat tolerance — same logic as erw-7's bf() function)

basalt_targeted <- terra::rast(paste0(input_path, 'basalt_merlos.tif'))
crops_df <- read.csv(paste0(input_path, 'ecocrop_parameters_hp.csv'))[-c(1)]

# ------------------------------------------------------------------------------
# 4) prediction — analytical, using posterior-mean coefficients

predict_yield_ratio <- function(rate_raster, pH, MAT, MAP, log_grain, crop_id) {
  # log_y_ratio = β0 + β_log_rate · log(rate) + β_pH · pH + β_MAT · MAT
  #             + β_MAP · MAP + β_log_grain · log(grain) + α_crop
  log_rate <- terra::ifel(rate_raster > 0, log(rate_raster), NA)
  alpha    <- crop_intercept(crop_id)
  log_ratio <- b$Intercept + alpha +
               b$log_rate    * log_rate +
               b$pH_baseline * pH +
               b$MAT_C       * MAT +
               b$MAP_mm      * MAP +
               b$log_grain   * log_grain
  exp(log_ratio)   # yield ratio = y_treat / y_control
}

# ------------------------------------------------------------------------------
# 5) loop over crops

for (crop in unique(crops_df$spam)) {
  cat('predict ', crop, '\n', sep = '')
  c_subset  <- crops_df[crops_df$spam == crop, ]
  layer_idx <- grep(paste0('_', c_subset$ac_sat, '$'), names(basalt_targeted))
  if (length(layer_idx) == 0) next
  rate <- basalt_targeted[[layer_idx]]

  uplift <- predict_yield_ratio(rate, pH, MAT, MAP, log_grain, crop)
  names(uplift) <- 'yield_uplift_ratio'

  terra::writeRaster(uplift,
                     paste0(input_path, 'erw_yield_uplift_', crop, '_median.tif'),
                     overwrite = TRUE)
}

# ------------------------------------------------------------------------------
# 6) optional: uncertainty arm via posterior_epred
# Uncomment to enable. WARNING: 4000 draws × ~1M pixels × 23 crops is slow.
#
# DRAWS <- 100   # sub-sample of posterior
# post <- as_draws_df(fit)
# idx  <- sample(nrow(post), DRAWS)
# (... loop, accumulating per-pixel quantiles ...)
# Persist as erw_yield_uplift_{crop}_p05.tif and _p95.tif.

# ------------------------------------------------------------------------------

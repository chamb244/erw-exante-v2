
# ------------------------------------------------------------------------------
# erw-5-crop-yield-loss-function.R
#
# Run Recocrop::ecocrop per crop x response (pH and acidity saturation) on the
# cropland-masked soil stack to produce relative-yield rasters, clamped to
# [0.2, 1]. erw-7 falls back to these rasters when the trial-calibrated yield
# uplift rasters from erw-yield-predict are not present.
#
# Inputs (from erw-1, erw-4):
#   soilgrids_properties_cropland.tif  (pH and hp_sat layers)
#   ecocrop_parameters_ph.csv
#   ecocrop_parameters_hp.csv
#
# Outputs:
#   ecocrop_f/{hp,ph}_crop_suitability_{crop}_0.tif   (23 crops x 2 responses)
# ------------------------------------------------------------------------------

# directories — resolved from the project root via the {here} package
# (anchored by the .here marker at the repo root)
library(here)
input_path  <- paste0(here::here('data'), '/')
output_path <- paste0(here::here('data'), '/')

# ------------------------------------------------------------------------------

# soil-grids
sprops_cropland <- terra::rast(paste0(input_path, 'soilgrids_properties_cropland.tif'))
sprops_cropland <- sprops_cropland[[c(2, 10)]]
names(sprops_cropland) <- c("ph", "hp")

# crops
crops_df <- read.csv(paste0(input_path, 'ecocrop_parameters_hp.csv'))

# ------------------------------------------------------------------------------

# yield-loss-function
ecocrop_f <- function(crop, response, properties, parameter=0) {
  crops_df <- read.csv(paste0(input_path, 'ecocrop_parameters_', response, '.csv'))
  subset_crops <- subset(crops_df, spam == crop)
  ecocrop_crop <- Recocrop::ecocropPars(subset_crops$ecocrop)
  sprop <- properties[[response]]
  if(response == 'hp'){
    svar <- "max_ac_sat"
    p <- subset_crops[[svar]]
    pars1 <- c(-Inf, -Inf, subset_crops$ac_sat, max_ac_sat=p)
  } else { # ph
    svar <- "min_ph"
    p <- subset_crops[[svar]]
    pars1 <- c(min_ph=p, subset_crops$max_ph, Inf, Inf)
  }
  pars <- pars1
  pars[[svar]] <- pars1[[svar]] - parameter
  ecocrop_crop$parameters <- cbind(ecocrop_crop$parameters, pars)
  colnames(ecocrop_crop$parameters)[6] <- "response"
  model <- Recocrop::ecocrop(ecocrop_crop)
  Recocrop::control(model, get_max=T)
  yield_loss <- Recocrop::predict(model, response=sprop)
  yield_loss <- terra::clamp(yield_loss, 0.2, 1)
  names(yield_loss) <- paste0(crop, '_', response)
  return(yield_loss)
}

# ------------------------------------------------------------------------------

# run
param <- 0
for(crop in unique(crops_df$spam)){
  for(resp in c('hp', 'ph')){
    print(paste0(crop, '_', resp))
    yield_loss <- ecocrop_f(crop=crop, response=resp, properties=sprops_cropland, parameter=param)
    terra::writeRaster(yield_loss, paste0(input_path, '/ecocrop_f/', resp, '_crop_suitability_', crop, '_', param, '.tif'), overwrite=T)
  }
}

# ------------------------------------------------------------------------------

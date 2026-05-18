
# ------------------------------------------------------------------------------
# erw-2-layers-spam.R
#
# Pull SPAM v2 (Africa) harvested area, production, and yield for 23 SPAM crops,
# crop to SSA, resample to the soilgrids working grid (aggregated 10x).
#
# Inputs (from erw-1):
#   gadm_ssa.gpkg
#   soilgrids_properties_all.tif   (reference grid)
#
# Outputs:
#   spam_harv_area_processed.tif
#   spam_prod_processed.tif
#   spam_yield_processed.tif
# ------------------------------------------------------------------------------

# directories — resolved from the project root via the {here} package
# (anchored by the .here marker at the repo root)
library(here)
input_path <- paste0(here::here('data'), '/')

# ------------------------------------------------------------------------------

# regions
ssa <- terra::vect(paste0(input_path, 'gadm_ssa.gpkg'))

# soils (working grid: aggregate the soilgrids ref by 10x)
ref <- terra::rast(paste0(input_path, 'soilgrids_properties_all.tif'))[[1]]
ref <- terra::aggregate(ref, 10, 'mean', na.rm=T)

# crops
spam <- c('MAIZ', 'SORG', 'BEAN', 'CHIC', 'LENT', 'WHEA', 'BARL', 'ACOF', 'RCOF', 'PMIL', 'SMIL', 'POTA',
          'SWPO', 'CASS', 'COWP', 'PIGE', 'SOYB', 'GROU', 'SUGC', 'COTT', 'COCO', 'TEAS', 'TOBA')

# pull, crop, resample
for(sv in c('harv_area', 'prod', 'yield')){
  print(sv)
  variable <- lapply(spam, function(crop){geodata::crop_spam(crop, sv, path=input_path)[[1]]})
  variable <- terra::rast(variable)
  names(variable) <- spam
  variable <- terra::mask(terra::crop(variable, ssa), ssa)
  variable <- terra::resample(variable, ref)
  terra::writeRaster(variable, paste0(input_path, 'spam_', sv, '_processed.tif'), overwrite=T)
  }

# ------------------------------------------------------------------------------

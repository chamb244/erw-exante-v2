
# ------------------------------------------------------------------------------
# erw-1-layers-soilgrids.R
#
# Build SSA mask, pull SoilGrids depth-weighted soil properties (pH, bulk
# density, exchangeable acidity, K/Ca/Mg/Na bases) and a QED cropland mask,
# derive ECEC and acidity saturation, mask to cropland.
#
# Inputs (downloaded):
#   GADM v4 world (geodata::world)
#   QED cropland mask (geodata::cropland)
#   SoilGrids Africa (geodata::soil_af): BLKD, pH, acid-exch at 5/15/30 cm;
#                                        K/Ca/Mg/Na-exch at 20 cm
#
# Outputs:
#   gadm_ssa.gpkg                       SSA admin boundaries
#   geosurvey_processed.tif             cropland mask (1/NA, > 0.1 fraction)
#   soilgrids_properties_all.tif        per-pixel soil stack (SBD, pH, hp,
#                                       K/Ca/Mg/Na, bases, ECEC, hp_sat)
#   soilgrids_properties_cropland.tif   same masked to cropland
# ------------------------------------------------------------------------------

# directories
input_path <- 'D:/# Jvasco/Working Papers/GAIA Guiding Acid Soil Investments/1-ex-ante-analysis/input-data/'

# ------------------------------------------------------------------------------

# sub-saharan africa
country <- geodata::world(path=input_path, resolution=5, level=0)
isocodes <- geodata::country_codes()
isocodes_ssa <- subset(isocodes, NAME=='Sudan' | UNREGION1=='Middle Africa' | UNREGION1=='Western Africa' | UNREGION1=='Southern Africa' | UNREGION1=='Eastern Africa')
isocodes_ssa <- subset(isocodes_ssa, NAME!='Cabo Verde' & NAME!='Comoros' & NAME!='Mauritius' & NAME!='Mayotte' & NAME!='Réunion' & NAME!='Saint Helena' & NAME!='São Tomé and Príncipe' & NAME!='Seychelles')
ssa <- subset(country, country$GID_0 %in% isocodes_ssa$ISO3)
terra::writeVector(ssa, paste0(input_path, 'gadm_ssa.gpkg'), overwrite=T)

# ------------------------------------------------------------------------------

# geosurvey (QED cropland)
geosurvey <- geodata::cropland(source='QED', path=paste0(input_path))
geosurvey <- terra::mask(terra::crop(geosurvey, ssa), ssa)
m <- c(0, 0.1, NA, 0.1, 1, 1)
rclmat <- matrix(m, ncol=3, byrow=TRUE)
geosurvey <- terra::classify(geosurvey, rclmat)
terra::writeRaster(geosurvey, paste0(input_path, 'geosurvey_processed.tif'), overwrite=T)

# soil properties — depth-weighted average of 5/15/30 cm
props_d <- lapply(c('BLKD', 'pH', 'acid-exch'), function(sv) {
  prop5  <- geodata::soil_af(var=sv, depth=5 , path=paste0(input_path, '/soilgrids'))
  prop15 <- geodata::soil_af(var=sv, depth=15, path=paste0(input_path, '/soilgrids'))
  prop30 <- geodata::soil_af(var=sv, depth=30, path=paste0(input_path, '/soilgrids'))
  prop <- (5 * prop5 + 10 * prop15 + 15 * prop30) / 30
  props <- terra::mask(terra::crop(prop, ssa), ssa)
  props})
props <- terra::rast(props_d)
names(props) <- c('SBD', 'ph', 'hp')
props$SBD <- props$SBD / 1000

# exchangeable bases at 20 cm
bases_d <- lapply(c('K-exch', 'Ca-exch', 'Mg-exch', 'Na-exch'), function(sv) {
	bases <- geodata::soil_af(var=sv, depth=20 , path=paste0(input_path, '/soilgrids'))
	bases <- terra::mask(terra::crop(bases, ssa), ssa)
	bases})
bases <- terra::rast(bases_d)
names(bases) <- c('k', 'ca', 'mg', 'na')
bases$bases <- sum(bases)

# ------------------------------------------------------------------------------

# combined layers + derived ECEC and acidity-saturation
p <- c(props, bases)
p$ecec <- p$hp + p$bases
p$hp_sat <- 100 * p$hp / p$ecec
terra::writeRaster(p, paste0(input_path, 'soilgrids_properties_all.tif'), overwrite=T)

# cropland-masked variant
p_cropland <- p * geosurvey
terra::writeRaster(p_cropland, paste0(input_path, 'soilgrids_properties_cropland.tif'), overwrite=T)

# ------------------------------------------------------------------------------

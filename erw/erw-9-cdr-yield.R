
# ------------------------------------------------------------------------------
# erw-9-cdr-yield.R
#
# Spatially-explicit CDR yield (t CO2/ha cumulative) per pixel. Combines:
#   - erw-3's per-tonne CDR potential at the reference climate (which already
#     bakes in grain size and the Lewis-2021-calibrated reactive fraction)
#   - a climate-and-pH scaling factor anchored to a temperate reference site
#
# The climate factor below is a v1 empirical proxy, not a process model.
# Replace with a reactive-transport surrogate when calibration data allows
# (Kanzaki et al. 2024 Nature; Beerling et al. 2020 Nature).
#
# Inputs:
#   basalt_merlos.tif, basalt_merlos_maintenance.tif      (from erw-3, targeted)
#   basalt_uniform_{10,20,50}.tif                          (from erw-3, uniform)
#   basalt_feedstock_chemistry.csv                         (from erw-3 — has
#                                                           CDR_eff_kg_per_t_ref)
#   soilgrids_properties_cropland.tif                      (from erw-1, pH layer)
#   WorldClim MAT and MAP                                  (via geodata)
#
# Outputs:
#   cdr_climate_factor.tif
#   cdr_per_t_basalt.tif                                   (kg CO2 / t basalt per pixel)
#   cdr_yield_merlos.tif, cdr_yield_merlos_maintenance.tif (targeted, t CO2/ha)
#   cdr_yield_uniform_{10,20,50}.tif                       (uniform, t CO2/ha)
# ------------------------------------------------------------------------------

# directories
input_path  <- 'D:/# Jvasco/Working Papers/GAIA Guiding Acid Soil Investments/1-ex-ante-analysis/input-data/'
output_path <- 'D:/# Jvasco/Working Papers/GAIA Guiding Acid Soil Investments/1-ex-ante-analysis/output-data/'

# ------------------------------------------------------------------------------
# 1) feedstock constants (includes grain-size factor + Lewis-calibrated NV)

fs <- read.csv(paste0(input_path, 'basalt_feedstock_chemistry.csv'))
get_fs <- function(p) as.numeric(fs$value[fs$parameter == p])

cdr_max_per_t_basalt   <- get_fs('CDR_max_kg_per_t')
cdr_eff_per_t_basalt   <- get_fs('CDR_eff_kg_per_t_ref')   # already × grain × reactivity
reactive_fraction_ref  <- get_fs('reactive_fraction_ref')
grain_size_factor      <- get_fs('grain_size_factor')

# baseline reactive fraction baked into cdr_eff (at reference grain × reactivity)
# climate scaling below is multiplicative on top of this baseline.
ref_reactive_fraction <- reactive_fraction_ref * grain_size_factor

# ------------------------------------------------------------------------------
# 2) basalt application-rate rasters

basalt_targeted     <- terra::rast(paste0(input_path, 'basalt_merlos.tif'))
basalt_targeted_m   <- terra::rast(paste0(input_path, 'basalt_merlos_maintenance.tif'))
basalt_uniform_10   <- terra::rast(paste0(input_path, 'basalt_uniform_10.tif'))
basalt_uniform_20   <- terra::rast(paste0(input_path, 'basalt_uniform_20.tif'))
basalt_uniform_50   <- terra::rast(paste0(input_path, 'basalt_uniform_50.tif'))

# soil pH (cropland-masked)
ph <- terra::rast(paste0(input_path, 'soilgrids_properties_cropland.tif'))[[2]]
names(ph) <- 'ph'

# climate: WorldClim 10' grids
mat_stack <- geodata::worldclim_global(var='tavg', res=10, path=paste0(input_path, '/worldclim'))
mat <- terra::mean(mat_stack); names(mat) <- 'MAT'
map_stack <- geodata::worldclim_global(var='prec', res=10, path=paste0(input_path, '/worldclim'))
map_yr <- sum(map_stack); names(map_yr) <- 'MAP'

# align everything to the working grid
ref    <- basalt_targeted[[1]]
mat    <- terra::resample(terra::crop(mat,    ref), ref)
map_yr <- terra::resample(terra::crop(map_yr, ref), ref)
ph     <- terra::resample(ph, ref)

# ------------------------------------------------------------------------------
# 3) climate factor (dimensionless multiplier on the reference reactive fraction)
#
# Form: f_climate = clamp(MAT/T_ref) * clamp(MAP/P_ref) * f_pH
# Reference: T_ref = 11 °C, P_ref = 1000 mm (US Corn Belt). Tropical sites with
# MAT ~25 °C and MAP ~1500 mm push f_climate toward ~3, consistent with the
# Kisumu and InPlanet field rates.

T_ref <- 11
P_ref <- 1000

f_mat <- terra::clamp(mat    / T_ref, 0.3, 3.0); names(f_mat) <- 'f_MAT'
f_map <- terra::clamp(map_yr / P_ref, 0.3, 3.0); names(f_map) <- 'f_MAP'

# triangular pH factor peaking at pH ~5.0
f_ph <- terra::ifel(ph < 4.0, 0.5,
        terra::ifel(ph < 5.0, 0.5 + (ph - 4.0) * 0.5,
        terra::ifel(ph < 7.0, 1.0 - (ph - 5.0) * 0.25,
                              0.5)))
names(f_ph) <- 'f_pH'

climate_factor <- f_mat * f_map * f_ph
names(climate_factor) <- 'climate_factor'
terra::writeRaster(climate_factor, paste0(input_path, 'cdr_climate_factor.tif'), overwrite=T)

# ------------------------------------------------------------------------------
# 3b) pedogenic-carbonate fraction
#
# In semi-arid soils, a substantial fraction of the alkalinity released by
# silicate dissolution precipitates locally as CaCO3 / MgCO3 rather than
# exporting to the ocean as bicarbonate. CaCO3 precipitation releases the
# CO2 that the silicate originally consumed, so this fraction must be
# deducted from gross CDR.
#
# References: Beerling et al. (2020) Nature SI; Renforth (2019) Nature
# Communications; Kanzaki et al. (2024) Nature; Frontiers in Climate (2024)
# "Are ERW rates overestimated?".
#
# Empirical proxy: fraction precipitated scales with aridity. Anchored to
# typical SSA conditions. Replace with CGIAR-CSI Global Aridity Index
# (P/PET) for production runs.

# Aridity-index categories (UNEP 1992):
#   hyperarid     AI < 0.05   → ~90% precipitation
#   arid          AI 0.05–0.20 → ~70%
#   semi-arid     AI 0.20–0.50 → ~40%
#   dry sub-humid AI 0.50–0.65 → ~15%
#   humid         AI > 0.65    → ~0%
# Using MAP alone as a crude AI proxy in SSA (MAP=600mm ≈ AI 0.65 typical;
# MAP=120mm ≈ hyperarid). This breaks down in cool highlands where PET is
# low — accept the approximation for v1.

pedogenic_frac <- terra::ifel(map_yr < 120, 0.90,
                  terra::ifel(map_yr < 300, 0.70,
                  terra::ifel(map_yr < 500, 0.40,
                  terra::ifel(map_yr < 600, 0.15,
                                            0.00))))
names(pedogenic_frac) <- 'pedogenic_fraction'
terra::writeRaster(pedogenic_frac, paste0(input_path, 'cdr_pedogenic_fraction.tif'), overwrite=T)

# exported fraction = (1 - pedogenic_fraction)
exported_fraction <- 1 - pedogenic_frac
names(exported_fraction) <- 'exported_fraction'

# ------------------------------------------------------------------------------
# 4) per-pixel effective reactive fraction and CDR per tonne basalt

# total reactive fraction = reference (already × grain) × climate
# capped at 1 because nothing can be more than 100% reacted
reactive_fraction_eff <- terra::clamp(ref_reactive_fraction * climate_factor, 0, 1)

# CDR per tonne of basalt at each pixel
# = stoichiometric ceiling × effective reactive fraction × exported fraction
# (last term deducts pedogenic carbonate precipitated rather than exported)
cdr_per_t_basalt_px <- reactive_fraction_eff * cdr_max_per_t_basalt * exported_fraction
names(cdr_per_t_basalt_px) <- 'cdr_kg_per_t_basalt'
terra::writeRaster(cdr_per_t_basalt_px, paste0(input_path, 'cdr_per_t_basalt.tif'), overwrite=T)

# ------------------------------------------------------------------------------
# 5) CDR yield rasters (t CO2/ha cumulative over project horizon)

write_cdr <- function(basalt_raster, name) {
  cdr <- basalt_raster * (cdr_per_t_basalt_px / 1000)
  names(cdr) <- names(basalt_raster)
  terra::writeRaster(cdr, paste0(input_path, name, '.tif'), overwrite=T)
  cdr
}

cdr_yield_merlos             <- write_cdr(basalt_targeted,   'cdr_yield_merlos')
cdr_yield_merlos_maintenance <- write_cdr(basalt_targeted_m, 'cdr_yield_merlos_maintenance')
cdr_yield_uniform_10         <- write_cdr(basalt_uniform_10, 'cdr_yield_uniform_10')
cdr_yield_uniform_20         <- write_cdr(basalt_uniform_20, 'cdr_yield_uniform_20')
cdr_yield_uniform_50         <- write_cdr(basalt_uniform_50, 'cdr_yield_uniform_50')

# ------------------------------------------------------------------------------
# 6) diagnostics

cat('\n--- CDR yield summary (t CO2/ha cumulative, project horizon) ---\n')
cat('Reference reactive fraction (grain × reactivity, pre-climate):',
    round(ref_reactive_fraction, 3), '\n')
cat('Targeted (merlos):\n')
print(terra::global(cdr_yield_merlos, fun=c('mean','min','max'), na.rm=TRUE))
cat('Uniform 20 t/ha:\n')
print(terra::global(cdr_yield_uniform_20, fun=c('mean','min','max'), na.rm=TRUE))

# ------------------------------------------------------------------------------

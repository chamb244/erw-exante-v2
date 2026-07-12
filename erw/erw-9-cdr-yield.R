
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

# directories — resolved from the project root via the {here} package
# (anchored by the .here marker at the repo root)
library(here)
input_path  <- paste0(here::here('data'), '/')
output_path <- paste0(here::here('data'), '/')

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

# Temperature response of gross weathering. Default "linear" (MAT/T_ref).
# "arrhenius" uses the standard kinetic form exp(-Ea/R (1/T - 1/T_ref)) with a
# silicate activation energy Ea = 68.8 kJ/mol (White & Blum 1995) -- the same
# value Cascade Climate's Weathering Potential Explorer uses. Both are normalized
# to f = 1 at T_ref and clamped to [0.3, 3.0] for comparability. The Arrhenius
# form is steeper in temperature and, area-weighted, raises SSA gross CDR by
# ~27% (capped) over the linear default. Carried as a SENSITIVITY VARIANT: for
# the analytic sweep in erw-11/erw-12, pass the pre-computed per-pixel multiplier
# data/cdr_climate_arrhenius_multiplier.tif (= f_arr/f_lin) as `rmult` to cdr_net()
# instead of re-running this script. See paper/analysis/erw_arrhenius_variant.py
# and paper/cascade-comparison-memo.md.
CLIMATE_TEMP_MODE <- "linear"          # "linear" | "arrhenius"
Ea <- 68800; Rgas <- 8.314             # J/mol ; J/mol/K
if (CLIMATE_TEMP_MODE == "arrhenius") {
  f_mat <- exp(-(Ea / Rgas) * (1 / (mat + 273.15) - 1 / (T_ref + 273.15)))
  f_mat <- terra::clamp(f_mat, 0.3, 3.0)
} else {
  f_mat <- terra::clamp(mat / T_ref, 0.3, 3.0)
}
names(f_mat) <- 'f_MAT'
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
#
# Preferred: CGIAR-CSI Global Aridity Index (AI = MAP / PET) at 1 km,
# Zomer et al. 2022 (https://doi.org/10.6084/m9.figshare.7504448). Place
# the raster at data/cgiar_aridity_index.tif. CGIAR ships AI × 10 000 as
# integer; this block auto-detects the scaling and divides if needed.
# Fallback when the AI raster is absent: MAP-only proxy. The proxy
# over-deducts in cool highlands (Ethiopian/Kenyan highlands, Rwanda,
# Burundi, Lesotho) where low PET keeps the true AI in the humid band
# even at modest MAP — replace by downloading the CGIAR file.

# Accept any of the common CGIAR-CSI file names so users can drop in the raw
# Figshare download without renaming.
ai_candidates <- c(
  paste0(input_path, 'cgiar_aridity_index.tif'),
  paste0(input_path, 'ai_v31_yr.tif'),
  paste0(input_path, 'ai_v3_yr.tif')
)
ai_path <- ai_candidates[file.exists(ai_candidates)][1]
if (!is.na(ai_path)) {
  ai <- terra::rast(ai_path)
  ai <- terra::resample(terra::crop(ai, ref), ref)
  # CGIAR ships INT2U with 65535 as the 16-bit nodata sentinel. terra picks
  # the GDAL NAflag automatically when present, but the v3.1 distribution
  # does not set it, so we mask explicitly. Values > 32767 are
  # treated as nodata to also catch any near-sentinel encoding.
  ai <- terra::ifel(ai >= 32767, NA, ai)
  ai_max <- terra::global(ai, fun='max', na.rm=TRUE)$max
  if (!is.na(ai_max) && ai_max > 10) ai <- ai / 10000   # CGIAR integer-scaled
  names(ai) <- 'aridity_index'
  pedogenic_frac <- terra::ifel(ai < 0.05, 0.90,
                    terra::ifel(ai < 0.20, 0.70,
                    terra::ifel(ai < 0.50, 0.40,
                    terra::ifel(ai < 0.65, 0.15,
                                           0.00))))
  cat('Pedogenic deduction: using CGIAR-CSI Global Aridity Index (AI = MAP/PET)\n')
} else {
  pedogenic_frac <- terra::ifel(map_yr < 120, 0.90,
                    terra::ifel(map_yr < 300, 0.70,
                    terra::ifel(map_yr < 500, 0.40,
                    terra::ifel(map_yr < 600, 0.15,
                                              0.00))))
  cat('Pedogenic deduction: CGIAR AI raster not found at ', ai_path,
      ' — falling back to MAP-only proxy. Download AI from ',
      'https://doi.org/10.6084/m9.figshare.7504448 for a better deduction.\n',
      sep = '')
}
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
# 5b) NET-EXPORT CDR (deduct alkalinity consumed neutralizing soil acidity)
#
# The alkalinity released by weathering can either neutralize soil acidity
# (raising pH -- the agronomic/private benefit) OR export as bicarbonate to the
# ocean (durable CDR). It cannot do both. Alkalinity that neutralizes
# exchangeable acidity re-releases the captured CO2 (HCO3- + H+ -> H2O + CO2,
# with protons supplied by Al3+ hydrolysis) -- exactly as agricultural lime does,
# which is why lime is not a CDR technology. Durable CDR is therefore only the
# alkalinity that exports BEYOND the soil's acidity demand:
#
#     net_export_CDR = max(gross_CDR - F * acidity_sink, 0)
#
#   F = CO2 re-released per t CaCO3-eq of acidity neutralized
#     = cdr_eff_per_t_basalt / (effective_NV * 1000)   (feedstock chemistry; ~0.88)
#   acidity_sink (t CaCO3/ha) = lime requirement from erw-3:
#     year-1 doses -> standing exchangeable acidity   (caco3_kamprath)
#     maintenance  -> annual re-acidification          (caco3_merlos_maintenance)
#
# NOTE: first-order (sequential) bound -- assumes the acidity sink is filled
# before any alkalinity exports. The truth lies between this and the gross CDR
# above; durable CDR is therefore mostly an equilibrium/maintenance phenomenon.
# erw-7 can consume either the gross (cdr_yield_*) or net (cdr_yield_*_netexport)
# rasters; the latter is the recommended default for the carbon (public) case.
# ------------------------------------------------------------------------------

effective_NV_value <- get_fs('effective_NV')
F_CO2_PER_CACO3    <- cdr_eff_per_t_basalt / (effective_NV_value * 1000)
cat('Net-export F (CO2 re-released per t CaCO3-eq neutralized):',
    round(F_CO2_PER_CACO3, 3), '\n')

acidity_standing <- terra::rast(paste0(input_path, 'caco3_kamprath.tif'))
acidity_maint    <- terra::rast(paste0(input_path, 'caco3_merlos_maintenance.tif'))[[1]]

net_export <- function(cdr_gross, sink, name) {
  s   <- terra::resample(sink, cdr_gross)
  s   <- terra::ifel(is.na(s), 0, s)
  net <- cdr_gross - F_CO2_PER_CACO3 * s
  net <- terra::ifel(net < 0, 0, net)
  names(net) <- names(cdr_gross)
  terra::writeRaster(net, paste0(input_path, name, '.tif'), overwrite = TRUE)
  net
}

net_export(cdr_yield_merlos,             acidity_standing, 'cdr_yield_merlos_netexport')
net_export(cdr_yield_merlos_maintenance, acidity_maint,    'cdr_yield_merlos_maintenance_netexport')
net_export(cdr_yield_uniform_10,         acidity_standing, 'cdr_yield_uniform_10_netexport')
net_export(cdr_yield_uniform_20,         acidity_standing, 'cdr_yield_uniform_20_netexport')
net_export(cdr_yield_uniform_50,         acidity_standing, 'cdr_yield_uniform_50_netexport')

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

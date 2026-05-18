
# ------------------------------------------------------------------------------
# erw-3-basalt-requirements.R
#
# Computes lime-equivalent CaCO3 rates (Kamprath / Cochrane / Aramburu-Merlos
# LiTAS year-1 and maintenance) directly from the cropland-masked soil stack,
# then converts to basalt application rates and per-tonne CDR potential with
# grain size as a decision variable. Produces both LiTAS-targeted rates (the
# agronomically-targeted approach) and uniform-rate rasters at 10/20/50 t/ha
# (the standard assumption in ERW modelling).
#
# Key references:
#   Lewis et al. (2021) Effects of basalt mineralogy on CDR via enhanced
#     weathering, Applied Geochemistry. Anchors the effective neutralising
#     fraction for crushed basalt — reports CDR of 1.3–8.5 t CO2/ha over 15 yr
#     at 50 t/ha (i.e. 26–170 kg CO2 / t basalt actually realised, far below
#     the stoichiometric maximum).
#   Aramburu Merlos et al. (2023) Estimating lime requirements for tropical
#     soils, Geoderma — the LiTAS method.
#   Aramburu Merlos et al. (2025) Soil acidity remediation in SSA requires
#     targeted investments, Nature Food — argues for spatially-targeted
#     application; motivation for keeping the LiTAS branch.
#   Beerling et al. (2020), Baek et al. (2023), Kantola et al. (2024) all use
#     uniform 10–50 t/ha for global / regional ERW modelling — motivation for
#     the uniform-rate branch.
#   Strefler et al. (2018) Potential and costs of CDR by enhanced weathering,
#     ERL — grinding-energy curve (0.07 GJ/t @ 50 µm → 3 GJ/t @ 2 µm) used to
#     parameterise the grain-size cost lever.
#
# Inputs (from erw-1, erw-2):
#   soilgrids_properties_cropland.tif
#   spam_harv_area_processed.tif
#
# Outputs:
#   caco3_kamprath.tif, caco3_cochrane.tif,
#   caco3_merlos.tif, caco3_merlos_maintenance.tif           (lime-equivalent CaCO3, t/ha)
#   basalt_kamprath.tif, basalt_cochrane.tif,
#   basalt_merlos.tif, basalt_merlos_maintenance.tif         (targeted, t basalt/ha)
#   basalt_uniform_10.tif, basalt_uniform_20.tif, basalt_uniform_50.tif (cropland-masked constants)
#   basalt_feedstock_chemistry.csv                            (constants for downstream scripts)
#   cdr_const_targeted.tif                                    (cumulative CDR at reference climate, targeted)
# ------------------------------------------------------------------------------

# directories — resolved from the project root via the {here} package
# (anchored by the .here marker at the repo root)
library(here)
input_path  <- paste0(here::here('data'), '/')
output_path <- paste0(here::here('data'), '/')

# ------------------------------------------------------------------------------
# 1) feedstock chemistry — representative tropical basalt fines
# Override per-quarry once erw-basalt-access has quarry-specific chemistry.

basalt <- list(
  CaO_frac  = 0.10,                 # 10% CaO by mass
  MgO_frac  = 0.07,                 # 7% MgO by mass
  K2O_frac  = 0.015,
  Na2O_frac = 0.025,
  P2O5_frac = 0.003,
  Ni_ppm    = 100,
  Cr_ppm    = 200,

  # grain-size lever (the dominant decision variable in ERW economics)
  grain_size_um = 100,              # default — moderate cost, moderate reactivity

  # Lewis-2021-calibrated effective neutralising fraction at the reference
  # grain size (100 µm) and reference climate (Corn Belt). Tropical climate
  # and finer grain push this up via erw-9 and the grain-size factor.
  # Lewis 2021 midpoint: ~80 kg CO2/t basalt at 50 t/ha over 15 yr in a
  # temperate humid forest → effective_NV ~ 0.20 of stoichiometric.
  reactive_fraction_ref = 0.20,

  project_horizon_yr = 5
)

# ------------------------------------------------------------------------------
# 2) derived: theoretical CCE and stoichiometric CDR ceiling

# 1 g CaO neutralises 100/56.08 = 1.783 g CaCO3-equivalent acidity
# 1 g MgO neutralises 100/40.30 = 2.481 g CaCO3-equivalent acidity
cce_theoretical <- with(basalt, CaO_frac * (100/56.08) + MgO_frac * (100/40.30))

# theoretical max CDR per tonne of basalt — 1 mol divalent cation consumes 2 mol CO2
# 1 g CaO removes (2 * 44.01) / 56.08 = 1.570 g CO2
# 1 g MgO removes (2 * 44.01) / 40.30 = 2.185 g CO2
cdr_max_per_t_basalt <- with(basalt,
  (CaO_frac * (2*44.01)/56.08 + MgO_frac * (2*44.01)/40.30) * 1000
)   # kg CO2 / t basalt (stoichiometric ceiling)

# ------------------------------------------------------------------------------
# 3) grain-size factor (reactivity scaling)
# Empirical surface-area effect: silt-dominated basalts (<45 µm) weather at
# ~2× the rate of sand-dominated (150–500 µm) — implies an exponent β ~ 0.35–0.5
# on (ref/d). Use β = 0.5 (square-root of surface area) as a defensible
# midpoint; this is parameter-free given the reference grain size.

GRAIN_REF_UM <- 100
GRAIN_BETA   <- 0.5
grain_size_factor <- (GRAIN_REF_UM / basalt$grain_size_um)^GRAIN_BETA

cat('Grain size:           ', basalt$grain_size_um, 'µm\n')
cat('Grain-size factor:    ', round(grain_size_factor, 3),
    '(× rate vs', GRAIN_REF_UM, 'µm reference)\n')

# ------------------------------------------------------------------------------
# 4) grain-size cost lever — grinding energy and electricity cost
# Strefler 2018: E(50 µm) ~ 0.07 GJ/t, E(2 µm) ~ 3 GJ/t.
# Fit a power law E(d) = E_ref × (d_ref / d)^α with α = 1.2.

GRIND_REF_UM <- 50
GRIND_REF_GJ <- 0.07
GRIND_ALPHA  <- 1.2
ELECTRICITY_USD_KWH <- 0.10    # global default; override per-country in erw-7

grinding_GJ_per_t  <- GRIND_REF_GJ * (GRIND_REF_UM / basalt$grain_size_um)^GRIND_ALPHA
grinding_kWh_per_t <- grinding_GJ_per_t * 277.78
grinding_usd_per_t <- grinding_kWh_per_t * ELECTRICITY_USD_KWH

cat('Grinding energy:      ', round(grinding_GJ_per_t, 3), 'GJ/t (',
    round(grinding_kWh_per_t, 1), 'kWh/t)\n')
cat('Grinding cost:        $', round(grinding_usd_per_t, 2), '/t at $',
    ELECTRICITY_USD_KWH, '/kWh\n', sep='')

# ------------------------------------------------------------------------------
# 5) effective neutralising value (per-tonne basalt, at reference climate)

effective_NV         <- cce_theoretical * basalt$reactive_fraction_ref * grain_size_factor
basalt_per_lime      <- 1 / effective_NV
cdr_eff_per_t_basalt <- cdr_max_per_t_basalt * basalt$reactive_fraction_ref * grain_size_factor

cat('Theoretical CCE:      ', round(cce_theoretical, 3), '\n')
cat('Effective NV (ref):   ', round(effective_NV, 3), '\n')
cat('Basalt-to-lime:       ', round(basalt_per_lime, 2), 't basalt / t CaCO3-eq\n')
cat('Theoretical max CDR:  ', round(cdr_max_per_t_basalt),
    'kg CO2 / t basalt (stoichiometric ceiling)\n')
cat('Effective CDR (ref):  ', round(cdr_eff_per_t_basalt),
    'kg CO2 / t basalt (per Lewis 2021, before per-pixel climate scaling)\n')

# ------------------------------------------------------------------------------
# 6) persist feedstock + decision variables for downstream scripts

feedstock_df <- data.frame(
  parameter = c('CaO_frac', 'MgO_frac', 'K2O_frac', 'Na2O_frac', 'P2O5_frac',
                'Ni_ppm', 'Cr_ppm',
                'grain_size_um', 'grain_size_factor',
                'reactive_fraction_ref', 'project_horizon_yr',
                'CCE_theoretical', 'effective_NV',
                'basalt_per_lime_t_t',
                'CDR_max_kg_per_t', 'CDR_eff_kg_per_t_ref',
                'grinding_GJ_per_t', 'grinding_kWh_per_t',
                'grinding_usd_per_t_at_ref_electricity', 'electricity_usd_kWh_ref'),
  value = c(basalt$CaO_frac, basalt$MgO_frac, basalt$K2O_frac, basalt$Na2O_frac, basalt$P2O5_frac,
            basalt$Ni_ppm, basalt$Cr_ppm,
            basalt$grain_size_um, grain_size_factor,
            basalt$reactive_fraction_ref, basalt$project_horizon_yr,
            cce_theoretical, effective_NV,
            basalt_per_lime,
            cdr_max_per_t_basalt, cdr_eff_per_t_basalt,
            grinding_GJ_per_t, grinding_kWh_per_t,
            grinding_usd_per_t, ELECTRICITY_USD_KWH)
)
write.csv(feedstock_df, paste0(input_path, 'basalt_feedstock_chemistry.csv'), row.names=FALSE)

# ------------------------------------------------------------------------------
# 7a) lime-equivalent CaCO3 requirements (Kamprath / Cochrane / LiTAS) from
#     the cropland-masked soil stack. Uses limer (gaiafrica/limer) for the
#     agronomic lime-rate methods.

sprops_cropland <- terra::rast(paste0(input_path, 'soilgrids_properties_cropland.tif'))
sprops_cropland <- sprops_cropland[[c(3,4,5,6,7,1)]]
names(sprops_cropland) <- c('exch_ac', 'exch_K', 'exch_Ca', 'exch_Mg', 'exch_Na', 'SBD')

# acidity-saturation filter: keep only soils with acidity saturation > 10%
hp_sat <- terra::rast(paste0(input_path, 'soilgrids_properties_cropland.tif'))
hp_sat <- hp_sat[[c(10)]]
hp_sat_acid <- terra::classify(hp_sat, rcl=cbind(-1, 10, 0))
hp_sat_acid <- terra::ifel(hp_sat_acid != 0, 1, hp_sat_acid)

# Kamprath: year 1
caco3_kamprath <- limer::limeRate(sprops_cropland, method='ka', check_Ca=F, unit='t/ha', SD=20)
caco3_kamprath <- caco3_kamprath * hp_sat_acid
terra::writeRaster(caco3_kamprath, paste0(input_path, 'caco3_kamprath.tif'), overwrite=T)

# Cochrane: year 1 across TAS 0..40
tas <- c(0, 5, 10, 15, 20, 25, 30, 35, 40)
caco3_cochrane <- lapply(tas, function(t){
  cochrane <- limer::limeRate(sprops_cropland, method='co', check_Ca=F, unit='t/ha', SD=20, TAS=t)
  names(cochrane) <- paste0('cochrane_', t)
  cochrane})
caco3_cochrane <- terra::rast(caco3_cochrane)
terra::writeRaster(caco3_cochrane, paste0(input_path, 'caco3_cochrane.tif'), overwrite=T)

# Aramburu-Merlos LiTAS: year 1 across TAS 0..40
caco3_merlos <- lapply(tas, function(t){
  merlos <- limer::limeRate(sprops_cropland, method='LiTAS', check_Ca=F, unit='t/ha', SD=20, TAS=t)
  names(merlos) <- paste0('merlos_', t)
  merlos})
caco3_merlos <- terra::rast(caco3_merlos)
terra::writeRaster(caco3_merlos, paste0(input_path, 'caco3_merlos.tif'), overwrite=T)

# Aramburu-Merlos LiTAS: maintenance (steady-state ECEC re-acidification)
sprops_maintenance <- terra::rast(paste0(input_path, 'soilgrids_properties_cropland.tif'))
sprops_maintenance <- sprops_maintenance[[c(3,4,5,6,7,1,9)]]
names(sprops_maintenance) <- c('exch_ac', 'exch_K', 'exch_Ca', 'exch_Mg', 'exch_Na', 'SBD', 'ECEC')
acidification <- 0
decay         <- 0.22
caco3_merlos_maintenance <- lapply(tas, function(t){
  maint_lime <- sprops_maintenance
  exal <- (maint_lime$ECEC * t) / 100   # ex_ac corresponding to target acidity saturation
  maint_lime$exch_ac <- min(maint_lime$exch_ac, exal + decay + acidification)
  merlos <- limer::limeRate(maint_lime[[1:6]], method='LiTAS', check_Ca=F, unit='t/ha', SD=20, TAS=t)
  names(merlos) <- paste0('merlos_', t)
  merlos})
caco3_merlos_maintenance <- terra::rast(caco3_merlos_maintenance)
terra::writeRaster(caco3_merlos_maintenance, paste0(input_path, 'caco3_merlos_maintenance.tif'), overwrite=T)

# ------------------------------------------------------------------------------
# 7b) LiTAS-targeted basalt rates (stoichiometrically converted from CaCO3)

basalt_kamprath           <- caco3_kamprath           * basalt_per_lime
basalt_cochrane           <- caco3_cochrane           * basalt_per_lime
basalt_merlos             <- caco3_merlos             * basalt_per_lime
basalt_merlos_maintenance <- caco3_merlos_maintenance * basalt_per_lime

terra::writeRaster(basalt_kamprath,           paste0(input_path, 'basalt_kamprath.tif'),           overwrite=T)
terra::writeRaster(basalt_cochrane,           paste0(input_path, 'basalt_cochrane.tif'),           overwrite=T)
terra::writeRaster(basalt_merlos,             paste0(input_path, 'basalt_merlos.tif'),             overwrite=T)
terra::writeRaster(basalt_merlos_maintenance, paste0(input_path, 'basalt_merlos_maintenance.tif'), overwrite=T)

# reference-climate cumulative CDR for the targeted rates
cdr_const_targeted             <- basalt_merlos             * (cdr_eff_per_t_basalt / 1000)
cdr_const_targeted_maintenance <- basalt_merlos_maintenance * (cdr_eff_per_t_basalt / 1000)
terra::writeRaster(cdr_const_targeted,             paste0(input_path, 'cdr_const_targeted.tif'),             overwrite=T)
terra::writeRaster(cdr_const_targeted_maintenance, paste0(input_path, 'cdr_const_targeted_maintenance.tif'), overwrite=T)

# ------------------------------------------------------------------------------
# 8) uniform-rate scenario rasters
# Match the modelling convention of Beerling 2020 (10 t/ha), Baek 2023 (10 t/ha),
# and Kantola 2024 (50 t/ha). Produced as cropland-masked constants; erw-7
# decides whether to additionally restrict to acid soils.

ref_grid <- basalt_merlos[[1]]   # working grid

# cropland mask from SPAM (any crop with > 0 ha)
crop_area <- terra::rast(paste0(input_path, 'spam_harv_area_processed.tif'))
crop_total <- sum(crop_area, na.rm=TRUE)
crop_mask  <- terra::ifel(crop_total > 0, 1, NA)
crop_mask  <- terra::resample(crop_mask, ref_grid, method='near')

for (rate in c(10, 20, 50)) {
  uniform_raster <- ref_grid * 0 + rate
  uniform_raster <- uniform_raster * crop_mask
  names(uniform_raster) <- paste0('uniform_', rate, '_tha')
  terra::writeRaster(uniform_raster,
                     paste0(input_path, 'basalt_uniform_', rate, '.tif'),
                     overwrite=T)

  # paired CDR raster at reference climate
  cdr_uniform <- uniform_raster * (cdr_eff_per_t_basalt / 1000)
  names(cdr_uniform) <- paste0('cdr_uniform_', rate, '_tha')
  terra::writeRaster(cdr_uniform,
                     paste0(input_path, 'cdr_const_uniform_', rate, '.tif'),
                     overwrite=T)
}

# ------------------------------------------------------------------------------

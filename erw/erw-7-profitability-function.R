
# ------------------------------------------------------------------------------
# erw-7-profitability-function.R
#
# ERW profitability with decomposed cost accounting, derived LCA emissions,
# an MRV-cost deduction, and a sweep over allocation rules (LiTAS-targeted +
# three uniform-rate variants).
#
# Cost components (per tonne basalt):
#   quarry_gate    $/t   ex-quarry feedstock price
#   grinding       $/t   = grinding_kWh_per_t × electricity_$/kWh  (from erw-3)
#   transport      $/t   = travel_min × $/min/t   (raster from erw-basalt-access)
#                        or flat fallback if access raster missing
#   spreading      $/t   on-farm application cost
#
# Lifecycle emissions (per tonne basalt, kg CO2):
#   grinding       grinding_kWh_per_t × grid_carbon_intensity
#   transport      transport_km × truck_kgCO2_per_t_km
#   spreading      spreading_kgCO2_per_t  (small)
#
# Net-export CDR (t CO2/ha) = max(gross_CDR − F × acidity_sink, 0)   (durable)
#   F = CDR_eff / effective_NV ≈ 0.88 tCO2 / tCaCO3-eq; sink is regime-specific
#   (standing acidity for year1/NPV, maintenance acidity for equilibrium)
# Net CDR (t CO2/ha) = max(net_export_CDR − LCA_per_ha, 0)
# CDR revenue ($/ha) = net_CDR × (carbon_price − mrv_cost_per_tco2)
# Gross margin ($/ha) = agronomic_return + cdr_revenue − basalt_cost
#
# Outputs:
#   economics_erw/{allocation_rule}/{crop}_{regime}.tif
#     where allocation_rule ∈ {targeted, uniform_10, uniform_20, uniform_50}
#           regime ∈ {year1, npv, equilibrium}
# ------------------------------------------------------------------------------

# directories — resolved from the project root via the {here} package
# (anchored by the .here marker at the repo root)
library(here)
input_path  <- paste0(here::here('data'), '/')
output_path <- paste0(here::here('data'), '/')

# ------------------------------------------------------------------------------
# keys

fao <- data.frame(spam = c("MAIZ", "SORG", "BEAN", "CHIC", 'LENT', "WHEA", "BARL", "ACOF", "RCOF", 'PMIL', 'SMIL', 'POTA', 'SWPO', 'CASS', 'COWP', 'PIGE', 'SOYB', 'GROU', 'SUGC', 'COTT', 'COCO', 'TEAS', 'TOBA'),
                  Item = c('Maize (corn)', "Sorghum", "Beans, dry", "Chick peas, dry", 'Lentils, dry', "Wheat", "Barley", "Coffee, green", "Coffee, green", 'Millet', 'Millet', 'Potatoes', 'Sweet potatoes', 'Cassava, fresh', 'Cow peas, dry', 'Pigeon peas, dry', 'Soya beans', 'Groundnuts, excluding shelled', 'Sugar cane', 'Cotton seed', 'Cocoa beans', 'Tea leaves', 'Unmanufactured tobacco'))
crops_df <- read.csv(paste0(input_path, 'ecocrop_parameters_hp.csv'))[-c(1)]
ctype_df <- read.csv(paste0(input_path, 'crop_types.csv'))[-c(1)]
crops_df <- merge(crops_df, ctype_df, by.x='spam', by.y='crop')
crops_df <- merge(crops_df, fao, by='spam')
country <- data.frame(iso3 = c('AGO', 'BEN', 'BWA', 'BFA', 'BDI', 'CMR', 'CAF', 'TCD', 'COG', 'COD', 'GNQ', 'ERI', 'SWZ', 'ETH', 'GAB', 'GMB', 'GHA', 'GIN', 'GNB', 'CIV', 'KEN', 'LSO', 'LBR', 'MDG', 'MWI', 'MLI', 'MRT', 'MOZ', 'NAM', 'NER', 'NGA', 'RWA', 'SEN', 'SLE', 'SOM', 'SSD', 'SDN', 'SWZ', 'TZA', 'TGO', 'UGA', 'ZAF', 'ZMB', 'ZWE'),
                      Area =  c('Angola', 'Benin', 'Botswana', 'Burkina Faso', 'Burundi', 'Cameroon', 'Central African Republic', 'Chad', 'Congo', 'DRC', 'Equatorial Guinea', 'Eritrea', 'Swaziland', 'Ethiopia', 'Gabon', 'Gambia', 'Ghana', 'Guinea', 'Guinea-Bissau', 'Côte d\'Ivoire', 'Kenya', 'Lesotho', 'Liberia', 'Madagascar', 'Malawi', 'Mali', 'Mauritania', 'Mozambique', 'Namibia', 'Niger', 'Nigeria', 'Rwanda', 'Senegal', 'Sierra Leone', 'Somalia', 'Sudan (former)', 'Sudan (former)', 'Swaziland', 'United Republic of Tanzania', 'Togo', 'Uganda', 'South Africa', 'Zambia', 'Zimbabwe'))

# ------------------------------------------------------------------------------
# agronomic side

resp_hp <- terra::rast(Sys.glob(paste0(input_path, 'ecocrop_f/hp_crop_suitability_*_0.tif')))
names(resp_hp) <- gsub("\\_0.tif$", "", basename(terra::sources(resp_hp)))
names(resp_hp) <- gsub("hp_crop_suitability_", "", names(resp_hp))
resp_hp <- terra::aggregate(resp_hp, 10, fun='mean', na.rm=T)

crop_yield <- terra::rast(paste0(input_path, "spam_yield_processed.tif")) / 1000
crop_area  <- terra::rast(paste0(input_path, "spam_harv_area_processed.tif"))
names(crop_area) <- paste0(names(crop_area), '_ha')

fao_price <- read.csv(paste0(input_path, 'FAOSTAT_data_en_4-24-2023.csv'))
fao_price <- subset(fao_price, Year > 2015 & Year <= 2020)
fao_price <- subset(fao_price, Item %in% crops_df$Item & Area %in% country$Area)
fao_price <- merge(fao_price, crops_df, by='Item', all.y=T)
fao_price <- merge(fao_price, country, by='Area', all.x=T)
fao_price <- fao_price[c(1, 2, 10, 12, 13, 14, 17, 18, 19)]
crop_price <- aggregate(fao_price$Value, by=list('crop'=fao_price$spam), FUN=median, na.rm=T)

soil <- terra::aggregate(terra::rast(paste0(input_path, 'soilgrids_properties_all.tif')), 10, 'mean', na.rm=T)

# ------------------------------------------------------------------------------
# feedstock constants from erw-3

fs <- read.csv(paste0(input_path, 'basalt_feedstock_chemistry.csv'))
get_fs <- function(p) as.numeric(fs$value[fs$parameter == p])

GRAIN_SIZE_UM        <- get_fs('grain_size_um')
GRINDING_KWH_PER_T   <- get_fs('grinding_kWh_per_t')
GRINDING_USD_PER_T   <- get_fs('grinding_usd_per_t_at_ref_electricity')
PROJECT_HORIZON_YR   <- get_fs('project_horizon_yr')

# net-export CDR factor: CO2 re-released per t CaCO3-eq of acidity neutralized.
# Not tuned — falls straight out of the feedstock's own chemistry:
#   F = CDR_eff (kg CO2 / t basalt) / effective_NV (kg CaCO3-eq / t basalt) ≈ 0.88
CDR_EFF_KG_PER_T <- get_fs('CDR_eff_kg_per_t_ref')     # 87.6 kg CO2 / t basalt
EFFECTIVE_NV_T   <- get_fs('effective_NV')             # 0.0996 t CaCO3-eq / t basalt
F_REEXPORT       <- CDR_EFF_KG_PER_T / (EFFECTIVE_NV_T * 1000)
cat('Net-export F (tCO2 re-released per tCaCO3-eq): ', round(F_REEXPORT, 3), '\n', sep='')

# ------------------------------------------------------------------------------
# cost components (override per scenario in erw-8)

QUARRY_GATE_USD_T          <- 10           # $/t ex-quarry
ELECTRICITY_USD_KWH_FB     <- 0.10         # fallback if country raster missing
GRID_CI_KG_PER_KWH_FB      <- 0.60         # fallback if country raster missing
TRUCK_KGCO2_PER_T_KM       <- 0.12         # diesel heavy truck
SPREADING_USD_T            <- 8            # on-farm spreading
SPREADING_KGCO2_PER_T      <- 0.5          # ≈ 0.1 L diesel per t for application
TRANSPORT_FLAT_USD_T       <- 20           # fallback if basalt-access raster missing
TRANSPORT_FLAT_KM          <- 100          # paired km for the LCA fallback

CARBON_PRICE_USD_T         <- 150          # mid 2024-25 ERW credit market
# MRV stack: sampling, lab, verification, registry. $30 is the current
# first-of-kind pilot benchmark (Levy et al. 2024); $20 reflects the
# at-scale aggregator pooling target that Isometric / Puro forecast for
# 2027+ once protocols industrialise.
MRV_COST_USD_T_CO2         <- 20
DISCOUNT_RATE_PCT          <- 10           # for NPV regime

# time-resolved CDR phasing — fraction of total reactive CDR realised per year
# Default: first-order-kinetics-shaped, 5-year horizon, ~80% by year 5.
# Used by the NPV regime to discount CDR revenue properly instead of treating
# it as upfront. Sum need not equal 1; remainder is the never-fully-reacted tail.
CDR_PHASING <- c(0.30, 0.25, 0.20, 0.15, 0.10)

# NPV factor applied to CDR revenue: NPV of phased revenue / undiscounted total
CDR_NPV_FACTOR <- sum(
  CDR_PHASING / (1 + DISCOUNT_RATE_PCT / 100) ^ seq_along(CDR_PHASING)
) / sum(CDR_PHASING)
cat('CDR NPV factor (', length(CDR_PHASING), '-yr phasing, ', DISCOUNT_RATE_PCT,
    '% discount): ', round(CDR_NPV_FACTOR, 3),
    ' (vs 1.0 for upfront treatment)\n', sep='')

# country energy rasters from erw-energy-country.R
elec_path <- paste0(input_path, 'electricity_usd_kWh.tif')
ci_path   <- paste0(input_path, 'grid_CI_kg_per_kWh.tif')
if (file.exists(elec_path) && file.exists(ci_path)) {
  # Already exported at the working 0.0833° grid by erw-energy-country.R
  electricity_raster <- terra::rast(elec_path)
  grid_ci_raster     <- terra::rast(ci_path)
  cat('Using country-level electricity + grid CI rasters\n')
} else {
  electricity_raster <- ELECTRICITY_USD_KWH_FB
  grid_ci_raster     <- GRID_CI_KG_PER_KWH_FB
  cat('No country energy rasters — using flat $', ELECTRICITY_USD_KWH_FB,
      '/kWh and ', GRID_CI_KG_PER_KWH_FB, ' kgCO2/kWh\n', sep='')
}

# per-pixel grinding cost and LCA
grinding_usd_per_t_px <- GRINDING_KWH_PER_T * electricity_raster
lca_grinding_kg_per_t_px <- GRINDING_KWH_PER_T * grid_ci_raster

# ------------------------------------------------------------------------------
# transport: load spatial raster if available, otherwise use flat fallback

transport_path <- paste0(input_path, 'basalt_transport_cost_usd_t.tif')
km_path        <- paste0(input_path, 'basalt_transport_km.tif')
if (file.exists(transport_path) && file.exists(km_path)) {
  # Already exported at the working 0.0833° grid by erw-basalt-access.R
  transport_cost <- terra::rast(transport_path)
  transport_km   <- terra::rast(km_path)
  cat('Using spatial transport from erw-basalt-access\n')
} else {
  transport_cost <- TRANSPORT_FLAT_USD_T
  transport_km   <- TRANSPORT_FLAT_KM
  cat('No basalt-access raster — using flat transport $', TRANSPORT_FLAT_USD_T,
      '/t and ', TRANSPORT_FLAT_KM, ' km\n', sep='')
}

# delivered basalt cost per tonne, decomposed (per-pixel where rasters available)
basalt_cost_per_t <- QUARRY_GATE_USD_T + grinding_usd_per_t_px +
                     transport_cost + SPREADING_USD_T

# lifecycle CO2 per tonne basalt (kg CO2 / t basalt)
lca_kg_per_t_basalt <- lca_grinding_kg_per_t_px +
                       transport_km * TRUCK_KGCO2_PER_T_KM +
                       SPREADING_KGCO2_PER_T

cat('Basalt cost per t: ', sep='')
if (inherits(basalt_cost_per_t, 'SpatRaster')) {
  print(terra::global(basalt_cost_per_t, fun=c('mean','min','max'), na.rm=TRUE))
} else cat('$', round(basalt_cost_per_t, 2), '/t\n', sep='')
cat('LCA per t basalt:  ', sep='')
if (inherits(lca_kg_per_t_basalt, 'SpatRaster')) {
  print(terra::global(lca_kg_per_t_basalt, fun=c('mean','min','max'), na.rm=TRUE))
} else cat(round(lca_kg_per_t_basalt, 1), ' kg CO2/t\n', sep='')

# ------------------------------------------------------------------------------
# basalt application-rate and CDR rasters (all allocation rules)

agg10 <- function(path) terra::aggregate(terra::rast(path), 10, mean, na.rm=TRUE)

basalt_stacks <- list(
  targeted   = list(rate = agg10(paste0(input_path, 'basalt_merlos.tif')),
                    rate_m = agg10(paste0(input_path, 'basalt_merlos_maintenance.tif')),
                    cdr  = agg10(paste0(input_path, 'cdr_yield_merlos.tif')),
                    cdr_m = agg10(paste0(input_path, 'cdr_yield_merlos_maintenance.tif')),
                    multi_layer = TRUE),
  uniform_10 = list(rate = agg10(paste0(input_path, 'basalt_uniform_10.tif')),
                    rate_m = agg10(paste0(input_path, 'basalt_uniform_10.tif')),
                    cdr  = agg10(paste0(input_path, 'cdr_yield_uniform_10.tif')),
                    cdr_m = agg10(paste0(input_path, 'cdr_yield_uniform_10.tif')),
                    multi_layer = FALSE),
  uniform_20 = list(rate = agg10(paste0(input_path, 'basalt_uniform_20.tif')),
                    rate_m = agg10(paste0(input_path, 'basalt_uniform_20.tif')),
                    cdr  = agg10(paste0(input_path, 'cdr_yield_uniform_20.tif')),
                    cdr_m = agg10(paste0(input_path, 'cdr_yield_uniform_20.tif')),
                    multi_layer = FALSE),
  uniform_50 = list(rate = agg10(paste0(input_path, 'basalt_uniform_50.tif')),
                    rate_m = agg10(paste0(input_path, 'basalt_uniform_50.tif')),
                    cdr  = agg10(paste0(input_path, 'cdr_yield_uniform_50.tif')),
                    cdr_m = agg10(paste0(input_path, 'cdr_yield_uniform_50.tif')),
                    multi_layer = FALSE)
)

# regime-specific acidity sinks for the net-export deduction (t CaCO3/ha):
#   year-1 / NPV -> standing exchangeable acidity (Kamprath lime requirement)
#   equilibrium  -> annual maintenance acidity (re-acidification only)
# NA (non-acid pixels) -> 0: no acidity to neutralize, so alkalinity fully exports.
acidity_standing <- agg10(paste0(input_path, 'caco3_kamprath.tif'))
acidity_standing <- terra::ifel(is.na(acidity_standing), 0, acidity_standing)
acidity_maint    <- agg10(paste0(input_path, 'caco3_merlos_maintenance.tif'))[[1]]
acidity_maint    <- terra::ifel(is.na(acidity_maint), 0, acidity_maint)

# per-crop basalt + CDR, with allocation-rule-aware masking
bf <- function(crop, alloc, maintenance = FALSE) {
  st <- basalt_stacks[[alloc]]
  rate_src <- if (maintenance) st$rate_m else st$rate
  cdr_src  <- if (maintenance) st$cdr_m  else st$cdr

  c_subset <- crops_df[crops_df$spam == crop, ]
  if (st$multi_layer) {
    idx <- grep(paste0("_", c_subset$ac_sat, "$"), names(rate_src))
    basalt_tha <- rate_src[[idx]]
    cdr_tha    <- cdr_src[[idx]]
  } else {
    basalt_tha <- rate_src
    cdr_tha    <- cdr_src
  }

  area_mask <- terra::ifel(crop_area[[paste0(crop, '_ha')]] > 0, 1, NA)
  # targeted: also mask to acid pixels above the crop's tolerance.
  # uniform: keep the rate everywhere there is cropland (matches Beerling/Baek
  # modelling convention — uniform across cropland regardless of soil acidity).
  if (alloc == 'targeted') {
    acid_mask <- terra::ifel(soil$hp_sat > c_subset$ac_sat, 1, NA)
    m <- area_mask * acid_mask
  } else {
    m <- area_mask
  }
  basalt_tha <- basalt_tha * m; names(basalt_tha) <- crop
  cdr_tha    <- cdr_tha    * m; names(cdr_tha)    <- crop
  list(basalt = basalt_tha, cdr = cdr_tha)
}

# ------------------------------------------------------------------------------
# profit functions

returns <- function(crop, yield_resp, crop_price, yield_f) {
  c_subset <- crops_df[crops_df$spam == crop, ]
  actual_yield <- crop_yield[c(crop), ]; names(actual_yield) <- paste0(crop, '_ya')
  yield_level  <- actual_yield * yield_f

  # If a Bayesian-fit yield-uplift raster is available (from erw-yield-predict),
  # use it directly: yield_resp_tha = actual_yield × (uplift_ratio − 1).
  # Otherwise fall back to the EcoCrop-derived relative yield from erw-5.
  erw_uplift_path <- paste0(input_path, 'erw_yield_uplift_', crop, '_median.tif')
  if (file.exists(erw_uplift_path)) {
    uplift <- terra::aggregate(terra::rast(erw_uplift_path), 10, mean, na.rm = TRUE)
    names(uplift) <- paste0(crop, '_uplift')
    yield_loss <- 1 / uplift; names(yield_loss) <- paste0(crop, '_loss')
    yield_resp_tha <- yield_level * (uplift - 1)
  } else {
    yield_loss   <- yield_resp[[crop]]; names(yield_loss) <- paste0(crop, '_loss')
    yield_resp_tha <- (yield_level / yield_loss) - yield_level
  }

  yield_resp_tha <- terra::subst(yield_resp_tha, 0, NA)
  names(yield_resp_tha) <- paste0(crop, '_yresp_tha')
  agro_return <- yield_resp_tha * crop_price
  names(agro_return) <- paste0(crop, '_agro_return_usha')
  c(actual_yield, yield_loss, yield_resp_tha, agro_return)
}

# decomposed basalt cost = rate × delivered_$/t (already includes quarry+grind+transport+spread)
basalt_cost <- function(crop, basalt_tha, cost_per_t) {
  cost <- basalt_tha * cost_per_t
  names(cost) <- paste0(crop, '_basalt_cost_usha')
  c(setNames(basalt_tha, paste0(crop, '_basalt_tha')), cost)
}

# CDR revenue with net-export deduction, derived LCA + MRV
cdr_revenue <- function(crop, basalt_tha, cdr_gross_tha, lca_kg_per_t,
                        carbon_price, mrv_cost_per_tco2,
                        acidity_sink, f_reexport) {
  gross <- cdr_gross_tha; names(gross) <- paste0(crop, '_cdr_gross_tha')
  # (1) net-export deduction: subtract the alkalinity consumed neutralizing soil
  # acidity, which re-releases its CO2 (HCO3- + H+ -> H2O + CO2) exactly like
  # agricultural lime. Only alkalinity that exports as bicarbonate is durable.
  s <- terra::resample(acidity_sink, gross)
  s <- terra::ifel(is.na(s), 0, s)
  net_export <- gross - f_reexport * s
  net_export <- terra::ifel(net_export < 0, 0, net_export)
  # (2) lifecycle supply-chain emissions (grinding / transport / spreading)
  lca_per_ha_t <- basalt_tha * lca_kg_per_t / 1000
  net <- net_export - lca_per_ha_t
  net <- terra::ifel(net < 0, 0, net); names(net) <- paste0(crop, '_cdr_net_tha')
  rev <- net * (carbon_price - mrv_cost_per_tco2)
  rev <- terra::ifel(rev < 0, 0, rev); names(rev) <- paste0(crop, '_cdr_revenue_usha')
  c(gross, net, rev)
}

# how many years between reapplications for the NPV regime
nyears_basalt <- function(crop, rate_y1, rate_maint) {
  r1 <- rate_y1; rm <- rate_maint
  n  <- round(r1 / rm, 0)
  n  <- terra::ifel(n < 1, 1, n); names(n) <- 'nyears'
  n
}

profit <- function(crop, yield_resp, yf, crop_price, returns_f,
                   alloc, basalt_cost_per_t, lca_kg_per_t,
                   carbon_price, mrv_cost_per_tco2) {

  # rates and CDR per allocation rule
  y1   <- bf(crop, alloc, maintenance = FALSE)
  m    <- bf(crop, alloc, maintenance = TRUE)
  rate_tha   <- y1$basalt
  rate_m_tha <- m$basalt
  cdr_tha    <- y1$cdr
  cdr_m_tha  <- m$cdr
  nyrs <- nyears_basalt(crop, rate_tha, rate_m_tha)

  if (returns_f == 'year1') {
    ret  <- returns(crop, yield_resp, yield_f = yf, crop_price)
    # The basalt is paid for up front but resides in the soil for the full
    # project horizon (default 5 yr — Lewis 2021 [S1]'s effective reactive
    # window). cdr_tha is already a horizon-cumulative number coming out of
    # erw-9, so the agronomic return must be put on the same cumulative
    # undiscounted basis to avoid a unit mismatch that drags GM_year1
    # artificially negative. NPV regime applies an explicit discount; this
    # regime is the undiscounted cumulative.
    agro_layer <- paste0(crop, '_agro_return_usha')
    ret[[agro_layer]] <- ret[[agro_layer]] * PROJECT_HORIZON_YR
    cost <- basalt_cost(crop, rate_tha, basalt_cost_per_t)
    cdr  <- cdr_revenue(crop, rate_tha, cdr_tha, lca_kg_per_t,
                        carbon_price, mrv_cost_per_tco2,
                        acidity_sink = acidity_standing, f_reexport = F_REEXPORT)

  } else if (returns_f == 'npv') {
    r1 <- returns(crop, yield_resp, yield_f = yf, crop_price)
    agro_npv <- limer::NPV_lime(r1[[paste0(crop, '_agro_return_usha')]],
                                nyears = nyrs, discount_rate = DISCOUNT_RATE_PCT)
    names(agro_npv) <- paste0(crop, '_agro_return_usha')
    ret  <- c(r1[[1:3]], agro_npv)
    cost <- basalt_cost(crop, rate_tha, basalt_cost_per_t)
    # CDR phased over the project horizon and discounted year-by-year.
    # CDR_NPV_FACTOR < 1 captures the time-value loss vs upfront treatment
    # (typically ~0.79 for a 5-yr first-order phasing at 10% discount).
    cdr  <- cdr_revenue(crop, rate_tha, cdr_tha, lca_kg_per_t,
                        carbon_price, mrv_cost_per_tco2,
                        acidity_sink = acidity_standing, f_reexport = F_REEXPORT)
    cdr_rev_npv <- cdr[[paste0(crop, '_cdr_revenue_usha')]] * CDR_NPV_FACTOR
    names(cdr_rev_npv) <- paste0(crop, '_cdr_revenue_usha')
    cdr[[paste0(crop, '_cdr_revenue_usha')]] <- cdr_rev_npv

  } else if (returns_f == 'equilibrium') {
    ret  <- returns(crop, yield_resp, yield_f = yf, crop_price)
    cost <- basalt_cost(crop, rate_m_tha, basalt_cost_per_t)
    cdr  <- cdr_revenue(crop, rate_m_tha, cdr_m_tha, lca_kg_per_t,
                        carbon_price, mrv_cost_per_tco2,
                        acidity_sink = acidity_maint, f_reexport = F_REEXPORT)
  }

  agro_ret <- ret[[paste0(crop, '_agro_return_usha')]]
  basalt_c <- cost[[paste0(crop, '_basalt_cost_usha')]]
  cdr_rev  <- cdr[[paste0(crop, '_cdr_revenue_usha')]]

  gm       <- agro_ret + cdr_rev - basalt_c; names(gm) <- paste0(crop, '_gm_combined_usha')
  gm_agro  <- agro_ret - basalt_c;           names(gm_agro) <- paste0(crop, '_gm_agro_only_usha')
  gm_cdr   <- cdr_rev  - basalt_c;           names(gm_cdr)  <- paste0(crop, '_gm_cdr_only_usha')
  roi      <- (agro_ret + cdr_rev) / basalt_c; names(roi) <- paste0(crop, '_roi_combined')

  c(ret, cost, cdr, gm, gm_agro, gm_cdr, roi)
}

# ------------------------------------------------------------------------------
# main loop

ALLOC_RULES <- c('targeted', 'uniform_10', 'uniform_20', 'uniform_50')

for (alloc in ALLOC_RULES) {
  out_dir <- paste0(input_path, 'economics_erw/', alloc, '/')
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  for (r_f in c('year1', 'npv', 'equilibrium')) {
    cat(alloc, '|', r_f, '\n')
    for (crop in unique(crops_df$spam)) {
      cat('  ', crop, '\n')
      area_ha <- crop_area[[paste0(crop, '_ha')]]
      cp <- crop_price[crop_price$crop == crop, ]$x

      out <- profit(crop = crop, yield_resp = resp_hp, yf = 1, crop_price = cp,
                    returns_f = r_f, alloc = alloc,
                    basalt_cost_per_t = basalt_cost_per_t,
                    lca_kg_per_t      = lca_kg_per_t_basalt,
                    carbon_price      = CARBON_PRICE_USD_T,
                    mrv_cost_per_tco2 = MRV_COST_USD_T_CO2)

      out_stack <- c(area_ha, out)
      terra::writeRaster(out_stack,
                         paste0(out_dir, crop, '_', r_f, '.tif'),
                         overwrite = TRUE)
    }
  }
}

# ------------------------------------------------------------------------------

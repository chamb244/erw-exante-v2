
# ------------------------------------------------------------------------------
# erw-8-sensitivity-analysis.R
#
# Sweeps for the decomposed-cost ERW model in erw-7. Five output CSVs, one per
# sweep dimension:
#
#   1) prices      — crop_price × basalt_cost × carbon_price grid
#   2) yields      — yield-factor 1.0–2.5
#   3) mrv         — MRV cost 0–80 $/tCO2
#   4) grain       — grain size 10, 30, 50, 100, 200, 500 µm
#                    (affects BOTH grinding cost and CDR rate per t basalt)
#   5) allocation  — targeted vs uniform_{10,20,50}
#
# All sweeps run all three return regimes (year1, npv, equilibrium) and the
# 23 SPAM crops.
#
# Imports the profit() machinery from erw-7-profitability-function.R via
# source(). Adjust the path if you reorganise the directory.
# ------------------------------------------------------------------------------

# directories — resolved from the project root via the {here} package
# (anchored by the .here marker at the repo root)
library(here)
input_path  <- paste0(here::here('data'), '/')
output_path <- paste0(here::here('data'), '/')

source(here::here('erw', 'erw-7-profitability-function.R'))

# ------------------------------------------------------------------------------
# helpers

aggregate_gm <- function(gm_raster, area_ha) {
  gm_pos <- terra::ifel(gm_raster <= 0, NA, gm_raster)
  ha     <- area_ha * terra::ifel(gm_raster > 0, 1, NA)
  list(
    gm = round(terra::global(gm_pos, 'sum', na.rm = TRUE)$sum, 2),
    ha = round(terra::global(ha,     'sum', na.rm = TRUE)$sum, 2)
  )
}

run_one <- function(crop, area_ha, alloc, r_f,
                    cost_per_t, lca_kg_per_t, carbon_p, mrv_p,
                    crop_p_scalar = 1, yf = 1) {
  cp <- crop_price[crop_price$crop == crop, ]$x * crop_p_scalar
  out <- profit(crop = crop, yield_resp = resp_hp, yf = yf, crop_price = cp,
                returns_f = r_f, alloc = alloc,
                basalt_cost_per_t = cost_per_t,
                lca_kg_per_t      = lca_kg_per_t,
                carbon_price      = carbon_p,
                mrv_cost_per_tco2 = mrv_p)
  list(
    combined = aggregate_gm(out[[paste0(crop, '_gm_combined_usha')]],  area_ha),
    agro     = aggregate_gm(out[[paste0(crop, '_gm_agro_only_usha')]], area_ha),
    cdr      = aggregate_gm(out[[paste0(crop, '_gm_cdr_only_usha')]],  area_ha)
  )
}

REGIMES <- c('year1', 'npv', 'equilibrium')

# ------------------------------------------------------------------------------
# 1) prices grid — crop × basalt × carbon

crop_mults   <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
basalt_mults <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
carbon_seq   <- c(0, 50, 100, 150, 250)
grid_p <- expand.grid(c_mult = crop_mults, b_mult = basalt_mults, c_price = carbon_seq)

rows <- list()
for (r_f in REGIMES) {
  cat('prices |', r_f, '\n')
  for (crop in unique(crops_df$spam)) {
    cat('  ', crop, '\n')
    area_ha <- crop_area[[paste0(crop, '_ha')]]
    for (i in seq_len(nrow(grid_p))) {
      g <- grid_p[i, ]
      cost_i <- basalt_cost_per_t * g$b_mult
      r <- run_one(crop, area_ha, alloc = 'targeted', r_f = r_f,
                   cost_per_t = cost_i, lca_kg_per_t = lca_kg_per_t_basalt,
                   carbon_p = g$c_price, mrv_p = MRV_COST_USD_T_CO2,
                   crop_p_scalar = g$c_mult)
      rows[[length(rows) + 1]] <- data.frame(
        regime = r_f, crop = crop,
        c_mult = g$c_mult, b_mult = g$b_mult, c_price = g$c_price,
        gm_combined = r$combined$gm, ha_combined = r$combined$ha,
        gm_agro = r$agro$gm, ha_agro = r$agro$ha,
        gm_cdr  = r$cdr$gm,  ha_cdr  = r$cdr$ha)
    }
  }
}
write.csv(do.call(rbind, rows), paste0(output_path, '/output-erw-sensitivity-prices.csv'), row.names = FALSE)

# ------------------------------------------------------------------------------
# 2) yield factor — closing the yield gap

yld <- seq(1, 2.5, 0.25)
rows <- list()
for (r_f in REGIMES) {
  cat('yields |', r_f, '\n')
  for (crop in unique(crops_df$spam)) {
    cat('  ', crop, '\n')
    area_ha <- crop_area[[paste0(crop, '_ha')]]
    for (yf in yld) {
      r <- run_one(crop, area_ha, alloc = 'targeted', r_f = r_f,
                   cost_per_t = basalt_cost_per_t, lca_kg_per_t = lca_kg_per_t_basalt,
                   carbon_p = CARBON_PRICE_USD_T, mrv_p = MRV_COST_USD_T_CO2,
                   yf = yf)
      rows[[length(rows) + 1]] <- data.frame(
        regime = r_f, crop = crop, yield_f = yf,
        gm_combined = r$combined$gm, ha_combined = r$combined$ha)
    }
  }
}
write.csv(do.call(rbind, rows), paste0(output_path, '/output-erw-sensitivity-yields.csv'), row.names = FALSE)

# ------------------------------------------------------------------------------
# 3) MRV cost

mrv_seq <- c(0, 15, 30, 50, 80)
rows <- list()
for (r_f in REGIMES) {
  cat('mrv |', r_f, '\n')
  for (crop in unique(crops_df$spam)) {
    cat('  ', crop, '\n')
    area_ha <- crop_area[[paste0(crop, '_ha')]]
    for (mrv in mrv_seq) {
      r <- run_one(crop, area_ha, alloc = 'targeted', r_f = r_f,
                   cost_per_t = basalt_cost_per_t, lca_kg_per_t = lca_kg_per_t_basalt,
                   carbon_p = CARBON_PRICE_USD_T, mrv_p = mrv)
      rows[[length(rows) + 1]] <- data.frame(
        regime = r_f, crop = crop, mrv_usd_tco2 = mrv,
        gm_combined = r$combined$gm, ha_combined = r$combined$ha)
    }
  }
}
write.csv(do.call(rbind, rows), paste0(output_path, '/output-erw-sensitivity-mrv.csv'), row.names = FALSE)

# ------------------------------------------------------------------------------
# 4) grain size — the dominant ERW lever
#
# Grain size affects BOTH the per-t grinding cost AND the per-t CDR rate.
# Rather than re-running erw-3 and erw-9 for each grain size, scale the
# existing rasters multiplicatively. The reference grain size is 100 µm
# (GRAIN_REF_UM in erw-3); the square-root surface-area law gives the
# CDR-rate factor; Strefler's α=1.2 grinding-energy law gives the cost factor.

GRAIN_REF_UM <- 100   # must match erw-3
GRAIN_BETA   <- 0.5   # reactivity exponent (surface-area)
GRIND_ALPHA  <- 1.2   # grinding-energy exponent

grain_size_seq <- c(10, 30, 50, 100, 200, 500)

# constants captured from erw-7 setup
ref_grain_factor   <- (GRAIN_REF_UM / GRAIN_SIZE_UM) ^ GRAIN_BETA
ref_grinding_kWh   <- GRINDING_KWH_PER_T
ref_grinding_usd   <- GRINDING_USD_PER_T

rows <- list()
for (r_f in REGIMES) {
  cat('grain |', r_f, '\n')
  for (crop in unique(crops_df$spam)) {
    cat('  ', crop, '\n')
    area_ha <- crop_area[[paste0(crop, '_ha')]]
    for (gs in grain_size_seq) {
      # ratios vs the reference grain size used in erw-7 setup
      new_grain_factor   <- (GRAIN_REF_UM / gs) ^ GRAIN_BETA
      reactivity_ratio   <- new_grain_factor / ref_grain_factor
      new_grinding_kWh   <- (50 / gs) ^ GRIND_ALPHA * 0.07 * 277.78    # GJ→kWh at 50µm anchor
      new_grinding_usd   <- new_grinding_kWh * ELECTRICITY_USD_KWH
      # adjusted cost per t basalt = swap out only the grinding component
      cost_adj <- basalt_cost_per_t - ref_grinding_usd + new_grinding_usd
      # adjusted LCA per t basalt = swap out only the grinding component
      lca_adj  <- lca_kg_per_t_basalt - ref_grinding_kWh * GRID_CI_KG_PER_KWH +
                                       new_grinding_kWh * GRID_CI_KG_PER_KWH

      # CDR scaling: profit() multiplies CDR_stack internally; for the sweep,
      # multiply the carbon price by reactivity_ratio so that the net effect
      # of "more reactive due to finer grain" is captured upstream. This is
      # equivalent to scaling cdr_net.
      r <- run_one(crop, area_ha, alloc = 'targeted', r_f = r_f,
                   cost_per_t = cost_adj, lca_kg_per_t = lca_adj,
                   carbon_p = CARBON_PRICE_USD_T * reactivity_ratio,
                   mrv_p    = MRV_COST_USD_T_CO2)
      rows[[length(rows) + 1]] <- data.frame(
        regime = r_f, crop = crop, grain_size_um = gs,
        reactivity_factor = round(new_grain_factor, 3),
        grinding_usd_t    = round(new_grinding_usd, 2),
        gm_combined = r$combined$gm, ha_combined = r$combined$ha,
        gm_agro = r$agro$gm, gm_cdr = r$cdr$gm)
    }
  }
}
write.csv(do.call(rbind, rows), paste0(output_path, '/output-erw-sensitivity-grain.csv'), row.names = FALSE)

# ------------------------------------------------------------------------------
# 5) allocation rule — targeted vs uniform_10 / 20 / 50

rows <- list()
for (r_f in REGIMES) {
  cat('alloc |', r_f, '\n')
  for (crop in unique(crops_df$spam)) {
    cat('  ', crop, '\n')
    area_ha <- crop_area[[paste0(crop, '_ha')]]
    for (alloc in c('targeted', 'uniform_10', 'uniform_20', 'uniform_50')) {
      r <- run_one(crop, area_ha, alloc = alloc, r_f = r_f,
                   cost_per_t = basalt_cost_per_t, lca_kg_per_t = lca_kg_per_t_basalt,
                   carbon_p = CARBON_PRICE_USD_T, mrv_p = MRV_COST_USD_T_CO2)
      rows[[length(rows) + 1]] <- data.frame(
        regime = r_f, crop = crop, allocation = alloc,
        gm_combined = r$combined$gm, ha_combined = r$combined$ha,
        gm_agro = r$agro$gm, ha_agro = r$agro$ha,
        gm_cdr = r$cdr$gm,   ha_cdr  = r$cdr$ha)
    }
  }
}
write.csv(do.call(rbind, rows), paste0(output_path, '/output-erw-sensitivity-allocation.csv'), row.names = FALSE)

# ------------------------------------------------------------------------------

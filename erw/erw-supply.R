
# ------------------------------------------------------------------------------
# erw-supply.R
#
# Imposes an annual basalt-supply cap and ranks SSA cropland pixels by their
# economic merit. The output is a deployment-frontier analysis: under a supply
# limit of S Mt/yr, which pixels get prioritised, what is the marginal pixel's
# gross margin, and what is total CDR delivered?
#
# This is a v1 post-processor — it operates on the targeted-allocation outputs
# of erw-7 (economics_erw/targeted/*.tif) and aggregates across crops.
#
# Ranking criterion: pixels are ranked descending by GROSS MARGIN PER TONNE OF
# BASALT (i.e. the marginal profitability of one more tonne of feedstock). This
# is the right rule when basalt is the scarce input — equivalent to the LP dual
# value of the basalt-supply constraint.
#
# Inputs (from erw-7):
#   economics_erw/targeted/{crop}_{regime}.tif containing per-crop layers:
#     {crop}_ha, {crop}_basalt_tha, {crop}_gm_combined_usha
#
# Outputs:
#   supply_curve_{regime}.csv      — supply level → marginal GM, total CDR, total ha
#   deployment_under_{supply}_Mt_{regime}.tif — 1 = deployed, NA = not deployed
# ------------------------------------------------------------------------------

input_path  <- 'D:/# Jvasco/Working Papers/GAIA Guiding Acid Soil Investments/1-ex-ante-analysis/input-data/'
output_path <- 'D:/# Jvasco/Working Papers/GAIA Guiding Acid Soil Investments/1-ex-ante-analysis/output-data/'

# ------------------------------------------------------------------------------
# config

# annual basalt-supply caps to evaluate (Mt/yr). The full range probes from
# "tiny pilot" to "an order of magnitude above any realistic SSA capacity".
SUPPLY_CAPS_MT <- c(1, 5, 10, 25, 50, 100, 250, 500, Inf)

REGIMES <- c('year1', 'npv', 'equilibrium')

# crop list (matches erw-7)
crops <- c("MAIZ", "SORG", "BEAN", "CHIC", 'LENT', "WHEA", "BARL", "ACOF",
           "RCOF", 'PMIL', 'SMIL', 'POTA', 'SWPO', 'CASS', 'COWP', 'PIGE',
           'SOYB', 'GROU', 'SUGC', 'COTT', 'COCO', 'TEAS', 'TOBA')

# CDR per pixel comes from erw-9
cdr_per_t_basalt <- terra::aggregate(
  terra::rast(paste0(input_path, 'cdr_per_t_basalt.tif')),
  10, mean, na.rm = TRUE
)   # kg CO2 / t basalt per pixel

# ------------------------------------------------------------------------------
# build a single per-pixel data frame across crops × regime

for (r_f in REGIMES) {
  cat('\n=== ', r_f, ' ===\n', sep = '')

  # aggregate basalt tonnes and GM across crops for each pixel
  total_basalt_tha <- NULL
  total_gm_usha    <- NULL
  for (crop in crops) {
    fp <- paste0(input_path, 'economics_erw/targeted/', crop, '_', r_f, '.tif')
    if (!file.exists(fp)) next
    s <- terra::rast(fp)
    rate_layer <- paste0(crop, '_basalt_tha')
    gm_layer   <- paste0(crop, '_gm_combined_usha')
    if (!(rate_layer %in% names(s)) || !(gm_layer %in% names(s))) next
    area_layer <- paste0(crop, '_ha')
    area_ha <- s[[area_layer]]

    # basalt tonnes per pixel = rate × area
    basalt_t <- s[[rate_layer]] * area_ha
    # GM per pixel = $/ha × ha
    gm_usd   <- s[[gm_layer]]   * area_ha

    basalt_t <- terra::subst(basalt_t, NA, 0)
    gm_usd   <- terra::subst(gm_usd,   NA, 0)

    total_basalt_tha <- if (is.null(total_basalt_tha)) basalt_t else total_basalt_tha + basalt_t
    total_gm_usha    <- if (is.null(total_gm_usha))    gm_usd   else total_gm_usha + gm_usd
  }
  if (is.null(total_basalt_tha)) next

  # gross margin per tonne of basalt — the ranking criterion
  gm_per_t <- terra::ifel(total_basalt_tha > 0, total_gm_usha / total_basalt_tha, NA)
  names(gm_per_t) <- 'gm_usd_per_t_basalt'
  terra::writeRaster(gm_per_t,
                     paste0(input_path, 'gm_per_t_basalt_', r_f, '.tif'),
                     overwrite = TRUE)

  # extract values for ranking
  vals <- terra::values(c(gm_per_t, total_basalt_tha, total_gm_usha, cdr_per_t_basalt))
  cells <- which(!is.na(vals[, 1]) & vals[, 2] > 0)
  if (length(cells) == 0) { cat('No deployable pixels\n'); next }

  df <- data.frame(
    cell        = cells,
    gm_per_t    = vals[cells, 1],
    basalt_t    = vals[cells, 2],
    gm_total    = vals[cells, 3],
    cdr_per_t   = vals[cells, 4]   # kg CO2 / t basalt
  )
  # rank descending by GM per tonne basalt
  df <- df[order(-df$gm_per_t), ]
  df$cum_basalt_Mt <- cumsum(df$basalt_t) / 1e6
  df$cum_gm_Musd   <- cumsum(df$gm_total) / 1e6
  df$cum_cdr_Mt    <- cumsum(df$basalt_t * df$cdr_per_t / 1e3) / 1e6   # tCO2 → Mt

  # supply-curve summary
  rows <- list()
  for (cap in SUPPLY_CAPS_MT) {
    if (is.infinite(cap)) {
      idx <- nrow(df)
    } else {
      idx <- max(0, which(df$cum_basalt_Mt <= cap))
      if (length(idx) == 0) idx <- 0 else idx <- max(idx)
    }
    if (idx == 0) {
      rows[[length(rows) + 1]] <- data.frame(
        regime = r_f, supply_cap_Mt = cap,
        marginal_gm_usd_t = NA, pixels = 0,
        total_basalt_Mt = 0, total_gm_Musd = 0, total_cdr_Mt = 0)
      next
    }
    rows[[length(rows) + 1]] <- data.frame(
      regime           = r_f,
      supply_cap_Mt    = cap,
      marginal_gm_usd_t = round(df$gm_per_t[idx], 2),
      pixels           = idx,
      total_basalt_Mt  = round(df$cum_basalt_Mt[idx], 2),
      total_gm_Musd    = round(df$cum_gm_Musd[idx], 2),
      total_cdr_Mt     = round(df$cum_cdr_Mt[idx], 2))
  }
  write.csv(do.call(rbind, rows),
            paste0(output_path, '/supply_curve_', r_f, '.csv'),
            row.names = FALSE)

  # deployment masks for selected supply caps
  for (cap in c(10, 50, 250)) {
    idx <- max(0, max(which(df$cum_basalt_Mt <= cap), 0))
    if (idx == 0) next
    deploy_cells <- df$cell[seq_len(idx)]
    deploy_mask <- gm_per_t * NA
    deploy_mask[deploy_cells] <- 1
    names(deploy_mask) <- paste0('deployed_at_', cap, 'Mt')
    terra::writeRaster(deploy_mask,
                       paste0(input_path, 'deployment_under_', cap, '_Mt_', r_f, '.tif'),
                       overwrite = TRUE)
  }

  cat('Supply curve written. Sample rows:\n')
  print(do.call(rbind, rows))
}

# ------------------------------------------------------------------------------

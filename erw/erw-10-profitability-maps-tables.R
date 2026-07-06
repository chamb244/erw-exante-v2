# ------------------------------------------------------------------------------
# erw-10-profitability-maps-tables.R
#
# Render profitability maps and summary tables from the 276 economics_erw/
# rasters produced by erw-7. Companion to erw-plot-maps.R (which handles the
# 12 indicator maps) — this script focuses on outcome maps under different
# assumptions and aggregate tables.
#
# Maps written to docs/maps/profitability/:
#   ssa_gm_<regime>_<alloc>.png        continent-wide GM summed across crops
#   crop_gm_<crop>_<regime>_targeted.png  per-crop GM for MAIZ/SORG/CASS/GROU/WHEA
#   profitable_mask_<regime>_<alloc>.png  binary mask: GM > 0
#   breakeven_carbon_<regime>_<alloc>.png minimum $/tCO2 needed for GM > 0
#
# Tables written to docs/tables/:
#   output-ssa-summary.csv         one row per regime × allocation
#   output-country-summary.csv     one row per country × regime × allocation
#   output-crop-ranking.csv        one row per crop × regime × allocation
#
# Reads:
#   data/economics_erw/{targeted,uniform_10,uniform_20,uniform_50}/
#     {crop}_{year1,npv,equilibrium}.tif      (14-band raster per crop)
#   data/gadm_ssa.gpkg                        (country boundaries, 44 features)
#
# Bands used per crop raster:
#   {crop}_ha                  harvested area, ha/pixel
#   {crop}_gm_combined_usha    gross margin $/ha (agro + CDR − basalt)
#   {crop}_cdr_net_tha         net CDR t CO2/ha
#   {crop}_agro_return_usha    agronomic return $/ha
#   {crop}_basalt_cost_usha    delivered basalt cost $/ha
#   {crop}_cdr_revenue_usha    CDR revenue $/ha at CARBON_PRICE_USD_T=$150
# ------------------------------------------------------------------------------

suppressMessages({
  library(terra)
  library(here)
})

DATA <- here::here("data")
MAP_OUT <- here::here("docs", "maps", "profitability")
TBL_OUT <- here::here("docs", "tables")
dir.create(MAP_OUT, recursive = TRUE, showWarnings = FALSE)
dir.create(TBL_OUT, recursive = TRUE, showWarnings = FALSE)

REGIMES <- c("year1", "npv", "equilibrium")
ALLOCS  <- c("targeted", "uniform_10", "uniform_20", "uniform_50")
KEY_CROPS <- c("MAIZ", "SORG", "CASS", "GROU", "WHEA")
CARBON_PRICE <- 150   # default in erw-7; used for breakeven back-out

ssa <- tryCatch(vect(file.path(DATA, "gadm_ssa.gpkg")), error = function(e) NULL)

# Enumerate crops from the targeted/ folder so this stays robust to additions
crop_files <- list.files(file.path(DATA, "economics_erw", "targeted"),
                         pattern = "_year1\\.tif$", full.names = FALSE)
CROPS <- sub("_year1\\.tif$", "", crop_files)
cat("crops detected:", length(CROPS), "->", paste(CROPS, collapse = ", "), "\n")

econ_path <- function(alloc, crop, regime) {
  file.path(DATA, "economics_erw", alloc, paste0(crop, "_", regime, ".tif"))
}

# -- helpers -------------------------------------------------------------------
# Sum a single named band across all crops, area-weighted where appropriate.
# Returns a SpatRaster (per-pixel sum).
sum_band_across_crops <- function(alloc, regime, band_suffix, weight_by_ha = FALSE) {
  acc <- NULL
  wsum <- NULL
  for (cp in CROPS) {
    fp <- econ_path(alloc, cp, regime)
    if (!file.exists(fp)) next
    r  <- rast(fp)
    bnm <- paste0(cp, "_", band_suffix)
    if (!(bnm %in% names(r))) next
    layer <- r[[bnm]]
    if (weight_by_ha) {
      ha <- r[[paste0(cp, "_ha")]]
      contrib <- layer * ha
      contrib <- ifel(is.na(contrib), 0, contrib)
      w       <- ifel(is.na(ha), 0, ha)
      acc  <- if (is.null(acc))  contrib else acc  + contrib
      wsum <- if (is.null(wsum)) w       else wsum + w
    } else {
      contrib <- ifel(is.na(layer), 0, layer)
      acc <- if (is.null(acc)) contrib else acc + contrib
    }
  }
  if (weight_by_ha) {
    out <- acc / wsum
    out <- ifel(wsum <= 0, NA, out)
    out
  } else {
    ifel(acc == 0, NA, acc)
  }
}

plot_map <- function(r, file, title, palette, units_lbl = "",
                     breaks = NULL, width = 1300, height = 1100, res = 150) {
  if (nlyr(r) > 1) r <- r[[1]]
  fp <- file.path(MAP_OUT, file)
  png(fp, width = width, height = height, res = res)
  par(mar = c(2.5, 2.5, 3.5, 5.5))
  args <- list(x = r, main = title, col = palette, axes = TRUE,
               cex.main = 1.0, plg = list(title = units_lbl, cex = 0.85))
  if (!is.null(breaks)) args$breaks <- breaks
  do.call(plot, args)
  if (!is.null(ssa)) plot(ssa, add = TRUE, lwd = 0.35, border = "grey25")
  dev.off()
  message("wrote ", fp)
}

# Diverging palette for GM (centered at 0)
gm_palette <- function(n = 21) {
  hcl.colors(n, "RdYlGn", rev = FALSE)
}

# -- 1) Continent-wide GM maps -------------------------------------------------
# Two products per (regime, alloc):
#   a) total GM $/pixel  (sum of agro+CDR-basalt × ha, across crops)
#   b) area-weighted mean GM $/ha (better for visual comparison)
cat("\n== continent-wide GM maps ==\n")
ssa_tables <- list()
for (alloc in ALLOCS) {
  for (regime in REGIMES) {
    cat(alloc, "|", regime, "\n")
    gm_per_ha <- sum_band_across_crops(alloc, regime, "gm_combined_usha", weight_by_ha = TRUE)
    if (is.null(gm_per_ha)) next

    # symmetric breaks around 0 so the diverging palette aligns with sign
    qs <- as.numeric(global(gm_per_ha, fun = function(v) {
      v <- v[is.finite(v)]
      if (!length(v)) return(c(NA_real_, NA_real_))
      quantile(v, c(0.02, 0.98), na.rm = TRUE)
    }))
    lim <- max(abs(qs), na.rm = TRUE)
    if (!is.finite(lim) || lim == 0) lim <- 100
    brks <- seq(-lim, lim, length.out = 22)

    plot_map(
      gm_per_ha,
      sprintf("ssa_gm_%s_%s.png", regime, alloc),
      sprintf("Crop-weighted GM ($/ha) — %s, %s allocation", regime, alloc),
      gm_palette(21),
      units_lbl = "$ / ha",
      breaks = brks
    )

    # contemporaneous summary row
    ha_total  <- sum_band_across_crops(alloc, regime, "ha", weight_by_ha = FALSE)
    gm_total_usd <- 0
    ha_pos_total <- 0
    cdr_total_t  <- 0
    cdr_pos_t    <- 0
    agro_total   <- 0
    basalt_total <- 0
    cdr_rev_total <- 0
    for (cp in CROPS) {
      fp <- econ_path(alloc, cp, regime)
      if (!file.exists(fp)) next
      r <- rast(fp)
      ha <- r[[paste0(cp, "_ha")]]
      gm <- r[[paste0(cp, "_gm_combined_usha")]]
      cdr_net <- r[[paste0(cp, "_cdr_net_tha")]]
      agro <- r[[paste0(cp, "_agro_return_usha")]]
      bcost <- r[[paste0(cp, "_basalt_cost_usha")]]
      crev  <- r[[paste0(cp, "_cdr_revenue_usha")]]

      gm_total_usd  <- gm_total_usd  + as.numeric(global(gm * ha,   "sum", na.rm = TRUE))
      cdr_total_t   <- cdr_total_t   + as.numeric(global(cdr_net*ha,"sum", na.rm = TRUE))
      agro_total    <- agro_total    + as.numeric(global(agro * ha, "sum", na.rm = TRUE))
      basalt_total  <- basalt_total  + as.numeric(global(bcost* ha, "sum", na.rm = TRUE))
      cdr_rev_total <- cdr_rev_total + as.numeric(global(crev * ha, "sum", na.rm = TRUE))
      ha_pos <- ifel(gm > 0, ha, 0)
      ha_pos_total <- ha_pos_total + as.numeric(global(ha_pos, "sum", na.rm = TRUE))
      cdr_pos <- ifel(gm > 0, cdr_net * ha, 0)
      cdr_pos_t <- cdr_pos_t + as.numeric(global(cdr_pos, "sum", na.rm = TRUE))
    }
    ssa_tables[[length(ssa_tables) + 1]] <- data.frame(
      regime = regime, allocation = alloc,
      total_gm_musd        = round(gm_total_usd / 1e6, 1),
      total_agro_musd      = round(agro_total   / 1e6, 1),
      total_basalt_musd    = round(basalt_total / 1e6, 1),
      total_cdr_revenue_musd = round(cdr_rev_total / 1e6, 1),
      total_cdr_mt         = round(cdr_total_t / 1e6, 2),
      profitable_mha       = round(ha_pos_total / 1e6, 2),
      cdr_on_profitable_mt = round(cdr_pos_t / 1e6, 2)
    )
  }
}

ssa_df <- do.call(rbind, ssa_tables)
write.csv(ssa_df, file.path(TBL_OUT, "output-ssa-summary.csv"), row.names = FALSE)
cat("\nwrote", file.path(TBL_OUT, "output-ssa-summary.csv"), "\n")
print(ssa_df)

# -- 2) Per-crop GM maps for key crops ----------------------------------------
cat("\n== per-crop GM maps (key crops, targeted) ==\n")
for (cp in KEY_CROPS) {
  for (regime in c("year1", "npv")) {
    fp <- econ_path("targeted", cp, regime)
    if (!file.exists(fp)) { message("skip ", fp); next }
    r <- rast(fp)
    gm <- r[[paste0(cp, "_gm_combined_usha")]]
    qs <- as.numeric(global(gm, fun = function(v) {
      v <- v[is.finite(v)]; if (!length(v)) return(c(NA_real_, NA_real_))
      quantile(v, c(0.02, 0.98), na.rm = TRUE)
    }))
    lim <- max(abs(qs), na.rm = TRUE); if (!is.finite(lim) || lim == 0) lim <- 100
    brks <- seq(-lim, lim, length.out = 22)
    plot_map(
      gm,
      sprintf("crop_gm_%s_%s_targeted.png", cp, regime),
      sprintf("Gross margin ($/ha) — %s, %s, targeted", cp, regime),
      gm_palette(21),
      units_lbl = "$ / ha",
      breaks = brks
    )
  }
}

# -- 3) Profitable-pixel masks -------------------------------------------------
cat("\n== profitable-pixel masks ==\n")
for (alloc in ALLOCS) {
  for (regime in REGIMES) {
    gm_per_ha <- sum_band_across_crops(alloc, regime, "gm_combined_usha", weight_by_ha = TRUE)
    if (is.null(gm_per_ha)) next
    mask <- ifel(gm_per_ha > 0, 1, ifel(gm_per_ha <= 0, 0, NA))
    fp <- file.path(MAP_OUT, sprintf("profitable_mask_%s_%s.png", regime, alloc))
    png(fp, width = 1300, height = 1100, res = 150)
    par(mar = c(2.5, 2.5, 3.5, 5.5))
    plot(mask,
         main = sprintf("Profitable pixels (crop-weighted GM > 0) — %s, %s", regime, alloc),
         col  = c("grey85", "#2c7a3f"),
         axes = TRUE,
         type = "classes",
         levels = c("GM <= 0", "GM > 0"),
         plg  = list(cex = 0.85))
    if (!is.null(ssa)) plot(ssa, add = TRUE, lwd = 0.35, border = "grey25")
    dev.off()
    message("wrote ", fp)
  }
}

# -- 4) Carbon-price breakeven maps -------------------------------------------
# GM = agro + cdr_net * (carbon_price - mrv) - basalt_cost
# Setting GM=0 and solving for carbon_price:
#   breakeven_cp = (basalt_cost - agro) / cdr_net + mrv
# Per-pixel crop-weighted version:
#   numerator  = sum_c ha_c * (basalt_cost_c - agro_c)
#   denominator = sum_c ha_c * cdr_net_c
#   breakeven_cp = numerator / denominator + MRV
# Pixels with denom<=0 (no CDR) are masked. Cap at 500 $/tCO2 for legibility.
MRV <- 30
cat("\n== breakeven carbon-price maps ==\n")
for (alloc in ALLOCS) {
  for (regime in REGIMES) {
    cat(alloc, "|", regime, "\n")
    num <- NULL; den <- NULL
    for (cp in CROPS) {
      fp <- econ_path(alloc, cp, regime)
      if (!file.exists(fp)) next
      r <- rast(fp)
      ha <- r[[paste0(cp, "_ha")]]
      basalt <- r[[paste0(cp, "_basalt_cost_usha")]]
      agro   <- r[[paste0(cp, "_agro_return_usha")]]
      cdr_n  <- r[[paste0(cp, "_cdr_net_tha")]]
      nc <- ifel(is.na(ha), 0, ha) * (ifel(is.na(basalt), 0, basalt) - ifel(is.na(agro), 0, agro))
      dc <- ifel(is.na(ha), 0, ha) *  ifel(is.na(cdr_n),  0, cdr_n)
      num <- if (is.null(num)) nc else num + nc
      den <- if (is.null(den)) dc else den + dc
    }
    be <- num / den + MRV
    be <- ifel(den <= 0, NA, be)
    be <- ifel(be < 0, 0, be)
    be <- ifel(be > 500, 500, be)
    plot_map(
      be,
      sprintf("breakeven_carbon_%s_%s.png", regime, alloc),
      sprintf("Breakeven carbon price ($/tCO2) — %s, %s (MRV=$%d)", regime, alloc, MRV),
      hcl.colors(20, "YlOrRd", rev = TRUE),
      units_lbl = "$ / tCO2"
    )
  }
}

# -- 5) Country-level breakdown table -----------------------------------------
cat("\n== country-level breakdown table ==\n")
if (is.null(ssa)) {
  warning("no gadm_ssa.gpkg — skipping country table")
} else {
  country_rows <- list()
  # Pre-rasterise countries once at the working grid for speed
  ref <- rast(econ_path("targeted", CROPS[1], "year1"))[[1]]
  country_r <- rasterize(ssa, ref, field = "GID_0")
  country_lookup <- levels(country_r)[[1]]
  for (alloc in ALLOCS) {
    for (regime in REGIMES) {
      cat(alloc, "|", regime, "\n")
      gm_usd_total <- NULL; cdr_t_total <- NULL; ha_pos_total <- NULL
      for (cp in CROPS) {
        fp <- econ_path(alloc, cp, regime)
        if (!file.exists(fp)) next
        r <- rast(fp)
        ha <- r[[paste0(cp, "_ha")]]
        gm <- r[[paste0(cp, "_gm_combined_usha")]]
        cdr_net <- r[[paste0(cp, "_cdr_net_tha")]]
        gm_usd  <- ifel(is.na(gm * ha), 0, gm * ha)
        cdr_t   <- ifel(is.na(cdr_net * ha), 0, cdr_net * ha)
        # Use !is.na guards so NA pixels (no harvested area / no soil data)
        # contribute 0 rather than poisoning the zonal sum.
        gm_pos_mask <- !is.na(gm) & gm > 0
        ha_pos  <- ifel(gm_pos_mask, ifel(is.na(ha), 0, ha), 0)
        gm_usd_total  <- if (is.null(gm_usd_total))  gm_usd  else gm_usd_total  + gm_usd
        cdr_t_total   <- if (is.null(cdr_t_total))   cdr_t   else cdr_t_total   + cdr_t
        ha_pos_total  <- if (is.null(ha_pos_total))  ha_pos  else ha_pos_total  + ha_pos
      }
      gm_by_c  <- zonal(gm_usd_total, country_r, fun = "sum", na.rm = TRUE)
      cdr_by_c <- zonal(cdr_t_total,  country_r, fun = "sum", na.rm = TRUE)
      ha_by_c  <- zonal(ha_pos_total, country_r, fun = "sum", na.rm = TRUE)
      m <- merge(gm_by_c, cdr_by_c, by = "GID_0")
      m <- merge(m,       ha_by_c,  by = "GID_0")
      names(m) <- c("iso3", "gm_musd", "cdr_mt", "profitable_mha")
      m$gm_musd        <- round(m$gm_musd / 1e6, 2)
      m$cdr_mt         <- round(m$cdr_mt  / 1e6, 3)
      m$profitable_mha <- round(m$profitable_mha / 1e6, 3)
      m$regime <- regime
      m$allocation <- alloc
      country_rows[[length(country_rows) + 1]] <- m[, c("regime","allocation","iso3","gm_musd","cdr_mt","profitable_mha")]
    }
  }
  country_df <- do.call(rbind, country_rows)
  write.csv(country_df, file.path(TBL_OUT, "output-country-summary.csv"), row.names = FALSE)
  cat("wrote", file.path(TBL_OUT, "output-country-summary.csv"),
      "(", nrow(country_df), "rows )\n")
}

# -- 6) Crop ranking table ----------------------------------------------------
cat("\n== crop ranking table ==\n")
crop_rows <- list()
for (alloc in ALLOCS) {
  for (regime in REGIMES) {
    for (cp in CROPS) {
      fp <- econ_path(alloc, cp, regime)
      if (!file.exists(fp)) next
      r <- rast(fp)
      ha <- r[[paste0(cp, "_ha")]]
      gm <- r[[paste0(cp, "_gm_combined_usha")]]
      agro <- r[[paste0(cp, "_agro_return_usha")]]
      bcost <- r[[paste0(cp, "_basalt_cost_usha")]]
      crev <- r[[paste0(cp, "_cdr_revenue_usha")]]
      cdr_net <- r[[paste0(cp, "_cdr_net_tha")]]
      gm_total <- as.numeric(global(gm * ha, "sum", na.rm = TRUE))
      ha_pos <- as.numeric(global(ifel(gm > 0, ha, 0), "sum", na.rm = TRUE))
      cdr_total <- as.numeric(global(cdr_net * ha, "sum", na.rm = TRUE))
      crop_rows[[length(crop_rows) + 1]] <- data.frame(
        regime = regime, allocation = alloc, crop = cp,
        gm_total_musd        = round(gm_total / 1e6, 2),
        profitable_mha       = round(ha_pos / 1e6, 3),
        cdr_total_mt         = round(cdr_total / 1e6, 3),
        agro_total_musd      = round(as.numeric(global(agro * ha, "sum", na.rm = TRUE)) / 1e6, 2),
        basalt_total_musd    = round(as.numeric(global(bcost * ha, "sum", na.rm = TRUE)) / 1e6, 2),
        cdr_revenue_total_musd = round(as.numeric(global(crev * ha, "sum", na.rm = TRUE)) / 1e6, 2)
      )
    }
  }
}
crop_df <- do.call(rbind, crop_rows)
write.csv(crop_df, file.path(TBL_OUT, "output-crop-ranking.csv"), row.names = FALSE)
cat("wrote", file.path(TBL_OUT, "output-crop-ranking.csv"),
    "(", nrow(crop_df), "rows )\n")

cat("\nAll profitability maps -> ", MAP_OUT, "\n")
cat("All profitability tables -> ", TBL_OUT, "\n")

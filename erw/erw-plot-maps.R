# erw-plot-maps.R
#
# Render a panel of indicator / outcome maps from the ERW pipeline outputs
# using terra.  Writes PNGs into docs/maps/.

suppressMessages({
  library(terra)
})

# Paths -----------------------------------------------------------------------
ROOT <- normalizePath(".")
DATA <- file.path(ROOT, "data")
OUT  <- file.path(ROOT, "docs", "maps")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

# Country borders -------------------------------------------------------------
ssa <- tryCatch(vect(file.path(DATA, "gadm_ssa.gpkg")), error = function(e) NULL)

# Helper ----------------------------------------------------------------------
plot_map <- function(r, file, title, palette,
                     units_lbl = "", width = 1300, height = 1100, res = 150) {
  if (terra::nlyr(r) > 1) r <- r[[1]]
  fp <- file.path(OUT, file)
  png(fp, width = width, height = height, res = res)
  par(mar = c(2.5, 2.5, 3.5, 5.5))
  plot(r,
       main  = title,
       col   = palette,
       axes  = TRUE,
       cex.main = 1.0,
       plg   = list(title = units_lbl, cex = 0.85))
  if (!is.null(ssa)) plot(ssa, add = TRUE, lwd = 0.35, border = "grey25")
  dev.off()
  message("wrote ", fp)
}

pick_band <- function(r, patterns) {
  nm <- names(r)
  for (p in patterns) {
    hit <- grep(p, nm, value = TRUE, ignore.case = TRUE)
    if (length(hit)) return(hit[1])
  }
  nm[1]
}

# Catalogue of what to plot ---------------------------------------------------
# 1. Soil pH ------------------------------------------------------------------
sg_path <- file.path(DATA, "soilgrids_properties_cropland.tif")
if (file.exists(sg_path)) {
  sg <- rast(sg_path)
  message("soilgrids bands: ", paste(names(sg), collapse = ", "))
  ph_band <- pick_band(sg, c("^ph_", "^phh2o", "^ph$", "pH"))
  message("using pH band: ", ph_band)
  ph <- sg[[ph_band]]
  # SoilGrids pH is sometimes scaled by 10 (so pH=58 -> 5.8).  Detect.
  mx <- as.numeric(global(ph, "max", na.rm = TRUE))
  if (!is.na(mx) && mx > 14) ph <- ph / 10
  plot_map(ph, "01-soil-ph.png",
           "Soil pH (topsoil, cropland mask)",
           hcl.colors(20, "Spectral", rev = TRUE),
           units_lbl = "pH")
}

# 2. Basalt application rate (LiTAS year-1) -----------------------------------
b_path <- file.path(DATA, "basalt_merlos.tif")
if (file.exists(b_path)) {
  b <- rast(b_path)
  plot_map(b, "02-basalt-rate-merlos.png",
           "Basalt application rate (LiTAS year-1, t / ha)",
           hcl.colors(20, "YlOrBr"),
           units_lbl = "t / ha")
}

# 3. CDR per tonne basalt (efficiency surface) --------------------------------
cdr_t_path <- file.path(DATA, "cdr_per_t_basalt.tif")
if (file.exists(cdr_t_path)) {
  cdr_t <- rast(cdr_t_path)
  plot_map(cdr_t, "03-cdr-per-t-basalt.png",
           "CDR efficiency (t CO2 per t basalt) - climate x pH x pedogenic-C net",
           hcl.colors(20, "Viridis"),
           units_lbl = "t CO2 / t")
}

# 4. CDR yield (LiTAS year-1, cumulative) -------------------------------------
cdr_y_path <- file.path(DATA, "cdr_yield_merlos.tif")
if (file.exists(cdr_y_path)) {
  cdr_y <- rast(cdr_y_path)
  plot_map(cdr_y, "04-cdr-yield-merlos.png",
           "Cumulative CDR yield (LiTAS year-1, t CO2 / ha)",
           hcl.colors(20, "Mako", rev = TRUE),
           units_lbl = "t CO2 / ha")
}

# 5. Climate scaling factor ---------------------------------------------------
cf_path <- file.path(DATA, "cdr_climate_factor.tif")
if (file.exists(cf_path)) {
  cf <- rast(cf_path)
  plot_map(cf, "05-cdr-climate-factor.png",
           "CDR climate scaling factor  -  f(MAT, MAP)",
           hcl.colors(20, "BluYl"),
           units_lbl = "factor")
}

# 6. Pedogenic-C deduction fraction -------------------------------------------
pc_path <- file.path(DATA, "cdr_pedogenic_fraction.tif")
if (file.exists(pc_path)) {
  pc <- rast(pc_path)
  plot_map(pc, "06-pedogenic-fraction.png",
           "Pedogenic-C fraction lost locally (aridity bands)",
           hcl.colors(20, "Reds 3", rev = TRUE),
           units_lbl = "fraction")
}

# 7. Industrial electricity price ---------------------------------------------
el_path <- file.path(DATA, "electricity_usd_kWh.tif")
if (file.exists(el_path)) {
  el <- rast(el_path)
  plot_map(el, "07-electricity-price.png",
           "Industrial electricity price ($ / kWh)",
           hcl.colors(20, "Plasma"),
           units_lbl = "$ / kWh")
}

# 8. Grid carbon intensity ----------------------------------------------------
ci_path <- file.path(DATA, "grid_CI_kg_per_kWh.tif")
if (file.exists(ci_path)) {
  ci <- rast(ci_path)
  plot_map(ci, "08-grid-CI.png",
           "Grid carbon intensity (kg CO2 / kWh)",
           hcl.colors(20, "Inferno", rev = TRUE),
           units_lbl = "kg / kWh")
}

# 9. Basalt source mask (lithology) -------------------------------------------
# Binary mask; render as a single-colour overlay against a soft background.
src_path <- file.path(DATA, "basalt_source_mask.tif")
if (file.exists(src_path)) {
  src <- rast(src_path)
  n <- as.numeric(global(src, "notNA"))
  if (!is.na(n) && n > 0) {
    fp <- file.path(OUT, "09-basalt-sources.png")
    png(fp, width = 1300, height = 1100, res = 150)
    par(mar = c(2.5, 2.5, 3.5, 5.5))
    plot(src,
         main   = "Basalt source rocks (GLiM v1 basic volcanics)",
         col    = "tomato",
         legend = FALSE,
         axes   = TRUE,
         background = "grey95")
    if (!is.null(ssa)) plot(ssa, add = TRUE, lwd = 0.35, border = "grey25")
    legend("bottomleft",
           legend = "basic volcanic outcrop (basalt)",
           fill   = "tomato",
           border = "tomato",
           bty    = "n",
           cex    = 0.85)
    dev.off()
    message("wrote ", fp)
  } else {
    message("skipped 09-basalt-sources.png (mask empty - run erw-build-basalt-mask.R first)")
  }
}

# 10. Travel time to nearest basalt source ------------------------------------
tt_path <- file.path(DATA, "basalt_traveltime_min.tif")
if (file.exists(tt_path)) {
  tt <- rast(tt_path)
  plot_map(tt, "10-basalt-traveltime.png",
           "Travel time to nearest basalt source (cost-distance on MAP friction, minutes)",
           hcl.colors(20, "Inferno", rev = TRUE),
           units_lbl = "min")
}

# 11. Delivered basalt price --------------------------------------------------
dp_path <- file.path(DATA, "basalt_delivered_price_usd_t.tif")
if (file.exists(dp_path)) {
  dp <- rast(dp_path)
  plot_map(dp, "11-basalt-delivered-price.png",
           "Delivered mafic-feedstock price ($ / t) - quarry gate + cost-distance haulage",
           hcl.colors(20, "Reds 3", rev = TRUE),
           units_lbl = "$ / t")
}

# 12. Feedstock-class map (categorical: basalt vs gabbro) ---------------------
cls_path <- file.path(DATA, "basalt_source_class.tif")
if (file.exists(cls_path)) {
  cls <- rast(cls_path)
  fp <- file.path(OUT, "12-feedstock-class.png")
  png(fp, width = 1300, height = 1100, res = 150)
  par(mar = c(2.5, 2.5, 3.5, 5.5))
  pal <- c("tomato", "steelblue3")  # vb -> 1, pb -> 3 (py = 2 absent in SSA)
  plot(cls,
       main   = "Mafic feedstock by GLiM class - basic volcanic vs basic plutonic",
       col    = pal,
       axes   = TRUE,
       legend = FALSE,
       background = "grey95")
  if (!is.null(ssa)) plot(ssa, add = TRUE, lwd = 0.35, border = "grey25")
  legend("bottomleft",
         legend = c("vb - basalt (basic volcanic)", "pb - gabbro (basic plutonic)"),
         fill   = pal,
         border = pal,
         bty    = "n", cex = 0.85)
  dev.off()
  message("wrote ", fp)
}

message("\nAll maps written to ", OUT)

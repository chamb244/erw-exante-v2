
# ------------------------------------------------------------------------------
# erw-basalt-access.R
#
# Builds a per-pixel delivered-basalt-price raster for SSA.
#
#   delivered_price ($/t) = quarry_gate_price + transport_cost
#   transport_cost ($/t)  = cost_distance_to_nearest_source (min) * $/min/t
#
# Transport cost dominates ERW economics, so this layer is the single most
# important input that erw-7-profitability-function.R consumes. Without it,
# basalt cost is a flat constant and the model is blind to the spatial
# heterogeneity that determines where ERW is actually deployable.
#
# Inputs (must be downloaded manually — see notes at each block):
#   GLiM / GLM lithology layer        -> basalt source mask
#   Optionally: quarry point inventory -> active-quarry source mask
#   MAP friction surface 2019 (Weiss)  -> minutes per meter travel
#   gadm_ssa.gpkg                       (from erw-1)
#
# Outputs:
#   basalt_source_mask.tif           (1 = basalt source, NA elsewhere)
#   basalt_traveltime_min.tif        (minutes from each cropland pixel to nearest source)
#   basalt_transport_km.tif          (approximate haul distance, km — for LCA)
#   basalt_transport_cost_usd_t.tif  ($/t transport cost)
#   basalt_delivered_price_usd_t.tif ($/t delivered to farm gate)
# ------------------------------------------------------------------------------

# directories — resolved from the project root via the {here} package
# (anchored by the .here marker at the repo root)
library(here)
input_path  <- paste0(here::here('data'), '/')
access_path <- paste0(here::here('data', 'access'), '/')   # holds manually downloaded inputs
dir.create(access_path, showWarnings=FALSE, recursive=TRUE)

# ------------------------------------------------------------------------------
# economic constants — override per scenario

QUARRY_GATE_PRICE     <- 10     # $/t  ex-quarry basalt fines (typical aggregate by-product)
USD_PER_MIN_PER_T     <- 0.04   # $/min/t  truck haulage operating cost (30-t truck at $80/hr)
MAX_HAUL_KM           <- 1000   # cap travel-time at this distance; further pixels treated as unreachable
KM_PER_HOUR_FREE      <- 60     # off-friction assumption used only for the haul cap
EFFECTIVE_KM_PER_MIN  <- 0.5    # 30 km/h effective speed for distance approximation
                                # (slower than free-flow because real routes
                                # include the friction surface's slow segments)

# ------------------------------------------------------------------------------
# region of interest

ssa <- terra::vect(paste0(input_path, 'gadm_ssa.gpkg'))
ref <- terra::rast(paste0(input_path, 'soilgrids_properties_all.tif'))[[1]]
ref <- terra::aggregate(ref, 10, 'mean', na.rm=TRUE)   # match the working resolution used by erw-7

# ------------------------------------------------------------------------------
# 1) basalt source mask
#
# Preferred source: Hartmann & Moosdorf GLiM (Global Lithological Map),
# https://doi.pangaea.de/10.1594/PANGAEA.788537. Two distributions are supported:
#   - v1.1 file geodatabase  ->  input_path/'LiMW_GIS 2015.gdb'  (CRS: ESRI:54012)
#   - v1.0 shapefile         ->  access_path/glim/LiMW_GIS_2015.shp
# Basalt is the "Basic volcanic" (xx = vb) and "Pyroclastics" classes
# (xx = py in v1.1, vp in v1.0). Adjust the filter if using a richer
# lithology dataset (e.g. national geological surveys).

glim_gdb <- paste0(input_path, 'LiMW_GIS 2015.gdb')
glim_shp <- paste0(access_path, 'glim/LiMW_GIS_2015.shp')

glim <- NULL
# Three mafic classes treated as basalt-equivalent feedstock: basic volcanic
# (basalt s.s.), pyroclastics, basic plutonic (gabbro). Ultramafic classes
# are intentionally excluded for cropland use because of Ni/Cr leaching risk
# — see docs/erw-review.md section 3.
if(dir.exists(glim_gdb)) {
  glim <- terra::vect(glim_gdb, layer='GLiM_export')
  basalt_classes <- c('vb', 'py', 'pb')
} else if(file.exists(glim_shp)) {
  glim <- terra::vect(glim_shp)
  basalt_classes <- c('vb', 'vp', 'pb')
}

if(!is.null(glim)) {
  # crop in GLiM's CRS — projecting all 1.2M global polygons first would be wasteful
  ssa_glim <- terra::project(ssa, terra::crs(glim))
  glim_ssa <- terra::crop(glim, ssa_glim)
  basalt_vec <- glim_ssa[glim_ssa$xx %in% basalt_classes, ]
  basalt_vec <- terra::project(basalt_vec, terra::crs(ref))
  basalt_mask <- terra::rasterize(basalt_vec, ref, field=1, background=NA)
} else {
  warning('GLiM not found at ', glim_gdb, ' or ', glim_shp,
          ' — falling back to a placeholder mask. ',
          'Download GLiM from https://doi.pangaea.de/10.1594/PANGAEA.788537 ',
          'before running for real.')
  basalt_mask <- ref * NA
}
names(basalt_mask) <- 'basalt_source'
terra::writeRaster(basalt_mask, paste0(input_path, 'basalt_source_mask.tif'), overwrite=TRUE)

# ------------------------------------------------------------------------------
# 2) friction surface
#
# Preferred source: Weiss et al. (2020) "Global maps of travel time to healthcare"
# 1km friction surface 2019, available from the Malaria Atlas Project:
#   https://malariaatlas.org/research-project/accessibility-to-cities/
# Or via the {malariaAtlas} R package:
#   library(malariaAtlas)
#   friction <- getRaster(surface = 'A global friction surface enumerating land-based
#                          travel speed for a nominal year 2019')
# The grid is minutes-of-travel per meter, with roads, rivers, urban areas, and
# off-road terrain folded in.

friction_path <- paste0(access_path, 'friction_surface_2019.tif')
if(file.exists(friction_path)) {
  friction <- terra::rast(friction_path)
  friction <- terra::crop(friction, ssa)
  friction <- terra::resample(friction, ref, method='bilinear')
} else {
  warning('Friction surface not found at ', friction_path,
          ' — using a uniform 60 km/h proxy. Download MAP friction surface 2019 ',
          'before running for real.')
  # uniform proxy: 1 m per (60 km/h) = 60 / (60*1000) min/m = 0.001 min/m
  friction <- ref * 0 + 0.001
}
names(friction) <- 'friction_min_per_m'

# ------------------------------------------------------------------------------
# 3) cost-distance from every pixel to nearest basalt source
#
# terra::costDist accumulates the friction surface from a set of source cells.
# Result is minutes-of-travel from the nearest source.

# terra::costDist accumulates from cells whose value in `x` equals `target`.
# We mark basalt-source cells in the friction surface with a sentinel value
# (-1, which the friction surface never takes) and use that as the source.
friction_src <- friction
friction_src[!is.na(basalt_mask)] <- -1
travel_min <- terra::costDist(friction_src, target=-1)
names(travel_min) <- 'travel_min'

# cap unreachable pixels (travel time implying > MAX_HAUL_KM at free-flow speed)
travel_cap_min <- (MAX_HAUL_KM / KM_PER_HOUR_FREE) * 60
travel_min <- terra::clamp(travel_min, 0, travel_cap_min)
terra::writeRaster(travel_min, paste0(input_path, 'basalt_traveltime_min.tif'), overwrite=TRUE)

# ------------------------------------------------------------------------------
# 4) transport cost and delivered price

# transport km — approximate haul distance derived from travel time
# Needed by erw-7 to compute lifecycle CO2 of transport.
transport_km <- travel_min * EFFECTIVE_KM_PER_MIN
names(transport_km) <- 'transport_km'
terra::writeRaster(transport_km, paste0(input_path, 'basalt_transport_km.tif'), overwrite=TRUE)

# transport cost ($/t)
transport_cost <- travel_min * USD_PER_MIN_PER_T
names(transport_cost) <- 'transport_cost_usd_t'
terra::writeRaster(transport_cost, paste0(input_path, 'basalt_transport_cost_usd_t.tif'), overwrite=TRUE)

delivered_price <- QUARRY_GATE_PRICE + transport_cost
names(delivered_price) <- 'delivered_price_usd_t'

# restrict to cropland (consistent with the rest of the pipeline)
crop_area <- terra::rast(paste0(input_path, 'spam_harv_area_processed.tif'))
crop_mask <- terra::ifel(sum(crop_area, na.rm=TRUE) > 0, 1, NA)
crop_mask <- terra::resample(crop_mask, ref, method='near')
delivered_price <- delivered_price * crop_mask
terra::writeRaster(delivered_price, paste0(input_path, 'basalt_delivered_price_usd_t.tif'), overwrite=TRUE)

# ------------------------------------------------------------------------------
# diagnostics

cat('\n--- basalt delivered price ($/t) summary ---\n')
print(terra::global(delivered_price, fun=c('mean','min','max'), na.rm=TRUE))
cat('\n--- travel time to nearest basalt source (min) summary ---\n')
print(terra::global(travel_min, fun=c('mean','min','max'), na.rm=TRUE))

# ------------------------------------------------------------------------------

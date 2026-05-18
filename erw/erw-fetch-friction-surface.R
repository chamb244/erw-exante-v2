# erw-fetch-friction-surface.R
#
# Install the malariaAtlas R package (if missing) and download the
# Malaria Atlas Project motorised friction surface (nominal year 2019),
# cropped to SSA, saving as data/access/friction_surface_2019.tif.
#
# This is the missing input for erw-basalt-access.R (the cost-distance step).

suppressMessages({
  library(terra)
})

DATA   <- "data"
access <- file.path(DATA, "access")
dir.create(access, recursive = TRUE, showWarnings = FALSE)

# --- 1. Install malariaAtlas if absent ---------------------------------------
if (!requireNamespace("malariaAtlas", quietly = TRUE)) {
  message("Installing malariaAtlas + dependencies ...")
  install.packages("malariaAtlas",
                   repos = "https://cloud.r-project.org",
                   Ncpus = max(1, parallel::detectCores() - 1))
}
library(malariaAtlas)

# --- 2. SSA bounding box (force EPSG:4326 — malariaAtlas requires it) -------
ssa <- vect(file.path(DATA, "gadm_ssa.gpkg"))
ssa <- project(ssa, "EPSG:4326")

# --- 3. Resolve dataset_id from the catalogue (malariaAtlas 1.6+ uses
#       dataset_id, not `surface`). -----------------------------------------
message("Listing available rasters from the Malaria Atlas Project ...")
catalogue <- listRaster()
hit <- catalogue[grepl("motoriz(ed|ised)?_friction_surface", catalogue$dataset_id, ignore.case = TRUE), ]
if (nrow(hit) == 0) {
  hit <- catalogue[grepl("friction_surface", catalogue$dataset_id, ignore.case = TRUE), ]
}
if (nrow(hit) == 0) stop("No friction-surface dataset_id found in catalogue")
message("Candidate friction-surface entries:")
print(hit[, intersect(c("dataset_id", "title"), names(hit))])

# Prefer the entry whose title explicitly says "2019" (motorised friction surface
# for the nominal year 2019).
ds_2019 <- hit$dataset_id[grepl("2019", hit$title, ignore.case = TRUE) &
                          grepl("motoriz", hit$dataset_id, ignore.case = TRUE)]
ds <- if (length(ds_2019)) ds_2019[1] else
      hit$dataset_id[grepl("motoriz", hit$dataset_id, ignore.case = TRUE)][1]
if (is.na(ds)) ds <- hit$dataset_id[1]
message("Using dataset_id: ", ds)

# malariaAtlas calls vect() on the shp internally; pass an {sf} object instead
# of a SpatVector to avoid a dispatch error.
if (!requireNamespace("sf", quietly = TRUE)) {
  install.packages("sf", repos = "https://cloud.r-project.org")
}
ssa_sf <- sf::st_as_sf(ssa)
res <- malariaAtlas::getRaster(dataset_id = ds, shp = ssa_sf)
if (is.null(res)) stop("getRaster returned NULL for ", ds)

# --- 4. Coerce, crop, write --------------------------------------------------
fr <- if (inherits(res, "SpatRaster")) res else rast(res)
fr <- crop(fr, ext(ssa))
out <- file.path(access, "friction_surface_2019.tif")
writeRaster(fr, out, overwrite = TRUE, gdal = c("COMPRESS=DEFLATE", "TILED=YES"))
message("wrote ", out, " (", round(file.size(out) / 1e6, 1), " MB)")
message("dims: ", paste(dim(fr), collapse = " x "),
        " | res: ", paste(round(res(fr), 5), collapse = ", "))

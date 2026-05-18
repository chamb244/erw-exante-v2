# erw-build-basalt-mask.R
#
# Build the basalt-source mask (GLiM v1 basic volcanics) at the SoilGrids
# working-grid resolution, clipped to SSA.  Writes data/basalt_source_mask.tif
# in place (overwriting the empty stub left by an incomplete run of
# erw-basalt-access.R).

suppressMessages({
  library(terra)
  library(here)
})

# Paths — resolved from the project root via the {here} package
# (anchored by the .here marker at the repo root)
DATA <- here::here("data")
gdb  <- file.path(DATA, "LiMW_GIS 2015.gdb")
ref  <- rast(file.path(DATA, "soilgrids_properties_all.tif"))[[1]]
ssa  <- vect(file.path(DATA, "gadm_ssa.gpkg"))

# Three mafic GLiM classes are treated as basalt-equivalent feedstock:
#   vb -- basic volcanic    (basalt s.s.; the default in the literature)
#   py -- pyroclastics      (basaltic tuff/agglomerate; same chemistry)
#   pb -- basic plutonic    (gabbro; the intrusive equivalent of basalt)
# Ultramafic ('um' / 'pi' if present) is intentionally excluded for cropland
# use because of Ni/Cr leaching concerns (see docs/erw-review.md section 3).
classes <- c("vb", "py", "pb")
class_codes <- setNames(seq_along(classes), classes)  # vb=1, py=2, pb=3

message("Reading mafic polygons (xx IN ", paste(classes, collapse = ", "), ") from GLiM ...")
vb_global <- vect(gdb,
                  query = sprintf(
                    "SELECT * FROM GLiM_export WHERE xx IN (%s)",
                    paste(sprintf("'%s'", classes), collapse = ", ")
                  ))
message("  global polygons:  ", nrow(vb_global),
        " (projection: ", crs(vb_global, describe = TRUE)$name, ")")
message("  by class (global):")
print(table(as.character(values(vb_global)[["xx"]])))

# GLiM is in Eckert IV (metres); reproject to lat/lon to match the working grid
vb_global <- project(vb_global, crs(ref))

# Bound to SSA extent so subsequent ops are cheap
vb_global <- crop(vb_global, ext(ssa))
message("  after SSA crop:   ", nrow(vb_global))
message("  by class (SSA):")
print(table(as.character(values(vb_global)[["xx"]])))

# 1) Binary mask consumed by erw-basalt-access.R for cost-distance
message("Rasterizing binary mask ...")
mask_bin <- rasterize(vb_global, ref, field = 1, background = NA, touches = TRUE)
mask_bin <- mask(mask_bin, ssa)
names(mask_bin) <- "basalt_source"
writeRaster(mask_bin, file.path(DATA, "basalt_source_mask.tif"), overwrite = TRUE)
message("wrote data/basalt_source_mask.tif - non-NA pixels: ",
        as.numeric(global(mask_bin, "notNA")))

# 2) Categorical raster: 1 = basalt, 2 = pyroclastic, 3 = gabbro
message("Rasterizing categorical class raster ...")
vb_global$class_code <- class_codes[as.character(values(vb_global)[["xx"]])]
mask_cls <- rasterize(vb_global, ref, field = "class_code",
                      background = NA, touches = TRUE)
mask_cls <- mask(mask_cls, ssa)
levels(mask_cls) <- data.frame(id = unname(class_codes),
                               class = paste0(names(class_codes),
                                              c(" (basalt s.s.)",
                                                " (pyroclastics)",
                                                " (gabbro)")))
names(mask_cls) <- "feedstock_class"
writeRaster(mask_cls, file.path(DATA, "basalt_source_class.tif"), overwrite = TRUE)
message("wrote data/basalt_source_class.tif - cell counts by class:")
print(freq(mask_cls))

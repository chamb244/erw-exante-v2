# Prep GADM level-0 layers for the interactive explorer:
#   data/country_id_grid.tif        integer country code per working-grid cell
#   data/explorer_country_codes.csv code, iso3, name
#   data/explorer_gadm0.geojson     simplified level-0 boundaries (lon/lat)
# Run: Rscript paper/analysis/build_explorer_geo.R
suppressMessages({ library(terra); library(here) })
DATA <- here::here("data")

ref <- rast(file.path(DATA, "economics_erw", "targeted", "MAIZ_equilibrium.tif"))[[1]]
ssa <- vect(file.path(DATA, "gadm_ssa.gpkg"))

# stable integer codes 1..N in GID_0 order
iso <- sort(unique(ssa$GID_0))
codes <- data.frame(code = seq_along(iso), iso3 = iso)
nm <- unique(data.frame(iso3 = ssa$GID_0, name = ssa$NAME_0))
codes <- merge(codes, nm, by = "iso3", all.x = TRUE)
codes <- codes[order(codes$code), c("code", "iso3", "name")]
ssa$code <- codes$code[match(ssa$GID_0, codes$iso3)]

cid <- rasterize(ssa, ref, field = "code")
writeRaster(cid, file.path(DATA, "country_id_grid.tif"), overwrite = TRUE,
            datatype = "INT1U", NAflag = 0)
write.csv(codes, file.path(DATA, "explorer_country_codes.csv"), row.names = FALSE)
cat("country_id_grid.tif +", nrow(codes), "codes written\n")

# simplified boundaries -> GeoJSON (lon/lat). ~0.04 deg keeps borders smooth+compact.
ssa_s <- simplifyGeom(ssa, tolerance = 0.04, preserveTopology = TRUE)
bnd <- as.lines(ssa_s)
gj <- file.path(DATA, "explorer_gadm0.geojson")
writeVector(bnd, gj, filetype = "GeoJSON", overwrite = TRUE)
cat("boundaries written:", gj, "\n")

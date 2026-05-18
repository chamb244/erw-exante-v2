
# ------------------------------------------------------------------------------
# erw-energy-country.R
#
# Produces per-pixel rasters of electricity price ($/kWh, industrial tariff)
# and grid carbon intensity (kg CO2 / kWh) for SSA. Consumed by erw-7 to
# replace its flat ELECTRICITY_USD_KWH and GRID_CI_KG_PER_KWH constants with
# country-specific values.
#
# Sources (approximate values — calibrate against latest IEA / Ember / GET.invest
# data for a production run):
#   - Grid CI: Ember Climate Data Explorer 2023 + IEA Africa Energy Outlook 2024
#   - Electricity: GET.invest / AfDB tariff database 2022–2024
#
# Grid CI ranges from ~0.03 kg/kWh (Ethiopia, DRC, Mozambique — hydro-dominated)
# to ~0.95 kg/kWh (South Africa — coal-dominated). This range matters: a 30×
# spread in grinding emissions means the same ERW project that produces credits
# in Ethiopia produces almost no net credits in South Africa.
#
# Inputs:
#   gadm_ssa.gpkg                 (from erw-1)
#   soilgrids_properties_all.tif  (reference grid, from erw-1)
#
# Outputs:
#   electricity_usd_kWh.tif       ($/kWh, industrial tariff)
#   grid_CI_kg_per_kWh.tif        (kg CO2 / kWh)
#   country_energy_table.csv      (canonical table — edit here, re-run script)
# ------------------------------------------------------------------------------

input_path  <- 'D:/# Jvasco/Working Papers/GAIA Guiding Acid Soil Investments/1-ex-ante-analysis/input-data/'

# ------------------------------------------------------------------------------
# 1) country energy table — SSA countries

energy <- data.frame(
  iso3 = c('AGO','BEN','BWA','BFA','BDI','CMR','CAF','TCD','COG','COD','GNQ',
           'ERI','SWZ','ETH','GAB','GMB','GHA','GIN','GNB','CIV','KEN','LSO',
           'LBR','MDG','MWI','MLI','MRT','MOZ','NAM','NER','NGA','RWA','SEN',
           'SLE','SOM','SSD','SDN','TZA','TGO','UGA','ZAF','ZMB','ZWE'),
  electricity_usd_kWh = c(
    0.08, 0.18, 0.12, 0.20, 0.18, 0.10, 0.30, 0.35, 0.12, 0.10, 0.18,
    0.20, 0.10, 0.05, 0.15, 0.20, 0.12, 0.18, 0.30, 0.10, 0.15, 0.10,
    0.30, 0.20, 0.13, 0.20, 0.25, 0.10, 0.15, 0.20, 0.10, 0.15, 0.18,
    0.30, 0.40, 0.40, 0.15, 0.13, 0.18, 0.13, 0.10, 0.08, 0.12),
  grid_CI_kg_per_kWh = c(
    0.35, 0.55, 0.85, 0.55, 0.10, 0.30, 0.45, 0.65, 0.45, 0.03, 0.35,
    0.60, 0.45, 0.03, 0.35, 0.55, 0.40, 0.15, 0.55, 0.35, 0.10, 0.30,
    0.45, 0.45, 0.10, 0.45, 0.55, 0.10, 0.45, 0.60, 0.40, 0.30, 0.55,
    0.55, 0.65, 0.55, 0.30, 0.30, 0.40, 0.03, 0.95, 0.05, 0.50)
)
write.csv(energy, paste0(input_path, 'country_energy_table.csv'), row.names = FALSE)

# ------------------------------------------------------------------------------
# 2) build country raster keyed by ISO3 → integer code

ssa <- terra::vect(paste0(input_path, 'gadm_ssa.gpkg'))
ref <- terra::rast(paste0(input_path, 'soilgrids_properties_all.tif'))[[1]]
ref <- terra::aggregate(ref, 10, 'mean', na.rm = TRUE)

# join the country code as an integer for rasterization
energy$code <- seq_len(nrow(energy))
ssa_df <- as.data.frame(ssa)
ssa_df$code <- match(ssa$GID_0, energy$iso3)
ssa$code    <- ssa_df$code

country_raster <- terra::rasterize(ssa, ref, field = 'code')
names(country_raster) <- 'country_code'

# ------------------------------------------------------------------------------
# 3) build electricity and grid-CI rasters via classification

elec_mat <- cbind(energy$code, energy$electricity_usd_kWh)
ci_mat   <- cbind(energy$code, energy$grid_CI_kg_per_kWh)

electricity_raster <- terra::classify(country_raster, elec_mat, others = NA)
grid_ci_raster     <- terra::classify(country_raster, ci_mat,   others = NA)

names(electricity_raster) <- 'electricity_usd_kWh'
names(grid_ci_raster)     <- 'grid_CI_kg_per_kWh'

terra::writeRaster(electricity_raster, paste0(input_path, 'electricity_usd_kWh.tif'), overwrite = TRUE)
terra::writeRaster(grid_ci_raster,     paste0(input_path, 'grid_CI_kg_per_kWh.tif'), overwrite = TRUE)

# ------------------------------------------------------------------------------
# diagnostics

cat('Electricity price ($/kWh):\n')
print(terra::global(electricity_raster, fun = c('mean', 'min', 'max'), na.rm = TRUE))
cat('Grid carbon intensity (kg CO2/kWh):\n')
print(terra::global(grid_ci_raster, fun = c('mean', 'min', 'max'), na.rm = TRUE))

# ------------------------------------------------------------------------------

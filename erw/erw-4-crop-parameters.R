
# ------------------------------------------------------------------------------
# erw-4-crop-parameters.R
#
# Build per-crop EcoCrop pH and acidity-saturation tolerance tables for the 23
# SPAM crops used downstream. The pH bounds are hard-coded from the EcoCrop
# documentation; the acidity-saturation bounds are loaded from a manually
# curated XLSX. Also writes a crop-type lookup (cereal / legume / RTB /
# commodity) used by erw-7 for grouping.
#
# Inputs:
#   ecocrop_parameters_hp_final.xlsx (external, manually compiled)
#
# Outputs:
#   crop_types.csv
#   ecocrop_parameters_ph.csv
#   ecocrop_parameters_hp.csv
#   crop-parameters-1.png            (response-curve figure)
# ------------------------------------------------------------------------------

# directories — resolved from the project root via the {here} package
# (anchored by the .here marker at the repo root)
library(here)
input_path  <- paste0(here::here('data'), '/')
output_path <- paste0(here::here('data'), '/')

# ------------------------------------------------------------------------------

# crop types
crop_types <- data.frame(crop=c("MAIZ", "SORG", "BEAN", "CHIC", 'LENT', "WHEA", "BARL", "ACOF", "RCOF", 'PMIL', 'SMIL', 'POTA', 'SWPO', 'CASS', 'COWP', 'PIGE', 'SOYB', 'GROU', 'SUGC', 'COTT', 'COCO', 'TEAS', 'TOBA'),
                         type=c('Cereal', "Cereal", "Legume", "Legume", 'Legume', "Cereal", "Cereal", "Commodity", "Commodity", 'Cereal', 'Cereal', 'RTBs', 'RTBs', 'RTBs', 'Legume', 'Legume', 'Legume', 'Legume', 'Commodity', 'Commodity', 'Commodity', 'Commodity', 'Commodity'))
write.csv(crop_types, paste0(input_path, 'crop_types.csv'))

# ------------------------------------------------------------------------------

# figure
png(paste0(output_path, "crop-parameters-1.png"), units="in", width=11.3, height=5.5, res=1000)
par(mfrow=c(1,2), mar=c(4.5,5,1,1), xaxs='i', yaxs='i', las=1, cex.main=1.5, cex.lab=1.4, cex.axis=1.3)

# pH
# max_ph is the soil pH at which the EcoCrop response reaches optimum (=1.0).
# Previously hard-coded at 5.5 for every crop, which (a) capped the linear ramp
# at an unrealistically low value for most cereals and (b) zeroed out the
# agronomic credit for the entire pH 5.5–7.0 belt covering most of SSA
# savanna and Sahel cropland. Per-crop values below are EcoCrop database
# optimum-upper-bounds — acid-loving species (tea, cocoa, coffee) get a low
# max_ph; cereals and legumes get 6.5–7.5.
crops_df_ph <- data.frame(spam=c("MAIZ", "SORG", "BEAN", "CHIC", 'LENT', "WHEA", "BARL", "ACOF", "RCOF", 'PMIL', 'SMIL', 'POTA', 'SWPO', 'CASS', 'COWP', 'PIGE', 'SOYB', 'GROU', 'SUGC', 'COTT', 'COCO', 'TEAS', 'TOBA'),
                       ecocrop=c('Maize', "Sorghum (med. altitude)", "Bean, Common", "Chick pea", 'Lentil', "Wheat, common", "Barley", "Coffee arabica", "Coffee robusta", 'Pearl millet', 'Finger millet', 'Potato', 'Sweet potato', 'Cassava', 'Cowpea', 'Pigeon Pea', 'Soyabean', 'Groundnut', 'Saccharum officinarum L.', 'Cotton, American upland', 'Cacao', 'Tea', 'Tobacco'),
                       min_ph=c(4.5, 4.5, 5.0, 5.0, 5.0, 4.5, 4.5, 4.0, 4.0, 4.5, 4.5, 4.0, 4.0, 4.0, 5.0, 5.0, 5.0, 5.0, 4.0, 4.5, 4.0, 4.0, 4.5),
                       max_ph=c(7.0, 7.5, 6.8, 8.0, 7.5, 7.0, 7.5, 6.5, 6.5, 7.5, 7.0, 6.5, 6.5, 7.0, 7.0, 7.5, 7.0, 7.0, 7.5, 7.5, 6.0, 5.5, 6.5))
write.csv(crops_df_ph, paste0(input_path, 'ecocrop_parameters_ph.csv'))
# Plot one response curve per crop, coloured by crop type. Robust to per-crop
# (min_ph, max_ph) values now that max_ph is no longer a scalar.
crops_for_plot <- merge(crops_df_ph, crop_types, by.x='spam', by.y='crop')
type_colors <- c(Cereal='steelblue', Legume='forestgreen',
                 Commodity='goldenrod', RTBs='sienna')
plot(NULL, xlim=c(3.5, 8), ylim=c(0, 1.05),
     xlab='Soil pH in water', ylab='Relative yield (-)', main='')
grid(nx=10, ny=10)
for(i in seq_len(nrow(crops_for_plot))){
  r <- crops_for_plot[i, ]
  lines(x=c(0, r$min_ph, r$max_ph, 14),
        y=c(0, 0,         1,         1),
        lwd=1.5, col=type_colors[[r$type]])
}
legend('topleft', cex=0.9, legend=names(type_colors), lty=1,
       col=type_colors, lwd=2.5)

# acidity
crops_df <- readxl::read_excel(paste0(input_path, '# ecocrop_parameters_hp_final.xlsx'))
crops_df <- crops_df[c(1,2,9,10)]
crops_df <- subset(crops_df, crops_df$spam %in% crops_df_ph$spam)
names(crops_df)[3:4] <- c('ac_sat', 'max_ac_sat')
write.csv(crops_df, paste0(input_path, 'ecocrop_parameters_hp.csv'))
crops_df <- merge(crops_df, crop_types, by.x='spam', by.y='crop')
crops_df <- unique(crops_df[c(3:5)])
crops_df$crop <- c('coffee', 'maize', 'bean', 'cassava', 'sugarcane', 'cowpea', 'potato', 'sweet potato')
plot(NULL, xlim=c(0,100), ylim=c(0,1.05), xlab='Acidity saturation (% ECEC)', ylab='Relative yield (-)', main='')
grid(nx=10, ny=10)
j <- 1
txt <- c()
col <- c()
for(tp in unique(crops_df$crop)){
  col_crop <- viridis::viridis(nrow(crops_df)*2)[j]
  croptype <- subset(crops_df, crop == tp)
  croptype <- reshape2::melt(croptype, id.vars=c('type', 'crop'))
  croptype$yield <- ifelse(croptype$variable == 'ac_sat', 1, 0)
  lines(x=c(0, croptype$value), y=c(1, croptype$yield), lwd=2.5, col=col_crop)
  j <- j + 2
  txt <- c(txt, tp)
  col <- c(col, col_crop)}
legend('topright', cex=0.9, legend=txt, lty=1, col=col, lwd=2.5)
dev.off()

# ------------------------------------------------------------------------------

# ==============================================================================
# erw_maps_housestyle.R
#
# House-style (bisrat-map-plotting) regeneration of the six ERW result maps used
# in docs/ERW_Public_Private_Returns_Walkthrough — WITH country boundaries as an
# overlay. Ports the compute logic that previously lived in Python
# (paper/analysis/erw_provisional_engine.py + erw_optimal_rate.py); those scripts
# plotted with bare matplotlib imshow and drew no (or barely visible) borders.
#
# Regime: HEADLINE = equilibrium + net-export CDR, targeted allocation
#   net_export_CDR = max(gross_CDR - F*S, 0),  phi = max(1 - F*S/gross, 0)
#   S (equilibrium) = caco3_merlos_maintenance.tif band 1
#
# Maps written to docs/figures/ (names the deck already references):
#   fig-typology.png  fig-private.png  fig-public.png  fig-intersection.png
#   fig-mac.png  fig-optimal-rates.png
#
# Run:  Rscript paper/analysis/erw_maps_housestyle.R
# ==============================================================================

suppressMessages({ library(terra); library(sf); library(ggplot2)
                   library(patchwork); library(here) })
source("~/.claude/skills/bisrat-map-plotting/_maps.R")

DATA   <- here::here("data")
FIGOUT <- here::here("docs", "figures")
dir.create(FIGOUT, showWarnings = FALSE, recursive = TRUE)

CARBON <- 150; MRV <- 20; F <- 0.88
ALLOC  <- "targeted"; REGIME <- "equilibrium"

CROPS <- c("MAIZ","SORG","BEAN","CHIC","LENT","WHEA","BARL","ACOF","RCOF","PMIL",
           "SMIL","POTA","SWPO","CASS","COWP","PIGE","SOYB","GROU","SUGC","COTT",
           "COCO","TEAS","TOBA")

econ <- function(crop, regime = REGIME, alloc = ALLOC)
  file.path(DATA, "economics_erw", alloc, paste0(crop, "_", regime, ".tif"))

# ---- boundaries: SSA countries (simplified), drawn as outlines on top ---------
ssa <- st_read(file.path(DATA, "gadm_ssa.gpkg"), quiet = TRUE)
if (is.na(st_crs(ssa))) st_crs(ssa) <- 4326          # gpkg ships without a CRS tag
ssa <- st_simplify(ssa, dTolerance = 0.02, preserveTopology = TRUE)

# ==============================================================================
# 1) equilibrium net-export primitives + envelopes (ports erw_provisional_engine)
# ==============================================================================
ref <- rast(econ(CROPS[1]))[[1]]

z <- ref * 0
na_ <- z; nb <- z; ncr <- z; ws <- z; cdrt <- z
for (cp in CROPS) {
  r    <- rast(econ(cp))
  ha   <- r[[paste0(cp, "_ha")]]
  agro <- r[[paste0(cp, "_agro_return_usha")]]
  bas  <- r[[paste0(cp, "_basalt_cost_usha")]]
  cnet <- r[[paste0(cp, "_cdr_net_tha")]]
  crev <- r[[paste0(cp, "_cdr_revenue_usha")]]
  gmc  <- r[[paste0(cp, "_gm_combined_usha")]]
  dfn  <- !is.na(gmc) & !is.na(ha) & ha > 0
  w    <- ifel(dfn, ha, 0)
  na_  <- na_  + ifel(dfn, ifel(is.na(agro),0,agro) * w, 0)
  nb   <- nb   + ifel(dfn, ifel(is.na(bas), 0,bas)  * w, 0)
  ncr  <- ncr  + ifel(dfn, ifel(is.na(crev),0,crev) * w, 0)
  cdrt <- cdrt + ifel(dfn, ifel(is.na(cnet),0,cnet) * w, 0)
  ws   <- ws + w
}
ok   <- ws > 0
AGRO <- ifel(ok, na_ / ws, NA)
BAS  <- ifel(ok, nb  / ws, NA)
CDRN <- ifel(ok, (ncr / ws) / (CARBON - MRV), NA)          # revenue-effective tCO2/ha
g    <- ifel(ok, cdrt / ws, NA)                             # area-wt gross CDR tCO2/ha

# net-export multiplier phi (equilibrium sink = merlos maintenance, band 1)
S <- rast(file.path(DATA, "caco3_merlos_maintenance.tif"))[[1]]
S <- resample(S, ref, method = "average")
S <- ifel(is.na(S), 0, S)
phi     <- ifel(!is.na(g) & g > 0, max(1 - F * S / g, 0), 0)
phi     <- clamp(phi, 0, 1)
CDRN_ne <- CDRN * phi

# envelopes (carbon $150, MRV $20)
gm_agro <- AGRO - BAS
gm_cdr  <- CDRN_ne * (CARBON - MRV) - BAS
gm_comb <- AGRO + CDRN_ne * (CARBON - MRV) - BAS
priv <- gm_agro > 0
publ <- gm_cdr  > 0
comb <- gm_comb > 0
inter <- priv & publ

# ---- house-style categorical map helper (boundaries overlaid) -----------------
cat_map <- function(class_r, title, cols, labs) {
  df <- as.data.frame(class_r, xy = TRUE); colnames(df)[3] <- "cls"
  df <- df[is.finite(df$cls), ]
  df$cls <- factor(df$cls, levels = seq_along(labs), labels = labs)
  ggplot() +
    geom_raster(data = df, aes(x, y, fill = cls)) +
    geom_sf(data = ssa, fill = NA, color = "black", linewidth = 0.15) +
    coord_sf(expand = FALSE) +
    scale_fill_manual(values = setNames(cols, labs), drop = FALSE, name = NULL) +
    labs(title = title) +
    theme_map_style() +
    theme(legend.key.width = unit(0.55, "cm"), legend.key.height = unit(0.4, "cm"))
}

# typology: 1 both, 2 private only, 3 public only, 4 combined only, 5 neither
typ <- ifel(priv & publ, 1, ifel(priv & !publ, 2, ifel(publ & !priv, 3,
        ifel(comb, 4, 5))))
typ <- mask(typ, ok, maskvalue = FALSE)

m_typ <- cat_map(typ,
  "Return typology  ·  equilibrium, net-export CDR, targeted",
  cols = c("#7B2D8E", "#2E7D32", "#1E5FA8", "#D9A93D", "grey85"),
  labs = c("both", "private only", "public only", "combined only", "neither"))
save_map(m_typ, file.path(FIGOUT, "fig-typology.png"), preset = "single")

m_priv <- cat_map(mask(ifel(priv, 1, 2), ok, maskvalue = FALSE),
  "Private-sufficient (yield)  ·  equilibrium",
  cols = c("#2E7D32", "grey85"), labs = c("private", "no"))
save_map(m_priv, file.path(FIGOUT, "fig-private.png"), preset = "single")

m_pub <- cat_map(mask(ifel(publ, 1, 2), ok, maskvalue = FALSE),
  "Public-sufficient (durable net-export CDR)  ·  equilibrium, $150/tCO2",
  cols = c("#1E5FA8", "grey85"), labs = c("public", "no"))
save_map(m_pub, file.path(FIGOUT, "fig-public.png"), preset = "single")

m_int <- cat_map(mask(ifel(inter, 1, 2), ok, maskvalue = FALSE),
  "Intersection  ·  equilibrium, net-export CDR",
  cols = c("#7B2D8E", "grey85"), labs = c("intersection", "outside"))
save_map(m_int, file.path(FIGOUT, "fig-intersection.png"), preset = "single")

# ---- MAC (durable net-export): $/tCO2, HAXBY magnitude, capped 0..500 ---------
MAC  <- ifel(!is.na(CDRN_ne) & CDRN_ne > 0, BAS / CDRN_ne, NA)
MAC  <- clamp(MAC, 0, 500)
gray <- ifel(ok & is.na(MAC), 1, NA)                       # cropland, no durable CDR
m_mac <- map_raster(MAC, ssa,
  title = "Marginal abatement cost  ·  durable net-export CDR (equilibrium, targeted)",
  fill_label = "$/tCO2  (cap 500)", limits = c(0, 500),
  gray_r = gray, gray_note = "gray: treated cropland with no durable net-export CDR",
  add_hist = TRUE, hist_fill = "#1B3A2F")
save_map(m_mac, file.path(FIGOUT, "fig-mac.png"), preset = "single")

cnt <- function(x) as.integer(global(ifel(x, 1, 0), "sum", na.rm = TRUE)[1, 1])
cat(sprintf("envelopes  priv/pub/inter/comb pixels: %d/%d/%d/%d\n",
    cnt(priv), cnt(publ), cnt(inter), cnt(comb)))
cat(sprintf("median MAC ($/tCO2): %.0f\n", median(values(MAC), na.rm = TRUE)))

# ==============================================================================
# 2) pixel-specific optimal application rate (ports erw_optimal_rate.py)
#    year-1 frame, central refinements (over-liming R1 + kinetic saturation R2)
# ==============================================================================
KD <- 30; KBETA <- 1; PH_NEUTRAL <- 6.5; REG <- "year1"
PH_OPT <- c(MAIZ=7.0,SORG=7.5,BEAN=7.0,CHIC=8.0,LENT=8.0,WHEA=7.5,BARL=7.8,ACOF=6.5,
  RCOF=6.5,PMIL=7.5,SMIL=7.5,POTA=6.5,SWPO=6.5,CASS=7.0,COWP=7.0,PIGE=7.0,SOYB=7.0,
  GROU=7.0,SUGC=7.5,COTT=8.0,COCO=7.0,TEAS=5.5,TOBA=6.5)
PH_ABS <- c(MAIZ=8.0,SORG=8.5,BEAN=8.0,CHIC=9.0,LENT=9.0,WHEA=8.5,BARL=8.5,ACOF=7.0,
  RCOF=7.0,PMIL=8.0,SMIL=8.0,POTA=7.5,SWPO=7.5,CASS=8.0,COWP=8.0,PIGE=8.0,SOYB=8.0,
  GROU=7.5,SUGC=8.5,COTT=8.5,COCO=7.5,TEAS=6.5,TOBA=7.5)

ref1 <- rast(econ(CROPS[1], REG))[[1]]
sg   <- rast(file.path(DATA, "soilgrids_properties_cropland.tif"))
pH0  <- resample(sg[[2]], ref1, method = "bilinear")
ECEC <- resample(sg[[9]], ref1, method = "bilinear"); ECEC <- ifel(is.na(ECEC), 0, ECEC)
Sk   <- rast(file.path(DATA, "caco3_kamprath.tif"))[[1]]     # year-1 standing acidity
Sk   <- resample(Sk, ref1, method = "average"); Sk <- ifel(is.na(Sk), 0, Sk)
beta <- max(KBETA * ECEC, 1)

z1 <- ref1 * 0
scost <- z1; scdr <- z1; stha <- z1; sagro <- z1; slr <- z1; sph <- z1; sphm <- z1; ws1 <- z1
for (cp in CROPS) {
  r   <- rast(econ(cp, REG))
  ha  <- r[[1]]; agro <- r[[5]]; bt <- r[[6]]; bas <- r[[7]]; cdrg <- r[[8]]; gmc <- r[[11]]
  dfn <- !is.na(gmc) & !is.na(ha) & ha > 0; w <- ifel(dfn, ha, 0)
  scost <- scost + ifel(dfn, ifel(is.na(bas),0,bas), 0)
  scdr  <- scdr  + ifel(dfn, ifel(is.na(cdrg),0,cdrg), 0)
  stha  <- stha  + ifel(dfn, ifel(is.na(bt),0,bt), 0)
  sagro <- sagro + ifel(dfn, ifel(is.na(agro),0,agro) * w, 0)
  slr   <- slr   + ifel(dfn, ifel(is.na(bt),0,bt) * w, 0)
  sph   <- sph   + PH_OPT[[cp]] * w; sphm <- sphm + PH_ABS[[cp]] * w; ws1 <- ws1 + w
}
ok1 <- ws1 > 0
tha <- ifel(stha > 0, stha, NA)
c_t <- ifel(stha > 0, scost / tha, NA)
d_t <- ifel(stha > 0, scdr  / tha, NA)
Ragro_max <- ifel(ok1, sagro / ws1, NA)
LR  <- max(ifel(ok1, slr / ws1, NA), 0.1)
PHO <- ifel(ok1, sph / ws1, 7.0); PHM <- ifel(ok1, sphm / ws1, 8.0)

final_pH <- function(A) {
  acid <- pH0 < PH_NEUTRAL
  ph   <- ifel(is.na(pH0), 6.0, pH0)
  frac <- clamp(ifel(Sk > 0.1, A / max(Sk, 0.1), 10.0), 0, 1)
  pa   <- ph + frac * (PH_NEUTRAL - ph)
  pa   <- ifel(A > Sk, PH_NEUTRAL + max(A - Sk, 0) / beta, pa)
  pn   <- ph + A / beta
  clamp(ifel(acid, pa, pn), ph, 8.5)
}
ypen <- function(A) {
  fp <- final_pH(A)
  ifel(fp <= PHO, 1.0, max(1 - ((fp - PHO) / max(PHM - PHO, 0.1))^2, 0))
}

grid_D <- seq(0, 100, by = 2.5)
Dopt_p <- z1; vb_p <- z1 - 1e9
Dopt_u <- z1; vb_u <- z1 - 1e9
Dopt_c <- z1; vb_c <- z1 - 1e9
for (D in grid_D) {
  gross <- D * d_t * ((KD + 50) / (KD + D)); A <- gross / F
  Ra <- Ragro_max * min(D / LR, 1) * ypen(A)
  Rc <- max(gross - F * Sk, 0) * (CARBON - MRV); Cc <- D * c_t
  o_p <- Ra - Cc; o_u <- Rc - Cc; o_c <- Ra + Rc - Cc
  bp <- !is.na(o_p) & o_p > vb_p; Dopt_p <- ifel(bp, D, Dopt_p); vb_p <- ifel(bp, o_p, vb_p)
  bu <- !is.na(o_u) & o_u > vb_u; Dopt_u <- ifel(bu, D, Dopt_u); vb_u <- ifel(bu, o_u, vb_u)
  bc <- !is.na(o_c) & o_c > vb_c; Dopt_c <- ifel(bc, D, Dopt_c); vb_c <- ifel(bc, o_c, vb_c)
}
dep <- (vb_c > 0) & ok1                                     # deployable: combined GM > 0

opt_panel <- function(rr, title) {
  map_raster(mask(rr, dep, maskvalue = FALSE), ssa, title = title,
             fill_label = "optimal rate (t/ha)", limits = c(0, 40),
             add_hist = FALSE)
}
m_a <- opt_panel(Dopt_p, "(a) Private-optimal")
m_b <- opt_panel(Dopt_u, "(b) Public-optimal")
m_c <- opt_panel(Dopt_c, "(c) Combined-optimal")
m_opt <- (m_a | m_b | m_c) + plot_layout(guides = "collect") &
  theme(legend.position = "bottom")
save_map(m_opt, file.path(FIGOUT, "fig-optimal-rates.png"),
         width = 15, height = 5.8)

cat("done: 6 house-style maps ->", FIGOUT, "\n")

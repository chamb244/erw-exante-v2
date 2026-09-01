# ------------------------------------------------------------------------------
# erw-11-private-public-envelopes.R
#
# Private vs public return envelopes and a targeting-robustness sweep, built on
# the erw-7 decomposed-cost rasters. Answers: where do agronomic (private)
# returns alone justify basalt-ERW investment, where do CDR (public) returns
# alone justify it, where do the two envelopes intersect, and how robust is that
# intersection to parameter assumptions.
#
# Framing (per pixel, area-weighted across the crops sharing the pixel):
#   gm_agro_only = agronomic_return - basalt_cost          (private)
#   gm_cdr_only  = cdr_net * (carbon_price - mrv) - basalt_cost   (public)
#   gm_combined  = agronomic_return + cdr_revenue - basalt_cost
#   private-sufficient  = gm_agro_only > 0
#   public-sufficient   = gm_cdr_only  > 0
#   intersection        = private & public  (investment is doubly justified;
#                         note: CDR credits are LEAST additional here)
#
# Because erw-7 stores agro_return, basalt_cost, gross CDR and net CDR as separate
# layers, every envelope and the whole parameter sweep reduce to a handful of
# area-weighted per-pixel primitives: AGRO ($/ha), BAS ($/ha), GROSS/LCA/S
# (tCO2/ha). The sweep is therefore fully analytic - no per-scenario model re-run.
#
# ACCOUNTING. erw-7 bakes the net-export deduction into `_cdr_net_tha` (band 9),
# so this file reads it straight through at the baseline. Verify with erw-12
# Section 0 before trusting any number here: if the on-disk economics_erw rasters
# predate the net-export wiring (commit 16b6321), band 9 is GROSS and every public
# figure below is overstated (targeted public 2.23 vs 1.65 Mha). Re-run erw-7.
#
# ALLOCATION. Private/targeting sections lead on `targeted`; the public/carbon
# section (Sec.4) leads on `uniform_20` -- the targeted dose is CDR-minimal by
# construction. See Sec.4's comment and paper/netexport-cdr-memo.md Sec.3.
#
# Baseline: REGIME = equilibrium, allocations targeted + uniform_20, carbon
# $150/tCO2, MRV $20/tCO2 (matches erw-7 defaults).
#
# Inputs:
#   data/economics_erw/{targeted,uniform_20}/{crop}_year1.tif   (from erw-7)
#   data/spam_prod_processed.tif                                (value of prod)
#   data/FAOSTAT_data_en_4-24-2023.csv                          (producer prices)
#   data/gadm_ssa.gpkg                                          (country zonal)
#
# Outputs:
#   docs/maps/envelopes/*.png            envelope, typology, robustness, core maps
#     (the public/VCM figures carry the allocation suffix: mac_{PUBLIC_ALLOC}.png,
#      cdr_rate_sensitivity_panel_{PUBLIC_ALLOC}.png. Their unsuffixed ancestors from
#      before that rename live in docs/maps/envelopes/orphan/ -- superseded, do not cite.)
#   docs/tables/output-envelope-summary.csv          ha/farms/value/CDR per envelope
#   docs/tables/output-envelope-country-summary.csv
#   docs/tables/output-core-priority-summary.csv
#   docs/tables/output-core-priority-by-country.csv
#   docs/tables/output-sensitivity-tornado.csv
# ------------------------------------------------------------------------------

suppressMessages({ library(terra); library(here); library(data.table) })

DATA    <- here::here("data")
MAP_OUT <- here::here("docs", "maps", "envelopes")
TBL_OUT <- here::here("docs", "tables")
dir.create(MAP_OUT, recursive = TRUE, showWarnings = FALSE)
dir.create(TBL_OUT, recursive = TRUE, showWarnings = FALSE)

# "equilibrium" is the manuscript headline (steady-state, net-export CDR now baked
# into erw-7's _cdr_net_tha layer). Switch to "year1" for the upper-bound contrast.
REGIME      <- "equilibrium"
ALLOCS      <- c("targeted", "uniform_10", "uniform_20", "uniform_50")
MRV         <- 20      # $/tCO2  (erw-7 default)
CARBON_BASE <- 150     # $/tCO2

CROPS <- c("MAIZ","SORG","BEAN","CHIC","LENT","WHEA","BARL","ACOF","RCOF","PMIL",
           "SMIL","POTA","SWPO","CASS","COWP","PIGE","SOYB","GROU","SUGC","COTT",
           "COCO","TEAS","TOBA")

# ---- crop prices: replicate erw-7 (FAOSTAT producer price, 2016-2020 median) --
fao_item <- list(MAIZ="Maize (corn)", SORG="Sorghum", BEAN="Beans, dry",
  CHIC="Chick peas, dry", LENT="Lentils, dry", WHEA="Wheat", BARL="Barley",
  ACOF="Coffee, green", RCOF="Coffee, green", PMIL="Millet", SMIL="Millet",
  POTA="Potatoes", SWPO="Sweet potatoes", CASS="Cassava, fresh",
  COWP="Cow peas, dry", PIGE="Pigeon peas, dry", SOYB="Soya beans",
  GROU="Groundnuts, excluding shelled", SUGC="Sugar cane", COTT="Cotton seed",
  COCO="Cocoa beans", TEAS="Tea leaves", TOBA="Unmanufactured tobacco")
ssa_areas <- c("Angola","Benin","Botswana","Burkina Faso","Burundi","Cameroon",
  "Central African Republic","Chad","Congo","Democratic Republic of the Congo",
  "Equatorial Guinea","Eritrea","Eswatini","Swaziland","Ethiopia","Gabon",
  "Gambia","Ghana","Guinea","Guinea-Bissau","Côte d'Ivoire","Kenya",
  "Lesotho","Liberia","Madagascar","Malawi","Mali","Mauritania","Mozambique",
  "Namibia","Niger","Nigeria","Rwanda","Senegal","Sierra Leone","Somalia",
  "South Sudan","Sudan (former)","Sudan","United Republic of Tanzania","Togo",
  "Uganda","South Africa","Zambia","Zimbabwe")

fao <- fread(file.path(DATA, "FAOSTAT_data_en_4-24-2023.csv"))
fao <- fao[Year > 2015 & Year <= 2020 & Area %in% ssa_areas]
crop_price <- sapply(CROPS, function(c)
  as.numeric(median(fao[Item == fao_item[[c]], Value], na.rm = TRUE)))

# ---- per-country average agricultural holding size, ha ------------------------
# Approximate national averages (FAO World Census of Agriculture; Lowder, Skoet
# & Raney 2016; FAO 2021). Coarse but transparent - swap for a gridded field-
# size layer for production runs. Used only to convert hectares -> farm counts.
farm_ha <- c(AGO=2.0,BDI=0.5,BEN=1.7,BFA=4.5,BWA=5.0,CAF=1.5,CIV=3.0,CMR=1.6,
  COD=1.6,COG=1.5,DJI=2.0,ERI=1.5,ETH=1.0,GAB=1.5,GHA=1.2,GIN=2.0,GMB=1.5,
  GNB=1.5,GNQ=1.5,KEN=1.0,LBR=1.5,LSO=1.0,MDG=0.9,MLI=4.0,MOZ=1.5,MRT=3.0,
  MWI=0.8,NAM=5.0,NER=5.0,NGA=1.8,RWA=0.6,SDN=5.0,SEN=3.5,SLE=1.5,SOM=2.5,
  SSD=2.0,SWZ=1.5,TCD=3.0,TGO=1.6,TZA=2.0,UGA=1.1,ZAF=3.0,ZMB=2.5,ZWE=2.0)
FARM_DEFAULT <- 2.0

# ---- helpers -----------------------------------------------------------------
econ_path <- function(alloc, crop)
  file.path(DATA, "economics_erw", alloc, paste0(crop, "_", REGIME, ".tif"))

prod_stack <- rast(file.path(DATA, "spam_prod_processed.tif"))   # 23 layers, t/pixel
ssa <- vect(file.path(DATA, "gadm_ssa.gpkg"))

# Feedstock constants for the net-export deduction. erw-7 already bakes the
# deduction into `_cdr_net_tha`, but the sweep below has to be able to re-scale
# the GROSS CDR rate and re-apply it, so we carry GROSS, LCA and the sink S
# separately rather than re-scaling the already-deducted layer. See cdr_net().
fs_chem <- read.csv(file.path(DATA, "basalt_feedstock_chemistry.csv"))
get_fs  <- function(p) as.numeric(fs_chem$value[fs_chem$parameter == p])
F_REEXPORT <- get_fs("CDR_eff_kg_per_t_ref") / (get_fs("effective_NV") * 1000)
GRIND_KWH  <- get_fs("grinding_kWh_per_t")

sink_file <- if (REGIME %in% c("year1","npv")) "caco3_kamprath.tif" else "caco3_merlos_maintenance.tif"
S_raw     <- aggregate(rast(file.path(DATA, sink_file))[[1]], 10, mean, na.rm=TRUE)
ci_raw    <- rast(file.path(DATA, "grid_CI_kg_per_kWh.tif"))
km_raw    <- rast(file.path(DATA, "basalt_transport_km.tif"))
# transport-only $/t, so the solar cost lever (Sec.5) can cut just that component
trans_raw <- if (file.exists(file.path(DATA, "basalt_transport_cost_usd_t.tif")))
               rast(file.path(DATA, "basalt_transport_cost_usd_t.tif")) else NULL

# Build the area-weighted per-pixel primitives (+ weight, value-of-production, CDR-t)
build_primitives <- function(alloc) {
  ref <- rast(econ_path(alloc, CROPS[1]))[[1]]
  lca_kg_per_t <- GRIND_KWH * resample(ci_raw, ref) + resample(km_raw, ref) * 0.12 + 0.5
  S <- resample(S_raw, ref); S <- ifel(is.na(S), 0, S)
  trans_t <- if (!is.null(trans_raw)) resample(trans_raw, ref) else ref*0

  z <- ref * 0
  num_agro <- z; num_bas <- z; num_cdrn <- z; num_gross <- z; num_lca <- z
  num_trans <- z; wsum <- z; vop <- z; cdrt <- z
  for (cp in CROPS) {
    r     <- rast(econ_path(alloc, cp))
    ha    <- r[[paste0(cp, "_ha")]]
    agro  <- r[[paste0(cp, "_agro_return_usha")]]
    bas   <- r[[paste0(cp, "_basalt_cost_usha")]]
    cdrn  <- r[[paste0(cp, "_cdr_net_tha")]]     # net-export, minus LCA (erw-7)
    gross <- r[[paste0(cp, "_cdr_gross_tha")]]   # before any deduction
    btha  <- r[[paste0(cp, "_basalt_tha")]]
    gmc   <- r[[paste0(cp, "_gm_combined_usha")]]
    defined <- !is.na(gmc) & !is.na(ha) & ha > 0
    w  <- ifel(defined, ha, 0)
    nz <- function(x) ifel(is.na(x), 0, x)
    num_agro  <- num_agro  + ifel(defined, nz(agro)  * w, 0)
    num_bas   <- num_bas   + ifel(defined, nz(bas)   * w, 0)
    num_cdrn  <- num_cdrn  + ifel(defined, nz(cdrn)  * w, 0)
    num_gross <- num_gross + ifel(defined, nz(gross) * w, 0)
    num_lca   <- num_lca   + ifel(defined, nz(btha * lca_kg_per_t / 1000) * w, 0)
    num_trans <- num_trans + ifel(defined, nz(btha * trans_t) * w, 0)  # transport $/ha
    wsum      <- wsum + w
    cdrt      <- cdrt + ifel(defined, nz(cdrn) * w, 0)
    pr <- prod_stack[[which(CROPS == cp)]]
    vop <- vop + ifel(defined, nz(pr) * crop_price[cp], 0)
  }
  ok <- wsum > 0
  list(AGRO  = ifel(ok, num_agro  / wsum, NA),
       BAS   = ifel(ok, num_bas   / wsum, NA),
       CDRN  = ifel(ok, num_cdrn  / wsum, NA),
       GROSS = ifel(ok, num_gross / wsum, NA),
       LCA   = ifel(ok, num_lca   / wsum, NA),
       S     = ifel(ok, S, NA),
       TRANS = ifel(ok, num_trans / wsum, NA),   # transport $/ha (for the solar lever)
       WSUM  = ifel(ok, wsum, NA), VOP = ifel(ok, vop, NA),
       CDRT  = ifel(ok, cdrt, NA), ok = ok)
}

# Durable CDR (t CO2/ha) under a GROSS-rate multiplier rmult and a net-export
# partition lambda (1 = sequential bound, 0 = gross accounting):
#
#     cdr_net = max( max(rmult*GROSS - lambda*F*S, 0) - LCA , 0 )
#
# rmult multiplies GROSS, not the already-deducted net: the reactive fraction,
# grain size, climate factor and exported fraction all scale gross CDR, while the
# acidity sink F*S and the lifecycle term LCA are fixed subtrahends. Because of
# the max(.,0), cdr_net is SUPER-linear in rmult, so scaling the net layer (as an
# earlier version of this file did) compresses the lever on both sides -- at
# rmult=2 the public envelope is 12.56 Mha under uniform-20, not 5.99 (targeted:
# 5.90 vs 2.68). At rmult=1, lambda=1 this reproduces erw-7's `_cdr_net_tha`
# exactly. See erw-12 for the full treatment.
cdr_net <- function(P, rmult = 1, lambda = 1) {
  pos <- function(x) ifel(x < 0, 0, x)
  pos(pos(rmult * P$GROSS - lambda * F_REEXPORT * P$S) - P$LCA)
}

# Envelopes from the primitives under arbitrary parameters.
# NOTE: the public envelope depends on (carbon, MRV, cmult) only through the
# ratio (carbon - MRV)/cmult -- they are one lever, not three (see erw-12 Sec.1).
envelopes <- function(P, carbon=CARBON_BASE, ymult=1, cmult=1, rmult=1, lambda=1) {
  cdrn    <- cdr_net(P, rmult, lambda)
  gm_agro <- P$AGRO*ymult - P$BAS*cmult
  gm_cdr  <- cdrn*(carbon-MRV) - P$BAS*cmult
  gm_comb <- P$AGRO*ymult + cdrn*(carbon-MRV) - P$BAS*cmult
  list(priv = gm_agro > 0, publ = gm_cdr > 0, comb = gm_comb > 0)
}

# Summaries for a mask: ha / farms / value of production / CDR
country_r <- NULL
summarize_mask <- function(P, mask) {
  ha  <- as.numeric(global(ifel(mask, P$WSUM, 0), "sum", na.rm=TRUE))
  vop <- as.numeric(global(ifel(mask, P$VOP,  0), "sum", na.rm=TRUE))
  cdr <- as.numeric(global(ifel(mask, P$CDRT, 0), "sum", na.rm=TRUE))
  ha_by_c <- zonal(ifel(mask, P$WSUM, 0), country_r, "sum", na.rm=TRUE)
  fs <- farm_ha[ha_by_c[[1]]]; fs[is.na(fs)] <- FARM_DEFAULT
  farms <- sum(ha_by_c[[2]] / fs, na.rm=TRUE)
  data.frame(ha_Mha=round(ha/1e6,2), farms_M=round(farms/1e6,2),
             value_prod_Musd=round(vop/1e6,1), cdr_Mt=round(cdr/1e6,2))
}

plot_cat <- function(r, file, title, levs, cols, labels) {
  png(file.path(MAP_OUT, file), width=1200, height=1100, res=150)
  par(mar=c(2,2,3.5,1))
  rr <- r; levels(rr) <- data.frame(id=levs, lab=labels)
  plot(rr, main=title, col=cols, axes=FALSE, plg=list(cex=0.8))
  plot(ssa, add=TRUE, lwd=0.3, border="grey30")
  dev.off()
}
plot_cont <- function(r, file, title, pal, lab) {
  png(file.path(MAP_OUT, file), width=1200, height=1100, res=150)
  par(mar=c(2,2,3.5,4))
  plot(r, main=title, col=pal, axes=FALSE, range=c(0,1),
       plg=list(title=lab, cex=0.8))
  plot(ssa, add=TRUE, lwd=0.3, border="grey30")
  dev.off()
}

# =============================================================================
# 1) baseline envelopes + summaries per allocation
# =============================================================================
ref0 <- rast(econ_path("targeted", CROPS[1]))[[1]]
country_r <- rasterize(ssa, ref0, field="GID_0")

summary_rows <- list(); country_rows <- list(); PRIMS <- list()
for (alloc in ALLOCS) {
  cat("== envelopes:", alloc, "==\n")
  P <- build_primitives(alloc); PRIMS[[alloc]] <- P
  e <- envelopes(P); inter <- e$priv & e$publ

  typ <- ifel(e$priv & e$publ, 1,
         ifel(e$priv & !e$publ, 2,
         ifel(e$publ & !e$priv, 3,
         ifel(e$comb, 4, 5))))
  typ <- mask(typ, P$ok, maskvalue=FALSE)

  plot_cat(ifel(e$priv,1,0), sprintf("env_private_%s.png",alloc),
    sprintf("Private-sufficient (agronomic > basalt cost) - %s", alloc),
    c(0,1), c("grey85","#1a7d3c"), c("no","private"))
  plot_cat(ifel(e$publ,1,0), sprintf("env_public_%s.png",alloc),
    sprintf("Public-sufficient (CDR > basalt cost) - %s", alloc),
    c(0,1), c("grey85","#2156a8"), c("no","public"))
  plot_cat(ifel(inter,1,0), sprintf("env_intersection_%s.png",alloc),
    sprintf("Intersection (both sufficient) - %s", alloc),
    c(0,1), c("grey85","#7d1f8c"), c("outside","intersection"))
  plot_cat(typ, sprintf("env_typology_%s.png",alloc),
    sprintf("Return typology - %s, %s", REGIME, alloc),
    c(1,2,3,4,5), c("#7d1f8c","#1a7d3c","#2156a8","#e8a33d","grey88"),
    c("both","private only","public only","combined only","neither"))

  masks <- list(private=e$priv, public=e$publ, intersection=inter, combined=e$comb)
  for (lab in names(masks)) {
    s <- summarize_mask(P, masks[[lab]] & P$ok)
    summary_rows[[length(summary_rows)+1]] <- cbind(allocation=alloc, envelope=lab, s)
  }
  # per-country
  for (lab in names(masks)) {
    m <- masks[[lab]] & P$ok
    ha_c  <- zonal(ifel(m, P$WSUM, 0), country_r, "sum", na.rm=TRUE)
    vop_c <- zonal(ifel(m, P$VOP,  0), country_r, "sum", na.rm=TRUE)
    fs <- farm_ha[ha_c[[1]]]; fs[is.na(fs)] <- FARM_DEFAULT
    country_rows[[length(country_rows)+1]] <- data.frame(
      allocation=alloc, envelope=lab, iso3=ha_c[[1]],
      ha_Mha=round(ha_c[[2]]/1e6,3),
      farms_M=round(ha_c[[2]]/fs/1e6,3),
      vop_Musd=round(vop_c[[2]]/1e6,1))
  }
}
write.csv(do.call(rbind, summary_rows),
          file.path(TBL_OUT,"output-envelope-summary.csv"), row.names=FALSE)
write.csv(do.call(rbind, country_rows),
          file.path(TBL_OUT,"output-envelope-country-summary.csv"), row.names=FALSE)
print(do.call(rbind, summary_rows))

# =============================================================================
# 2) targeting robustness sweep (primary allocation: targeted)
# =============================================================================
# The intersection test is homogeneous of degree zero in the delivered cost. Divide
# both envelope conditions by the cost multiplier c:
#
#     private : AGRO * (ymult/c)        > BAS
#     public  : cdr_net(r,lambda) * ((carbon - MRV)/c) > BAS
#
# so the intersection depends on the five economic parameters ONLY through four
# effective knobs: the yield/cost ratio y/c, the net-price/cost ratio (p-m)/c, the
# CDR-rate multiplier r, and the net-export partition lambda. Verified exactly:
# (y,c,p) = (1,1,150), (2,2,280), (0.5,0.5,85) all give 1.2002 Mha.
#
# This is why the delivered cost looked like the dominant lever in earlier drafts:
# it is the ONLY parameter that moves BOTH ratios at once. Its 2.36 Mha swing
# decomposes into a public channel (1.66 Mha, holding y/c fixed) and a private
# channel (0.76 Mha, holding (p-m)/c fixed) -- and that 0.76 is exactly the yield
# swing, as it must be, since yield moves y/c and nothing else. Cost is not a
# separate mechanism; it is the two ratios moving together.
#
# Everything below is on the HEADLINE basis (equilibrium, net-export), matching the
# regime on which the carbon case is led. Earlier drafts computed this section on
# the NPV/gross grid -- a regime mismatch.
YC  <- c(0.5, 0.75, 1.0, 1.5, 2.0)   # yield / delivered-cost ratio
PC  <- c(30, 80, 130, 230)           # (carbon - MRV) / delivered-cost ratio
RM  <- c(0.5, 1.0, 1.5)              # CDR-rate multiplier (scales GROSS)
LAM <- c(0.0, 0.5, 1.0)              # net-export partition

P <- PRIMS[["targeted"]]; ok <- P$ok

# vectorise over live cells: 180 combos of raster algebra would be needlessly slow
cells <- which(!is.na(values(P$WSUM)) & values(P$WSUM) > 0)
Av <- values(P$AGRO)[cells];  Bv <- values(P$BAS)[cells]
Gv <- values(P$GROSS)[cells]; Lv <- values(P$LCA)[cells]
Sv <- values(P$S)[cells];     Wv <- values(P$WSUM)[cells]
posv <- function(x) pmax(x, 0)
cdrv <- function(r, lam) posv(posv(r*Gv - lam*F_REEXPORT*Sv) - Lv)

grid <- expand.grid(yc=YC, pc=PC, r=RM, lam=LAM)
N <- nrow(grid)
freq_i <- numeric(length(cells)); freq_c <- numeric(length(cells))
for (i in seq_len(N)) {
  g  <- grid[i, ]; cd <- cdrv(g$r, g$lam)
  pr <- Av*g$yc > Bv
  pu <- cd*g$pc > Bv
  freq_i <- freq_i + (pr & pu)
  freq_c <- freq_c + (Av*g$yc + cd*g$pc > Bv)
}
cat(sprintf("\nrobustness sweep: %d combos over (y/c, (p-m)/c, r, lambda)\n", N))

mkrast <- function(v) { r <- ref0; values(r) <- NA_real_; r[cells] <- v; r }
robust_i <- mkrast(freq_i/N); robust_c <- mkrast(freq_c/N)
plot_cont(robust_i, "robustness_intersection.png",
  sprintf("Robustness of the intersection (%d combos, equilibrium net-export)", N),
  hcl.colors(20,"Inferno"), "frac")
plot_cont(robust_c, "robustness_combined.png",
  sprintf("Robustness of profitability (%d combos, equilibrium net-export)", N),
  hcl.colors(20,"Viridis"), "frac")

core <- robust_i >= 0.50; cand <- robust_i >= 0.33
plot_cat(ifel(core,1,ifel(cand,2,0)), "core_priority.png",
  "Core targeting tiers (equilibrium, net-export)",
  c(0,2,1), c("grey85","#f4a259","#b30000"),
  c("outside","candidate >=33%","core >=50%"))
cat(sprintf("max per-pixel robustness score: %.2f\n",
    max(freq_i)/N))

core_summary <- rbind(
  cbind(tier="core_>=50%",  summarize_mask(P, core & ok)),
  cbind(tier="candidate_>=33%", summarize_mask(P, cand & ok)))
write.csv(core_summary, file.path(TBL_OUT,"output-core-priority-summary.csv"), row.names=FALSE)

ha_c  <- zonal(ifel(core & ok, P$WSUM, 0), country_r, "sum", na.rm=TRUE)
vop_c <- zonal(ifel(core & ok, P$VOP,  0), country_r, "sum", na.rm=TRUE)
ha_cd <- zonal(ifel(cand & ok, P$WSUM, 0), country_r, "sum", na.rm=TRUE)
fs <- farm_ha[ha_c[[1]]]; fs[is.na(fs)] <- FARM_DEFAULT
core_country <- data.frame(iso3=ha_c[[1]], core_Mha=round(ha_c[[2]]/1e6,3),
  core_farms_M=round(ha_c[[2]]/fs/1e6,3), core_vop_Musd=round(vop_c[[2]]/1e6,1),
  candidate_Mha=round(ha_cd[[2]]/1e6,3))
core_country <- core_country[order(-core_country$core_Mha),]
write.csv(core_country, file.path(TBL_OUT,"output-core-priority-by-country.csv"), row.names=FALSE)

# =============================================================================
# 3) one-at-a-time tornado: total intersection ha vs each EFFECTIVE knob
# =============================================================================
# Reported on the four knobs the intersection actually depends on. The raw
# delivered-cost lever is reported too, but decomposed: it is not a fifth
# mechanism, it is y/c and (p-m)/c moving together.
inter_v <- function(yc=1, pc=RATIO0, r=1, lam=1)
  sum(Wv[(Av*yc > Bv) & (cdrv(r,lam)*pc > Bv)]) / 1e6
RATIO0 <- CARBON_BASE - MRV          # = 130, the central net price per unit cost
base_ha <- inter_v()

sweep1 <- function(vals, f) { h <- sapply(vals, f); c(min(h), max(h)) }
rows <- list(
  c("yield/cost ratio y/c (x0.5-2.0)",        sweep1(YC,  function(x) inter_v(yc=x)),        "private"),
  c("net-price/cost ratio (p-m)/c (30-230)",  sweep1(PC,  function(x) inter_v(pc=x)),        "public"),
  c("CDR rate r (x0.5-1.5)",                  sweep1(RM,  function(x) inter_v(r=x)),         "public"),
  c("net-export lambda (0-1)",                sweep1(LAM, function(x) inter_v(lam=x)),       "public"),
  c("[delivered cost c (x0.5-2.0)]",          sweep1(c(0.5,0.75,1,1.5,2),
       function(x) inter_v(yc=1/x, pc=RATIO0/x)),                                            "both"),
  c("  -- its public channel only",           sweep1(c(0.5,0.75,1,1.5,2),
       function(x) inter_v(yc=1, pc=RATIO0/x)),                                              "public"),
  c("  -- its private channel only",          sweep1(c(0.5,0.75,1,1.5,2),
       function(x) inter_v(yc=1/x, pc=RATIO0)),                                              "private")
)
tor_df <- do.call(rbind, lapply(rows, function(z) data.frame(
  knob = z[1], min_inter_Mha = round(as.numeric(z[2]),2),
  max_inter_Mha = round(as.numeric(z[3]),2),
  swing_Mha = round(as.numeric(z[3]) - as.numeric(z[2]), 2), acts_on = z[4])))
write.csv(tor_df, file.path(TBL_OUT,"output-sensitivity-tornado.csv"), row.names=FALSE)

cat("\nbaseline intersection:", round(base_ha,2), "Mha (equilibrium, net-export)\n")
print(tor_df, row.names=FALSE)

# =============================================================================
# 4) public/VCM envelope: marginal abatement cost + CDR-rate sensitivity panel
# =============================================================================
# Public-sufficiency reduces to a marginal-abatement-cost (MAC) test in which the
# per-hectare dose cancels:
#   MAC ($/tCO2) = cost_per_t_basalt / CDR_per_t_basalt = BAS / cdr_net (area-wt)
# The public envelope is exactly { MAC < carbon_price - MRV }. Because realized
# CDR per tonne basalt is small (~0.1-0.25 tCO2/t), MAC sits well above current
# VCM prices on most cropland -> the CDR RATE, not the credit price, is binding.
#
# ALLOCATION. The carbon case is led on UNIFORM-20, not on the targeted dose. The
# acidity sink F*S is a soil property and is near-constant across allocation rules,
# while gross CDR scales with the dose -- so the lime-requirement (targeted) dose
# is CDR-MINIMAL by construction: essentially all of its alkalinity is consumed
# neutralizing the acidity it was sized to neutralize, and little exports. Leading
# the carbon case on `targeted` understates the public envelope by ~1.9x in area
# and ~3.1x in tonnage (1.65 -> 3.16 Mha; 4.85 -> 15.11 Mt). Targeted remains the
# lead for the private/agronomic envelope and for the targeting sections above.
# This is the dose-design corollary of paper/netexport-cdr-memo.md Sec.3.
PUBLIC_ALLOC <- "uniform_20"
P <- PRIMS[[PUBLIC_ALLOC]]; ok <- P$ok
MAC <- ifel(cdr_net(P) > 0 & ok, P$BAS / cdr_net(P), NA)

png(file.path(MAP_OUT, sprintf("mac_%s.png", PUBLIC_ALLOC)), width=1200, height=1100, res=150)
par(mar=c(2,2,3.5,4))
plot(clamp(MAC,0,500),
     main=sprintf("Marginal abatement cost of ERW-CDR ($/tCO2)\n= delivered cost per t basalt / CDR per t basalt, %s", PUBLIC_ALLOC),
     col=rev(hcl.colors(20,"Inferno")), axes=FALSE, range=c(0,500),
     plg=list(title="$/tCO2", cex=0.8))
plot(ssa, add=TRUE, lwd=0.3, border="grey30"); dev.off()

area_of <- function(which=c("public","intersection"),
                    carbon=CARBON_BASE, rmult=1, cmult=1) {
  e <- envelopes(P, carbon=carbon, ymult=1, cmult=cmult, rmult=rmult)
  m <- if (match.arg(which)=="public") e$publ else (e$priv & e$publ)
  as.numeric(global(ifel(m & ok, P$WSUM, 0), "sum", na.rm=TRUE))/1e6
}

# carbon-price ladder. Shares are of the TREATED cropland under this allocation --
# note the denominator is allocation-specific: the targeted dose is applied only to
# acid-eligible pixels (17.6 Mha) while a uniform dose goes on all cropland the 23
# SPAM crops occupy (32.6 Mha at uniform-20). Always report which base is in use.
treated_Mha <- as.numeric(global(ifel(ok, P$WSUM, 0), "sum", na.rm=TRUE))/1e6
ALL_CROPLAND_MHA <- 146   # SSA harvested cropland, SPAM
cat(sprintf("\ntreated cropland under %s: %.2f Mha\n", PUBLIC_ALLOC, treated_Mha))

cdr_of <- function(carbon=CARBON_BASE, rmult=1, cmult=1) {
  e <- envelopes(P, carbon=carbon, ymult=1, cmult=cmult, rmult=rmult)
  as.numeric(global(ifel(e$publ & ok, cdr_net(P, rmult)*P$WSUM, 0), "sum", na.rm=TRUE))/1e6
}
ladder_p <- c(50,100,130,150,200,250,300,350,400,500,750,1000)
ladder <- data.frame(carbon_usd=ladder_p,
  public_Mha  = sapply(ladder_p, function(p) round(area_of("public", carbon=p),2)),
  pct_treated = sapply(ladder_p, function(p) round(100*area_of("public",carbon=p)/treated_Mha,1)),
  pct_all_cropland = sapply(ladder_p, function(p) round(100*area_of("public",carbon=p)/ALL_CROPLAND_MHA,1)),
  durable_CDR_Mt = sapply(ladder_p, function(p) round(cdr_of(carbon=p),1)))
write.csv(ladder, file.path(TBL_OUT,"output-public-mac-price-ladder.csv"), row.names=FALSE)
print(ladder)

# price-ladder figure on the HEADLINE basis (equilibrium, net-export, PUBLIC_ALLOC)
png(file.path(MAP_OUT, sprintf("public_area_vs_price_%s.png", PUBLIC_ALLOC)),
    width=1200, height=950, res=150)
par(mar=c(4.6,4.8,3.4,1.4))
plot(ladder$carbon_usd, ladder$public_Mha, type="b", pch=19, lwd=2, col="#2156a8",
     xlab="VCM carbon price ($/tCO2)", ylab="Public-sufficient area (Mha)",
     main=sprintf("Carbon-alone deployable area vs credit price\n(equilibrium, net-export, %s)", PUBLIC_ALLOC))
abline(v=CARBON_BASE, lty=2, col="grey45")
text(CARBON_BASE, max(ladder$public_Mha)*0.95, " $150 today", pos=4, cex=0.8, col="grey30")
dev.off()

# CDR-rate sweep (the binding lever)
rmults <- c(0.5,0.75,1.0,1.25,1.5,2.0,2.5)
cdr_sens <- data.frame(cdr_rate_mult=rmults,
  public_Mha       = sapply(rmults, function(r) round(area_of("public",       rmult=r),2)),
  intersection_Mha = sapply(rmults, function(r) round(area_of("intersection", rmult=r),2)))
write.csv(cdr_sens, file.path(TBL_OUT,"output-cdr-rate-sensitivity.csv"), row.names=FALSE)

# Lever comparison on the public envelope.
# NOTE the carbon-price and delivered-cost rows are the SAME lever seen at
# different step sizes: the public envelope depends on (carbon, MRV, cmult) only
# through (carbon - MRV)/cmult. +33% carbon takes the ratio 130 -> 180 (x1.38);
# -33% delivered cost takes it 130 -> 194 (x1.49). Kept for continuity with the
# memo, but erw-12 reports the collapsed, band-free version.
base_pub <- area_of("public")
levers <- c("+33% carbon ($200)"  = area_of("public", carbon=200),
            "-33% delivered cost" = area_of("public", cmult=0.67),
            "+33% CDR rate"       = area_of("public", rmult=1.33),
            "2x CDR rate"         = area_of("public", rmult=2.0))
lever_pct <- round(100*(levers/base_pub - 1), 0)

# two-panel CDR-rate sensitivity figure
png(file.path(MAP_OUT, sprintf("cdr_rate_sensitivity_panel_%s.png", PUBLIC_ALLOC)),
    width=2000, height=850, res=150)
par(mfrow=c(1,2), mar=c(4.5,4.5,3.5,1))
plot(rmults, cdr_sens$public_Mha, type="b", pch=19, col="#2156a8", lwd=2,
     ylim=c(0, max(cdr_sens$public_Mha)),
     xlab="CDR-rate multiplier (x GROSS tCO2 per t basalt)", ylab="Area (Mha)",
     main=sprintf("(a) Envelope area vs CDR rate (%s, $150/tCO2)", PUBLIC_ALLOC))
lines(rmults, cdr_sens$intersection_Mha, type="b", pch=15, col="#7d1f8c", lwd=2)
abline(v=1, lty=2)
legend("topleft", c("public-sufficient","intersection"),
       col=c("#2156a8","#7d1f8c"), pch=c(19,15), lwd=2, bty="n")
par(mar=c(4.5,11,3.5,2))
barplot(rev(lever_pct), horiz=TRUE, las=1,
        col=rev(c("grey60","grey60","#2c7a3f","#1a7d3c")),
        xlab="Change in public-sufficient area (%)",
        main="(b) Public envelope: lever comparison")
dev.off()

mac_med <- median(values(MAC), na.rm=TRUE)
cat("\npublic-envelope MAC median ($/tCO2):", round(mac_med,0), "\n")
cat("baseline public:", round(base_pub,2), "Mha;  2x CDR rate:",
    round(area_of("public", rmult=2),2), "Mha\n"); print(cdr_sens)

# =============================================================================
# 5) cost-side lever: at-scale solar/electric haulage (targeted; sec:solar)
# =============================================================================
# Solar displaces the fuel/energy portion of trucking cost -> a cut to the
# TRANSPORT term of delivered cost only. Per pixel:
#     BAS_solar = BAS - f * TRANS         (TRANS = transport $/ha, area-weighted)
# The CDR side is left untouched: solar would also cut transport LCA emissions,
# so holding LCA fixed makes the public-side gain a conservative lower bound.
# Reported on the HEADLINE basis (equilibrium net-export), NOT the NPV/gross grid
# the earlier draft used -- the point of the section is to compare against the
# headline envelopes, so it must share their regime.
Psol <- PRIMS[["targeted"]]; oks <- Psol$ok
solar_env <- function(f = 0) {           # f = fraction off the transport term
  BASs <- Psol$BAS - f * Psol$TRANS
  cd   <- cdr_net(Psol)                  # rmult=1, lambda=1
  net  <- CARBON_BASE - MRV
  list(priv  = (Psol$AGRO - BASs) > 0,
       publ  = (cd*net    - BASs) > 0,
       inter = ((Psol$AGRO - BASs) > 0) & ((cd*net - BASs) > 0))
}
solar_Mha <- function(m) as.numeric(global(ifel(m & oks, Psol$WSUM, 0),"sum",na.rm=TRUE))/1e6

# transport share of delivered cost. Report the AREA-weighted mean of the per-pixel
# share (so "x% off delivered" = f * mean share is internally consistent), plus the
# area-weighted median for the distribution.
tsh <- Psol$TRANS / Psol$BAS
tsh_mean <- as.numeric(global(ifel(oks, tsh * Psol$WSUM, 0),"sum",na.rm=TRUE)) /
            as.numeric(global(ifel(oks, Psol$WSUM,       0),"sum",na.rm=TRUE))
tsh_med  <- {
  v <- values(tsh)[oks_v <- which(!is.na(values(tsh)) & !is.na(values(Psol$WSUM)))]
  wv <- values(Psol$WSUM)[oks_v]; o <- order(v)
  approx(cumsum(wv[o])/sum(wv), v[o], 0.5, ties="ordered")$y
}

solar <- do.call(rbind, lapply(c(0, 0.25, 0.40), function(f) {
  e <- solar_env(f)
  data.frame(transport_cut = f,
             pct_off_delivered = round(100*f*tsh_mean, 0),
             private_Mha = round(solar_Mha(e$priv), 2),
             public_Mha  = round(solar_Mha(e$publ), 2),
             inter_Mha   = round(solar_Mha(e$inter), 2))
}))
write.csv(solar, file.path(TBL_OUT,"output-solar-transport.csv"), row.names=FALSE)
cat(sprintf("\nsolar haulage (targeted, equilibrium net-export); transport share of\n"))
cat(sprintf("delivered cost: mean %.0f%%, median %.0f%%\n", 100*tsh_mean, 100*tsh_med))
print(solar, row.names=FALSE)

cat("\nmaps  ->", MAP_OUT, "\ntables ->", TBL_OUT, "\n")
# ------------------------------------------------------------------------------

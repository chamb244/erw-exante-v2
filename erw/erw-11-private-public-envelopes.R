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
# Because erw-7 stores agro_return, basalt_cost and cdr_net as separate layers,
# every envelope and the whole parameter sweep reduce to three area-weighted
# per-pixel primitives: AGRO ($/ha), BAS ($/ha), CDRN (tCO2/ha). The sweep is
# therefore fully analytic - no per-scenario model re-run.
#
# Baseline: REGIME = year1, allocations targeted + uniform_20, carbon $150/tCO2,
# MRV $20/tCO2 (matches erw-7 defaults).
#
# Inputs:
#   data/economics_erw/{targeted,uniform_20}/{crop}_year1.tif   (from erw-7)
#   data/spam_prod_processed.tif                                (value of prod)
#   data/FAOSTAT_data_en_4-24-2023.csv                          (producer prices)
#   data/gadm_ssa.gpkg                                          (country zonal)
#
# Outputs:
#   docs/maps/envelopes/*.png            envelope, typology, robustness, core maps
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

REGIME      <- "year1"
ALLOCS      <- c("targeted", "uniform_20")
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

# Build the three area-weighted primitives (+ weight, value-of-production, CDR-t)
build_primitives <- function(alloc) {
  num_agro <- num_bas <- num_cdrn <- wsum <- vop <- cdrt <- NULL
  ref <- rast(econ_path(alloc, CROPS[1]))[[1]]
  z <- ref * 0
  num_agro <- z; num_bas <- z; num_cdrn <- z; wsum <- z; vop <- z; cdrt <- z
  for (cp in CROPS) {
    r    <- rast(econ_path(alloc, cp))
    ha   <- r[[paste0(cp, "_ha")]]
    agro <- r[[paste0(cp, "_agro_return_usha")]]
    bas  <- r[[paste0(cp, "_basalt_cost_usha")]]
    cdrn <- r[[paste0(cp, "_cdr_net_tha")]]
    gmc  <- r[[paste0(cp, "_gm_combined_usha")]]
    defined <- !is.na(gmc) & !is.na(ha) & ha > 0
    w <- ifel(defined, ha, 0)
    num_agro <- num_agro + ifel(defined, ifel(is.na(agro),0,agro) * w, 0)
    num_bas  <- num_bas  + ifel(defined, ifel(is.na(bas), 0,bas)  * w, 0)
    num_cdrn <- num_cdrn + ifel(defined, ifel(is.na(cdrn),0,cdrn) * w, 0)
    wsum     <- wsum + w
    cdrt     <- cdrt + ifel(defined, ifel(is.na(cdrn),0,cdrn) * w, 0)
    pr <- prod_stack[[which(CROPS == cp)]]
    vop <- vop + ifel(defined, ifel(is.na(pr),0,pr) * crop_price[cp], 0)
  }
  ok   <- wsum > 0
  AGRO <- ifel(ok, num_agro / wsum, NA)
  BAS  <- ifel(ok, num_bas  / wsum, NA)
  CDRN <- ifel(ok, num_cdrn / wsum, NA)
  list(AGRO=AGRO, BAS=BAS, CDRN=CDRN,
       WSUM=ifel(ok, wsum, NA), VOP=ifel(ok, vop, NA),
       CDRT=ifel(ok, cdrt, NA), ok=ok)
}

# Envelopes from the primitives under arbitrary parameters
envelopes <- function(P, carbon=CARBON_BASE, ymult=1, cmult=1, rmult=1) {
  gm_agro <- P$AGRO*ymult - P$BAS*cmult
  gm_cdr  <- P$CDRN*rmult*(carbon-MRV) - P$BAS*cmult
  gm_comb <- P$AGRO*ymult + P$CDRN*rmult*(carbon-MRV) - P$BAS*cmult
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
    sprintf("Return typology - year-1, %s", alloc),
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
CMULT <- c(0.5,0.75,1.0,1.5,2.0)   # delivered basalt cost
CPRICE<- c(50,100,150,250)         # VCM carbon price
YMULT <- c(0.5,1.0,1.5,2.0)        # yield-benefit
RMULT <- c(0.5,1.0,1.5)            # CDR-rate
P <- PRIMS[["targeted"]]; ok <- P$ok
grid <- expand.grid(c=CMULT, cp=CPRICE, y=YMULT, r=RMULT)
N <- nrow(grid)
freq_i <- ref0*0; freq_c <- ref0*0
for (i in seq_len(N)) {
  g <- grid[i,]; e <- envelopes(P, g$cp, g$y, g$c, g$r)
  freq_i <- freq_i + ifel((e$priv & e$publ) & ok, 1, 0)
  freq_c <- freq_c + ifel(e$comb & ok, 1, 0)
}
robust_i <- mask(freq_i/N, ok, maskvalue=FALSE)
robust_c <- mask(freq_c/N, ok, maskvalue=FALSE)
plot_cont(robust_i, "robustness_intersection.png",
  sprintf("Robustness of the intersection (%d combos)", N), hcl.colors(20,"Inferno"),"frac")
plot_cont(robust_c, "robustness_combined.png",
  sprintf("Robustness of profitability (%d combos)", N), hcl.colors(20,"Viridis"),"frac")

core <- robust_i >= 0.50; cand <- robust_i >= 0.33
plot_cat(ifel(core,1,ifel(cand,2,0)), "core_priority.png",
  "Core targeting tiers (full-grid robustness)",
  c(0,2,1), c("grey85","#f4a259","#b30000"),
  c("outside","candidate >=33%","core >=50%"))

core_summary <- rbind(
  cbind(tier="core_>=50%",  summarize_mask(P, core & ok)),
  cbind(tier="candidate_>=33%", summarize_mask(P, cand & ok)))
write.csv(core_summary, file.path(TBL_OUT,"output-core-priority-summary.csv"), row.names=FALSE)

ha_c  <- zonal(ifel(core & ok, P$WSUM, 0), country_r, "sum", na.rm=TRUE)
vop_c <- zonal(ifel(core & ok, P$VOP,  0), country_r, "sum", na.rm=TRUE)
fs <- farm_ha[ha_c[[1]]]; fs[is.na(fs)] <- FARM_DEFAULT
core_country <- data.frame(iso3=ha_c[[1]], core_Mha=round(ha_c[[2]]/1e6,3),
  core_farms_M=round(ha_c[[2]]/fs/1e6,3), core_vop_Musd=round(vop_c[[2]]/1e6,1))
core_country <- core_country[order(-core_country$core_Mha),]
write.csv(core_country, file.path(TBL_OUT,"output-core-priority-by-country.csv"), row.names=FALSE)

# =============================================================================
# 3) one-at-a-time tornado: total intersection ha vs each parameter
# =============================================================================
inter_ha <- function(carbon, ymult, cmult, rmult) {
  e <- envelopes(P, carbon, ymult, cmult, rmult)
  as.numeric(global(ifel((e$priv & e$publ) & ok, P$WSUM, 0), "sum", na.rm=TRUE))/1e6
}
base_ha <- inter_ha(CARBON_BASE, 1, 1, 1)
axes <- list(carbon_price=list("carbon",CPRICE), yield_mult=list("ymult",YMULT),
             cost_mult=list("cmult",CMULT), cdr_rate_mult=list("rmult",RMULT))
tor <- list()
for (nm in names(axes)) {
  key <- axes[[nm]][[1]]; vals <- axes[[nm]][[2]]; hh <- numeric(length(vals))
  for (j in seq_along(vals)) {
    args <- list(CARBON_BASE,1,1,1)
    names(args) <- c("carbon","ymult","cmult","rmult")
    args[[c(carbon="carbon",ymult="ymult",cmult="cmult",rmult="rmult")[key]]] <- vals[j]
    hh[j] <- do.call(inter_ha, args)
  }
  tor[[nm]] <- data.frame(parameter=nm, min_inter_Mha=round(min(hh),2),
                          max_inter_Mha=round(max(hh),2), swing_Mha=round(max(hh)-min(hh),2))
}
tor_df <- do.call(rbind, tor); tor_df <- tor_df[order(-tor_df$swing_Mha),]
write.csv(tor_df, file.path(TBL_OUT,"output-sensitivity-tornado.csv"), row.names=FALSE)

cat("\nbaseline intersection:", round(base_ha,2), "Mha\n"); print(tor_df)

# =============================================================================
# 4) public/VCM envelope: marginal abatement cost + CDR-rate sensitivity panel
# =============================================================================
# Public-sufficiency reduces to a marginal-abatement-cost (MAC) test in which the
# per-hectare dose cancels:
#   MAC ($/tCO2) = cost_per_t_basalt / CDR_per_t_basalt = BAS / CDRN  (area-wt)
# The public envelope is exactly { MAC < carbon_price - MRV }. Because realized
# CDR per tonne basalt is small (~0.1-0.25 tCO2/t), MAC sits well above current
# VCM prices on most cropland -> the CDR RATE, not the credit price, is binding.
P <- PRIMS[["targeted"]]; ok <- P$ok
MAC <- ifel(P$CDRN > 0 & ok, P$BAS / P$CDRN, NA)

png(file.path(MAP_OUT,"mac_targeted.png"), width=1200, height=1100, res=150)
par(mar=c(2,2,3.5,4))
plot(clamp(MAC,0,500),
     main="Marginal abatement cost of ERW-CDR ($/tCO2)\n= delivered cost per t basalt / CDR per t basalt, targeted",
     col=rev(hcl.colors(20,"Inferno")), axes=FALSE, range=c(0,500),
     plg=list(title="$/tCO2", cex=0.8))
plot(ssa, add=TRUE, lwd=0.3, border="grey30"); dev.off()

area_of <- function(which=c("public","intersection"),
                    carbon=CARBON_BASE, rmult=1, cmult=1) {
  e <- envelopes(P, carbon=carbon, ymult=1, cmult=cmult, rmult=rmult)
  m <- if (match.arg(which)=="public") e$publ else (e$priv & e$publ)
  as.numeric(global(ifel(m & ok, P$WSUM, 0), "sum", na.rm=TRUE))/1e6
}

# carbon-price ladder
ladder_p <- c(50,100,130,150,200,250,300,400,500,750,1000)
ladder <- data.frame(carbon_usd=ladder_p,
  public_Mha=sapply(ladder_p, function(p) round(area_of("public", carbon=p),2)))
write.csv(ladder, file.path(TBL_OUT,"output-public-mac-price-ladder.csv"), row.names=FALSE)

# CDR-rate sweep (the binding lever)
rmults <- c(0.5,0.75,1.0,1.25,1.5,2.0,2.5)
cdr_sens <- data.frame(cdr_rate_mult=rmults,
  public_Mha       = sapply(rmults, function(r) round(area_of("public",       rmult=r),2)),
  intersection_Mha = sapply(rmults, function(r) round(area_of("intersection", rmult=r),2)))
write.csv(cdr_sens, file.path(TBL_OUT,"output-cdr-rate-sensitivity.csv"), row.names=FALSE)

# lever comparison on the public envelope
base_pub <- area_of("public")
levers <- c("+33% carbon ($200)"  = area_of("public", carbon=200),
            "-33% delivered cost" = area_of("public", cmult=0.67),
            "+33% CDR rate"       = area_of("public", rmult=1.33),
            "2x CDR rate"         = area_of("public", rmult=2.0))
lever_pct <- round(100*(levers/base_pub - 1), 0)

# two-panel CDR-rate sensitivity figure
png(file.path(MAP_OUT,"cdr_rate_sensitivity_panel.png"), width=2000, height=850, res=150)
par(mfrow=c(1,2), mar=c(4.5,4.5,3.5,1))
plot(rmults, cdr_sens$public_Mha, type="b", pch=19, col="#2156a8", lwd=2,
     ylim=c(0, max(cdr_sens$public_Mha)),
     xlab="CDR-rate multiplier (x realized tCO2 per t basalt)", ylab="Area (Mha)",
     main="(a) Envelope area vs CDR rate (targeted, $150/tCO2)")
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

cat("\nmaps  ->", MAP_OUT, "\ntables ->", TBL_OUT, "\n")
# ------------------------------------------------------------------------------

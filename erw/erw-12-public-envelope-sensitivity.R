# ------------------------------------------------------------------------------
# erw-12-public-envelope-sensitivity.R
#
# Sensitivity of the PUBLIC (carbon-only) return envelope to model assumptions.
#
# Public-sufficiency at a pixel is
#
#     cdr_net(r, lambda) * (p - m)  >  BAS * c
#
#   p      carbon price ($/tCO2)          m   MRV cost ($/tCO2)
#   c      delivered-cost multiplier      r   CDR-rate multiplier (x gross)
#   lambda net-export partition in [0,1]  BAS delivered basalt cost ($/ha)
#
# with the deduction applied in the CORRECT order -- r scales GROSS CDR, before
# the acidity sink is subtracted:
#
#     cdr_net(r,lambda) = max( max(r*GROSS - lambda*F*S, 0) - LCA , 0 )
#
# Three results this file establishes, each of which changes how the public
# envelope's uncertainty should be reported:
#
# Numbers below are on the headline PUBLIC_ALLOC = uniform_20; the targeted
# equivalents are given in parentheses.
#
#   (1) COLLAPSE. cdr_net depends on neither price nor cost, so the envelope
#       depends on (p, m, c) only through the single ratio (p - m)/c. The
#       five-lever tornado in erw-8 / erw_sensitivity_harness.py therefore
#       treats one knob as three; the apparent ranking carbon > cost > MRV is
#       an artifact of how wide each band was drawn, not a model property.
#
#   (2) ORDERING. The harness scales the already-deducted net CDR (r * cdr_net).
#       Physically r multiplies GROSS (reactive fraction x grain x climate x
#       exported fraction), and the sink F*S and LCA are fixed subtrahends. The
#       max(.,0) then makes cdr_net super-linear in r, so scaling net compresses
#       the lever on both sides. At r = 2 the public envelope is 12.56 Mha, not
#       the 5.99 Mha the harness reports (targeted: 5.90 vs 2.68).
#
#   (3) LAMBDA. The net-export partition -- the single most-scrutinised modelling
#       choice (see paper/netexport-cdr-memo.md Sec.6) -- moves the envelope only
#       from 3.51 (lambda=0, gross) to 3.16 Mha (lambda=1, sequential bound)
#       (targeted: 2.23 -> 1.65). It is the SMALLEST structural lever. Report one
#       number and a band, not two competing accountings.
#
#   NOTE. The CDR-rate lever still leads the tornado on uniform-20 (4.93 vs 4.60
#   Mha for the price ratio) but by a much narrower margin than on targeted (2.56
#   vs 2.16). uniform-20's acidity sink is a smaller share of its gross CDR
#   (0.42/3.94 = 11% vs 0.43/1.67 = 26%), so the marginal amplifier falls from
#   1.33 to 1.16 and the CDR-rate elasticity from 1.72 to 1.19. Re-leading the
#   carbon case on uniform-20 therefore WEAKENS the "CDR rate dominates" claim,
#   even as it roughly doubles the public envelope. Both facts should be reported.
#
# ACCOUNTING NOTE. This script reads band 8 `_cdr_gross_tha`, which is gross CDR
# before any net-export deduction under BOTH the current and the re-run erw-7,
# and reconstructs LCA from `_basalt_tha` and the energy/transport rasters. It is
# therefore invariant to whether erw-7 has been re-run since the net-export block
# was wired in (commit 16b6321) -- unlike erw-11, which reads band 9 directly.
# Section 0 reports which accounting the on-disk rasters actually carry.
#
# Inputs:
#   data/economics_erw/{targeted,uniform_20,uniform_50}/{crop}_{regime}.tif  (erw-7)
#   data/caco3_kamprath.tif, data/caco3_merlos_maintenance.tif              (erw-3)
#   data/grid_CI_kg_per_kWh.tif, data/basalt_transport_km.tif
#   data/basalt_feedstock_chemistry.csv
#
# Outputs:
#   docs/maps/envelopes/public_envelope_sensitivity_{PUBLIC_ALLOC}.png
#   docs/tables/output-public-*.csv
# ------------------------------------------------------------------------------

suppressMessages({ library(terra); library(here) })
terra::terraOptions(progress = 0)

DATA    <- here::here("data")
MAP_OUT <- here::here("docs", "maps", "envelopes")
TBL_OUT <- here::here("docs", "tables")
dir.create(MAP_OUT, recursive = TRUE, showWarnings = FALSE)
dir.create(TBL_OUT, recursive = TRUE, showWarnings = FALSE)

REGIME <- "equilibrium"          # manuscript headline; "year1"/"npv" also valid
ALLOCS <- c("targeted", "uniform_20", "uniform_50")

# The carbon case is led on uniform-20 (Sec.6): the targeted lime-requirement dose
# is CDR-minimal by construction, so leading the public envelope on it understates
# the carbon case ~1.9x in area and ~3.1x in tonnage. `targeted` remains the lead
# for the private/agronomic envelope elsewhere in the pipeline.
PUBLIC_ALLOC <- "uniform_20"

CARBON <- 150; MRV <- 20         # erw-7 defaults
RATIO0 <- CARBON - MRV           # central effective net price per unit cost

CROPS <- c("MAIZ","SORG","BEAN","CHIC","LENT","WHEA","BARL","ACOF","RCOF","PMIL",
           "SMIL","POTA","SWPO","CASS","COWP","PIGE","SOYB","GROU","SUGC","COTT",
           "COCO","TEAS","TOBA")

fs <- read.csv(file.path(DATA, "basalt_feedstock_chemistry.csv"))
gf <- function(p) as.numeric(fs$value[fs$parameter == p])
F_REEXPORT <- gf("CDR_eff_kg_per_t_ref") / (gf("effective_NV") * 1000)   # ~0.880
GRIND_KWH  <- gf("grinding_kWh_per_t")
cat(sprintf("F (tCO2 re-released per tCaCO3-eq neutralized) = %.3f\n", F_REEXPORT))

# ------------------------------------------------------------------------------
# separable per-pixel primitives, area-weighted across the crops sharing a pixel

sink_raster <- function() {
  f <- if (REGIME %in% c("year1","npv")) "caco3_kamprath.tif" else "caco3_merlos_maintenance.tif"
  terra::aggregate(terra::rast(file.path(DATA, f))[[1]], 10, mean, na.rm = TRUE)
}
S_raw <- sink_raster()
ci    <- terra::rast(file.path(DATA, "grid_CI_kg_per_kWh.tif"))
km    <- terra::rast(file.path(DATA, "basalt_transport_km.tif"))

build_primitives <- function(alloc) {
  cat("  primitives:", alloc, "")
  epath <- function(cp) file.path(DATA, "economics_erw", alloc, paste0(cp, "_", REGIME, ".tif"))
  ref   <- terra::rast(epath(CROPS[1]))[[1]]

  lca_kg_per_t <- GRIND_KWH * terra::resample(ci, ref) +
                  terra::resample(km, ref) * 0.12 + 0.5
  S <- terra::resample(S_raw, ref); S <- terra::ifel(is.na(S), 0, S)

  z <- ref * 0
  n_agro <- z; n_bas <- z; n_gross <- z; n_lca <- z; wsum <- z
  nz <- function(x) terra::ifel(is.na(x), 0, x)
  for (cp in CROPS) {
    r     <- terra::rast(epath(cp))
    ha    <- r[[paste0(cp, "_ha")]]
    gmc   <- r[[paste0(cp, "_gm_combined_usha")]]
    btha  <- r[[paste0(cp, "_basalt_tha")]]
    defined <- !is.na(gmc) & !is.na(ha) & ha > 0
    w <- terra::ifel(defined, ha, 0)
    n_agro  <- n_agro  + terra::ifel(defined, nz(r[[paste0(cp,"_agro_return_usha")]]) * w, 0)
    n_bas   <- n_bas   + terra::ifel(defined, nz(r[[paste0(cp,"_basalt_cost_usha")]]) * w, 0)
    n_gross <- n_gross + terra::ifel(defined, nz(r[[paste0(cp,"_cdr_gross_tha")]])    * w, 0)
    n_lca   <- n_lca   + terra::ifel(defined, nz(btha * lca_kg_per_t / 1000)          * w, 0)
    wsum    <- wsum + w
    cat(".")
  }
  cat("\n")
  ok <- wsum > 0
  out <- c(terra::ifel(ok, n_agro/wsum, NA), terra::ifel(ok, n_bas/wsum, NA),
           terra::ifel(ok, n_gross/wsum, NA), terra::ifel(ok, n_lca/wsum, NA),
           terra::ifel(ok, S, NA), terra::ifel(ok, wsum, NA))
  names(out) <- c("AGRO","BAS","GROSS","LCA","S","WSUM")
  d <- as.data.frame(out, na.rm = FALSE)
  d[!is.na(d$WSUM) & d$WSUM > 0, ]
}

PR <- lapply(setNames(ALLOCS, ALLOCS), build_primitives)
P  <- PR[[PUBLIC_ALLOC]]
cat(sprintf("\nheadline allocation for the public envelope: %s\n", PUBLIC_ALLOC))

# ------------------------------------------------------------------------------
# envelope algebra

pos      <- function(x) pmax(x, 0)
cdr_net  <- function(d, r = 1, lam = 1) pos(pos(r*d$GROSS - lam*F_REEXPORT*d$S) - d$LCA)
cdr_harn <- function(d, r = 1, lam = 1) r * pos(pos(d$GROSS - lam*F_REEXPORT*d$S) - d$LCA)

pub_mask <- function(d, ratio = RATIO0, r = 1, lam = 1, fn = cdr_net)
  fn(d, r, lam) * ratio - d$BAS > 0
Mha <- function(d, ...) sum(d$WSUM[pub_mask(d, ...)]) / 1e6
Mt  <- function(d, ratio = RATIO0, r = 1, lam = 1, fn = cdr_net) {
  cd <- fn(d, r, lam); sum((cd * d$WSUM)[cd*ratio - d$BAS > 0]) / 1e6
}
wmedian <- function(x, w) { o <- order(x); x <- x[o]; w <- w[o]
  as.numeric(approx(cumsum(w)/sum(w), x, 0.5, ties = "ordered")$y) }

# ==============================================================================
# 0) which accounting do the on-disk rasters carry?
# ==============================================================================
cat("\n== 0) accounting check on the committed economics_erw rasters ==\n")
r1  <- terra::rast(file.path(DATA,"economics_erw",PUBLIC_ALLOC,paste0("MAIZ_",REGIME,".tif")))
gg  <- r1[["MAIZ_cdr_gross_tha"]]; nn <- r1[["MAIZ_cdr_net_tha"]]
lca <- r1[["MAIZ_basalt_tha"]] * (GRIND_KWH*terra::resample(ci,gg) +
                                  terra::resample(km,gg)*0.12 + 0.5) / 1000
Sg  <- terra::resample(S_raw, gg); Sg <- terra::ifel(is.na(Sg), 0, Sg)
resid <- function(pred) as.numeric(terra::global(abs(nn - pred), "max", na.rm = TRUE))
rA <- resid(terra::ifel(gg-lca < 0, 0, gg-lca))                                    # no deduction
rB <- resid(terra::ifel(terra::ifel(gg-F_REEXPORT*Sg<0,0,gg-F_REEXPORT*Sg)-lca<0, 0,
                        terra::ifel(gg-F_REEXPORT*Sg<0,0,gg-F_REEXPORT*Sg)-lca))   # net-export
acct <- data.frame(hypothesis = c("net = max(gross - LCA, 0)  [NO net-export]",
                                  "net = max(max(gross - F*S,0) - LCA, 0)  [net-export]"),
                   max_abs_residual_tCO2_ha = c(rA, rB))
print(acct, row.names = FALSE, digits = 3)
cat(sprintf("-> on-disk rasters carry: %s\n",
            if (rA < rB) "GROSS (net-export NOT applied; erw-7 not re-run)" else "NET-EXPORT"))
write.csv(acct, file.path(TBL_OUT,"output-public-envelope-accounting-check.csv"), row.names=FALSE)

# ==============================================================================
# 1) COLLAPSE: (p, m, c) enter only through (p - m)/c
# ==============================================================================
cat("\n== 1) collapse of the three price/cost levers ==\n")
tri <- data.frame(carbon = c(150,280, 85,140,400, 75,170),
                  mrv    = c( 20, 20, 20, 10, 10, 10, 40),
                  cost_x = c(1.0,2.0,0.5,1.0,3.0,0.5,1.0))
tri$ratio      <- (tri$carbon - tri$mrv) / tri$cost_x
tri$public_Mha <- mapply(function(p,m,c) Mha(P, ratio = (p-m)/c), tri$carbon, tri$mrv, tri$cost_x)
print(tri, row.names = FALSE, digits = 5)
cat(sprintf("-> %d distinct (p,m,c) triples, all ratio=%.0f, spread in area = %.2e Mha\n",
            nrow(tri), tri$ratio[1], diff(range(tri$public_Mha))))
write.csv(tri, file.path(TBL_OUT,"output-public-envelope-collapse.csv"), row.names=FALSE)

# ==============================================================================
# 2) ORDERING: scaling GROSS (correct) vs scaling NET (current harness)
# ==============================================================================
cat("\n== 2) CDR-rate lever, correct vs harness ordering ==\n")
rs  <- c(0.25,0.5,0.75,1.0,1.25,1.5,2.0,2.5,3.0)
ord <- data.frame(r = rs,
  correct_Mha = sapply(rs, function(r) Mha(P, r=r)),
  harness_Mha = sapply(rs, function(r) Mha(P, r=r, fn=cdr_harn)),
  correct_Mt  = sapply(rs, function(r) Mt (P, r=r)),
  harness_Mt  = sapply(rs, function(r) Mt (P, r=r, fn=cdr_harn)))
print(ord, row.names = FALSE, digits = 3)
write.csv(ord, file.path(TBL_OUT,"output-public-cdr-rate-ordering.csv"), row.names=FALSE)

# ==============================================================================
# 3) LAMBDA sweep
# ==============================================================================
cat("\n== 3) net-export partition lambda ==\n")
lams <- c(0, 0.25, 0.5, 0.75, 1.0)
lam_df <- data.frame(lambda = lams,
  public_Mha = sapply(lams, function(l) Mha(P, lam=l)),
  public_Mt  = sapply(lams, function(l) Mt (P, lam=l)),
  median_MAC = sapply(lams, function(l) { cd <- cdr_net(P,1,l)
                       wmedian((P$BAS/cd)[cd>0], P$WSUM[cd>0]) }))
print(lam_df, row.names = FALSE, digits = 4)
write.csv(lam_df, file.path(TBL_OUT,"output-public-lambda-sweep.csv"), row.names=FALSE)

# ==============================================================================
# 4) band-free ranking: local log-log elasticities at Central
# ==============================================================================
cat("\n== 4) elasticities of public area at Central ==\n")
h <- 0.02
e_ratio <- (log(Mha(P, ratio=RATIO0*exp(h))) - log(Mha(P, ratio=RATIO0*exp(-h))))/(2*h)
e_r     <- (log(Mha(P, r=exp(h)))            - log(Mha(P, r=exp(-h))))/(2*h)
s_lam   <- (log(Mha(P, lam=1))               - log(Mha(P, lam=0.95)))/0.05
cd0 <- cdr_net(P); bcr <- (cd0*RATIO0)/P$BAS; marg <- bcr>0.95 & bcr<1.05 & cd0>0
ela <- data.frame(
  quantity = c("d lnA / d ln[(p-m)/c]","d lnA / d ln[CDR rate r]","d lnA / d lambda",
               "marginal-pixel amplifier GROSS/cdr_net"),
  value = c(e_ratio, e_r, s_lam, wmedian((P$GROSS/cd0)[marg], P$WSUM[marg])))
print(ela, row.names = FALSE, digits = 3)
cat(sprintf("-> elasticity ratio e_r/e_ratio = %.2f matches the marginal amplifier %.2f:\n",
            e_r/e_ratio, ela$value[4]))
cat("   d(cdr_net)/dr = GROSS, not cdr_net, because F*S and LCA are fixed subtrahends.\n")
write.csv(ela, file.path(TBL_OUT,"output-public-elasticities.csv"), row.names=FALSE)

# ==============================================================================
# 5) tornado on the collapsed levers
# ==============================================================================
cat("\n== 5) public-envelope tornado (collapsed levers) ==\n")
base <- Mha(P)
tor <- data.frame(
  lever = c("CDR rate (x0.5-1.5)","Effective (p-m)/c [80-230]","Net-export lambda (1-0)"),
  low   = c(Mha(P,r=0.5), Mha(P,ratio=80),  Mha(P,lam=1)),
  high  = c(Mha(P,r=1.5), Mha(P,ratio=230), Mha(P,lam=0)))
tor$swing <- abs(tor$high - tor$low)
tor <- tor[order(-tor$swing), ]
cat(sprintf("baseline public = %.2f Mha\n", base)); print(tor, row.names=FALSE, digits=3)
write.csv(tor, file.path(TBL_OUT,"output-public-tornado.csv"), row.names=FALSE)

# ==============================================================================
# 6) allocation ladder -- the targeted dose is CDR-minimal by construction
# ==============================================================================
cat("\n== 6) allocation ladder ==\n")
ald <- do.call(rbind, lapply(ALLOCS, function(a) {
  d <- PR[[a]]; cd <- cdr_net(d)
  data.frame(allocation = a,
             gross_tCO2_ha = mean(d$GROSS), sink_FS_tCO2_ha = mean(F_REEXPORT*d$S),
             cdr_net_tCO2_ha = mean(cd), public_Mha = Mha(d), public_Mt = Mt(d),
             median_MAC = wmedian((d$BAS/cd)[cd>0], d$WSUM[cd>0]))
}))
print(ald, row.names = FALSE, digits = 3)
cat("-> the acidity sink F*S is a soil property (near-constant across allocations)\n")
cat("   while gross CDR scales with dose: the lime-requirement dose is CDR-minimal.\n")
write.csv(ald, file.path(TBL_OUT,"output-public-allocation-ladder.csv"), row.names=FALSE)

# ==============================================================================
# 7) figure
# ==============================================================================
png(file.path(MAP_OUT, sprintf("public_envelope_sensitivity_%s.png", PUBLIC_ALLOC)),
    width=2100, height=1750, res=170)
par(mfrow=c(2,2), mar=c(4.6,4.6,3.6,1.4))

rr <- seq(0.5, 3, by = 0.05)
ac <- sapply(rr, function(r) Mha(P, r=r)); ah <- sapply(rr, function(r) Mha(P, r=r, fn=cdr_harn))
plot(rr, ac, type="l", lwd=3, col="#b3261e", ylim=c(0, max(ac)),
     xlab="CDR-rate multiplier  r  (x gross tCO2 per t basalt)",
     ylab="Public-sufficient area (Mha)",
     main=sprintf("(a) The CDR-rate lever is understated when r\nscales post-deduction CDR (%s)", PUBLIC_ALLOC))
lines(rr, ah, lwd=3, col="#2156a8", lty=2); abline(v=1, col="grey60", lty=3)
points(1, base, pch=19)
legend("topleft", c("correct: r scales GROSS","current harness: r scales NET"),
       col=c("#b3261e","#2156a8"), lwd=3, lty=c(1,2), bty="n", cex=0.85)
text(2.05, Mha(P,r=2)+0.5, sprintf("%.1fx at r=2", Mha(P,r=2)/Mha(P,r=2,fn=cdr_harn)),
     cex=0.8, col="#b3261e")

rat <- seq(40, 400, length.out=48); rg <- seq(0.4, 2.5, length.out=48)
Z <- outer(rat, rg, Vectorize(function(a,b) Mha(P, ratio=a, r=b)))
image(rat, rg, Z, col=hcl.colors(24,"YlOrRd", rev=TRUE),
      xlab="effective net price per unit delivered cost  (p - m)/c",
      ylab="CDR-rate multiplier  r",
      main="(b) The public envelope is a surface\nover exactly two composite knobs")
contour(rat, rg, Z, add=TRUE, levels=c(0.5,1.65,3,6,10,14), labcex=0.65, col="grey20")
points(RATIO0, 1, pch=21, bg="white", cex=1.4); text(RATIO0, 1.12, "Central", cex=0.75)

par(mar=c(4.6,15,3.6,1.4))
t2 <- tor[order(tor$swing), ]
plot(NA, xlim=c(0, max(t2$high)*1.05), ylim=c(0.5, nrow(t2)+0.5), yaxt="n",
     xlab="Public-sufficient area (Mha)", ylab="",
     main="(c) Tornado after collapsing the three\nprice/cost levers into one ratio")
for (i in seq_len(nrow(t2)))
  segments(min(t2$low[i],t2$high[i]), i, max(t2$low[i],t2$high[i]), i, lwd=15, col="#4472a8", lend=1)
axis(2, seq_len(nrow(t2)), t2$lever, las=1, cex.axis=0.85)
abline(v=base, lty=2, col="grey40"); text(base, nrow(t2)+0.42, sprintf("central %.2f", base), cex=0.72)

par(mar=c(4.6,4.6,3.6,1.4))
lseq <- seq(0,1,by=0.02); al <- sapply(lseq, function(l) Mha(P, lam=l))
plot(lseq, al, type="l", lwd=3, col="#1a7d3c", ylim=c(0, max(al)*1.08),
     xlab=expression(paste("net-export partition  ", lambda, "   (0 = gross, 1 = sequential bound)")),
     ylab="Public-sufficient area (Mha)",
     main="(d) The most-scrutinised modelling choice\nis NOT what drives the answer")
polygon(c(lseq, rev(lseq)), c(al, rep(0, length(al))), col="#1a7d3c22", border=NA)
points(c(0,1), c(Mha(P,lam=0), Mha(P,lam=1)), pch=19)
text(0.07, Mha(P,lam=0)+0.09, sprintf("%.2f", Mha(P,lam=0)), cex=0.8)
text(0.93, Mha(P,lam=1)+0.09, sprintf("%.2f", Mha(P,lam=1)), cex=0.8)
dev.off()

cat("\nmaps   ->", MAP_OUT, "\ntables ->", TBL_OUT, "\n")
# ------------------------------------------------------------------------------

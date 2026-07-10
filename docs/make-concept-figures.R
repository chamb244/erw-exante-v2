## Conceptual figures for the ERW end-to-end modelling report
## (1) EcoCrop suitability envelope  (2) CDR-efficiency cascade
## Base-R graphics, 300 dpi, white background to match the house style.

# Writes the two conceptual figures used by docs/erw-technical-report.tex.
# Run from the repo root:  Rscript docs/make-concept-figures.R
outdir <- if (dir.exists("docs/figures")) "docs/figures" else "figures"

## crop-type palette (matches erw-4)
col_cereal <- "#4682B4"  # steelblue
col_rtb    <- "#A0522D"  # sienna
col_comm   <- "#DAA520"  # goldenrod
col_leg    <- "#228B22"  # forestgreen
grid_col   <- "#DDDDDD"
ax_col     <- "#333333"

panel_setup <- function(xlim, ylim, xlab, ylab, main, yticks) {
  plot.new(); plot.window(xlim = xlim, ylim = ylim)
  abline(h = yticks, col = grid_col, lwd = 0.8)
  axis(1, col = ax_col, col.axis = ax_col, cex.axis = 0.9, lwd = 0.8)
  axis(2, at = yticks, las = 1, col = ax_col, col.axis = ax_col,
       cex.axis = 0.9, lwd = 0.8)
  title(main = main, cex.main = 1.05, font.main = 2, col.main = "#111111",
        line = 1.4)
  title(xlab = xlab, ylab = ylab, col.lab = ax_col, cex.lab = 0.98)
}

## ---------- Figure 1: EcoCrop suitability envelope -------------------------
png(file.path(outdir, "fig-ecocrop-concept.png"),
    width = 11.2, height = 3.7, units = "in", res = 300)
par(mfrow = c(1, 3), mar = c(4.3, 4.2, 3.0, 1.0), mgp = c(2.4, 0.6, 0),
    family = "sans")

## (a) generic trapezoidal envelope --------------------------------------
yticks <- seq(0, 1, 0.25)
panel_setup(c(0, 10), c(0, 1.05), "Environmental variable (generic units)",
            "Suitability  s  (0-1)",
            "(a)  EcoCrop tolerance envelope", yticks)
amin <- 2; omin <- 4; omax <- 7; amax <- 9
xx <- c(0, amin, omin, omax, amax, 10)
yy <- c(0, 0,    1,    1,    0,    0)
polygon(c(xx, 10, 0), c(yy, 0, 0), col = "#4682B420", border = NA)
lines(xx, yy, col = col_cereal, lwd = 3)
bp <- c(amin, omin, omax, amax)
segments(bp, 0, bp, c(0, 1, 1, 0), col = ax_col, lty = 3, lwd = 1)
lbl <- c("absolute\nmin", "optimal\nmin", "optimal\nmax", "absolute\nmax")
text(bp, c(-0.02, 1.04, 1.04, -0.02), lbl, cex = 0.72, col = ax_col,
     pos = c(1, 3, 3, 1), xpd = NA)
text(5.5, 0.5, "plateau\ns = 1", cex = 0.8, col = "#215a86")

## (b) soil-pH response used in the pipeline -----------------------------
ph <- seq(3.5, 8, 0.02)
resp_ramp <- function(x, lo, hi, floor = 0.2) {
  r <- ifelse(x <= lo, 0, ifelse(x >= hi, 1, (x - lo) / (hi - lo)))
  pmax(floor, r)
}
panel_setup(c(3.5, 8), c(0, 1.05), "Soil pH (water)",
            "Relative yield", "(b)  Soil-pH response (Recocrop)", yticks)
crops_b <- list(
  list(name = "Maize (4.5-7.0)",   lo = 4.5, hi = 7.0, col = col_cereal),
  list(name = "Cassava (4.0-7.0)", lo = 4.0, hi = 7.0, col = col_rtb),
  list(name = "Tea (4.0-5.5)",     lo = 4.0, hi = 5.5, col = col_comm))
for (c in crops_b) lines(ph, resp_ramp(ph, c$lo, c$hi), col = c$col, lwd = 2.6)
abline(h = 0.2, lty = 2, col = "#888888", lwd = 1)
text(7.9, 0.24, "Recocrop floor 0.2", cex = 0.66, col = "#666666", pos = 2)
## basalt "nudge" arrow along the maize curve
x0 <- 5.2; x1 <- 6.0
arrows(x0, resp_ramp(x0, 4.5, 7.0), x1, resp_ramp(x1, 4.5, 7.0),
       length = 0.08, lwd = 2, col = "#B22222")
text(5.6, resp_ramp(5.6, 4.5, 7.0) + 0.13, "basalt raises pH",
     cex = 0.72, col = "#B22222", font = 3)
legend("bottomright", legend = sapply(crops_b, `[[`, "name"),
       col = sapply(crops_b, `[[`, "col"), lwd = 2.6, bty = "n",
       cex = 0.78, seg.len = 1.6)

## (c) acidity-saturation response ---------------------------------------
sat <- seq(0, 100, 0.5)
resp_decl <- function(x, plat, zero, floor = 0.2) {
  r <- ifelse(x <= plat, 1, ifelse(x >= zero, 0, 1 - (x - plat) / (zero - plat)))
  pmax(floor, r)
}
panel_setup(c(0, 100), c(0, 1.05), "Acidity (Al) saturation (% of ECEC)",
            "Relative yield", "(c)  Acidity-saturation response", yticks)
crops_c <- list(
  list(name = "acid-sensitive (10-40%)", plat = 10, zero = 40, col = col_leg),
  list(name = "moderate (20-55%)",       plat = 20, zero = 55, col = col_cereal),
  list(name = "acid-tolerant (60-90%)",  plat = 60, zero = 90, col = col_rtb))
for (c in crops_c) lines(sat, resp_decl(sat, c$plat, c$zero), col = c$col, lwd = 2.6)
abline(h = 0.2, lty = 2, col = "#888888", lwd = 1)
legend("topright", legend = sapply(crops_c, `[[`, "name"),
       col = sapply(crops_c, `[[`, "col"), lwd = 2.6, bty = "n",
       cex = 0.78, seg.len = 1.6)
dev.off()

## ---------- Figure 2: CDR-efficiency cascade (stage bars) ------------------
png(file.path(outdir, "fig-cdr-cascade.png"),
    width = 8.8, height = 4.7, units = "in", res = 300)
par(mar = c(5.8, 4.8, 3.2, 1.2), mgp = c(2.7, 0.6, 0), family = "sans")

## per-tonne CDR chain, reference climate, humid short-haul pixel (kg CO2/t)
labels <- c("Stoichiometric\nceiling",
            "x reactive\nfraction",
            "x grain-size\nfactor",
            "Net durable CDR\n(ref. climate, humid)")
vals    <- c(310, 62, 88, 82)
between <- c("x 0.20", "x 1.41", "- LCA")   # transition annotations
is_tot  <- c(TRUE, FALSE, FALSE, TRUE)
n <- length(labels)

plot.new(); plot.window(xlim = c(0.4, n + 0.6), ylim = c(0, 340))
abline(h = seq(0, 300, 50), col = grid_col, lwd = 0.8)
axis(2, at = seq(0, 300, 50), las = 1, col = ax_col, col.axis = ax_col,
     cex.axis = 0.9, lwd = 0.8)
title(ylab = expression("CDR efficiency  (kg CO"[2]*" per t basalt)"),
      col.lab = ax_col, cex.lab = 1.0)
title(main = "How much of the stoichiometric ceiling survives?",
      cex.main = 1.14, font.main = 2, col.main = "#111111", line = 1.4)

## faint reference line at the ceiling
abline(h = 310, col = "#c9d6e3", lty = 2, lwd = 1)

w <- 0.36
for (i in 1:n) {
  fill <- if (is_tot[i]) "#2c5f8a" else "#5a9bd4"
  bd   <- if (is_tot[i]) "#1d4160" else "#2f6ea5"
  rect(i - w, 0, i + w, vals[i], col = fill, border = bd, lwd = 1.4)
  text(i, vals[i] + 12, sprintf("%.0f", vals[i]), cex = 0.9, font = 2,
       col = "#111111")
  ## transition annotation + arrow between bar i and i+1
  if (i < n) {
    ytop <- max(vals[i], vals[i + 1])
    arrows(i + w + 0.02, vals[i], i + 1 - w - 0.02, vals[i + 1],
           length = 0.07, lwd = 1.6, col = "#B22222")
    text((i + i + 1) / 2, ytop + 34, between[i], cex = 0.82, font = 2,
         col = "#B22222")
  }
}
text(1:n, rep(-46, n), labels, cex = 0.78, col = ax_col, xpd = NA)
text(n, 200, "~0.08 tCO2 / t\ndurable", cex = 0.82, col = "#1d4160", font = 3)
mtext(paste("Reference climate, humid short-haul pixel. Across SSA the climate factor scales this +-(0.3-3x)",
            "and drylands lose up to 90% to pedogenic carbonate,\nso realised durable CDR spans roughly 0.03-0.15 tCO2 per t basalt."),
      side = 1, line = 4.5, cex = 0.66, col = "#666666")
dev.off()

cat("wrote fig-ecocrop-concept.png and fig-cdr-cascade.png\n")

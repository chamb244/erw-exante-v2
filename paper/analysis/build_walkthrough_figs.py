#!/usr/bin/env python3
"""Refresh the walkthrough deck's matplotlib figures on the current basis:
fig-netexport.png (returns vs pH, NPV), fig-supply-curve.png (public envelope
vs carbon price, targeted), fig-core.png (core targeting tiers, 180-grid).
The six house-style maps come from erw_maps_housestyle.R; fig-overliming.png
is copied from erw_overliming_sensitivity.py's output."""
import os, sys, numpy as np, rasterio
from rasterio.warp import reproject, Resampling
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
import geopandas as gpd

HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import erw_envelope_primitives as P
FIGOUT = os.path.join(os.path.dirname(os.path.dirname(HERE)), "erw-exante-v2")  # placeholder
FIGOUT = os.path.join(P.ROOT, "docs", "figures")
CARBON, MRV = 150.0, 20.0

ssa = gpd.read_file(f"{P.DATA}/gadm_ssa.gpkg")

# ---------- fig-netexport: returns vs pH (NPV) --------------------------------
def ph_on_grid(prim, regime):
    ref = f"{P.DATA}/economics_erw/{prim['alloc']}/MAIZ_{regime}.tif"
    with rasterio.open(ref) as ds:
        H, W, TR, CRS = ds.height, ds.width, ds.transform, ds.crs
    dst = np.full((H, W), np.nan, np.float32)
    with rasterio.open(f"{P.DATA}/soilgrids_properties_cropland.tif") as s:
        reproject(rasterio.band(s, 2), dst, src_transform=s.transform, src_crs=s.crs,
                  dst_transform=TR, dst_crs=CRS, resampling=Resampling.average)
        if s.nodata is not None: dst[dst == s.nodata] = np.nan
    return dst

def profile(prim, ph, lam):
    cd = P.cdr_net(prim, 1.0, lam)
    mids, priv, pub = [], [], []
    for lo in np.arange(4.8, 6.6, 0.2):
        m = prim["ok"] & (ph >= lo) & (ph < lo + 0.2)
        w = prim["WSUM"][m]
        if w.sum() < 1e4: continue
        mids.append(lo + 0.1)
        priv.append(np.nansum(prim["AGRO"][m]*w)/w.sum())
        pub.append(np.nansum(cd[m]*(CARBON-MRV)*w)/w.sum())
    return np.array(mids), np.array(priv), np.array(pub)

fig, axes = plt.subplots(1, 2, figsize=(13.5, 5.2), dpi=120)
for ax, alloc, ttl in [(axes[0], "targeted", "(a) Targeted (lime-requirement dose)"),
                       (axes[1], "uniform_20", "(b) Uniform 20 t/ha dose")]:
    prim = P.build(alloc, "npv"); ph = ph_on_grid(prim, "npv")
    x, pr, _ = profile(prim, ph, 1.0)
    _, _, pg = profile(prim, ph, 0.0)
    _, _, pn = profile(prim, ph, 1.0)
    ax.plot(x, pr, "-o", color="#2e7d32", lw=2.5, ms=7, label="Private (yield) return $/ha")
    ax.plot(x, pg, "--s", color="#a8c4e6", lw=2, ms=7, label="Public, gross CDR (current model)")
    ax.plot(x, pn, "-s", color="#1a4f9c", lw=2.5, ms=7, label="Public, net-export CDR (acidity-sink deducted)")
    ax.set_title(ttl, fontsize=13); ax.set_xlabel("Soil pH"); ax.set_ylabel("NPV return ($/ha)")
    ax.legend(fontsize=9); ax.grid(alpha=0.25)
fig.suptitle("Does the public peak shift to higher pH? Net-export CDR accounting (NPV)", fontsize=14)
fig.tight_layout(rect=(0, 0, 1, 0.95))
fig.savefig(f"{FIGOUT}/fig-netexport.png", bbox_inches="tight"); plt.close(fig)
print("fig-netexport.png")

# ---------- fig-supply-curve: public envelope vs carbon price (targeted) ------
prim = P.build("targeted")
cd = P.cdr_net(prim); W, ok = prim["WSUM"], prim["ok"]
prices = np.arange(40, 1001, 20)
areas, cdrs = [], []
for p in prices:
    m = ok & ((cd*(p-MRV) - prim["BAS"]) > 0)
    areas.append(np.nansum(np.where(m, W, 0))/1e6)
    cdrs.append(np.nansum(np.where(m, cd*W, 0))/1e6)
fig, ax = plt.subplots(figsize=(9.5, 5.6), dpi=120)
ax.plot(prices, areas, color="#1a4f9c", lw=2.5, label="public-sufficient area (Mha)")
ax.axvline(150, color="k", ls="--", lw=1.2); ax.text(155, 0.4, "current 150", fontsize=9)
ax.set_xlabel("VCM carbon price ($/tCO2)"); ax.set_ylabel("Public-sufficient area (Mha)")
ax.set_title("Public envelope vs carbon price (targeted, MRV $20)", fontsize=13)
ax2 = ax.twinx()
ax2.plot(prices, cdrs, color="#2e7d32", ls="--", lw=2)
ax2.set_ylabel("Cumulative net CDR (Mt CO2)", color="#2e7d32")
ax.legend(loc="upper left", fontsize=9); ax.grid(alpha=0.2)
fig.tight_layout(); fig.savefig(f"{FIGOUT}/fig-supply-curve.png", bbox_inches="tight"); plt.close(fig)
print("fig-supply-curve.png")

# ---------- fig-core: robustness tiers on the 180-point grid ------------------
YC  = [0.5, 0.75, 1.0, 1.5, 2.0]
PC  = [30, 80, 130, 230]
RM  = [0.5, 1.0, 1.5]
LAM = [0.0, 0.5, 1.0]
score = np.zeros_like(prim["WSUM"]); N = 0
for r in RM:
    for lam in LAM:
        cdr = P.cdr_net(prim, r, lam)
        for yc in YC:
            privm = (prim["AGRO"]*yc - prim["BAS"]) > 0
            for pc in PC:
                pubm = (cdr*pc - prim["BAS"]) > 0
                score += (privm & pubm & ok); N += 1
score = score / N
core = ok & (score >= 0.50); cand = ok & (score >= 1/3) & ~core; outside = ok & (score < 1/3)
extent = prim["extent"]
fig, ax = plt.subplots(figsize=(9.2, 8.6), dpi=120)
def show(mask, color):
    img = np.zeros(mask.shape + (4,), np.float32)
    img[mask] = matplotlib.colors.to_rgba(color)
    ax.imshow(img, extent=extent, origin="upper", interpolation="nearest")
show(outside, "#cccccc"); show(cand, "#f4a259"); show(core, "#b30000")
ssa.boundary.plot(ax=ax, color="#555555", linewidth=0.5)
ax.set_xlim(extent[0], extent[1]); ax.set_ylim(extent[2], extent[3])
ax.set_xticks([]); ax.set_yticks([])
ax.set_title("Core targeting tiers (full-grid robustness)", fontsize=14)
from matplotlib.patches import Patch
ax.legend(handles=[Patch(fc="#cccccc", label="outside"),
                   Patch(fc="#f4a259", label="candidate (>=33%)"),
                   Patch(fc="#b30000", label="core (>=50%)")], loc="lower left", fontsize=10)
fig.tight_layout(); fig.savefig(f"{FIGOUT}/fig-core.png", bbox_inches="tight"); plt.close(fig)
core_mha = np.nansum(np.where(core, W, 0))/1e6
cand_mha = np.nansum(np.where(cand | core, W, 0))/1e6
print(f"fig-core.png  (check: core {core_mha:.2f} Mha, candidate {cand_mha:.2f} Mha)")

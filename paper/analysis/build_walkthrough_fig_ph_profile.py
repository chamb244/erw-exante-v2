#!/usr/bin/env python3
"""Slide-10 figure: private vs public (gross / net-export) returns along the soil-pH
gradient, NPV regime (first application), from the current rasters. Replaces the old NPV-basis
chart baked into the 2026-07 walkthrough deck."""
import numpy as np, rasterio, sys, os
from rasterio.warp import reproject, Resampling
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import erw_envelope_primitives as P

CARBON, MRV = 150.0, 20.0

def ph_on_grid(prim):
    ref = f"{P.DATA}/economics_erw/{prim['alloc']}/MAIZ_npv.tif"
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
    bins = np.arange(4.9, 6.7, 0.2)
    mids, priv, pub = [], [], []
    for lo in bins[:-1]:
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
    prim = P.build(alloc, "npv")
    ph = ph_on_grid(prim)
    x, pr, _ = profile(prim, ph, 1.0)
    _, _, pg = profile(prim, ph, 0.0)
    _, _, pn = profile(prim, ph, 1.0)
    ax.plot(x, pr, "-o", color="#2e7d32", lw=2.5, ms=6, label="Private (yield) return $/ha")
    ax.plot(x, pg, "--s", color="#a8c4e6", lw=2, ms=6, label="Public, gross CDR")
    ax.plot(x, pn, "-s", color="#1a4f9c", lw=2.5, ms=6, label="Public, net-export CDR (acidity-sink deducted)")
    ax.set_title(ttl); ax.set_xlabel("Soil pH"); ax.set_ylabel("NPV return ($/ha, area-weighted)")
    ax.legend(fontsize=8.5); ax.grid(alpha=0.25)
fig.suptitle("Standing acidity consumes the first-application carbon case — NPV, gross vs net-export "
             "(2026-09 basis: Arrhenius temperature factor, pH optimum 6.0)", fontsize=12)
fig.tight_layout(rect=(0, 0, 1, 0.94))
out = os.path.join(HERE, "..", "figures", "walkthrough_ph_profile_npv.png")
fig.savefig(out, bbox_inches="tight")
print("wrote", os.path.abspath(out))

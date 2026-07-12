#!/usr/bin/env python3
"""Arrhenius temperature variant of the gross-CDR climate factor (sensitivity).

Cascade Climate's Weathering Potential Explorer uses an Arrhenius temperature
term with a silicate activation energy Ea = 68.8 kJ/mol; our erw-9 default uses a
linear clamp(MAT/T_ref). This builds the per-pixel multiplier that converts our
gross CDR to the Arrhenius basis:

    f_lin(T) = clamp(MAT / 11 C, 0.3, 3.0)
    f_arr(T) = clamp( exp(-Ea/R * (1/T - 1/T_ref)), 0.3, 3.0 )      (T in Kelvin)
    multiplier = f_arr / f_lin            -> data/cdr_climate_arrhenius_multiplier.tif

Feed the multiplier into the erw-11/erw-12 analytic sweep as `rmult` in cdr_net()
(rmult scales GROSS CDR), i.e. envelopes(P, rmult = arr_multiplier_resampled).
No pipeline re-run needed. To regenerate erw-9's base factor on the Arrhenius
basis instead, set CLIMATE_TEMP_MODE <- "arrhenius" in erw-9.

Result (area-weighted over SSA cropland): mean multiplier ~1.27 (capped) /
~1.74 (uncapped); in the illustrative uniform-20 all-cropland envelope this
raises public-viable area ~+54% (4.6 -> 7.1 Mha). Both are normalized to f=1 at
T_ref=11 C. The cap [0.3,3.0] matches the linear default; the uncapped Arrhenius
(full Cascade steepness) roughly doubles tropical gross CDR.
"""
import os, glob
import numpy as np, rasterio
from rasterio.warp import reproject, Resampling

ROOT = os.environ.get("ERW_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DATA = f"{ROOT}/data"
Tref_C, Ea, Rgas = 11.0, 68800.0, 8.314

# target = the sweep's economics grid (fallback to delivered-price grid)
tgt = f"{DATA}/economics_erw/targeted/MAIZ_equilibrium.tif"
if not os.path.exists(tgt):
    tgt = f"{DATA}/basalt_delivered_price_usd_t.tif"
with rasterio.open(tgt) as ds:
    TR, CRS, H, W = ds.transform, ds.crs, ds.height, ds.width

def to_grid(path, band=1, how=Resampling.bilinear):
    d = np.full((H, W), np.nan, "float32")
    with rasterio.open(path) as s:
        reproject(rasterio.band(s, band), d, src_transform=s.transform, src_crs=s.crs,
                  dst_transform=TR, dst_crs=CRS, resampling=how)
        if s.nodata is not None:
            d[d == s.nodata] = np.nan
    return d

# MAT = mean of 12 WorldClim tavg tiles
tavg = sorted(glob.glob(f"{DATA}/worldclim/climate/wc2.1_10m/wc2.1_10m_tavg_*.tif"))
acc = np.zeros((H, W)); cnt = np.zeros((H, W))
for f in tavg:
    d = to_grid(f); m = np.isfinite(d); acc[m] += d[m]; cnt[m] += 1
MAT = np.where(cnt > 0, acc / np.maximum(cnt, 1), np.nan).astype("float32")

f_lin = np.clip(MAT / Tref_C, 0.3, 3.0)
f_arr = np.clip(np.exp(-(Ea / Rgas) * (1.0 / (MAT + 273.15) - 1.0 / (Tref_C + 273.15))), 0.3, 3.0)
mult = np.where(np.isfinite(MAT), f_arr / np.maximum(f_lin, 1e-6), 1.0).astype("float32")

prof = dict(driver="GTiff", height=H, width=W, count=1, dtype="float32",
            crs=CRS, transform=TR, nodata=np.nan, compress="lzw")
out = f"{DATA}/cdr_climate_arrhenius_multiplier.tif"
with rasterio.open(out, "w", **prof) as dst:
    dst.write(np.nan_to_num(mult, nan=1.0), 1)
print("wrote", out, "| area-mean multiplier (unweighted):", round(float(np.nanmean(mult[np.isfinite(MAT)])), 3))

#!/usr/bin/env python3
"""Bake the envelope primitives into a single self-contained HTML explorer.

Regenerates paper/notebooks/public_envelope_explorer.html from
paper/analysis/explorer_template.html + the current economics_erw rasters.

    ERW_ROOT=$(pwd) python3 paper/analysis/build_explorer_html.py

Primitives are area-weight-aggregated by K=2 (for file size / speed) and each field
is quantised to uint16, then base64-embedded. Displayed areas track the canonical
erw-12 values to ~2-3%; the HTML says so and prints the fine-resolution public numbers.
"""
import sys, os, json, base64, numpy as np, rasterio
from rasterio.warp import reproject, Resampling
from rasterio.transform import array_bounds
from affine import Affine
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import erw_envelope_primitives as EP

TEMPLATE = open(os.path.join(HERE, "explorer_template.html")).read()
DATA = EP.DATA

K = 2                       # block-aggregation factor (area-weighted)
ALLOCS = ["targeted", "uniform_10", "uniform_20", "uniform_50"]
FIELDS = ["AGRO", "BAS", "GROSS", "LCA", "S", "TRANS", "WSUM"]

# ---- GADM level-0: country id per coarse cell + simplified boundary polylines ----
def country_id_coarse(k):
    """Nearest-resample data/country_id_grid.tif onto the K-aggregated grid."""
    with rasterio.open(f"{DATA}/economics_erw/targeted/MAIZ_equilibrium.tif") as ds:
        H, W, TR, CRS = ds.height, ds.width, ds.transform, ds.crs
    Hc, Wc = H // k, W // k
    ctr = Affine(TR.a*k, TR.b, TR.c, TR.d, TR.e*k, TR.f)   # same origin, k x cells
    dst = np.zeros((Hc, Wc), np.uint8)
    with rasterio.open(f"{DATA}/country_id_grid.tif") as s:
        reproject(rasterio.band(s, 1), dst, src_transform=s.transform, src_crs=s.crs,
                  dst_transform=ctr, dst_crs=CRS, resampling=Resampling.nearest)
    return dst   # 0 = no country

def load_codes():
    import csv
    rows = list(csv.DictReader(open(f"{DATA}/explorer_country_codes.csv")))
    return {int(r["code"]): {"iso3": r["iso3"], "name": r["name"]} for r in rows}

def pack_boundaries(extent):
    """Flatten GADM0 GeoJSON to polylines, quantise lon/lat to uint16 vs extent."""
    gj = json.load(open(f"{DATA}/explorer_gadm0.geojson"))
    xmin, xmax, ymin, ymax = extent
    polys = []
    for f in gj["features"]:
        g = f["geometry"]; t = g["type"]
        lines = g["coordinates"] if t == "MultiLineString" else [g["coordinates"]]
        for ln in lines:
            polys.append(ln)
    lens, coords = [], []
    for ln in polys:
        lens.append(len(ln))
        for x, y in ln:
            qx = min(65535, max(0, round((x - xmin) / (xmax - xmin) * 65535)))
            qy = min(65535, max(0, round((y - ymin) / (ymax - ymin) * 65535)))
            coords.append(qx); coords.append(qy)
    return np.array(lens, np.uint16), np.array(coords, np.uint16)

def agg(P, k):
    H, W = P["WSUM"].shape; Hc, Wc = H // k, W // k
    blk = lambda a: a[:Hc*k, :Wc*k].reshape(Hc, k, Wc, k)
    w = np.nan_to_num(blk(P["WSUM"])); wsum = w.sum(axis=(1, 3))
    ok = wsum > 0
    out = {"WSUM": np.where(ok, wsum, np.nan), "ok": ok, "H": Hc, "W": Wc}
    for key in ["AGRO", "BAS", "GROSS", "LCA", "S", "TRANS"]:
        num = (np.nan_to_num(blk(P[key])) * w).sum(axis=(1, 3))
        out[key] = np.where(ok, num / np.where(ok, wsum, 1), np.nan)
    out["F"] = P["F"]; out["extent"] = P["extent"]
    return out

CID = country_id_coarse(K)          # coarse-grid country id (Hc x Wc)
CODES = load_codes()

blob = bytearray(); meta = {"K": K, "F": None, "allocs": {}}
def align2():                       # keep uint16 views 2-byte aligned
    if len(blob) & 1: blob.append(0)
def w_u16(arr):
    align2(); off = len(blob); blob.extend(arr.astype(np.uint16).tobytes()); return off
def w_u8(arr):
    off = len(blob); blob.extend(arr.astype(np.uint8).tobytes()); return off

ref = None
for a in ALLOCS:
    P = agg(EP.build(a), K)
    if ref is None:
        ref = P; meta["H"] = P["H"]; meta["W"] = P["W"]
        meta["extent"] = [round(x, 4) for x in P["extent"]]; meta["F"] = round(P["F"], 6)
    rows, cols = np.where(P["ok"])
    n = rows.size
    entry = {"n": int(n), "fields": {}}
    entry["fields"]["col"] = {"off": w_u16(cols), "kind": "u16"}
    entry["fields"]["row"] = {"off": w_u16(rows), "kind": "u16"}
    # quantised primitives (uint16, per-field 0..max linear scale)
    for f in FIELDS:
        v = P[f][P["ok"]].astype(np.float64)
        vmax = float(np.nanmax(v)) if v.size else 1.0
        vmax = vmax if vmax > 0 else 1.0
        q = np.clip(np.round(v / vmax * 65535.0), 0, 65535)
        entry["fields"][f] = {"off": w_u16(q), "kind": "u16", "max": vmax}
    # country id per live cell (uint8) LAST, so it never misaligns the uint16 fields
    entry["fields"]["cid"] = {"off": w_u8(CID[rows, cols]), "kind": "u8"}
    base = EP.areas(P, EP.envelopes(P))
    entry["central_k"] = {k: round(v, 2) for k, v in base.items()}
    meta["allocs"][a] = entry

# boundaries (shared across allocations)
blens, bcoords = pack_boundaries(meta["extent"])
meta["bounds"] = {"n_poly": int(blens.size), "n_coord": int(bcoords.size)}
meta["bounds"]["lens_off"] = w_u16(blens)
meta["bounds"]["coords_off"] = w_u16(bcoords)
# country code table (index -> iso3, name)
meta["codes"] = {str(k): v for k, v in CODES.items()}

b64 = base64.b64encode(bytes(blob)).decode()
print(f"payload: {len(blob)/1e6:.2f} MB raw, {len(b64)/1e6:.2f} MB base64, "
      f"{sum(m['n'] for m in meta['allocs'].values())} live cells, "
      f"{meta['bounds']['n_poly']} boundary polylines")

# canonical (fine-resolution) numbers from erw-12, for the disclaimer line
CANON = {"targeted": "1.65", "uniform_10": "2.75", "uniform_20": "3.16", "uniform_50": "3.38"}
meta["canon_public"] = CANON

html = TEMPLATE.replace("__META__", json.dumps(meta, separators=(",", ":"))).replace("__DATA__", b64)
out = "paper/notebooks/public_envelope_explorer.html"
open(out, "w").write(html)
print("wrote", out, f"({os.path.getsize(out)/1e6:.2f} MB)")

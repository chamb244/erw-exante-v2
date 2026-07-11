#!/usr/bin/env python3
"""Bake the envelope primitives into a single self-contained HTML explorer.

Regenerates paper/notebooks/public_envelope_explorer.html from
paper/analysis/explorer_template.html + the current economics_erw rasters.

    ERW_ROOT=$(pwd) python3 paper/analysis/build_explorer_html.py

Primitives are area-weight-aggregated by K=2 (for file size / speed) and each field
is quantised to uint16, then base64-embedded. Displayed areas track the canonical
erw-12 values to ~2-3%; the HTML says so and prints the fine-resolution public numbers.
"""
import sys, os, json, base64, numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import erw_envelope_primitives as EP

TEMPLATE = open(os.path.join(HERE, "explorer_template.html")).read()

K = 2                       # block-aggregation factor (area-weighted)
ALLOCS = ["targeted", "uniform_10", "uniform_20", "uniform_50"]
FIELDS = ["AGRO", "BAS", "GROSS", "LCA", "S", "TRANS", "WSUM"]

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

blob = bytearray(); meta = {"K": K, "F": None, "allocs": {}}
ref = None
for a in ALLOCS:
    P = agg(EP.build(a), K)
    if ref is None:
        ref = P; meta["H"] = P["H"]; meta["W"] = P["W"]
        meta["extent"] = [round(x, 4) for x in P["extent"]]; meta["F"] = round(P["F"], 6)
    rows, cols = np.where(P["ok"])
    n = rows.size
    entry = {"n": int(n), "fields": {}}
    # positions
    for name, arr in (("col", cols.astype(np.uint16)), ("row", rows.astype(np.uint16))):
        entry["fields"][name] = {"off": len(blob), "kind": "u16"}
        blob += arr.tobytes()
    # quantised primitives (uint16, per-field 0..max linear scale)
    for f in FIELDS:
        v = P[f][P["ok"]].astype(np.float64)
        vmax = float(np.nanmax(v)) if v.size else 1.0
        vmax = vmax if vmax > 0 else 1.0
        q = np.clip(np.round(v / vmax * 65535.0), 0, 65535).astype(np.uint16)
        entry["fields"][f] = {"off": len(blob), "kind": "u16", "max": vmax}
        blob += q.tobytes()
    # reference (k=2) central areas, to show canonical vs displayed
    base = EP.areas(P, EP.envelopes(P))
    entry["central_k"] = {k: round(v, 2) for k, v in base.items()}
    meta["allocs"][a] = entry

b64 = base64.b64encode(bytes(blob)).decode()
print(f"payload: {len(blob)/1e6:.2f} MB raw, {len(b64)/1e6:.2f} MB base64, "
      f"{sum(m['n'] for m in meta['allocs'].values())} live cells")

# canonical (fine-resolution) numbers from erw-12, for the disclaimer line
CANON = {"targeted": "1.65", "uniform_10": "2.75", "uniform_20": "3.16", "uniform_50": "3.38"}
meta["canon_public"] = CANON

html = TEMPLATE.replace("__META__", json.dumps(meta, separators=(",", ":"))).replace("__DATA__", b64)
out = "paper/notebooks/public_envelope_explorer.html"
open(out, "w").write(html)
print("wrote", out, f"({os.path.getsize(out)/1e6:.2f} MB)")

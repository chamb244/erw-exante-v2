#!/usr/bin/env python3
"""
Separable per-pixel primitives for interactive public/private-envelope exploration.

Unlike erw_provisional_engine.build_primitives (which reads the already-deducted
net-CDR band 9), this keeps GROSS removal, the lifecycle term LCA, and the acidity
sink S as SEPARATE 2-D arrays, so the CDR-rate multiplier and the net-export
partition lambda can be applied in the physically correct order:

    cdr_net(r, lam) = max( max(r*GROSS - lam*F*S, 0) - LCA , 0 )

Mirrors erw/erw-12-public-envelope-sensitivity.R. Validated against it: the central
case (r=1, lam=1, $150, MRV $20) reproduces erw-12's public envelope to <0.01 Mha
(targeted 1.65, uniform_20 3.16). Arrays stay 2-D (H x W) so a typology raster can be
imshow-n directly; `extent` is returned for geographic axes.

Usage:
    import erw_envelope_primitives as P
    prim = P.build("targeted")            # equilibrium, net-export
    env  = P.envelopes(prim, carbon=150, mrv=20, cmult=1, rmult=1, lam=1, ymult=1)
    areas = P.areas(prim, env)            # dict of Mha per envelope
"""
import os, numpy as np, rasterio
from rasterio.warp import reproject, Resampling

ROOT = os.environ.get("ERW_ROOT",
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DATA = f"{ROOT}/data"

CROPS = ['MAIZ','SORG','BEAN','CHIC','LENT','WHEA','BARL','ACOF','RCOF','PMIL','SMIL',
 'POTA','SWPO','CASS','COWP','PIGE','SOYB','GROU','SUGC','COTT','COCO','TEAS','TOBA']
# band order in economics_erw/{alloc}/{crop}_{regime}.tif
B_HA, B_AGRO, B_BAS_THA, B_BAS, B_GROSS, B_GMC = 1, 5, 6, 7, 8, 11

def _fs(param):
    import csv
    for row in csv.DictReader(open(f"{DATA}/basalt_feedstock_chemistry.csv")):
        if row["parameter"] == param:
            return float(row["value"])
    raise KeyError(param)

F_REEXPORT = _fs("CDR_eff_kg_per_t_ref") / (_fs("effective_NV") * 1000.0)   # ~0.88
GRIND_KWH  = _fs("grinding_kWh_per_t")

def _to_grid(path, band, dst_transform, dst_crs, H, W, how=Resampling.average):
    """reproject one band of `path` onto the target grid."""
    dst = np.full((H, W), np.nan, np.float32)
    with rasterio.open(path) as s:
        reproject(rasterio.band(s, band), dst,
                  src_transform=s.transform, src_crs=s.crs,
                  dst_transform=dst_transform, dst_crs=dst_crs, resampling=how)
        if s.nodata is not None:
            dst[dst == s.nodata] = np.nan
    return dst

def build(alloc, regime="equilibrium"):
    """Area-weighted separable primitives for one allocation, kept 2-D."""
    ref = f"{DATA}/economics_erw/{alloc}/{CROPS[0]}_{regime}.tif"
    with rasterio.open(ref) as ds:
        H, W, TR, CRS = ds.height, ds.width, ds.transform, ds.crs
    b, l, r_, t = rasterio.transform.array_bounds(H, W, TR)
    extent = (b, r_, l, t)  # (xmin, xmax, ymin, ymax) for imshow origin='upper'
    xmin, ymax = TR.c, TR.f
    extent = (xmin, xmin + W*TR.a, ymax + H*TR.e, ymax)

    # LCA per tonne basalt (kg CO2/t): grinding + transport + spreading, as erw-7
    ci = _to_grid(f"{DATA}/grid_CI_kg_per_kWh.tif", 1, TR, CRS, H, W)
    km = _to_grid(f"{DATA}/basalt_transport_km.tif", 1, TR, CRS, H, W)
    lca_kg_per_t = GRIND_KWH*np.nan_to_num(ci) + np.nan_to_num(km)*0.12 + 0.5
    # transport-only $/t for the solar lever (optional)
    tpath = f"{DATA}/basalt_transport_cost_usd_t.tif"
    trans_t = _to_grid(tpath, 1, TR, CRS, H, W) if os.path.exists(tpath) else np.zeros((H, W))
    trans_t = np.nan_to_num(trans_t)
    # regime acidity sink (t CaCO3/ha)
    sink = "caco3_kamprath.tif" if regime in ("year1", "npv") else "caco3_merlos_maintenance.tif"
    S = np.nan_to_num(_to_grid(f"{DATA}/{sink}", 1, TR, CRS, H, W))

    z = np.zeros((H, W), np.float64)
    nA = z.copy(); nB = z.copy(); nG = z.copy(); nL = z.copy(); nT = z.copy(); w = z.copy()
    for c in CROPS:
        with rasterio.open(f"{DATA}/economics_erw/{alloc}/{c}_{regime}.tif") as ds:
            arr = ds.read([B_HA, B_AGRO, B_BAS_THA, B_BAS, B_GROSS, B_GMC]).astype(np.float64)
            nod = ds.nodata
        if nod is not None:
            arr = np.where(arr == nod, np.nan, arr)
        ha, agro, bt, bas, gross, gmc = arr
        d = np.isfinite(gmc) & np.isfinite(ha) & (ha > 0)
        ww = np.where(d, ha, 0.0)
        nz = np.nan_to_num
        nA += np.where(d, nz(agro)*ww, 0); nB += np.where(d, nz(bas)*ww, 0)
        nG += np.where(d, nz(gross)*ww, 0); nL += np.where(d, nz(bt)*lca_kg_per_t/1000.0*ww, 0)
        nT += np.where(d, nz(bt)*trans_t*ww, 0); w += ww
    ok = w > 0
    d = lambda num: np.where(ok, num/np.where(ok, w, 1), np.nan)
    return dict(AGRO=d(nA), BAS=d(nB), GROSS=d(nG), LCA=d(nL), TRANS=d(nT), S=np.where(ok, S, np.nan),
                WSUM=np.where(ok, w, np.nan), ok=ok, extent=extent, alloc=alloc, regime=regime,
                F=F_REEXPORT, H=H, W=W)

def cdr_net(P, rmult=1.0, lam=1.0):
    return np.fmax(np.fmax(rmult*P["GROSS"] - lam*P["F"]*P["S"], 0) - P["LCA"], 0)

def envelopes(P, carbon=150.0, mrv=20.0, cmult=1.0, rmult=1.0, lam=1.0, ymult=1.0, solar=0.0):
    """Boolean masks. `solar` in [0,1] cuts the transport term of delivered cost."""
    BAS = P["BAS"] - solar*P["TRANS"]
    cd  = cdr_net(P, rmult, lam)
    net = carbon - mrv
    priv = (P["AGRO"]*ymult - BAS*cmult) > 0
    publ = (cd*net          - BAS*cmult) > 0
    comb = (P["AGRO"]*ymult + cd*net - BAS*cmult) > 0
    return dict(private=priv, public=publ, intersection=priv & publ, combined=comb)

def areas(P, env):
    W = P["WSUM"]; ok = P["ok"]
    out = {}
    for k, m in env.items():
        out[k] = float(np.nansum(np.where(m & ok, W, 0)))/1e6
    return out

def typology(P, env):
    """5-way categorical raster: 1 both, 2 private-only, 3 public-only, 4 combined-only, 5 neither."""
    pr, pu, co, ok = env["private"], env["public"], env["combined"], P["ok"]
    t = np.full(P["WSUM"].shape, np.nan, np.float32)
    t[ok] = 5
    t[ok & co] = 4
    t[ok & pu & ~pr] = 3
    t[ok & pr & ~pu] = 2
    t[ok & pr & pu] = 1
    return t

if __name__ == "__main__":
    for a in ("targeted", "uniform_20"):
        P = build(a)
        e = envelopes(P)
        ar = areas(P, e)
        print(f"{a:11s} central: private {ar['private']:.2f}  public {ar['public']:.2f}  "
              f"intersection {ar['intersection']:.2f}  combined {ar['combined']:.2f} Mha")

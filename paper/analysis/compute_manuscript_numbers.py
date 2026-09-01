#!/usr/bin/env python3
"""All manuscript numbers for the 2026-09 re-run (Arrhenius + pH-6 basis)."""
import numpy as np, erw_envelope_primitives as P

def sums(prim, env, carbon=150., mrv=20., rmult=1., lam=1., ymult=1., cmult=1.):
    W, ok = prim["WSUM"], prim["ok"]
    cd = P.cdr_net(prim, rmult, lam)
    out = {}
    for k, m in env.items():
        mm = m & ok
        out[k] = dict(
            Mha   = np.nansum(np.where(mm, W, 0))/1e6,
            priv_M= np.nansum(np.where(mm, prim["AGRO"]*ymult*W, 0))/1e6,
            pub_M = np.nansum(np.where(mm, cd*(carbon-mrv)*W, 0))/1e6,
            cost_M= np.nansum(np.where(mm, prim["BAS"]*cmult*W, 0))/1e6,
            cdr_Mt= np.nansum(np.where(mm, cd*W, 0))/1e6)
    return out

def wmedian(vals, wts):
    i = np.argsort(vals); v, w = vals[i], wts[i]
    c = np.cumsum(w); return float(v[np.searchsorted(c, c[-1]/2)])

print("=== tab:envelopes (equilibrium, net-export, central) ===")
prims = {}
for a in ("targeted","uniform_10","uniform_20","uniform_50"):
    pr = P.build(a); prims[a] = pr
    e = P.envelopes(pr)
    s = sums(pr, e)
    for k in ("private","public","intersection","combined"):
        d = s[k]
        print(f"{a:11s} {k:12s} {d['Mha']:6.2f}  priv {d['priv_M']:7.0f}  pub {d['pub_M']:6.0f}  cost {d['cost_M']:6.0f}  cdr {d['cdr_Mt']:5.1f}")

print("\n=== typology decomposition (targeted) ===")
pr = prims["targeted"]; e = P.envelopes(pr); W, ok = pr["WSUM"], pr["ok"]
both = e["private"] & e["public"]; ponly = e["private"] & ~e["public"]
puonly = e["public"] & ~e["private"]; conly = e["combined"] & ~e["private"] & ~e["public"]
for n,m in [("both",both),("private-only",ponly),("public-only",puonly),("combined-only",conly)]:
    print(f"  {n:14s} {np.nansum(np.where(m&ok,W,0))/1e6:5.2f} Mha")
print(f"  treated total  {np.nansum(np.where(ok,W,0))/1e6:5.2f} Mha")

print("\n=== tab:regimes (targeted): public Mha + total credited CDR Mt ===")
for regime in ("npv","equilibrium"):
    pr2 = pr if regime=="equilibrium" else P.build("targeted","npv")
    for lam,name in ((0.0,"gross"),(1.0,"netexport")):
        e2 = P.envelopes(pr2, lam=lam)
        area = np.nansum(np.where(e2["public"]&pr2["ok"], pr2["WSUM"],0))/1e6
        tot  = np.nansum(np.where(pr2["ok"], P.cdr_net(pr2,1,lam)*pr2["WSUM"],0))/1e6
        print(f"  {regime:12s} {name:10s} public {area:5.2f} Mha   total CDR {tot:6.1f} Mt")

print("\n=== retention uniform_20 ===")
for regime in ("npv","equilibrium"):
    pu = P.build("uniform_20", regime) if regime=="npv" else prims["uniform_20"]
    g = np.nansum(np.where(pu["ok"], P.cdr_net(pu,1,0)*pu["WSUM"],0))/1e6
    n = np.nansum(np.where(pu["ok"], P.cdr_net(pu,1,1)*pu["WSUM"],0))/1e6
    print(f"  {regime}: gross {g:.1f} -> net {n:.1f} Mt ({100*n/g:.0f}%)")

print("\n=== scenario bundles (targeted, equilibrium) ===")
for nm,kw in [("Conservative",dict(carbon=100,mrv=40,cmult=1.5,rmult=0.5,ymult=0.75)),
              ("Central",{}),
              ("Optimistic",dict(carbon=250,mrv=10,cmult=0.75,rmult=1.5,ymult=1.5))]:
    e3 = P.envelopes(pr, **kw)
    a3 = P.areas(pr, e3)
    print(f"  {nm:12s} private {a3['private']:5.2f}  public {a3['public']:5.2f}  inter {a3['intersection']:5.2f}  combined {a3['combined']:5.2f}")

print("\n=== targeted price ladder ===")
Wt = np.nansum(np.where(pr["ok"], pr["WSUM"],0))/1e6
for p in (100,150,250,350,500):
    e4 = P.envelopes(pr, carbon=p)
    a = np.nansum(np.where(e4["public"]&pr["ok"], pr["WSUM"],0))/1e6
    c = np.nansum(np.where(e4["public"]&pr["ok"], P.cdr_net(pr)*pr["WSUM"],0))/1e6
    print(f"  ${p}: {a:5.2f} Mha ({100*a/Wt:4.1f}% of {Wt:.1f} Mha treated)  {c:5.1f} Mt")

print("\n=== MAC medians (area-weighted, over pixels with cdr_net>0) ===")
for tag, pp in [("targeted-eq", pr), ("uniform20-eq", prims["uniform_20"]),
                ("targeted-npv", P.build("targeted","npv"))]:
    cd = P.cdr_net(pp); m = pp["ok"] & (cd > 1e-9)
    mac = (pp["BAS"][m]/cd[m]); w = pp["WSUM"][m]
    print(f"  {tag}: median MAC ${wmedian(mac,w):.0f}/tCO2")

print("\n=== sink invariance ===")
for a in ("targeted","uniform_20"):
    pp = prims[a]; m = pp["ok"]
    sink = np.nansum(np.where(m, pp["F"]*pp["S"]*pp["WSUM"],0))/np.nansum(np.where(m,pp["WSUM"],0))
    print(f"  {a}: area-weighted F*S = {sink:.3f} tCO2/ha")

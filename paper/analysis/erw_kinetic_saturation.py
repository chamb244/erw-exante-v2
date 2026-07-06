#!/usr/bin/env python3
"""Refinement 2 -- kinetic / weathering saturation (sensitivity band).

Effective reacted tonnage saturates with applied dose: D_eff = D_max*D/(K_d+D).
Normalizing so low rates match the current (linear) calibration (D_max=K_d) gives a
multiplier on gross CDR of   sat(D) = K_d/(K_d + D),  D = basalt rate (t/ha).
K_d = half-saturation dose (uncalibrated -> report as a band).

We apply sat() to per-crop gross CDR, area-weight to the pixel, then apply the
net-export acidity-sink deduction (equilibrium). Shows CDR becoming concave in dose
-> an interior public-optimal rate. K_d in {inf (no sat), 60, 30, 15}."""
import numpy as np, pandas as pd, rasterio
from rasterio.warp import reproject, Resampling
import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
import os; ROOT=os.environ.get("ERW_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))); DATA=f"{ROOT}/data"; FIG=f"{ROOT}/paper/figures"; TBL=f"{ROOT}/paper/tables"
CARBON,MRV,F=150.0,20.0,0.88
CROPS=['MAIZ','SORG','BEAN','CHIC','LENT','WHEA','BARL','ACOF','RCOF','PMIL','SMIL','POTA','SWPO','CASS','COWP','PIGE','SOYB','GROU','SUGC','COTT','COCO','TEAS','TOBA']
KD={'no sat':1e9,'mild (K_d=60)':60.0,'central (K_d=30)':30.0,'strong (K_d=15)':15.0}
with rasterio.open(f"{DATA}/economics_erw/targeted/MAIZ_equilibrium.tif") as ds: TR,CRS,H,W=ds.transform,ds.crs,ds.height,ds.width
def grid(p,b,how=Resampling.average):
    d=np.full((H,W),np.nan,np.float32)
    with rasterio.open(p) as s:
        reproject(rasterio.band(s,b),d,src_transform=s.transform,src_crs=s.crs,dst_transform=TR,dst_crs=CRS,resampling=how)
        if s.nodata is not None: d[d==s.nodata]=np.nan
    return d
Smaint=np.nan_to_num(grid(f"{DATA}/caco3_merlos_maintenance.tif",1))
rows=[]
for alloc in ['targeted','uniform_10','uniform_20','uniform_50']:
    z=np.zeros((H,W)); ws=z.copy(); nbc=z.copy()
    ng={k:z.copy() for k in KD}   # area-weighted saturated gross CDR
    for c in CROPS:
        with rasterio.open(f"{DATA}/economics_erw/{alloc}/{c}_equilibrium.tif") as ds:
            ha,bt,bas,cdrg,gmc=ds.read([1,6,7,8,11]).astype(np.float32); nod=ds.nodata
        if nod is not None:
            for a in [ha,bt,bas,cdrg,gmc]: a[a==nod]=np.nan
        dfn=np.isfinite(gmc)&np.isfinite(ha)&(ha>0); w=np.where(dfn,ha,0.0)
        D=np.nan_to_num(bt); g=np.nan_to_num(cdrg)
        ws+=w; nbc+=np.where(dfn,np.nan_to_num(bas)*w,0)
        for k,kd in KD.items():
            # normalized to the reference dose (~50 t/ha, Lewis 2021): sat=1 at D=50,
            # per-tonne reactivity HIGHER below it, lower above it.
            ng[k]+=np.where(dfn, g*((kd+50.0)/(kd+D))*w, 0)
    ok=ws>0; wsm=np.where(ok,ws,1); BAS=np.where(ok,nbc/wsm,np.nan)
    for k,kd in KD.items():
        gross=np.where(ok,ng[k]/wsm,np.nan)                 # saturated gross CDR t/ha
        net=np.maximum(gross-F*Smaint,0)                    # net-export
        Rc=net*(CARBON-MRV); pub=((Rc-BAS)>0)&ok
        rows.append(dict(alloc=alloc,Kd=k,pub_Mha=round(float(np.nansum(np.where(pub,ws,0)))/1e6,2),
                         durCDR_Mt=round(float(np.nansum(np.where(pub,net*ws,0)))/1e6,1)))
df=pd.DataFrame(rows); df.to_csv(f"{TBL}/kinetic_saturation.csv",index=False)
print(df.pivot(index='alloc',columns='Kd',values='durCDR_Mt').reindex(['targeted','uniform_10','uniform_20','uniform_50'])[list(KD)].to_string())
# figure: durable CDR (Mt) and public area (Mha) vs rate, per K_d
allocs=['targeted','uniform_10','uniform_20','uniform_50']; labs=['targeted','10','20','50']; x=np.arange(4)
fig,(a1,a2)=plt.subplots(1,2,figsize=(12,4.5),dpi=140)
for k in KD:
    cd=[df[(df.alloc==a)&(df.Kd==k)]['durCDR_Mt'].iloc[0] for a in allocs]
    pa=[df[(df.alloc==a)&(df.Kd==k)]['pub_Mha'].iloc[0] for a in allocs]
    ls='--' if k=='no sat' else '-'
    a1.plot(x,cd,ls+'o',lw=2,label=k); a2.plot(x,pa,ls+'o',lw=2,label=k)
for a,t,y in [(a1,'(a) Durable public CDR vs dose','Durable net-export CDR (Mt)'),(a2,'(b) Public-sufficient area vs dose','Public envelope (Mha)')]:
    a.set_xticks(x); a.set_xticklabels(labs); a.set_xlabel('Application rate (t/ha; targeted = lime req.)'); a.set_ylabel(y); a.set_title(t); a.grid(alpha=0.3); a.legend(fontsize=8)
fig.suptitle('Kinetic saturation makes CDR concave in dose (equilibrium, net-export)',fontsize=12.5)
fig.tight_layout(); fig.savefig(f"{FIG}/kinetic_saturation.png",bbox_inches='tight'); print('saved kinetic_saturation.png')

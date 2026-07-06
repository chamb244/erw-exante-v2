#!/usr/bin/env python3
"""Pixel-specific OPTIMAL application-rate maps (private / public / combined).

Uses the two refinements so each objective is concave and has an interior optimum:
  C(D)      = D * c_t                                   (delivered cost, linear)
  R_agro(D) = R_agro_max * min(D/LR,1) * ypen(D)        (relief ramp x over-liming, R1)
  gross(D)  = D * d_t * (K_d+50)/(K_d+D)                (kinetic saturation, R2)
  R_c(D)    = max(gross(D) - F*S, 0) * (p - m)          (net-export durable CDR)
Optimal rate = argmax over D in [0,100] of each objective's per-ha gross margin.
Establishment (year-1) frame: one-time dose D, one-time cost, durable CDR net of
STANDING acidity. Central parameters (K_d=30, buffer k_beta=1); a sensitivity band
on these would widen the maps -- reported separately.
"""
import numpy as np, pandas as pd, rasterio
from rasterio.warp import reproject, Resampling
import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
import os; ROOT=os.environ.get("ERW_ROOT", os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))); DATA=f"{ROOT}/data"; FIG=f"{ROOT}/paper/figures"; TBL=f"{ROOT}/paper/tables"
CARBON,MRV,F=150.0,20.0,0.88; KD=30.0; KBETA=1.0; PH_NEUTRAL=6.5; REG="year1"
CROPS=['MAIZ','SORG','BEAN','CHIC','LENT','WHEA','BARL','ACOF','RCOF','PMIL','SMIL','POTA','SWPO','CASS','COWP','PIGE','SOYB','GROU','SUGC','COTT','COCO','TEAS','TOBA']
PH_OPT_MAX={'MAIZ':7.0,'SORG':7.5,'BEAN':7.0,'CHIC':8.0,'LENT':8.0,'WHEA':7.5,'BARL':7.8,'ACOF':6.5,'RCOF':6.5,'PMIL':7.5,'SMIL':7.5,'POTA':6.5,'SWPO':6.5,'CASS':7.0,'COWP':7.0,'PIGE':7.0,'SOYB':7.0,'GROU':7.0,'SUGC':7.5,'COTT':8.0,'COCO':7.0,'TEAS':5.5,'TOBA':6.5}
PH_ABS_MAX={'MAIZ':8.0,'SORG':8.5,'BEAN':8.0,'CHIC':9.0,'LENT':9.0,'WHEA':8.5,'BARL':8.5,'ACOF':7.0,'RCOF':7.0,'PMIL':8.0,'SMIL':8.0,'POTA':7.5,'SWPO':7.5,'CASS':8.0,'COWP':8.0,'PIGE':8.0,'SOYB':8.0,'GROU':7.5,'SUGC':8.5,'COTT':8.5,'COCO':7.5,'TEAS':6.5,'TOBA':7.5}
with rasterio.open(f"{DATA}/economics_erw/targeted/MAIZ_{REG}.tif") as ds:
    TR,CRS,H,W=ds.transform,ds.crs,ds.height,ds.width; EXT=[ds.bounds.left,ds.bounds.right,ds.bounds.bottom,ds.bounds.top]
def grid(p,b,how=Resampling.average):
    d=np.full((H,W),np.nan,np.float32)
    with rasterio.open(p) as s:
        reproject(rasterio.band(s,b),d,src_transform=s.transform,src_crs=s.crs,dst_transform=TR,dst_crs=CRS,resampling=how)
        if s.nodata is not None: d[d==s.nodata]=np.nan
    return d
pH0=grid(f"{DATA}/soilgrids_properties_cropland.tif",2,Resampling.bilinear); ECEC=np.nan_to_num(grid(f"{DATA}/soilgrids_properties_cropland.tif",9,Resampling.bilinear))
S=np.nan_to_num(grid(f"{DATA}/caco3_kamprath.tif",1)); beta=np.maximum(KBETA*ECEC,1.0)
# per-pixel primitives from targeted year-1 (area-weighted)
z=np.zeros((H,W)); scost=z.copy();scdr=z.copy();stha=z.copy();sagro=z.copy();slr=z.copy();sph=z.copy();sphm=z.copy();ws=z.copy()
for c in CROPS:
    with rasterio.open(f"{DATA}/economics_erw/targeted/{c}_{REG}.tif") as ds:
        ha,agro,bt,bas,cdrg,gmc=ds.read([1,5,6,7,8,11]).astype(np.float32); nod=ds.nodata
    if nod is not None:
        for a in [ha,agro,bt,bas,cdrg,gmc]: a[a==nod]=np.nan
    dfn=np.isfinite(gmc)&np.isfinite(ha)&(ha>0); w=np.where(dfn,ha,0.0)
    scost+=np.where(dfn,np.nan_to_num(bas),0); scdr+=np.where(dfn,np.nan_to_num(cdrg),0); stha+=np.where(dfn,np.nan_to_num(bt),0)
    sagro+=np.where(dfn,np.nan_to_num(agro)*w,0); slr+=np.where(dfn,np.nan_to_num(bt)*w,0)
    sph+=PH_OPT_MAX[c]*w; sphm+=PH_ABS_MAX[c]*w; ws+=w
ok=ws>0; wsm=np.where(ok,ws,1); tha=np.where(stha>0,stha,np.nan)
c_t=np.where(stha>0,scost/tha,np.nan); d_t=np.where(stha>0,scdr/tha,np.nan)     # per-tonne cost, gross CDR
Ragro_max=np.where(ok,sagro/wsm,np.nan); LR=np.maximum(np.where(ok,slr/wsm,np.nan),0.1)
PHO=np.where(ok,sph/wsm,7.0); PHM=np.where(ok,sphm/wsm,8.0)
def final_pH(A):
    acid=pH0<PH_NEUTRAL; ph=np.where(np.isfinite(pH0),pH0,6.0).astype(np.float32)
    frac=np.clip(np.where(S>0.1,A/np.maximum(S,0.1),10.0),0,1); pa=ph+frac*(PH_NEUTRAL-ph)
    pa=np.where(A>S,PH_NEUTRAL+np.maximum(A-S,0)/beta,pa); pn=ph+A/beta
    return np.clip(np.where(acid,pa,pn),ph,8.5)
def ypen(A):
    fp=final_pH(A); return np.where(fp<=PHO,1.0,np.maximum(1-((fp-PHO)/np.maximum(PHM-PHO,0.1))**2,0))
# optimize over D grid
grid_D=np.arange(0,100.01,2.5)
best={'priv':(z.copy(),z.copy()-1e9),'pub':(z.copy(),z.copy()-1e9),'comb':(z.copy(),z.copy()-1e9)}
for D in grid_D:
    gross=D*d_t*((KD+50.0)/(KD+D)); A=gross/F
    Ra=Ragro_max*np.minimum(D/LR,1.0)*ypen(A)
    Rc=np.maximum(gross-F*S,0)*(CARBON-MRV); Cc=D*c_t
    obj={'priv':Ra-Cc,'pub':Rc-Cc,'comb':Ra+Rc-Cc}
    for k in best:
        Dopt,vbest=best[k]; better=np.isfinite(obj[k])&(obj[k]>vbest)
        best[k]=(np.where(better,D,Dopt),np.where(better,obj[k],vbest))
# deployable mask: combined optimum GM > 0
dep=(best['comb'][1]>0)&ok
def savemap(arr,title,fn,mask):
    a=np.where(mask,arr,np.nan)
    f,ax=plt.subplots(figsize=(6.6,6),dpi=140); im=ax.imshow(a,extent=EXT,origin='upper',cmap='viridis',vmin=0,vmax=40,interpolation='nearest')
    ax.set_title(title,fontsize=11); ax.set_xticks([]); ax.set_yticks([]); cb=f.colorbar(im,ax=ax,shrink=0.7); cb.set_label('optimal rate (t/ha)',fontsize=9)
    f.tight_layout(); f.savefig(f"{FIG}/{fn}",bbox_inches='tight'); plt.close(f)
savemap(best['priv'][0],'(a) Private-optimal rate','optrate_private.png',dep)
savemap(best['pub'][0],'(b) Public-optimal rate','optrate_public.png',dep)
savemap(best['comb'][0],'(c) Combined-optimal rate','optrate_combined.png',dep)
# combined 3-panel
f,axs=plt.subplots(1,3,figsize=(15,5),dpi=135)
for ax,arr,t in zip(axs,[best['priv'][0],best['pub'][0],best['comb'][0]],['(a) Private-optimal','(b) Public-optimal','(c) Combined-optimal']):
    im=ax.imshow(np.where(dep,arr,np.nan),extent=EXT,origin='upper',cmap='viridis',vmin=0,vmax=40,interpolation='nearest'); ax.set_title(t); ax.set_xticks([]); ax.set_yticks([])
f.colorbar(im,ax=axs,shrink=0.6,label='optimal application rate (t/ha)')
f.suptitle('Pixel-specific optimal ERW application rate by objective (central refinements)',fontsize=13)
f.savefig(f"{FIG}/optrate_panel.png",bbox_inches='tight'); plt.close(f)
def med(a): v=a[dep&np.isfinite(a)]; return round(float(np.median(v)),1) if v.size else np.nan
print("deployable pixels (Mha-ish, unweighted count):",int(dep.sum()))
print("median optimal rate (t/ha) -- private:",med(best['priv'][0])," public:",med(best['pub'][0])," combined:",med(best['comb'][0]))
for k,lab in [('priv','private'),('pub','public'),('comb','combined')]:
    a=best[k][0][dep]; print(f"  {lab}: p25/50/75 =",[round(float(np.percentile(a,q)),1) for q in (25,50,75)])
print("saved optrate maps")

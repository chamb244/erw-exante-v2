#!/usr/bin/env python3
import json, os, subprocess, urllib.request, time

refs = json.load(open('ref-verification.json'))
UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36'

def curl(url, dest):
    subprocess.run(['curl','-sL','--compressed','--max-time','90','-A',UA,'-o',dest,url], capture_output=True)
    if os.path.exists(dest):
        with open(dest,'rb') as f: magic = f.read(5)
        if magic == b'%PDF-' and os.path.getsize(dest) > 10000:
            return os.path.getsize(dest)
        os.remove(dest)
    return None

def jget(url):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': UA})
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.load(r)
    except Exception:
        return None

def s2_pdf(doi):
    j = jget(f'https://api.semanticscholar.org/graph/v1/paper/DOI:{doi}?fields=openAccessPdf')
    if j and j.get('openAccessPdf'):
        return j['openAccessPdf'].get('url')
    return None

def epmc_pdf(doi):
    j = jget(f'https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=DOI:%22{doi}%22&format=json')
    if not j: return None
    for hit in j.get('resultList',{}).get('result',[]):
        pmcid = hit.get('pmcid')
        if pmcid:
            return f'https://www.ebi.ac.uk/europepmc/webservices/rest/{pmcid}/fullTextPDF'
    return None

ok, miss = [], []
for e in refs:
    if e.get('status') != 'ok': continue
    dest = f"papers/{e['ref']:03d}_{e['slug']}.pdf"
    if os.path.exists(dest): continue
    urls = []
    u = s2_pdf(e['doi']);  time.sleep(1.1)
    if u: urls.append(u)
    u = epmc_pdf(e['doi']); time.sleep(0.3)
    if u: urls.append(u)
    got = None
    for u in urls:
        got = curl(u, dest)
        if got: break
    (ok if got else miss).append((e['ref'], e['slug']))
    time.sleep(0.3)

print('newly downloaded:', len(ok))
for r in ok: print('  OK', *r)
print('still missing:', len(miss))
for r in miss: print('  MISS', *r)

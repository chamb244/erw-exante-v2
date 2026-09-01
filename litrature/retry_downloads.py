#!/usr/bin/env python3
import json, os, subprocess, urllib.request, re, time

refs = json.load(open('ref-verification.json'))
UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36'

def curl(url, dest):
    r = subprocess.run(['curl','-sL','--compressed','--max-time','90','-A',UA,'-o',dest,url], capture_output=True)
    if os.path.exists(dest):
        with open(dest,'rb') as f: magic = f.read(5)
        if magic == b'%PDF-' and os.path.getsize(dest) > 10000:
            return os.path.getsize(dest)
        os.remove(dest)
    return None

def publisher_urls(doi, oa_page):
    urls = []
    d = doi.lower()
    if d.startswith('10.1038/'):  # nature portfolio OA
        art = d.split('/',1)[1]
        urls.append(f'https://www.nature.com/articles/{art}.pdf')
    if d.startswith('10.1088/'):  # IOP
        urls.append(f'https://iopscience.iop.org/article/{doi}/pdf')
    if d.startswith('10.3389/'):  # frontiers
        urls.append(f'https://www.frontiersin.org/articles/{doi}/pdf')
        urls.append(f'https://www.frontiersin.org/journals/climate/articles/{doi}/pdf')
    if d.startswith('10.5194/'):  # copernicus e.g. gmd-15-4959-2022
        m = re.match(r'10\.5194/(\w+)-(\d+)-(\d+)-(\d+)', d)
        if m:
            j, vol, page, yr = m.groups()
            urls.append(f'https://{j}.copernicus.org/articles/{vol}/{page}/{yr}/{j}-{vol}-{page}-{yr}.pdf')
    if d.startswith('10.1111/') or d.startswith('10.1029/') or d.startswith('10.1002/'):  # wiley/agu
        urls.append(f'https://onlinelibrary.wiley.com/doi/pdfdirect/{doi}')
        urls.append(f'https://agupubs.onlinelibrary.wiley.com/doi/pdfdirect/{doi}')
    if d.startswith('10.1016/'):  # elsevier OA
        urls.append(f'https://www.sciencedirect.com/science/article/pii/{d}')  # rarely works; placeholder
    if d.startswith('10.1039/'):  # RSC
        urls.append(f'https://pubs.rsc.org/en/content/articlepdf/2022/ee/{d.split("/")[-1]}')
    if oa_page:
        urls.append(oa_page)
    return urls

def openalex_urls(doi):
    try:
        req = urllib.request.Request(f'https://api.openalex.org/works/doi:{doi}', headers={'User-Agent':'erw/1.0'})
        with urllib.request.urlopen(req, timeout=30) as r:
            w = json.load(r)
        urls = []
        best = w.get('best_oa_location') or {}
        if best.get('pdf_url'): urls.append(best['pdf_url'])
        for loc in w.get('locations', []):
            u = loc.get('pdf_url')
            if u and u not in urls: urls.append(u)
        return urls
    except Exception:
        return []

ok, fail = [], []
for e in refs:
    if e.get('status') != 'ok': continue
    dest = f"papers/{e['ref']:03d}_{e['slug']}.pdf"
    if os.path.exists(dest): continue
    urls = openalex_urls(e['doi']) + publisher_urls(e['doi'], e.get('oa_page'))
    got = None
    for u in urls:
        got = curl(u, dest)
        if got: break
        time.sleep(0.3)
    (ok if got else fail).append((e['ref'], e['slug'], f'{(got or 0)//1024} KB'))
    time.sleep(0.4)

print('newly downloaded:', len(ok))
for r in ok: print('  OK', *r)
print('still missing:', len(fail))
for r in fail: print('  MISS', r[0], r[1])

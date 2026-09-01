#!/usr/bin/env python3
import json, os, re, subprocess, time, urllib.parse

UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36'

CANDIDATES = {
 18: ['https://orca.cardiff.ac.uk/id/eprint/60892/1/Renforth%25202012%2520-%2520IJGGC.pdf',
      'https://orca.cardiff.ac.uk/id/eprint/60892/'],
 37: ['https://orca.cardiff.ac.uk/id/eprint/102182/1/2016RG000533.pdf',
      'https://orca.cardiff.ac.uk/id/eprint/102182/'],
 164:['https://researchonline.jcu.edu.au/13470/1/13470_Gillman_et_al_2002.pdf'],
 47: ['https://pub.h-brs.de/files/5966/S004896972106054X.pdf'],
 408:['http://oceanrep.geomar.de/48798/1/Moosdorf.pdf',
      'https://orca.cardiff.ac.uk/id/eprint/60901/1/Carbon%20dioxide%20efficiency%20of%20terrestrial%20enhanced%20weathering.pdf'],
 75: ['https://hal.science/hal-03401843/document'],
 286:['https://hal.science/hal-04548370/document'],
 132:['https://www.research-collection.ethz.ch/handle/20.500.11850/787844'],
 372:['https://spiral.imperial.ac.uk/handle/10044/1/101125'],
 354:['https://deepblue.lib.umich.edu/handle/2027.42/95356'],
 357:['https://scholarsphere.psu.edu/resources/baebe1e7-6b54-4048-92d3-8f840670e394'],
 209:['https://dspace.lib.cranfield.ac.uk/handle/1826/14277'],
 65: ['https://ora.ox.ac.uk/objects/uuid:36f6c26c-d673-460f-83ac-73e06a3d5cda'],
}

refs = {e['ref']: e for e in json.load(open('ref-verification.json')) if e.get('status')=='ok'}

def curl_bin(url, dest):
    subprocess.run(['curl','-sL','--compressed','--max-time','90','-A',UA,'-o',dest,url], capture_output=True)
    if os.path.exists(dest):
        with open(dest,'rb') as f: magic = f.read(5)
        if magic == b'%PDF-' and os.path.getsize(dest) > 10000:
            return os.path.getsize(dest)
        os.remove(dest)
    return None

def curl_html(url):
    r = subprocess.run(['curl','-sL','--compressed','--max-time','60','-A',UA,url], capture_output=True)
    return r.stdout.decode('utf-8','ignore')

ok, miss = [], []
for num, urls in CANDIDATES.items():
    e = refs[num]
    dest = f"papers/{num:03d}_{e['slug']}.pdf"
    if os.path.exists(dest): continue
    got = None
    for u in urls:
        if got: break
        if '.pdf' in u.lower() or u.endswith('/document'):
            got = curl_bin(u, dest)
            if got: break
        # scrape landing page for pdf links
        html = curl_html(u)
        links = re.findall(r'href=["\']([^"\']+\.pdf[^"\']*)["\']', html, re.I)
        links += re.findall(r'content=["\']([^"\']+\.pdf[^"\']*)["\']', html, re.I)  # citation_pdf_url meta
        seen = []
        for l in links[:6]:
            full = urllib.parse.urljoin(u, l)
            if full in seen: continue
            seen.append(full)
            got = curl_bin(full, dest)
            if got: break
        time.sleep(0.4)
    (ok if got else miss).append((num, e['slug'], f'{(got or 0)//1024} KB'))

print('newly downloaded:', len(ok))
for r in ok: print('  OK', *r)
print('still missing from this pass:', len(miss))
for r in miss: print('  MISS', r[0], r[1])

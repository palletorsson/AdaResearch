from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin,urlsplit,unquote
import hashlib,json,urllib.request
r=Path.cwd();o=Path(__file__).resolve().parent;rel=o.relative_to(r).as_posix();url='http://localhost:3003/book-review/'+rel+'/index.html'
class Links(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.ids=[]
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if 'id' in a:self.ids.append(a['id'])
  for k in ['href','src']:
   if k in a:self.links.append(a[k])
p=Links();p.feed((o/'index.html').read_text());results=[]
assert len(p.ids)==len(set(p.ids))
for link in dict.fromkeys(p.links):
 if link.startswith('#'):assert link[1:] in p.ids;continue
 target=urljoin(url,link)
 if urlsplit(target).hostname!='localhost':continue
 with urllib.request.urlopen(target,timeout=20) as response:
  body=response.read();assert response.status==200;results.append({'url':target,'status':response.status,'bytes':len(body)})
 path=unquote(urlsplit(target).path)
 if path.startswith('/book-review/'):
  source=r/path.removeprefix('/book-review/');assert source.read_bytes()==body
with urllib.request.urlopen(url,timeout=20) as response:assert response.read()==(o/'index.html').read_bytes()
for m in ['CA_ExpandingSpace','CA_SoftRules']:
 for name in ['before','after']:
  assert (o/(m+'-'+name+'.md')).exists()
 assert (o/(m+'-after.md')).read_bytes()==(r/'commons/maps'/m/'final.md').read_bytes()
v=json.loads((o/'verification.json').read_text());q=json.loads((o/'queue-verification.json').read_text())
assert all(c['passed'] for c in v['checks']);assert q['counts']=={'done':24,'open':9},q
(o/'http-checks.json').write_bytes((json.dumps({'checks':results,'internal_anchors_valid':True,'served_review_matches_file':True,'chapter_copies_current':True},indent=2)+'\n').encode())
working=r/'doc/book/iterations/WORKING.md';current=working.read_text(encoding='utf-8')
entry='''## 25 September 2026 — CA body and exchange review comments

Review: `2026-09-25-ca-body-and-exchange-review/index.html`.

- CA_ExpandingSpace: one SOURCE press before RUN; upright, dark, larger basin/W directions; RIGHT / DESK SIDE matches the recovery route. Frieze backing now has fixed physical collision while its shared colour panels remain visual. Chapter notices that the wall stays when the tile loses support.
- CA_SoftRules: W correctly located as a small gold frame on either table, read at the side desk. Replaced the misleading one-bit comparison after the graded bridge with the actual two-concentration difference. Existing body-seeding paragraphs, clockmaker, all code and notes retained.
- Four queue comments resolved (.008/.011/.021/.022); .023 remains open for headset label readability despite verified native reveal; .024 stays open for Quest profiling. Queue now 24 done / 9 open. Original feedback and notes retained.
- 36 final native assertions (21 bridge, 15 exchange), 14 baseline checks, 60 preservation checks. Original interior PNGs, exact text/source diffs, source hashes and HTTP checks published. Body stops at the fixed frieze; no tracked headset/Quest/full-gallery claim. Existing engine warnings retained; no script/shader errors, exit zero.
- Canonical final.md and eight-hall capture refreshed. Map layouts, roles, solvers, seed receiver, ramps and live plan/bake unchanged. Earlier immersion evidence linked with its limits. No commit. Next: Agents/Circuits and Edge of Chaos; preserve concurrent immersion work.

'''
assert '## 25 September 2026 — CA body and exchange review comments' not in current
working.write_bytes((entry+current).encode('utf-8'))
print(json.dumps({'http_links':len(results),'queue':q['counts'],'review':url},indent=2))

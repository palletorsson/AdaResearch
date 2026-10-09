from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin, urlsplit, unquote
import hashlib, json, urllib.request
r=Path.cwd();rel='doc/book/iterations/2026-09-25-noise-ending-review';o=r/rel
base='http://localhost:3003/book-review/'+rel+'/index.html'
class Links(HTMLParser):
    def __init__(self):super().__init__();self.ids=[];self.urls=[]
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if 'id' in a:self.ids.append(a['id'])
        for k in ['href','src']:
            if a.get(k):self.urls.append(a[k])
p=Links();p.feed((o/'index.html').read_text())
checks=[]
def check(name,passed):checks.append({'name':name,'passed':bool(passed)});assert passed,name
check('unique chapter and footnote anchors',len(p.ids)==len(set(p.ids)))
seen=set()
for link in p.urls:
    if link.startswith('#'):check('anchor '+link,link[1:] in p.ids);continue
    url=urljoin(base,link);parts=urlsplit(url)
    if parts.netloc!='localhost:3003' or url in seen:continue
    seen.add(url)
    with urllib.request.urlopen(url,timeout=30) as response:
        body=response.read();check('HTTP '+link,response.status==200 and bool(body))
    if parts.path.startswith('/book-review/'):
        local=r/unquote(parts.path.removeprefix('/book-review/'))
        if local.is_file():check('HTTP bytes match '+link,hashlib.sha256(body).hexdigest()==hashlib.sha256(local.read_bytes()).hexdigest())
with urllib.request.urlopen(base,timeout=30) as response:check('published page served unchanged',response.read()==(o/'index.html').read_bytes())
q=json.loads((r/'doc/tasks/book_noise.json').read_text(encoding='utf-8-sig'))
check('nineteen Noise comments done',sum(t['status']=='done' for t in q['tasks'])==19)
check('one Noise comment remains open',sum(t['status']=='open' for t in q['tasks'])==1)
check('headset request still open',next(t for t in q['tasks'] if t['id']=='book_noise.020')['status']=='open')
(o/'http-verification.json').write_bytes((json.dumps({'passed':True,'checks':checks},indent=2)+'\n').encode())

entry="""**25 September — Noise ending review comments.** [Ending, exact comparisons and new museum interior photographs](2026-09-25-noise-ending-review/index.html). Keep the mature Perlin/Simplex chapter, four code excerpts, paired arches and blob-culture ending. Clarify VIEW versus REGEN; move engine documentation into a sourced footnote. Fix Simplex apply_grid_config so readout-only changes preserve the regenerated field. 29 native assertions pass: seed, 49 values, generator properties, colours, returning heights, explicit seed/config-before-ready, shared VIEW/MATCH and arches. Exit 0, no script/shader errors. Lab_Path remains an optional grid-lane return: add H1 and optional subtitle, retain geometry and drop flag, fold its two-tellings/hold-a-seed invitation into the main ending, remove the duplicate CA handover and align three companion summaries. Repair Noise sequence encoding, current titles and descriptions; distinguish spatial coherence from stored state. Map order, unlocks, roles, artifact lists and live route retained. 59 preservation checks pass; current nine-hall capture refreshed. Eight comments resolved, queue 19 done / 1 open; the requested other-approach headset walk stays open and unchanged. Original feedback retained. No commit. Next: Cellular Automata review comments; start from current encounters, preserve a concrete poetic investigative voice, inspect companion texts and bring in relevant existing artifacts where needed.

"""
p=r/'doc/book/iterations/WORKING.md';s=p.read_text(encoding='utf-8-sig');assert 'Noise ending review comments.' not in s
if s.startswith('#'):
    first,rest=s.split('\n',1);s=first+'\n\n'+entry+rest.lstrip('\n')
else:s=entry+s
p.write_bytes(s.encode('utf-8'))
print(f'{len(checks)} link/HTTP/queue checks pass; continuation note added.')

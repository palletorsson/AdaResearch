from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin, urlsplit, unquote
import hashlib, json, urllib.request
r=Path.cwd();rel='doc/book/iterations/2026-09-25-ca-opening-review';o=r/rel
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
q=json.loads((r/'doc/tasks/book_cellularautomata.json').read_text(encoding='utf-8-sig'))
check('twenty CA comments done',sum(t['status']=='done' for t in q['tasks'])==20)
check('thirteen CA comments remain open',sum(t['status']=='open' for t in q['tasks'])==13)
check('headset request still open',next(t for t in q['tasks'] if t['id']=='book_cellularautomata.016')['status']=='open')
(o/'http-verification.json').write_bytes((json.dumps({'passed':True,'checks':checks},indent=2)+'\n').encode())


entry="""**25 September — CA opening review comments.** [Text comparisons, names and native museum photographs](2026-09-25-ca-opening-review/index.html). Introduction reaches the board sooner, locates CA RULES/90/30, spells out 100 versus 010 and puts all eight Rule 90 answers in the existing footnote. Agents/Circuits receives the same one-sentence 90/RST orientation. The current ring and arrival-history passages remain; moving ants are agents, and the close no longer says every later hall changes the rule. History replaces the repeated index lesson with a back-reference and acknowledges the rear gallery. Lab universality assertion replaced by WHAT COUNTS AS COMPUTATION?; side annotations disabled. Sign moved to rear window and lowered .55 m after native captures exposed apparatus and exit-light occlusion. Optional shared sign-height offset defaults to zero. Runner had no museum GridMultiMesh target or geometry: only that placement removed, source/registry retained; stand remains secondary. Three pearl/hall titles match their chapters without ID/order/route changes. Elementary/Beyond manuscripts unchanged; critical essays and all code excerpts/anchors preserved. Final native runs 13+14 assertions pass, exit 0, no script/shader errors; 134 preservation checks. Current eight-hall capture refreshed, exact diffs and intermediate captures retained. Nine comments resolved; CA queue 20 done / 13 open. Headset/performance work remains open. No commit. Next: CA_ExpandingSpace and CA_SoftRules review comments; inspect newer immersive work and preserve concurrent edits.

"""
p=r/'doc/book/iterations/WORKING.md';s=p.read_text(encoding='utf-8-sig');assert 'CA opening review comments.' not in s
if s.startswith('#'):
    first,rest=s.split('\n',1);s=first+'\n\n'+entry+rest.lstrip('\n')
else:s=entry+s
p.write_bytes(s.encode('utf-8'))
print(f'{len(checks)} link/HTTP/queue checks pass; continuation note added.')

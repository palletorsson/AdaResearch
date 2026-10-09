from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin, urlsplit, unquote
import hashlib, json, urllib.request

r=Path.cwd(); rel='doc/book/iterations/2026-09-25-noise-opening-review'; o=r/rel
base='http://localhost:3003/book-review/'+rel+'/index.html'
class Links(HTMLParser):
    def __init__(self):super().__init__();self.ids=[];self.urls=[]
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if 'id' in a:self.ids.append(a['id'])
        for k in ['href','src']:
            if a.get(k):self.urls.append(a[k])
p=Links();page=(o/'index.html').read_text();p.feed(page)
checks=[]
def check(name,passed):
    checks.append({'name':name,'passed':bool(passed)});assert passed,name
check('unique reading and footnote anchors',len(p.ids)==len(set(p.ids)))
seen=set()
for link in p.urls:
    if link.startswith('#'):
        check('internal anchor: '+link,link[1:] in p.ids);continue
    url=urljoin(base,link);parts=urlsplit(url)
    if parts.netloc!='localhost:3003' or url in seen:continue
    seen.add(url)
    with urllib.request.urlopen(url,timeout=30) as response:
        body=response.read();check('HTTP: '+link,response.status==200 and bool(body))
    if parts.path.startswith('/book-review/'):
        local=r/unquote(parts.path.removeprefix('/book-review/'))
        if local.is_file():check('HTTP bytes match source: '+link,hashlib.sha256(body).hexdigest()==hashlib.sha256(local.read_bytes()).hexdigest())
with urllib.request.urlopen(base,timeout=30) as response:check('review page served unchanged',response.read()==(o/'index.html').read_bytes())
q=json.loads((r/'doc/tasks/book_noise.json').read_text(encoding='utf-8-sig'))
check('seven Noise tasks resolved',sum(t['status']=='done' for t in q['tasks'])==7)
check('thirteen later Noise tasks remain open',sum(t['status']=='open' for t in q['tasks'])==13)
write=lambda path,obj:path.write_bytes((json.dumps(obj,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
write(o/'http-verification.json',{'passed':True,'checks':checks})

entry='''**25 September — Noise opening review comments.** [Four current chapters, exact diffs and native museum photographs](2026-09-25-noise-opening-review/index.html). Random Noise Types gains one paragraph break; Noise Columns gives the plaque’s 35% its actual image-comparison referent and a metric footnote; Noise One locates the basin at the room’s centre; Noise Voxel locates the piece count at the bench and removes “desktop” from its dated computation footnote. All source excerpts, artifact anchors, companion manuscripts, roles and existing geometry are retained. The ring supports and voxel orientation were already repaired by recent work; source hashes and fresh native checks confirm them. The Noise Voxel bench alone gains keyboard:off: arrow/R/N keys no longer change its field while walking; the four console button signals still act, standalone shortcuts remain, and the 28 m flight enclosure survives updates. 38 native assertions pass across two halls, both final processes exit 0, no GDScript errors; existing engine warnings and the initial 25-vs-25.0 test assumption are archived. 78 preservation/publication checks pass. Seven review items closed with original comments preserved; Noise now 7 done / 13 open. Current nine-hall capture refreshed and only four shared core references updated. Controlled inputs/cameras, not headset/Quest/flight traversal/learner acceptance. No commit. Next review targets: Noise 6 Wall, Inside Noise and Space 10; preserve their newer immersive work.\n\n'''
p=r/'doc/book/iterations/WORKING.md';s=p.read_text(encoding='utf-8-sig')
assert 'Noise opening review comments.' not in s
if s.startswith('#'):
    first,rest=s.split('\n',1);s=first+'\n\n'+entry+rest.lstrip('\n')
else:s=entry+s
p.write_bytes(s.encode('utf-8'))
print(f'{len(checks)} HTTP/anchor checks pass; shared continuation note added.')

from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin, urlsplit, unquote
import hashlib, json, urllib.request
r=Path.cwd();rel='doc/book/iterations/2026-09-25-noise-surface-and-body';o=r/rel
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
check('eleven Noise comments done',sum(t['status']=='done' for t in q['tasks'])==11)
check('nine Noise comments remain open',sum(t['status']=='open' for t in q['tasks'])==9)
check('headset request still open',next(t for t in q['tasks'] if t['id']=='book_noise.020')['status']=='open')
(o/'http-verification.json').write_bytes((json.dumps({'passed':True,'checks':checks},indent=2)+'\n').encode())
entry='''**25 September — Noise surface and body review comments.** [Three chapters, exact text comparisons and native interior photographs](2026-09-25-noise-surface-and-body/index.html). Noise 6 Wall removes one untraceable half-white statistic while retaining the gain/clamp argument and changes “the player” to direct address. Space 10 moves desktop wording out of the walk paragraph, retains dated provenance in the footnote and uses “your body” for occupied-terrain protection. Five sentence edits in two final.md files; Inside Noise retained byte for byte. The full-size sphere, wall finish, pink walking trace and miniature return remain intact. Fresh native sphere check: host/study/shell global scale 1, base radius 5 m, floor support, six doorway rays and RELIEF/SKIN return; 20 assertions pass, exit 0, no GDScript errors. Initial rays reached the outer hall wall at local -5.5 m; diagnostic retained, final rays end beyond the shell but before the outer wall. This is doorway clearance, not a new body route or comfort claim. Existing wall and miniature evidence reused with matching implementation hashes; all artifact code, placements, companion texts and roles preserved. 88 preservation checks pass, current nine-hall capture refreshed. Four comments closed; requested other-approach headset walk remains open with a note. Queue 11 done / 9 open, original feedback preserved. No commit. Next: Perlin/Simplex and the sequence/coda metadata; keep the new arches and the critique of the noise/blob shortcut.\n\n'''
p=r/'doc/book/iterations/WORKING.md';s=p.read_text(encoding='utf-8-sig');assert 'Noise surface and body review comments.' not in s
if s.startswith('#'):
    first,rest=s.split('\n',1);s=first+'\n\n'+entry+rest.lstrip('\n')
else:s=entry+s
p.write_bytes(s.encode('utf-8'))
print(f'{len(checks)} link/HTTP/queue checks pass; continuation note added.')

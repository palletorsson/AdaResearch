from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin,urlsplit,unquote
import json,urllib.request
r=Path.cwd();o=Path(__file__).resolve().parent;rel=o.relative_to(r).as_posix();url='http://localhost:3003/book-review/'+rel+'/index.html'
class Links(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.ids=[]
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if 'id' in a:self.ids.append(a['id'])
  for key in ['href','src']:
   if key in a:self.links.append(a[key])
p=Links();p.feed((o/'index.html').read_text());assert len(p.ids)==len(set(p.ids));results=[]
for link in dict.fromkeys(p.links):
 if link.startswith('#'):assert link[1:] in p.ids;continue
 target=urljoin(url,link)
 if urlsplit(target).hostname!='localhost':continue
 with urllib.request.urlopen(target,timeout=20) as response:
  body=response.read();assert response.status==200;results.append({'url':target,'status':response.status,'bytes':len(body)})
 path=unquote(urlsplit(target).path)
 if path.startswith('/book-review/'):assert (r/path.removeprefix('/book-review/')).read_bytes()==body
with urllib.request.urlopen(url,timeout=20) as response:assert response.read()==(o/'index.html').read_bytes()
for m in ['CA_AgentsCircuits','CA_EdgeOfChaos']:assert (o/(m+'-after.md')).read_bytes()==(r/'commons/maps'/m/'final.md').read_bytes()
v=json.loads((o/'verification.json').read_text());q=json.loads((o/'queue-verification.json').read_text());assert all(c['passed'] for c in v['checks']);assert q['counts']=={'done':28,'open':5},q
(o/'http-checks.json').write_bytes((json.dumps({'checks':results,'internal_anchors_valid':True,'served_review_matches_file':True,'chapter_copies_current':True},indent=2)+'\n').encode())
working=r/'doc/book/iterations/WORKING.md';current=working.read_text()
entry='''## 25 September 2026 — CA ending review comments

[Read the ending, native interior images and exact diffs](2026-09-25-ca-ending-review/index.html).

- Agents/Circuits: native Rule 222 settles with ONE dark address, not a completely filled ring. Text follows that result; classifications and universality are distinguished from what the finite panel demonstrates. New floor comparison and both primary works retained verbatim. Earlier critical essay archived whole into the Wireworld proposal; current critical companion grounds its queer reading in recognition, failed correspondence and bodily support. Two registry description fields corrected.
- Edge of Chaos: name presented as a borrowed research question; lambda definition corrected, blur analogy bounded, storage comparison specified. Handover into Fractals was already correct and retained. Stale plan pier claim failed exact-address AND full-volume queries: runtime rebuilds this map from its authored geometry. No plan/map/geometry repair performed.
- Concurrent walking-slice pass completed during this review. Preserved its six changed existing files, new reader, body-selected gold frames, encounter paragraphs and figure. Its source hashes match completed evidence. Final focused volume run uses the combined implementation. Combined chapter diff explicitly attributes this addition.
- 23 final native checks and 86 preservation/source checks pass. Original native PNGs and failed diagnostic assumptions retained; final processes zero, no script/shader errors. Existing UID/environment/material warnings and sculpture time-budget warning remain. No headset/Quest/learner/full-gallery acceptance.
- Four queue comments resolved (.003/.006/.019/.025); CA now 28 done / 5 open, all remaining items need headset walking/readability/profiling. Original reviewer comments and notes preserved. Canonical final.md and eight-hall capture current; core roles/statuses retained. No commit.
- Next: Fractals, starting from current manuscripts and the newer immersive work. Preserve the distinction between references, things actually demonstrated and open questions.

'''
assert '## 25 September 2026 — CA ending review comments' not in current
working.write_bytes((entry+current).encode())
print(json.dumps({'http_links':len(results),'queue':q['counts'],'review':url},indent=2))

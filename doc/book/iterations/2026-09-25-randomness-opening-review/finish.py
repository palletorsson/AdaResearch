from pathlib import Path
import json,difflib,urllib.request
from html.parser import HTMLParser
from urllib.parse import urlparse,unquote
r=Path.cwd();o=r/'doc/book/iterations/2026-09-25-randomness-opening-review'
p=r/'doc/book/iterations/WORKING.md';s=p.read_text(encoding='utf-8-sig');(o/'working-before-update.md').write_text(s,encoding='utf-8');first,rest=s.split('\n',1)
entry='''

**25 September — Randomness opening review: before anything falls.** [Reading, exact text diff and native museum pairs](2026-09-25-randomness-opening-review/index.html) · [decisions](2026-09-25-randomness-opening-review/DECISIONS.md). Opening four halls only: Random_Definition, Random_Entropy, Random_Remove, Randomness_10_PRINT_Algorithm. Six comments resolved (.002/.015/.022/.024/.025/.031); .017/.023 headset walks remain open and .032 retains its secondary-placement decision after confirming the placeholder screen is absent. Queue now 17 done / 27 open out of 44; Claude's 11 previously completed items and recent manuscript additions preserved. The actual museum refreshes map-authored tiles/artifacts on load, so stale colonnade/screen entries in the saved plan do not justify a global rewrite. Entropy now explicitly declares piers:false and opts its existing ruin into autostart:false; legacy placements keep the running default. Arrival paragraph lets the visitor choose a joint before starting; one original museum photograph enters final.md. Other three chapters unchanged, including breathing bias and probability-versus-count already present in 10 PRINT. 42 recorded native assertions across three halls: Entropy 16 (exit 0), printed walls/floor 13 (exit 0), removal floor 13 completed but process then crashes at shutdown (0xC0000005) in both attempts, including explicit scene cleanup. Cause unresolved; actual desktop-body observations and photographs precede the failure, not clean-process or headset acceptance. 195 publication/preservation checks pass. Paired photographs are from inside actual halls, no grid diagrams or synthetic illustrations. Current 14-chapter capture refreshed; roles, sequence, companion manuscripts, other placements, live plan/save/bake retained. Reload Random_Entropy for waiting ruin. Next: Random_Cubes and subsequent Randomness halls, carrying Claude's newer NoC additions forward; coordinate with independent Noise work.
'''
p.write_text(first+entry+rest,encoding='utf-8')
changes=json.loads((o/'changed-files.json').read_text())
for rel in ['doc/tasks/book_randomness.json','doc/book/iterations/WORKING.md']:
 if rel not in changes:changes.append(rel)
 p=r/rel;dst=o/'after'/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(p.read_bytes())
 before=o/'working-before-update.md' if rel.endswith('WORKING.md') else o/'queue-before-update.json'
 a=before.read_text(encoding='utf-8-sig');b=p.read_text(encoding='utf-8-sig');dst=o/'diffs'/(rel+'.diff');dst.parent.mkdir(parents=True,exist_ok=True);dst.write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+rel,tofile=rel)),encoding='utf-8')
(o/'changed-files.json').write_text(json.dumps(changes,indent=2)+'\n',encoding='utf-8')
class Links(HTMLParser):
 def __init__(self):super().__init__();self.ids=[];self.links=[]
 def handle_starttag(self,t,attrs):
  d=dict(attrs)
  if 'id' in d:self.ids.append(d['id'])
  if t in ['a','img']:self.links.append(d.get('href',d.get('src','')))
p=Links();p.feed((o/'index.html').read_text(encoding='utf-8'));fail=[]
for link in p.links:
 u=urlparse(link)
 if u.scheme or u.netloc:continue
 if not u.path:
  if u.fragment and unquote(u.fragment) not in p.ids:fail.append(link)
  continue
 if u.path.startswith('/compose/') or u.path.startswith('/book-tasks/'):continue
 path=r/u.path.removeprefix('/book-review/') if u.path.startswith('/book-review/') else o/unquote(u.path)
 if not path.exists():fail.append(link)
assert not fail,fail
assert len(p.ids)==len(set(p.ids)),'Duplicate IDs'
url='http://localhost:3003/book-review/doc/book/iterations/2026-09-25-randomness-opening-review/index.html'
with urllib.request.urlopen(url,timeout=20) as response:assert response.read()==(o/'index.html').read_bytes()
result={'links_checked':len(p.links),'missing':fail,'duplicate_ids':False,'live_page_matches_file':True}
(o/'page-verification.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(result)

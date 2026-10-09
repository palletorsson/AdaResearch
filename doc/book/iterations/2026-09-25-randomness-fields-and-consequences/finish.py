from pathlib import Path
import json,difflib,urllib.request
from html.parser import HTMLParser
from urllib.parse import urlparse,unquote
r=Path.cwd();o=Path(__file__).parent
p=r/'doc/book/iterations/WORKING.md';s=p.read_text(encoding='utf-8-sig');(o/'working-before-update.md').write_text(s,encoding='utf-8');first,rest=s.split('\n',1)
entry='''

**25 September — Randomness: fields and consequences.** [Six-hall reading, exact diffs and native museum photographs](2026-09-25-randomness-fields-and-consequences/index.html) · [decisions](2026-09-25-randomness-fields-and-consequences/DECISIONS.md). Remaining Randomness halls reviewed: Mushrooms, Space Geometry, Examples, Pheromone, Space, Game. Ten comments resolved (.001/.004/.005/.006/.009/.010/.011/.012/.027/.034); .028/.029/.030 remain open with current observations. Queue 35 done / 9 open out of 44; original review fields and notes retained. Mushroom specimen staging alone removes demo prism/camera/fill light; standalone scene and population rules preserved. Geometry source layers repaired to 12×24, six tokens shifted onto the existing second-room floor; native bench already had floor through its stamped necklace, which stays authoritative. Local sculpture exclusion clears the approach; no claim of rescuing an unsupported native visitor. Bench remains overlit. Examples opts dartboard into keyboard:off; default demo shortcuts remain. Pheromone review confused script defaults with scene overrides: original four walkers / 40% chapter restored byte for byte, initial failed diagnostic archived. Space gains anchored Worley and entropy-gauge comparisons; native views exposed ground occlusion, addressed through local .35 m and 1.05 m supports. Ground itself retained; walker-bounds task stays open. Game gains podium/profile anchor, biome handover and a timing correction: expected attempt counts, with the podium drawing uniform waits rather than Bernoulli ticks. Two original museum PNGs enter final.md. 35 bounded native assertions across six halls pass, all final exits 0, no GDScript errors; existing engine/renderer/resource warnings retained. Pheromone diagnostic view shows terrain near end wall/gate; full footprint and headset approach remain unverified. No tracked-hand/Quest/whole-route acceptance. 122 publication checks pass; current 14-hall capture refreshed. Five final.md texts changed, Pheromone retained, companions/code excerpts/roles/sequence and live plan/bake/save retained. Shared core references updated only for these six halls; concurrent Noise work preserved. No new commit. Next: coordinate with independent Noise pass before advancing review comments there; nine Randomness follow-ups remain explicitly open.
'''
p.write_text(first+entry+rest,encoding='utf-8')
changed=json.loads((o/'changed-files.json').read_text())
for rel,baseline in [('doc/book/iterations/WORKING.md','working-before-update.md'),('doc/tasks/book_randomness.json','queue-before-update.json')]:
 if rel not in changed:changed.append(rel)
 p=r/rel;dst=o/'after'/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(p.read_bytes())
 a=(o/baseline).read_text(encoding='utf-8-sig');b=p.read_text(encoding='utf-8-sig');dst=o/'diffs'/(rel+'.diff');dst.parent.mkdir(parents=True,exist_ok=True);dst.write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+rel,tofile=rel)),encoding='utf-8')
(o/'changed-files.json').write_text(json.dumps(changed,indent=2)+'\n')
class Links(HTMLParser):
 def __init__(self):super().__init__();self.ids=[];self.links=[]
 def handle_starttag(self,t,attrs):
  d=dict(attrs)
  if 'id' in d:self.ids.append(d['id'])
  if t in ['a','img']:self.links.append(d.get('href',d.get('src','')))
p=Links();p.feed((o/'index.html').read_text());fail=[]
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
url='http://localhost:3003/book-review/'+o.relative_to(r).as_posix()+'/index.html'
with urllib.request.urlopen(url,timeout=20) as response:assert response.read()==(o/'index.html').read_bytes()
result={'links_checked':len(p.links),'missing':fail,'duplicate_ids':False,'live_page_matches_file':True}
(o/'page-verification.json').write_text(json.dumps(result,indent=2)+'\n');print(result)

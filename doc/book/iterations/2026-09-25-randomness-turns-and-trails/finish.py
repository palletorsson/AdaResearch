from pathlib import Path
import json,difflib,urllib.request
from html.parser import HTMLParser
from urllib.parse import urlparse,unquote
r=Path.cwd();o=Path(__file__).parent
p=r/'doc/book/iterations/WORKING.md';s=p.read_text(encoding='utf-8-sig');(o/'working-before-update.md').write_text(s,encoding='utf-8');first,rest=s.split('\n',1)
entry='''

**25 September — Randomness: turns and trails.** [Reading, exact diffs and native museum photographs](2026-09-25-randomness-turns-and-trails/index.html) · [decisions](2026-09-25-randomness-turns-and-trails/DECISIONS.md). Next four halls: Random_Cubes, Random_Rotate_Random_XYZ, Random_Walk, Random_Gaussian. Eight comments resolved (.003/.007/.008/.014/.016/.021/.026/.033); .018/.020 headset tasks and .019 die tuning remain open. Randomness queue now 25 done / 19 open out of 44; original review notes and other queue records preserved. Current die chapter retained, including paired and continuing dice; only two desktop asides removed. Scene animate_slope=false disproves review's proposed clock: static tilt comparison now fits in hall via study:compact (5×5, .6 m cubes, .75 m spacing, .42 m local lift), moved to cell (6,11); default 7×30 preserved. Gaussian compact console hid numeric record: map opts into enlarged side readout on stem via readout:wing, same six lines and compact buttons; other cabinets retain original plate. Walk gains pixel_cloud anchor and rightward direction, returns to terrarium anchor for logbook, names Point Trace, drops mid-chapter heading. Two native PNGs enter final.md; companions, code excerpts, roles, sequence, all other placements and live plan/bake/save retained. Final native checks: rotation 9/9 and sampler 11/11, both exit 0, no GDScript errors; existing engine warnings retained. Initial sampler diagnostic emitted wrong outer signal; corrected to connected InteractableAreaButton signal. Initial compact geometry intersected floor; corrected lift and actual floor-ray assertion. Controlled desktop cameras / supplied button signals, no tracked hands, headset comfort, Quest or complete route acceptance. 79 publication checks, current 14-hall capture and review page served. No new commit. Next: remaining Randomness halls (mushrooms onward), with VR items separate. Concurrent Noise and Claude work preserved.
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

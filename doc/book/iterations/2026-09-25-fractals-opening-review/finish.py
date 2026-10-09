from pathlib import Path
from urllib.request import urlopen
from urllib.parse import urljoin,urlparse,unquote
import hashlib,json,re
r=Path.cwd();o=Path(__file__).resolve().parent;rel=o.relative_to(r).as_posix()
base='http://localhost:3003/book-review/'+rel+'/';page=(o/'index.html').read_text(encoding='utf-8');checks=[]
ids=set(re.findall(r'id="([^"]+)"',page))
for target in sorted(set(re.findall(r'(?:href|src)="([^"]+)"',page))):
 if target.startswith('#'):
  assert unquote(target[1:]) in ids,target
  continue
 url=urljoin(base,target);parts=urlparse(url)
 if parts.netloc!='localhost:3003':continue
 with urlopen(url,timeout=15) as response:
  assert response.status==200,url
  data=response.read()
 checks.append({'url':url,'status':200,'bytes':len(data)})
with urlopen(base+'index.html',timeout=15) as response:assert response.read()==(o/'index.html').read_bytes()
for m in ['Fractal_Recursion','Fractal_RecursiveTrees']:
 for name in ['final.md','intent.md']:
  assert (o/'after/commons/maps'/m/name).read_bytes()==(r/'commons/maps'/m/name).read_bytes(),m+'/'+name
concurrent=json.loads((o/'concurrent-immersion.json').read_text())
assert all(hashlib.sha256((r/p).read_bytes()).hexdigest()==h for p,h in concurrent.items())
(o/'http-checks.json').write_bytes((json.dumps(checks,indent=2)+'\n').encode())
p=r/'doc/book/iterations/WORKING.md';old=p.read_text(encoding='utf-8')
entry='''## 25 September 2026 — Fractals opening review

[Read the revised opening, exact text diffs and native museum image pairs](2026-09-25-fractals-opening-review/index.html).

- Claude had already addressed all 23 Fractals queue items. No duplicate task pass: the queue and existing acceptance statuses remain unchanged.
- Recursion: distinguished smaller copies from a complete fractal definition; returned to the actual last square. Kept the loop/self-call question and allocation encounters. Credited Shiffman beside the code and attributed the introductory explanation accurately.
- RecursiveTrees: separated the generation queue from one possible depth-first self-call. Reworked the rear grammar-tree paragraph into a visible comparison; preserved the critical question of organic recognition without soil/light/wind. Both critical essays, every code excerpt and all anchors retained.
- Updated the two stale intent files. Concurrent threshold work then added shrinking floor frames, new encounter paragraphs and a native chapter image; all retained, with its correction of manuscript encounters versus promoted primary works. Editorial-only snapshots and combined diffs are separately available.
- 27 focused native checks pass (15 Recursion, 12 Trees), including current controls, 85-cell allocation at depths 12/3, 31/121 tree counts and absent branch support. Recursion was rerun against the combined implementation using a distinct output directory. Separate threshold evidence reports 43 passing checks with controlled walking and real mouse rays; headset/Quest/learner acceptance remains open.
- 56 preservation/publication checks pass. Current seven-hall capture, two core review links/digests and served assets verified. Native original screenshots preserved. No geometry or solver edits by this editorial pass; concurrent map/fixture/new receiver changes explicitly attributed. No live plan/save rewrite or commit.
- Next: Cantor and Koch/Sierpinski. Focus on removal, length, passage and pacing; preserve the existing encounter ecology and the newer Claude additions.

'''
if not old.startswith('## 25 September 2026 — Fractals opening review'):p.write_bytes((entry+old).encode('utf-8'))
print('Verified',len(checks),'local HTTP links, anchors, canonical snapshots and concurrent source hashes; WORKING updated')

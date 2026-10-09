from pathlib import Path
from urllib.request import urlopen
from urllib.parse import urljoin,urlparse,unquote
import hashlib,json,re
r=Path.cwd();o=Path(__file__).resolve().parent;rel=o.relative_to(r).as_posix()
base='http://localhost:3003/book-review/'+rel+'/';page=(o/'index.html').read_text(encoding='utf-8');checks=[]
ids=re.findall(r'id="([^"]+)"',page);assert len(ids)==len(set(ids)),'duplicate anchors'
for target in sorted(set(re.findall(r'(?:href|src)="([^"]+)"',page))):
 if target.startswith('#'):
  assert unquote(target[1:]) in ids,target
  continue
 url=urljoin(base,target);parts=urlparse(url)
 if parts.netloc!='localhost:3003':continue
 with urlopen(url,timeout=15) as response:
  assert response.status==200,url;data=response.read()
 checks.append({'url':url,'status':200,'bytes':len(data)})
with urlopen(base+'index.html',timeout=15) as response:assert response.read()==(o/'index.html').read_bytes()
for p in json.loads((o/'changed-files.json').read_text()):assert (o/'after'/p).read_bytes()==(r/p).read_bytes(),p
(o/'http-checks.json').write_bytes((json.dumps(checks,indent=2)+'\n').encode())
v=json.loads((o/'verification.json').read_text())
entry=f'''## 25 September 2026 — Soft Bodies opening: what holds?

[Read both revised chapters, exact text diffs and native museum image pairs](2026-09-25-softbodies-opening-review/index.html).

- User steering: jump to Soft Bodies. This supersedes the Fractals continuation for this review task. Two opening halls covered; next is SoftBodies_Carusell.
- Deformation: clearer stiffness/damping distinction; finite solver budget moved later, hand asymmetry qualified to the current rig, closed skin distinguished from modeled flesh. Five passes scoped to this cube; bending constraints acknowledged. Code and all artifact anchors preserved.
- Native images exposed the free cube leaving its pedestal. Receiver trials failed and are retained as diagnostics, not installed. The opening map now opts into one held crown point with an exposed stem/open stand. It retains its existing physics and controls; unconfigured placements retain the original free cube. This boundary condition is explicit in final.md and technical.md.
- Cloth: preserve SUPPORT's reveal; eight pins → two → none before REBUILD and STIFFNESS. Restore open-surface/closed-volume distinction; correct edge, gravity, landing and arrival wording. Companion now lists all seven controls. The rail is not promised to retain every surface above the floor.
- {v['native_checks']} final native checks pass, including the fixed visible point, changed free surface, unchanged free default, pin motion, support removal and fresh pan falls. Original interior PNGs reviewed. Supplied pointer events are not mouse-ray/headset acceptance. Free-body contact with small supports remains a development issue. Existing engine warnings retained.
- {len(v['checks'])} preservation/publication checks and {len(checks)} local HTTP assets pass. Two canonical manuscripts and technical companions current; nine-hall capture refreshed. Core review digests/links refreshed without acceptance upgrades. Queue (21 done / 1 open), critical essays preserved. Latest rebuilt plan retained; its cube setting alone synchronized to the final map. No commit.

'''
p=r/'doc/book/iterations/WORKING.md';old=p.read_text(encoding='utf-8')
if not old.startswith('## 25 September 2026 — Soft Bodies opening:'):p.write_bytes((entry+old).encode())
print('Verified',len(checks),'served assets and links; canonical snapshots match; WORKING updated')

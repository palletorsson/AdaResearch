from pathlib import Path
import copy, difflib, hashlib, html, json, re, sys
from datetime import datetime, timezone
import markdown
ROOT=Path.cwd(); sys.path.insert(0,str(ROOT))
from tools.book_registers import parse_blocks
OUT=ROOT/'doc/book/iterations/2026-09-23-triangle-illustration'
REPORT=ROOT/'doc/reports/primitives-purpose-2026-09-21'
OLD=REPORT/'annotations-2026-09-23-triangle-face-and-view.json'
NEW=REPORT/'annotations-2026-09-23-triangle-illustration.json'
IMAGE='/book-review/doc/book/iterations/2026-09-23-triangle-illustration/figures/triangle-construction.png'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def write(p,s,raw):p.write_bytes(s.replace('\r\n','\n').replace('\n','\r\n' if b'\r\n' in raw else '\n').encode())
def backup(p):
 q=OUT/'before'/p.relative_to(ROOT);q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():q.write_bytes(p.read_bytes())
p=ROOT/"commons/maps/Point_Triangle_Context/final.md";after=p.read_text(encoding="utf-8");newsha=sha(p.read_bytes())
mapsha=sha((ROOT/"commons/maps/Point_Triangle_Context/map_data.json").read_bytes())
figure="![Three identical sets of points A, B and C: points alone, connected boundary, and pink triangular face.]("+IMAGE+")"
caption="*One set of positions. Connecting them closes a boundary; filling it adds a face.*"
assert after.replace(figure+"\n\n"+caption+"\n\n", "")==OUT.joinpath("Point_Triangle_Context.before.md").read_text(encoding="utf-8")
snapshot=load(OLD);source=next(s for s in snapshot['sources'] if s['map']=='Point_Triangle_Context')
oldblocks={b['id']:b for b in source['blocks']};blocks=parse_blocks(after)
for b in blocks:
 if b['id'] in oldblocks:
  for k in ['status','registers','model','request_sha256']:
   if k in oldblocks[b['id']]:b[k]=oldblocks[b['id']][k]
source['blocks']=blocks;source['sha256']=newsha
snapshot.update(generated_at=datetime.now(timezone.utc).isoformat(),derived_from=OLD.relative_to(ROOT).as_posix(),note='Same Triangle prose, with a native Godot illustration and its caption added. Scene used in the museum and book; unchanged paragraph annotations retained.')
parts={n:load(REPORT/(n+'.json')) for n in ['early','middle','late']}
hall=next(h for h in parts['middle']['maps'] if h['map']=='Point_Triangle_Context')
oldnotes={n['block_id']:n for n in hall['paragraphs']}
newnotes=[]
for b in blocks:
 if b['kind'] not in ['paragraph','footnote']:continue
 if b['id'] in oldnotes:newnotes.append(oldnotes[b['id']]);continue
 assert b['source_text'] in [figure,caption]
 newnotes.append(dict(block_id=b['id'],block_sha256=b['sha256'],purpose='Compare the same three positions under three constructions using the native illustration also encountered in the museum.' if b['source_text']==figure else 'Name the separate operations visible in the illustration without replacing the hands-on encounter.',artifact_anchor='Shared native points, boundary and face reference plate.',artifact_ids=['triangle_construction_plate','triangle_line_puzzle'],evidence_ids=['plate-scene','plate-placement'],reader_move='Compare which elements change while the three positions stay fixed.',why_here='The short mesh explanation has just distinguished vertex data from a rendered face.',without='The reader must hold all three constructions in memory without a common visual reference.',assessment='grounded',opportunity=''))
hall['paragraphs']=newnotes;hall['source_sha256']=newsha
for eid,path,excerpt,note in [
 ('plate-scene','commons/artifacts/triangle_construction_plate/triangle_construction_plate.gd','const TRI_UV:','Native scene repeats the same canonical coordinates at each stage; edges and fill are separate nodes.'),
 ('plate-placement','commons/maps/Point_Triangle_Context/map_data.json','triangle_construction_plate:0:0#offset:0.15,0,-0.30','Plate at source cell (9,5), inspected in a private actual-museum assembly.')]:
 lines=(ROOT/path).read_text(encoding='utf-8').splitlines();hits=[i for i,l in enumerate(lines) if excerpt in l];assert len(hits)==1
 hall['evidence'].append(dict(id=eid,path=path,start_line=hits[0]+1,end_line=hits[0]+1,excerpt=excerpt,kind='artifact' if eid=='plate-scene' else 'placement',note=note))

save(OUT/'triangle-purpose-update.json',dict(source=source,hall=hall,note='Triangle-only update. Shared purpose rebuild deferred because independent Polyhedra revisions are not yet reflected in its paragraph audit.'))
print('Triangle purpose notes saved independently; shared audit files unchanged.')

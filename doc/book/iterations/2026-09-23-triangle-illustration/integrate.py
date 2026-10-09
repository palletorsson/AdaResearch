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
for rel in ['tools/primitives_purpose_view.py','doc/research/possible-bodies/primitives-purpose.html','commons/maps/Point_Triangle_Context/artifacts.md','commons/maps/Point_Triangle_Context/intent.md']:
 backup(ROOT/rel)
for name in ['early.json','middle.json','late.json','audit.json']:backup(REPORT/name)

p=ROOT/'commons/maps/Point_Triangle_Context/final.md';raw=p.read_bytes()
assert sha(raw)=='167fbbfa9a6066475dcb491d2483e9ac2cbf3754241a5d61a96ac5b69e3582e3'
before=raw.decode().replace('\r\n','\n')
figure='![Three identical sets of points A, B and C: points alone, connected boundary, and pink triangular face.]('+IMAGE+')'
caption='*One set of positions. Connecting them closes a boundary; filling it adds a face.*'
anchor='This fill is visible from both sides.'
assert before.count(anchor)==1
after=before.replace(anchor,figure+'\n\n'+caption+'\n\n'+anchor,1)
write(p,after,raw);newsha=sha(p.read_bytes())
OUT.joinpath('Point_Triangle_Context.before.md').write_bytes(raw)
OUT.joinpath('Point_Triangle_Context.after.md').write_bytes(p.read_bytes())
OUT.joinpath('Point_Triangle_Context.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='before/final.md',tofile='final.md')),encoding='utf-8')
assert after.replace(figure+'\n\n'+caption+'\n\n','')==before

p=ROOT/'commons/data/artifact_roles.json';raw=p.read_bytes();s=raw.decode().replace('\r\n','\n')
needle='"primary|boundary-and-face": [\n        "triangle_line_puzzle",\n        "draw_triangle_faces"\n      ]'
assert s.count(needle)==1
s=s.replace(needle,needle.replace('"draw_triangle_faces"','"triangle_construction_plate",\n        "draw_triangle_faces"'),1)
write(p,s,raw)
p=ROOT/'commons/data/museum_core_encounters.json';raw=p.read_bytes();s=raw.decode().replace('\r\n','\n');c=json.loads(s)
room=c['rooms']['Point_Triangle_Context']
start=s.index('"Point_Triangle_Context": {');end=s.index('\n    }',start)
fragment=s[start:end]
fragment=fragment.replace('"triangle_line_puzzle",','"triangle_line_puzzle",\n        "triangle_construction_plate",',1)
fragment=fragment.replace(room['text_sha256'],newsha)
mapsha=sha((ROOT/'commons/maps/Point_Triangle_Context/map_data.json').read_bytes())
fragment=fragment.replace(room['map_sha256'],mapsha)
s=s[:start]+fragment+s[end:];json.loads(s);write(p,s,raw)

p=ROOT/'commons/maps/Point_Triangle_Context/artifacts.md';raw=p.read_bytes();s=raw.decode().replace('\r\n','\n')
s=s.replace('Two primary artifacts carry [the book](final.md).','Two hands-on primary artifacts and one shared illustration carry [the book](final.md).',1)
s=s.replace('| Primary 2 | `draw_triangle_faces`','| Primary illustration | `triangle_construction_plate` | (9, 5) | Compare the same three positions alone, connected and filled. This native scene also supplies the book figure. |\n| Primary 2 | `draw_triangle_faces`',1)
s=s.replace('The stale placement count in metadata is corrected from 17 to 15.','The illustration brings the current placement count to 16, including the text marker.',1)
s=s.replace('This editorial pass changes neither their configurations nor the floor.','The illustration preserves their configurations and the existing floor. Its source cell (9, 5) faces into the wider room; a small placement offset brings it against the wall. The neighbouring sculpture-clear rectangle protects the plate’s reading space.',1)
write(p,s,raw)
p=ROOT/'commons/maps/Point_Triangle_Context/intent.md';raw=p.read_bytes();s=raw.decode().replace('\r\n','\n')
s=s.replace('These are the two book markers and the two primary cards in the room\'s boundary-and-face group.','These remain the two hands-on book markers. The same group now includes triangle_construction_plate, a native points/boundary/face illustration whose Godot render also appears in the book.',1)
s=s.replace('Keep all fourteen artifact placements and the text marker.','Keep all fourteen existing artifact placements and the text marker, with the reference plate added as a fifteenth artifact.',1)
write(p,s,raw)

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
# Existing excerpts only: reanchor nearby line shifts caused by registry/map edits
# and an independent museum-source insertion; never accept changed excerpt text.
relocations=[]
for part in parts.values():
 for h in part['maps']:
  for e in h['evidence']:
   lines=(ROOT/e['path']).read_text(encoding='utf-8-sig').splitlines();a=e['start_line'];b=e['end_line']
   if e['excerpt'] in '\n'.join(lines[a-1:b]):continue
   count=b-a+1
   hits=[i for i in range(max(0,a-22),min(len(lines),a+22)) if e['excerpt'] in '\n'.join(lines[i:i+count])]
   assert hits,(h['map'],e['id'],'Changed evidence must be reviewed')
   index=min(hits,key=lambda i:abs(i+1-a))
   relocations.append(dict(map=h['map'],id=e['id'],path=e['path'],old_line=a,new_line=index+1))
   e['start_line']=index+1;e['end_line']=index+count
save(NEW,snapshot)
for name,part in parts.items():save(REPORT/(name+'.json'),part)
save(OUT/'evidence-relocations.json',relocations)
p=ROOT/'tools/primitives_purpose_view.py';raw=p.read_bytes();s=raw.decode().replace('\r\n','\n')
s=s.replace(OLD.relative_to(ROOT).as_posix(),NEW.relative_to(ROOT).as_posix(),1);write(p,s,raw)
from tools import primitives_purpose_view as purpose
audit=purpose.build_audit();save(REPORT/'audit.json',audit);purpose.render_report(audit)
print(json.dumps({'manuscript_sha256':newsha,'map_sha256':mapsha,'purpose_halls':len(audit['maps']),'purpose_paragraphs':audit['total_paragraphs'],'reanchored_excerpts':len(relocations)}))

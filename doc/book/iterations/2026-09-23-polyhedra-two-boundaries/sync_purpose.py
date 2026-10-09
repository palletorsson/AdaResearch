from pathlib import Path
import json,hashlib,re,copy,sys
from datetime import datetime,timezone
ROOT=Path.cwd();sys.path.insert(0,str(ROOT))
from tools.book_registers import parse_blocks
REPORT=ROOT/'doc/reports/primitives-purpose-2026-09-21'
OUT=ROOT/'doc/book/iterations/2026-09-23-polyhedra-two-boundaries'
OLD=REPORT/'annotations-2026-09-23-triangle-face-and-view.json'
NEW=REPORT/'annotations-2026-09-23-shared-illustrations.json'
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
snapshot=load(OLD);parts={n:load(REPORT/(n+'.json')) for n in ['early','middle','late']}
for source in snapshot['sources']:
 if source['map'] not in ['Point_Triangle_Context','Primitives_Polythedra']:assert sha(ROOT/source['path'])==source['sha256'],source['map']
triangle=load(ROOT/'doc/book/iterations/2026-09-23-triangle-illustration/triangle-purpose-update.json')
for i,s in enumerate(snapshot['sources']):
 if s['map']=='Point_Triangle_Context':snapshot['sources'][i]=triangle['source']
for part in parts.values():
 for i,h in enumerate(part['maps']):
  if h['map']=='Point_Triangle_Context':part['maps'][i]=triangle['hall']
source=next(s for s in snapshot['sources'] if s['map']=='Primitives_Polythedra')
hall=next(h for h in parts['middle']['maps'] if h['map']=='Primitives_Polythedra')
oldblocks={b['id']:b for b in source['blocks']};oldnotes={n['block_id']:n for n in hall['paragraphs']}
blocks=parse_blocks((ROOT/source['path']).read_text(encoding='utf-8'))
for b in blocks:
 if b['id'] in oldblocks:
  for k in ['status','registers','model','request_sha256']:
   if k in oldblocks[b['id']]:b[k]=oldblocks[b['id']][k]
source['blocks']=blocks;source['sha256']=sha(ROOT/source['path']);hall['source_sha256']=source['sha256']
def evidence(eid,path,excerpt,kind,note):
 lines=(ROOT/path).read_text(encoding='utf-8-sig').splitlines();hits=[i for i,l in enumerate(lines) if excerpt in l];assert len(hits)==1,(eid,hits)
 hall['evidence'].append(dict(id=eid,path=path,start_line=hits[0]+1,end_line=hits[0]+1,excerpt=excerpt,kind=kind,note=note))
evidence('plate-scene','commons/artifacts/polyhedra_boundary_plate/polyhedra_boundary_plate.gd','const OPEN_FACES:', 'artifact','Native relief reproduces the held trihedron connectivity; amber closes its absent base.')
evidence('plate-placement','commons/maps/Primitives_Polythedra/map_data.json','polyhedra_boundary_plate:90:0:0.8','placement','Wall-mounted comparison inside the first chamber at cell (1,5). Actual museum images accompany this pass.')
evidence('corner-volume','commons/scenes/em/em_simplex_corners.gd','var points := PackedVector3Array([Vector3.ZERO,','artifact','Four wall/floor intercepts construct a closed right tetrahedron with a matching convex collision hull.')
evidence('corner-placement','commons/maps/Primitives_Polythedra/map_data.json','"simplex_corners":','placement','Nine authored pink corner fills; preserved by this illustration pass.')
readings=[
 ('Look at the two versions','Bring the hidden collision boundary into the visible comparison.','Compare the open object with the amber base in the illustration.','The code has just assigned the same vertices to another construction.','The hidden boundary would remain something to infer only from prose and code.'),
 ('![The open trihedron','Show how the same positions yield different visible and physical boundaries.','Compare what is drawn on the left and closed on the right.','The reader has both the held object and its collision rule in view.','The reader loses the common visual reference between museum and book.'),
 ('*Four positions','Name the precise difference carried by the amber face.','Locate the base absent from the open mesh.','A caption makes the graphic convention explicit.','Colour could look decorative rather than identifying a changed boundary.'),
 ('Walk toward a pink corner','Bring the enclosed volume out of the hand and into the room.','Approach the sloping face and follow its lower edge.','The held tetrahedron can now be recognized as architecture.','The change in scale remains an imagined possibility.'),
 ('Imagine four points','Let the visitor reconstruct the corner from four familiar positions.','Find the floor corner and the three intercepts that define the solid.','The visible face now needs a construction the reader can follow.','The architectural form would arrive without a route to making it.'),
 ('This tetrahedron is','Connect the corner to the accumulated point, segment and triangle vocabulary.','Follow what adding one point outside the prior span makes possible.','Four non-coplanar points have just enclosed a volume.','Simplex would remain an unintroduced name for a familiar construction.'),
 ('The small regular','Distinguish regularity from the wall-fitted tetrahedron.','Compare equal edges with three perpendicular edges at the room corner.','The two tetrahedra share connectivity while serving different geometries.','The reader could mistake a tetrahedron for necessarily regular.'),
 ('Approach it through','Make the gain in solid volume a loss of space for another body.','Meet the corner through the movement controls.','The geometry and collision hull have already been specified.','The room-scale construction would lose its bodily consequence.')]
notes=[]
for b in blocks:
 if b['kind'] not in ['paragraph','footnote']:continue
 if b['id'] in oldnotes:notes.append(oldnotes[b['id']]);continue
 match=next((x for x in readings if b['source_text'].startswith(x[0])),None);assert match,b['source_text']
 plate=readings.index(match)<3
 notes.append(dict(block_id=b['id'],block_sha256=b['sha256'],purpose=match[1],artifact_anchor='Shared native boundary comparison.' if plate else 'Pink right-tetrahedron fills in existing museum corners.',artifact_ids=['polyhedra_boundary_plate','grab_trihedron'] if plate else ['grab_tetrahedron'],evidence_ids=['plate-scene','plate-placement','hull'] if plate else ['corner-volume','corner-placement'],reader_move=match[2],why_here=match[3],without=match[4],assessment='grounded',opportunity=''))
hall['paragraphs']=notes
for e in hall['evidence']:
 if e['id']=='inventory':e['excerpt']='rotated 180 degrees';e['note']='Local inventory now agrees with the existing 180-degree trihedron placement.'
hall['actions']=[a for a in hall['actions'] if a['title']!='Correct the trihedron orientation in the local inventory']
relocations=[]
for part in parts.values():
 for h in part['maps']:
  for e in h['evidence']:
   lines=(ROOT/e['path']).read_text(encoding='utf-8-sig').splitlines();a=e['start_line'];b=e['end_line'];count=b-a+1
   if e['excerpt'] in '\n'.join(lines[a-1:b]):continue
   hits=[i for i in range(len(lines)) if e['excerpt'] in '\n'.join(lines[i:i+count])];assert hits,(h['map'],e['id'],e['excerpt'])
   index=min(hits,key=lambda i:abs(i+1-a));assert abs(index+1-a)<1500,(h['map'],e['id'],'Large source move')
   relocations.append(dict(map=h['map'],id=e['id'],old_line=a,new_line=index+1));e['start_line']=index+1;e['end_line']=index+count
snapshot.update(generated_at=datetime.now(timezone.utc).isoformat(),derived_from=OLD.relative_to(ROOT).as_posix(),note='Synchronizes the shared Triangle and Polyhedra illustrations and the existing authored pink-corner passage. Earlier annotations retained where paragraphs match.')
for p in [REPORT/'early.json',REPORT/'middle.json',REPORT/'late.json',REPORT/'audit.json',ROOT/'tools/primitives_purpose_view.py',ROOT/'doc/research/possible-bodies/primitives-purpose.html']:
 q=OUT/'before'/p.relative_to(ROOT);q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():q.write_bytes(p.read_bytes())
save(NEW,snapshot)
for n,part in parts.items():save(REPORT/(n+'.json'),part)
save(OUT/'purpose-source-relocations.json',relocations)
p=ROOT/'tools/primitives_purpose_view.py';s=p.read_text(encoding='utf-8');assert OLD.relative_to(ROOT).as_posix() in s;s=s.replace(OLD.relative_to(ROOT).as_posix(),NEW.relative_to(ROOT).as_posix(),1)
# Render source figures safely as images in the paragraph-purpose view.
needle="function prose(m,b){const n=el("
image_handler="function prose(m,b){const picture=String(b.source_text||'').match(/^!\\[([^\\]]*)\\]\\((\\/book-review\\/[^\\s)]+)\\)$/);if(picture){const f=el('figure','prose'),a=el('a'),img=el('img');a.href=picture[2];img.src=picture[2];img.alt=picture[1];img.loading='lazy';img.style.cssText='display:block;width:100%;height:auto';a.append(img);f.append(a);f.style.margin='4px 0';return f;}const n=el("
# The builder holds PAGE as a raw Python string, so JS requires single backslashes.
assert s.count(needle)==1;s=s.replace(needle,image_handler,1);p.write_text(s,encoding='utf-8')
from tools import primitives_purpose_view as purpose
audit=purpose.build_audit();save(REPORT/'audit.json',audit);purpose.render_report(audit)
print(json.dumps(dict(halls=len(audit['maps']),paragraphs=audit['total_paragraphs'],reanchored_excerpts=len(relocations))))

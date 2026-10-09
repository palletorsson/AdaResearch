from pathlib import Path
import json,hashlib,sys
from datetime import datetime,timezone
ROOT=Path.cwd();sys.path.insert(0,str(ROOT))
from tools.book_registers import parse_blocks
REPORT=ROOT/'doc/reports/primitives-purpose-2026-09-21'
OLD=REPORT/'annotations-2026-09-23-shared-illustrations.json'
NEW=REPORT/'annotations-2026-09-23-cube-hidden-diagonal.json'
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
snapshot=load(OLD);parts={n:load(REPORT/(n+'.json')) for n in ['early','middle','late']}
source=next(s for s in snapshot['sources'] if s['map']=='Point_Animatedcube')
hall=next(h for h in parts['middle']['maps'] if h['map']=='Point_Animatedcube')
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
evidence('shared-diagonal-plate','commons/artifacts/cube_diagonal_plate/cube_diagonal_plate.gd','const FACE_TRIPLES:', 'artifact','The two reference states use the actual builder front-face triples. The capture checks the rendered meshes against the source.')
evidence('shared-diagonal-placement','commons/maps/Point_Animatedcube/map_data.json','cube_diagonal_plate:-90:0:0.8','placement','Wall reference beside the first builder, cell (7,5). Existing artifact placements remain.')
notes=[]
for b in blocks:
 if b['kind'] not in ['paragraph','footnote']:continue
 if b['id'] in oldnotes:notes.append(oldnotes[b['id']]);continue
 assert b['source_text'].startswith(('![The same cube face','*The diagonal was already there.')),b['source_text']
 image=b['source_text'].startswith('![')
 notes.append(dict(block_id=b['id'],block_sha256=b['sha256'],purpose='Make the shared edge and the changed triangle available to compare in the book and room.' if image else 'Identify which points stay still and why the edge becomes a crease.',artifact_anchor='Front face of animatedcubebuilder and the wall reference.',artifact_ids=['animatedcubebuilder','cube_diagonal_plate'],evidence_ids=['triangles','shared-diagonal-plate','shared-diagonal-placement'],reader_move='Compare the two states after trying the corner experiment.',why_here='The reader has just followed the triangle triples; the picture connects their shared indices to the crease.',without='The reader must reconstruct the spatial relation from the code alone.',assessment='grounded',opportunity=''))
hall['paragraphs']=notes
relocations=[]
for part in parts.values():
 for h in part['maps']:
  for e in h['evidence']:
   lines=(ROOT/e['path']).read_text(encoding='utf-8-sig').splitlines();a=e['start_line'];b=e['end_line'];count=b-a+1
   if e['excerpt'] in '\n'.join(lines[a-1:b]):continue
   hits=[i for i in range(len(lines)) if e['excerpt'] in '\n'.join(lines[i:i+count])];assert hits,(h['map'],e['id'],e['excerpt'])
   index=min(hits,key=lambda i:abs(i+1-a));assert abs(index+1-a)<1500,(h['map'],e['id'])
   relocations.append(dict(map=h['map'],id=e['id'],old_line=a,new_line=index+1));e['start_line']=index+1;e['end_line']=index+count
snapshot.update(generated_at=datetime.now(timezone.utc).isoformat(),derived_from=OLD.relative_to(ROOT).as_posix(),note='Adds two Animated Cube figure/caption notes. Earlier manuscript wording and editorial notes retained.')
save(NEW,snapshot)
for n,part in parts.items():save(REPORT/(n+'.json'),part)
save(ROOT/'doc/book/iterations/2026-09-23-cube-hidden-diagonal/purpose-relocations.json',relocations)
p=ROOT/'tools/primitives_purpose_view.py';s=p.read_text(encoding='utf-8');assert OLD.relative_to(ROOT).as_posix() in s;s=s.replace(OLD.relative_to(ROOT).as_posix(),NEW.relative_to(ROOT).as_posix(),1);p.write_text(s,encoding='utf-8')
from tools import primitives_purpose_view as purpose
audit=purpose.build_audit();save(REPORT/'audit.json',audit);purpose.render_report(audit)
print(json.dumps(dict(halls=len(audit['maps']),paragraphs=audit['total_paragraphs'],reanchored=len(relocations))))

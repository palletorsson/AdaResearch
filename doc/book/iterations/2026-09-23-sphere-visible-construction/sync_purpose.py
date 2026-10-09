from pathlib import Path
import json,hashlib,sys
from datetime import datetime,timezone
ROOT=Path.cwd();sys.path.insert(0,str(ROOT))
from tools.book_registers import parse_blocks
REPORT=ROOT/'doc/reports/primitives-purpose-2026-09-21'
OLD=REPORT/'annotations-2026-09-23-cube-hidden-diagonal.json'
NEW=REPORT/'annotations-2026-09-23-sphere-visible-construction.json'
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
snapshot=load(OLD);part=load(REPORT/'late.json')
source=next(s for s in snapshot['sources'] if s['map']=='Primitives_Ignorance')
hall=next(h for h in part['maps'] if h['map']=='Primitives_Ignorance')
oldblocks={b['id']:b for b in source['blocks']};oldnotes={n['block_id']:n for n in hall['paragraphs']}
blocks=parse_blocks((ROOT/source['path']).read_text(encoding='utf-8'))
for b in blocks:
 if b['id'] in oldblocks:
  for k in ['status','registers','model','request_sha256']:
   if k in oldblocks[b['id']]:b[k]=oldblocks[b['id']][k]
source['blocks']=blocks;source['sha256']=sha(ROOT/source['path']);hall['source_sha256']=source['sha256']
path='tools/captures/sphere_resolution_layout.gd';excerpt='subject.apply_grid_config(row["configs"][j])'
lines=(ROOT/path).read_text(encoding='utf-8').splitlines();line=next(i+1 for i,l in enumerate(lines) if excerpt in l)
hall['evidence'].append(dict(id='i-shared-figure',path=path,start_line=line,end_line=line,excerpt=excerpt,kind='artifact',note='Book layout loads the actual scenes and applies their six map configurations; geometry and materials remain the museum artifacts.'))
notes=[]
for b in blocks:
 if b['kind'] not in ['paragraph','footnote']:continue
 if b['id'] in oldnotes:notes.append(oldnotes[b['id']]);continue
 assert b['source_text'].startswith(('![The existing high','*The lower row keeps')),b['source_text']
 notes.append(dict(block_id=b['id'],block_sha256=b['sha256'],purpose='Let the reader compare the same mesh with and without its edge overlay.',artifact_anchor='The six existing sphere-resolution exhibits.',artifact_ids=['sphere_high','sphere_mid','sphere_low'],evidence_ids=['i-pairs','i-overlay','i-high','i-mid','i-low','i-shared-figure'],reader_move='Compare the two images in each column, then inspect how the silhouette differs across columns.',why_here='The distinction between sampled geometry and softened shading has just been introduced.',without='A reader away from the museum must imagine the paired comparison from prose alone.',assessment='grounded',opportunity=''))
hall['paragraphs']=notes
snapshot.update(generated_at=datetime.now(timezone.utc).isoformat(),derived_from=OLD.relative_to(ROOT).as_posix(),note='Adds the sphere comparison figure and caption; all earlier notes and chapter wording retained.')
save(NEW,snapshot);save(REPORT/'late.json',part)
p=ROOT/'tools/primitives_purpose_view.py';s=p.read_text(encoding='utf-8');assert OLD.relative_to(ROOT).as_posix() in s;s=s.replace(OLD.relative_to(ROOT).as_posix(),NEW.relative_to(ROOT).as_posix(),1);p.write_text(s,encoding='utf-8')
from tools import primitives_purpose_view as purpose
audit=purpose.build_audit();save(REPORT/'audit.json',audit);purpose.render_report(audit)
print(json.dumps(dict(halls=len(audit['maps']),paragraphs=audit['total_paragraphs'])))

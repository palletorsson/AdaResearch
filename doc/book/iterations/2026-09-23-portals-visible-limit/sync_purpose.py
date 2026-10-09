from pathlib import Path
import json,hashlib,sys
from datetime import datetime,timezone
ROOT=Path.cwd();sys.path.insert(0,str(ROOT))
from tools.book_registers import parse_blocks
REPORT=ROOT/'doc/reports/primitives-purpose-2026-09-21'
OLD=REPORT/'annotations-2026-09-23-sphere-visible-construction.json'
NEW=REPORT/'annotations-2026-09-23-portals-visible-limit.json'
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
snapshot=load(OLD);parts={n:load(REPORT/(n+'.json')) for n in ['early','middle','late']}
source=next(s for s in snapshot['sources'] if s['map']=='Primitives_Portals')
hall=next(h for h in parts['late']['maps'] if h['map']=='Primitives_Portals')
oldblocks={b['id']:b for b in source['blocks']};oldnotes={n['block_id']:n for n in hall['paragraphs']}
blocks=parse_blocks((ROOT/source['path']).read_text(encoding='utf-8'))
for b in blocks:
 if b['id'] in oldblocks:
  for k in ['status','registers','model','request_sha256']:
   if k in oldblocks[b['id']]:b[k]=oldblocks[b['id']][k]
source['blocks']=blocks;source['sha256']=sha(ROOT/source['path']);hall['source_sha256']=source['sha256']
for e in hall['evidence']:
 if e['id']=='p-route':
  e['excerpt']='This map now sets `#portal_spacing:1.4`'
  e['note']='The map-local spacing now fits all twenty ring origins within 26.6 metres; headset passage remains a separate check.'
path='commons/ui/limit_polygon_diagram.gd';excerpt='var perimeter := 2.0*n*sin(PI/n)'
lines=(ROOT/path).read_text(encoding='utf-8').splitlines();line=next(i+1 for i,l in enumerate(lines) if excerpt in l)
hall['evidence'].append(dict(id='p-shared-diagram',path=path,start_line=line,end_line=line,excerpt=excerpt,kind='artifact',note='A changing native polygon and fixed circle reference share the selected ring count; this production component also supplies the book figure.'))
notes=[]
for b in blocks:
 if b['kind'] not in ['paragraph','footnote']:continue
 if b['id'] in oldnotes:notes.append(oldnotes[b['id']]);continue
 assert b['source_text'].startswith(('The display names','![Three states','*The corner becomes')),b['source_text']
 notes.append(dict(block_id=b['id'],block_sha256=b['sha256'],purpose='Make the separate planar comparison visible while preserving the distinction between perception and measured boundary length.',artifact_anchor='Live polygon diagram beside the portal instrument.',artifact_ids=['combine_portals'],evidence_ids=['p-shared-diagram','p-perimeter','p-panel'],reader_move='Select a ring, compare straight chords with the fixed circular reference, and read the remaining perimeter gap.',why_here='The reader has reached the simpler planar model carried beside the walk through the tori.',without='The gap remains an abstract number and the chord construction is difficult to inspect from prose alone.',assessment='grounded',opportunity=''))
hall['paragraphs']=notes
relocations=[]
for part in parts.values():
 for h in part['maps']:
  for e in h['evidence']:
   lines=(ROOT/e['path']).read_text(encoding='utf-8-sig').splitlines();a=e['start_line'];b=e['end_line'];count=b-a+1
   if e['excerpt'] in '\n'.join(lines[a-1:b]):continue
   hits=[i for i in range(len(lines)) if e['excerpt'] in '\n'.join(lines[i:i+count])];assert hits,(h['map'],e['id'],e['excerpt'])
   index=min(hits,key=lambda i:abs(i+1-a));assert abs(index+1-a)<1500
   relocations.append(dict(map=h['map'],id=e['id'],old_line=a,new_line=index+1));e['start_line']=index+1;e['end_line']=index+count
snapshot.update(generated_at=datetime.now(timezone.utc).isoformat(),derived_from=OLD.relative_to(ROOT).as_posix(),note='Portals gains a live polygon comparison and shared book figure; map-local spacing fits its complete progression. Earlier prose and other hall notes retained.')
save(NEW,snapshot)
for n,part in parts.items():save(REPORT/(n+'.json'),part)
save(ROOT/'doc/book/iterations/2026-09-23-portals-visible-limit/purpose-relocations.json',relocations)
p=ROOT/'tools/primitives_purpose_view.py';s=p.read_text(encoding='utf-8');assert OLD.relative_to(ROOT).as_posix() in s;s=s.replace(OLD.relative_to(ROOT).as_posix(),NEW.relative_to(ROOT).as_posix(),1);p.write_text(s,encoding='utf-8')
from tools import primitives_purpose_view as purpose
audit=purpose.build_audit();save(REPORT/'audit.json',audit);purpose.render_report(audit)
core_path=ROOT/'commons/data/museum_core_encounters.json';core=load(core_path)
row=core['rooms']['Primitives_Portals'];row['text_sha256']=sha(ROOT/'commons/maps/Primitives_Portals/final.md');row['map_sha256']=sha(ROOT/'commons/maps/Primitives_Portals/map_data.json');save(core_path,core)
print(json.dumps(dict(halls=len(audit['maps']),paragraphs=audit['total_paragraphs'],reanchored=len(relocations))))

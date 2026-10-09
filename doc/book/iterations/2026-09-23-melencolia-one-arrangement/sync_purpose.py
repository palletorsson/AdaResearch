from pathlib import Path
import json,hashlib,sys
from datetime import datetime,timezone
ROOT=Path.cwd();sys.path.insert(0,str(ROOT))
from tools.book_registers import parse_blocks
REPORT=ROOT/'doc/reports/primitives-purpose-2026-09-21'
OUT=ROOT/'doc/book/iterations/2026-09-23-melencolia-one-arrangement'
OLD=REPORT/'annotations-2026-09-23-portals-visible-limit.json'
NEW=REPORT/'annotations-2026-09-23-melencolia-one-arrangement.json'
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
snapshot=load(OLD);part=load(REPORT/'late.json')
source=next(s for s in snapshot['sources'] if s['map']=='Primitives_Melencolia')
hall=next(h for h in part['maps'] if h['map']=='Primitives_Melencolia')
oldblocks={b['id']:b for b in source['blocks']};oldnotes={n['block_id']:n for n in hall['paragraphs']}
blocks=parse_blocks((ROOT/source['path']).read_text(encoding='utf-8'))
for b in blocks:
 if b['id'] in oldblocks:
  for k in ['status','registers','model','request_sha256']:
   if k in oldblocks[b['id']]:b[k]=oldblocks[b['id']][k]
source['blocks']=blocks;source['sha256']=sha(ROOT/source['path']);hall['source_sha256']=source['sha256']
def evidence(eid,path,excerpt,note,kind='artifact'):
 lines=(ROOT/path).read_text(encoding='utf-8-sig').splitlines();hits=[i for i,l in enumerate(lines) if excerpt in l];assert hits
 hall['evidence'].append(dict(id=eid,path=path,start_line=hits[0]+1,end_line=hits[0]+1,excerpt=excerpt,kind=kind,note=note))
evidence('m-shared-court','tools/captures/melencolia_court.gd','subject: Node3D = load(row["scene"]).instantiate()','The three views instantiate the nine production scenes with actual map configurations; capture checks compare their bounds with the museum.')
evidence('m-counter-place','commons/maps/Primitives_Melencolia/map_data.json','frame_counter_display:180:2:3','Existing return counter by the exit, default count/boot mode.','placement')
evidence('m-counter-source','commons/visualaid/frame_counter/frame_counter_display.gd','var frames: int = int(Engine.get_process_frames())','The default reading comes from engine process frames, not a saved personal elapsed-time record.')
for e in hall['evidence']:
 if e['id']=='m-stale-intent':
  e['excerpt']='Recognising a form does not finish looking at its arrangement.'
  e['note']='Updated intent replaces the old claim that everything buildable has been built; it follows the present court and counter return.'
notes=[]
for b in blocks:
 if b['kind'] not in ['paragraph','footnote']:continue
 if b['id'] in oldnotes:notes.append(oldnotes[b['id']]);continue
 t=b['source_text'];figure=t.startswith(('![The museum court','*The same court'))
 assert figure or t.startswith(('By the way out,','It is much larger now.','Ten rooms ago')),t
 notes.append(dict(block_id=b['id'],block_sha256=b['sha256'],purpose='Separate a change of view from a change of geometry by returning to one arrangement.' if figure else 'Return to the opening counter and ask which history a cumulative number can carry.',artifact_anchor='Nine production court objects.' if figure else 'Default frame counter by the exit.',artifact_ids=['pyramid','pyramidlong','cube_scene'] if figure else ['frame_counter_display'],evidence_ids=['m-shared-court','m-court','m-centre','m-cross'] if figure else ['m-counter-place','m-counter-source'],reader_move='Compare aligned, oblique and plan views; keep track of the objects that become hidden.' if figure else 'Recognise the running number from Point One and distinguish its total from the visitor’s experience.',why_here='The solids have begun to read as an arrangement; a camera change anticipates Transformation.' if figure else 'The closing hall returns to the opening encounter before the visitor moves into Transformation.',without='The change of appearance remains verbal for someone away from the museum.' if figure else 'The already placed counter and new closing passage remain absent from the purpose notes.',assessment='grounded',opportunity='' if figure else 'The greater count assumes the same running engine session; direct hall entry does not replay that history.'))
hall['paragraphs']=notes
for a in hall['actions']:
 if a['title'].startswith('Align the supporting corpus'):
  a['reason']='Intent and the current tutorial now follow the court and counter. Older summary, walked and technical research still need a separate alignment pass; technical.md now links to the current implementation companion.'
 if a['title'].startswith('Test the two-platform route'):
  a['reason']='Two controlled ramp walks and three floor rays now pass. Headset comfort, magic-square reading distance and learner experience of the return sightline remain unverified.'
relocations=[]
for h in part['maps']:
 for e in h['evidence']:
  lines=(ROOT/e['path']).read_text(encoding='utf-8-sig').splitlines();start=e['start_line'];span=e['end_line']-start+1
  if e['excerpt'] in '\n'.join(lines[start-1:start-1+span]):continue
  hits=[i for i in range(len(lines)) if e['excerpt'] in '\n'.join(lines[i:i+span])];assert hits,(h['map'],e['id'])
  i=min(hits,key=lambda i:abs(i+1-start));e['start_line']=i+1;e['end_line']=i+span;relocations.append(dict(map=h['map'],id=e['id'],old=start,new=i+1))
snapshot.update(generated_at=datetime.now(timezone.utc).isoformat(),derived_from=OLD.relative_to(ROOT).as_posix(),note='Melencolia gains a shared native court illustration; existing counter return receives paragraph notes. Earlier prose is preserved.')
save(NEW,snapshot);save(REPORT/'late.json',part);save(OUT/'purpose-relocations.json',relocations)
p=ROOT/'tools/primitives_purpose_view.py';s=p.read_text(encoding='utf-8');assert OLD.relative_to(ROOT).as_posix() in s;p.write_text(s.replace(OLD.relative_to(ROOT).as_posix(),NEW.relative_to(ROOT).as_posix(),1),encoding='utf-8')
stale=[s['map'] for s in snapshot['sources'] if sha(ROOT/s['path'])!=s['sha256']]
assert source['sha256']==sha(ROOT/source['path'])
assert {b['id'] for b in blocks if b['kind'] in ['paragraph','footnote']}=={n['block_id'] for n in hall['paragraphs']}
status=dict(melencolia_notes_current=True,paragraphs=len(notes),global_view_rebuild='deferred for concurrent manuscript changes' if stale else 'ready',stale_maps=stale)
if not stale:
 from tools import primitives_purpose_view as purpose
 audit=purpose.build_audit();save(REPORT/'audit.json',audit);purpose.render_report(audit)
save(OUT/'purpose-sync-status.json',status);print(json.dumps(status))

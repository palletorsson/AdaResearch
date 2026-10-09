from pathlib import Path
import hashlib, json
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
ROOM='Escher_Impossible'

def read(p): return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,d): (ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

p='commons/artifacts/registry/foundations.json'; d=read(p)
a=d['artifacts']['escher_staircase']
a['description']='Finite staircase study with five constructions: descending return, closing drop, open run, incomplete scaffold and tilted treads. Opt-in physical controls advance a visible marker and measure displayed tread-centre heights. No walkable treads or player transport; no proof of incompleteness.'
a['qfep_connection']='Compare the desire for a perpetual climb with the return, opening or tilted surface that its finite construction supplies.'
a['interactions']=['STEP / BACK move the model marker; FORM cycles five constructions; RESET clears the measured journey (lesson_controls:on).','Without lesson_controls, the legacy rotating sculpture and marker API remain available.']
a['parameters']['lesson_controls']='Opt-in reachable study console; on in Escher_Impossible. Disables auto rotation, stages a smaller model and measures world-space tread-centre heights.'
a=d['artifacts']['penrose_triangle']
a['description']='Three-beam perspective study. Separated top endpoint centres project together from the marked eye position; moving sideways reveals their gap. This is not a reconstruction of the classic three-right-angle Penrose tribar. Optional active-camera feedback reports alignment.'
a['qfep_connection']='A connection in the image depends on a viewpoint; move the viewer to examine the connection in space.'
a['gamwell_reference']='Chapter 9: impossible figures (context; this sculpture isolates endpoint projection)'
a['parameters']['track_viewer']='Opt-in active Camera3D alignment feedback; on in Escher_Impossible. Headset stereoscopic appearance still requires testing.'
a['parameters']['auto_rotate']='Slowly rotate the beams to reveal their separated endpoints'
a['dna']['default']='disclosure=marker: caption and viewing bead remain; the back endpoint is aligned to the ray from the marked eye through the front endpoint. track_viewer is opt-in.'
write(p,d)

p='commons/data/museum_core_encounters.json'; d=read(p); r=d['rooms'][ROOM]
r.update(reason='Follow actual tread heights, then move the viewer to separate apparent connection from spatial connection. Preserve the trident and pipe as supporting comparisons.',status='encounter_and_text_revised',learner_verified=False,review_evidence='doc/book/iterations/2026-09-20-escher-review/SUMMARY.md')
for key,f in [('text_sha256','final.md'),('map_sha256','map_data.json')]:
 r[key]=hashlib.sha256((ROOT/'commons/maps'/ROOM/f).read_bytes()).hexdigest()
write(p,d)

lines={
 'escher_staircase':'Follow the marker. Where does the rise return?',
 'penrose_triangle':'Do the ends meet, or only their images? Move sideways.',
 'impossible_trident':'Two rods below, three tines above. Follow one edge through the change.',
 'magritte_pipe':'You recognised a pipe before asking what you could do with it.'}
p='commons/data/book/foundationscrisis.json'; d=read(p)
pearl=next(n for n in d['pearls'] if n['map']==ROOM)
for ln in pearl['lines']:
 if ln.get('token') in lines:
  ln.update(text=lines[ln['token']],by='hand');ln.pop('note',None);ln.pop('note_src',None)
write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p); n=next(n for n in d['trunk'] if n['node']=='foundationscrisis')
 for pearl in n['pearls']+d.get('hand_pearls',{}).get('foundationscrisis',[]):
  if pearl.get('map')==ROOM:
   pearl.update(says=lines,says_by={t:'hand' for t in lines})
 write(p,d)

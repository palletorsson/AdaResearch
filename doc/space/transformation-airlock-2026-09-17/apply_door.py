"""Scoped new finale; preserve all prior studies and other maps' authored work."""
import copy
import hashlib
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
MAP = 'Trans_Pit'
TOKEN = 'transformation_airlock'

def read(rel):
    return json.loads((ROOT / rel).read_text(encoding='utf-8-sig'))

def save(rel, value):
    path = ROOT / rel
    backup = OUT / 'before' / rel
    if not backup.exists():
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, backup)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')

rel = f'commons/maps/{MAP}/map_data.json'
data = read(rel)
assert len(data['layers']['structure']) == 25, 'Run once on original 25-row hall'
before_layers = copy.deepcopy(data['layers'])
for layer, rows in data['layers'].items():
    for z in range(25, 33):
        rows.append(['5'] + ['1']*13 + ['5'] if layer == 'structure' else ['']*15)
data['layers']['structure'][29] = ['5']*3 + ['1']*9 + ['5']*3
data['layers']['structure'][32] = ['5']*6 + ['1']*3 + ['5']*6
data['layers']['interactables'][29][7] = TOKEN + ':0:0#plinth:0'
assert data['layers']['utilities'][23][7] == 't'
data['layers']['utilities'][23][7] = ''
data['layers']['utilities'][31][7] = 't'
data['map_info']['dimensions']['depth'] = 33
data['map_info']['description'] += ' At the end, approach an armoured door: its two leaves translate, rotate and shrink into recesses, combining the chapter into a passage.'
data['map_info']['metadata']['learning_objectives'].append('Recognise translation, rotation and scale accumulating in one physical doorway')
data['dev_notes'] += ' Finale added 2026-09-17: 8m-wide transformation_airlock at (7,29), floor origin, flat approach and exit runway. Exit t moved to (7,31). Door remains open while a visitor is in its clearance area, then reverses after three empty seconds. Existing simulation observation route remains available.'
data['transformation_finale'] = {'artifact': TOKEN, 'cell': [7,29], 'opening_metres': [3,2.8], 'operations': ['translation','rotation','uniform scale'], 'trigger':'approach from either side', 'reset':'three seconds after all visitors leave sensor', 'museum_route':'simulation exit; outer observation route remains available'}
save(rel,data)
for layer, rows in before_layers.items():
    if layer == 'utilities': rows[23][7] = ''
    assert data['layers'][layer][:25] == rows

registry_path = ROOT / 'commons/artifacts/registry/transforms.json'
raw = registry_path.read_text(encoding='utf-8-sig')
registry = json.loads(raw)
assert TOKEN not in registry['artifacts']
entry = {
    'lookup_name':TOKEN, 'name':'Make Room — Transformation Airlock',
    'scene':f'res://commons/artifacts/{TOKEN}/{TOKEN}.tscn',
    'description':'A full-size armoured doorway. Approach: the same two leaves translate apart and upwards, turn through ninety degrees, then shrink into the side recesses. Physical collision follows every visible pose. Stays open around visitors; reverses after the clearance zone is empty.',
    'category':'transforms','dev_category':'transforms','complexity':'beginner',
    'dev_themes':['transforms','space','embodiment'],
    'tags':['translation','rotation','scale','door','sci-fi','passage','composition'],
    'qfep_connection':'The same operations can occupy a route or make room. Transformation changes relations between the panels, the frame and a body; the fixed frame makes those changes observable.',
    'map_ready':True,'include_in_map_data':True,'auto_ground':False,
    'map_sequences':['transformation'],
    'interactions':['Approach from either side to open','Wait beside the opening and compare the three movements','Walk through; leave the clearance area to see the sequence reverse'],
    'signals':['passage_opened','passage_closed'],
    'parameters':{'opening_seconds':'Seconds for the cumulative opening, default 4.8','empty_hold_seconds':'Empty clearance time before reversing, default 3'},
    'spatial_needs':{'platform':'none','footprint_cells':8,'clearance':{'front':5,'back':5,'left':0,'right':0},'player_position':'front','wall_backing':False,'orientation':'face_approach','preferred_zone':'end'},
    'geometry_spec':{'mesh_type':'procedural','construction':{'method':'extruded convex plates and fixed box frame','primitives':['box','convex prism'],'operations':['translate','rotate','uniform scale']},'material':{'type':'standard','key_properties':['metallic','emission']},'animation':{'type':'proximity','driven_by':'physics process','affects':['transform','collision']}}
}
registry['artifacts'][TOKEN] = entry
# Keep the large registry's existing formatting and ordering untouched.
backup = OUT / 'before/commons/artifacts/registry/transforms.json'
backup.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(registry_path,backup)
addition = json.dumps({TOKEN:entry},indent='\t',ensure_ascii=False)[2:-2]
addition = '\n'.join('\t'+line for line in addition.splitlines())
raw = raw.replace('"artifacts": {','"artifacts": {\n'+addition+',',1)
assert json.loads(raw)['artifacts'][TOKEN] == entry
registry_path.write_text(raw,encoding='utf-8')

roles = read('commons/data/artifact_roles.json')
roles['roles'][MAP][TOKEN]='primary'
roles['order'][MAP]['primary'].append(TOKEN)
save('commons/data/artifact_roles.json',roles)

final_path = ROOT / f'commons/maps/{MAP}/final.md'
backup = OUT / f'before/commons/maps/{MAP}/final.md'
backup.parent.mkdir(parents=True,exist_ok=True)
shutil.copy2(final_path,backup)
final = final_path.read_text(encoding='utf-8-sig').rstrip() + '''

## Make room

<!-- @transformation_airlock -->

After the growing cubes, two armoured leaves meet inside a heavy frame. Approach, then stop. Follow the bright strip along one leaf.

It moves sideways and up. It turns through a quarter-turn. Then it becomes smaller, drawing its armour into a recess beside the opening. The frame has stayed still. The passage has changed.

These are the same three operations we added to the pickup cube at the beginning of the chapter. There they made a small object conspicuous. Here they make room for you.

The door keeps a fraction of its opening, from zero to one. Three overlapping intervals of that fraction drive position, angle and size:

```gdscript
var factor: float = lerpf(1.0, 0.34, operations.z)
var at := Vector3(side * lerpf(0.75, 2.15, operations.x), lerpf(1.4, 2.0, operations.x), -0.26)
var turn := Basis(Vector3.BACK, side * operations.y * PI * 0.5)
```

`side` gives the leaves opposite directions. The local Z axis points through the doorway, so these turns happen across its face. Each leaf ends at thirty-four percent of its original size. Its collision shape changes with it: the visible opening is also an opening your body can use.

Walk through. The door stays open while someone is near it. Once everyone leaves its clearance area, it waits three seconds and reverses. You can return from the other side and open it again. No pickup count decides whether you may enter.

A moving boundary has become a welcome. That welcome, too, has been written: how near you must come, how much room the frame leaves, how long the door waits. What else could these three operations make possible?

<!-- @ -->
'''
final_path.write_text(final,encoding='utf-8')

summary = 'Timed pushers, rotating slabs and synchronised growers change access on level ground. At the exit, two armoured door leaves combine translation, rotation and scale into a passage that opens on approach.'
core = read('commons/data/museum_core_encounters.json')
core['rooms'][MAP]['primary_tokens'].append(TOKEN)
core['rooms'][MAP]['reason']=summary
core['rooms'][MAP]['text_sha256']=hashlib.sha256(final_path.read_bytes()).hexdigest()
core['rooms'][MAP]['map_sha256']=hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()
core['rooms'][MAP]['learner_verified']=False
save('commons/data/museum_core_encounters.json',core)

book=read('commons/data/book/transformation.json')
pearl=next(p for p in book['pearls'] if p['map']==MAP)
pearl['lines'][0]['text']=summary
pearl['lines'].append({'token':TOKEN,'text':re.search(r'<!-- @transformation_airlock -->\s*(.*?)\n\n',final,re.S)[1],'by':'final.md encounter'})
save('commons/data/book/transformation.json',book)

seq=read('commons/maps/sequences/transformation.json')
chapter=seq['sequences']['transformation']
chapter['content']=[MAP+': '+summary if s.startswith(MAP+':') else s for s in chapter['content']]
group=next(g for g in chapter['artifact_groups'] if g['map']==MAP)
group['artifacts'].append(TOKEN)
group['rationale']=summary
save('commons/maps/sequences/transformation.json',seq)
print('Door placed, primary registered, final/book/sequence aligned. Derive museum plan separately.')

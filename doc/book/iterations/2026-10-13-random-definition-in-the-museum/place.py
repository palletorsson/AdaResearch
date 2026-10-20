"""Apply only the requested Random Definition / 10 PRINT placement changes."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
maps = ['Random_Definition', 'Randomness_10_PRINT_Algorithm']

def save_before(path):
    destination = HERE / 'before' / path.relative_to(ROOT)
    destination.parent.mkdir(parents=True, exist_ok=True)
    if not destination.exists(): destination.write_bytes(path.read_bytes())

for name in maps:
    path = ROOT / 'commons/maps' / name / 'map_data.json'
    save_before(path)
    data = json.loads(path.read_text(encoding='utf-8'))
    grid = data['layers']['interactables']
    if name == maps[0]:
        for row in grid:
            for x, token in enumerate(row):
                if token.startswith('textile_comparison'): row[x] = 'random_return'
    else:
        if not any('textile_comparison' in cell for row in grid for cell in row):
            for key, layer in data['layers'].items():
                for _ in range(5): layer.append(['1' if key == 'structure' else ' '] * 13)
            grid[16][6] = 'textile_comparison#controls:compact#control_front:-1.7#control_facing:-z'
            data['map_info']['dimensions']['depth'] = 19
            data['map_info']['metadata']['n_artifacts'] += 1
            data['map_info']['museum']['sculpture_clear_rects'][0][3] = 18
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

path = ROOT / 'commons/data/museum/em_plan.json'
save_before(path)
raw = path.read_text(encoding='utf-8')
data = json.loads(raw)
encode = lambda x: json.dumps(x, ensure_ascii=False, separators=(',', ':'))
for row in data['plans']:
    name = row.get('map')
    if name not in maps: continue
    old = encode(row)
    assert old in raw, 'Plan encoding changed; refusing a whole-plan rewrite'
    if name == maps[0]:
        for artifact in row['artifacts']:
            if artifact['token'] == 'textile_comparison':
                artifact['token'] = 'random_return'
                artifact.pop('config', None)
    elif not any(a['token'] == 'textile_comparison' for a in row['artifacts']):
        # The museum plan has a one-cell expansion around this authored map.
        row['tile'][-1] = ['4'] + ['1'] * 13 + ['4']
        row['tile'].extend([['4']+['1']*13+['4'] for _ in range(4)])
        row['tile'].append(['4']*6+['1']*3+['4']*6)
        row['h'] = len(row['tile'])
        row['room']['h'] = row['h']
        row['_ruling']['src_h'] = 19
        row['interior_count'] = sum(c == '1' for line in row['tile'] for c in line)
        row['artifacts'].append({'token':'textile_comparison','cell':[7,17],'tile_cell':[7,17],
          'rotation':0,'mode':'freestanding','venue':'interior','support_height_m':0.0,'hand':False,
          'ruled':{'by':'map: '+name,'cell':[6,16]},
          'config':{'controls':'compact','control_front':'-1.7','control_facing':'-z'}})
    raw = raw.replace(old, encode(row), 1)
path.write_text(raw,encoding='utf-8')

path = ROOT / 'commons/artifacts/registry/randomness.json'
save_before(path)
raw = path.read_text(encoding='utf-8')
data = json.loads(raw)
if 'random_return' not in data['artifacts']:
    item = {'lookup_name':'random_return','name':'Out / Back — the carried point',
      'scene':'res://commons/artifacts/random_return/random_return.tscn',
      'category':'procedural','sequence':'randomness','map_sequences':['randomness'],
      'map_ready':True,'include_in_map_data':True,'complexity':'beginner',
      'parameters':{'footprint':[7,3.4,7],'size_group':'room_scale'},
      'description':'A seeded direction and distance carry the learned sphere away from its centre and back. Hold to travel with it; release to stay. Replay repeats the destinations.',
      'interactions':['Grip the sphere in VR; right-click to hold or release on desktop','Release before REPLAY or NEXT SEED'],
      'qfep_connection':'Chance chooses a destination inside an authored range; return remains a rule. Holding turns the same bounded choice into a bodily journey.',
      'tags':['randomness','seed','point','sphere','ride','return']}
    entry = json.dumps({'random_return':item},ensure_ascii=False,indent=2)[2:-2]
    raw = raw.replace('"artifacts": {','"artifacts": {\n'+entry+',',1)
    json.loads(raw)
    path.write_text(raw,encoding='utf-8')
print('Placed random_return in Random_Definition; moved textiles into an extended 10 PRINT hall.')

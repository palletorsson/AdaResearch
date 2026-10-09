from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
def read(rel): return json.loads((ROOT/rel).read_text(encoding='utf-8'))
def write(rel,d): (ROOT/rel).write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
rel='commons/maps/Fractal_KochSierpinski/map_data.json'
d=read(rel)
old='sierpinski_pyramid:0:1.0125:0.45#tick:fine'
new='sierpinski_pyramid:180:1.0125:0.45#tick:fine#lesson:true#plinth:0'
assert d['layers']['interactables'][25][6] in [old,new]
d['layers']['interactables'][25][6]=new
write(rel,d)
rel='commons/data/artifact_roles.json'
d=read(rel)
d['roles']['Fractal_KochSierpinski']['sierpinski_pyramid']='primary'
order=d['order']['Fractal_KochSierpinski']
order['secondary']=[x for x in order['secondary'] if x!='sierpinski_pyramid']
if 'sierpinski_pyramid' not in order['primary']:order['primary'].append('sierpinski_pyramid')
write(rel,d)
rel='commons/artifacts/registry/cellular_automata.json'
d=read(rel);r=d['artifacts']['sierpinski_pyramid']
r['description']='Finite recursive cube construction with an inherited six-call recipe. The opt-in lesson compares it with the same recipe minus the extra upper call; depth and leaf size stay fixed.'
r['dna']['default']='tick=dense, packing=contact: depth 4, six recursive calls per nonterminal node, 1296 leaf instances. The inherited call order, leaf coordinates and scales are preserved. With lesson=true, COMPARE gates the extra upper call at every level; at depth 3 the comparison changes 216 leaf instances to 125.'
r['dna']['note']='Packing changes the leaf cube size while preserving recursive centers and instance count. The overall bounds change with cube thickness. This overlapping finite cube construction does not establish the dimension, volume or walkability of an ideal Sierpinski set.'
r['dna']['still_note']='An image alone cannot establish the recursive call count. The lesson exposes one controlled change; ordinary placements retain the inherited six-call construction.'
r['parameters']['lesson']='true adds the compact COMPARE / RULE / RESET desk; omitted keeps the existing sculpture without controls'
r['qfep_connection']='Compare the cost and visible form produced by one additional recursive call. Rule 90 offers a related appearance made by a different procedure; resemblance does not prove computational equivalence or an entropy measure.'
r['interactions']=['With lesson:true, COMPARE toggles the extra upper recursive call at every level.', 'RULE reveals call and leaf-instance counts after inspection.', 'RESET restores the inherited six-call recipe.']
write(rel,d)
print('Promoted existing pyramid and enabled its local comparison; other map cells retained.')

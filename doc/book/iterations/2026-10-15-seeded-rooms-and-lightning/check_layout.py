"""Initial support is explicit; no side bypass is invented by map validation."""
from pathlib import Path
import json, sys, copy
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'tools'))
from map_pathfinder import MapGraph
HERE=Path(__file__).parent
checks=[]
def check(name,result):
    checks.append({'name':name,'passed':bool(result)})
    print(('PASS ' if result else 'FAIL ')+name)
data=json.loads((ROOT/'commons/maps/Random_Remove/map_data.json').read_text(encoding='utf-8'))
graph=MapGraph(data)
check('All 165 tile addresses start with destructible support',len(graph.dynamic_support_cells)==165)
check('Far end reachable in initial state',(25,8) in graph.bfs_flood())
bare=copy.deepcopy(data);bare['layers']['interactables'][17][8]=' '
check('Removing the arena leaves no side bypass',(25,8) not in MapGraph(bare).bfs_flood())
bare['layers']['interactables'][17][8]='random_removal_arena:0:3#columns:15#rows:11'
check('Legacy configuration does not gain new pathfinder semantics',not MapGraph(bare).dynamic_support_cells)
plan=json.loads((ROOT/'commons/data/museum/em_plan.json').read_text(encoding='utf-8'))
row=next(r for r in plan['plans'] if r.get('map')=='Random_Remove')
check('Derived plan keeps every basin cell void',all(row['tile'][z][x]=='0' for z in range(12,23) for x in range(1,16)))
check('Source map keeps every basin cell void',all(str(data['layers']['structure'][z][x])=='0' for z in range(12,23) for x in range(1,16)))
registry=json.loads((ROOT/'commons/artifacts/registry/randomness.json').read_text(encoding='utf-8'))['artifacts']
for token in ['seeded_room','random_removal_arena']:
    check(token+' registry scene exists',(ROOT/registry[token]['scene'].removeprefix('res://')).is_file())
(HERE/'layout-report.json').write_text(json.dumps({'checks':checks,'passed':all(c['passed'] for c in checks)},indent=2),encoding='utf-8')
assert all(c['passed'] for c in checks)

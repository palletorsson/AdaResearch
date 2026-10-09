from pathlib import Path
import hashlib,json,shutil,sys
r=Path.cwd();o=Path(__file__).resolve().parent
maps=['CA_AgentsCircuits','CA_EdgeOfChaos']
files=[p for m in maps for p in (r/'commons/maps'/m).iterdir() if p.suffix in ['.md','.json']]
for folder in ['commons/artifacts/ca_rule_explorer','algorithms/cellularautomata/ca_showcase']:
 files += [p for p in (r/folder).iterdir() if p.suffix in ['.gd','.tscn']]
files += [r/p for p in ['commons/artifacts/registry/commons_artifacts.json','commons/data/museum_core_encounters.json','commons/maps/sequences/cellularautomata.json','commons/data/book/cellularautomata.json','doc/tasks/book_cellularautomata.json','ada_run/em_plan.json']]
assert not (o/'baseline.json').exists();hashes={}
for p in files:
 rel=p.relative_to(r).as_posix();dest=o/'before'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest);hashes[rel]=hashlib.sha256(p.read_bytes()).hexdigest()
(o/'baseline.json').write_bytes((json.dumps(hashes,indent=2)+'\n').encode())
sys.path.insert(0,str(r/'tools'))
from em_map_halls import derive_row,normalize_row
plan=json.loads((r/'ada_run/em_plan.json').read_text());old=next(row for row in plan['plans'] if row.get('map')=='CA_EdgeOfChaos')
new=derive_row(old['pearl'],old['map'],old['museum'],old['pearl_index'],old['pearls_total'],'cellularautomata')
normalize_row(new,True,any(k in new for k in ('basin','passage','simulation')))
assert new['artifacts']==old['artifacts']
assert new['room']==old['room']
diff={k:{'old':old.get(k),'new':new.get(k)} for k in set(old)|set(new) if old.get(k)!=new.get(k)}
(o/'derived-row.json').write_bytes((json.dumps(new,indent=2)+'\n').encode())
(o/'plan-row-diff.json').write_bytes((json.dumps(diff,indent=2)+'\n').encode())
for m in maps:
 for phase in ['before','after']:(o/(m+'-'+phase+'.json')).write_bytes((json.dumps({'room':m,'sequence':'cellularautomata','after':phase=='after'})+'\n').encode())
print('Frozen',len(hashes),'files; derived row changes:',list(diff))

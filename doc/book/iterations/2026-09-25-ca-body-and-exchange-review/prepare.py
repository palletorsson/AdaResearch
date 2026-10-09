from pathlib import Path
import hashlib,json,shutil
r=Path.cwd();o=Path(__file__).resolve().parent
maps=['CA_ExpandingSpace','CA_SoftRules']
files=[p for m in maps for p in (r/'commons/maps'/m).iterdir() if p.suffix in ['.md','.json']]
for folder in ['algorithms/cellularautomata/living_architecture','commons/artifacts/rd_artifact']:
    files += [p for p in (r/folder).iterdir() if p.suffix in ['.gd','.tscn']]
files += [r/p for p in ['commons/data/museum_core_encounters.json','commons/maps/sequences/cellularautomata.json','commons/data/book/cellularautomata.json','doc/tasks/book_cellularautomata.json','ada_run/em_plan.json']]
assert not (o/'baseline.json').exists()
hashes={}
for p in files:
    rel=p.relative_to(r).as_posix();dest=o/'before'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
    hashes[rel]=hashlib.sha256(p.read_bytes()).hexdigest()
(o/'baseline.json').write_bytes((json.dumps(hashes,indent=2)+'\n').encode())
for m in maps:
    for phase in ['before','after']:
        (o/(m+'-'+phase+'.json')).write_bytes((json.dumps({'room':m,'sequence':'cellularautomata','after':phase=='after'})+'\n').encode())
print('Frozen',len(hashes),'files')

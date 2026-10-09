from pathlib import Path
import hashlib,json
r=Path.cwd();o=r/'doc/book/iterations/2026-09-25-ca-opening-review'
maps=['CA_Introduction','CA_ElementaryRules','CA_GameOfLife','CA_BeyondBinary','CA_AgentsCircuits']
files=[p for m in maps for p in (r/'commons/maps'/m).iterdir() if p.suffix in ['.md','.json']]
folders=['commons/artifacts/ca_rule_explorer','commons/artifacts/synthesis','commons/artifacts/lab_room','commons/artifacts/turing_apparatus','commons/grid/mutators']
files += [p for folder in folders for p in (r/folder).iterdir() if p.suffix in ['.gd','.tscn']]
files += [r/p for p in ['commons/maps/sequences/cellularautomata.json','commons/data/book/cellularautomata.json','commons/data/museum_core_encounters.json','doc/tasks/book_cellularautomata.json','doc/book/captures/cellularautomata/cellularautomata-book.md','doc/book/captures/cellularautomata/cellularautomata-book.manifest.json','ada_run/em_plan.json']]
assert not (o/'baseline.json').exists()
hashes={}
for p in files:
 rel=p.relative_to(r).as_posix();dest=o/'before'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes());hashes[rel]=hashlib.sha256(p.read_bytes()).hexdigest()
(o/'baseline.json').write_bytes((json.dumps(hashes,indent=2)+'\n').encode())
print('Frozen',len(hashes),'sources')

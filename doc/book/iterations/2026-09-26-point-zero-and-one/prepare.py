from pathlib import Path
import hashlib, json, shutil

r = Path.cwd()
o = Path(__file__).resolve().parent
paths = [p for m in ['Point_Zero', 'Point_One'] for p in (r/'commons/maps'/m).iterdir() if p.suffix in ['.md', '.json']]
paths += [r/p for p in [
    'commons/maps/sequences/primitives.json', 'commons/data/map_authored.json',
    'commons/data/book/primitives.json', 'commons/data/artifact_roles.json',
    'commons/data/museum_core_encounters.json', 'commons/artifacts/registry/commons_artifacts.json',
    'commons/scenes/endless_museum.tscn', 'ada_run/em_plan.json',
    'doc/book/iterations/2026-09-25-private-writing-notes/halls/Point_One.md',
]]
assert not (o/'baseline.json').exists()
hashes = {}
for p in paths:
    rel = p.relative_to(r).as_posix()
    dest = o/'before'/rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(p, dest)
    hashes[rel] = hashlib.sha256(p.read_bytes()).hexdigest()
(o/'baseline.json').write_text(json.dumps(hashes, indent=2)+'\n', encoding='utf-8')
print('Frozen', len(hashes), 'files')

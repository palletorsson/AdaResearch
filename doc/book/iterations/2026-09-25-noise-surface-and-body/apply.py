from pathlib import Path
import hashlib, json
r=Path.cwd();o=r/'doc/book/iterations/2026-09-25-noise-surface-and-body'
maps=['Noise_6_Wall','Noise_Inside_Noise','Noise_Space_10']
files=[p.relative_to(r).as_posix() for m in maps for p in (r/'commons/maps'/m).iterdir() if p.suffix in ['.md','.json']]
for folder in ['algorithms/randomness/noisesphere','algorithms/randomness/shadernoisespace']:
    files += [p.relative_to(r).as_posix() for p in (r/folder).iterdir() if p.suffix in ['.gd','.tscn','.gdshader']]
files += ['commons/context/walkgrids/NoiseSpace.gd','commons/context/walkgrids/TopologySpace.gd','commons/context/walkgrids/noise_walk_study.gd','commons/context/walkgrids/noise_walk_trace.gd','commons/context/walkgrids/noise_scale_portals.gd','commons/scenes/endless_museum.gd','commons/data/museum_core_encounters.json','commons/maps/sequences/noise.json','commons/data/book/noise.json','doc/tasks/book_noise.json','doc/book/captures/noise/noise-book.md','doc/book/captures/noise/noise-book.manifest.json']
assert not (o/'baseline.json').exists()
hashes={}
for rel in files:
    p=r/rel;dest=o/'before'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes());hashes[rel]=hashlib.sha256(p.read_bytes()).hexdigest()
(o/'baseline.json').write_bytes((json.dumps(hashes,indent=2)+'\n').encode())
def replace(rel,a,b):
    p=r/rel;s=p.read_text(encoding='utf-8-sig');assert s.count(a)==1,(rel,a);p.write_bytes(s.replace(a,b).encode('utf-8'))
replace('commons/maps/Noise_6_Wall/final.md',
    'What the player can physically cross and what the player imagines crossing need not arrive together.',
    'What your body can cross and what you imagine crossing need not arrive together.')
replace('commons/maps/Noise_6_Wall/final.md',
    'Any two sums of 0.5 or more would become the same white, although when the four windows were measured at one held moment, even their brightest pixel reached only about half-white.',
    'Any two sums of 0.5 or more would become the same white.')
replace('commons/maps/Noise_Space_10/final.md','In the recorded desktop walk, the first crossing reached the far margin.','In one recorded walk, the first crossing reached the far margin.')
replace('commons/maps/Noise_Space_10/final.md','The recorded desktop body accepted floor angles up to forty-five degrees.','The controller in that walk accepted floor angles up to forty-five degrees.')
replace('commons/maps/Noise_Space_10/final.md','HEIGHT and RESET refuse while a player body is still on the patch:','HEIGHT and RESET refuse while your body is still on the patch:')
print('Baseline frozen; five sentence edits in two chapters. Inside Noise retained unchanged.')

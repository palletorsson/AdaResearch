"""Freeze this opening hall before revision; never replace an existing baseline."""
from pathlib import Path
import hashlib, json, shutil
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-lsystems-a-sentence-and-a-reading'
assert not (O/'before').exists(), 'Baseline already exists; do not overwrite it.'
paths=['commons/maps/LSystems_Grammar_Lab/'+n for n in ['tutorial.md','final.md','technical.md','map_data.json']]
paths+=['commons/artifacts/lsystem_editor/lsystem_editor.gd','commons/artifacts/grammar_lesson/grammar_lesson.gd','commons/maps/sequences/lsystems.json','doc/book/course/execution-plan/plan.json']
hashes={}
for name in paths:
    source=R/name; dest=O/'before'/name; dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(source,dest); hashes[name]=hashlib.sha256(source.read_bytes()).hexdigest()
(O/'before-hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
sequence=json.loads((R/'commons/maps/sequences/lsystems.json').read_text(encoding='utf-8'))
maps=sequence.get('maps') or next(iter(sequence['sequences'].values()))['maps']
inventory=[]
for name in maps:
    folder=R/'commons/maps'/name
    tutorial=(folder/'tutorial.md').read_text(encoding='utf-8') if (folder/'tutorial.md').exists() else ''
    inventory.append({'hall':name,'tutorial_exists':bool(tutorial),'code_blocks':tutorial.count('```gdscript'),'complete_file_markers':tutorial.count('student-code:'),'words':len(tutorial.split())})
(O/'sequence-inventory.json').write_text(json.dumps(inventory,indent=2),encoding='utf-8')
print(json.dumps(inventory,indent=2))

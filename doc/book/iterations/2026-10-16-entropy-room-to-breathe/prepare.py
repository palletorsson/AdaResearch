from pathlib import Path
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
paths = [
    'commons/artifacts/ordinary_entropies/chair_reference.gd',
    'commons/artifacts/registry/ordinary_entropies.json',
]
for name in ['Random_Entropies', 'Random_Entropy']:
    paths += [f'commons/maps/{name}/{file}' for file in ['final.md','tutorial.md','writing_wall.json','map_data.json','plan.md','summary.md','artifacts.md']]
for path in paths:
    target = HERE/'before'/path
    if not target.exists():
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT/path, target)
print('Retained current chapters, map metadata and chair source before this revision.')

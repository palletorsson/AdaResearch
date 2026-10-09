"""Copy the canonical artifacts into the independent teaching project."""
from pathlib import Path
import shutil
import json
import hashlib

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SOURCE = ROOT / 'commons/artifacts/reference_studies'
IDS = ['suspension','passage','landscape','pattern_garden','plural_body']
for name in IDS:
    scene = f'''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="{name}.gd" id="1"]
[node name="{name}" type="Node3D"]
script = ExtResource("1")
'''
    (SOURCE / f'{name}.tscn').write_text(scene, encoding='utf-8')
(HERE / 'artifacts').mkdir(exist_ok=True)
manifest = {}
for path in sorted(SOURCE.iterdir()):
    if path.suffix in ['.gd','.gdshader','.tscn']:
        shutil.copyfile(path, HERE / 'artifacts' / path.name)
        manifest[path.name] = hashlib.sha256(path.read_bytes()).hexdigest()
(HERE / 'source-hashes.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
print(f'Prepared {len(manifest)} canonical artifact sources.')

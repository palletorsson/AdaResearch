"""Publish the reviewed prototype to the sibling local Encyclopedia."""
from pathlib import Path
import shutil
root = Path(__file__).resolve().parents[1]
source = root / 'commons/artifacts/biome_primitives'
target = root.parent / 'ada_encyclopedia/public/biome-primitives'
assert target.parent.parent.name == 'ada_encyclopedia'
target.mkdir(parents=True, exist_ok=True)
for file in (source/'web').iterdir():
    if file.is_file(): shutil.copyfile(file, target/file.name)
shutil.copyfile(source/'pilot.json', target/'pilot.json')
for file in (root/'ada_run/biome_primitives/captures').glob('*.png'):
    shutil.copyfile(file, target/file.name)
for file in (root/'ada_run/biome_primitives/inside').glob('*.png'):
    shutil.copyfile(file, target/('inside_'+file.name))
for study in ['hinge','scale']:
    for file in (root/'ada_run/biome_primitives'/study).glob('*'):
        if file.suffix in ['.png','.mp4']: shutil.copyfile(file,target/file.name)
print('http://127.0.0.1:3003/biome-primitives/index.html')

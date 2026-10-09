"""Copy canonical fabrication byte-for-byte into the independent Godot project."""
from pathlib import Path
import hashlib, json, shutil
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
FILES = [
    'commons/artifacts/suspension_passage/score.gd',
    'commons/artifacts/suspension_passage/suspension_passage.gd',
    'commons/artifacts/suspension_passage/suspension_passage.tscn',
    'commons/artifacts/suspension_passage/stone.gdshader',
    'commons/artifacts/reference_studies/build.gd',
    'commons/artifacts/reference_studies/suspension.gd',
    'commons/artifacts/reference_studies/grain.gdshader',
]
def sync():
    hashes = {}
    for name in FILES:
        target = HERE / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / name, target)
        hashes[name] = hashlib.sha256(target.read_bytes()).hexdigest()
    (HERE/'source-hashes.json').write_text(json.dumps(hashes, indent=2)+'\n', encoding='utf-8')
    print(f'{len(hashes)} canonical sources copied exactly')
if __name__ == '__main__':
    sync()

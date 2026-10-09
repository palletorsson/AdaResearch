"""Copy only the specimen and its three local dependencies, byte-for-byte."""
from pathlib import Path
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SOURCES = [
    'commons/artifacts/bicho_hinge/bicho_hinge.gd',
    'commons/render/pbr_kit.gd',
    'commons/ui/text_screen.gd',
    'commons/utils/baked_text_albedo.gd',
]

def sync():
    records = []
    for source in SOURCES:
        original = ROOT / source
        target = HERE / source
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(original.read_bytes())
        digest = hashlib.sha256(target.read_bytes()).hexdigest()
        records.append(dict(source=source, portable=source, sha256=digest, exact_copy=True))
    (HERE / 'source-hashes.json').write_text(json.dumps(records, indent=2) + '\n', encoding='utf-8')

if __name__ == '__main__':
    sync()

"""Copy canonical artifact code into the portable project; record exact provenance."""
from pathlib import Path
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SOURCES = {
    'build.gd': 'commons/artifacts/reference_studies/build.gd',
    'score.gd': 'commons/artifacts/signal_room/score.gd',
    'signal_room.gd': 'commons/artifacts/signal_room/signal_room.gd',
    'signal_room.tscn': 'commons/artifacts/signal_room/signal_room.tscn',
}

def sync():
    (HERE / 'artifacts').mkdir(exist_ok=True)
    hashes = []
    for name, source in SOURCES.items():
        data = (ROOT / source).read_text(encoding='utf-8')
        for target, original in SOURCES.items():
            data = data.replace('res://' + original, 'res://artifacts/' + target)
        output = HERE / 'artifacts' / name
        output.write_text(data, encoding='utf-8', newline='\n')
        hashes.append(dict(source=source, source_sha256=hashlib.sha256((ROOT/source).read_bytes()).hexdigest(),
                           portable='artifacts/'+name, portable_sha256=hashlib.sha256(output.read_bytes()).hexdigest()))
    (HERE/'source-hashes.json').write_text(json.dumps(hashes, indent=2)+'\n', encoding='utf-8')

if __name__ == '__main__':
    sync()

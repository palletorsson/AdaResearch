"""Snapshot the existing twelve-hall route before the next tutorial pass."""
from pathlib import Path
import hashlib, json, shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-08-wavefunctions-what-returns'

def main():
    sequence_path = ROOT / 'commons/maps/sequences/wavefunctions.json'
    data = json.loads(sequence_path.read_text(encoding='utf8'))
    sequence = data['sequences']['wavefunctions']
    print(json.dumps(sequence, ensure_ascii=False)[:1200])
    maps = sequence.get('maps', sequence.get('map_order', []))
    manifest = {}
    paths = [sequence_path, ROOT/'doc/book/course/execution-plan/plan.json']
    for item in maps:
        name = item if isinstance(item, str) else item['map']
        paths += [ROOT/'commons/maps'/name/file for file in ['tutorial.md','final.md','map_data.json']]
    for path in paths:
        dest = OUT/'before'/path.relative_to(ROOT)
        if not dest.exists():
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, dest)
        manifest[path.relative_to(ROOT).as_posix()] = hashlib.sha256(dest.read_bytes()).hexdigest()
    (OUT/'before/source-sha256.json').write_text(json.dumps(manifest, indent=2), encoding='utf8')
    print('Snapshot:', len(manifest), 'files')

if __name__ == '__main__': main()

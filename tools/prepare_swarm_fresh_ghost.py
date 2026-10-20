"""Freeze a reading-only packet for a fresh-context student agent."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import zipfile

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-11-swarm-fresh-ghost-student'
PACK = R / 'doc/book/iterations/2026-10-11-swarm-tightened-readings/swarm-review.zip'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def put(p, data):
    p.parent.mkdir(parents=True, exist_ok=True)
    assert not p.exists(), p
    p.write_bytes(data)


assert not (O / 'input-manifest.json').exists(), 'Preserve the first student input.'
with zipfile.ZipFile(PACK) as bundle:
    manifest = json.loads(bundle.read('manifest.json'))
    rows = []
    for row in manifest:
        hall = row['hall']
        entry = {'hall': hall, 'name': row['name'], 'order': row['order'], 'files': {}}
        for kind in ['tutorial', 'final']:
            data = bundle.read(f'canonical/{hall}/{kind}.md')
            assert sha(data) == row['texts'][kind]['sha256']
            p = O / 'input/halls' / hall / (kind + '.md')
            put(p, data)
            entry['files'][kind] = {'path': p.relative_to(R).as_posix(), 'sha256': sha(data)}
        image = bundle.read(f'assets/{row["order"]}.png')
        assert sha(image) == row['image_sha256']
        put(O / 'input/images' / f'{row["order"]}.png', image)
        entry['image_sha256'] = sha(image)
        rows.append(entry)
    # Only the assignment, without the earlier investigation or its answers.
    brief = bundle.read('OPEN-STUDY.md')
    put(O / 'input/OPEN-STUDY.md', brief)
protected = json.loads((R / 'doc/book/iterations/2026-10-11-swarm-tightened-readings/before/protected-hashes.json').read_text(encoding='utf-8'))
for row in manifest:
    for item in row['texts'].values():
        protected[item['path']] = item['sha256']
assert all(sha((R / path).read_bytes()) == expected for path, expected in protected.items())
data = {'created': datetime.now(timezone.utc).isoformat(), 'package': PACK.relative_to(R).as_posix(),
        'package_sha256': sha(PACK.read_bytes()), 'halls': rows, 'protected': protected,
        'withheld': ['earlier author tests', 'earlier ghost outcomes', 'prebuilt lesson scripts/scenes', 'review verdicts', 'conversation history'],
        'scope': 'Fresh-context agent with task-enforced reading limits, not filesystem access isolation. Shared prepared Godot project supplies declared dependencies.'}
put(O / 'input-manifest.json', (json.dumps(data, indent=2) + '\n').encode())
route = '# Swarm — fresh student input\n\nRead these seven tutorial/final pairs in order. Each image records the installed museum encounter. Reconstruct from the printed code, not prebuilt lesson scripts.\n\n'
for row in rows:
    route += f'{row["order"]}. {row["name"]}: `halls/{row["hall"]}/tutorial.md` and `final.md`; `images/{row["order"]}.png`.\n'
route += '\nThe optional OPEN-STUDY.md supplies a research exercise. Its link to prior results is withheld for this session. Do not follow it. Choose your own additional variation rather than replaying a supplied answer.\n'
put(O / 'input/START.md', route.encode())
print('Frozen seven pairs, seven images and the optional assignment; no answer files included.')

"""Apply the accepted reading proposals only while their captured sources match."""
from pathlib import Path
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
hashes = json.loads((HERE / 'before-sha256.json').read_text(encoding='utf-8'))
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
pending = []
for proposal in sorted((HERE / 'proposed').glob('*.md')):
    name = proposal.stem
    target = ROOT / f'commons/maps/{name}/final.md'
    if target.read_text(encoding='utf-8') == proposal.read_text(encoding='utf-8'):
        continue
    assert sha(target) == hashes[name], f'{name} changed after the proposal; reconcile before applying'
    data = proposal.read_bytes()
    old = target.read_bytes()
    if old.count(b'\r\n') == old.count(b'\n') and b'\n' in old:
        data = data.replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')
    pending.append((target, data))
for target, data in pending:
    target.write_bytes(data)
record = {
    'date': '2026-09-19',
    'status': 'applied',
    'basis': 'Author continued after the four passage proposals and the discussion of investigative voice.',
    'chapters': {
        p.stem: {'before_sha256': hashes[p.stem], 'after_sha256': sha(ROOT / f'commons/maps/{p.stem}/final.md')}
        for p in sorted((HERE / 'proposed').glob('*.md'))
    },
    'scope': 'Four final.md chapters only. No source, artifact or map changes; no new runtime claims.'
}
(HERE / 'applied.json').write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
print(f'Applied {len(pending)} Noise chapters; original versions retained.')

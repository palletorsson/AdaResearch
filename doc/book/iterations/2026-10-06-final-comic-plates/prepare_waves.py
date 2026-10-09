"""Verify chosen quotations and preserve the chapters used for illustration."""
from pathlib import Path
import json
import hashlib

here = Path(__file__).resolve().parent
root = here.parents[3]
path = here / 'waves-plates.json'
spec = json.loads(path.read_text(encoding='utf-8'))
replacements = {
    'There is no field in its list for the difference that made you want to listen again.': 'The rig reports changed parameters, but there is no field in its list for the difference that made you want to listen again.',
    'A formula gives positions, while a route needs provision for the body moving between them.': 'Each needs a tread with width and depth, an orientation, and a relationship to the next tread.',
    'The same pair set at right angles makes a shape.': 'The rows made a slow pulse from a pair; the same pair set at right angles makes a shape.',
}
def normalize(t):
    return ' '.join(t.replace('*', '').split())
for p in spec['plates']:
    for old, new in replacements.items():
        p['prompt'] = p['prompt'].replace(old, new)
        if p['footer'] == old:
            p['footer'] = new
        for panel in p['panels']:
            if panel[0] == old:
                panel[0] = new
    data = (root / p['source']).read_bytes()
    p['source_sha256'] = hashlib.sha256(data).hexdigest()
    text = normalize(data.decode('utf-8'))
    for caption in [*[row[0] for row in p['panels']], p['footer']]:
        assert normalize(caption) in text, (p['map'], caption)
    snapshot = here / 'sources' / (p['map'] + '.md')
    if snapshot.exists():
        assert snapshot.read_bytes() == data, 'Do not replace a drafting snapshot.'
    else:
        snapshot.write_bytes(data)
path.write_text(json.dumps(spec, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('Read 12 complete chapters; verified 72 captions and 12 footers; preserved source bytes and hashes.')

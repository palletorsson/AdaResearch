"""Collect the current reflective track without editing any chapter."""
import json
from build import HERE, ROOT, put, sha, shell, render

sequence = json.loads((ROOT / 'commons/maps/sequences/transformation.json').read_text(encoding='utf-8'))
halls = sequence['sequences']['transformation']['maps']
parts = ['# Transformation — the reflective sequence\n\nCollected 6 October 2026. The seven current `final.md` chapters, in spine order, with their writing unchanged. The proposed editorial refinements have not been applied.\n']
sources = {}
for hall in halls:
    source = ROOT / 'commons/maps' / hall / 'final.md'
    sources[source.relative_to(ROOT).as_posix()] = sha(source)
    text = source.read_text(encoding='utf-8')
    parts.append('\n\n---\n\n<!-- hall:' + hall + ' -->\n\n' + text)
collected = '\n'.join(parts)
put(HERE / 'ALL_FINAL.md', collected)
for path, digest in sources.items():
    assert sha(ROOT / path) == digest, path
    assert (ROOT / path).read_text(encoding='utf-8') in collected
assert collected.count('<!-- hall:') == len(halls) == 7
navigation = '<a href="index.html">Overview</a><a href="ALL_FINAL.md">Final texts · Markdown</a><a href="all.html">Tutorial sequence</a>'
page = shell('Transformation — complete reflective sequence', render(collected), navigation)
page = page.replace('Endless Museum · Transformation · Review draft', 'Endless Museum · Transformation · Reflective sequence')
put(HERE / 'final.html', page)
put(HERE / 'final-collection.json', json.dumps({'date': '2026-10-06', 'order': halls, 'sources': sources, 'output_sha256': sha(HERE / 'ALL_FINAL.md'), 'chapter_text_preserved': True}, indent=2) + '\n')
print('Collected seven unchanged final.md chapters into ALL_FINAL.md and final.html.')

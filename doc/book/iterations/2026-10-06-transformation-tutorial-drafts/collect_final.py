"""Collect revised reflective drafts; preserve the canonical manuscripts."""
import json
from build import HERE, ROOT, HALLS, put, sha, shell, render

sequence = json.loads((ROOT / 'commons/maps/sequences/transformation.json').read_text(encoding='utf-8'))
halls = sequence['sequences']['transformation']['maps']
assert halls == HALLS
parts = ['# Transformation — the reflective sequence\n\n6 October 2026 · Revised drafts for paired reading and independent review. Repeated procedural explanations have been shortened. These revisions have not replaced the canonical manuscripts.\n']
sources = {}
for hall in halls:
    source = HERE / hall / 'final.md'
    sources[source.relative_to(ROOT).as_posix()] = sha(source)
    text = source.read_text(encoding='utf-8')
    parts.append('\n\n---\n\n<!-- hall:' + hall + ' -->\n\n' + text)
collected = '\n'.join(parts)
put(HERE / 'ALL_FINAL.md', collected)
for path, digest in sources.items():
    assert sha(ROOT / path) == digest, path
    assert (ROOT / path).read_text(encoding='utf-8') in collected
assert collected.count('<!-- hall:') == len(halls) == 7
navigation = '<a href="index.html">Overview</a><a href="paired.html">Facing texts</a><a href="ALL_FINAL.md">Reflections · Markdown</a><a href="all.html">Tutorial sequence</a><a href="changes.html">Changes</a>'
page = shell('Transformation — complete reflective sequence', render(collected), navigation)
put(HERE / 'final.html', page)
put(HERE / 'final-collection.json', json.dumps({'date': '2026-10-06', 'status': 'revised-drafts-awaiting-review', 'order': halls, 'sources': sources, 'output_sha256': sha(HERE / 'ALL_FINAL.md'), 'draft_chapter_text_preserved_in_collection': True}, indent=2) + '\n')
print('Collected seven revised reflective drafts; canonical manuscripts preserved.')

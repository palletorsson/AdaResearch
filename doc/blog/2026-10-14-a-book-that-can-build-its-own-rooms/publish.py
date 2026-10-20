"""Publish the supplied writing-apparatus essay to the local encyclopedia."""
from pathlib import Path
import hashlib
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
APP = ROOT.parent / 'ada_encyclopedia'
SLUG = HERE.name
SOURCE = Path('C:/Users/palle/.codex/attachments/7efd2d10-b448-4058-8e60-066dc49fde18/Pasted text.txt')

sources = {
    'glass-close.png': (
        ROOT / 'doc/book/iterations/2026-10-13-random-glass/glass-close.png',
        'Actual Godot capture of the current glass grids in Random Definition',
    ),
    'writing-routes.png': (
        ROOT / 'doc/book/iterations/2026-10-13-random-definition-two-routes/comparison.png',
        'Browser capture of an earlier two-draft writing study, not a game capture',
    ),
}

receipts = []
for name, (source, description) in sources.items():
    data = source.read_bytes()
    for destination in [HERE / 'images' / name, APP / 'public/book-images/blog' / SLUG / name]:
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        assert destination.read_bytes() == data
    receipts.append({
        'file': name,
        'source': source.relative_to(ROOT).as_posix(),
        'sha256': hashlib.sha256(data).hexdigest(),
        'description': description,
    })

original = HERE / 'submitted-essay.md'
if SOURCE.exists():
    original.write_bytes(SOURCE.read_bytes())
assert original.exists(), 'Keep the submitted essay with the edited post.'

post = HERE / 'post.md'
text = post.read_text(encoding='utf-8')
for target in re.findall(r'\]\((/book-images/[^)]+)', text):
    assert (APP / 'public' / target.lstrip('/')).exists(), target
for target in re.findall(r'\]\(/blog/([^)#]+)', text):
    assert (APP / 'src/content/blog' / f'{target}.md').exists(), target

destination = APP / 'src/content/blog' / f'{SLUG}.md'
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_bytes(post.read_bytes())
assert destination.read_bytes() == post.read_bytes()

(HERE / 'publication.json').write_text(json.dumps({
    'date': '2026-10-14',
    'url': f'http://localhost:3003/blog/{SLUG}',
    'source': 'post.md',
    'submitted_essay': 'submitted-essay.md',
    'submitted_essay_sha256': hashlib.sha256(original.read_bytes()).hexdigest(),
    'post_sha256': hashlib.sha256(post.read_bytes()).hexdigest(),
    'local_publication': str(destination),
    'images': receipts,
    'editorial_changes': [
        'Opening reflects the current glass grids; the sleeve began with the earlier cubes.',
        'The sleeve and further experiments remain explicitly proposed, not built.',
        'Distinguishes conjecture, executable observations and embodied experience.',
        'Retains learning debt, dissipated authorship and the text-code-observation loop.',
        'Keeps the supplied essay alongside the edited publication.',
    ],
    'scope': 'Local encyclopedia blog; no changes to hall tutorials or finals.',
}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

print(f'Published locally: http://localhost:3003/blog/{SLUG}')

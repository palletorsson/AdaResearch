"""Publish an edited blog from the supplied ZIP without installing its proposals."""
from pathlib import Path
from zipfile import ZipFile
import hashlib
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
APP = ROOT.parent / 'ada_encyclopedia'
SLUG = HERE.name
SUBMITTED = Path('C:/Users/palle/Downloads/Ada_Final_Critical_Knowledge_Strategy_2026-10-14.zip')
ARCHIVED = HERE / 'source-package.zip'
MEMBER = 'ada_final_critical_composition/BLOG_Writing_at_the_Edge_of_the_Simulation.md'

if SUBMITTED.exists():
    shutil.copyfile(SUBMITTED, ARCHIVED)
assert ARCHIVED.exists()
with ZipFile(ARCHIVED) as package:
    (HERE / 'submitted-blog.md').write_bytes(package.read(MEMBER))

images = {
    'glass-close.png': ROOT / 'doc/book/iterations/2026-10-13-random-glass/glass-close.png',
    'five-spatial-views.png': ROOT / 'ada_run/encounter_pilot/Random_Definition/seed-bench-001-space-views/five-spatial-views.png',
}
receipts = []
for name, source in images.items():
    data = source.read_bytes()
    for destination in [HERE / 'images' / name, APP / 'public/book-images/blog' / SLUG / name]:
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
        assert destination.read_bytes() == data
    receipts.append({'file': name, 'source': source.relative_to(ROOT).as_posix(),
                     'sha256': hashlib.sha256(data).hexdigest(), 'kind': 'actual Godot capture'})

post = HERE / 'post.md'
text = post.read_text(encoding='utf-8')
assert '\ufffd' not in text
for target in re.findall(r'\]\((/book-images/[^)]+)', text):
    assert (APP / 'public' / target.lstrip('/')).exists(), target
for target in re.findall(r'\]\((/book-review/[^)#]+)', text):
    assert (ROOT / target.removeprefix('/book-review/')).exists(), target
for target in re.findall(r'\]\(/blog/([^)#]+)', text):
    assert (APP / 'src/content/blog' / f'{target}.md').exists(), target

destination = APP / 'src/content/blog' / f'{SLUG}.md'
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_bytes(post.read_bytes())
assert destination.read_bytes() == post.read_bytes()

checked_sources = [
    'doc/book/experiments/random-definition/seed-bench-001/runtime/seed_record.gd',
    'doc/book/experiments/random-definition/seed-bench-001/SPATIAL_VIEWS.md',
    'doc/book/experiments/random-definition/seed-bench-001/observations.md',
    'doc/book/course/randomness-research-2026-10-14/implementation/003/evidence/museum-space-views.json',
    'commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.gd',
    'commons/maps/Random_Entropy/final.md',
]
(HERE / 'publication.json').write_text(json.dumps({
    'date': '2026-10-14', 'url': f'http://localhost:3003/blog/{SLUG}',
    'source': 'post.md', 'local_publication': str(destination),
    'submitted_archive': 'source-package.zip',
    'submitted_archive_sha256': hashlib.sha256(ARCHIVED.read_bytes()).hexdigest(),
    'submitted_blog': 'submitted-blog.md', 'submitted_member': MEMBER,
    'post_sha256': hashlib.sha256(post.read_bytes()).hexdigest(),
    'images': receipts,
    'checked_sources': [{'path': p, 'sha256': hashlib.sha256((ROOT / p).read_bytes()).hexdigest()} for p in checked_sources],
    'historical_source': 'https://www.rand.org/pubs/monograph_reports/MR1418.html',
    'editorial_changes': [
        'Retains edge, leak, technical bias, attachment, research pools and paragraph routes.',
        'Uses the current glass grids in the opening; the sleeve originated with cubes.',
        'Updates the proposal-only pilot account to the existing five-view implementation and recorded desktop checks.',
        'Keeps the sleeve and ghost-reader protocol explicitly prospective; distinguishes human reception from technical evidence.',
        'Includes two actual museum captures and links to the preceding essay and experiment notes.',
    ],
    'scope': 'Blog publication only. Archive instructions and proposed tasks were treated as source material, not executed or installed. No hall tutorials or finals changed.',
}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'Published locally: http://localhost:3003/blog/{SLUG}')

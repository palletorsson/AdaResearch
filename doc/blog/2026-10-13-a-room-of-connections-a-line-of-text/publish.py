"""Publish the writing journal to the local encyclopedia with traceable images."""
from pathlib import Path
import hashlib
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
APP = ROOT.parent/'ada_encyclopedia'
SLUG = HERE.name
REVIEW = ROOT/'doc/book/iterations/2026-10-13-random-definition-in-the-museum'
GRID = ROOT/'ada_run/encounter_pilot/Random_Definition/four-by-four-20261013'
report = json.loads((GRID/'report.json').read_text(encoding='utf8'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
sources = {
    'seed-after.png': GRID/'seed-after.png',
    'two-routes.png': ROOT/'doc/book/iterations/2026-10-13-random-definition-two-routes/comparison.png',
    'sphere-out.png': REVIEW/'images/sphere-out.png',
}
receipts = []
for name, source in sources.items():
    for destination in [HERE/'images'/name, APP/'public/book-images/blog'/SLUG/name]:
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        assert destination.read_bytes() == source.read_bytes()
    receipts.append({'file':name, 'source':source.relative_to(ROOT).as_posix(),
                     'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
                     'kind':'earlier browser reading trial' if name=='two-routes.png' else 'actual Godot screenshot'})
post = (HERE/'post.md').read_text(encoding='utf8')
for target in re.findall(r'\]\((/book-review/[^)#]+)', post):
    assert (ROOT/target.removeprefix('/book-review/')).exists(), target
for target in re.findall(r'\]\((/book-images/[^)]+)', post):
    assert (APP/'public'/target.lstrip('/')).exists(), target
destination = APP/'src/content/blog'/f'{SLUG}.md'
destination.write_bytes((HERE/'post.md').read_bytes())
assert destination.read_bytes() == (HERE/'post.md').read_bytes()
(HERE/'publication.json').write_text(json.dumps({
    'date':'2026-10-13', 'url':f'http://localhost:3003/blog/{SLUG}',
    'source':'post.md', 'local_publication':str(destination), 'images':receipts,
    'grid_report':str((GRID/'report.json').relative_to(ROOT)),
    'student_report':'doc/book/iterations/2026-10-13-four-by-four-seed/student/tests.json',
    'scope':'Local encyclopedia post; no external social publication or student-comprehension claim.'
},ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print(f'Published locally: http://localhost:3003/blog/{SLUG}')

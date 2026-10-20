"""Publish hall photographs + declared carry text beside the existing relation snapshot.

This is a browser companion. It does not change lessons, the spine or the VR exhibit.
Edit carry text in execution-plan/plan.json; curate photographs in atlas-images.json.
"""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import subprocess
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / 'doc/book/course/atlas'
PUBLIC = ROOT.parent / 'ada_encyclopedia/public/research/ada-relations'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def link(path):
    return '/book-review/' + path.relative_to(ROOT).as_posix()


def photograph(path, evidence, output):
    """Only resize native captures for delivery; keep full source and receipt links."""
    source = ROOT / path
    digest = sha(source)
    name = digest[:20] + '.webp'
    target = output / 'images' / name
    if not target.exists():
        with Image.open(source) as picture:
            picture.thumbnail((1200, 800))
            picture.convert('RGB').save(target, 'WEBP', quality=85)
    return {'src': 'images/' + name, 'source': path, 'original': link(source),
            'evidence': evidence, 'receipt': link(ROOT / evidence) if evidence else None,
            'sha256': digest,
            'saved': datetime.fromtimestamp(source.stat().st_mtime, timezone.utc).date().isoformat()}


def candidates(mid, inventory):
    choices = []
    base = ROOT / 'ada_run/encounter_pilot'
    for folder in base.iterdir():
        if not folder.is_dir() or not (folder.name == mid or folder.name.startswith(mid + '_')):
            continue
        for specpath in folder.rglob('spec.json'):
            if any('before' in p.lower() for p in specpath.relative_to(folder).parts):
                continue
            try:
                spec = read(specpath)
                reportpath = specpath.parent / 'report.json'
                report = read(reportpath) if reportpath.exists() else {}
            except (ValueError, OSError):
                continue
            if spec.get('room') != mid or report.get('passed') is False:
                continue
            # Each photo is backed by a room-specific native capture spec.
            for p in specpath.parent.glob('*.png'):
                if any(term in p.stem for term in ['before', 'student', 'learner', 'atlas-', 'study-', 'fault']):
                    continue
                choices.append((p, specpath))
    for item in inventory.get(mid, {}).get('images', []):
        p = ROOT / item['path']; evidence = ROOT / item['evidence']
        if p.exists() and evidence.exists() and 'before' not in p.as_posix():
            choices.append((p, evidence))
    # Newest capture session first; then prefer a readable room/encounter view.
    def score(pair):
        p, _ = pair
        day = int(p.stat().st_mtime // 86400)
        preference = {'entry': 8, 'inside': 9, 'room': 10, 'clean-hall': 11,
                      'museum-encounter': 10, 'museum-entry': 8, 'workshop-revised': 12}
        priority = preference.get(p.stem, 1)
        if 'above' in p.stem: priority = 0
        return (day, priority, p.stat().st_mtime)
    return sorted(set(choices), key=score, reverse=True)


def publish():
    CONTENT.mkdir(parents=True, exist_ok=True)
    (PUBLIC / 'images').mkdir(parents=True, exist_ok=True)
    # Refresh the browser's relations without rewriting a tested native snapshot.
    data_path = PUBLIC / 'relations.json'
    subprocess.run([sys.executable, str(ROOT / 'tools/build_ada_relations.py'), '--output', str(data_path)], check=True)
    data = read(data_path)
    planpath = ROOT / 'doc/book/course/execution-plan/plan.json'
    lessons = {h['id']: h for h in read(planpath)['lessons']}
    inventory = {h['id']: h for h in read(ROOT / 'doc/book/course/storyboards/inventory.json')['halls']}
    choicespath = CONTENT / 'atlas-images.json'
    choices = read(choicespath) if choicespath.exists() else {}
    allmaps = [m for n in data['nodes'] for m in n['maps']]
    halls = []
    for seq in data['nodes']:
        for index, mid in enumerate(seq['maps']):
            lesson = lessons.get(mid, {})
            options = candidates(mid, inventory)
            curated = choices.get(mid)
            if curated:
                chosen = [(ROOT / curated['path'], ROOT / curated['evidence'])]
                assert all(p.is_file() for p in chosen[0]), mid
            else:
                chosen = options[:1]
            photo = photograph(*[p.relative_to(ROOT).as_posix() for p in chosen[0]], PUBLIC) if chosen else None
            above = next((pair for pair in options if 'above' in pair[0].stem), None)
            overhead = photograph(*[p.relative_to(ROOT).as_posix() for p in above], PUBLIC) if above else None
            i = allmaps.index(mid)
            carry = lesson.get('carry', '').strip()
            hall = {'id': mid, 'sequence': seq['id'], 'index': index + 1,
                    'order': i + 1, 'title': mid.replace('_', ' '),
                    'carry': carry or 'The next handoff has not yet been described.',
                    'carryStatus': 'Declared lesson plan' if carry else 'Missing handoff',
                    'decision': lesson.get('decision', 'unrecorded'),
                    'next': allmaps[i + 1] if i + 1 < len(allmaps) else None,
                    'nextText': lesson.get('next', ''),
                    'photo': photo, 'above': overhead,
                    'planSource': link(planpath),
                    'planEditor': '/tutorial-plan?map=' + mid + '&view=halls',
                    'tutorial': link(ROOT / f'commons/maps/{mid}/tutorial.md'),
                    'reflection': link(ROOT / f'commons/maps/{mid}/final.md')}
            for field, filename in [('tutorial', 'tutorial.md'), ('reflection', 'final.md')]:
                if not (ROOT / f'commons/maps/{mid}' / filename).exists():
                    hall[field] = None
            if mid == 'Lab_Path' and not photo:
                hall['captureGap'] = 'Listed in the sequence, but the museum loader did not load this hall during the capture attempt. Its map description identifies an optional grid-lane return corridor.'
                hall['captureAttempt'] = link(CONTENT / 'lab-path-capture-note.md')
            halls.append(hall)
    data['halls'] = halls
    data['references'] = read(CONTENT / 'references.json')
    hall_sequences = {h['id']: h['sequence'] for h in halls}
    reference_ids = [r['id'] for r in data['references']]
    assert len(reference_ids) == len(set(reference_ids)), 'Duplicate reference IDs'
    for reference in data['references']:
        assert reference['group'] in ['networks', 'across-spine', 'method'], reference['id']
        assert reference['reading'] and reference['question'], reference['id']
        assert reference['halls'], reference['id']
        for connection in reference['halls']:
            assert connection['id'] in hall_sequences, connection
            assert connection['reason'] and (ROOT / connection['basis']).is_file(), connection
        assert set(reference['sequences']) == {hall_sequences[h['id']] for h in reference['halls']}, reference['id']
    data['readingMethod'] = read(CONTENT / 'reading-method.json')
    for connection in data['readingMethod']['returns']:
        assert connection['hall'] in hall_sequences, connection
        assert connection['question'] and (ROOT / connection['basis']).is_file(), connection
    data['imageView'] = {'built': datetime.now(timezone.utc).isoformat(),
                         'planSha256': sha(planpath), 'relationSha256': sha(data_path),
                         'photographed': sum(h['photo'] is not None for h in halls),
                         'total': len(halls),
                         'textGaps': [{'id': h['id'], 'field': field} for h in halls for field in ['tutorial', 'reflection'] if not h[field]],
                         'staleRelationSources': [p for p, digest in data['source_hashes'].items()
                                                  if not (ROOT / p).exists() or sha(ROOT / p) != digest],
                         'limits': 'Saved native captures; dates are file save dates. Captions are current plan declarations, not runtime or learner verification.'}
    snapshot = json.dumps(data, ensure_ascii=False)
    template = (ROOT / 'tools/templates/ada-atlas.html').read_text(encoding='utf-8')
    assert template.count('__ATLAS_DATA__') == 1
    (PUBLIC / 'index.html').write_text(template.replace('__ATLAS_DATA__', snapshot.replace('<', '\\u003c')), encoding='utf-8')
    (PUBLIC / 'atlas.json').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    manifest = {'imageView': data['imageView'], 'halls': [{k: h[k] for k in ['id', 'photo', 'above', 'carry', 'carryStatus', 'next']} for h in halls]}
    (CONTENT / 'image-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'halls': len(halls), 'photos': data['imageView']['photographed'],
                      'missing': [h['id'] for h in halls if not h['photo']],
                      'stale_relation_sources': data['imageView']['staleRelationSources']}))
    return data


if __name__ == '__main__':
    publish()

"""Bounded preservation and integration checks for this Isosurfaces pass."""
from pathlib import Path
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
BEFORE = HERE / 'before'
checks = []

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def check(ok, message):
    checks.append({'passed': bool(ok), 'check': message})

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

sequence = read(ROOT / 'commons/maps/sequences/isosurfaces.json')['sequences']['isosurfaces']['maps']
check(len(sequence) == 13, 'Thirteen declared halls')
check(read(ROOT / 'commons/data/map_authored.json')['isosurfaces'] == sequence, 'Authored route matches sequence')
pearls = read(ROOT / 'commons/data/book/isosurfaces.json')['pearls']
check([p['map'] for p in pearls if p['map'] in sequence] == sequence, 'Book pearls for active halls match route')
check([p for p in pearls if p['map'] not in sequence] == [p for p in read(BEFORE / 'commons/data/book/isosurfaces.json')['pearls'] if p['map'] not in sequence], 'Existing off-route Chamber pearl preserved')
for path in ['ada_run/em_plan.json', 'commons/data/museum/em_plan.json']:
    old, current = read(BEFORE / path), read(ROOT / path)
    iso = [r for r in current['plans'] if r.get('sequence') == 'isosurfaces']
    check([r['map'] for r in iso] == sequence, path + ': thirteen halls in order')
    check([r['pearl_index'] for r in iso] == list(range(13)), path + ': contiguous pearl indices')
    check(all(r['pearls_total'] == 13 for r in iso), path + ': total is thirteen')
    check([r for r in old['plans'] if r.get('sequence') != 'isosurfaces'] ==
          [r for r in current['plans'] if r.get('sequence') != 'isosurfaces'], path + ': unrelated plan rows preserved')
check(read(ROOT / 'ada_run/em_plan.json') == read(ROOT / 'commons/data/museum/em_plan.json'), 'Local and shipped plans agree')
for path, key in [('commons/data/long_museum.json', 'segments'), ('commons/data/museum_order_effective.json', 'halls')]:
    halls = [r['name'] for r in read(ROOT / path)[key] if r.get('sequence') == 'isosurfaces' and r.get('kind', 'hall') == 'hall']
    check(halls == sequence, path + ': derived halls match route')

changed_texts = {'ISO_PortalLandscape', 'ISO_Metaballs'}
restored = {'ISO_PortalLandscape', 'ISO_CaveGeneration', 'ISO_AnimatedNoise', 'ISO_ImplicitModeling', 'ISO_RhizomeBody'}
core = read(ROOT / 'commons/data/museum_core_encounters.json')['rooms']
roles = read(ROOT / 'commons/data/artifact_roles.json')['roles']
old_roles = read(BEFORE / 'commons/data/artifact_roles.json')['roles']

def tokens(data):
    return {str(cell).split('#')[0].split(':')[0] for row in data['layers']['interactables'] for cell in row if str(cell) not in ('', '0', 'None')}

for room in sequence:
    rel = Path('commons/maps') / room
    if room not in changed_texts:
        check((ROOT / rel / 'final.md').read_bytes() == (BEFORE / rel / 'final.md').read_bytes(), room + ': prose byte-preserved')
    if room not in restored:
        check((ROOT / rel / 'map_data.json').read_bytes() == (BEFORE / rel / 'map_data.json').read_bytes(), room + ': map byte-preserved')
    else:
        old, current = read(BEFORE / rel / 'map_data.json'), read(ROOT / rel / 'map_data.json')
        check(tokens(old) <= tokens(current), room + ': original artifact tokens retained')
        size = current['map_info']['dimensions']
        for layer, rows in current['layers'].items():
            check(len(rows) == size['depth'] and all(len(row) == size['width'] for row in rows), room + ': rectangular ' + layer)
    check(all(roles.get(room, {}).get(t) == r for t, r in old_roles.get(room, {}).items()), room + ': existing roles retained')
    if room in restored | changed_texts:
        check(core[room]['text_sha256'] == digest(ROOT / rel / 'final.md'), room + ': current text reference')
        check(core[room]['map_sha256'] == digest(ROOT / rel / 'map_data.json'), room + ': current map reference')

registry = read(ROOT / 'commons/artifacts/registry/isosurfaces.json')['artifacts']
for token, rooms in [('iso_portal_console', ['ISO_PortalLandscape']), ('iso_specimen_stage', ['ISO_CaveGeneration', 'ISO_AnimatedNoise'])]:
    check(token in registry and (ROOT / registry[token]['scene'].removeprefix('res://')).exists(), token + ': registered scene exists')
    for room in rooms:
        check(roles[room][token] == 'secondary', room + ': helper is secondary')

portal = read(HERE / 'review-report.json')
check(portal['passed'] and not portal['failures'], 'Portal runtime report passes')
nav = read(HERE / 'navigation.json')
check(all(c['ok'] for c in nav['checks']), 'Navigation selection checks pass')
restored_reports = read(HERE / 'restored-checks.json')
check({r['map'] for r in restored_reports} == restored - {'ISO_PortalLandscape'}, 'All four other restored halls have reports')
check(all(r['present'] and not r['failures'] and all(w['passed'] for w in r['walks']) for r in restored_reports), 'Restored halls and gallery routes pass')

failures = [c['check'] for c in checks if not c['passed']]
result = {'checks': checks, 'count': len(checks), 'failures': failures, 'passed': not failures}
(HERE / 'content-checks.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'checks': len(checks), 'failures': failures}))
raise SystemExit(bool(failures))

"""Preservation and integration checks for the bounded Swarm review."""
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

def tokens(data):
    return {str(cell).split('#')[0].split(':')[0]
            for row in data['layers']['interactables'] for cell in row
            if str(cell) not in ('', '0', 'None')}

name = 'swarmintelligence'
sequence = read(ROOT / f'commons/maps/sequences/{name}.json')['sequences'][name]['maps']
check(len(sequence) == 7, 'Seven declared halls')
check(read(ROOT / f'commons/maps/sequences/{name}.json')['sequences'][name]['maps'] ==
      read(BEFORE / f'commons/maps/sequences/{name}.json')['sequences'][name]['maps'], 'Declared order retained')
check(read(ROOT / 'commons/data/map_authored.json')[name] == sequence, 'Authored route matches declaration')
pearls = read(ROOT / f'commons/data/book/{name}.json')['pearls']
check([p['map'] for p in pearls if p['map'] in sequence] == sequence, 'Active book pearls follow route')
check([p for p in pearls if p['map'] not in sequence] ==
      [p for p in read(BEFORE / f'commons/data/book/{name}.json')['pearls'] if p['map'] not in sequence],
      'Off-route book entries retained')
for path in ['ada_run/em_plan.json', 'commons/data/museum/em_plan.json']:
    old, current = read(BEFORE / path), read(ROOT / path)
    rows = [r for r in current['plans'] if r.get('sequence') == name]
    check([r['map'] for r in rows] == sequence, path + ': seven halls in order')
    check([r['pearl_index'] for r in rows] == list(range(7)) and
          all(r['pearls_total'] == 7 for r in rows), path + ': consistent indices and totals')
    check([r for r in old['plans'] if r.get('sequence') != name] ==
          [r for r in current['plans'] if r.get('sequence') != name], path + ': unrelated rows preserved')
check(read(ROOT / 'ada_run/em_plan.json') == read(ROOT / 'commons/data/museum/em_plan.json'), 'Local and shipped plans agree')
for path, key in [('commons/data/long_museum.json', 'segments'), ('commons/data/museum_order_effective.json', 'halls')]:
    halls = [r['name'] for r in read(ROOT / path)[key] if r.get('sequence') == name and r.get('kind', 'hall') == 'hall']
    check(halls == sequence, path + ': derived route matches')

core = read(ROOT / 'commons/data/museum_core_encounters.json')['rooms']
roles = read(ROOT / 'commons/data/artifact_roles.json')['roles']
check((ROOT / 'commons/data/artifact_roles.json').read_bytes() ==
      (BEFORE / 'commons/data/artifact_roles.json').read_bytes(), 'All artifact roles byte-preserved')
unchanged_texts = [sequence[i] for i in (0, 1, 2, 4)]
for room in sequence:
    rel = Path('commons/maps') / room
    if room in unchanged_texts:
        check((ROOT / rel / 'final.md').read_bytes() == (BEFORE / rel / 'final.md').read_bytes(), room + ': prose byte-preserved')
    if room in sequence[:3]:
        check((ROOT / rel / 'map_data.json').read_bytes() == (BEFORE / rel / 'map_data.json').read_bytes(), room + ': map byte-preserved')
    old, current = read(BEFORE / rel / 'map_data.json'), read(ROOT / rel / 'map_data.json')
    check(tokens(old) <= tokens(current), room + ': original artifact families retained')
    size = current['map_info']['dimensions']
    check(all(len(rows) == size['depth'] and all(len(row) == size['width'] for row in rows)
              for rows in current['layers'].values()), room + ': layers match dimensions')
    check(core[room]['text_sha256'] == digest(ROOT / rel / 'final.md') and
          core[room]['map_sha256'] == digest(ROOT / rel / 'map_data.json'), room + ': current encounter references')
    hero = next(p['hero'] for p in pearls if p['map'] == room)
    check(roles.get(room, {}).get(hero) == 'primary' and hero in tokens(current), room + ': book hero is a placed primary')
    check('\ufffd' not in (ROOT / rel / 'final.md').read_text(encoding='utf-8'), room + ': no replacement characters')

for path, changed in [('commons/artifacts/registry/swarmintelligence.json', {'fitness_landscape_politics', 'ant_colony_optimization'}),
                      ('commons/artifacts/registry/algorithms_misc.json', {'ecosystem_simulation'})]:
    old, current = read(BEFORE / path)['artifacts'], read(ROOT / path)['artifacts']
    check({k:v for k,v in old.items() if k not in changed} ==
          {k:v for k,v in current.items() if k not in changed}, path + ': unrelated entries preserved')

for file in ['model-checks.json', 'navigation.json']:
    report = read(HERE / file)
    check(not report['failures'] and all(c['ok'] for c in report['checks']), file + ': recorded runtime checks pass')
for room in sequence[3:]:
    report = read(HERE / (room + '-runtime.json'))
    check(report['passed'] and report['required_present'] and not report['failures'], room + ': museum primary instantiated')
    check(bool(report['walks']) and all(w['passed'] for w in report['walks']), room + ': tested approach or perimeter walk passes')
    if 'Modeling' in room:
        primary = next(a for a in report['artifacts'] if a['token'] == 'ant_colony_optimization')
        check(primary['detectors'] and all(.85 < d['position'][1] < 1.4 for d in primary['detectors']), 'Ant button detectors at reachable height')
    if room == sequence[-1]:
        check(bool(report['care_records']), 'Ecosystem exposes intervention record in museum')

frozen = read(HERE / 'before-sha256.json')
check(all(digest(BEFORE / p) == h for p,h in frozen.items()), 'All frozen before-files still match their recorded hashes')
manifest = {p: {'before': h, 'current': digest(ROOT / p)} for p,h in frozen.items()}
(HERE / 'current-inputs.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
failures = [c['check'] for c in checks if not c['passed']]
result = {'checks': checks, 'count': len(checks), 'failures': failures, 'passed': not failures}
(HERE / 'content-checks.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'checks': len(checks), 'failures': failures}))
raise SystemExit(bool(failures))

"""Check this pass's exact scope and recorded evidence. Does not rerun Godot."""
from collections import Counter
import copy
from html.parser import HTMLParser
import hashlib
import json
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PAGE = HERE.parent / '2026-09-19-review-comparison'
FEEDBACK = ROOT / 'doc/book/review-feedback/2026-09-18/forces'


def load(path):
    return json.loads(path.read_text(encoding='utf-8'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pair(relative):
    return load(HERE / 'before' / relative), load(ROOT / relative)


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links, self.ids = [], set()

    def handle_starttag(self, tag, attrs):
        data = dict(attrs)
        if data.get('id'):
            self.ids.add(data['id'])
        self.links.extend(data[k] for k in ('href', 'src') if data.get(k))
        if tag == 'img':
            assert data.get('alt')


def verify():
    result = {'scope': 'Forces: thirteen-hall source review, bounded encounter repairs and recorded desktop evidence'}
    old, seq = [d['sequences']['forces'] for d in pair('commons/maps/sequences/forces.json')]
    changed_seq = {'truth', 'description', 'demonstration', 'qfep_connection', 'learning_objectives', 'content', 'curation_history'}
    for key in old:
        if key not in changed_seq:
            assert old[key] == seq[key], key
    for key in changed_seq - {'curation_history'}:
        assert old[key] == seq['curation_history'][0][key]
    maps = seq['maps']
    assert len(maps) == 13
    replacements = load(HERE / 'text-changes.json')
    manuscripts = {}
    for name in maps:
        relative = f'commons/maps/{name}/final.md'
        original = (HERE / 'before' / relative).read_text(encoding='utf-8')
        current = (ROOT / relative).read_text(encoding='utf-8')
        expected = original
        for a, b in replacements.get(name, []):
            assert expected.count(a) == 1
            expected = expected.replace(a, b, 1)
        assert expected == current, name
        if name not in replacements:
            assert sha(HERE / 'before' / relative) == sha(ROOT / relative), name
        manuscripts[name] = 'narrow recorded repair' if name in replacements else 'byte unchanged'
    result['manuscripts'] = manuscripts

    roles_before, roles = pair('commons/data/artifact_roles.json')
    expected_roles = copy.deepcopy(roles_before)
    expected_roles['roles']['Change_Choreography']['parametric_pendulum_waves'] = 'secondary'
    expected_roles['order']['Change_Choreography']['secondary'].append('parametric_pendulum_waves')
    assert expected_roles == roles
    result['roles'] = 'only existing pendulum comparison classified secondary; all book roles/order preserved'
    chain = load(HERE / 'source-chain.json')
    placements = 0
    for hall in chain:
        name = hall['map']
        before, now = pair(f'commons/maps/{name}/map_data.json')
        assert set(before['layers']) == set(now['layers'])
        for key in before['layers']:
            if name == 'Vectors_Act4a_KineticForces' and key == 'interactables':
                a, b = before['layers'][key], now['layers'][key]
                assert Counter(str(c) for row in a for c in row) == Counter(str(c) for row in b for c in row)
                assert sum(c != d for ar, br in zip(a, b) for c, d in zip(ar, br)) == 4
            else:
                assert before['layers'][key] == now['layers'][key], (name, key)
        for inst in hall['instances']:
            assert now['layers']['interactables'][inst['z']][inst['x']] == inst['token']
            assert inst['sources'] and all(s['exists'] and (ROOT / s['scene'].removeprefix('res://')).is_file() for s in inst['sources'])
        tags = re.findall(r'<!--\s*@([\w:-]+)\s*-->', (ROOT / f'commons/maps/{name}/final.md').read_text(encoding='utf-8'))
        assert tags == [t for t in roles['order'][name]['primary'] if not t.startswith('#')]
        placements += len(hall['instances'])
    assert placements == 178
    result['placements'] = {'authored_instances_retained': placements, 'book_encounters': 27, 'kinetic_changed_cells': 4}

    recovered = {'sisyphus_mower', 'prop_carousel', 'parlour_orbits', 'paused_fountain', 'prop_mobile',
                 'prop_spigot', 'revolving_door', 'three_gravities', 'umbrella_field'}
    changes = {'vectors_demos.json': recovered | {'torque_crank', 'vector_machine', 'force_field_zone', 'centrifuge_ring'},
               'vectors.json': {'vector_normalize_demo'}, 'hazards.json': {'four_leg_critter'}}
    for filename, expected in changes.items():
        a, b = pair('commons/artifacts/registry/' + filename)
        assert set(a) == set(b)
        for k in a:
            if k != 'artifacts':
                assert a[k] == b[k]
        assert set(a['artifacts']) == set(b['artifacts'])
        assert {k for k in a['artifacts'] if a['artifacts'][k] != b['artifacts'][k]} == expected
        if filename == 'vectors_demos.json':
            for token in recovered:
                value = dict(a['artifacts'][token], lookup_name=token, map_ready=True, include_in_map_data=True)
                assert b['artifacts'][token] == value
    physics = load(ROOT / 'commons/artifacts/registry/physics_simulation.json')['artifacts']['momentum_collision']
    assert physics['map_ready'] is False and physics['include_in_map_data'] is False
    result['catalog'] = {'recovered_readiness': sorted(recovered), 'explicitly_disabled_preserved': 'momentum_collision'}

    before_core, core = pair('commons/data/museum_core_encounters.json')
    assert set(before_core) == set(core) and set(before_core['rooms']) == set(core['rooms'])
    for key in core:
        if key != 'rooms':
            assert core[key] == before_core[key]
    for name, room in core['rooms'].items():
        if name not in maps:
            assert room == before_core['rooms'][name], name
            continue
        assert room['primary_tokens'] == before_core['rooms'][name]['primary_tokens']
        assert room['text_sha256'] == sha(ROOT / room['text_path'])
        assert room['map_sha256'] == sha(ROOT / f'commons/maps/{name}/map_data.json')
        assert room['learner_verified'] is False
    assert core['rooms']['VFM_08_Arena']['status'] == 'behavior_checks_passed_teardown_failure'
    result['core_records'] = 'current text/map hashes; unchanged primaries; explicit Arena process failure'

    package = load(FEEDBACK / 'package.json')
    assert sha(ROOT / package['review_text']) == package['review_text_sha256']
    assert sha(ROOT / package['zip']) == package['zip_sha256']
    for receipt in load(FEEDBACK / 'received.json'):
        assert sha(FEEDBACK / receipt['file']) == receipt['sha256']
    result['frozen_review_inputs_preserved'] = True

    navigation = load(HERE / 'navigation.json')
    run = load(HERE / 'navigation-run.json')
    assert navigation['route'] == maps and all(c['ok'] for c in navigation['checks'])
    assert run['returncode'] == 0 and run['before'] == run['after']
    result['navigation'] = {'checks': len(navigation['checks']), 'scope': navigation['scope']}
    for group in ['opening', 'motion']:
        report = load(HERE / group / 'verification.json')
        assert all(report['checks'].values()), group
        for test in report['runtime'].values():
            assert test['returncode'] == 0 and not test['failures']
        result[group] = report['runtime']
    relations = load(HERE / 'relations/runtime-summary.json')
    for test in relations:
        if test['folder'] in ['before', 'after']:
            assert test['clean_process_pass'] and not test['recorded_failures']
        elif test['folder'] in ['arena-after', 'arena-after-clean']:
            assert test['recorded_checks'] == 49 and not test['recorded_failures']
            assert test['returncode'] != 0 and not test['clean_process_pass']
            assert test['missing_tokens'] == ['momentum_collision']
    result['relations'] = relations
    result['unresolved'] = ['Arena completes behavior checks but native headless teardown hangs/crashes; not a clean suite pass.', 'No headset or learner verification; no complete physical thirteen-hall route walk.']

    page = load(PAGE / 'forces.json')
    for item in page['items']:
        if item.get('map'):
            relative = f"commons/maps/{item['map']}/final.md"
            assert item['before'] in (HERE / 'before' / relative).read_text(encoding='utf-8')
            assert item['after'] in (ROOT / relative).read_text(encoding='utf-8')
    html = Links()
    html.feed((PAGE / 'index.html').read_text(encoding='utf-8'))
    assert 'forces' in html.ids
    checked = 0
    for link in html.links:
        parsed = urlsplit(link)
        if parsed.scheme or parsed.netloc:
            continue
        if parsed.path:
            assert (PAGE / unquote(parsed.path)).exists(), link
        elif parsed.fragment:
            assert parsed.fragment in html.ids, link
        checked += 1
    result['comparison_links_checked'] = checked
    result['chosen_image_sha256'] = {p: sha(ROOT / p) for item in page['items'] for p in item.get('images', [])}
    result.update(headset_tested=False, learner_verified=False, browser_layout_verified=False)
    (HERE / 'verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('Verified: 13 scoped manuscripts, 178 retained placements, 9 catalog recoveries, recorded evidence and', checked, 'comparison links. Arena teardown remains explicitly unresolved.')


if __name__ == '__main__':
    verify()

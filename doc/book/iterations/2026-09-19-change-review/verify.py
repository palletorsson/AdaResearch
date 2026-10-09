"""Verify this bounded review's preservation and recorded evidence; no Godot run."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import hashlib
import json
import difflib
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PAGE = HERE.parent / '2026-09-19-review-comparison'
FEEDBACK = ROOT / 'doc/book/review-feedback/2026-09-18/change'


def load(path):
    return json.loads(path.read_text(encoding='utf-8'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def result(path):
    data = load(path)
    checks = data['checks']
    assert not data.get('failures'), str(path)
    if isinstance(checks, list):
        assert all(c.get('ok', c.get('pass', c.get('passed', False))) for c in checks)
        checks = len(checks)
    return checks


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links, self.ids = [], set()

    def handle_starttag(self, tag, attrs):
        d = dict(attrs)
        if d.get('id'):
            self.ids.add(d['id'])
        self.links += [d[k] for k in ('href', 'src') if d.get(k)]
        if tag == 'img':
            assert d.get('alt')


def verify():
    evidence = {'scope': 'Change: two halls; source/preservation and recorded desktop evidence'}
    paths = ['commons/maps/Change_Intro/final.md', 'commons/maps/Flow_Field/final.md']
    a, b = [(HERE / 'before' / p).read_text(encoding='utf-8') for p in paths]
    current, flow = [(ROOT / p).read_text(encoding='utf-8') for p in paths]
    assert b == flow
    page = load(PAGE / 'change.json')
    # All displayed manuscript changes must be exact contiguous source excerpts.
    for item in page['items']:
        if item.get('text_kind', '').startswith('final.md'):
            assert item['before'] in a and item['after'] in current
            a = a.replace(item['before'], item['after'], 1)
    assert a == current, 'Unreported manuscript change'
    evidence['manuscripts'] = {'Flow_Field': 'unchanged', 'Change_Intro': 'only the displayed sentence relocation and bridge-control paragraph'}

    package = load(FEEDBACK / 'package.json')
    assert sha(ROOT / package['review_text']) == package['review_text_sha256']
    assert sha(ROOT / package['zip']) == package['zip_sha256']
    receipt = load(FEEDBACK / 'received.json')[0]
    assert sha(FEEDBACK / receipt['file']) == receipt['sha256']
    evidence['frozen_review_inputs_preserved'] = True

    seqpath = 'commons/maps/sequences/change.json'
    old, new = [load(p)['sequences']['change'] for p in (HERE / 'before' / seqpath, ROOT / seqpath)]
    for key in ('maps', 'prerequisites', 'unlocks', 'artifact_groups', 'deferred_maps', 'formula', 'consolidation_ledger'):
        assert old[key] == new[key], key
    for key in ('truth', 'qfep_connection', 'demonstration', 'description', 'learning_objectives', '_status', '_provenance'):
        assert new['curation_history'][0][key] == old[key], key
    evidence['sequence_order_and_original_overview_preserved'] = True

    for path, changed in [('commons/artifacts/registry/change.json', {'riemann_sum_workbench', 'tangent_slope_workbench', 'ftc_bridge'}), ('commons/artifacts/registry/commons_artifacts.json', {'flow_field_painter'})]:
        before, after = [load(p) for p in (HERE / 'before' / path, ROOT / path)]
        assert set(before) == set(after)
        for k in before:
            if k != 'artifacts':
                assert before[k] == after[k]
        assert set(before['artifacts']) == set(after['artifacts'])
        actual = {k for k in before['artifacts'] if before['artifacts'][k] != after['artifacts'][k]}
        assert actual == changed, actual
    evidence['registry_scope'] = 'four descriptions/related curation fields; all other entries unchanged'

    roles = load(ROOT / 'commons/data/artifact_roles.json')
    oldroles = load(HERE / 'before/commons/data/artifact_roles.json')
    for key in roles:
        for name in new['maps']:
            if isinstance(roles[key], dict) and name in roles[key]:
                assert roles[key][name] == oldroles[key][name]
    chain = load(HERE / 'source-chain.json')
    count = 0
    for hall in chain:
        name = hall['map']
        data = load(ROOT / 'commons/maps' / name / 'map_data.json')
        for inst in hall['instances']:
            assert data['layers']['interactables'][inst['z']][inst['x']] == inst['token']
            assert inst['sources'] and all(s['exists'] and (ROOT / s['scene'].removeprefix('res://')).is_file() for s in inst['sources'])
        tags = re.findall(r'<!--\s*@([\w:-]+)\s*-->', (ROOT / 'commons/maps' / name / 'final.md').read_text(encoding='utf-8'))
        assert tags == roles['order'][name]['primary']
        count += len(hall['instances'])
    assert count == 23
    evidence['placed_artifacts_resolved'] = count
    evidence['roles_and_primary_order_preserved'] = True

    core_path = 'commons/data/museum_core_encounters.json'
    old_core, core = [load(p) for p in (HERE / 'before' / core_path, ROOT / core_path)]
    assert set(old_core) == set(core)
    for key in core:
        if key != 'rooms':
            assert core[key] == old_core[key]
    assert set(core['rooms']) == set(old_core['rooms'])
    for name, room in core['rooms'].items():
        if name not in new['maps']:
            assert room == old_core['rooms'][name], name
            continue
        assert room['primary_tokens'] == old_core['rooms'][name]['primary_tokens']
        assert room['text_sha256'] == sha(ROOT / room['text_path'])
        assert room['map_sha256'] == sha(ROOT / 'commons/maps' / name / 'map_data.json')
        assert room['learner_verified'] is False
        assert room['status'] == 'desktop_verified_headset_pending'
        assert (ROOT / room['local_review']).is_file()
    evidence['core_records'] = 'two scoped records updated; source hashes current; other rooms preserved'

    evidence['desktop_checks'] = {}
    for path in ['intro/after/staging-checks.json', 'intro/after/probe_change_intro.json', 'intro/after/probe_accumulation.json', 'bridge/runtime/verification.json', 'bridge/museum/verification.json']:
        evidence['desktop_checks'][path] = result(HERE / path)
    # Flow's own verifier inspects narrow scope, executable-line preservation,
    # baseline replay, status state and final museum source hashes.
    flow_report = load(HERE / 'flow/verification.json')
    assert all(flow_report['checks'].values())
    for name in ('final-headless', 'before-runtime', 'after-runtime'):
        run = flow_report['runtime'][name]
        assert not run['failures'] and run['returncode'] == 0, name
        assert run['source_hashes_stable_during_run'], name
    evidence['flow_report'] = flow_report

    before_camera = load(HERE / 'intro/before/entry-camera.json')
    after_camera = load(HERE / 'intro/after/entry-camera.json')
    assert before_camera == after_camera
    html = Links()
    html.feed((PAGE / 'index.html').read_text(encoding='utf-8'))
    assert 'change' in html.ids
    checked = 0
    for link in html.links:
        p = urlsplit(link)
        if p.scheme or p.netloc:
            continue
        if p.path:
            assert (PAGE / unquote(p.path)).exists(), link
        elif p.fragment:
            assert p.fragment in html.ids, link
        checked += 1
    evidence['comparison_local_links_checked'] = checked
    evidence['chosen_image_sha256'] = {p: sha(ROOT / p) for item in page['items'] for p in item.get('images', [])}
    evidence['headset_tested'] = False
    evidence['learner_verified'] = False
    evidence['browser_layout_verified'] = False
    evidence['diagnostics'] = 'See each local audit: existing startup/renderer/cache/shutdown diagnostics retained. No whole-project clean-log claim.'
    (HERE / 'verification.json').write_text(json.dumps(evidence, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print('Verified two scoped manuscripts, frozen inputs, 23 placements, four registry entries, recorded runtime evidence and', checked, 'comparison links.')


if __name__ == '__main__':
    verify()

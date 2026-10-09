"""Verify the integrated scope and evidence links. Does not rerun Godot."""
from pathlib import Path
from collections import Counter
from html.parser import HTMLParser
from urllib.parse import unquote, urlsplit
import copy
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PAGE = HERE.parent / '2026-09-19-review-comparison'
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def pair(p): return read(HERE / 'before' / p), read(ROOT / p)
def artifacts(d):
    return Counter(re.split('[:#]', str(x))[0] for row in d['layers']['interactables'] for x in row if str(x) not in ('', '0', 'None'))

def verify():
    old_seq, seq = [x['sequences']['formfinding'] for x in pair('commons/maps/sequences/formfinding.json')]
    assert old_seq['maps'] == seq['maps']
    assert len(seq['maps']) == 6
    for key in old_seq:
        if key not in ['v1_note', 'learning_objectives', 'content']:
            assert old_seq[key] == seq[key], key
    chapters, maps = {}, {}
    changes = read(HERE / 'text-changes.json')
    for name in seq['maps']:
        path = f'commons/maps/{name}/final.md'
        original = (HERE / 'before' / path).read_text(encoding='utf-8')
        target = original
        for a,b in changes.get(name, []):
            assert target.count(a) == 1
            target = target.replace(a,b,1)
        assert (ROOT/path).read_text(encoding='utf-8') == target, name
        if name == 'FormFinding_Descent': assert sha(HERE/'before'/path) == sha(ROOT/path)
        chapters[name] = 'byte unchanged' if name not in changes else ('one stop-condition correction' if name.endswith('Forge') else 'encounter and source revision')
        old, new = pair(f'commons/maps/{name}/map_data.json')
        assert artifacts(old) == artifacts(new), name
        cells = []
        assert old['map_info'] == new['map_info'], name
        for key in old:
            if key != 'layers': assert old[key] == new[key], (name,key)
        for key in old['layers']:
            if key != 'interactables': assert old['layers'][key] == new['layers'][key], (name,key)
        for z, row in enumerate(old['layers']['interactables']):
            for x, value in enumerate(row):
                if value != new['layers']['interactables'][z][x]: cells.append([x,z,value,new['layers']['interactables'][z][x]])
        expected = {'FormFinding_Relaxation':1, 'FormFinding_Annealing':4}.get(name,0)
        assert len(cells) == expected, (name,cells)
        maps[name] = {'artifacts_retained':sum(artifacts(new).values()), 'changed_cells':cells}
    assert sum(v['artifacts_retained'] for v in maps.values()) == 28
    old_book, book = pair('commons/data/book/formfinding.json')
    expected_book = copy.deepcopy(old_book)
    for pearl in expected_book['pearls']:
        if pearl.get('map') == 'FormFinding_Annealing':
            for line in pearl['lines']:
                if line['token'] == 'max_q_basin_room':
                    line['text'] = 'Two wells with different receivers: compare the responses before INTERPRET.'
    assert expected_book == book, 'only Q display card changed; editorial notes retained'
    old_roles, roles = pair('commons/data/artifact_roles.json')
    expected = copy.deepcopy(old_roles)
    promotion = {'FormFinding_Catenary':('laundry_line_cathedral',['cable_builder','laundry_line_cathedral','catenoid']),
        'FormFinding_Relaxation':('frozen_glass_vessel',['verlet_workbench','mass_spring_bench','frozen_glass_vessel']),
        'FormFinding_Annealing':('max_q_basin_room',['energy_landscape_bench','simulated_annealing','max_q_basin_room'])}
    for name,(token,order) in promotion.items():
        expected['roles'][name][token]='primary'
        expected['order'][name]['primary']=order
        expected['order'][name]['secondary'].remove(token)
    assert expected == roles, 'roles scope'
    old_core, core = pair('commons/data/museum_core_encounters.json')
    for name,value in core['rooms'].items():
        if name not in seq['maps']:
            assert value == old_core['rooms'][name], name
            continue
        assert value['primary_tokens'] == roles['order'][name]['primary']
        assert value['map_sha256'] == sha(ROOT/f'commons/maps/{name}/map_data.json')
        assert value['text_sha256'] == sha(ROOT/f'commons/maps/{name}/final.md')
        assert value['learner_verified'] is False
    source = read(HERE/'source-chain.json')
    for name, record in source.items():
        for artifact in record['placements']:
            assert any(s['map_ready'] and s['scene_exists'] for s in artifact['sources']), (name,artifact['key'])
    registry_changes = {}
    for path in (HERE/'before/commons/artifacts/registry').glob('*.json'):
        current = ROOT/'commons/artifacts/registry'/path.name
        before, after = read(path),read(current)
        if before == after: continue
        changed = [k for k in before.get('artifacts',{}) if before['artifacts'][k] != after['artifacts'][k]]
        assert changed, path.name
        rebuilt = copy.deepcopy(before)
        for key in changed: rebuilt['artifacts'][key] = after['artifacts'][key]
        assert rebuilt == after, path.name
        registry_changes[path.name] = changed
    historical = read(HERE/'descent-historical-evidence.json')
    assert len(historical) == 10 and all(x['unchanged'] for x in historical.values())
    numerical = read(HERE/'relaxation/measures/measurement.json')['rows']
    one = next(v for v in numerical if v['passes']==1 and v['steps']==420)
    four = next(v for v in numerical if v['passes']==4 and v['steps']==420)
    assert one['mean_absolute_percent'] > four['mean_absolute_percent']
    assert one['worst_absolute_percent'] > four['worst_absolute_percent']
    assert abs(four['worst_absolute_percent'] - 8.935516) < .001
    diagram = read(HERE/'diagram/check.json')
    assert not diagram['failures']
    run = read(HERE/'diagram/run.json')
    assert run['returncode']==0 and run['before']==run['after']
    review = read(PAGE/'formfinding.json')
    for item in review['items']:
        for path in item.get('images',[]): assert (ROOT/path).is_file(), path
        if item.get('map') and item.get('before') is not None:
            path = f'commons/maps/{item["map"]}/final.md'
            assert item['before'] in (HERE/'before'/path).read_text(encoding='utf-8'), item['title']
            assert item['after'] in (ROOT/path).read_text(encoding='utf-8'), item['title']
    class Links(HTMLParser):
        def __init__(self): super().__init__(); self.links=[]
        def handle_starttag(self, tag, attrs):
            data=dict(attrs)
            self.links += [data[k] for k in ('href','src') if data.get(k)]
            if tag=='img': assert data.get('alt')
    parser=Links();parser.feed((PAGE/'index.html').read_text(encoding='utf-8'))
    checked=0
    for link in parser.links:
        part=urlsplit(link)
        if part.scheme or not part.path:continue
        assert (PAGE/unquote(part.path)).is_file(), link
        checked+=1
    result={'scope':'Six-hall Form Finding source and bounded desktop pass; recorded numerical/visual evidence, no headset or learner claim',
        'chapters':chapters,'maps':maps,'promoted':list(promotion),'registry_entries_changed':registry_changes,
        'all_28_source_chains_eligible':True,'unchanged_descent_historical_hashes':10,
        'mean_worst_comparison':{'one_pass':one,'four_passes':four},'comparison_local_links_checked':checked,
        'diagram_checks':len(diagram['checks']),'headset_tested':False,
        'runtime_evidence':read(HERE/'runtime-evidence.json')}
    (HERE/'verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print('PASS: six halls, 28 retained placements, recorded manuscript edits, three promotions, source chains, measurements and',checked,'comparison links')

if __name__=='__main__': verify()

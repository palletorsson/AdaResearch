"""Create a separate six-study trial. Refuse to replace existing arrangements."""
from pathlib import Path
import copy
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
TRIAL = 'chains_studies'
TARGET = ROOT / 'commons/void/trials' / TRIAL
TITLES = ['Bodies Made for Others', 'Animated Futures', 'The Refusal',
          'Model B / The Unwanted Repair', 'Workers of All Bodies, Connect', 'The Occupation']

def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8-sig'))

def write(path, obj):
    p = ROOT / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def main():
    if TARGET.exists():
        raise SystemExit('Trial exists; preserve its arrangements, do not prepare again.')
    TARGET.mkdir(parents=True)
    definitions = {}
    for i, title in enumerate(TITLES):
        token = f'chains_study_{i + 1}'
        scene = f'commons/artifacts/chains_studies/study_{i + 1}.tscn'
        (ROOT / scene).write_text(
            '[gd_scene load_steps=2 format=3]\n'
            '[ext_resource type="PackedScene" path="res://commons/artifacts/chains_studies/chains_study.tscn" id="1"]\n'
            f'[node name="ChainsStudy{i + 1}" instance=ExtResource("1")]\nstudy = {i}\n', encoding='utf-8')
        definitions[token] = dict(lookup_name=token, name=f'Chains / {title}', scene='res://' + scene,
            configure_before_ready=True, map_ready=True, category='chains_studies',
            description='A scripted study with adult cyborg sex workers who already have their own preferences. ' + title +
                '. Reuses procedural Dream Bodies. Controls make requests; refusals and material needs affect the result.',
            qfep_connection='Variation in appearance does not determine who controls a body, a schedule or the shared infrastructure. '
                'The residents negotiate the conditions under which different forms can coexist.',
            interactions=['Use the request dock; read the resident response; watch the changed body or infrastructure.'],
            tags=['queer', 'drag', 'worker-autonomy', 'care', 'procedural', 'study'])
    write('commons/artifacts/registry/chains_studies.json', dict(id=TRIAL, name='Nothing to Lose but Our Chains', artifacts=definitions))
    catalog = read('commons/void/catalog.json')
    assert not set(definitions).intersection(catalog['artifacts'])
    catalog['artifacts'].update(definitions)
    write('commons/void/catalog.json', catalog)
    layout = copy.deepcopy(read('commons/void/trials/matter_gates/layout.json'))
    layout.update(status='Six authored studies / separate from the main spine', levels=[-6*i for i in range(8)],
        floor_roles=['Roof', *TITLES, 'Catch floor'], floor_styles={str(i):'abstract' for i in range(8)},
        route_note='Standard 42 x 18 m slabs. Central dressing spaces keep both 5 x 6 m shaft openings clear. '
            'Drop through shaft A corner pads to continue. Each floor is also selectable directly in the lab editor.')
    layout['descent']['pad_shafts'] = {str(i):'A' for i in range(1,8)}
    write(f'commons/void/trials/{TRIAL}/layout.json', layout)
    floors, placements = [], []
    for i, title in enumerate(['Roof', *TITLES, 'Catch floor']):
        # The trial reuses the Cube host chapter only for the existing Void shell.
        # No source chapter, museum map or main-spine arrangement is modified.
        floor = dict(map='Point_Animatedcube', title=title, origin=False, walls=[], artifacts=[],
            props=[], impact_cells=[], route=[], supply_leads=False)
        if 1 <= i <= 6:
            item = dict(id=f'study-{i}', artifact=f'chains_study_{i}', station='NW', position=[0,0],
                height=0, facing=0, scale=1, config=dict(study=i-1, seed=731, editor_label=title))
            floor['artifacts'].append(item)
            placements.append(dict(floor=i, id=item['id'], artifact=item['artifact'], token=item['artifact'], scene=definitions[item['artifact']]['scene']))
        floors.append(floor)
    write(f'commons/void/trials/{TRIAL}/rooms.json', dict(version=1, floors=floors))
    (TARGET/'trial.tscn').write_text('[gd_scene load_steps=2 format=3]\n'
        '[ext_resource type="PackedScene" path="res://commons/void/void.tscn" id="1"]\n'
        '[node name="ChainsStudiesTrial" instance=ExtResource("1")]\ntrial_id = "chains_studies"\n', encoding='utf-8')
    playable = read('commons/void/trials/playable.json')
    playable['trials'][TRIAL] = dict(title='Nothing to Lose but Our Chains / six studies', label='CHAINS / SIX STUDIES',
        map='Point_Animatedcube', start_floor=1,
        notice='Six fictional studies of adult cyborg workers, care and collective infrastructure.\n'
            'Requests can be declined. Use the dock and read the reply.\nShaft A leads down; R / B retries. No main-spine layout is changed.',
        rooms=f'res://commons/void/trials/{TRIAL}/rooms.json', layout=f'res://commons/void/trials/{TRIAL}/layout.json',
        scene=f'res://commons/void/trials/{TRIAL}/trial.tscn', models=f'/void-trials/{TRIAL}/manifest.json',
        retry_floors={str(i):max(1,min(i,6)) for i in range(8)}, spawn_points={str(i):[0,0.06,6.5] for i in range(1,7)})
    write('commons/void/trials/playable.json', playable)
    preserved = {}
    for path in ['commons/void/rooms.json', 'commons/void/layout.json', 'commons/maps/Point_Zero/final.md',
                 'commons/void/care_body.gd', 'commons/void/model_b_charger.gd',
                 'commons/artifacts/dream_bodies/dream_bodies.gd']:
        preserved[path] = hashlib.sha256((ROOT/path).read_bytes()).hexdigest()
    write(f'commons/void/trials/{TRIAL}/source-inventory.json', dict(purpose='New scripted studies, not original-occurrence transfers',
        maps=['Point_Animatedcube']*6, placements=placements, preserved_sources=preserved))
    print('Registered six Chains studies; main tower preserved.')

if __name__ == '__main__': main()

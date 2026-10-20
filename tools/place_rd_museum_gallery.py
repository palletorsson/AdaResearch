"""Place the saved RD research gallery; preserve every other hall and exhibit."""
from pathlib import Path
import copy
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from em_map_halls import derive_row

MAP = 'ProceduralGeneration_Reaction_Diffusion_Systems'
TOKEN = 'rd_museum_gallery'


def main():
    path = ROOT / f'commons/maps/{MAP}/map_data.json'
    data = json.loads(path.read_text(encoding='utf-8'))
    cells = data['layers']['interactables']
    assert str(cells[29][22]).strip() in ('', TOKEN + ':0:0')
    cells[29][22] = TOKEN + ':0:0'
    path.write_bytes((json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode())

    path = ROOT / 'commons/artifacts/registry/cellular_automata.json'
    registry = json.loads(path.read_text(encoding='utf-8'))
    registry['artifacts'][TOKEN] = {
        'lookup_name': TOKEN,
        'name': 'Reaction / Diffusion — Eighteen Kept Fields',
        'scene': f'res://commons/artifacts/{TOKEN}/{TOKEN}.tscn',
        'description': 'All 18 rd-gallery configurations as baked Gray–Scott reliefs, colour plates and pillar fields. Two rows of off-white plinths; each names F, K, steps and seed. Saved simulations, alongside the hall\u2019s live experiments.',
        'category': 'cellular_automata',
        'tags': ['reaction_diffusion', 'gray_scott', 'gallery', 'saved_field'],
        'map_ready': True,
        'include_in_map_data': True,
        'footprint': [7.1, 2.5, 30.6],
        'interactions': ['Walk between the studies; compare the parameters and spatial renderings.'],
    }
    path.write_bytes((json.dumps(registry, ensure_ascii=False, indent=2) + '\n').encode())

    path = ROOT / 'commons/data/museum/em_plan.json'
    stamp = path.stat().st_mtime_ns
    plan = json.loads(path.read_text(encoding='utf-8'))
    old = copy.deepcopy(plan)
    row = next(r for r in plan['plans'] if r['map'] == MAP)
    derived = derive_row(row['pearl'], MAP, row['museum'], row['pearl_index'], row['pearls_total'], row['sequence'])
    placement = next(a for a in derived['artifacts'] if a['token'] == TOKEN)
    row['artifacts'] = [a for a in row['artifacts'] if a['token'] != TOKEN] + [placement]
    assert [r for r in plan['plans'] if r['map'] != MAP] == [r for r in old['plans'] if r['map'] != MAP]
    before = next(r for r in old['plans'] if r['map'] == MAP)
    assert [a for a in row['artifacts'] if a['token'] != TOKEN] == [a for a in before['artifacts'] if a['token'] != TOKEN]
    assert path.stat().st_mtime_ns == stamp
    path.write_bytes(json.dumps(plan, ensure_ascii=False, separators=(',', ':')).encode())
    print('Placed RD gallery at (22,29), alongside all existing artifacts. Other halls unchanged.')


if __name__ == '__main__':
    main()

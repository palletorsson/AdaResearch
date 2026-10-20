"""Regenerate only this authored hall using the existing map compiler."""
from pathlib import Path
import datetime, json, sys
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'tools'))
from em_map_halls import derive_row, normalize_row, spine_names
path=ROOT/'commons/data/museum/em_plan.json'
plan=json.loads(path.read_text(encoding='utf8'))
index=next(i for i,r in enumerate(plan['plans']) if r.get('map')=='Random_Entropy')
old=plan['plans'][index]
row=derive_row(old['pearl'],old['map'],old['museum'],old['pearl_index'],old['pearls_total'],old['sequence'])
order=spine_names()
normalize_row(row,order.index(old['sequence'])>order.index('color'),any(k in row for k in ('basin','passage','simulation')),width_exempt=False)
plan['plans'][index]=row
plan['_entropy_compartments']={'at':datetime.datetime.now().astimezone().isoformat(),'producer':'em_map_halls.derive_row + normalize_row','map':old['map']}
path.write_text(json.dumps(plan),encoding='utf8')
print('Derived Random_Entropy:',[(a['token'],a['tile_cell']) for a in row['artifacts']])

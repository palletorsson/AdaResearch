"""Add one punching-bag comparison beside recoil; club is embedded at bowling."""
from pathlib import Path
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-07-club-and-punching-bag'
MAP = 'VFM_08_Arena'

def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p, data): p.write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', encoding='utf8')
def backup(p):
    dst=OUT/'before'/p.relative_to(ROOT)
    if not dst.exists():
        dst.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(p,dst)

def main():
    p=ROOT/'commons/artifacts/registry/force_play.json';backup(p);data=read(p)
    for token,name,scene,size,description in [
        ('force_impact_club','Oversized impact club','impact_club_rack',[2,3,2],
         'Take the rose grip and swing a long metal shaft with an oversized driver head. Actual held-tool collision sends the existing PointBody ball onward. RETURN CLUB restores the unheld tool.'),
        ('force_punching_bag','A push comes back','punching_bag',[6,4,7],
         'A seven-kilogram padded bag swings on a real pin joint. Nearby tracked hands wear local collision mitts; held clubs and loose balls also strike it. Pull the rose force grip without detaching the bag. Local reset.')]:
        data['artifacts'][token]=dict(lookup_name=token,name=name,scene=f'res://commons/artifacts/force_play/{scene}.tscn',category='vectors_forces',map_ready=True,include_in_map_data=True,map_sequences=['forces'],footprint=size,parameters={'footprint':size,'size_group':'large'},description=description,qfep_connection='Contact redistributes motion; the joint permits a return while preventing free translation. The encounter does not measure muscular force or entropy.')
    write(p,data)
    p=ROOT/'commons/artifacts/force_halls/curation.json';backup(p);plan=read(p)
    hall=next(h for h in plan['halls'] if h['map']==MAP)
    if not any(a['token']=='force_punching_bag' for a in hall['placements']):
        hall['placements'].append(dict(token='force_punching_bag',cell=[20,39],zone=[6,7],role='comparison',rotation=0,y=0,config='',pedestal=False))
    hall['after_count']=len(hall['placements'])
    note=' The oversized impact club is beside the bowling ball. A seven-kilogram punching bag beside recoil adds contact and constrained return; both are supporting play, with the bowling sphere still carrying the tutorial.'
    if 'oversized impact club' not in hall['selection_note']:hall['selection_note']+=note
    write(p,plan)
    p=ROOT/f'commons/maps/{MAP}/map_data.json';backup(p);data=read(p)
    cell=data['layers']['interactables'][39][20]
    assert not cell.strip() or cell.startswith('force_punching_bag'),cell
    data['layers']['interactables'][39][20]='force_punching_bag#pin:1#plinth:0'
    data['map_info']['metadata']['n_artifacts']=len(hall['placements'])
    data['documentation']['supporting_artifacts']=[a['token'] for a in hall['placements'] if a['role']!='tutorial']
    write(p,data)
    from em_map_halls import derive_row
    for p in [ROOT/'commons/data/museum/em_plan.json',ROOT/'commons/data/museum/em_plan.json']:
        backup(p);data=read(p)
        for i,row in enumerate(data['plans']):
            if row.get('sequence')=='forces' and row.get('map')==MAP:
                data['plans'][i]=derive_row(row['pearl'],MAP,row['museum'],hall['number']-1,len(plan['halls']),'forces')
        write(p,data)
    print('Added punching bag beside recoil; existing route, hall size and tutorial carrier retained.')

if __name__=='__main__':main()

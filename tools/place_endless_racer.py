"""Add a reachable racer bay in the gap before the capability court."""
from pathlib import Path
import json, shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-07-endless-drive'
MAP='Vectors_Act5_ForceAsPlace'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d):p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
def backup(p):
    dest=OUT/'before'/p.relative_to(ROOT)
    if not dest.exists():
        dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
def main():
    p=ROOT/'commons/artifacts/registry/force_play.json';backup(p);d=read(p)
    d['artifacts']['endless_racer']=dict(lookup_name='endless_racer',name='Endless Drive',scene='res://commons/artifacts/endless_racer/endless_racer.tscn',category='vectors_forces',map_ready=True,include_in_map_data=True,map_sequences=['forces'],footprint=[6,3,6],parameters={'footprint':[6,3,6],'size_group':'large'},description='Board an arcade car inside the museum. Grip the steering wheel, right trigger accelerates, left trigger brakes. A bounded road pool supplies endless bends, collectible cubes and barriers. Reachable restart and museum return.',qfep_connection='Steering selects a path while speed, inertia and resistance constrain corrections. Arcade rules are explicit; this is not a physical tyre model or an entropy measurement.')
    write(p,d)
    p=ROOT/'commons/artifacts/force_halls/curation.json';backup(p);cur=read(p)
    hall=next(h for h in cur['halls'] if h['map']==MAP)
    if not any(x['token']=='endless_racer' for x in hall['placements']):
        hall['placements'].append(dict(token='endless_racer',cell=[11,20],zone=[6,6],role='comparison',rotation=180,y=0,config='',pedestal=False))
    next(x for x in hall['placements'] if x['token']=='endless_racer')['cell']=[11,20]
    hall['after_count']=len(hall['placements']);write(p,cur)
    p=ROOT/f'commons/maps/{MAP}/map_data.json';backup(p);d=read(p)
    if d['layers']['interactables'][21][11].startswith('endless_racer'):d['layers']['interactables'][21][11]=''
    assert not d['layers']['interactables'][20][11].strip() or d['layers']['interactables'][20][11].startswith('endless_racer')
    d['layers']['interactables'][20][11]='endless_racer:180#pin:1#plinth:0'
    # One decorative column occupied the car's left wheel. Open this bay, keeping
    # the cross-wall and its central doorway at z=23.
    assert d['layers']['structure'][20][10] in ('w','1')
    d['layers']['structure'][20][10]='1'
    d['map_info']['metadata']['n_artifacts']=len(hall['placements'])
    d['documentation']['supporting_artifacts']=[x['token'] for x in hall['placements'] if x['role']!='tutorial'];write(p,d)
    from em_map_halls import derive_row
    for p in [ROOT/'commons/data/museum/em_plan.json',ROOT/'commons/data/museum/em_plan.json']:
        backup(p);d=read(p)
        for i,r in enumerate(d['plans']):
            if r.get('sequence')=='forces' and r.get('map')==MAP:d['plans'][i]=derive_row(r['pearl'],MAP,r['museum'],hall['number']-1,len(cur['halls']),'forces')
        write(p,d)
    print('Endless Drive bay added; final Forces tutorial remains the thrust sphere.')
if __name__=='__main__':main()

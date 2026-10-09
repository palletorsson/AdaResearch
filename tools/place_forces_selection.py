"""Place Palle's fifteen picker selections; preserve the eleven tutorial anchors."""
from pathlib import Path
import json, shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-07-forces-selected-in-the-halls'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,data):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
def backup(p):
    dest=OUT/'before'/p.relative_to(ROOT)
    if not dest.exists():dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
def a(token,x,z,zone,config='',y=0,pedestal=False,rotation=0):
    return dict(token=token,cell=[x,z],zone=zone,config=config,y=y,pedestal=pedestal,rotation=rotation,role='comparison')
ADDITIONS={
 'VFM_05_Launch':([44,88],[a('bubble_blaster',32,12,[4,4],y=.95,pedestal=True),a('catapult',33,32,[12,20],'default_force:9'),a('human_catapult',10,62,[14,32]),a('firework_burst',31,66,[16,16],'lesson:live_fountain')]),
 'VFM_03_Motion':([28,56],[a('force_mower',14,46,[10,8],'workings:expression')]),
 'Vectors_Act3_FieldsAndMotion':([28,84],[a('wind_room',14,52,[16,14],'lesson:hands_on_wind'),a('force_vortex',14,72,[10,10],'warning:beacon')]),
 'Vectors_Act4a_KineticForces':([30,80],[a('viscosity_layers',15,52,[8,6],y=.82,pedestal=True,rotation=180),a('centrifuge_ring',15,69,[12,12],'lesson:hand_ring')]),
 'Vectors_Act4b_Oscillation':([30,72],[a('SpringSuspension',8,61,[8,8],'lesson:museum_spring'),a('spring_tower',22,61,[8,8])]),
 'VFM_07_Gravity':([34,80],[a('orbit_walk',17,70,[10,10])]),
 'VFM_08_Arena':([28,64],[a('momentum_cradle',8,55,[5,4],rotation=180),a('newton_cradle',18,55,[5,4],y=.82,pedestal=True,rotation=180)])
}
NOTES={
 'VFM_05_Launch':'The selected Bubble Blaster carries the launch velocity in the hand. Compare the existing Launch Arc with a projectile catapult and a human catapult. The enlarged fountain runs ballistic trajectories and pauses its own clock near the apex; the museum continues running.',
 'VFM_03_Motion':'The mower applies the earlier projection to work: integrate the nominal drawn force along the actual displacement. Its force is a declared model value, not a measurement of pressure from the hand.',
 'Vectors_Act3_FieldsAndMotion':'The upgraded Wind Room drives rigid cubes and familiar points with relative-velocity drag. Aim a held rose point to steer the air, or use the controls at the entry. Walk through the same field. Compare the older Force Vortex, which prescribes a spiral velocity and ejects the visitor, with the primary vortex that integrates acceleration.',
 'Vectors_Act4a_KineticForces':'Viscosity Layers returns the drag comparison at bench scale. The centrifuge adds a circular hand ride: hold the rose handle, travel around the ring, release into the tangent. It prescribes the circular motion; it does not simulate a physical hinge or rotate the tracked head.',
 'Vectors_Act4b_Oscillation':'Compare the physical 6DOF SpringSuspension joint, now pulled with a rose hand grip, with Spring Tower, whose cosine animation illustrates a period. The existing coupled PointBody springs remain the tutorial object.',
 'VFM_07_Gravity':'Orbit Walk is a prescribed two-body barycentre diagram. It is a controlled comparison beside the primary mutually attracting points, whose trajectories are integrated.',
 'VFM_08_Arena':'Compare two presentations: Momentum Cradle shows ideal input/output poses; Newton\'s Cradle integrates pendulum angles with an idealized equal-mass collision exchange. Neither is the Jolt collision solver used by bowling.'
}
def main():
    path=ROOT/'commons/artifacts/force_halls/curation.json';backup(path)
    plan=read(path);selected=[]
    for h in plan['halls']:
        if h['map'] not in ADDITIONS:continue
        size,extra=ADDITIONS[h['map']];h['size']=size
        for item in extra:
            existing=next((p for p in h['placements'] if p['token']==item['token']),None)
            if existing:existing.update(item)
            else:h['placements'].append(item)
            selected.append(dict(map=h['map'],**item))
        mp=ROOT/f"commons/maps/{h['map']}/map_data.json";backup(mp);data=read(mp)
        style=next(str(v).split('#')[0] for line in data['layers']['interactables'] for v in line if str(v).startswith('force_hall_'))
        w,d=size;center=w//2
        layers={k:[['']*w for _ in range(d)] for k in ['structure','utilities','interactables']}
        for z in range(d):
            for x in range(w):
                edge=x in [0,w-1] or z in [0,d-1];passage=z in [0,d-1] and abs(x-center)<=2
                layers['structure'][z][x]='w' if edge and not passage else '1'
        layers['utilities'][3][center]='s';layers['utilities'][d-4][w-3]='t'
        for p in h['placements']:
            x,z=p['cell'];layers['interactables'][z][x]=f"{p['token']}:{p['rotation']}:{p['y']}:1#pin:1#plinth:0"+('#'+p['config'] if p.get('config') else '')
        layers['interactables'][0][0]=style+'#pin:1#plinth:0';data['layers']=layers
        data['map_info']['dimensions']={'width':w,'depth':d,'max_height':8}
        data['map_info']['museum'].update(open_roof=True,plinths=False,piers=False,sculpture_clear_rects=[[0,0,w-1,d-1]])
        data['documentation']['supporting_artifacts']=[p['token'] for p in h['placements'] if p['role']!='tutorial']
        data['map_info']['metadata']['n_artifacts']=len(h['placements'])
        data['map_info']['version']='force-selection-2026-10-07';write(mp,data)
        h['walk']=[[center+.5,3.5],[w-2.5,3.5],[w-2.5,d-4.5]];h['after_count']=len(h['placements'])
        h['selection_note']=NOTES[h['map']]
        lp=mp.parent/'FORCES_LESSON.md';backup(lp);text=lp.read_text(encoding='utf8')
        if '\n## Selected comparisons\n' in text:text=text.split('\n## Selected comparisons\n')[0]
        lp.write_text(text.rstrip()+'\n\n## Selected comparisons\n\n'+h['selection_note']+'\n',encoding='utf8')
    selected.append(dict(map='VFM_05_Launch',token='launch_arc',role='tutorial',already_placed=True))
    for item in plan['keep_disposition']:
        item['halls']=[h['map'] for h in plan['halls'] if any(p['token']==item['token'] for p in h['placements'])]
        if item['halls']:item['status']='main walk'
    plan['picker_selection']=[p['token'] for p in selected];write(path,plan)
    write(OUT/'selection.json',{'date':'2026-10-07','artifacts':selected,'notes':NOTES})
    write(ROOT/'doc/vector_forces_selected.json',{'date':'2026-10-07','source':'Explicit user selection; complements the one-item-per-tier picker choices.','artifacts':selected})
    from em_map_halls import derive_row
    live=ROOT/'commons/data/museum/em_plan.json';backup(live);museum=read(live)
    for i,row in enumerate(museum['plans']):
        if row.get('sequence')=='forces' and row.get('map') in ADDITIONS:
            h=next(h for h in plan['halls'] if h['map']==row['map'])
            museum['plans'][i]=derive_row(row['pearl'],row['map'],row['museum'],h['number']-1,len(plan['halls']),'forces')
    write(live,museum)
    fallback=ROOT/'commons/data/museum/em_plan.json';backup(fallback);shutil.copy2(live,fallback)
    print('15 selected artifacts in 7 Forces halls; tutorial anchors and eleven-hall order retained.')
if __name__=='__main__':main()

"""Place the requested physical studies in the existing eleven-hall Forces route.
Only listed Forces maps and their derived museum rows are changed. Earlier Keep
choices remain collection alternatives. Full book manuscripts are not generated.
"""
from pathlib import Path
import json,copy,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-07-forces-extravaganza'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,data):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
def backup(p):
    dest=OUT/'before'/p.relative_to(ROOT)
    if p.exists() and not dest.exists():dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
def p(kind,x,z,zone,role='comparison'):
    return dict(token='force_play_'+kind,cell=[x,z],zone=zone,role=role,rotation=0,y=0,config='',pedestal=False)
CATALOG={
 'tower':('One brick holds the question',[10,7,12],'Pull the bottom rose brick; forty-two upper bricks lose their support. A companion table has nine loose hand-stackable shapes and its own reset.'),
 'gravity':('The room lets go',[22,5,10],'An entry threshold releases a hinged trapdoor, suspended cargo and a leaning pole.'),
 'mass':('Same force, different mass',[12,4,10],'Equal-size PointBody spheres: 1, 2 and 4 kg; a matched one-newton pulse.'),
 'trolley':('Load changes the push',[10,4,10],'Load the cart and pull its hand grip. A low-friction sliding carrier with decorative wheels.'),
 'puzzle':('Make room for a body',[10,4,10],'Three weighted cubes, staggered walls and destination marks; push and rearrange.'),
 'bowling':('Ten pins, one commitment',[10,5,25],'Ten compound rigid pins, a black sphere, long lane, bumpers and banked sides.'),
 'recoil':('The launcher also moves',[12,4,10],'Compare equal opposite impulses on free and braced carts.'),
 'friction':('The slope does not choose the ending',[24,5,16],'Four slopes compare cube/ball and smooth/rough contact; trajectories leave trails.'),
 'liquids':('Walk into resistance',[24,5,16],'Three large transparent drag regions slow falling points and the visitor. Approximate drag and buoyancy, not fluid simulation.'),
 'springs':('Pull one, disturb the row',[18,5,12],'Seven hanging familiar points share restoring springs; pull one and disturb its neighbours.'),
 'swings':('How long should a disturbance last',[24,5,11],'Three connected swing pairs compare weak, medium and strong damping.'),
 'torque':('Where you push matters',[22,5,10],'A gate, seesaw and crank retain actual hinges while rose hand grips transmit forces.'),
 'constraints':('Attachment changes the possible',[24,5,11],'Basket, three-link chain, suspended plank and articulated arm use physical joints.'),
 'magnet':('The catch must end',[14,5,14],'A large timed magnet attracts twelve prefabs for three seconds. A held point also becomes a trigger-driven gravity gun.'),
 'vortex':('The field takes a turn',[20,5,18],'Eighteen prefabs move through a visible swirl; the visitor meets the same acceleration field.'),
 'mutual':('You become another source',[20,5,20],'Five larger orbiting points; the visitor becomes the sixth source. Softened attraction with contact disabled.'),
 'support':('Move a leg, inherit the load',[18,6,16],'Move an actual table leg beneath a tall uneven load; contacts decide the collapse.'),
 'flight':('A mat, two points, a way through',[14,7,26],'Two inherited trigger-thrust points carry the visitor and a visual flying mat through four elevated gates.')
}
def build():
    for kind,(title,footprint,description) in CATALOG.items():
        scene=ROOT/f'commons/artifacts/force_play/{kind}.tscn'
        scene.write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://commons/artifacts/force_play/encounter.gd" id="1"]\n[node name="ForcePlay" type="Node3D"]\nscript = ExtResource("1")\nkind = '+json.dumps(kind)+'\n',encoding='utf8')
    registry={f'force_play_{k}':dict(lookup_name=f'force_play_{k}',name=v[0],scene=f'res://commons/artifacts/force_play/{k}.tscn',category='vectors_forces',map_ready=True,include_in_map_data=True,map_sequences=['forces'],footprint=v[1],parameters={'footprint':v[1],'size_group':'large'},description=v[2]) for k,v in CATALOG.items()}
    write(ROOT/'commons/artifacts/registry/force_play.json',{'artifacts':registry})
    path=ROOT/'commons/artifacts/force_halls/curation.json';backup(path)
    # Idempotent migration from the pre-pass arrangement, not from earlier sessions.
    plan=read(OUT/'before'/path.relative_to(ROOT));halls={h['map']:h for h in plan['halls']}
    motion=halls['VFM_03_Motion'];motion.update(size=[28,40],placements=[p('mass',14,10,[12,10],'tutorial'),p('trolley',8,28,[10,10]),p('puzzle',20,28,[10,10])],tutorial_artifact='force_play_mass')
    motion['lesson']='Keep the familiar PointBody, with matched visible radius, height and collision shape. Apply the same one-newton force for one second to 1, 2 and 4 kg spheres; read acceleration and the retained velocity after the push. The loaded trolley and push-box puzzle let the same relation become a task. Reconstruct only the equal-force comparison.'
    launch=halls['VFM_05_Launch'];launch['size']=[30,50];launch['placements'].append(p('torque',15,41,[22,10]));launch['lesson']+=' Compare a gate, seesaw and crank by pulling their rose grips at different distances from the physical pivot. The existing catapult remains the launch comparison.'
    fields=halls['Vectors_Act3_FieldsAndMotion'];fields.update(size=[28,44],placements=[p('vortex',14,13,[20,18],'tutorial'),next(a for a in fields['placements'] if a['token']=='VectorFieldFlow')],tutorial_artifact='force_play_vortex');fields['placements'][1]['cell']=[14,35]
    fields['lesson']='Give the known PointBody a position-dependent acceleration with inward and tangential components. Solid cylinder arrows make the field legible; eighteen spheres, cubes and cylinders supply receivers. Walk into it and feel the same acceleration through the existing player movement adapter. Reconstruct the field sample and its receiver, then change the balance without prescribing a path.'
    kinetic=halls['Vectors_Act4a_KineticForces'];kinetic.update(size=[30,48],placements=[p('liquids',15,13,[24,16],'tutorial'),p('friction',15,35,[24,16])],tutorial_artifact='force_play_liquids',principle='Speed-dependent drag, buoyancy approximation and contact friction')
    kinetic['lesson']='Drop the same PointBody into three large regions and compare speed-dependent drag. Walk through the same coefficients. Distinguish this resistance model and its constant upward buoyancy term from a fluid solver. Then release cubes and balls on four slopes: smooth/rough contact changes sliding and rolling. The tutorial reconstructs the point in one drag region; the ramps are comparisons. Trails retain the consequence.'
    springs=halls['Vectors_Act4b_Oscillation'];springs.update(size=[30,52],placements=[p('springs',15,11,[18,12],'tutorial'),p('swings',15,28,[24,11]),p('constraints',15,43,[24,11])],tutorial_artifact='force_play_springs',principle='Restoring force, coupling, damping and constraints')
    springs['lesson']='Return the point to a displaced rest length with a spring force; its position evolves through the physics engine. Pull one of seven hanging points and follow the response through neighbour springs. Compare three connected swing pairs with increasing damping, then basket, chain, plank and arm constraints. Reconstruct one spring first; coupling is one return of the same relation. Hinge grip proxies transmit force while preserving the joint.'
    gravity=halls['VFM_07_Gravity'];gravity.update(size=[34,64],placements=[p('mutual',17,14,[20,20],'tutorial'),p('magnet',10,36,[14,14]),p('tower',26,36,[10,12]),p('gravity',17,54,[22,10])],tutorial_artifact='force_play_mutual')
    gravity['lesson']='Let five PointBody spheres attract one another with paired forces, softened at close range. Initial tangential velocity and disabled contact keep this an orbital model; entering adds the visitor as a sixth model mass. Compare a selective, three-second magnet and a hand-held gravity point with ordinary gravity: remove a bottom brick, cross a release threshold, and watch existing support cease to hold. Reconstruct the pairwise relation; the other experiments expose different boundary conditions.'
    support=halls['VFM_09_Legs'];support.update(size=[28,40],placements=[p('support',14,13,[18,16],'tutorial')]+support['placements'][1:],tutorial_artifact='force_play_support')
    for a in support['placements'][1:]:a['cell'][1]=31
    support['lesson']='Reuse the cube as a leg and the point/cube family as a load. Four actual rigid legs support a table with a tall asymmetric stack. Pull the rose leg away by hand: no fall animation or scripted collapse decides the result. Compare the existing walking bodies as changing support arrangements. The tutorial reconstructs one support-and-load contact experiment.'
    arena=halls['VFM_08_Arena'];arena.update(size=[28,51],tutorial_artifact='force_play_bowling')
    arena['placements']=[p('bowling',8,17,[10,25],'tutorial')]+[a for a in arena['placements'] if a['token'] in ['sentry_turret','ball_dropper','queer_cylinder_target']]+[p('recoil',9,41,[12,10])]
    arena['lesson']='Roll the known sphere into ten real pins along a long banked lane. The impulse initiates motion; contact distributes it. Compare a free and a braced launcher receiving equal opposite impulses. Keep the target bay as a separate question about what is selected. Reconstruct the sphere impulse and observe the pin contacts; pins need not become ten separate tutorials.'
    final=halls['Vectors_Act5_ForceAsPlace'];final['size']=[16,84];final['placements'].append(p('flight',8,68,[14,26]));final['lesson']+=' The flying-mat circuit returns those same two trigger-thrust points at four raised gates. The mat is a visual carrier of the player movement model; release stops thrust while gravity remains. The mortar now has nine posts and its controls face the approach.'
    changed=[h for h in plan['halls'] if h['map'] not in ['Vectors_Act1_WhatAVectorIs','Change_Choreography']]
    for h in changed:
        mp=ROOT/f"commons/maps/{h['map']}/map_data.json";backup(mp);data=read(OUT/'before'/mp.relative_to(ROOT));w,d=h['size'];center=w//2
        style=next(str(v).split('#')[0] for line in data['layers']['interactables'] for v in line if str(v).startswith('force_hall_'))
        if h['map']=='Vectors_Act5_ForceAsPlace':
            old_depth=len(data['layers']['structure'])
            for key,L in data['layers'].items():L.extend([['']*w for _ in range(d-old_depth)])
            for z in range(old_depth-1,d):
                for x in range(w):data['layers']['structure'][z][x]='w' if x in [0,w-1] or (z==d-1 and abs(x-center)>2) else '1'
            for line in data['layers']['utilities']:
                for x,v in enumerate(line):
                    if v=='t':line[x]=''
            data['layers']['utilities'][d-3][center]='t'
            new=h['placements'][-1];data['layers']['interactables'][new['cell'][1]][new['cell'][0]]=new['token']+'#pin:1#plinth:0'
            h['walk'] += [[2.5,52.5],[13.5,52.5],[13.5,80.5]]
        else:
            L={k:[['']*w for _ in range(d)] for k in ['structure','utilities','interactables']}
            for z in range(d):
                for x in range(w):
                    boundary=x in [0,w-1] or z in [0,d-1];passage=z in [0,d-1] and abs(x-center)<=2
                    L['structure'][z][x]='w' if boundary and not passage else '1'
            L['utilities'][3][center]='s';L['utilities'][d-4][w-3]='t'
            for a in h['placements']:
                x,z=a['cell'];L['interactables'][z][x]=f"{a['token']}:{a['rotation']}:{a['y']}:1#pin:1#plinth:0"+('#'+a['config'] if a['config'] else '')
            L['interactables'][0][0]=style+'#pin:1#plinth:0';data['layers']=L
            h['walk']=[[center+0.5,3.5],[w-2.5,3.5],[w-2.5,d-4.5]]
        data['map_info'].update(title=h['title'],description=h['lesson'],version='force-play-2026-10-07',dimensions={'width':w,'depth':d,'max_height':8})
        data['map_info'].setdefault('museum',{}).update(plinths=False,open_roof=True,piers=False,sculpture_clear_rects=[[0,0,w-1,d-1]])
        h['after_count']=len(h['placements']);data['map_info'].setdefault('metadata',{}).update(tutorial_artifact=h['tutorial_artifact'],learning_objectives=[h['principle']],n_artifacts=h['after_count'])
        data['documentation'].update(tutorial_artifact=h['tutorial_artifact'],supporting_artifacts=[a['token'] for a in h['placements'] if a['role']!='tutorial'])
        write(mp,data)
        lp=mp.parent/'FORCES_LESSON.md';backup(lp)
        lp.write_text('# '+h['title']+'\n\nArtifact and lesson contract, 7 October 2026. Full tutorial.md and final.md remain separate manuscripts.\n\nTutorial anchor: `'+h['tutorial_artifact']+'`.\n\n'+h['lesson']+'\n\nCarry onward: '+h['carry']+'\n\nIndependent check: '+h['independent_check']+'\n',encoding='utf8')
    for item in plan['keep_disposition']:
        item['halls']=[h['map'] for h in plan['halls'] if any(a['token']==item['token'] for a in h['placements'])]
        if item['status']!='needs construction':item['status']='main walk' if item['halls'] else 'collection alternative'
    plan['force_play']='Eighteen larger hand-led studies added to the existing eleven-hall route; one tutorial anchor per principle, comparisons remain optional.'
    write(path,plan);write(OUT/'curation.json',plan);write(OUT/'artifact-list.json',{k:dict(title=v[0],footprint=v[1],description=v[2]) for k,v in CATALOG.items()})
    seqp=ROOT/'commons/maps/sequences/forces.json';backup(seqp);seq=read(seqp);route=seq['sequences']['forces']
    route['tutorial_progression']=[dict(map=h['map'],artifact=h['tutorial_artifact'],subject=h['principle'],carry=h['carry']) for h in plan['halls']]
    route['content']=[h['map']+': '+h['principle'] for h in plan['halls']];write(seqp,seq)
    primary=ROOT/'doc/book/course/forces-primary-objects.json';backup(primary);proposal=read(primary)
    for r in proposal['halls']:
        if r['map'] in [h['map'] for h in changed]:
            h=halls[r['map']];r.update(current=h['lesson'],tutorial=h['lesson'],primary=h['tutorial_artifact'],status='Implemented prototype; see forces-extravaganza verification. Headset trial remains open.')
    write(primary,proposal)
    from em_map_halls import derive_row
    live=ROOT/'commons/data/museum/em_plan.json';backup(live);museum=read(live)
    for i,row in enumerate(museum['plans']):
        if row.get('sequence')=='forces' and row.get('map') in [h['map'] for h in changed]:
            h=halls[row['map']];museum['plans'][i]=derive_row(row['pearl'],row['map'],row['museum'],h['number']-1,len(plan['halls']),'forces')
    write(live,museum)
    fallback=ROOT/'commons/data/museum/em_plan.json';backup(fallback);shutil.copy2(live,fallback)
    print(f'Placed {len(CATALOG)} studies in {len(changed)} existing halls; vector room, choreography and original final-court pit retained.')
if __name__=='__main__':build()

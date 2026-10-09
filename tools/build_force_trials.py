"""Build the optional review route and inventory. Never rewrite the canonical Forces spine."""
from pathlib import Path
import json, re, shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-07-forces-ten-more'
PUBLIC = ROOT.parent/'ada_encyclopedia/public'
TRIALS = [
 ('mass','Same force, different mass',12,'A timed force pulse gives the familiar points different accelerations. Coast after the pulse; compare 1, 2 and 4 kg.','Force, mass, acceleration; ending a force preserves velocity.'),
 ('vortex','The drain becomes an orbit',15,'Release the point into a radial field, then add a sideways component. A cube can join it; the path is integrated, not animated.','Field composition, initial velocity, resistance.'),
 ('roll','Slide, roll or tip?',18,'Release a rotation-locked sphere, a free sphere and a cube on three equal slopes. Compare contact, rolling and sticking.','Friction, shape, rotational freedom.'),
 ('pipe','Where the pipe lets go',19,'Send the point through a transparent, open curved channel. Predict where it leaves; the channel stops but motion and gravity continue.','Contact redirects velocity; tangent and ballistic departure.'),
 ('conveyor','The belt keeps going',24,'Feed twelve cubes against a closed receiver. Open the gate and see which boxes still make it. Spilled boxes remain available.','Contact motion, input/output rate, accumulated backlog.'),
 ('attractor','It caught the doorstop',25,'Attract the chosen point, then widen the filter to include the doorstop. The hinged door keeps trying to close.','Attraction, selection, unintended secondary effects.'),
 ('threebody','Three bodies, two beginnings',26,'Release two planar trios with one small velocity difference. Compare their paths with equal opposite forces and softened near contact.','Pairwise force sums, initial conditions, limits of prediction.'),
 ('support','Remove one support',27,'Let a loaded table settle. Pull the marked foot and keep the collapse, or rebuild it by hand.','Support, centre of mass, contact and structural dependence.'),
 ('bowling','One push, two directions',29,'Send the point into a little bowling formation. Compare a braced launch cart with a free one; retain the knocked blocks.','Impulse, recoil, momentum transfer.'),
 ('catapult','The lever lets go',9,'Release a point from a hinged cup driven by a short torque pulse. Its flight comes from contact with the arm.','Torque, hinge constraint, release and trajectory.'),
]

def read(p):
    return json.loads(re.sub(r',\s*([\]}])',r'\1',p.read_text(encoding='utf-8-sig')))

def write(p,d):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def build():
    OUT.mkdir(parents=True,exist_ok=True)
    registry={};maps=[]
    base=read(ROOT/'commons/maps/Vectors_Act5_ForceAsPlace/map_data.json')
    for i,(kind,title,idea,action,learn) in enumerate(TRIALS,1):
        token='force_trial_'+kind;map_id=f'Force_Review_{i:02d}_{kind.title()}'
        maps.append(map_id)
        scene=ROOT/f'commons/artifacts/force_trials/{kind}.tscn'
        scene.parent.mkdir(parents=True,exist_ok=True)
        scene.write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://commons/artifacts/force_trials/trial.gd" id="1"]\n\n[node name="ForceTrial" type="Node3D"]\nscript = ExtResource("1")\nkind = "'+kind+'"\n',encoding='utf-8')
        registry[token]={'lookup_name':token,'name':title,'scene':'res://'+scene.relative_to(ROOT).as_posix(),'category':'vectors_forces','map_ready':True,'include_in_map_data':True,'map_sequences':['forces_review'],'footprint':[10,5,11],'parameters':{'footprint':[10,5,11],'size_group':'large'},'description':action,'learning_objectives':[learn],'qfep_connection':'An available operation changes a situation; the body and environment retain its consequence. This trial makes no numerical entropy claim.','illustrated_idea':idea,'review_map':map_id}
        w,d=16,18
        layers={'structure':[['w' if (x in (0,w-1) or z in (0,d-1)) and not (z in (0,d-1) and x in (7,8,9)) else '1' for x in range(w)] for z in range(d)],'utilities':[['']*w for _ in range(d)],'interactables':[['']*w for _ in range(d)]}
        layers['utilities'][2][8]='s';layers['interactables'][9][8]=token+'#pin:1#plinth:0'
        next_kind=TRIALS[i % len(TRIALS)][0]
        layers['utilities'][14][13]='t' # the optional route owns its next hall
        info={'name':map_id,'lookup_name':map_id,'title':title,'description':action,'version':'force-review-2026-10-07','format':'json','dimensions':{'width':w,'depth':d,'max_height':4},'metadata':{'difficulty':'intermediate','category':'vectors_forces','learning_objectives':[learn],'n_artifacts':1},'museum':{'artifact_placement':'map','wall_height':4,'gate_depth_rows':0,'sculpture_clear_rects':[[1,1,14,16]]}}
        write(ROOT/f'commons/maps/{map_id}/map_data.json',{'map_info':info,'lighting':base.get('lighting',{}),'settings':base.get('settings',{}),'layers':layers})
    write(ROOT/'commons/artifacts/registry/force_trials.json',{'artifacts':registry})
    write(ROOT/'commons/maps/sequences/forces_review.json',{'sequences':{'forces_review':{'name':'Forces — ten more trials','description':'Optional curation route: compare ten playable experiments before selecting the final spine.','maps':maps,'difficulty':'intermediate','prerequisites':['forces'],'artifact_groups':[]}},'world_phase':'grid','artifact_groups':[]})
    authored=read(ROOT/'commons/data/map_authored.json')
    authored['forces_review']=maps
    write(ROOT/'commons/data/map_authored.json',authored)
    (ROOT/'commons/scenes/force_trials_museum.tscn').write_text('[gd_scene load_steps=3 format=3]\n\n[ext_resource type="PackedScene" path="res://commons/scenes/endless_museum.tscn" id="1"]\n[ext_resource type="Script" path="res://commons/scenes/force_trials_museum.gd" id="2"]\n\n[node name="EndlessMuseum" instance=ExtResource("1")]\nscript = ExtResource("2")\nstart_chapter = "forces_review"\nstart_map = "'+maps[0]+'"\nplan_file = "res://commons/artifacts/force_trials/review_plan.json"\n',encoding='utf-8')
    plans=[]
    for i,m in enumerate(maps):
        token='force_trial_'+TRIALS[i][0]
        layers=read(ROOT/f'commons/maps/{m}/map_data.json')['layers']
        plans.append({'museum':'sainsbury-false-perspective-enfilade','sequence':'forces_review','pearl':m.lower(),'pearl_index':i,'pearls_total':10,'map':m,'authored':'map','room':{'w':16,'h':18},'h':18,'rooms':0,'apron':0,'ordered':True,'tile':layers['structure'],'artifacts':[{'token':token,'cell':[8,9],'tile_cell':[8,9],'rotation':0,'mode':'freestanding','venue':'interior','support_height_m':0,'config':{'pin':'1','plinth':'0'}}]})
    write(ROOT/'commons/artifacts/force_trials/review_plan.json',{'schema':2,'plans':plans,'museums':{}})
    write(ROOT/'commons/artifacts/force_trials/review_order.json',{'order':[{'lookup':'force_trial_'+k,'sequence':'forces_review'} for k,*_ in TRIALS]})
    write(OUT/'trials.json',[dict(kind=k,title=t,idea=n,action=a,learn=l,token='force_trial_'+k,map=maps[i]) for i,(k,t,n,a,l) in enumerate(TRIALS)])
    inventory()

def inventory():
    all_items={}
    for p in sorted((ROOT/'commons/artifacts/registry').glob('*.json')):
        try:d=read(p)
        except Exception:continue
        for k,v in d.get('artifacts',{}).items():
            if isinstance(v,dict):all_items[k]=(v,p)
    sequence=read(ROOT/'commons/maps/sequences/forces.json')['sequences']['forces']
    places={}
    for m in sequence['maps']:
        d=read(ROOT/f'commons/maps/{m}/map_data.json')
        for row in d['layers'].get('interactables',[]):
            for v in row:
                if isinstance(v,str) and v.split('#')[0] in all_items:
                    places.setdefault(v.split('#')[0],set()).add(m)
    selected={k:v for k,v in all_items.items() if 'forces' in v[0].get('map_sequences',[]) or k in places or v[1].stem in ['vectors','vectors_demos','vector_arena','force_vortex','force_pad','force_capability_lab','mortar_vector_siege','free_ball_launcher','force_trials']}
    # Registry aliases sharing the exact same scene are one candidate with multiple names.
    by_scene={}
    for token,(v,p) in selected.items():
        scene=v.get('scene','')
        if not scene:continue
        item=by_scene.setdefault(scene,{'token':token,'aliases':[],'title':v.get('name',token),'description':v.get('description',''),'scene':scene,'registry':p.relative_to(ROOT).as_posix(),'category':v.get('category',p.stem),'halls':[],'tags':v.get('tags',[]),'new':p.stem=='force_trials','scene_exists':(ROOT/scene.removeprefix('res://')).is_file(),'preview':None,'preview_note':'No verified image found yet.'})
        if token!=item['token']:item['aliases'].append(token)
        item['halls']=sorted(set(item['halls'])|places.get(token,set()))
    # XL and laser variants delegate to a real scene instead of naming one.
    # Keep them attached to that scene, including their different parameters.
    for token,(v,p) in selected.items():
        if not v.get('delegate_to'):continue
        target=v['delegate_to'];visited=set()
        while target in all_items and target not in visited:
            visited.add(target);entry=all_items[target][0]
            scene=entry.get('scene','')
            if scene:
                if scene in by_scene:
                    item=by_scene[scene]
                    item['aliases'].append(token)
                    item.setdefault('variants',[]).append({'token':token,'parameters':v.get('delegate_params',{}),'description':v.get('description','')})
                    item['halls']=sorted(set(item['halls'])|places.get(token,set()))
                break
            target=entry.get('delegate_to','')
    # Use exact token captures first. Parameter variants are explicitly labelled.
    dirs=['vector-bench-gallery','vector-toys-gallery','forces-props-dna','artifact-gallery','prop-shots','prop-shots-curated','vector-bench-gallery','station-shots','godot-captures','scene-catalog','gallery','artifact-in-map','forces-concepts']
    images=[]
    for name in dirs:
        images.extend((PUBLIC/name).rglob('*.png'))
    all_images=list(PUBLIC.rglob('*.png'))
    images=list(dict.fromkeys(images+all_images))
    (OUT/'images').mkdir(exist_ok=True)
    for item in by_scene.values():
        token=item['token']
        if item['new']:continue
        chosen=None;variant=False
        names=[token]+item['aliases']
        for name in names:
            exact=[p for p in images if p.stem==name or (p.parent.name==name and p.stem in ['front','hero','00'])]
            if exact:chosen=exact[0];break
        if chosen is None:
            for name in names:
                candidates=[p for p in images if p.stem in [f'vt_{name}_mid',name+'__shipped'] or p.stem.startswith(name+'__')]
                if candidates:chosen=candidates[0];variant=True;break
        if chosen:
            dest=OUT/'images'/f'{token}.png';shutil.copy2(chosen,dest)
            item['preview']='images/'+dest.name
            item['preview_note']='Existing Godot capture'+(' — parameter variant.' if variant else '.')+' Appearance reference; interaction not retested in this pass.'
            item['preview_source']=str(chosen)
    items=sorted(by_scene.values(),key=lambda x:(not x['new'],not bool(x['halls']),x['title'].lower()))
    write(OUT/'catalog.json',items)
    write(OUT/'missing-captures.json',[x for x in items if not x['new'] and not x['preview'] and x['scene_exists']])
    print(json.dumps({'unique_scenes':len(items),'new':sum(x['new'] for x in items),'existing_images':sum(bool(x['preview']) for x in items),'missing':sum(not x['new'] and not x['preview'] for x in items)},indent=2))

if __name__=='__main__':build()

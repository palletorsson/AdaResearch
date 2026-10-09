"""Author the selected Forces walk. The review choices remain a larger collection.

Edit HALLS, then run this file. Originals are preserved once under before/.
This edits placement and the lesson-role contract, not the full book manuscripts.
"""
from pathlib import Path
import json, re, shutil

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-07-forces-curated-progression'
DEST=ROOT/'commons/artifacts/force_halls'
def read(p): return json.loads(re.sub(r',\s*([\]}])',r'\1',p.read_text(encoding='utf-8-sig')))
def write(p,d):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
def p(token,x,z,role='comparison',rotation=180,config='',size=(4,4),y=0,pedestal=False):
    return dict(token=token,cell=[x,z],role=role,rotation=rotation,config=config,zone=list(size),y=y,pedestal=pedestal)
def h(map,title,size,principle,hero,placements,lesson,carry,check):
    return dict(map=map,title=title,size=list(size),principle=principle,tutorial_artifact=hero,
                placements=placements,lesson=lesson,carry=carry,independent_check=check)

HALLS=[
h('Vectors_Act1_WhatAVectorIs','The point gives a direction',(16,24),'Displacement, magnitude, unit direction','force_point_direction',[
 p('force_point_direction',8,8,'tutorial',0,size=(7,8)),p('magnitude_bench',4,18),p('stretch_bench',11,17,config='scale_multiplier:3',y=1.05,pedestal=True)],
 'Bring the grabbable PointBody from Coordinates. Move it relative to a fixed origin and read the displacement, its length and its unit direction. The rose unit marker is a separate reading; it never moves the held point for you. The magnitude and scaling benches offer comparisons, not two further reconstructions.',
 'A displacement with a declared origin and a direction separated from length.',
 'Move the point to another position; predict which readings change. Explain what zero displacement leaves undefined.'),
h('VFM_02_Operations','Two moves, one arrival',(20,28),'Vector addition and travelled route','force_point_addition',[
 p('force_point_addition',10,9,'tutorial',0,size=(7,8)),p('adder_board',5,22,config='scale_multiplier:3',y=1.05,pedestal=True),p('vector_addition_walk',15,22,size=(5,5))],
 'Keep the same point class and introduce a second displacement in the same frame. Place their arrows head to tail and build one result point from a+b. Compare the sum with the two travelled segments. The drafting board and walk-in construction let the same operation be read at two other scales.',
 'A sum can preserve an endpoint without preserving the journey.',
 'Choose cancelling displacements, then swap two unequal ones. Show the same arrival and a different intermediate position.'),
h('Vectors_Act2_VectorArithmetic','What the rail keeps',(22,28),'Projection and the remaining component','force_point_projection',[
 p('force_point_projection',11,9,'tutorial',0,size=(7,8)),p('dot_aligner',5,22),p('torque_crank',17,22)],
 'Continue with the held point. Project its displacement onto a fixed unit rail and retain the perpendicular remainder. Add the two parts to recover the original. The alignment and crank instruments are nearby comparisons: an alignment score, a component and a turning relation are different quantities. This lesson reconstructs only the projection point.',
 'A selected component does not erase what the operation leaves over.',
 'Move the point perpendicular to the rail; verify that the projection stays still while the remainder changes.'),
h('VFM_05_Launch','A beginning, then a flight',(28,38),'Initial velocity and constant acceleration','launch_arc',[
 p('launch_arc',14,8,'tutorial',180,'lesson:launch_chamber',size=(16,12)),p('force_trial_catapult',7,26,'experiment',0,size=(10,11)),p('force_trial_pipe',20,26,'experiment',0,size=(10,11))],
 'Give the point an initial velocity and observe how gravity changes its journey. Reconstruct the compact analytic trajectory with its stated constant-acceleration assumptions. Then compare the hinged catapult and the open pipe: their release velocities arise from contacts. The same appearance of a curve need not mean the same mechanism.',
 'Initial state and a rule for change; prediction can be compared with an actual release.',
 'Change launch speed or angle and predict the landing. Explain why a collision invalidates the simple analytic prediction.'),
h('VFM_03_Motion','The push ends. Motion stays.',(22,30),'Force, mass and retained velocity','force_trial_mass',[
 p('force_trial_mass',11,10,'tutorial',0,size=(10,11)),p('newton_bench',5,24),p('velocity_bench',17,24)],
 'The familiar PointBody now receives one timed force pulse. Compare equal-sized spheres of 1, 2 and 4 kg; the engine integrates their motion. Keep the small tutorial focused on applying force and ending it. The Newton and velocity benches support reading acceleration and coasting. They do not add separate code exercises.',
 'A dynamic point retains velocity after an input ends.',
 'Predict the velocity ordering for another mass. Verify that ending the pulse does not command a stop.'),
h('Vectors_Act3_FieldsAndMotion','The room gives a direction',(28,38),'Sample a field; retain a moving state','force_trial_vortex',[
 p('force_trial_vortex',8,10,'tutorial',0,size=(10,11)),p('field_room',22,9,size=(4,4)),p('VectorFieldFlow',14,28,'comparison',180,'lesson:field_receivers',size=(14,12))],
 'Reuse the dynamic point and evaluate a force from its current position. Begin with radial attraction, then add a sideways component. Compare it with the cube and with the existing two-receiver field chamber. The tutorial owns one point receiving a force; the chamber exposes the different consequence of directly assigning velocity.',
 'A local rule becomes a trajectory through repeated sampling.',
 'Release from a new position and compare radial-only with sideways force. Name the retained velocity that changes the result.'),
h('Vectors_Act4a_KineticForces','What resists the journey',(28,40),'Velocity-dependent drag','drag_corridor',[
 p('drag_corridor',14,11,'tutorial',0,'lesson:kinetic_drag',size=(14,14)),p('force_trial_roll',7,28,'experiment',0,size=(10,11)),p('force_mower',21,27,size=(7,7)),p('work_meter',21,35,size=(4,4))],
 'Keep a moving body and add resistance opposite to its velocity. Use the existing measured drag probes to compare coefficient and mass, then reconstruct one probe before comparing several. The slope contrasts sliding and rolling; the mower and work meter contrast travel with signed work. These remain supporting encounters rather than extra lesson implementations.',
 'A force may depend on the state it is changing.',
 'Predict how changing mass at fixed drag changes slowing. Distinguish the physical probes from the separate walking adapter.'),
h('Vectors_Act4b_Oscillation','A force toward home',(26,34),'Restoring force and damping','spring_tower',[
 p('spring_tower',13,9,'tutorial',0,'lesson:restoring_forces',size=(12,12)),p('calder_mobile',6,26,size=(5,5)),p('coupled_pendulums',20,26,size=(4,4),y=1.05,pedestal=True)],
 'Keep displacement and velocity but make the force point toward an equilibrium. Pull and release the existing one-dimensional spring handle; compare free motion with damping. Reconstruct this one update, with the fixed-step runner supplied. Its constrained cube handle is an honest exception to the sphere appearance. The balanced mobile and coupled pendulums open other outcomes without multiplying the tutorial.',
 'Restoration and resistance can act together; a periodic appearance can have a dynamic cause.',
 'Choose a new displacement and damping. Predict whether the body crosses equilibrium, then test the release.'),
h('Change_Choreography','The next body arrives',(24,34),'Phase, rate and accumulated backlog','phase_rod_array',[
 p('phase_rod_array',12,8,'tutorial',180,size=(9,8)),p('force_trial_conveyor',12,24,'experiment',0,size=(10,11))],
 'Reuse the clock and repeated objects. Change phase in the existing rod array and distinguish a fixed offset from a different rate. This lesson is prescribed motion, following the spring whose motion was integrated. At the belt, contact and a closed receiver turn continuing input into a backlog. The belt is the consequence to explore, not another program to reconstruct here.',
 'Repeated local actions can accumulate into a new condition.',
 'Make a fixed phase difference, then a growing one. Explain why opening a gate does not undo cubes already spilled.'),
h('VFM_07_Gravity','The source can move too',(28,40),'Pairwise attraction and initial conditions','force_trial_threebody',[
 p('force_trial_threebody',14,10,'tutorial',0,size=(10,11)),p('force_trial_attractor',7,28,'experiment',0,size=(10,11)),p('orbital_mechanics_demo',21,27,size=(4,4),y=1.3,pedestal=True)],
 'Return to the black points. Start with a pair and apply equal opposite forces, then sum each pair once for three bodies. Compare the two planar trios with one small initial difference; name the softened close-range rule. The small fixed-source orbital model and the doorstop experiment contrast source policy and receiver selection. The tutorial stays with the pairwise point model.',
 'A source can also be a receiver; selecting bodies is part of a force system.',
 'Change one initial velocity, preserve the others, and compare paths without claiming every difference proves chaos.'),
h('VFM_09_Legs','What holds the body up',(28,36),'Support, contact and centre of mass','force_trial_support',[
 p('force_trial_support',14,10,'tutorial',0,size=(10,11)),p('one_leg',5,27,config='driven_by_player:false#show_foot_markers:false#pace_reach:1.1#patrol_speed:0.25',size=(4,4)),p('four_leg_critter',14,27,config='driven_by_player:false#show_foot_markers:false#pace_reach:1.1#patrol_speed:0.25',size=(4,4)),p('six_leg_critter',23,27,config='driven_by_player:false#show_foot_markers:false#pace_reach:1.1#patrol_speed:0.25',size=(4,4))],
 'Bring back the cube because a support surface needs extent. Reconstruct the small loaded table from known rigid bodies, let it settle, then remove one foot. The one-, four- and six-legged walkers show other arrangements, but their commanded gait is not evidence of physical balance. Keep that distinction visible while the table answers through contact.',
 'A body depends on a configuration of other bodies.',
 'Move the load or choose a different foot. Predict a stable or unstable result, then keep the actual aftermath.'),
h('VFM_08_Arena','One push reaches another body',(26,28),'Impulse, recoil and collision','force_trial_bowling',[
 p('force_trial_bowling',8,10,'tutorial',0,size=(10,11)),p('sentry_turret',19,11,'comparison',180,'target:balls#detection_range:6',size=(4,4),y=0.82,pedestal=True),p('ball_dropper',19,16,'experiment',0,'total_balls:8#spawn_spread:0.4#drop_interval_min:2#drop_interval_max:3',size=(5,5),y=2.8),p('collision_carts',7,22,size=(5,5)),p('queer_cylinder_target',19,23,'experiment',180,size=(4,4),y=1.35,pedestal=True)],
 'Launch the point into the cube pins, then release the launch cart and compare recoil. Reconstruct one impulse exchange using the bodies already learned. The collision carts offer a controlled comparison; the sentry and target stay in their own bay. A target-selection rule is a separate programmed decision, not a property inferred from a force.',
 'An action can redistribute motion beyond its intended recipient.',
 'Predict the signs of the two velocities before release. Compare braced and free without calling both systems isolated.'),
h('Vectors_Act5_ForceAsPlace','Carry the point through',(16,50),'The visitor as another receiver','force_capability_lab',[
 p('force_capability_lab',8,37,'tutorial',0,size=(14,24)),p('vector_machine',4,6,'comparison',180,'lesson:force_as_place',size=(4,4)),p('force_field_zone',8,12,'comparison',0,'lesson:force_as_place',size=(12,8))],
 'Return to the held black point as a source of thrust. Aim the two spheres down or back and hold the triggers; release stops thrust while motion and gravity continue. The existing local-field crossing compares cube and visitor receiver contracts. In the final court the mortar, pad, moving platform, hinge, springs and loose cubes return as a space for combinations. The tutorial owns only the thrust-point-to-player connection. Wear the body visor to compare world velocity, thrust per unit mass and gravity. Turn your head without changing the world vector, then release the triggers: thrust stops before motion does. The visor reads this same connection; it adds no second movement model.',
 'Earlier operations become available capacities, and their combinations leave consequences.',
 'Change the two aim directions and predict their combined thrust. Deliver the unpowered point while accounting for what else moved.'),
]

def build():
    DEST.mkdir(parents=True,exist_ok=True)
    choices=read(OUT/'selection-source.json')['choices']
    catalog=read(ROOT/'doc/book/iterations/2026-10-07-forces-ten-more/catalog.json')
    by_title={a['title']:a for a in catalog}
    user_export=read(OUT/'user-choices.json') if (OUT/'user-choices.json').exists() else None
    keep=[a for a in catalog if user_export['choices'].get(a['token'],{}).get('decision')=='keep'] if user_export else [by_title[c['title']] for c in choices if c['decision']=='Keep']
    registry={}
    for mode in ['direction','addition','projection']:
        token='force_point_'+mode
        scene=DEST/(mode+'.tscn')
        scene.write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://commons/artifacts/force_halls/point_lesson.gd" id="1"]\n[node name="PointLesson" type="Node3D"]\nscript = ExtResource("1")\nprinciple = "'+mode+'"\n',encoding='utf8')
        registry[token]={'lookup_name':token,'name':'The point / '+mode,'scene':'res://'+scene.relative_to(ROOT).as_posix(),'map_ready':True,'include_in_map_data':True,'category':'vectors_forces','footprint':[8,4,9],'description':'The earlier grabbable PointBody reads '+mode+'. A geometric relation, not an integrated force.'}
    for i,row in enumerate(HALLS):
        row['number']=i+1
        path=ROOT/f"commons/maps/{row['map']}/map_data.json"
        backup=OUT/'before'/row['map']/'map_data.json'
        if not backup.exists():backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,backup)
        old=read(backup);w,d=row['size'];center=w//2
        if i==12:
            # Preserve the authored pit, bridge, fields and tested capability court.
            data=read(backup)
            data['map_info']['museum'].update(plinths=False,sculpture_clear_rects=[[0,0,w,d]])
            for z,line in enumerate(data['layers']['utilities']):
                for x,val in enumerate(line):
                    if str(val).startswith('t'):line[x]='t'
            row['walk']=[[7.5,3.5],[7.5,22.5],[7.5,24.5],[2.5,24.5],[2.5,46.5]]
        else:
            layers={name:[['']*w for _ in range(d)] for name in ['structure','utilities','interactables']}
            for z in range(d):
                for x in range(w):
                    boundary=x in [0,w-1] or z in [0,d-1]
                    passage=z in [0,d-1] and abs(x-center)<=2
                    layers['structure'][z][x]='w' if boundary and not passage else '1'
            layers['utilities'][3][center]='s'
            layers['utilities'][d-4][w-3]='t'
            for a in row['placements']:
                x,z=a['cell']
                layers['interactables'][z][x]=f"{a['token']}:{a['rotation']}:{a['y']}:1#pin:1#plinth:0"+('#'+a['config'] if a['config'] else '')
            data={'map_info':old['map_info'],'lighting':old.get('lighting',{}),'settings':old.get('settings',{}),'layers':layers}
            data['map_info']['dimensions']={'width':w,'depth':d,'max_height':5}
            data['map_info']['museum']={'artifact_placement':'map','wall_height':4,'gate_depth_rows':0,'gate':False,'plinths':False,'open_roof':True,'sculpture_clear_rects':[[0,0,w-1,d-1]]}
            row['walk']=[[center+0.5,3.5],[w-2.5,3.5],[w-2.5,d-4.5]]
            if i==0:row['walk']=[[8.5,3.5],[13.5,3.5],[13.5,18.5],[11.8,18.5],[11.8,20.5]]
        data['map_info']['title']=row['title'];data['map_info']['description']=row['lesson']
        data['map_info']['version']='forces-curated-2026-10-07'
        data['map_info'].setdefault('metadata',{}).update(tutorial_artifact=row['tutorial_artifact'],learning_objectives=[row['principle']],n_artifacts=sum(bool(v) for l in data['layers']['interactables'] for v in l))
        row['before_count']=sum(bool(v) for l in old['layers']['interactables'] for v in l)
        row['after_count']=data['map_info']['metadata']['n_artifacts']
        style='force_hall_'+str(i+1).zfill(2)
        data['layers']['interactables'][0][0]=style+'#pin:1#plinth:0'
        scene=DEST/(style+'.tscn')
        scene.write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://commons/artifacts/force_halls/hall_display.gd" id="1"]\n[node name="HallDisplay" type="Node3D"]\nscript = ExtResource("1")\nhall_number = '+str(i+1)+'\n',encoding='utf8')
        registry[style]={'lookup_name':style,'name':'Forces hall '+str(i+1)+' / wayfinding','scene':'res://'+scene.relative_to(ROOT).as_posix(),'category':'museum_architecture','map_ready':True,'include_in_map_data':True,'footprint':[1,1,1]}
        data['documentation']={'layout':'One primary encounter, spaced comparisons, a clear perimeter route. See the curation manifest for lesson roles.','curation':'res://commons/artifacts/force_halls/curation.json','tutorial_artifact':row['tutorial_artifact'],'supporting_artifacts':[a['token'] for a in row['placements'] if a['role']!='tutorial']}
        write(path,data)
        # Separate, explicit contract; do not pass a lesson plan off as tested full prose.
        lesson_path=path.parent/'FORCES_LESSON.md'
        lesson_path.write_text(f"# {row['title']}\n\nCuration and next tutorial contract — 7 October 2026. Full tutorial.md and final.md remain separate manuscripts; this contract controls their next revision.\n\nTutorial artifact: `{row['tutorial_artifact']}`.\n\nLearning elements: {row['principle']}.\n\n{row['lesson']}\n\nCarry onward: {row['carry']}\n\nIndependent check: {row['independent_check']}\n",encoding='utf8')
    used={a['token'] for row in HALLS for a in row['placements']}
    disposition=[]
    for a in keep:
        in_halls=[r['map'] for r in HALLS if any(p['token'] in [a['token']]+a.get('aliases',[]) for p in r['placements'])]
        disposition.append({'token':a['token'],'title':a['title'],'user_decision':'Keep','status':'needs construction' if a.get('stub') else 'main walk' if in_halls else 'collection alternative','halls':in_halls,'reason':'Empty scene record; not presented as a working experiment.' if a.get('stub') else 'A distinct contribution in this arrangement.' if in_halls else 'Retained for comparison and later swaps; not crowded into this pass.'})
    write(DEST/'curation.json',{'schema':1,'date':'2026-10-07','rule':'One tutorial artifact per principle. Other artifacts may compare or complicate it. A Keep is a collection choice, not an obligation to fill every hall.','halls':HALLS,'keep_disposition':disposition})
    write(ROOT/'commons/artifacts/registry/force_halls.json',{'artifacts':registry})
    write(OUT/'curation.json',read(DEST/'curation.json'))
    # The sequence remains thirteen halls in its existing order.
    seq_path=ROOT/'commons/maps/sequences/forces.json';seq=read(seq_path)
    seq['sequences']['forces']['curation_manifest']='res://commons/artifacts/force_halls/curation.json'
    seq['sequences']['forces']['tutorial_progression']=[{'map':r['map'],'artifact':r['tutorial_artifact'],'subject':r['principle'],'carry':r['carry']} for r in HALLS]
    seq['sequences']['forces']['content']=[r['map']+': '+r['principle'] for r in HALLS]
    seq['sequences']['forces']['demonstration']='Carry the known point through displacement, addition and projection. Give it a launch, a force pulse, a field and resistance. Compare restoration with prescribed phase, mutual attraction with a selected receiver, support with commanded gait, and collision with targeting. Finally let the held points propel the visitor through a court of earlier capacities.'
    write(seq_path,seq)
    print('Curated',len(HALLS),'halls;',len(keep),'Keep choices preserved;',len(used),'selected identities.')

if __name__=='__main__':build()

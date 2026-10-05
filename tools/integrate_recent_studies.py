"""Install reviewed application studies in existing halls, preserving their lessons.

The manifest records placement and learning dependencies separately. Re-running
does not append a second bay or duplicate the chapter passages.
"""
from pathlib import Path
import json, hashlib, re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-02-studies-in-the-spine'
OUT.mkdir(parents=True, exist_ok=True)
def read(p): return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def save(p,d):
    path=ROOT/p;path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def snapshot(p):
    src=ROOT/p;dst=OUT/'before'/p
    if src.exists() and not dst.exists():
        dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(src.read_bytes())

# id, adapter, hall, chapter, minimum bay width/depth, display origin x offset,
# title, artist reference, prerequisites, one student edit, source review.
SPECS = [
('hinge_release','hinge','Trans_Rotation','transformation',15,13,0,'A pose left','Lygia Clark',['loop','transform','trace'],'Change the return speed while keeping the reference pose.','2026-10-01-clark-a-pose-left'),
('reference_passage','passage','Trans_Scale','transformation',15,17,0,'Who fits through?','Mirosław Bałka',['coordinates','transform'],'Change opening width while keeping the body and opening height.','2026-10-01-five-reference-rooms'),
('open_structures','open','Tutorial_3D','array_tutorial',21,21,0,'A rule takes up space','Sol LeWitt',['line','coordinates','transform','array'],'Replace (column + row) % 5 with column; keep all 25 addresses.','2026-10-01-lewitt-reading-a-rule'),
('reference_suspension','suspension','Tutorial_3D','array_tutorial',21,21,0,'A place still held','Mona Hatoum',['array','coordinates'],'Change fragment roughness without changing any of the 75 positions.','2026-10-01-hatoum-grid-under-load'),
('reference_landscape','landscape','Color_Context_Placed','color',21,21,0,'A world from a cone','Alex McLeod',['array','transform','colour'],'Change the height factor; keep the 48 sites and three cones per tree.','2026-10-01-five-reference-rooms'),
('sphere_in_pink','pink','Color_Flashlight','color',17,19,0,'A sphere in pink','Sol LeWitt',['point','colour'],'Change one lamp state; compare pink light with a pink surface.','2026-10-01-sphere-in-pink'),
('colour_assembly','assembly','Color_Walls','color',25,23,0,'Room to gather','Liam Gillick',['coordinates','transform','array','colour'],'Shift the colour index by one without moving a panel.','2026-10-02-gillick-room-to-gather'),
('colour_wall_studies','wall','Color_Walls','color',25,17,0,'Wall relations','Liam Gillick',['line','coordinates','array','colour'],'Change the pitch of 24 rails without changing their count.','2026-10-02-gillick-wall-relations'),
('signal_room','signal','Random_Entropy','randomness',25,35,0,'Different neighbours','Ryoji Ikeda',['array','random'],'Shuffle the retained values; compare unchanged counts with changed neighbours.','2026-10-01-signal-room'),
('reference_pattern_garden','garden','Shader_05_Patterns','shaders',21,21,0,'The pattern crosses over','Claudia Hart',['array','shader'],'Change pattern phase while retaining every flower position.','2026-10-01-five-reference-rooms'),
('reference_plural_body','body','Shader_12_PinkExtravaganza','shaders',21,21,0,'A body in the plural','Peaches & Pussykrew',['transform','shader'],'Change the unfolding parameter; retain six limbs and three heads.','2026-10-01-five-reference-rooms'),
('conical_sightline','cut','Boolean_Works','boolean_surfaces',37,23,5,'One cut, three rooms','Gordon Matta-Clark',['coordinates','transform','boolean'],'Translate the shared cutter 0.75 metres; keep the three walls.','2026-10-01-matta-clark-one-cut'),
('kapoor_void_studies','void','Boolean_Works','boolean_surfaces',37,21,0,'The surface that says depth','Anish Kapoor',['boolean','shader'],'Change the cavity from unlit black to lit chalk; keep its geometry.','2026-10-01-kapoor-surface-and-depth'),
]

READINGS = {
'kapoor_void_studies': '''A dark circle opens in a raised plinth. Beside it, six smaller apertures repeat the hesitation. At the wall, an outward swelling shares its pale surface with a hollow. Approach from the clear floor and look across their edges.

Choose BLACK / CHALK. The cavity has not changed, but light now gives you more of its shape. In these responses to Kapoor, an opening and the evidence of an opening can be separated. The raised base keeps the deep bowl above the museum floor, and its whole footprint stays closed to your feet. Darkness is available to look into without turning uncertainty into a demand to step.''',
'hinge_release': '''A small plate waits on a hinge. Turn it; its neighbours travel with it. Release it under KEEP. The pose stays where you left it. Choose RETURN, turn again, then release. The joint moves towards the earlier angle, as if the object had a preferred answer.

The fixed support and stored angles make this an Ada response to Lygia Clark's articulated works. They give us a way to ask what an invitation permits. A joint can be available to your hand while the rule after release quietly takes the last word. Switch on TRACE and watch one corner: two journeys can arrive at the same pose without leaving the same line.''',
'reference_passage': '''Another wall waits beyond the enlarged room. Its opening changes width; your body stays the same. At the narrow setting the strip on the floor continues through a passage you cannot take. Walk around the wall instead.

The displaced dark disc belongs to this sparse arrangement too. Following the supplied Bałka reference, a few architectural parts make the missing room present. The code can name a clearance. It cannot decide whose body ought to be the measure. Widen the opening and return to the same strip.''',
'open_structures': '''The solid cube has lost its faces. Five open forms stand together, made from connections you can follow with your eye. Across the next arrangement, each place contains one of those forms. A row returns with its beginning moved along.

Change RULE. The places remain; the diagonal succession settles into repeated columns. These are our proposed rules after LeWitt's images. Reading a rule from an image means choosing among constructions that might have made it. The ease of producing another arrangement does not settle which one is worth keeping.''',
'reference_suspension': '''Beyond the open frames, rough fragments hang at three heights along a field of slender supports. Look down one row. Through the damaged-looking surfaces, the address remains exact.

Change the roughness. Seventy-five fragments keep their places. This response to Hatoum borrows the tension between an orderly support and something that seems to have survived damage. Our meshes have no weight and no history of demolition. Their easy restoration makes that absence conspicuous. What would the grid have to carry before its promise to hold something became a responsibility?''',
'reference_landscape': '''A cone returns as a tree. Three cones become its tiers; forty-eight places become a forest. The little pavilion shares their vocabulary. Change the height and the same sites seem to belong to another scale of world.

The supplied Alex McLeod image offered a way into this abundance. Here it takes surprisingly few kinds of part to make somewhere you want to look into. Gold, water and a pastel arch invite a belief that the geometry alone never required. Keep the sites and alter one proportion. Notice when a collection begins to feel like a place.''',
'sphere_in_pink': '''The sphere has returned, pale and still. Five switches offer five directions of pink light. Leave one on and move to the side. The shadow gives the curve an uneven weight.

Keep the lamps in place and change LIGHT / MATERIAL. The pink now belongs to the sphere; the illumination is white. The floor helps you see what the sphere cannot tell you by itself. This is our five-switch response to LeWitt's light study. Thirty-two possible switch states include all five lamps off. An inventory can be complete while the experience of looking keeps changing.''',
'colour_assembly': '''Twelve numbered panels hang above an open floor. Their colours repeat. From the controls, choose SCREENS: the same panels stand upright and divide the space ahead. Choose GATHER. Some return overhead while others hold an edge around an open centre.

Walk into it. Naming a space for gathering does not say who may gather there, or who is allowed to move its walls. Gillick's secondary structures make that uncertainty productive for this study. Here the arrangement can be changed from the console, while the colour can be changed independently. Find a panel by its number. Where did its neighbour go?''',
'colour_wall_studies': '''On the wall, twenty-four coloured rails stand at equal intervals. Widen the spacing. The same material now occupies more wall; the gaps have become a larger part of what you see.

Beside them, pull the vertical members of a crossing forward. Its drawing acquires depth and a second, shadowed grid. Further along, one rail can be omitted from an open composition and restored. These responses to Gillick keep a small vocabulary available for rearrangement. The clarity of the parts can suggest a comprehensible system. It does not disclose who made it, who maintains it, or who gets to change the plan.''',
'signal_room': '''The count returns as a room. Black and white continue from the floor onto the far wall and overhead. Choose ROWS, then CELLS. The broad bands loosen into another distribution. Both counts stay at 2,048.

The small four-by-four witness lets you inspect the same record at another scale. The entropy reading stays at one bit per symbol while the number of unlike neighbours changes. In this response to Ikeda, the immensity is made from a finite stored array. Its authority can be felt before its omissions are understood. You can leave along either side of the display; the dark pixels never remove the floor.''',
'reference_pattern_garden': '''The pattern leaves the flat sample and crosses a flower. Turn its phase: a band moves over the petal while the petal stays still. Further back it crosses the room itself.

Claudia Hart's supplied image makes ornament difficult to dismiss as a finishing layer. In this response, the shared pattern can compete with the outline that would ordinarily tell us where one thing ends. Keep watching one edge through the change. Does the surface make the object more available, or make its boundary harder to trust?''',
'reference_plural_body': '''Six limbs unfold around three heads. The pose opens without becoming another inventory. A pink edge catches the light; a silver loop holds a space beside the body.

The Peaches and Pussykrew reference brings bodily excess into this return to familiar primitives and shaders. Our assembly makes an attachment changeable. That is a technical permission, with limits: a larger menu of parts cannot by itself promise a freer life. Let the pose remain unresolved. The body does not owe the room a single final outline.''',
'conical_sightline': '''Three walls stand apart. Through them, one widening cut makes a view reach from room to room. Walk through the ordinary doors beside it; looking through and passing through remain different permissions.

The removed volumes stand nearby. Move the cutter and compare what stays with what is kept as an offcut. This response to Matta-Clark's Conical Intersect makes the subtraction reversible. The buildings, demolition and people of the historical work cannot be restored by our RESET button. The clean operation gives us a relation to inspect; it also shows what the model has left outside.''',
}

from relations_studies import SPECS as NEW_SPECS, READINGS as NEW_READINGS
SPECS += NEW_SPECS
READINGS.update(NEW_READINGS)
from tension_study import SPECS as TENSION_SPECS, READINGS as TENSION_READINGS
SPECS += TENSION_SPECS
READINGS.update(TENSION_READINGS)
from paired_time_study import SPECS as TIME_SPECS, READINGS as TIME_READINGS
SPECS += TIME_SPECS
READINGS.update(TIME_READINGS)
from tube_painting_study import SPECS as TUBE_SPECS, READINGS as TUBE_READINGS
SPECS += TUBE_SPECS
READINGS.update(TUBE_READINGS)

manifest=[]
registrypath='commons/artifacts/registry/reference_studies.json';snapshot(registrypath);registry=read(registrypath)
for key,mode,hall,seq,min_width,depth,xoffset,title,artist,requires,exercise,review in SPECS:
    rel=f'commons/maps/{hall}/map_data.json';snapshot(rel);data=read(rel)
    mus=data['map_info'].setdefault('museum',{})
    placements=mus.setdefault('reference_studies',{})
    if key not in placements:
        layers=data['layers'];old_width=len(layers['structure'][0]);old_depth=len(layers['structure'])
        width=max(old_width,min_width);middle=width//2
        for name,layer in layers.items():
            for row in layer: row.extend(['' for _ in range(width-len(row))])
        # The original end wall becomes the entrance to an adjoining application bay.
        # Its existing aperture is retained; the bay has a three-metre exit and side bypasses.
        height=max(8,int(mus.get('wall_height',5)))
        for name,layer in layers.items():
            for z in range(depth):
                row=['']*width
                if name=='structure':
                    row=[str(height)]+['1']*(width-2)+[str(height)]
                    if z==depth-1:
                        row=[str(height)]*width;row[middle-1:middle+2]=['1']*3
                layer.append(row)
        # Close the short shoulder if this bay is wider than its predecessor.
        for x in range(old_width,width): layers['structure'][old_depth-1][x]=str(height)
        exit_token='t'
        for row in layers['utilities'][:old_depth]:
            for x,c in enumerate(row):
                if str(c)=='t' or str(c).startswith('t:'): exit_token=c;row[x]=''
        layers['utilities'][-2][middle]=exit_token
        at=[middle+xoffset,old_depth+depth//2]
        layers['interactables'][at[1]][at[0]]=key+':180:0#plinth:0#pin:1'
        placements[key]={'cell':at,'rotation':180,'bay':[0,old_depth,width-1,old_depth+depth-1]}
        mus.setdefault('sculpture_clear_rects',[]).append([1,old_depth,width-2,old_depth+depth-2])
        mus.update({'artifact_placement':'map','plinths':False,'open_roof':True})
        data['map_info']['dimensions'].update({'width':width,'depth':len(layers['structure']),'max_height':max(height,data['map_info']['dimensions'].get('max_height',0))})
        save(rel,data)
    source_scene=f'res://commons/artifacts/spine_studies/{mode}.tscn'
    if key=='signal_room':
        rp='commons/artifacts/registry/signal_room.json';snapshot(rp);reg=read(rp);item=reg['artifacts'][key]
    else:
        item=registry['artifacts'].setdefault(key,{})
    item.update({'lookup_name':key,'name':title,'scene':source_scene,'category':'reference_studies','sequence':seq,'map_ready':True,'include_in_map_data':True,
        'description':f'{title}: an original response after {artist}. Installed application bay in {hall}; controls belong to the main museum pointer.',
        'reference_artist':artist,'installed_maps':[hall],'status':'Installed in the authored museum route; native integration verification recorded with the spine review.',
        'parameters':{'study':'Adapter selected by the installed scene; use its labelled pointer controls.'},'signals':[],
        'interactions':['Use the labelled 3D controls; geometry changes require the display area to be clear.','RESET restores this study, without resetting the hall.'],
        'study_adapter':mode})
    if mode in ['network','sentence','witness']:
        item['interactions'] = ['Use the labelled museum pointer controls to change records, sentences or image state.','RESET restores this study without resetting the hall.']
    if mode == 'witness':
        item['interactions'] += ['Grab pink cameras A and B beside the readouts; aim them and release to leave them in place. C stays fixed.','RETURN CAMERAS restores starting poses; release held cameras first. Delayed and held exposures retain their recorded viewpoints.']
    if mode == 'tension':
        item['interactions'] = ['Grab and pull the pink handle; release to let the membrane respond.', 'HOLD A PULL and RELEASE provide a repeatable comparison. LOAD cycles 0/1/3 kg; MORE / LESS GIVE changes compliance.', 'RESET restores the settled unloaded surface; release a held handle first.']
        item['qfep_connection'] = 'Compare imposed load, fixed attachments and material response separately; the rule for returning encodes a remembered rest shape.'
    if mode == 'paired_time':
        item['interactions'] = ['DRIFT RIGHT changes the right rate without moving either hand immediately.', 'SAME RATE retains the gap; OFFSET adds 45 degrees; ALIGN retains the rates.', 'HOLD / RUN pauses this pair only. READING reveals the rates and gap. RESET restores local starting state.']
        item['qfep_connection'] = 'Equal rates preserve a difference inherited from prior updates. Agreement is an imposed relation; both apparent clocks share one engine delta.'
    if key=='signal_room': save(rp,reg)
    record=dict(id=key,adapter=mode,map=hall,sequence=seq,title=title,reference=artist,requires=requires,kind='application',new_capability=False,
        student_edit=exercise,borrow='Display fabrication, lighting, colliders, main player and pointer controls.',
        scene=source_scene,review=f'doc/book/iterations/{review}/index.html',placement=placements[key],capture=f'figures/{key}.png')
    if mode == 'tube':
        record.update(new_capability=True, introduces=['sweep'])
        item['description'] = 'Ada pipe, cable and tube workbench: continue suspended paths or twenty-one supplied forms, branch from a run, join at named ports, or attach to the wall.'
        item['interactions'] = ['Grab a free end and extend; release at the amber marker to join another run, or at the wall to attach.', 'Hold the pen trigger to draw; start beside an existing run to branch. VIEW cycles path, rings and skin for drawn runs.', 'FORM chooses tube, hollow pipe or drafted cable for the last run and next stroke. SAG changes the last cable; NETWORK loads the combined example.', 'PARTS cycles sixteen pipe/glass forms in four groups. CABLES shows five cable arrangements. Grab any free part port to draw a new run; the supplied part stays fixed.', 'UNDO restores pieces, geometry and sockets together. Release held ends before editing. Eight pieces and runs share the workbench.']
    manifest.append(record)
    seqpath=f'commons/maps/sequences/{seq}.json';snapshot(seqpath);sequence=read(seqpath)
    groups=sequence['sequences'][seq].setdefault('artifact_groups',[])
    group=next((g for g in groups if g['map']==hall),None)
    if group is None: group={'map':hall,'position':'application','artifacts':[]};groups.append(group)
    if key not in group['artifacts']: group['artifacts'].append(key)
    group.setdefault('application_studies',{})[key]=exercise
    save(seqpath,sequence)
    # Reading remains prose. Its code/implementation task lives in the companion tutorial.
    passage='<!-- @'+key+' -->\n\n'+READINGS[key]+'\n\n'
    for filename in ['final.md','tutorial.md','intent.md','technical.md','summary.md','critical.md','artifacts.md']:
        path=f'commons/maps/{hall}/{filename}';snapshot(path);p=ROOT/path
        text=p.read_text(encoding='utf-8-sig') if p.exists() else '# '+title+'\n'
        marker='<!-- study-spine:'+key+' -->'
        if marker in text: continue
        if filename=='final.md':
            insertion=marker+'\n\n'+passage
            where=text.rfind('<!-- @ -->')
            if where<0: where=len(text)
            text=text[:where].rstrip()+'\n\n'+insertion+text[where:]
        elif filename=='tutorial.md':
            text+='\n\n'+marker+'\n\n## Return: '+title+'\n\n'+exercise+' Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.\n\n'
            text+='This application reuses '+', '.join(requires)+'. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`'+mode+'`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.\n\n'
            text+=f'[Earlier study and making notes](/book-review/doc/book/iterations/{review}/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.\n'
        else:
            text+='\n\n'+marker+'\n\n## Installed application: '+title+'\n\n'
            if filename=='critical.md': text+=READINGS[key].split('\n\n')[-1]+'\n'
            else: text+=f'`{key}` occupies a new adjoining bay, after the existing encounters. Cell {placements[key]["cell"]}, rotation 180°, museum adapter `{source_scene}`. Original response to {artist}; no claim of exact reconstruction.\n\n{exercise} Reuses {", ".join(requires)}; adds no prerequisite node. The display and main-player controls are supplied.\n'
        if mode == 'tube':
            text=text.replace('adds no prerequisite node.', 'introduces the sweep capability after those earlier tools.').replace('Original response to Ada / drawing in space; no claim of exact reconstruction.', 'Original Ada geometry lesson, continuing an already started drawing.').replace('Geometry controls wait until the exhibit is clear.', 'Finish the current gesture before editing the work.')
        p.write_text(text.rstrip()+'\n',encoding='utf-8')
save(registrypath,registry)
save('doc/book/recent-studies.json',{'date':'2026-10-02','scope':'Recent artist studies integrated into existing book/museum halls; sequence order preserved.','studies':manifest,
 'already_installed':[{'id':'boolean_eggs','map':'Boolean_Works'},{'id':'colour_light_rooms','map':'Color_Flashlight'}],
 'retained_companions':[]})
print(f'Integrated {len(manifest)} studies in {len(set(s["map"] for s in manifest))} existing halls.')

"""Insert four existing-example Logic floors without rebuilding any existing room."""
import copy
import hashlib
import json
import os
from pathlib import Path
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT.parent/'ada_encyclopedia'
OUT = ROOT/'ada_run/logic-sequence-2026-10-26'
VOID = ROOT/'commons/void'
URL = 'http://localhost:3003/api/void-layout'
MAPS = ['Logic_Event','Logic_AND','Logic_Alternatives','Logic_Assemblage']
TITLES = ['Logic / event and consequence','Logic / both supports',
          'Logic / either path and interruption','Logic / assemble and keep']
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def encode(d):return json.dumps(d,ensure_ascii=False,indent=2)+'\n'
def write(p,d):
    p.parent.mkdir(parents=True,exist_ok=True)
    temp=p.with_name(p.name+'.logic-next');temp.write_text(encode(d),encoding='utf-8');os.replace(temp,p)
def moved(i):return i+4 if i>=20 else i
def item(id,token,x,z,config=None,facing=0):
    return dict(id=id,artifact=token,station='SW' if x<0 else 'SE',position=[x,z],height=0,
                scale=1,facing=facing,config=config or {})
def room(i,artifacts,props=None):
    return dict(map=MAPS[i],title=TITLES[i],origin=False,walls=[],artifacts=artifacts,
                props=props or [],impact_cells=[],route=[],supply_leads=False)

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    assert not (OUT/'migration-checks.json').exists(),'Already inserted; preserve subsequent edits'
    payload=json.load(urllib.request.urlopen(URL,timeout=90))
    before=payload['rooms'];assert len(before['floors'])==205
    assert before['floors'][19]['map']=='Trans_Pit' and before['floors'][20]['map']=='Array'
    paths=[VOID/n for n in ['rooms.json','layout.json','spine.json','primitive-prefabs.json',
        'capacity-artifacts.json','capacity-spine.json']]
    paths += [ROOT/'commons/maps/curriculum_spine.json',ROOT/'commons/maps/sequences/transformation.json',
        ROOT/'commons/maps/sequences/array_tutorial.json',WEB/'public/void-models/manifest.json']
    snapshots={str(p):p.read_bytes() for p in paths}
    for i,p in enumerate(paths):(OUT/f'before-{i}-{p.name}').write_bytes(snapshots[str(p)])
    write(OUT/'backup-index.json',[str(p) for p in paths])
    write(OUT/'rooms.before.json',before)

    rooms=copy.deepcopy(before)
    new=[
        room(0,[item('logic-event','reference_tyre_chain',-16,0,facing=90)]),
        room(1,[item('logic-and','matter_spring_and',-16,0,{'editor_label':'AND / both gaps need support'})]),
        room(2,[item('logic-or','matter_spring_or',-16,0,{'editor_label':'OR / either supported path'}),
                item('logic-not','matter_spring_not',16,0,{'editor_label':'NOT / interruption'})]),
        room(3,[item('logic-workshop','pallet_assemblage',-16,-3,{'term':'pallet_hand_kit','workshop':True,'insertion_map':'Logic_Assemblage'}),
                item('logic-pallet-and','pallet_assemblage',-16,3.5,{'term':'pallet_hand_kit','workshop':True,
                    'study':'pallet_and','track_height':.6,'board_count':2,'logic_grammar':'supports','insertion_map':'Logic_Assemblage'})])]
    rooms['floors'][20:20]=new
    # Editor aliases point into the main tower; trial-local provenance stays local.
    for f in rooms['floors']:
        for a in f.get('artifacts',[])+f.get('copies',[]):
            source=a.get('config',{}).get('editor_source')
            if source and isinstance(source.get('floor'),int):source['floor']=moved(source['floor'])

    frame=read(VOID/'layout.json')
    frame['levels']=[-i*frame['storey_height'] for i in range(209)]
    frame['floor_roles'][20:20]=TITLES
    for key in ['floor_styles','spawn_points','floor_sign_positions','floor_sources']:
        frame[key]={str(moved(int(k))):v for k,v in frame.get(key,{}).items()}
    for i in range(20,24):
        frame['spawn_points'][str(i)]=[-13.8 if i==20 else -16,.06,5.8 if i==20 else 7 if i==23 else 3.2]
        frame['floor_sign_positions'][str(i)]=[-14,7.9]
        frame['descent']['pad_shafts'][str(i)]='A'
    for key in ['pad_shafts','pad_x_sides']:
        # Shift only original records: the four fresh pad entries above are added below.
        original=read(VOID/'layout.json')['descent'].get(key,{})
        frame['descent'][key]={str(moved(int(k))):v for k,v in original.items()}
    for i in range(20,24):frame['descent']['pad_shafts'][str(i)]='A'
    frame['descent']['pad_disabled_floors']=[moved(i) for i in frame['descent'].get('pad_disabled_floors',[])]
    for group in frame['spine']:group['floors']=[moved(i) for i in group['floors']]
    group=dict(id='logic',title='Logic: Conditions Become Events',floors=list(range(20,24)))
    frame['spine'].insert(2,group)
    frame['status']='209 saved floors: Logic inserted after Transformation; existing local arrangements preserved.'
    spine=read(VOID/'spine.json')
    for f in spine['floors']:
        f['floor']=moved(f['floor'])
        if not f.get('source',{}).get('trial') and 'floor' in f.get('source',{}):f['source']['floor']=moved(f['source']['floor'])
    spine['floors'][20:20]=[dict(floor=20+i,map=m,sequence='logic',title=TITLES[i],
        source=dict(trial='',floor=20+i)) for i,m in enumerate(MAPS)]
    spine['sequences']=copy.deepcopy(frame['spine'])

    curriculum=read(ROOT/'commons/maps/curriculum_spine.json')
    curriculum['spine']['sequences'].insert(2,dict(name='logic',phase='F_order',order=2.5,
        lab_post=None,qfep_role='Make conditions, alternative routes and physical consequences explicit; assemble with familiar parts.'))
    curriculum['_meta']['last_updated']='2026-10-26'
    curriculum['_meta']['note']+=' Logic inserted after Transformation, using existing physical examples; earlier sketches retained.'
    logic=dict(name='Logic: Conditions Become Events',truth='A condition is encountered through what a construction lets happen.',
        description='Four short rooms reuse the event chain, supported gravity gates and hand-built pallet workshop.',
        qfep_term='F',qfep_connection='Separate intended truth tables from observed material outcomes.',
        layer='F_order',prerequisites=['transformation'],unlocks=['array_tutorial'],maps=MAPS,
        difficulty='beginner',estimated_time='12-20 minutes',return_to='lab',
        learning_objectives=['Trace an event through physical contacts','Compare serial supports and alternative paths',
            'Read interruption without mistaking every accident for a Boolean rule','Arrange parts by hand and save a reusable loose collection'])
    trans=read(ROOT/'commons/maps/sequences/transformation.json')
    unlock=trans['sequences']['transformation'].setdefault('unlocks',[])
    unlock[:]=['logic' if x=='array_tutorial' else x for x in unlock]
    if 'logic' not in unlock:unlock.append('logic')
    arrays=read(ROOT/'commons/maps/sequences/array_tutorial.json')
    arrays['sequences']['array_tutorial']['prerequisites']=['logic' if x=='transformation' else x
        for x in arrays['sequences']['array_tutorial'].get('prerequisites',[])]

    prefabs=read(VOID/'primitive-prefabs.json');graph=read(VOID/'capacity-artifacts.json')
    for p in prefabs['prefabs']:
        if 'placement' in p:p['placement']['source_floor']=moved(p['placement']['source_floor'])
        if p['id'].startswith('matter_spring_'):
            op=p['id'].removeprefix('matter_spring_');index=21 if op=='and' else 22
            p.update(map=MAPS[index-20],title='Logic / '+op.upper()+' / gravity')
            p['placement'].update(source_floor=index,source_id='logic-'+op)
            p['completion']['map']=p['map'] # Keep existing objective IDs and earned inventory.
            n=next(n for n in graph['nodes'] if n['id']==p['id'])
            n.update(title=p['title'],sequence='logic',scene=p['scene'],proposed=False,
                insertion=dict(map=p['map'],basis='authored',reason='Formal comparison after Transformation; the earlier floor-14 sketch remains in place.'))
    scene='res://commons/artifacts/matter_reference/tyre_chain.tscn'
    prefabs['prefabs'].append(dict(id='logic_event_chain',title='Logic / event chain',map=MAPS[0],
        family='Logic / event',dimensions=[10.5,2.5,3],anchor='Original local mechanism frame; actual scale one.',
        behaviour='Release the existing tyre; contacts carry motion through plank, wedge and boxes.',
        learn='A contact can trigger another event without imposing a truth table.',scene=scene,
        recipe=['profile_rollingtyre_o','timber_plank_1m','wp','construction_cube'],
        placement=dict(artifact='reference_tyre_chain',source_floor=20,source_id='logic-event',height=0,scale=1)))
    scene='res://commons/artifacts/pallet_assemblage/pallet_assemblage.tscn'
    prefabs['prefabs'].append(dict(id='logic_assemblage_workshop',title='Logic / hand-built assemblage',map=MAPS[3],
        family='Logic / assemblage',dimensions=[3.5,2.5,3],anchor='Collection origin; independently editable timber pieces.',
        behaviour='Take apart, arrange, test gravity and save through the existing shared handmade-prefab system. Saving creates no joints.',
        learn='A person can supply the relation before it becomes a reusable construction.',scene=scene,
        recipe=['pallet_hand_kit'],placement=dict(artifact='pallet_assemblage',source_floor=23,
            source_id='logic-workshop',height=0,scale=1,config=dict(term='pallet_hand_kit',workshop=True,insertion_map='Logic_Assemblage'))))
    for id,index,scene in [('logic_event_chain',0,'res://commons/artifacts/matter_reference/tyre_chain.tscn'),
        ('logic_assemblage_workshop',3,'res://commons/artifacts/pallet_assemblage/pallet_assemblage.tscn')]:
        p=next(p for p in prefabs['prefabs'] if p['id']==id)
        graph['nodes'].append(dict(id=id,title=p['title'],sequence='logic',learn=p['learn'],use=p['behaviour'],
            icon='assembly',scene=scene,proposed=False,insertion=dict(map=MAPS[index],basis='authored',
                reason='Existing implementation reused in the short Logic progression.')))
    edges=[('tyre_plank_wedge','logic_event_chain','develop','Read the existing physical chain as a sequence of contacts.'),
        ('logic_event_chain','matter_spring_and','develop','Ask which conditions must be present for the event to continue.'),
        ('matter_spring_and','matter_spring_or','associate','Compare both supports in series with either supported route.'),
        ('matter_spring_or','matter_spring_not','associate','Compare a possible route with physical interruption.'),
        ('pallet_hand_kit','logic_assemblage_workshop','combine','Reuse the same twenty loose timber pieces.'),
        ('matter_spring_and','logic_assemblage_workshop','develop','Use a known relation as a starting strategy for hand assembly.'),
        ('matter_spring_or','logic_assemblage_workshop','develop','Try an alternative path with familiar parts.'),
        ('matter_spring_not','logic_assemblage_workshop','develop','Test what a placed or removed piece prevents.')]
    for a,b,k,label in edges:
        if not any(e['source']==a and e['target']==b and e['kind']==k for e in graph['edges']):
            graph['edges'].append(dict(source=a,target=b,kind=k,label=label))
    graph['updated']=prefabs['updated']='2026-10-26'
    capacity=read(VOID/'capacity-spine.json')
    capacity['sequences'].insert(2,dict(id='logic',label='Logic',cue='Contact · condition · consequence',
        parent='transformation',relation='Read conditions in the movement of familiar bodies.',x=600,y=0,
        build='Reuse a physical gate, then arrange and keep a hand-built construction.',
        association=dict(title='A material rule',description='Use supported paths and blockers without confusing expected logic with observed motion.',state='implemented')))

    models=read(WEB/'public/void-models/manifest.json')
    models['floors']={str(moved(int(k))):v for k,v in models['floors'].items()}
    for i,m in enumerate(MAPS):models['floors'][str(20+i)]=dict(map=m,artifacts={},structure=copy.deepcopy(models['floors']['19']['structure']))
    # Existing GLBs are local to their artifact/floor; preserve URLs and exact bytes.
    models['revision']=hashlib.sha256(encode(models).encode()).hexdigest()[:12]
    outputs={VOID/'layout.json':frame,VOID/'spine.json':spine,VOID/'primitive-prefabs.json':prefabs,
        VOID/'capacity-artifacts.json':graph,VOID/'capacity-spine.json':capacity,
        ROOT/'commons/maps/curriculum_spine.json':curriculum,
        ROOT/'commons/maps/sequences/transformation.json':trans,
        ROOT/'commons/maps/sequences/array_tutorial.json':arrays,
        ROOT/'commons/maps/sequences/logic.json':dict(sequences=dict(logic=logic)),
        WEB/'public/void-models/manifest.json':models}
    # Minimal map data registers the existing instruments; chapter prose is deferred.
    for i,m in enumerate(MAPS):
        structure=[['1']*9 for _ in range(9)];utilities=[[' ']*9 for _ in range(9)];utilities[0][4]='s';utilities[8][4]='t:'+(MAPS[i+1] if i<3 else 'Lab')
        instruments=[[' ']*9 for _ in range(9)]
        for n,a in enumerate(new[i]['artifacts']):instruments[3+n*2][4]=a['artifact']
        outputs[ROOT/f'commons/maps/{m}/map_data.json']=dict(map_info=dict(name=TITLES[i],lookup_name=m,
            description=logic['learning_objectives'][i],dimensions=dict(width=9,depth=9,max_height=3),
            metadata=dict(category='logic',difficulty='beginner',existing_examples=True)),
            layers=dict(structure=structure,utilities=utilities,interactables=instruments),
            documentation=dict(summary=logic['learning_objectives'][i],source='Existing native artifacts; no new solver.',chapter_text='deferred'))
    for p in paths:assert p.read_bytes()==snapshots[str(p)],str(p)+' changed during preparation'
    for p,d in outputs.items():write(p,d)
    request=urllib.request.Request(URL,json.dumps(dict(rooms=rooms,revision=payload['revision'])).encode(),
        {'Content-Type':'application/json'},method='POST')
    try:save=json.load(urllib.request.urlopen(request,timeout=120))
    except Exception:
        for p in paths:
            if p!=VOID/'rooms.json':p.write_bytes(snapshots[str(p)])
        raise
    assert save['saved']
    saved=read(VOID/'rooms.json');assert saved==rooms
    for old,f in enumerate(before['floors']):
        expected=copy.deepcopy(f)
        for a in expected.get('artifacts',[])+expected.get('copies',[]):
            ref=a.get('config',{}).get('editor_source')
            if ref and isinstance(ref.get('floor'),int):ref['floor']=moved(ref['floor'])
        assert saved['floors'][moved(old)]==expected,old
    assert read(Path.home()/'Desktop/Ada Void/rooms.json')==saved
    report=dict(passed=True,previous_floors=205,current_floors=209,logic_floors=list(range(20,24)),
        preserved_early_floors=20,existing_arrangements_preserved=205,
        shifted_floor_aliases=True,old_to_new={str(i):moved(i) for i in range(205)},save=save)
    write(OUT/'migration-checks.json',report)
    print(json.dumps({k:v for k,v in report.items() if k not in ['save','old_to_new']}))

if __name__=='__main__':main()

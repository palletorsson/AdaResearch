"""Approved compact vector hall. Only this map's geometry is rebuilt.

Preserve the other Forces halls, collection choices and archived vector maps.
"""
from pathlib import Path
import copy, json, shutil

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-07-vectors-one-room'
FIRST='Vectors_Act1_WhatAVectorIs'
RETIRED=['VFM_02_Operations','Vectors_Act2_VectorArithmetic']
COMBINED_HALL={
    'map':FIRST,'title':'Vectors in your hands','size':[16,20],
    'principle':'Displacement, magnitude and unit direction; addition; signed projection and remainder',
    'tutorial_artifact':'force_point_direction',
    'tutorial_artifacts':['force_point_direction','force_point_addition','force_point_projection'],
    'placements':[dict(token='force_point_'+mode,cell=cell,role='tutorial',rotation=0,config='',zone=[5,5],y=0,pedestal=False)
                  for mode,cell in [('direction',[4,7]),('addition',[11,7]),('projection',[8,14])]],
    'lesson':'Carry the known grabbable PointBody through three stations in one room. First move one point relative to its local origin: read displacement, length and a separate unit direction. Next move two points and follow a then b to the rose sum; compare the route length with the direct arrival. Finally project onto the signed X rail and retain the perpendicular remainder. Live labels follow the inputs. Thin cylinders give direction a visible body. These are geometric operations; a moving point does not yet imply a force simulation.',
    'carry':'One point class; a declared local frame; direction, sum and selected component ready for launch and force.',
    'independent_check':'Choose an unlisted displacement, then zero. Predict length and direction. Swap two displacements and cancel them. Move perpendicular to the X rail, then behind its origin: recover a from projection + remainder.',
    'number':1,'walk':[[8.5,3.5],[13.5,3.5],[13.5,16.5]],'before_count':9,'after_count':3
}

def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def write(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
def backup(path):
    dest=OUT/'before'/path.relative_to(ROOT)
    if not dest.exists():dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)

def build():
    cp=ROOT/'commons/artifacts/force_halls/curation.json'; backup(cp); plan=read(cp)
    old=plan['halls']; archived=plan.get('archived_halls',[])
    archived += [r for r in old if r['map'] in RETIRED and r['map'] not in [a['map'] for a in archived]]
    plan['archived_halls']=archived
    plan['halls']=[copy.deepcopy(COMBINED_HALL)]+[r for r in old if r['map'] not in [FIRST]+RETIRED]
    for i,row in enumerate(plan['halls']):row['number']=i+1
    plan['keep_disposition']=read(OUT/'before/commons/artifacts/force_halls/curation.json')['keep_disposition']
    for item in plan['keep_disposition']:
        item['halls']=[m for m in item['halls'] if m not in [FIRST]+RETIRED]
        if item['token'] in COMBINED_HALL['tutorial_artifacts']:item['halls'].insert(0,FIRST)
        if item['status']!='needs construction':
            item['status']='main walk' if item['halls'] else 'collection alternative'
    plan['vector_compaction']='Three vector readings in one hall. Older comparison machines stay in the collection, outside this route.'
    write(cp,plan)
    mp=ROOT/f'commons/maps/{FIRST}/map_data.json';backup(mp);data=read(mp)
    w,d=COMBINED_HALL['size'];center=w//2
    layers={name:[['']*w for _ in range(d)] for name in ['structure','utilities','interactables']}
    for z in range(d):
        for x in range(w):
            boundary=x in (0,w-1) or z in (0,d-1)
            passage=z in (0,d-1) and abs(x-center)<=2
            layers['structure'][z][x]='w' if boundary and not passage else '1'
    layers['utilities'][3][center]='s';layers['utilities'][d-4][w-3]='t'
    for a in COMBINED_HALL['placements']:
        x,z=a['cell'];layers['interactables'][z][x]=a['token']+':0:0:1#pin:1#plinth:0'
    layers['interactables'][0][0]='force_hall_01#pin:1#plinth:0'
    data['layers']=layers
    data['map_info'].update(title=COMBINED_HALL['title'],description=COMBINED_HALL['lesson'],version='vectors-one-room-2026-10-07')
    data['map_info']['dimensions']={'width':w,'depth':d,'max_height':5}
    data['map_info']['museum']['sculpture_clear_rects']=[[0,0,w-1,d-1]]
    data['map_info']['metadata'].update(tutorial_artifact=COMBINED_HALL['tutorial_artifact'],tutorial_artifacts=COMBINED_HALL['tutorial_artifacts'],n_artifacts=3,learning_objectives=['Displacement and magnitude','Unit direction; zero case','Vector addition; head to tail','Signed projection and remainder'])
    data['documentation'].update(layout='Three hand-controlled vector stations, one room, a clear perimeter walk.',tutorial_artifacts=COMBINED_HALL['tutorial_artifacts'],supporting_artifacts=[])
    write(mp,data)
    # Stable map identity protects dressing and arena geometry from ordinal shifts.
    original=read(OUT/'before/commons/artifacts/force_halls/curation.json')['halls']
    for row in original:
        sp=ROOT/f"commons/artifacts/force_halls/force_hall_{row['number']:02d}.tscn";backup(sp)
        text=sp.read_text(encoding='utf8')
        if 'map_id = ' not in text:text+='map_id = '+json.dumps(row['map'])+'\n'
        sp.write_text(text,encoding='utf8')
    seqpath=ROOT/'commons/maps/sequences/forces.json';backup(seqpath);seq=read(seqpath)
    route=seq['sequences']['forces'];route['maps']=[r['map'] for r in plan['halls']]
    route['description']='Eleven halls: one hand-controlled vector room, then launch, force, fields, resistance, restoration, accumulation, attraction, support, collision and the visitor as receiver.'
    route['tutorial_progression']=[dict(map=r['map'],artifact=r['tutorial_artifact'],artifacts=r.get('tutorial_artifacts',[r['tutorial_artifact']]),subject=r['principle'],carry=r['carry']) for r in plan['halls']]
    route['content']=[r['map']+': '+r['principle'] for r in plan['halls']]
    write(seqpath,seq)
    authored=ROOT/'commons/data/map_authored.json';backup(authored);a=read(authored);a['forces']=route['maps'];write(authored,a)
    # The live museum follows this derived plan, not the sequence list alone.
    from em_map_halls import derive_row
    live=ROOT/'ada_run/em_plan.json';backup(live);museum=read(live)
    existing={r['map']:r for r in museum['plans'] if r.get('sequence')=='forces' and 'map' in r}
    first_index=next(i for i,r in enumerate(museum['plans']) if r.get('sequence')=='forces')
    kept=[r for r in museum['plans'] if r.get('sequence')!='forces']
    force_rows=[]
    for i,map_name in enumerate(route['maps']):
        row=existing[map_name]
        if map_name==FIRST:row=derive_row(row['pearl'],map_name,row['museum'],i,len(route['maps']),'forces')
        row['pearl_index']=i;row['pearls_total']=len(route['maps']);force_rows.append(row)
    museum['plans']=kept[:first_index]+force_rows+kept[first_index:]
    for chapter in museum.get('_map_halls',{}).get('chapters',[]):
        if chapter.get('chapter')=='forces':chapter.update(halls=len(force_rows),maps=route['maps'],replaced=len(force_rows))
    museum['_vector_compaction']='2026-10-07: three vector stations in one hall; remaining Forces rows preserved.'
    write(live,museum)
    shipped=ROOT/'commons/data/museum/em_plan.json'
    if shipped.exists():backup(shipped);shutil.copy2(live,shipped)
    rp=ROOT/'commons/artifacts/registry/force_halls.json';backup(rp);registry=read(rp)
    for token in COMBINED_HALL['tutorial_artifacts']:
        registry['artifacts'][token]['footprint']=[5,3,5]
        registry['artifacts'][token]['description']='Move the known PointBody by hand. Live local XYZ values and solid slender arrows show '+token.removeprefix('force_point_')+'.'
    write(rp,registry)
    lesson=mp.parent/'FORCES_LESSON.md'
    if lesson.exists():backup(lesson)
    lesson.write_text('# Vectors in your hands\n\nThree stations in one map. One reconstruction per principle.\n\n'+COMBINED_HALL['lesson']+'\n\nLearning elements:\n\n- Displacement and magnitude.\n- Unit direction, including zero.\n- Addition: head to tail; route versus arrival.\n- Signed projection and the perpendicular remainder.\n\nCarry: '+COMBINED_HALL['carry']+'\n\nCheck: '+COMBINED_HALL['independent_check']+'\n\nThis is the revised lesson contract; the full tutorial and reflective manuscripts are separate.\n',encoding='utf8')
    pp=ROOT/'doc/book/course/forces-primary-objects.json';backup(pp);proposal=read(pp)
    merged=copy.deepcopy(proposal['halls'][0])
    merged.update(title=COMBINED_HALL['title'],principle=COMBINED_HALL['principle'],primary='PointBody: direction, addition and projection',gesture='Grab and move the four black points across three stations.',current='Three working PointBody stations in one map. Values follow the balls; solid cylinder arrows show direction, head-to-tail addition and signed projection.',upgrade='Implemented vector compaction; headset legibility and reach remain for human review.',tutorial=COMBINED_HALL['lesson'],check=COMBINED_HALL['independent_check'],support='No separate comparison machines. Borrowed ruler ticks, head-to-tail construction and signed readings.',status='Implemented; see vectors-one-room verification')
    proposal['halls']=[merged]+[r for r in proposal['halls'] if r['map'] not in [FIRST]+RETIRED]
    proposal['order_judgment']='Eleven active halls. The first contains the three vector operations. Then launch, motion, field, drag, spring, choreography, gravity, support, collision and the player receiver. Other upgrade proposals retain their existing status.'
    write(pp,proposal)
    write(OUT/'curation.json',plan)
    print('Compacted vector mathematics: 3 stations, 4 points, 11 active Forces halls.')

if __name__=='__main__':build()

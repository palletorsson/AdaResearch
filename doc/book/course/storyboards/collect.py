"""Inventory the actual spine, saved museum plan and attributed museum captures."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))
def rel(path):
    return path.relative_to(ROOT).as_posix()
spine = sorted(read(ROOT/'commons/maps/curriculum_spine.json')['spine']['sequences'], key=lambda s:s['order'])
plan = read(ROOT/'ada_run/em_plan.json')['plans']
planned = {p['map']:p for p in plan if p.get('map')}
segments = {s['name']:s for s in read(ROOT/'commons/data/long_museum.json')['segments'] if s['kind']=='hall'}
sequences=[]
hall_ids=set()
for seq in spine:
    raw=read(ROOT/f'commons/maps/sequences/{seq["name"]}.json')['sequences'][seq['name']]
    sequences.append({'id':seq['name'],'order':seq['order'],'label':raw.get('name',seq['name']),'maps':raw['maps']})
    hall_ids.update(raw['maps'])

candidates={m:[] for m in hall_ids}
def add_images(map_id, folder, evidence, kind):
    if map_id not in candidates: return
    for pic in folder.glob('*.png'):
        name=pic.stem.lower()
        if re.search(r'before|grid.view|dollhouse|top.down|overhead|contact.sheet|rejected|hello|fixture|diagnostic',name): continue
        if pic.stat().st_size < 30000: continue
        candidates[map_id].append({'path':rel(pic),'evidence':rel(evidence),'kind':kind,'mtime':pic.stat().st_mtime})

for spec in (ROOT/'ada_run/encounter_pilot').glob('*/spec.json'):
    try:
        data=read(spec)
        add_images(data.get('room'),spec.parent,spec,'Saved museum probe')
    except (ValueError,OSError): pass

# Museum probe reports were also preserved alongside earlier book reviews.
for manifest in (ROOT/'doc/book/iterations').rglob('source_manifest.json'):
    if any(p in ('before','evidence','sources','backups') for p in manifest.relative_to(ROOT/'doc/book/iterations').parts): continue
    try:
        data=read(manifest)
        sources=str(data.get('sources',{}))
        if 'endless_museum' not in sources and 'museum' not in str(data.get('scope','')).lower():continue
        add_images(data.get('room',data.get('map')),manifest.parent,manifest,'Preserved museum capture')
    except (ValueError,OSError,AttributeError): pass

choices=read(OUT/'image-choices.json') if (OUT/'image-choices.json').exists() else {}
for mid, paths in choices.items():
    for path in paths:
        pic=ROOT/path
        assert pic.exists(),path
        evidence=next((pic.parent/name for name in ('source_manifest.json','spec.json','run.json','report.json') if (pic.parent/name).exists()),None)
        if evidence is None and (pic.parent.parent/'figure-provenance.json').exists(): evidence=pic.parent.parent/'figure-provenance.json'
        assert evidence is not None,path
        candidates[mid].append({'path':path,'evidence':rel(evidence),'kind':'Curated museum capture','mtime':pic.stat().st_mtime})

# Explicit image preferences keep selected artifact views useful rather than
# treating a newer timestamp as a guarantee of a clearer picture.
preferred={
 'Point_Zero':'museum-counter.png','Point_One':'corridor.png','Point_Coordinates':'coordinates-basin.png',
 'Point_Lines':'entrance-line.png','Point_Trace':'room.png','Trans_Rotation':'museum-study-context.png',
 'Array':'museum-hall.png','Color_Nails':'salon-violet.png','SoftBodies_Cloth_Physics':'gantry.png',
 'SpeculativeComputation_Rhizome_Network':'museum-junction.png'
}
def score(pic,map_id):
    name=Path(pic['path']).name.lower()
    words=['museum','hall','room','overview','approach','entry','context','panorama','inside','gantry','first-view']
    value=sum(10 for w in words if w in name)
    if name==preferred.get(map_id):value+=120
    if name=='museum-encounter.png':value+=25
    if pic['path'] in choices.get(map_id,[]):value+=1000-choices[map_id].index(pic['path'])
    if any(w in name for w in ('broken','failure','empty','closed','controls','close')):value-=12
    return (value,pic['mtime'])
halls=[]
source_hashes={}
for seq in sequences:
    for order,map_id in enumerate(seq['maps'],1):
        folder=ROOT/'commons/maps'/map_id
        mp=folder/'map_data.json'
        data=read(mp) if mp.exists() else {}
        source_hashes[rel(mp)]=hashlib.sha256(mp.read_bytes()).hexdigest() if mp.exists() else None
        placed=[]
        layer=data.get('layers',{}).get('interactables',[])
        if isinstance(layer,list):
            for z,row in enumerate(layer):
                if not isinstance(row,list):continue
                for x,token in enumerate(row):
                    if isinstance(token,str) and token.strip() and token.strip()!='0':
                        placed.append({'x':x,'z':z,'token':token,'id':token.split(':')[0].split('#')[0]})
        docs={}
        for name in ('final','tutorial','intent','critical','technical','artifacts'):
            p=folder/(name+'.md')
            if p.exists():docs[name]=rel(p)
        p=planned.get(map_id)
        segment=segments.get(map_id,{})
        unique={pic['path']:pic for pic in candidates[map_id]}
        pics=sorted(unique.values(),key=lambda a:score(a,map_id),reverse=True)
        halls.append({'id':map_id,'sequence':seq['id'],'index':order,'docs':docs,'map_source':rel(mp),
            'placed':placed,'dimensions':data.get('map_info',{}).get('dimensions',{}),
            'structure':data.get('layers',{}).get('structure',[]),
            'plan_present':p is not None,'plan_position':plan.index(p)+1 if p else None,
            'plan_museum':p.get('museum') if p else None,
            'strip':{k:segment[k] for k in ('w','h','z0','z1','source','layout','tile_source') if k in segment},
            'images':pics[:8]})
extras=[{'map':p['map'],'sequence':p['sequence'],'note':'Removed from Colour by author; retained in saved plan.' if p['map']=='Chamber_Color' else 'Saved-plan side encounter; not in the current book spine.'} for p in plan if p.get('map') and p['map'] not in hall_ids]
result={'date':'2026-10-04','sequences':sequences,'halls':halls,'plan_extras':extras,
        'sources':['commons/maps/curriculum_spine.json','commons/maps/sequences/*.json','ada_run/em_plan.json','commons/data/long_museum.json'],
        'map_source_hashes':source_hashes,
        'scope':'Current book spine in museum order; saved museum-plan comparison. Prior images are attributed captures, not verification of the current lesson or headset.'}
(OUT/'inventory.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'sequences':len(sequences),'halls':len(halls),'with_images':sum(bool(h['images']) for h in halls),'missing_images':[h['id'] for h in halls if not h['images']],'saved_plan_extras':extras},indent=2))

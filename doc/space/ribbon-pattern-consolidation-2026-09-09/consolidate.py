"""One-time scoped migration. Archives inputs; does not retire source folders."""
from pathlib import Path
from collections import Counter, defaultdict
import json, math, re, copy, hashlib

ROOT = Path.cwd()
OUT = ROOT / 'doc/space/ribbon-pattern-consolidation-2026-09-09'
def read(p): return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def save(p, d):
    p = Path(p); p.parent.mkdir(parents=True, exist_ok=True)
    s = json.dumps(d, indent=1, ensure_ascii=False)
    if p.name == 'map_data.json':
        s = re.sub(r'\[\n\s*(?:"(?:[^"\\]|\\.)*"\s*,?\s*)+\]', lambda m: json.dumps(json.loads(m.group()), ensure_ascii=False), s)
    p.write_text(s+'\n', encoding='utf-8')
def backup(p):
    p = Path(p); q = OUT / 'before' / p.relative_to(ROOT)
    if p.exists() and not q.exists(): q.parent.mkdir(parents=True, exist_ok=True); q.write_bytes(p.read_bytes())
def token(v): return str(v).split(':')[0].split('#')[0].strip()

sources = sorted(p.parent.name for p in (ROOT/'commons/maps').glob('Ribbon_Color_*/map_data.json'))
assert len(sources) == 7, 'Migration expects the seven original ribbon rooms.'
shared = ['commons/maps/sequences/color.json', 'commons/maps/sequences/tiling.json', 'commons/maps/sequences/placed_museums.json', 'commons/data/artifact_roles.json', 'commons/data/map_authored.json', 'commons/data/book/color.json', 'commons/data/book/tiling.json', 'commons/data/museum_core_encounters.json', 'commons/data/spine_artifact_order.json', 'ada_run/em_plan.json', 'commons/data/museum/em_plan.json', 'commons/data/long_museum.json', 'commons/data/museum_order_effective.json']
for p in shared: backup(ROOT/p)
for m in sources:
    for p in (ROOT/'commons/maps'/m).iterdir():
        if p.is_file(): backup(p)

owners = defaultdict(list)
for seq in ['color', 'tiling']:
    for m in read(ROOT/f'commons/maps/sequences/{seq}.json')['sequences'][seq]['maps']:
        if m in sources: continue
        for row in read(ROOT/f'commons/maps/{m}/map_data.json')['layers']['interactables']:
            for v in row:
                if token(v): owners[token(v)].append({'map':m, 'placement':v})
kept = {}; removed = []
for m in sources:
    for z,row in enumerate(read(ROOT/f'commons/maps/{m}/map_data.json')['layers']['interactables']):
        for x,v in enumerate(row):
            t=token(v)
            if not t: continue
            rec={'token':t,'source_map':m,'source_cell':[x,z],'source_placement':v}
            if t in owners: removed.append(dict(rec, retained_at=owners[t]))
            elif t in kept: removed.append(dict(rec, retained_at=[kept[t]]))
            else: kept[t]=rec

groups = [
 ('Ribbon_Patterns_01','Structure and repetition','grid_2d_4x4 grid_3d_4x4x4 xyz_coordinates column_3_z row_3_x grid3d bar_array bar_array_bubble_sort sorting_algorithm_race shelf shelf_with_stickers'.split(), ['grid_2d_4x4','grid_3d_4x4x4']),
 ('Ribbon_Patterns_02','Sampling and comparison','spherecolors hue_carousel grabcolorcollection color_mixing SimultaneousContrast MetamerismLab dark_side_prism prism grab_stick_scanner color_scanner grab_stick two_roads'.split(), ['SimultaneousContrast','MetamerismLab']),
 ('Ribbon_Patterns_03','Signals and glitches','pulsar_visualizer standalone_disco coloredlines RotatingLaser minimalglitch textureglitch glitchcolor advancedglitch colortrails neon_garden strobe_lasers disco_lights one_bulb_room laser_turret'.split(), ['minimalglitch','textureglitch'])]
assert Counter(t for _,_,ts,_ in groups for t in ts) == Counter(kept.keys())
reg={}
for p in (ROOT/'commons/artifacts/registry').glob('*.json'):
    d=read(p).get('artifacts',{})
    if isinstance(d,dict): reg.update(d)
# Conservative local reservations for procedural artifacts without a recorded AABB.
fallback={'hue_carousel':([4,3,4],[0,1.5,0]),'two_roads':([5,3,9],[0,1.5,3]),'neon_garden':([5,4,5],[0,2,0]),'one_bulb_room':([6,4,6],[0,2,0]),'colortrails':([8,6,8],[0,3,0]),'strobe_lasers':([10,6,10],[0,3,0])}
roles=read(ROOT/'commons/data/artifact_roles.json');core=read(ROOT/'commons/data/museum_core_encounters.json')
report={'source_maps':sources,'sequence':'tiling','duplicate_policy':'Remove ribbon copies when the artifact is represented in an authored colour/tiling room; prefer the authored room including its developed configuration. Preserve all remaining ribbon tokens once. Deliberate repeats inside authored rooms are outside this consolidation.','removed':removed,'rooms':[],'learner_verified':False}
for name,title,tokens,primary in groups:
    items=[]
    for t in tokens:
        entry=reg[t];measurement=entry.get('measurements',{})
        size=measurement.get('aabb_size');center=measurement.get('aabb_center')
        if not size or max(size)==0: size,center=fallback.get(t,([4,4,4],[0,2,0]))
        center=center or [0,0,0]
        raw=kept[t]['source_placement'];parts=raw.split('#')[0].split(':');rot=float(parts[1]) if len(parts)>1 else 0
        theta=math.radians(rot);c,s=math.cos(theta),math.sin(theta)
        corners=[(c*x+s*z,-s*x+c*z) for x in [center[0]-size[0]/2,center[0]+size[0]/2] for z in [center[2]-size[2]/2,center[2]+size[2]/2]]
        bounds=[min(p[0] for p in corners),min(p[1] for p in corners),max(p[0] for p in corners),max(p[1] for p in corners)]
        items.append({'token':t,'rotation':rot,'bounds':bounds,'measurement':bool(measurement.get('aabb_size') and max(measurement['aabb_size'])>0),'source':kept[t]})
    bay=math.ceil(max(i['bounds'][2]-i['bounds'][0] for i in items))+4
    width=2*bay+7;aisle=width//2;cursor=5;placements=[]
    for start in range(0,len(items),2):
        pair=items[start:start+2];rowdepth=math.ceil(max(i['bounds'][3]-i['bounds'][1] for i in pair))+4
        for side,item in enumerate(pair):
            b=item['bounds'];targetx=2+bay/2 if side==0 else width-3-bay/2
            x=round(targetx-(b[0]+b[2])/2);z=round(cursor+rowdepth/2-(b[1]+b[3])/2)
            # Full-size scenes, existing orientation; prevent museum packing from silently sliding them.
            raw=item['source']['source_placement']+'#pin:1#plinth:0'
            item.update(cell=[x,z],placement=raw,reserved_bounds=[x+b[0],z+b[1],x+b[2],z+b[3]])
            placements.append(item)
        cursor+=rowdepth
    depth=cursor+5
    layers={k:[['1' if k=='structure' else '' for x in range(width)] for z in range(depth)] for k in ['structure','utilities','interactables']}
    for z in range(depth):
        for x in range(width):
            if x in [0,width-1] or z in [0,depth-1]:layers['structure'][z][x]='4'
    for z in [0,depth-1]:
        for x in range(aisle-1,aisle+2):layers['structure'][z][x]='1'
    layers['utilities'][2][aisle]='s';layers['utilities'][depth-3][aisle]='t'
    for i in placements:
        x,z=i['cell'];assert not layers['interactables'][z][x];layers['interactables'][z][x]=i['placement']
        b=i['reserved_bounds'];assert b[0]>1 and b[2]<width-1 and b[1]>1 and b[3]<depth-1
        assert b[2]<aisle-1.5 or b[0]>aisle+1.5
    d={'map_info':{'name':name,'lookup_name':name,'title':title,'description':'Consolidated remaining exhibits from the former colour ribbon.','version':'1.0','format':'json','dimensions':{'width':width,'depth':depth,'max_height':4},'museum':{'wall_height':4,'open_roof':True,'gate':False,'plinths':False,'passage':{'kind':'straight','width':3,'offset':0}},'metadata':{'sequence':'tiling','source':'2026-09-09 ribbon consolidation','source_maps':sorted({kept[t]['source_map'] for t in tokens}),'n_artifacts':len(tokens),'layout':'Two exhibit bays with a clear central aisle; measured footprint reservations, full-size scenes.'}},'layers':layers}
    p=ROOT/'commons/maps'/name;p.mkdir(exist_ok=True);save(p/'map_data.json',d)
    intro=f'{title}. This hall gathers {len(tokens)} remaining ribbon exhibits after copies already represented in the authored colour and pattern rooms were removed.'
    (p/'blurb.md').write_text(intro+'\n',encoding='utf-8')
    (p/'summary.md').write_text('# '+title+'\n\n'+intro+'\n\nPrimary encounters: '+', '.join(primary)+'. All other exhibits are secondary material for subsequent curation. This is a collection scaffold, not a completed lesson.\n',encoding='utf-8')
    (p/'technical.md').write_text('# Layout and provenance\n\nOriginal scene tokens and orientations are retained. Placement uses recorded AABBs, with conservative reservations where procedural scenes have no measurement. Two exhibit bays leave a central aisle clear; the building surrounds the collection.\n\nSee `doc/space/ribbon-pattern-consolidation-2026-09-09/report.json` for every source cell, removed duplicate, destination and spatial reservation. Headset performance and complete interaction testing remain pending.\n',encoding='utf-8')
    (p/'critical.md').write_text('# A question for the next pass\n\nWhat does this collection treat as a repeat, and what differences does that decision suppress? Removing a second placement is an editorial decision. It does not prove two encounters would have produced the same understanding. The archive retains the comparison.\n',encoding='utf-8')
    roles['roles'][name]={t:'primary' if t in primary else 'secondary' for t in tokens};roles['order'][name]={'primary':primary,'secondary':[t for t in tokens if t not in primary],'decoration':[]};roles['groups'][name]=[]
    core['rooms'][name]={'sequence':'tiling','status':'text_pending','primary_tokens':primary,'reason':'Consolidated ribbon collection; primary encounters selected provisionally.','learner_verified':False,'map_sha256':hashlib.sha256((p/'map_data.json').read_bytes()).hexdigest()}
    report['rooms'].append({'map':name,'title':title,'dimensions':[width,depth],'primary':primary,'placements':placements})
newmaps=[g[0] for g in groups]
for key in ['roles','order','groups']:
    for m in sources:roles[key].pop(m,None)
for m in sources:core['rooms'].pop(m,None)
save(ROOT/'commons/data/artifact_roles.json',roles);save(ROOT/'commons/data/museum_core_encounters.json',core)
for seq in ['color','tiling','placed_museums']:
    p=ROOT/f'commons/maps/sequences/{seq}.json';d=read(p);s=d['sequences'][seq]
    s['maps']=[m for m in s['maps'] if not m.startswith('Ribbon_Color_')]
    if 'content' in s:s['content']=[v for v in s['content'] if not str(v).startswith('Ribbon_Color_')]
    if seq in ['tiling','placed_museums']:
        s['maps']+=newmaps;s.setdefault('content',[]).extend(n+': '+t for n,t,_,_ in groups)
    if seq=='tiling':s['ribbon_consolidation']='2026-09-09: seven former colour ribbon rooms consolidated into three annexes; authored colour/tiling copies take precedence. Remaining exhibits occur once across the annexes.'
    save(p,d)
p=ROOT/'commons/data/book/tiling.json';b=read(p);b['pearls']=[v for v in b['pearls'] if v['map'] not in sources]
for n,title,ts,primary in groups:b['pearls'].append({'map':n,'pearl':n.replace('_',' ').lower(),'title':title,'hero':primary[0],'join':True,'lines':[{'token':t,'text':t.replace('_',' '),'by':'astra'} for t in primary]})
save(p,b)
p=ROOT/'commons/data/book/color.json';b=read(p);b['pearls']=[v for v in b['pearls'] if v['map'] not in sources];save(p,b)
p=ROOT/'commons/data/map_authored.json';a=read(p)
for key,vals in a.items():
    if isinstance(vals,list):a[key]=[v for v in vals if v not in sources]
save(p,a)
for p in [ROOT/'ada_run/em_plan.json',ROOT/'commons/data/museum/em_plan.json']:
    d=read(p);d['plans']=[v for v in d['plans'] if v.get('map') not in sources];save(p,d)
report['counts']={'source_placements':len(kept)+len(removed),'removed_duplicate_placements':len(removed),'retained_unique_artifacts':len(kept),'old_rooms':len(sources),'new_rooms':len(groups)}
save(OUT/'report.json',report)
print(json.dumps(report['counts']));print([(r['map'],r['dimensions']) for r in report['rooms']])

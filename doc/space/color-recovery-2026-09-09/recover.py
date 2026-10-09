from pathlib import Path
import json,subprocess,copy,re,hashlib
ROOT=Path.cwd(); OUT=ROOT/'doc/space/color-recovery-2026-09-09'
G=['git','-c','safe.directory='+str(ROOT).replace('\\','/')]
REV=subprocess.check_output(G+['rev-parse','62e08730f^']).decode().strip()
def historical(path):return subprocess.check_output(G+['show',REV+':'+path])
def read(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def save(p,d,indent=1):
 s=json.dumps(d,indent=indent,ensure_ascii=False)
 if str(p).endswith('map_data.json'): s=re.sub(r'\[\n\s*(?:"(?:[^"\\]|\\.)*"\s*,?\s*)+\]',lambda m:json.dumps(json.loads(m.group()),ensure_ascii=False),s)
 Path(p).write_text(s+'\n',encoding='utf-8')
def backup(path):
 p=Path(path); dest=OUT/'before'/p
 if p.exists() and not dest.exists():dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes())
seqpath='commons/maps/sequences/color.json';hist=historical(seqpath);(OUT/'historical').mkdir(exist_ok=True);(OUT/'historical/color.json').write_bytes(hist)
s=json.loads(hist.decode('utf-8-sig'))['sequences']['color'];color=[m for m in s['maps'] if m!='Pattern_Foundry']
tiling=read('commons/maps/sequences/tiling.json')['sequences']['tiling']['maps']
for p in [seqpath,'commons/maps/sequences/tiling.json','commons/maps/curriculum_spine.json','commons/data/map_authored.json','commons/data/book/color.json','commons/data/book/tiling.json','commons/data/artifact_roles.json','commons/data/museum_core_encounters.json','commons/data/spine_artifact_order.json','ada_run/em_plan.json','commons/data/museum/em_plan.json']:backup(p)
report={'historical_commit':REV,'boundary':'Parent of first endless museum commit 62e08730f, 2026-07-31','color_maps':color,'pattern_sequence':'tiling','pattern_maps':tiling,'rooms':[],'learner_verified':False}
for m in color+tiling:
 path='commons/maps/'+m+'/map_data.json'
 for p in Path('commons/maps',m).glob('*'):
  if p.is_file():backup(p)
 if m in color:
  data=historical(path);hp=OUT/'historical'/m/'map_data.json';hp.parent.mkdir(parents=True,exist_ok=True);hp.write_bytes(data);old=json.loads(data.decode('utf-8-sig'));source=REV
 else:
  old=read(OUT/'before'/path);source='current arrangement retained; already assigned to tiling'
 d=copy.deepcopy(old); layers=old['layers'];h=max(len(v) for v in layers.values() if isinstance(v,list));w=max(len(r) for v in layers.values() if isinstance(v,list) for r in v)
 pad=4; nw=w+pad*2;nh=h+pad*2
 if m=='Color_Pillar':nw=41;nh=38
 if m=='Color_Walls':nw=37
 out={k:[['1' if k=='structure' else '' for x in range(nw)] for z in range(nh)] for k in layers}
 for k,a in layers.items():
  for z,row in enumerate(a):
   for x,val in enumerate(row):out[k][z+pad][x+pad]=val
 wallheight=max(8,int(float(old['map_info']['dimensions'].get('max_height',4)))+1)
 for z in range(nh):
  for x in range(nw):
   if z in [0,nh-1] or x in [0,nw-1]:out['structure'][z][x]=str(wallheight)
 for z in [0,nh-1]:
  for x in range(nw//2-1,nw//2+2):out['structure'][z][x]='1'
 # The old footprint remains byte-for-byte in its new offset. Expanded artifacts
 # move into added floor instead of erasing the old map's internal geometry.
 edits=[]
 for z,row in enumerate(out.get('interactables',[])):
  for x,t in enumerate(row):
   token=str(t).split(':')[0].split('#')[0]
   if token=='ball_painting_demo':row[x]=str(t)+'#automated:true';edits.append({'token':token,'from':[x,z],'to':[x,z],'change':'automatic painting'})
   if token=='pillarcolorcollection' and m=='Color_Pillar':
    row[x]='';out['interactables'][8][20]='pillarcolorcollection:0:-0.5:1#layout:spatial_gradient#plinth:0';edits.append({'token':token,'from':[x,z],'to':[20,8],'change':'35 spatial samples in a 12.8 x 19.2 m gradient annex'})
   if token=='color_sets_overview' and m=='Color_Pillar':
    row[x]='';out['interactables'][32][26]='color_sets_overview:180:-0.5:1#mount:wall#plinth:0';edits.append({'token':token,'from':[x,z],'to':[26,32],'change':'framed 6.4 m palette wall beyond the field'})
   if token=='color_constellation_office' and m=='Color_Walls':
    row[x]='';out['interactables'][20][23]='color_constellation_office:0:-0.5:1#layout:cubicles#plinth:0';edits.append({'token':token,'from':[x,z],'to':[23,20],'change':'eight full-size cubicles in the added east gallery'})
 if m=='Color_Flashlight':out['interactables'][9][9]='flashlight_demo:180:-0.5:1#plinth:0';edits.append({'token':'flashlight_demo','from':None,'to':[9,9],'change':'historical map was empty; install its existing namesake demonstration'})
 d['layers']=out;d['map_info']['dimensions']={'width':nw,'depth':nh,'max_height':wallheight}
 d['map_info']['museum']={'wall_height':wallheight,'open_roof':True,'gate':False,'plinths':False,'passage':{'kind':'straight','width':3,'offset':0},'simulation':{'grid':True,'staged':False,'margin':1,'depth':0.3,'fire':False},'recovery':{'source':source,'offset':[pad,pad],'source_size':[w,h]}}
 d['map_info'].setdefault('metadata',{})['museum_recovery']='2026-09-09: original configuration surrounded by a new wall; selected oversized exhibits occupy added floor.'
 save(path,d)
 # Check every original structure and utility cell survived the padding.
 for k in ['structure','utilities']:
  for z,row in enumerate(layers.get(k,[])):
   for x,v in enumerate(row):assert out[k][z+pad][x+pad]==v,(m,k,x,z)
 report['rooms'].append({'map':m,'source':source,'original_size':[w,h],'museum_size':[nw,nh],'offset':[pad,pad],'changes':edits})
 current=read(seqpath)['sequences']['color'] if m==color[0] else None
# Retain current conceptual metadata, restore old colour membership, remove stale pattern content.
d=read(seqpath);c=d['sequences']['color'];c['maps']=color;c['content']=[m+': '+{'Color_Pillar':'A spatial gradient sampled by pillars; named palettes on a wall','Color_Walls':'Colour at office scale through orthogonal glass cubicles','Color_Paint':'A painting continues before you touch it','Color_Flashlight':'Light meets a coloured surface'}.get(m,m.replace('_',' ')) for m in color];c['deferred_maps']=[m for m in c.get('deferred_maps',[]) if m not in color];c['museum_recovery']=report['historical_commit'];c['v1_3_note']='2026-09-09: restore the pre-endless-museum colour rooms. Pattern maps belong exclusively to tiling; array indexing remains in array_tutorial.';c['deferred_reason']='The earlier consolidation is superseded by the documented 2026-09-09 recovery. Pattern_Foundry, Tutorial_Pattern, Array_Patterns and Symmetry_Seventeen are in tiling.';c.pop('taxonomy',None);save(seqpath,d)
p='commons/maps/sequences/tiling.json';d=read(p);t=d['sequences']['tiling'];t['content']=[m+': '+m.replace('_',' ') for m in tiling];t['museum_recovery_note']='2026-09-09: retain current pattern configurations inside perimeter walls. These four maps are owned by tiling, never colour.';save(p,d)
p='commons/maps/curriculum_spine.json';d=read(p)
for r in d['spine']['sequences']:
 if r['name']=='color':r['description']='Recovered colour rooms: colour in the hand, palette, spectrum, spatial gradient, painting, context and glass architecture. Pattern maps belong to the following tiling sequence.'
save(p,d)
save(OUT/'recovery.json',report,2)
print('Recovered',len(color),'colour maps; enclosed',len(tiling),'existing pattern maps; original structures and utilities verified.')

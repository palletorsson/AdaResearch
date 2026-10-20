"""Add seven independently placeable ordinary-object entropy encounters."""
from pathlib import Path
import json
import shutil
from em_map_halls import derive_row

ROOT=Path(__file__).resolve().parents[1]
HERE=ROOT/'doc/book/iterations/2026-10-16-ordinary-entropies'
MAP='Random_Entropies'
IDS=['entropy_chairs_shannon','entropy_chairs_boltzmann','entropy_chairs_description','entropy_door_dynamics','entropy_cooling_cup','entropy_frosted_chair','entropy_ball_pit']
NAMES=['Shannon: a chair colour','Boltzmann: how many arrangements','Algorithmic complexity: describe these chairs','Dynamical entropy: a door and its rule','Thermodynamic entropy: a cooling cup','Conditional entropy: the frosted chair','Min-entropy: the easiest guess']
CELLS=[(4,6),(13,6),(9,18),(9,24),(6,30),(9,41),(9,50)]
FOOTPRINTS=[[8, 3, 7], [9, 3, 7], [17, 3, 4], [18, 3, 5], [12, 3, 4], [18, 3, 4], [17, 3, 4]]
TUTORIALS=['Compare four visible inventories: 4/4, the same counts rearranged, 7/1 and 8/0. Predict uncertainty in a hypothetical equal-ID colour draw; reconstruct the colour-count function.', 'Compare sorted, mixed and a second arrangement with the same count. Enumerate assignments: Omega=1 versus 36; colour H stays one bit.', 'Four chair groups and their candidate recipes remain visible together. Reconstruct seed 435 with the shared generator; do not infer shortest-program length from appearance.', 'Watch contracting and expanding pairs in a solid wall on the same nine-step clock. Reconstruct LOW/HIGH records. The central doorway stays open.', 'Compare five cups on one table, with a donut and plate: fixed 25% milk, different mixing stages. Reconstruct the separate heat model at 0, 5, 15, 30, 60 seconds; neither swirl nor steam measures entropy.', 'Compare five panes over one chair: identity, colour plus arms, colour, colour, no detail. Reconstruct 0, 1, 2, 2, 3 unresolved bits from eight identities. Stronger blur does not necessarily change the record.', 'Keep one colour question: sixteen equal-sized balls, pink/teal counts 8/8, 12/4 and 16/0. Best chances 1/2, 3/4 and 1 give min-entropies 1, 0.415 and 0 bits.']
FINALS=[
 'Familiar seats establish scale. Rearranging the colours can alter the scene while its one-bit reading stays still. The unregistered visible difference asks for another account of arrangement.',
 'Across the divider, many assignments can meet one brief. Fixed colour uncertainty now accompanies changing multiplicity. The next wall asks what it would take to describe a particular arrangement.',
 'The scatter resists the eye, then yields to a short seeded recipe. What looks difficult to remember may be simple to construct. A rule can specify motion as well as a frozen arrangement.',
 'One pair of leaves converges; another rule separates them. Movement alone does not establish growing uncertainty. Holding the door open lets us pass into a change whose direction concerns energy.',
 'A pale wisp locates the hot cup. The cup loses entropy while the combined system gains it. Another wall turns attention from heat leaving an object to detail missing from its record.',
 'Something pink remains through the pane while distinctions among backs and arms are dropped. Remaining uncertainty belongs to a specified observation. The last chamber asks which one answer is easiest to guess.',
 'The question stays while a guess becomes certain. The next hall asks what changes a measurement can miss.'
]
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def write(path,data):
 path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def backup(path):
 dest=HERE/'before'/path.relative_to(ROOT)
 if path.exists() and not dest.exists():dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
def main():
 folder=ROOT/'commons/artifacts/ordinary_entropies';folder.mkdir(parents=True,exist_ok=True)
 registry_path=ROOT/'commons/artifacts/registry/ordinary_entropies.json'
 registry=read(registry_path) if registry_path.exists() else {'id':'ordinary_entropies','name':'Different entropies, ordinary objects','artifacts':{}}
 for i,(id,name,footprint) in enumerate(zip(IDS,NAMES,FOOTPRINTS)):
  (folder/f'{id}.tscn').write_text(f'''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://commons/artifacts/ordinary_entropies/comparison.gd" id="1"]
[node name="{id}" type="Node3D"]
script = ExtResource("1")
kind = {i}
''',encoding='utf-8')
  registry['artifacts'][id]={'lookup_name':id,'name':name,'scene':f'res://commons/artifacts/ordinary_entropies/{id}.tscn','description':name+'. Simultaneous versions at everyday scale, with one compact wall explanation and no interface. See the map tutorial for the measurement contract.','category':'randomness','complexity':'intermediate','map_ready':True,'include_in_map_data':True,'map_sequences':['randomness'],'tags':['entropy','everyday objects','experiment','simultaneous comparison','wall text'],'parameters':{'footprint':footprint,'size_group':'floor_display'},'qfep_connection':'Changing the measurement, grouping or update rule changes which differences can matter. No single disorder gauge substitutes for these distinct contracts.','interactions':['Walk between the versions and compare what differs with what remains fixed.',TUTORIALS[i]]}
 write(ROOT/'commons/artifacts/registry/ordinary_entropies.json',registry)
 width,depth=19,57
 structure=[['1']*width for _ in range(depth)]
 utilities=[['']*width for _ in range(depth)]
 artifacts=[['']*width for _ in range(depth)]
 for z in range(depth):structure[z][0]=structure[z][-1]='4'
 for z in [0,depth-1]:
  for x in range(width):structure[z][x]='4' if x not in [8,9,10] else '1'
 for z,gaps in [(11,range(14,18)),(35,range(14,18)),(44,[8,9,10])]:
  for x in range(1,width-1):structure[z][x]='1' if x in gaps else '4'
 # The low divider is geometry in the map, not an unregistered eighth instrument.
 for z in range(3,9):structure[z][9]='p:1'
 utilities[1][9]='s';utilities[55][9]='t:Random_Entropy'
 structure[55][9]='0'
 for id,(x,z) in zip(IDS,CELLS):artifacts[z][x]=id+':180:0#plinth:0#pin:1'
 artifacts[2][3]='entropy_chair_reference:180:0#plinth:0#pin:1'
 artifacts[13][9]='research_info_wall:0:0#plinth:0#pin:1#style:gallery#storage_key:Random_Entropies-work-wall'
 data={'map_info':{'name':'Entropy Types','title':'What remains uncertain','lookup_name':MAP,'description':'Seven everyday-scale encounters distinguish colour uncertainty, configurational counting, description length, temporal information, heat transfer, partial records and best guesses.','version':'1.0','format':'json','dimensions':{'width':width,'depth':depth,'max_height':4},'metadata':{'difficulty':'intermediate','category':'laboratory','estimated_time':'12-20 minutes','n_artifacts':9,'learning_objectives':['Declare the outcomes, ensemble, record or update rule before interpreting a number.','Compare Shannon and Boltzmann chair studies without treating scattering as a universal entropy measure.','Compare simultaneous versions, identify the fixed conditions and reconstruct one difference.']},'museum':{'wall_height':2,'artifact_placement':'map','plinths':False,'piers':False,'gate_depth_rows':0,'open_roof':True,'sculpture_clear_rects':[[1,1,17,55]],'props_deny':['dream_bodies']}},'documentation':{'summary':'Seven distinct questions, one route through ordinary objects.','layout':'Paired chairs, low divider, wall with east opening, description wall, driven door, cooling cup, another wall, frosted chair, wall and ball pit.','objective':'Change one explicit contract and observe what its measure can and cannot register.','key_elements':[f'{id} at {cell}' for id,cell in zip(IDS,CELLS)]},'layers':{'structure':structure,'utilities':utilities,'interactables':artifacts},'lighting':{'ambient_color':[0.75,0.72,0.65],'ambient_energy':0.6},'settings':{'cube_size':1.0,'enable_physics':True}}
 write(ROOT/f'commons/maps/{MAP}/map_data.json',data)
 data['map_info']['museum']['floor_cells']=[[9,55]]
 write(ROOT/f'commons/maps/{MAP}/map_data.json',data)
 wall={'schema':'writing-wall/1','map':MAP,'order':IDS,'magnets':[],'notes':[],'edges':[]}
 for i,(id,name,(x,z)) in enumerate(zip(IDS,NAMES,CELLS)):
  wall['magnets'].append({'id':id,'x':x*60,'y':z*35,'brief':name,'question':['Which colour can the next draw produce?','How many assignments match this left-side count?','Does looking irregular require a long description?','Does this rule reveal new distinctions over time?','Where does the cup lose heat, and where does entropy increase?','What does this record leave unresolved?','Which guess wins most often under this sampling rule?'][i],'tutorial':TUTORIALS[i],'final':FINALS[i],'theme':'entropy','tags':['tutorial','final']})
 wall['magnets'].append({'id':'research_info_wall','x':540,'y':455,'brief':'Shared research wall / notes and drawings','question':'What should remain beside the explanation?','tutorial':'Write or draw a comparison; move a sticky note; return to its locally saved ink and position.','final':'','theme':'research','tags':[]})
 write(ROOT/f'commons/maps/{MAP}/writing_wall.json',wall)
 p=ROOT/'commons/maps/sequences/randomness.json';backup(p);d=read(p);seq=d['sequences']['randomness']
 if MAP not in seq['maps']:seq['maps'].insert(seq['maps'].index('Random_Definition')+1,MAP)
 line=MAP+': Seven ordinary-object encounters distinguish different entropy contracts'
 if line not in seq['content']:seq['content'].insert(1,line)
 if not any(g.get('map')==MAP for g in seq.get('artifact_groups',[])):seq.setdefault('artifact_groups',[]).append({'map':MAP,'position':'foundation','artifacts':IDS,'size_budget':'environmental','rationale':'One measurement contract becomes insufficient and prepares the next encounter.','grammar':'enfilade'})
 write(p,d)
 p=ROOT/'commons/data/map_authored.json';backup(p);d=read(p)
 if MAP not in d['randomness']:d['randomness'].insert(d['randomness'].index('Random_Definition')+1,MAP)
 write(p,d)
 p=ROOT/'commons/data/book/randomness.json';backup(p);d=read(p)
 if not any(x.get('map')==MAP for x in d['pearls']):d['pearls'].insert(next(i for i,x in enumerate(d['pearls']) if x.get('map')=='Random_Definition')+1,{'pearl':'random entropies','map':MAP,'hero':IDS[0],'lines':[{'token':id,'text':name,'by':'ordinary-entropies-2026-10-16'} for id,name in zip(IDS,NAMES)]})
 write(p,d)
 p=ROOT/'commons/data/museum/em_plan.json';backup(p);d=read(p)
 existing=next(r for r in d['plans'] if r.get('map')=='Random_Definition' and r.get('sequence')=='randomness')
 authored=read(ROOT/'commons/data/map_authored.json')['randomness']
 row=derive_row('random entropies',MAP,existing['museum'],authored.index(MAP),len(authored),'randomness')
 d['plans']=[r for r in d['plans'] if not (r.get('map')==MAP and r.get('sequence')=='randomness')]
 d['plans'].insert(d['plans'].index(existing)+1,row)
 for r in d['plans']:
  if r.get('sequence')=='randomness' and r.get('map') in authored:r['pearl_index']=authored.index(r['map']);r['pearls_total']=len(authored)
 # Preserve all other halls and cached layouts; only the new derived row is inserted.
 p.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
 print('Installed',MAP,'after Random_Definition:',len(IDS),'separate artifacts.')
if __name__=='__main__':main()

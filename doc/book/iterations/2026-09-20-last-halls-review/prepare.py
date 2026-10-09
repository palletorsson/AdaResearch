from pathlib import Path
import json,shutil

H=Path(__file__).resolve().parent;R=H.parents[3];B=H/'before'
rooms=['AdvancedLaboratory_Lab_Equipment_Simulation','PostCrisis_Synthesis']
seq=json.loads((R/'commons/maps/sequences/postfoundationscrisis.json').read_text(encoding='utf-8'))['sequences']['postfoundationscrisis']['maps']
rels=['commons/maps/sequences/postfoundationscrisis.json','commons/data/artifact_roles.json','commons/data/map_authored.json','commons/data/museum_core_encounters.json','commons/data/book/postfoundationscrisis.json','commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json','commons/data/museum/em_plan.json','ada_run/em_plan.json','commons/artifacts/registry/postfoundations_crisis.json','doc/book/iterations/2026-09-19-review-comparison/postfoundationscrisis.json']
rels += ['algorithms/computationalbiology/molecular_framework/'+n for n in ['MolecularDesigner.gd','MolecularDesigner.tscn','Part.gd','Part.tscn','assemblies.json']]
rels += ['commons/artifacts/accountability_ledger/'+n for n in ['accountability_ledger.gd','accountability_ledger.tscn']]
for room in seq:
 rels += ['commons/maps/'+room+'/'+n for n in (['map_data.json','final.md','technical.md','critical.md','tutorial.md','blurb.md','summary.md'] if room in rooms else ['map_data.json','final.md'])]
for rel in rels:
 src=R/rel;dst=B/rel
 if src.exists() and not dst.exists():dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
(B/'.gdignore').write_text('',encoding='utf-8')

# Give the existing assembly room enough floor to move around the forms.
p=R/'commons/maps'/rooms[0]/'map_data.json';m=json.loads(p.read_text(encoding='utf-8'))
layers={k:[[' ']*12 for _ in range(12)] for k in m['layers']}
for z in range(12):
 for x in range(12):layers['structure'][z][x]='w' if x in [0,11] or z in [0,11] else '1'
for z in [0,11]:
 for x in [5,6,7]:layers['structure'][z][x]='1'
layers['utilities'][1][6]='s';layers['utilities'][1][3]='an';layers['utilities'][10][6]='t';layers['utilities'][10][7]='sp'
layers['utilities'][3][2]='3t:FOLLOW ONE PART';layers['utilities'][8][9]='3t:SAME INSTANCE / ANOTHER ROLE'
layers['interactables'][5][6]='MolecularDesigner:0:0:2#body_study:true#float_duration:8#assemble_duration:18'
m['layers']=layers
m['map_info'].update(description='An open assembly floor. Walk around the same changing parts as they become an authored body, chair and other structures. The amber witness follows one reusable instance.',title='The Inventory Before the Body',dimensions={'width':12,'depth':12,'max_height':4},museum={'artifact_placement':'map','gate_depth_rows':0,'wall_height':4,'sculpture_clear_rects':[[2,2,10,10]]})
m['map_info']['metadata']['design_notes']='Replaces the cramped irregular bench footprint with circulation around a two-times-scale automatic assembly. Parts are visual: no chair support or solid body is claimed.'
p.write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

# The ledger remains a reading object. Slower examples and readable mounting earn
# their place here without adding another control panel.
p=R/'commons/maps'/rooms[1]/'map_data.json';m=json.loads(p.read_text(encoding='utf-8'))
m['layers']['interactables'][2][2]='accountability_ledger:180:0.65:1.8#log_interval:6'
m['layers']['utilities'][1][7]='s'
m['layers']['structure'][14][7]='1'
m['map_info']['museum'].update(artifact_placement='map',sculpture_clear_rects=[[1,1,4,5],[5,10,9,14]])
m['map_info']['metadata']['status']='reviewed_draft'
m['map_info']['metadata']['design_notes']='Six existing artifact families retained. Read one concrete example at the ledger, then leave with a proposed return. The ledger is mounted for reading and its examples arrive every six seconds. The return cell is floor.'
p.write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Frozen',len(rels),'inputs; staged both rooms.')

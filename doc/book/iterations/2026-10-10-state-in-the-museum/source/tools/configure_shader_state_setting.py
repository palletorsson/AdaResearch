"""Give retained state a quiet room, keeping the earlier unbound comparison."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
data=json.loads((ROOT/'doc/book/iterations/2026-10-10-state-in-the-museum/before/map_data.json').read_text(encoding='utf-8-sig'))
w,d=25,29
data['map_info']['dimensions']=dict(width=w,depth=d,max_height=8)
data['map_info']['museum'].update(gate=False,gate_depth_rows=0,plinths=False,open_roof=True,sculpture_clear_rects=[[0,0,w-1,d-1]])
data['map_info']['metadata']['setting_revision']='2026-10-10: a retained 96x96 field beside the original unbound shader and animated frost; input, update and display separated.'
structure=[['6' if x in (0,w-1) or z in (0,d-1) else '1' for x in range(w)] for z in range(d)]
for x in [11,12,13]:structure[0][x]='1';structure[-1][x]='1'
layers={name:[[' ']*w for _ in range(d)] for name in ['utilities','interactables']}
layers['structure']=structure
layers['utilities'][1][12]='s';layers['utilities'][27][12]='t'
layers['interactables'][12][12]='shader_state_chamber:180:0#plinth:0#pin:1'
layers['interactables'][23][8]='shader_10_reactiondiffusion:180:0#plinth:0#pin:1#setting:wall'
layers['interactables'][22][18]='dark_sphere:0:0#pin:1'
data['layers']=layers
data['utility_definitions']['t'].update(name='Continue beyond Shaders',description='The museum continues beyond this sequence. The stored-state question carries toward cellular automata.')
data['utility_definitions']['s']['properties']['height']=0
(ROOT/'commons/maps/Shader_10_ReactionDiffusion/map_data.json').write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('Reaction–Diffusion: 25×29 m, original two artifacts retained and relocated.')

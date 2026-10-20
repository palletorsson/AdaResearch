"""Add a composition bay, preserving old artifact cells and the plural-body room."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
before=ROOT/'doc/book/iterations/2026-10-10-pink-in-the-museum/before/map_data.json'
data=json.loads(before.read_text(encoding='utf-8-sig'))
w,d=39,37
data['map_info']['dimensions'].update(width=w)
data['map_info']['museum'].update(gate=False,gate_depth_rows=0)
data['map_info']['museum']['sculpture_clear_rects'].append([15,0,38,17])
for name,rows in data['layers'].items():
    for row in rows: row.extend(['']*(w-len(row)))
for z in range(18):
    for x in range(16,w):
        if z>=16 and x<21:continue  # Keep the authored plural-body room exactly.
        data['layers']['structure'][z][x]='5' if z in (0,17) or x==38 else '1'
for z in range(1,10):data['layers']['structure'][z][15]='1'
data['layers']['utilities'][0][0]=' '
data['layers']['utilities'][1][7]='s'
for x in (6,7,8):data['layers']['structure'][0][x]='1'
data['layers']['interactables'][8][27]='shader_composition_stage:180:0#pin:1#plinth:0'
data['utility_definitions']['t'].update(name='Next: Reaction–Diffusion',description='Continue to the distinction between animated appearance and retained state.')
data['map_info']['metadata']['setting_revision']='2026-10-10: independent material recipe and surround controls in a new composition bay; prior artifacts and plural-body room retained.'
(ROOT/'commons/maps/Shader_12_PinkExtravaganza/map_data.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Pink: 39×37 m; original three placements retained; new bay at (27,8).')

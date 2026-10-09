from pathlib import Path
import re, hashlib, json
root=Path.cwd()
out=root/'doc/book/iterations/2026-09-21-colour-return/nails'
proj=out/'probe_project'
proj.mkdir(exist_ok=True)
def write(path,text):
    p=proj/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf-8')
sources=['commons/maps/Color_Nails/map_data.json','commons/maps/Color_Nails/final.md','commons/interfaces/nail_color_controller.gd','commons/interfaces/nail_color_controller.tscn','commons/interfaces/hand_color_controller.tscn','commons/body/hands/left_hand.tscn','commons/body/hands/right_hand.tscn','commons/body/hands/left_hand_nails.gd','commons/body/hands/right_hand_nails.gd','commons/managers/GameManager.gd','commons/scenes/base.tscn','commons/scenes/endless_museum_staged.tscn','commons/scenes/endless_museum.gd','commons/scenes/em/em_staged_museum.gd','commons/artifacts/nail_salon/nail_salon.gd','commons/scenes/main_menu/MainMenu3D.gd','addons/godot-xr-tools/staging/scene_base.tscn','addons/godot-xr-tools/hands/hand.gd','project.godot']
(out/'source_hashes.json').write_text(json.dumps({p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in sources},indent=2)+'\n',encoding='utf-8')
for side in ('left','right'):
    src=f'commons/body/hands/{side}_hand_nails.gd'
    write(src,(root/src).read_text(encoding='utf-8-sig'))
    src=f'commons/body/hands/{side}_hand.tscn'
    s=(root/src).read_text(encoding='utf-8-sig')
    s=re.sub(r'^\[ext_resource[^\n]*(?:hands/hand.gd|AnimationPlayer.tscn)[^\n]*\]\n','',s,flags=re.M)
    s=re.sub(r'\[node name="Animation(?:Tree|Player)"[^\n]*\]\n.*?(?=\[node |\Z)','',s,flags=re.S)
    s=re.sub(r'(\[node name="(?:Left|Right)Hand"[^\n]*\]\n)script = [^\n]*\n',r'\1',s)
    s=re.sub(r' uid="[^"]*"','',s)
    write(src,s)
write('commons/interfaces/nail_color_controller.gd',(root/'commons/interfaces/nail_color_controller.gd').read_text(encoding='utf-8-sig'))
gm=(root/'commons/managers/GameManager.gd').read_text(encoding='utf-8-sig').splitlines()
write('game_manager_colour_slice.gd','extends Node\n'+'\n'.join(gm[76:78]+gm[91:93]+gm[902:919])+'\n')
write('project.godot','''config_version=5
[application]
config/name="Isolated nail receiver verification"
config/use_custom_user_dir=true
config/custom_user_dir="AdaResearchColourNailsIsolatedProbe20260921"
[autoload]
GameManager="*res://game_manager_colour_slice.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
''')
print(proj)

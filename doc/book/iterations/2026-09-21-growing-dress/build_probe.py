from pathlib import Path
import re,json,shutil,hashlib
r=Path.cwd();out=r/'doc/book/iterations/2026-09-21-growing-dress';p=out/'probe_project';p.mkdir(exist_ok=True)
files=['commons/player/costume_wardrobe.gd','commons/player/queer_costume.gd','commons/player/super_drag_outfit.gd','commons/player/costume_trophies.gd','commons/body/tartan.gd','commons/artifacts/dream_bodies/dream_skin.gd','commons/artifacts/dream_bodies/dream_shaders.gd','commons/artifacts/dream_bodies/dream_gloss.gdshader','commons/artifacts/fabric_shader_studio/fabric_recipe.gd','commons/artifacts/fabric_shader_studio/fabric.gdshader','commons/maps/curriculum_spine.json']
for f in files:
 target=p/f;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(r/f,target)
source=(r/'commons/scenes/endless_museum.gd').read_text(encoding='utf-8')
def body(name):
 m=re.search(r'(?m)^func '+re.escape(name)+r'\([^\n]*\n(?:[ \t]+[^\n]*\n|\n)*',source);assert m
 return m[0].rstrip()+'\n'
harness='''extends Node3D
var _costume_on := true
var _studio := false
var _bake_mode := false
var _vr := false
var _dollhouse := false
var _wardrobe: Node
var _costume_hall := ""
var _player: Node3D
var _cam: Camera3D
var _vr_cam: Camera3D
var _vr_eye_name := ""
var _segments: Array = []
var _next_z := 0.0
const EYE := 1.65
const BUILD_AHEAD_M := 20.0
'''
for name in ['_costume_walk','_vr_eye','_collect_of_type','_eye_pos','_node_or_null']:
 harness+='\n'+body(name)
(p/'museum_costume_slice.gd').write_text(harness,encoding='utf-8')
(p/'project.godot').write_text('''config_version=5
[application]
config/name="Isolated growing dress"
config/use_custom_user_dir=true
config/custom_user_dir="AdaResearchGrowingDressProbe20260921"
[display]
window/size/viewport_width=1100
window/size/viewport_height=1000
[rendering]
renderer/rendering_method="gl_compatibility"
textures/default_filters/use_nearest_mipmap_filter=false
''',encoding='utf-8')
(out/'source-hashes.json').write_text(json.dumps({f:hashlib.sha256((r/f).read_bytes()).hexdigest() for f in files+['commons/scenes/endless_museum.gd']},indent=2)+'\n',encoding='utf-8')
print(p)

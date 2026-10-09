from pathlib import Path
import json
r=Path.cwd();o=Path(__file__).parent
def edit(rel,fn):
 p=r/rel;before=o/'before'/rel
 expected=fn(before.read_text(encoding='utf-8-sig'))
 if p.read_text(encoding='utf-8-sig')==expected:return
 assert p.read_bytes()==before.read_bytes(),f'Concurrent edit: {rel}'
 p.write_text(expected,encoding='utf-8')
def replace(s,a,b):
 assert s.count(a)==1,repr(a)
 return s.replace(a,b)
def field(s):
 s=replace(s,'var _container: Node3D','var _container: Node3D\nvar _cube_scale: float = 1.0')
 s=replace(s,'\t\t\tcube.position = Vector3(pos_x, 0, pos_z)','\t\t\tcube.position = Vector3(pos_x, 0, pos_z)\n\t\t\tcube.scale = Vector3.ONE * _cube_scale')
 s=replace(s,'func apply_grid_config(config: Dictionary) -> void:\n\tpass','''func apply_grid_config(config: Dictionary) -> void:
	# The museum's short comparison contains the whole half-wave. Other placements
	# retain their authored grid, size and animation settings.
	if str(config.get("study", "")) != "compact" or has_meta("compact_study"):
		return
	set_meta("compact_study", true)
	grid_size = Vector2i(5, 5)
	spacing = 0.75
	_cube_scale = 0.6
	gradient_start_offset = 0.0
	gradient_length = 3.0
	max_slope_angle = 30.0
	animate_slope = false
	if _container != null:
		_generate_grid()
		_update_cubes(max_slope_angle)''')
 return s
edit('algorithms/randomness/SlopeGradientCubes.gd',field)
def mapfield(s):
 d=json.loads(s);g=d['layers']['interactables']
 assert g[11][3]=='RotateGridCubes:0:-0.5' and g[11][6] in [' ','']
 g[11][3]=' ';g[11][6]='RotateGridCubes:0:-0.08#study:compact'
 # Preserve formatting outside the two cells.
 rows=s.splitlines(True);start=next(i for i,v in enumerate(rows) if '"RotateGridCubes:0:-0.5"' in v)
 assert rows[start+3].strip().rstrip(',') in ['" "','""']
 rows[start]=rows[start].replace('RotateGridCubes:0:-0.5',' ')
 rows[start+3]=rows[start+3].replace('" "','"RotateGridCubes:0:-0.08#study:compact"')
 out=''.join(rows);assert json.loads(out)==d
 return out
edit('commons/maps/Random_Rotate_Random_XYZ/map_data.json',mapfield)
def sampler(s):
 s=replace(s,'@export var batch_size: int = 100','@export var batch_size: int = 100\n\n# Optional side-mounted record for a cabinet with a separate front console.\nvar _readout_wing: bool = false')
 s=replace(s,'func apply_grid_config(config_data: Dictionary) -> void:', '''func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("readout"):
		_readout_wing = str(config_data["readout"]) == "wing"
		_position_readout()''')
 s=replace(s,'\t\t\t_build_cabinet()\n\t\t_update_readout()', '\t\t\t_build_cabinet()\n\t\t_position_readout()\n\t\t_update_readout()')
 s=replace(s,'func _apply_stand() -> void:', '''func _position_readout() -> void:
	if _readout == null or _stand_root == null:
		return
	var plate: Node3D = _readout.get_parent()
	plate.position = Vector3(-0.86, 1.43, CAB_FACE + 0.012) if _readout_wing else Vector3(0, CAB_H - 0.118, CAB_FACE + 0.012)
	plate.scale = Vector3.ONE * (1.35 if _readout_wing else 1.0)
	var stem := _stand_root.get_node_or_null("ReadoutStem") as MeshInstance3D
	if _readout_wing and stem == null:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.13, 0.15, 0.18)
		material.metallic = 0.5
		stem = HangarKit.box(Vector3(-0.70, 1.18, 0.14), Vector3(0.025, 0.46, 0.045), material)
		stem.name = "ReadoutStem"
		_stand_root.add_child(stem)
	if stem != null:
		stem.visible = _readout_wing


func _apply_stand() -> void:''')
 return s
edit('commons/artifacts/distribution_sampler/distribution_sampler.gd',sampler)
edit('commons/maps/Random_Gaussian/map_data.json',lambda s:replace(s,'distribution_sampler:180#stand:cabinet#controls:compact#control_front:1.05','distribution_sampler:180#stand:cabinet#controls:compact#control_front:1.05#readout:wing'))
def cubes(s):
 for sentence in [" On a desktop the object is dropped rather than thrown, and the direction of your view sets its held orientation."," On a desktop, these are drops: the hand's throw is unavailable."]:
  s=replace(s,sentence,'')
 return s
edit('commons/maps/Random_Cubes/final.md',cubes)
def rotation(s):
 a='Behind the display, a low field of cubes begins to tilt, each row by how far along the field it stands. Inside this hall you see only the first few degrees; the steeper rows lie beyond the back wall. Nothing there turns, and nothing there was drawn. The same tilt comes back every time the hall is built. Rotation can be a rule about place as easily as a record of chance.'
 b='Behind the stacks, twenty-five cubes make a low square field. The first row lies level; the middle pitches upward; the last lies level again. Nothing keeps turning as you watch. The angle follows a row’s place along half a sine curve. Walk along its side. The same arrangement returns whenever the hall is built. Here your walk supplies the sequence: level, inclined, level again. Rotation can be a rule about place as easily as a record of chance.'
 return replace(s,a,b)
edit('commons/maps/Random_Rotate_Random_XYZ/final.md',rotation)
def walk(s):
 s=replace(s,'built. Between this cabinet and the basin, a sculpture','built.\n\n<!-- @pixel_cloud -->\n\nOn your right, between this cabinet and the basin, a sculpture')
 s=replace(s,'The wing beside the tank carries','<!-- @random_walk_terrarium -->\n\nThe wing beside the tank carries')
 s=replace(s,'## A hand with company\n\n','')
 s=replace(s,'This is the grip from Trace with one addition.','This is the drawing dot from the Point Trace room, with one addition.')
 s=replace(s,'as it did in Trace.','as it did there.')
 return s
edit('commons/maps/Random_Walk/final.md',walk)
edit('commons/maps/Random_Gaussian/final.md',lambda s:replace(s,'The plate counts them as “in flight” until they land;','The plate beside the histogram counts them as “in flight” until they land;'))
print('Scoped artifact, placement and manuscript changes applied.')

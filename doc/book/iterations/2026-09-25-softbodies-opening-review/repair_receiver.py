from pathlib import Path
import hashlib,json,shutil
r=Path.cwd();o=Path(__file__).resolve().parent
base=json.loads((o/'baseline.json').read_text());changed=json.loads((o/'changed-files.json').read_text())
p=r/'commons/artifacts/jelly_cube/jelly_cube.gd';raw=p.read_bytes();assert hashlib.sha256(raw).hexdigest()==base[p.relative_to(r).as_posix()]
s=raw.decode().replace('\r\n','\n')
s=s.replace('@export var use_transparency: bool = true','''@export var use_transparency: bool = true

## A receiving tray for the opening hall; legacy placements keep their pedestal.
@export_enum("pedestal", "tray") var support: String = "pedestal"''')
s=s.replace('func _read_dna_meta() -> void:\n','''func _read_dna_meta() -> void:
	if str(get_meta("config_support", "")) == "tray":
		support = "tray"
''')
s=s.replace('func _create_pedestal() -> void:\n','''func _create_pedestal() -> void:
	if support == "tray":
		_create_receiving_tray()
		return
''')
marker='func _create_labels() -> void:'
addition='''## A wider floor and finite rim catch a settling body without pinning its mesh.
## Geometry and collision use the same box dimensions. No solver state is reset.
func _create_receiving_tray() -> void:
	var tray := StaticBody3D.new()
	tray.name = "Pedestal"
	tray.collision_layer = 1
	tray.collision_mask = 0
	add_child(tray)
	_track_node(tray)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.23, 0.26)
	mat.metallic = 0.45
	mat.roughness = 0.4
	var h: float = cube_size * 2.0
	var span: float = h * 2.0 + 0.12
	_tray_box(tray, Vector3(0, -0.03, 0), Vector3(span, 0.06, span), mat)
	for sign_value in [-1.0, 1.0]:
		_tray_box(tray, Vector3(sign_value * (h + 0.03), 0.06, 0), Vector3(0.06, 0.12, span), mat)
		_tray_box(tray, Vector3(0, 0.06, sign_value * (h + 0.03)), Vector3(h * 2.0, 0.12, 0.06), mat)
	# The hall places the tray surface at one metre; legs make that support visible.
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			_tray_box(tray, Vector3(x * h * 0.8, -0.53, z * h * 0.8), Vector3(0.05, 0.94, 0.05), mat)

func _tray_box(parent: StaticBody3D, center: Vector3, size: Vector3, material: Material) -> void:
	var visual := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	visual.mesh = box
	visual.material_override = material
	visual.position = center
	parent.add_child(visual)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = center
	parent.add_child(collision)

'''
assert s.count(marker)==1;s=s.replace(marker,addition+marker)
s=s.replace('_control_panel.position = Vector3(0, 0.04, cube_size * 0.7 + 0.15)','''_control_panel.position = Vector3(0, 0.04, cube_size * 0.7 + 0.15)
	if support == "tray":
		_control_panel.position.z = cube_size * 2.0 + 0.24''')
s=s.replace('func apply_grid_config(config_data: Dictionary) -> void:\n','''func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("support"):
		var next_support: String = str(config_data["support"]).strip_edges().to_lower()
		if next_support in ["pedestal", "tray"] and next_support != support:
			support = next_support
			if is_node_ready():
				for node_name in ["Pedestal", "PedestalCollision"]:
					var old_support := get_node_or_null(NodePath(node_name))
					if old_support != null:
						remove_child(old_support)
						old_support.queue_free()
				_create_pedestal()
				_control_panel.position.z = cube_size * 2.0 + 0.24 if support == "tray" else cube_size * 0.7 + 0.15
''')
if b'\r\n' in raw:s=s.replace('\n','\r\n')
p.write_bytes(s.encode());changed.append(p.relative_to(r).as_posix())
p=r/'commons/maps/SoftBodies_Soft_Body_Deformation/map_data.json';raw=p.read_bytes();assert hashlib.sha256(raw).hexdigest()==base[p.relative_to(r).as_posix()]
assert raw.count(b'"jelly_cube:180:1.0"')==1
p.write_bytes(raw.replace(b'"jelly_cube:180:1.0"',b'"jelly_cube:180:1.0#support:tray"'));changed.append(p.relative_to(r).as_posix())
shutil.copytree(o/'cube-native',o/'cube-before-tray',dirs_exist_ok=True)
p=o/'cube_probe.gd';s=p.read_text()
s=s.replace('cube.to_global(Vector3(0.65,0.60,0.8)),cube.to_global(Vector3(0,0.17,0)),48','cube.to_global(Vector3(1.1,0.8,1.7)),cube.to_global(Vector3(0,0.10,0)),48')
s=s.replace('func landing_checks() -> void:', '''func retained(sb:SoftBody3D) -> bool:
	for i in sb.mesh.surface_get_array_len(0):
		var p:=cube.to_local(PhysicsServer3D.soft_body_get_point_global_position(sb.get_physics_rid(),i))
		if absf(p.x)>0.68 or absf(p.z)>0.68 or p.y < -0.035:return false
	return true
func landing_checks() -> void:''')
s=s.replace('observations["initial_extent"]=extent(sb)','''check("this hall opts into a tray with nine matching collision pieces",cube.support=="tray" and cube.get_node("Pedestal").find_children("*","CollisionShape3D",true,false).size()==9)
	observations["initial_extent"]=extent(sb)''')
s=s.replace('await shot("cube-pressure-zero")','''check("cube retained on tray after zero pressure",retained(sb))
	await shot("cube-pressure-zero")''').replace('await shot("cube-pressure-two")','''check("cube retained on tray after pressure two",retained(sb))
	await shot("cube-pressure-two")''')
s += '''
func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"observations":observations,"failures":failures,"passed":failures.is_empty(),"scope":"Native museum with completed stamp queue; supplied pointer events, solver vertex bounds and original captures. No tracked hand, force feedback or headset acceptance."},"  "))
	quit(0 if failures.is_empty() else 1)
'''
p.write_bytes(s.encode())
(o/'changed-files.json').write_bytes((json.dumps(changed,indent=2)+'\n').encode())
print('Added map-specific receiving tray; preserved legacy pedestal and solver')

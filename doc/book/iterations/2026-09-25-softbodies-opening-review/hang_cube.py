from pathlib import Path
import shutil
r=Path.cwd();o=Path(__file__).resolve().parent
shutil.copytree(o/'cube-native',o/'underside-anchor-diagnostic',dirs_exist_ok=True)
p=r/'commons/artifacts/jelly_cube/jelly_cube.gd';raw=p.read_bytes();s=raw.decode().replace('\r\n','\n')
s=s.replace('"underside"','"crown"').replace('UndersideAnchor','CrownAnchor').replace('One underside point held','One upper point held')
s=s.replace('## Optional visible attachment for the opening hall; ordinary placements stay free.','## Placement-only attachment for the opening hall; ordinary placements stay free.')
s=s.replace('## Choose a single point on the underside, nearest its centre. Pinning constrains','## Choose a single point on the top face, nearest its centre. Pinning constrains')
s=s.replace('absf(v.y + cube_size * 0.5)','absf(v.y - cube_size * 0.5)')
s=s.replace('Vector3(points[_anchor_index].x, 0.025, points[_anchor_index].z)','Vector3(points[_anchor_index].x, cube_size + 0.075, points[_anchor_index].z)')
start=s.index('\tif config_data.has("anchor"):',s.index('func apply_grid_config'))
end=s.index('\t#',start)
s=s[:start]+s[end:]
s=s.replace('func _create_pedestal() -> void:\n','''func _create_pedestal() -> void:
	if anchor == "crown":
		_create_hanging_support()
		return
''')
support='''## Expose the held point with an open stand. No plate passes through the body.
func _create_hanging_support() -> void:
	var stand := Node3D.new()
	stand.name = "HangingSupport"
	add_child(stand)
	_track_node(stand)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13, 0.16, 0.18)
	mat.metallic = 0.4
	mat.roughness = 0.4
	var top: float = cube_size + 0.12
	_stand_piece(stand, Vector3(0, -0.97, -0.4), Vector3(0.40, 0.06, 0.36), mat)
	_stand_piece(stand, Vector3(0, (top - 1.0) * 0.5, -0.4), Vector3(0.045, top + 1.0, 0.045), mat)
	_stand_piece(stand, Vector3(0, top, -0.18), Vector3(0.09, 0.04, 0.48), mat)

func _stand_piece(parent: Node3D, center: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.position = center
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)

'''
s=s.replace('## Choose a single point',support+'## Choose a single point')
s=s.replace('_control_panel.position = Vector3(0, 0.04, cube_size * 0.7 + 0.15)','''_control_panel.position = Vector3(0, 0.04, cube_size * 0.7 + 0.15)
	if anchor == "crown":
		_control_panel.position = Vector3(0, -0.35, cube_size + 0.35)''')
if b'\r\n' in raw:s=s.replace('\n','\r\n')
p.write_bytes(s.encode())
p=r/'commons/maps/SoftBodies_Soft_Body_Deformation/map_data.json';raw=p.read_bytes();assert raw.count(b'#anchor:underside')==1;p.write_bytes(raw.replace(b'#anchor:underside',b'#anchor:crown'))
p=o/'cube_probe.gd';s=p.read_text().replace('"underside"','"crown"').replace('UndersideAnchor','CrownAnchor').replace('one underside point','one upper point')
start=s.index('func retained(');end=s.index('func landing_checks()',start)
s=s[:start]+'''func retained(sb:SoftBody3D) -> bool:
	var fixed:=PhysicsServer3D.soft_body_get_point_global_position(sb.get_physics_rid(),cube._anchor_index)
	for i in sb.mesh.surface_get_array_len(0):
		var p:=PhysicsServer3D.soft_body_get_point_global_position(sb.get_physics_rid(),i)
		if p.distance_to(fixed)>0.65:return false
	return true
'''+s[end:]
s=s.replace('cube stays at its support after zero pressure','free surface stays within reach of held point at zero pressure').replace('cube stays at its support after pressure two','free surface stays within reach of held point at pressure two')
s=s.replace('await shot("cube-pressure-two")','''await shot("cube-pressure-two")
	await create_timer(10).timeout
	check("body remains near held point after ten more seconds",retained(sb))
	var default_cube:Node3D=load("res://commons/artifacts/jelly_cube/jelly_cube.tscn").instantiate()
	default_cube.position=Vector3(40,2,40)
	root.add_child(default_cube)
	check("unconfigured cube retains free body and original pedestal",default_cube.anchor=="free" and default_cube._anchor_index==-1 and default_cube.get_node_or_null("PedestalCollision")!=null and default_cube.get_node_or_null("HangingSupport")==null)
	default_cube.queue_free()''')
p.write_bytes(s.encode())

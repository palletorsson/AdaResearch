from pathlib import Path
import shutil,json
r=Path.cwd();o=Path(__file__).resolve().parent
shutil.copytree(o/'cube-native',o/'tray-deep-diagnostic',dirs_exist_ok=True)
p=r/'commons/artifacts/jelly_cube/jelly_cube.gd'
shutil.copy2(p,o/'tray-experiment.gd')
raw=(o/'before/commons/artifacts/jelly_cube/jelly_cube.gd').read_bytes()
s=raw.decode().replace('\r\n','\n')
s=s.replace('@export var use_transparency: bool = true','''@export var use_transparency: bool = true

## Optional visible attachment for the opening hall; ordinary placements stay free.
@export_enum("free", "underside") var anchor: String = "free"
var _anchor_index: int = -1
var _anchor_marker: MeshInstance3D''')
s=s.replace('\t_create_pedestal()\n\t_create_labels()', '\t_create_pedestal()\n\t_configure_anchor()\n\t_create_labels()')
s=s.replace('func _read_dna_meta() -> void:\n','''func _read_dna_meta() -> void:
	if str(get_meta("config_anchor", "")) == "underside":
		anchor = "underside"
''')
addition='''## Choose a single point on the underside, nearest its centre. Pinning constrains
## that mesh point; it does not restore coefficients or replace the simulated body.
func _configure_anchor() -> void:
	if _anchor_index >= 0:
		_soft_body.set_point_pinned(_anchor_index, false)
		_anchor_index = -1
	if is_instance_valid(_anchor_marker):
		remove_child(_anchor_marker)
		_anchor_marker.queue_free()
		_anchor_marker = null
	if anchor != "underside":
		return
	# Use the same undeformed BoxMesh as the body: a deformed mesh is not an index map.
	var rest := BoxMesh.new()
	rest.size = Vector3.ONE * cube_size
	rest.subdivide_width = subdivisions
	rest.subdivide_height = subdivisions
	rest.subdivide_depth = subdivisions
	var points: PackedVector3Array = rest.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var best := INF
	for i in points.size():
		var v: Vector3 = points[i]
		if absf(v.y + cube_size * 0.5) > 0.001:
			continue
		var distance: float = Vector2(v.x, v.z).length_squared()
		if distance < best:
			best = distance
			_anchor_index = i
	if _anchor_index < 0:
		return
	_soft_body.set_point_pinned(_anchor_index, true)
	# A small brass stem exposes the attachment instead of pretending it is contact.
	var stem := CylinderMesh.new()
	stem.top_radius = 0.008
	stem.bottom_radius = 0.012
	stem.height = 0.05
	_anchor_marker = MeshInstance3D.new()
	_anchor_marker.name = "UndersideAnchor"
	_anchor_marker.mesh = stem
	_anchor_marker.position = Vector3(points[_anchor_index].x, 0.025, points[_anchor_index].z)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.55, 0.15)
	material.metallic = 0.5
	material.roughness = 0.35
	_anchor_marker.material_override = material
	add_child(_anchor_marker)
	_track_node(_anchor_marker)

'''
s=s.replace('func _create_labels() -> void:',addition+'func _create_labels() -> void:')
s=s.replace('_info_label.text = "JELLY CUBE\\nTouch to deform"','_info_label.text = "JELLY CUBE\\nOne underside point held" if anchor == "underside" else "JELLY CUBE\\nTouch to deform"')
s=s.replace('func apply_grid_config(config_data: Dictionary) -> void:\n','''func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("anchor"):
		var next_anchor: String = str(config_data["anchor"]).strip_edges().to_lower()
		if next_anchor in ["free", "underside"] and next_anchor != anchor:
			anchor = next_anchor
			if is_node_ready():
				_configure_anchor()
				_info_label.text = "JELLY CUBE\\nOne underside point held" if anchor == "underside" else "JELLY CUBE\\nTouch to deform"
''')
if b'\r\n' in raw:s=s.replace('\n','\r\n')
p.write_bytes(s.encode())
p=r/'commons/maps/SoftBodies_Soft_Body_Deformation/map_data.json';raw=p.read_bytes();assert raw.count(b'#support:tray')==1;p.write_bytes(raw.replace(b'#support:tray',b'#anchor:underside'))
p=o/'cube_probe.gd';s=p.read_text()
s=s.replace('Vector3(1.1,1.25,1.7)','Vector3(0.85,0.7,1.1)')
start=s.index('\tcheck("this hall opts into a tray');end=s.index('\tawait shot("cube-pressure-one")',start)
s=s[:start]+'''	check("hall holds one underside point with a visible attachment",cube.anchor=="underside" and cube._anchor_index>=0 and sb.is_point_pinned(cube._anchor_index) and cube.get_node_or_null("UndersideAnchor")!=null)
	var held_before:=PhysicsServer3D.soft_body_get_point_global_position(sb.get_physics_rid(),cube._anchor_index)
	observations["initial_extent"]=extent(sb)
'''+s[end:]
s=s.replace('cube retained on tray after zero pressure','cube stays at its support after zero pressure').replace('cube retained on tray after pressure two','cube stays at its support after pressure two')
s=s.replace('await snapshot("deformation-hall"','''check("held point stays fixed through the setting changes",held_before.distance_to(PhysicsServer3D.soft_body_get_point_global_position(sb.get_physics_rid(),cube._anchor_index))<0.001)
	await snapshot("deformation-hall"''')
s=s.replace('func finish() -> void:', '''func finish() -> void:''')
p.write_bytes(s.encode())
print('Replaced the failed receiver trial with an explicitly anchored cube; old free default retained')

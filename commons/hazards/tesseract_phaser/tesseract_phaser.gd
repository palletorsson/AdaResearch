# @identity
# essence: project_4D(vertices, angle_xw, angle_yw) -> 3D -- wireframe tesseract rotating through 4th dimension
# desire: a hypercube whose vertices phase in/out of hittability based on W-depth coordinate
# critical_parameter: _angle_xw / _angle_yw -- 4D rotation angles determine which vertices reach 3D space
# triggers: continuous 4D rotation; vertices phase by W-depth; only vertices near W=0 can be hit
# emerges: the fourth dimension as combat mechanic -- the creature is partly elsewhere, and elsewhere rotates
# needs: HazardCreatureBase [has]; 4D vertex/edge system [has]; projection [has]; W-depth hitbox [has]; VR interaction [missing]
# relationships: embodies higher_dimensions sequence; the only creature partly outside 3D space
# truth: the tesseract rotates through dimensions you cannot see -- vertices phase in and out by W-depth.

extends HazardCreatureBase
class_name TesseractPhaser
## Higher Dimensions hazard — a wireframe tesseract (4D hypercube) projected
## into 3D. 4D rotation causes parts to phase in and out. Only hittable
## when a face is fully projected. Teaches dimensional projection.

@export_group("Tesseract")
@export var edge_length: float = 0.3
@export var rotation_speed_4d: float = 0.5
@export var vertex_radius: float = 0.03
@export var edge_thickness: float = 0.01

@export_group("Appearance")
@export var inner_color: Color = Color(0.3, 0.5, 1.0, 0.7)
@export var outer_color: Color = Color(1.0, 0.7, 0.2, 0.9)
@export var edge_color_val: Color = Color(0.5, 0.6, 0.8, 0.6)
@export var emission_val: Color = Color(0.3, 0.4, 1.0)

# 4D geometry
var _vertices_4d: Array[Array] = []  # 16 vertices as [x,y,z,w]
var _edges: Array[Vector2i] = []  # 32 edges as index pairs
var _angle_xw: float = 0.0  # 4D rotation angles
var _angle_yw: float = 0.0
var _projected: Array[Vector3] = []

# Visual
var _vertex_meshes: Array[MeshInstance3D] = []
var _vertex_mats: Array[StandardMaterial3D] = []
var _edge_meshes: Array[MeshInstance3D] = []
var _label: Label3D = null
var _inner_mat: StandardMaterial3D
var _outer_mat: StandardMaterial3D
var _edge_mat: StandardMaterial3D


func _on_ready() -> void:
	add_to_group("dimension_enemy")


func _generate_tesseract() -> void:
	# 16 vertices of a tesseract: all combinations of ±1 in 4D
	_vertices_4d.clear()
	for i in range(16):
		var x: float = -1.0 if (i & 1) == 0 else 1.0
		var y: float = -1.0 if (i & 2) == 0 else 1.0
		var z: float = -1.0 if (i & 4) == 0 else 1.0
		var w: float = -1.0 if (i & 8) == 0 else 1.0
		_vertices_4d.append([x * edge_length, y * edge_length, z * edge_length, w * edge_length])

	# 32 edges: connect vertices that differ in exactly one coordinate
	_edges.clear()
	for i in range(16):
		for j in range(i + 1, 16):
			var diff: int = i ^ j  # XOR to find differing bits
			# Only one bit different = edge
			if diff == 1 or diff == 2 or diff == 4 or diff == 8:
				_edges.append(Vector2i(i, j))

	_projected.resize(16)


func _create_materials() -> void:
	_inner_mat = _make_material(inner_color, emission_val, inner_color.a)
	_outer_mat = _make_material(outer_color, Color(1.0, 0.6, 0.1), outer_color.a)
	_edge_mat = _make_material(edge_color_val, emission_val * 0.3, edge_color_val.a)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = edge_length * 2.0
	col.shape = shape
	col.position.y = edge_length * 2.0
	add_child(col)


func _build_mesh() -> void:
	_generate_tesseract()
	# Create vertex meshes
	var sphere := SphereMesh.new()
	sphere.radius = vertex_radius
	sphere.height = vertex_radius * 2.0

	for i in range(16):
		var is_inner: bool = _vertices_4d[i][3] < 0.0
		var mat: StandardMaterial3D = (_inner_mat if is_inner else _outer_mat).duplicate()
		var mi := MeshInstance3D.new()
		mi.mesh = sphere
		mi.set_surface_override_material(0, mat)
		_mesh_root.add_child(mi)
		_vertex_meshes.append(mi)
		_vertex_mats.append(mat)

	# Create edge meshes
	var cyl := CylinderMesh.new()
	cyl.top_radius = edge_thickness
	cyl.bottom_radius = edge_thickness
	cyl.height = 1.0  # Will be rescaled

	for _e in _edges:
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.set_surface_override_material(0, _edge_mat.duplicate())
		_mesh_root.add_child(mi)
		_edge_meshes.append(mi)

	# Label
	_label = Label3D.new()
	_label.text = "4D TESSERACT"
	_label.font_size = 22
	_label.pixel_size = 0.002
	_label.modulate = outer_color
	_label.position = Vector3(0.0, edge_length * 3.5, 0.05)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mesh_root.add_child(_label)


func _process_visual(delta: float) -> void:
	# 4D rotation
	var spd: float = rotation_speed_4d
	if _state == BaseState.CHASE:
		spd *= 2.5
	_angle_xw += delta * spd
	_angle_yw += delta * spd * 0.7

	# Project each vertex from 4D to 3D
	for i in range(16):
		var v: Array = _vertices_4d[i]
		var x: float = v[0]
		var y: float = v[1]
		var z: float = v[2]
		var w: float = v[3]

		# Rotate in XW plane
		var cos_xw: float = cos(_angle_xw)
		var sin_xw: float = sin(_angle_xw)
		var nx: float = x * cos_xw - w * sin_xw
		var nw: float = x * sin_xw + w * cos_xw
		x = nx
		w = nw

		# Rotate in YW plane
		var cos_yw: float = cos(_angle_yw)
		var sin_yw: float = sin(_angle_yw)
		var ny: float = y * cos_yw - w * sin_yw
		nw = y * sin_yw + w * cos_yw
		y = ny
		w = nw

		# Perspective projection from 4D to 3D
		var projection_dist: float = 1.5
		var scale_factor: float = projection_dist / (projection_dist - w)
		_projected[i] = Vector3(x * scale_factor, y * scale_factor + edge_length * 2.0, z * scale_factor)

		# Update vertex mesh position and alpha based on W depth
		if i < _vertex_meshes.size() and is_instance_valid(_vertex_meshes[i]):
			_vertex_meshes[i].position = _projected[i]
			# Alpha based on W proximity (closer to 0 = more visible)
			var alpha: float = clamp(1.0 - abs(w) * 0.5, 0.2, 1.0)
			_vertex_mats[i].albedo_color.a = alpha

	# Update edge meshes
	for e_idx in range(_edges.size()):
		if e_idx >= _edge_meshes.size():
			break
		var edge_mi: MeshInstance3D = _edge_meshes[e_idx]
		if not is_instance_valid(edge_mi):
			continue

		var a: Vector3 = _projected[_edges[e_idx].x]
		var b: Vector3 = _projected[_edges[e_idx].y]
		var mid: Vector3 = (a + b) * 0.5
		var dist: float = a.distance_to(b)

		edge_mi.position = mid
		edge_mi.scale.y = dist
		# Rotate to connect a and b
		var dir: Vector3 = (b - a).normalized()
		if dir.length() > 0.001:
			edge_mi.look_at(edge_mi.position + dir, Vector3.RIGHT)
			edge_mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	if _label:
		_label.text = "4D | XW=%.1f YW=%.1f" % [rad_to_deg(_angle_xw), rad_to_deg(_angle_yw)]

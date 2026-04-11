# @identity
# essence: five octahedra in a row — fold_amount 0.0, 0.25, 0.5, 0.75, 1.0 — the complete fold progression
# desire: see the entire lifecycle at once — flat net to rigid diamond in five frozen steps
# critical_parameter: spacing between stages shows the fold as a continuous transformation
# truth: one variable, five snapshots, the whole story.

class_name DeltahedronStages
extends Node3D
## Five deltahedra side by side at different fold_amounts.
## Shows the complete net-to-solid progression in one glance.

const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

const STAGE_COUNT := 5
const STAGE_FOLDS: PackedFloat64Array = [0.0, 0.25, 0.5, 0.75, 1.0]
const SPACING := 0.4

enum Species { TETRAHEDRON, OCTAHEDRON, ICOSAHEDRON }

var species: Species = Species.OCTAHEDRON
var _vertices_3d: Array[Vector3] = []
var _vertices_flat: Array[Vector3] = []
var _faces: Array = []
var _body_scale: float = 0.12


func _ready() -> void:
	_gen_species()
	_compute_flat_net()
	_build_stages()


func _gen_species() -> void:
	match species:
		Species.TETRAHEDRON:
			_gen_tetrahedron()
		Species.OCTAHEDRON:
			_gen_octahedron()
		Species.ICOSAHEDRON:
			_gen_icosahedron()


func _gen_tetrahedron() -> void:
	var s := _body_scale
	_vertices_3d = [
		Vector3(1, 1, 1).normalized() * s,
		Vector3(1, -1, -1).normalized() * s,
		Vector3(-1, 1, -1).normalized() * s,
		Vector3(-1, -1, 1).normalized() * s,
	]
	_faces = [[0, 2, 1], [0, 1, 3], [0, 3, 2], [1, 2, 3]]


func _gen_octahedron() -> void:
	var s := _body_scale
	_vertices_3d = [
		Vector3(0, s, 0), Vector3(0, -s, 0),
		Vector3(s, 0, 0), Vector3(-s, 0, 0),
		Vector3(0, 0, s), Vector3(0, 0, -s),
	]
	_faces = [
		[0, 4, 2], [0, 2, 5], [0, 5, 3], [0, 3, 4],
		[1, 2, 4], [1, 5, 2], [1, 3, 5], [1, 4, 3],
	]


func _gen_icosahedron() -> void:
	var s := _body_scale
	var phi := (1.0 + sqrt(5.0)) / 2.0
	var a := s / sqrt(1.0 + phi * phi)
	var b := phi * a
	_vertices_3d = [
		Vector3(-a, b, 0), Vector3(a, b, 0), Vector3(-a, -b, 0), Vector3(a, -b, 0),
		Vector3(0, -a, b), Vector3(0, a, b), Vector3(0, -a, -b), Vector3(0, a, -b),
		Vector3(b, 0, -a), Vector3(b, 0, a), Vector3(-b, 0, -a), Vector3(-b, 0, a),
	]
	_faces = [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
	]


func _compute_flat_net() -> void:
	var vert_count := _vertices_3d.size()
	var face_count := _faces.size()
	_vertices_flat.resize(vert_count)
	for i in vert_count:
		_vertices_flat[i] = Vector3.ZERO

	if face_count == 0:
		return

	var placed_face: Array[bool] = []
	placed_face.resize(face_count)
	var placed_vert: Array[bool] = []
	placed_vert.resize(vert_count)

	var f0: Array = _faces[0]
	var edge_len: float = _vertices_3d[f0[0]].distance_to(_vertices_3d[f0[1]])
	_vertices_flat[f0[0]] = Vector3(0, 0, 0)
	_vertices_flat[f0[1]] = Vector3(edge_len, 0, 0)
	_vertices_flat[f0[2]] = Vector3(edge_len * 0.5, 0, edge_len * 0.866)
	placed_vert[f0[0]] = true
	placed_vert[f0[1]] = true
	placed_vert[f0[2]] = true
	placed_face[0] = true

	var queue: Array[int] = [0]
	while not queue.is_empty():
		var fi: int = queue.pop_front()
		var face: Array = _faces[fi]
		for ni in face_count:
			if placed_face[ni]:
				continue
			var nface: Array = _faces[ni]
			var shared: Array[int] = []
			var new_vert: int = -1
			for vi in 3:
				if nface[vi] in face:
					shared.append(nface[vi])
				else:
					new_vert = nface[vi]
			if shared.size() != 2 or new_vert < 0 or placed_vert[new_vert]:
				continue
			var old_third: int = -1
			for vi in 3:
				if face[vi] != shared[0] and face[vi] != shared[1]:
					old_third = face[vi]
					break
			if old_third < 0:
				continue
			var a: Vector3 = _vertices_flat[shared[0]]
			var b: Vector3 = _vertices_flat[shared[1]]
			var mid: Vector3 = (a + b) * 0.5
			var edge_dir: Vector3 = (b - a).normalized()
			var old_pos: Vector3 = _vertices_flat[old_third]
			var to_old: Vector3 = old_pos - mid
			var parallel: Vector3 = edge_dir * to_old.dot(edge_dir)
			var perp: Vector3 = to_old - parallel
			_vertices_flat[new_vert] = mid + parallel - perp
			placed_vert[new_vert] = true
			placed_face[ni] = true
			queue.append(ni)

	var center := Vector3.ZERO
	for v in _vertices_flat:
		center += v
	center /= max(vert_count, 1)
	for i in vert_count:
		_vertices_flat[i] -= center


func _build_stages() -> void:
	var total_width: float = (STAGE_COUNT - 1) * SPACING
	var start_x: float = -total_width * 0.5

	for stage in STAGE_COUNT:
		var t: float = STAGE_FOLDS[stage]
		var x_offset: float = start_x + stage * SPACING

		# Interpolate vertices
		var verts: Array = []
		for i in _vertices_3d.size():
			verts.append(_vertices_flat[i].lerp(_vertices_3d[i], t))

		# Build mesh
		var mat := StandardMaterial3D.new()
		# Color gradient: blue (flat) to white (mid) to gold (assembled)
		var color: Color
		if t < 0.5:
			color = Color(0.5 + t, 0.6 + t * 0.6, 0.9 - t * 0.4)  # Blue → white
		else:
			color = Color(0.9 + (t - 0.5) * 0.2, 0.85 - (t - 0.5) * 0.3, 0.5 - (t - 0.5) * 0.4)  # White → gold
		mat.albedo_color = color
		mat.roughness = 0.8
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission = color * 0.2
		mat.emission_energy_multiplier = 0.5

		var mesh: ArrayMesh = PrimitiveMeshBuilder.build_mesh(verts, _faces, {"double_sided": true})
		if not mesh:
			continue

		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.position = Vector3(x_offset, _body_scale * 0.5, 0)
		mi.name = "Stage_%d" % stage
		add_child(mi)

		# Label below each stage
		var label := Label3D.new()
		label.text = "%.0f%%\n%dv %df" % [t * 100.0, verts.size(), _faces.size()]
		label.font_size = 48
		label.pixel_size = 0.002
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(color.r, color.g, color.b, 0.9)
		label.position = Vector3(x_offset, -_body_scale * 0.3, 0)
		add_child(label)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("species"):
		var sp: String = str(config["species"]).to_lower()
		match sp:
			"tetrahedron", "tetra", "4":
				species = Species.TETRAHEDRON
			"octahedron", "octa", "8":
				species = Species.OCTAHEDRON
			"icosahedron", "icosa", "20":
				species = Species.ICOSAHEDRON

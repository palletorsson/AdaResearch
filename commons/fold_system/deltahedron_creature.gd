# @identity
# essence: a convex deltahedron that unfolds from its flat net — Cauchy's theorem guarantees rigidity when assembled
# desire: a creature whose genome IS its net topology — tetrahedron, octahedron, icosahedron are species
# critical_parameter: fold_amount — 0.0 is flat net (vulnerable), 1.0 is assembled solid (rigid, strong)
# triggers: fold_amount drives all vertex positions simultaneously — single DOF via lerp between flat and 3D
# emerges: structural integrity increases with fold_amount; partially folded = partially vulnerable
# needs: PrimitiveMeshBuilder [reuse]; GridMaterialFactory [reuse]; existing polyhedra vertex data [reuse]
# relationships: replaces hand-placed segments with mathematically grounded nets; each deltahedron is a species
# truth: triangles can't deform. A closed convex deltahedron can't flex. The net IS the genome.

class_name DeltahedronCreature
extends FoldCritter
## A creature built from a deltahedron net — uses existing Ada primitives.
## Flat at fold_amount=0, fully assembled solid at fold_amount=1.
## All faces are equilateral triangles — maximum structural integrity.

const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")

enum Species {
	TETRAHEDRON,   # 4 faces, 4 vertices
	OCTAHEDRON,    # 8 faces, 6 vertices
	ICOSAHEDRON,   # 20 faces, 12 vertices
}

@export var species: Species = Species.OCTAHEDRON
@export var body_scale: float = 0.15
@export var base_color: Color = Color(0.93, 0.91, 0.86)
@export var wireframe_color: Color = Color(0.4, 0.35, 0.3)

# Geometry — topology is fixed, only positions change
var _vertices_3d: Array[Vector3] = []
var _vertices_flat: Array[Vector3] = []
var _faces: Array = []  # Array of [i0, i1, i2] — NEVER changes after creation
var _mesh_instance: MeshInstance3D = null
var _material: Material = null
var _mesh: ArrayMesh = null
var _last_fold_amount: float = -1.0  # Track to skip redundant updates


func _ready() -> void:
	_generate_species()
	_compute_flat_net()
	_create_fold_rig()

	# Set fold_amount BEFORE building mesh so initial geometry matches
	fold_state = FoldState.FOLDED
	fold_amount = 0.5
	target_fold = 0.5

	_build_fold_mesh()
	_create_collision()
	super._ready()


# ═════════════════════════════════════════════════════════════════════════
# SPECIES — reuse existing Ada primitive vertex/face data
# ═════════════════════════════════════════════════════════════════════════

func _generate_species() -> void:
	match species:
		Species.TETRAHEDRON:
			_gen_tetrahedron()
		Species.OCTAHEDRON:
			_gen_octahedron()
		Species.ICOSAHEDRON:
			_gen_icosahedron()


func _gen_tetrahedron() -> void:
	var s := body_scale
	_vertices_3d = [
		Vector3(1, 1, 1).normalized() * s,
		Vector3(1, -1, -1).normalized() * s,
		Vector3(-1, 1, -1).normalized() * s,
		Vector3(-1, -1, 1).normalized() * s,
	]
	_faces = [[0, 2, 1], [0, 1, 3], [0, 3, 2], [1, 2, 3]]


func _gen_octahedron() -> void:
	# Same vertices as commons/primitives/octahedron, scaled
	var s := body_scale
	_vertices_3d = [
		Vector3(0, s, 0),     # top
		Vector3(0, -s, 0),    # bottom
		Vector3(s, 0, 0),     # right
		Vector3(-s, 0, 0),    # left
		Vector3(0, 0, s),     # back
		Vector3(0, 0, -s),    # front
	]
	_faces = [
		[0, 4, 2], [0, 2, 5], [0, 5, 3], [0, 3, 4],  # upper
		[1, 2, 4], [1, 5, 2], [1, 3, 5], [1, 4, 3],  # lower
	]


func _gen_icosahedron() -> void:
	var s := body_scale
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


# ═════════════════════════════════════════════════════════════════════════
# NET UNFOLDING — BFS reflection across shared edges
# ═════════════════════════════════════════════════════════════════════════

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

	# Place first face flat on XZ plane
	var f0: Array = _faces[0]
	var edge_len: float = _vertices_3d[f0[0]].distance_to(_vertices_3d[f0[1]])
	_vertices_flat[f0[0]] = Vector3(0, 0, 0)
	_vertices_flat[f0[1]] = Vector3(edge_len, 0, 0)
	_vertices_flat[f0[2]] = Vector3(edge_len * 0.5, 0, edge_len * 0.866)
	placed_vert[f0[0]] = true
	placed_vert[f0[1]] = true
	placed_vert[f0[2]] = true
	placed_face[0] = true

	# BFS: reflect unplaced vertex across shared edge
	var queue: Array[int] = [0]
	while not queue.is_empty():
		var fi: int = queue.pop_front()
		var face: Array = _faces[fi]

		for ni in face_count:
			if placed_face[ni]:
				continue
			var nface: Array = _faces[ni]

			# Find shared edge (2 vertices in common)
			var shared: Array[int] = []
			var new_vert: int = -1
			for vi in 3:
				if nface[vi] in face:
					shared.append(nface[vi])
				else:
					new_vert = nface[vi]

			if shared.size() != 2 or new_vert < 0 or placed_vert[new_vert]:
				continue

			# Find the old third vertex (in placed face, not in shared edge)
			var old_third: int = -1
			for vi in 3:
				if face[vi] != shared[0] and face[vi] != shared[1]:
					old_third = face[vi]
					break
			if old_third < 0:
				continue

			# Reflect old_third across the shared edge to get new_vert position
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

	# Center the net
	var center := Vector3.ZERO
	for v in _vertices_flat:
		center += v
	center /= max(vert_count, 1)
	for i in vert_count:
		_vertices_flat[i] -= center


# ═════════════════════════════════════════════════════════════════════════
# FOLD RIG — minimal, just for FSM/energy/tension
# ═════════════════════════════════════════════════════════════════════════

func _create_fold_rig() -> void:
	fold_rig = FoldRig.new()
	fold_rig.solver = BoneFoldSolver.new()
	fold_rig.base_stiffness = 14.0
	fold_rig.base_damping = 0.88
	fold_rig.max_fold_energy = 1.0
	fold_rig.supports_misfold = true

	# One dummy segment so the rig doesn't crash
	var seg := FoldSegmentData.new()
	seg.segment_name = &"body"
	seg.mass = 1.0
	fold_rig.segments = [seg]


# ═════════════════════════════════════════════════════════════════════════
# MESH — uses PrimitiveMeshBuilder + GridMaterialFactory
# ═════════════════════════════════════════════════════════════════════════

func _build_fold_mesh() -> void:
	_segment_nodes.clear()

	# Create a single body node for the segment system
	var body_node := Node3D.new()
	body_node.name = "body"
	add_child(body_node)
	_segment_nodes[&"body"] = body_node

	# Paper material — double sided, slight emission for visibility
	_material = StandardMaterial3D.new()
	_material.albedo_color = base_color
	_material.roughness = 0.85
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.emission_enabled = true
	_material.emission = base_color * 0.15
	_material.emission_energy_multiplier = 0.4

	# Create mesh instance — topology built once, positions update each frame
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "DeltahedronMesh"
	body_node.add_child(_mesh_instance)
	_build_initial_mesh()


func _create_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = body_scale * 1.2
	col.shape = shape
	add_child(col)


# ═════════════════════════════════════════════════════════════════════════
# FOLD ANIMATION — same faces, same vertex count, only positions change
# ═════════════════════════════════════════════════════════════════════════

func _process_visual(delta: float) -> void:
	if not fold_rig or not fold_rig.solver:
		return
	# Only update if fold_amount actually changed
	if abs(fold_amount - _last_fold_amount) > 0.001:
		_update_vertex_positions()
		_last_fold_amount = fold_amount


func _build_initial_mesh() -> void:
	## Create the ArrayMesh once with current vertex positions.
	## Topology (faces) is fixed forever. Only positions update.
	if _vertices_3d.is_empty() or _vertices_flat.is_empty():
		return

	var current_verts: Array = []
	for i in _vertices_3d.size():
		current_verts.append(_vertices_flat[i].lerp(_vertices_3d[i], fold_amount))

	_mesh = PrimitiveMeshBuilder.build_mesh(current_verts, _faces, {"double_sided": true})
	if _mesh and _mesh_instance:
		_mesh_instance.mesh = _mesh
		_mesh_instance.material_override = _material
		_last_fold_amount = fold_amount


func _update_vertex_positions() -> void:
	## Update vertex positions in-place. Same face count, same vertex count.
	## Topology never changes — only geometry transforms.
	if not _mesh or _mesh.get_surface_count() == 0:
		_build_initial_mesh()
		return

	var t: float = fold_amount

	# Compute current positions
	var current_verts: Array = []
	for i in _vertices_3d.size():
		current_verts.append(_vertices_flat[i].lerp(_vertices_3d[i], t))

	# Rebuild mesh with same topology, new positions
	# (ArrayMesh doesn't support in-place vertex update easily,
	#  but we reuse the same mesh reference and avoid material/instance churn)
	var new_mesh: ArrayMesh = PrimitiveMeshBuilder.build_mesh(current_verts, _faces, {"double_sided": true})
	if new_mesh:
		_mesh = new_mesh
		_mesh_instance.mesh = _mesh


# ═════════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═════════════════════════════════════════════════════════════════════════

func configure(config: Dictionary) -> void:
	if config.has("species"):
		var sp: String = str(config["species"]).to_lower()
		match sp:
			"tetrahedron", "tetra", "4":
				species = Species.TETRAHEDRON
			"octahedron", "octa", "8":
				species = Species.OCTAHEDRON
			"icosahedron", "icosa", "20":
				species = Species.ICOSAHEDRON
	if config.has("scale"):
		body_scale = float(config["scale"])
	if config.has("fold_amount"):
		fold_amount = float(config["fold_amount"])
		target_fold = fold_amount
	if config.has("color"):
		base_color = Color(config["color"])


func apply_grid_config(config: Dictionary) -> void:
	configure(config)

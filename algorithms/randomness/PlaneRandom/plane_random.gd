extends Node3D
## DynamicTerrain.gd
## Creates a 20×20 quad grid (Y up), randomly lifts vertices ±lift_range, and updates collider.
## Uses HeightMapShape3D for smooth, walkable terrain physics.

@export var quads_x: int = 20
@export var quads_z: int = 20
@export var cell_size: float = 1.0
@export_range(0.1, 0.5, 0.01) var lift_range: float = 0.5
@export var do_lift_on_ready: bool = true
@export var initial_rounds: int = 100
@export var update_interval: float = 1.0  # seconds between updates

var verts: PackedVector3Array
var uvs: PackedVector2Array
var indices: PackedInt32Array

var mesh_instance: MeshInstance3D
var body: StaticBody3D
var shape_node: CollisionShape3D
var rng := RandomNumberGenerator.new()
var update_timer: float = 0.0
var initial_rounds_complete: bool = false

func _ready() -> void:
	rng.randomize()
	_build_nodes()
	_build_flat_grid()
	_commit_mesh()
	_update_collider()

	if do_lift_on_ready:
		_run_initial_rounds()

# ---------------------------------------------------------------------
# --- Public ----------------------------------------------------------
func lift_random_vertex() -> void:
	# Randomly lift one vertex up/down within ±lift_range
	if verts.is_empty():
		return
	var i := rng.randi_range(0, verts.size() - 1)
	var dy := rng.randf_range(-lift_range, lift_range)
	var p := verts[i]
	p.y += dy
	verts[i] = p

func _run_initial_rounds() -> void:
	# Run initial rounds of random vertex lifting
	for round in range(initial_rounds):
		lift_random_vertex()
	_commit_mesh()
	_update_collider()
	initial_rounds_complete = true
	print("✅ Completed %d initial rounds" % initial_rounds)

func _process(delta: float) -> void:
	if not initial_rounds_complete:
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		lift_random_vertex()
		_commit_mesh()
		await get_tree().process_frame  # allow physics to update
		_update_collider()

# ---------------------------------------------------------------------
# --- Internals -------------------------------------------------------
func _build_nodes() -> void:
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Apply SimpleGrid shader material
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	mesh_instance.material_override = shader_mat

	body = StaticBody3D.new()
	add_child(body)

	shape_node = CollisionShape3D.new()
	body.add_child(shape_node)

func _build_flat_grid() -> void:
	var vx := quads_x + 1
	var vz := quads_z + 1

	verts = PackedVector3Array()
	uvs = PackedVector2Array()
	indices = PackedInt32Array()

	verts.resize(vx * vz)
	uvs.resize(vx * vz)

	var width := float(quads_x) * cell_size
	var depth := float(quads_z) * cell_size
	var x0 := -width * 0.5
	var z0 := -depth * 0.5

	# Create vertices (Y up)
	for z in range(vz):
		for x in range(vx):
			var idx := z * vx + x
			var px := x0 + float(x) * cell_size
			var pz := z0 + float(z) * cell_size
			verts[idx] = Vector3(px, 0.0, pz)
			uvs[idx] = Vector2(float(x) / quads_x, float(z) / quads_z)

	# Triangles
	for z in range(quads_z):
		for x in range(quads_x):
			var i0 := z * vx + x
			var i1 := i0 + 1
			var i2 := i0 + vx
			var i3 := i2 + 1
			indices.push_back(i0)
			indices.push_back(i2)
			indices.push_back(i1)
			indices.push_back(i1)
			indices.push_back(i2)
			indices.push_back(i3)

func _commit_mesh() -> void:
	# Build mesh using SurfaceTool for normals
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in indices.size():
		var idx := indices[i]
		st.set_uv(uvs[idx])
		st.add_vertex(verts[idx])

	st.generate_normals()
	var mesh := st.commit()
	mesh_instance.mesh = mesh

func _update_collider() -> void:
	# Build smooth physics shape from vertex heights (HeightMapShape3D)
	var m := mesh_instance.mesh
	if m == null:
		return

	var size_x := quads_x + 1
	var size_z := quads_z + 1
	var heights := PackedFloat32Array()

	for z in range(size_z):
		for x in range(size_x):
			var idx := z * size_x + x
			heights.append(verts[idx].y)

	var shape := HeightMapShape3D.new()
	shape.map_width = size_x
	shape.map_depth = size_z
	shape.map_data = heights
	shape_node.shape = shape

	# Lower the collider slightly for safe walking clearance
	body.transform.origin.y = -0.05
